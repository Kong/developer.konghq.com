---
title: Consume Kafka records as JSON with {{site.event_gateway}}
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/consume-kafka-records-as-json-with-event-gateway/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka
    - confluent
    - schema-registry
    - avro

description: "Store records as Avro in the backend cluster, and convert them to JSON for consumers that don't run a Schema Registry client."

tldr:
  q: How can I let a consumer read JSON while records are stored as Avro?
  a: |
    1. Create a Schema Validation policy (consume phase) to parse Avro records against a Confluent Schema Registry.
    1. Nest a Record Transcode Consume policy that converts the parsed record to JSON.

tools:
    - konnect-api

prereqs:
  inline:
    - title: Install kafkactl
      position: before
      include_content: knep/kafkactl
    - title: Start a local Kafka cluster
      position: before
      include_content: knep/docker-compose-start

cleanup:
  inline:
    - title: Clean up {{site.event_gateway}} resources
      include_content: cleanup/products/event-gateway
      icon_url: /assets/icons/gateway.svg

min_version:
  event-gateway: '1.3'

related_resources:
  - text: Record Transcode Consume policy
    url: /event-gateway/policies/record-transcode-consume/
  - text: Schema Validation policy
    url: /event-gateway/policies/schema-validation-consume/
  - text: Schema Registry entity
    url: /event-gateway/entities/schema-registry/
  - text: Validate Avro messages with Confluent Schema Registry
    url: /event-gateway/validate-avro-messages-with-schema-registry/
---

## Overview

In this guide, you'll learn how to store Kafka records as Avro and serve them as JSON to a consumer that doesn't run a Schema Registry client.

Avro keeps records compact and schema-governed in the cluster, but not every consumer wants the overhead of an Avro deserializer.
The {{site.event_gateway_short}} [Record Transcode Consume policy](/event-gateway/policies/record-transcode-consume/) converts an already schema-validated record to a different format on its way to the client, so producers and the cluster keep using Avro while this consumer reads plain JSON.

We'll use an `orders` topic that holds order records, produced and stored as Avro. A consumer that connects through the virtual cluster receives the same records converted to JSON, with no producer or cluster changes.

Here's how the data flows through the system:

{% mermaid %}
flowchart LR
    P[Producer<br/>Avro] --> K[Kafka <br>Broker<br/>Avro records]

    subgraph consume [Event Gateway Consume policy chain]
        SV[Schema <br>Validation<br/>Parse Avro] --> RT[Record Transcode<br/>convert to JSON]
    end

    K --> SV
    RT --> CO[Consumer<br/>JSON records]
{% endmermaid %}

## Create a backend cluster

{% include knep/create-backend-cluster.md insecure=true %}

## Create a virtual cluster

Create a virtual cluster that the consumer connects to:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: orders_vc
  destination:
    id: $BACKEND_CLUSTER_ID
  dns_label: orders
  authentication:
    - type: anonymous
  acl_mode: passthrough
extract_body:
  - name: id
    variable: VIRTUAL_CLUSTER_ID
capture:
  - variable: VIRTUAL_CLUSTER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a listener with a forwarding policy

Create a [listener](/event-gateway/entities/listener/) to accept connections:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners
status_code: 201
method: POST
body:
  name: orders_listener
  addresses:
    - 0.0.0.0
  ports:
    - 19092-19095
extract_body:
  - name: id
    variable: LISTENER_ID
capture:
  - variable: LISTENER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Create a [Forward to Virtual Cluster policy](/event-gateway/policies/forward-to-virtual-cluster/) to forward traffic to the virtual cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: forward_to_virtual_cluster
  name: forward_to_orders_vc
  config:
    type: port_mapping
    advertised_host: localhost
    destination:
      id: $VIRTUAL_CLUSTER_ID
{% endkonnect_api_request %}
<!--vale on-->

