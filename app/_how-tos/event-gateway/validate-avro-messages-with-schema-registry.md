---
title: Validate Avro messages with Confluent Schema Registry
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/validate-avro-messages-with-schema-registry/

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

description: "Enforce Avro schema validation on produced messages using the Confluent Schema Registry and {{site.event_gateway}}."

tldr:
  q: How can I validate Avro messages against a Confluent Schema Registry?
  a: |
    1. Register an Avro schema in the Confluent Schema Registry.
    1. Create a Schema Registry entity in {{site.event_gateway_short}} pointing to the registry.
    1. Create a Schema Validation produce policy with the `confluent_schema_registry` type and `reject` action.

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

related_resources:
  - text: Schema Validation produce policy
    url: /event-gateway/policies/schema-validation-produce/
  - text: Schema Registry entity
    url: /event-gateway/entities/schema-registry/
  - text: Confluent Schema Registry documentation
    url: https://docs.confluent.io/platform/current/schema-registry/index.html
---

## Overview

In this guide, you'll learn how to enforce Avro schema validation on messages produced through {{site.event_gateway_short}} using the Confluent Schema Registry.

We'll use an application logging scenario where producers send log events to an `app_logs` topic. Each log event must conform to an Avro schema with `level` and `message` fields. The {{site.event_gateway_short}} [Schema Validation policy](/event-gateway/policies/schema-validation-produce/) validates every produced message against the schema registered in the Confluent Schema Registry, and rejects messages that don't conform.

Here's how the data flows through the system:

{% mermaid %}
flowchart LR
    P[Producer] --> EG

    subgraph EG [Event Gateway]
        SV{Schema Validation<br/>Valid Avro?}
        SV -->|Yes| K[Kafka Broker]
        SV -->|No| R[Reject]
    end

    K --> C[Consumer]
{% endmermaid %}

## Create a backend cluster

{% include knep/create-backend-cluster.md insecure=true %}

## Create a virtual cluster

Create a virtual cluster with anonymous authentication:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: logs_vc
  destination:
    id: $BACKEND_CLUSTER_ID
  dns_label: logs
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

Create a listener to accept connections:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners
status_code: 201
method: POST
body:
  name: logs_listener
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

Create a [port mapping policy](/event-gateway/policies/forward-to-virtual-cluster/) to forward traffic to the virtual cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: forward_to_virtual_cluster
  name: forward_to_logs_vc
  config:
    type: port_mapping
    advertised_host: localhost
    destination:
      id: $VIRTUAL_CLUSTER_ID
{% endkonnect_api_request %}
<!--vale on-->

## Create a Schema Registry entity

Create a [Schema Registry](/event-gateway/entities/schema-registry/) entity in {{site.event_gateway_short}} that points to the Confluent Schema Registry running locally. Since the {{site.event_gateway_short}} data plane runs in the same Docker network as the Schema Registry, use the container hostname `schema-registry`:

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

## Create a Schema Validation produce policy

Create a [Schema Validation policy](/event-gateway/policies/schema-validation-produce/) that validates all produced messages against the Confluent Schema Registry. Messages that don't conform to the registered Avro schema are rejected:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/produce-policies
status_code: 201
method: POST
body:
  type: schema_validation
  name: validate_avro
  config:
    type: confluent_schema_registry
    schema_registry:
      name: local-schema-registry
    value_validation_action: reject
{% endkonnect_api_request %}
<!--vale on-->

The `value_validation_action: reject` setting ensures that the entire batch containing an invalid message is rejected, and the producer receives an error. Alternatively, you can use `mark`, which passes the message to the broker but adds a `kong/sverr-value` header to flag it as invalid.

## Configure kafkactl

Create a kafkactl configuration with a context that connects through the virtual cluster, with Schema Registry configured for Avro serialization:

<!--vale off-->
{% validation custom-command %}
command: |
  cat <<EOF > avro-cluster.yaml
  contexts:
    vc:
      brokers:
        - localhost:19092
      schemaRegistry:
        url: http://localhost:8081
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Create a Kafka topic

Create an `app_logs` topic through the virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C avro-cluster.yaml --context vc create topic app_logs
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Register an Avro schema

Register an Avro schema for the `app_logs` topic in the Confluent Schema Registry. The schema defines two fields: `level` (the log severity) and `message` (the log content):

<!--vale off-->
{% validation custom-command %}
command: |
  curl -sS --fail -X POST http://localhost:8081/subjects/app_logs-value/versions \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    -d '{"schema": "{\"type\": \"record\", \"name\": \"AppLog\", \"namespace\": \"com.example\", \"fields\": [{\"name\": \"level\", \"type\": \"string\"}, {\"name\": \"message\", \"type\": \"string\"}]}"}'
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The subject name `app_logs-value` follows Confluent's default [TopicNameStrategy](https://docs.confluent.io/platform/current/schema-registry/fundamentals/serdes-develop/index.html#subject-name-strategy), which uses the pattern `<topic>-value`.

## Validate
Use the following steps to make sure everything was set up correctly.

### Produce a valid Avro message

Produce a log event that conforms to the registered Avro schema:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C avro-cluster.yaml --context vc produce app_logs \
    --value='{"level": "info", "message": "Application started"}'
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The message is serialized as Avro by kafkactl using the schema from the registry, validated by {{site.event_gateway_short}}, and accepted:

```shell
message produced (partition=0	offset=0)
```
{:.no-copy-code}

### Produce a message that doesn't match the schema

Try to produce a valid JSON message that doesn't conform to the registered Avro schema. This message has a `severity` field instead of `level`:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C avro-cluster.yaml --context vc produce app_logs \
    --value='{"severity": "info", "message": "Application started"}'
expected:
  return_code: 1
render_output: false
{% endvalidation %}
<!--vale on-->

The message is rejected by {{site.event_gateway_short}} because it doesn't match the registered Avro schema:

```shell
Failed to produce message: failed to convert value to avro data: cannot decode textual record "com.example.AppLog": cannot decode textual map: cannot determine codec: "severity"
```
{:.no-copy-code}

### Consume the validated messages

Consume the messages from the `app_logs` topic to verify that only the valid Avro message was accepted. The `--print-schema` flag displays the Avro schema used for deserialization:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C avro-cluster.yaml --context vc consume app_logs --from-beginning --exit --print-schema
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The output shows the valid message that passed schema validation, along with its Avro schema:

```shell
##{"type":"record","name":"AppLog","namespace":"com.example","fields":[{"name":"level","type":"string"},{"name":"message","type":"string"}]}#1#{"level":"info","message":"Application started"}
```
{:.no-copy-code}

The Schema Validation policy ensures that only properly serialized Avro messages that match the registered schema reach your Kafka brokers.
