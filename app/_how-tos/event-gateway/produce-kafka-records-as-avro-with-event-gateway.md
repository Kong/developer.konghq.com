---
title: Produce Kafka records as Avro with {{site.event_gateway}}
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/produce-kafka-records-as-avro-with-event-gateway/

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

description: "Let producers send plain JSON or Avro, and store their records as Avro in the backend cluster using a Confluent Schema Registry."

tldr:
  q: How can producers send JSON or Avro while records are stored as Avro?
  a: |
    To let producers send plain JSON or Avro while storing records as Avro in the backend cluster, you need to:
    1. Create a Schema Validation policy (produce phase) that parses both formats using a schema registry with `schema_type: any`.
    1. Nest a Record Transcode Produce policy that converts the parsed record to Avro using the same schema registry.

tools:
    - konnect-api

prereqs:
  inline:
    - title: Install kafkactl
      position: before
      include_content: knep/kafkactl
    - title: Start a local Kafka cluster and schema registry
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
  - text: Record Transcode Produce policy
    url: /event-gateway/policies/record-transcode-produce/
  - text: Schema Validation policy
    url: /event-gateway/policies/schema-validation-produce/
  - text: Schema Registry entity
    url: /event-gateway/entities/schema-registry/
  - text: Consume Kafka records as JSON with {{site.event_gateway}}
    url: /event-gateway/consume-kafka-records-as-json-with-event-gateway/
  - text: Validate Avro messages with Confluent Schema Registry
    url: /event-gateway/validate-avro-messages-with-schema-registry/
---

## Overview

In this guide, you'll learn how to let producers send records as plain JSON or as Avro while {{site.event_gateway_short}} stores them as Avro in the backend cluster.

Not every producer wants to run a Schema Registry client or serialize Avro directly, and during a migration from JSON to Avro, both formats can be in use at once.
The {{site.event_gateway_short}} [Record Transcode Produce policy](/event-gateway/policies/record-transcode-produce/) converts an already schema-validated record to a different format on its way to the backend cluster. The cluster and every consumer of the topic only ever see a single format, regardless of what the producers send.

We'll use an `orders` topic that holds order records. One producer connects through the virtual cluster and sends plain JSON, and another sends Avro serialized with a Schema Registry client. {{site.event_gateway_short}} accepts both and stores every record as Avro.

Here's how the data flows through the system:

{% mermaid %}
flowchart LR
    P1[Producer<br/>JSON] --> SV
    P2[Producer<br/>Avro] --> SV

    subgraph produce [Event Gateway Produce policy chain]
        SV[Schema <br>Validation<br/>Parse JSON or Avro] --> RT[Record Transcode<br/>convert to Avro]
    end

    RT --> K[Kafka <br>Broker<br/>Avro records]
{% endmermaid %}

## Create a backend cluster

{% include knep/create-backend-cluster.md insecure=true %}

## Create a virtual cluster

Create a virtual cluster that the producer connects to:

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
    - 19092-19105
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
    schema_type: any
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