For demo purposes, we're using port mapping, which assigns each Kafka broker to a dedicated port on the {{site.event_gateway_short}}.
In production, we recommend using [SNI routing](/event-gateway/architecture/#hostname-mapping) instead.

## Create a Schema Registry entity

Create a [Schema Registry](/event-gateway/entities/schema-registry/) entity that points to the Confluent Schema Registry running locally.
Since the {{site.event_gateway_short}} data plane runs in the same Docker network as the Schema Registry, use the container hostname `schema-registry`:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/schema-registries
status_code: 201
method: POST
body:
  name: local-schema-registry
  type: confluent
  config:
    schema_type: avro
    endpoint: http://schema-registry:8081
    timeout_seconds: 10
extract_body:
  - name: id
    variable: SCHEMA_REGISTRY_ID
capture:
  - variable: SCHEMA_REGISTRY_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Register an Avro schema

Register an Avro schema for the `orders` topic in the Confluent Schema Registry.
The schema defines three fields: `order_id`, `item`, and `amount`:

<!--vale off-->
{% validation custom-command %}
command: |
  curl -sS --fail -X POST http://localhost:8081/subjects/orders-value/versions \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    -d '{"schema": "{\"type\": \"record\", \"name\": \"Order\", \"fields\": [{\"name\": \"order_id\", \"type\": \"string\"}, {\"name\": \"item\", \"type\": \"string\"}, {\"name\": \"amount\", \"type\": \"double\"}]}"}'
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The subject name `orders-value` follows Confluent's default [TopicNameStrategy](https://docs.confluent.io/platform/current/schema-registry/fundamentals/serdes-develop/index.html#subject-name-strategy), which uses the pattern `<topic>-value`.

## Create a Schema Validation policy

Create a [Schema Validation policy](/event-gateway/policies/schema-validation-consume/) that parses Avro records against the Confluent Schema Registry during the consume phase.
The Record Transcode Consume policy needs a parsed record, so it must be nested under this policy:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/consume-policies
status_code: 201
method: POST
body:
  type: schema_validation
  name: validate_avro
  config:
    type: confluent_schema_registry
    schema_registry:
      name: local-schema-registry
    value_validation_action: skip
extract_body:
  - name: id
    variable: SCHEMA_VALIDATION_POLICY_ID
capture:
  - variable: SCHEMA_VALIDATION_POLICY_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

The `value_validation_action: skip` setting means a record that can't be decoded against the registered Avro schema is never delivered to the consumer.

## Create a Record Transcode Consume policy

Create the [Record Transcode Consume policy](/event-gateway/policies/record-transcode-consume/) nested under the Schema Validation policy.
Set `output_format: json` to convert each parsed Avro record to JSON before it reaches the consumer:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/consume-policies
status_code: 201
method: POST
body:
  type: transcode
  name: convert_orders_to_json
  parent_policy_id: $SCHEMA_VALIDATION_POLICY_ID
  config:
    failure_mode: skip
    output_format: json
    schema_ref_destination:
      type: none
{% endkonnect_api_request %}
<!--vale on-->

Converting to JSON doesn't require a `schema_source`, because JSON doesn't need a schema to serialize the record value.
`schema_ref_destination: none` means the converted record carries no reference to a schema, since a plain JSON consumer has no use for one.

Both policies use `failure_mode: skip`, so a record either policy can't process is never delivered.
The alternatives are `error`, `passthrough`, and `mark`.

We generally recommend using `skip` over `error`, because `error` blocks the whole batch and leaves the consumer stuck on the problematic offset until someone intervenes.

## Configure kafkactl

Create a kafkactl configuration with a `direct` context that connects to Kafka using the Schema Registry for Avro serialization, and a `vc` context that connects through the virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  cat <<EOF > kafkactl.yaml
  contexts:
    direct:
      brokers:
        - localhost:9094
        - localhost:9095
        - localhost:9096
      schemaRegistry:
        url: http://localhost:8081
    vc:
      brokers:
        - localhost:19092
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The `vc` context has no Schema Registry configured, because the consumer reads plain JSON through the virtual cluster and doesn't need one.

## Create a topic and produce records

Create the `orders` topic:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context direct create topic orders
expected:
  message: "topic created: orders"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Produce two order records directly to Kafka.
kafkactl serializes them to Avro using the schema from the registry:

<!--vale off-->
{% validation custom-command %}
command: |
  echo '{"order_id":"1001","item":"widget","amount":42.5}
  {"order_id":"1002","item":"gadget","amount":19.99}' | kafkactl -C kafkactl.yaml --context direct produce orders
expected:
  message: "2 messages produced"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Validate

### Consume directly from Kafka

Consume the records straight from the broker to confirm that Kafka stores them as Avro.
The `--print-schema` flag displays the Avro schema used for deserialization:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context direct consume orders --from-beginning --exit --print-schema
expected:
  message: '"order_id":"1001"'
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Both records come back deserialized from Avro, alongside the schema used to decode them:

```shell
##{"type":"record","name":"Order","fields":[{"name":"order_id","type":"string"},{"name":"item","type":"string"},{"name":"amount","type":"double"}]}#1#{"order_id":"1001","item":"widget","amount":42.5}
##{"type":"record","name":"Order","fields":[{"name":"order_id","type":"string"},{"name":"item","type":"string"},{"name":"amount","type":"double"}]}#1#{"order_id":"1002","item":"gadget","amount":19.99}
```
{:.no-copy-code}

### Consume through the virtual cluster

Now consume the same records through the virtual cluster, with no Schema Registry configured for this context:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc consume orders --from-beginning --exit
expected:
  message: '"order_id":"1001"'
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The records arrive as plain JSON, with no Avro schema needed to read them:

```json
{"order_id":"1001","item":"widget","amount":42.5}
{"order_id":"1002","item":"gadget","amount":19.99}
```
{:.no-copy-code}

In this case, the producer and the backend cluster never changed formats. 
The Schema Validation policy parsed the Avro records, and the Record Transcode Consume policy converted them to JSON for this consumer only.