The `schema_type: any` setting lets this one registry accept records in more than one format. Values that carry a schema reference, in the [Confluent wire format](https://docs.confluent.io/platform/current/schema-registry/fundamentals/serdes-develop/index.html#wire-format) or in a record header, are decoded using the registry. 
Any other value is parsed as JSON without a schema.
Both the Schema Validation policy and the Record Transcode Produce policy reference this same registry.

## Register the target Avro schema

Register the Avro schema that {{site.event_gateway_short}} converts records into, under the `orders-value` subject in the Confluent Schema Registry.
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
The Record Transcode Produce policy looks up this subject at runtime, so the schema must already exist before a producer sends records.
The Avro producer serializes against this same schema, so one registration serves both.

## Create a Schema Validation policy

Create a [Schema Validation policy](/event-gateway/policies/schema-validation-produce/) that parses a producer's records during the produce phase.
The Record Transcode Produce policy needs a parsed record, so it must be nested under this policy:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/produce-policies
status_code: 201
method: POST
body:
  type: schema_validation
  name: validate_records
  config:
    type: confluent_schema_registry
    schema_registry:
      name: local-schema-registry
    value_validation_action: reject
extract_body:
  - name: id
    variable: SCHEMA_VALIDATION_POLICY_ID
capture:
  - variable: SCHEMA_VALIDATION_POLICY_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Because the registry's `schema_type` is `any`, this policy accepts both formats at once: a record that references a schema in the registry is decoded and validated against it, and a record with no schema reference is parsed as JSON.
The `value_validation_action: reject` setting means a batch that holds a record that can't be parsed or validated is rejected outright.

## Create a Record Transcode Produce policy

Create the [Record Transcode Produce policy](/event-gateway/policies/record-transcode-produce/) nested under the Schema Validation policy.
Set `output_format: avro` to convert each parsed JSON record to Avro before {{site.event_gateway_short}} writes it to the backend cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/produce-policies
status_code: 201
method: POST
body:
  type: transcode
  name: convert_orders_to_avro
  parent_policy_id: $SCHEMA_VALIDATION_POLICY_ID
  config:
    failure_mode: reject
    output_format: avro
    schema_source:
      type: reference
      schema_registry:
        name: local-schema-registry
      subject: context.topic.name + "-value"
      version: '"latest"'
    schema_ref_destination:
      type: confluent_format
{% endkonnect_api_request %}
<!--vale on-->

In this configuration:
* `schema_source`: Required to convert to Avro, because Avro needs a schema to serialize the record value.
* `subject`: An expression that selects the subject. In this example, `context.topic.name + '-value'` resolves to `orders-value` for records produced to the `orders` topic.
* `version`: An expression that selects the schema version. In this example, `'latest'` resolves to the newest registered version.
* `schema_ref_destination: confluent_format`: Prefixes the converted record with a reference to the schema, so any Confluent-compatible consumer of the topic can deserialize it.
* `failure_mode: reject`: Used by both the Schema Validation policy and the nested Record Transcode Produce policy. If either policy fails to process a record, the whole batch is rejected and never written to the backend cluster. The alternatives are `passthrough` and `mark`.

## Configure kafkactl

Create a kafkactl configuration with three contexts:

* `vc`: produces through the virtual cluster with no Schema Registry configured, for the producer that sends plain JSON.
* `vc-avro`: produces through the same virtual cluster with the Schema Registry configured, for the producer that sends Avro.
* `direct`: connects straight to Kafka using the Schema Registry for Avro deserialization.

<!--vale off-->
{% validation custom-command %}
command: |
  cat <<EOF > kafkactl.yaml
  contexts:
    vc:
      brokers:
        - localhost:19092
    vc-avro:
      brokers:
        - localhost:19092
      schemaRegistry:
        url: http://localhost:8081
    direct:
      brokers:
        - localhost:9094
        - localhost:9095
        - localhost:9096
      schemaRegistry:
        url: http://localhost:8081
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The `vc` context has no Schema Registry configured, because this producer sends plain JSON through the virtual cluster and doesn't need one.

## Create a topic and produce JSON records

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

Produce two order records as plain JSON through the virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  echo '{"order_id":"1001","item":"widget","amount":42.5}
  {"order_id":"1002","item":"gadget","amount":19.99}' | kafkactl -C kafkactl.yaml --context vc produce orders
expected:
  message: "2 messages produced"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Produce an Avro record

A second producer sends the same kind of record as Avro, using a client that serializes values with the Schema Registry.
Switch to the `vc-avro` context, which serializes values as Avro and prefixes them with a schema reference in the Confluent wire format:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc-avro produce orders \
    --value='{"order_id":"1003","item":"sprocket","amount":7.25}'
expected:
  message: "message produced (partition=0	offset=2)"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The Schema Validation policy accepts this record too, because it references the `Order` schema registered in the Schema Registry.
The record value already matches the Record Transcode Produce policy's `output_format`, so the policy leaves it unchanged, and the backend cluster stores the record exactly as the producer sent it.

Both producers now write to the same topic through the same policy chain: one sends plain JSON, the other sends Avro, and both records are accepted.

## Validate

Consume the records straight from the broker to confirm that Kafka stores every record as Avro, no matter which format the producers sent.
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

All three records come back deserialized from Avro, alongside the schema used to decode them:

```shell
##{"type":"record","name":"Order","fields":[{"name":"order_id","type":"string"},{"name":"item","type":"string"},{"name":"amount","type":"double"}]}#1#{"order_id":"1001","item":"widget","amount":42.5}
##{"type":"record","name":"Order","fields":[{"name":"order_id","type":"string"},{"name":"item","type":"string"},{"name":"amount","type":"double"}]}#1#{"order_id":"1002","item":"gadget","amount":19.99}
##{"type":"record","name":"Order","fields":[{"name":"order_id","type":"string"},{"name":"item","type":"string"},{"name":"amount","type":"double"}]}#1#{"order_id":"1003","item":"sprocket","amount":7.25}
```
{:.no-copy-code}

The Record Transcode Produce policy converted the records from the JSON producer to Avro, and the record from the Avro producer passed through unchanged.
In both cases, the backend cluster and every consumer of the topic only ever see Avro.
