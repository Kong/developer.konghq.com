---
title: Mask Kafka message fields selected by schema registry tags with {{site.event_gateway}}
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/mask-kafka-message-fields-from-schema/

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

description: "Redact fields tagged in a Confluent Schema Registry, so masking follows schema evolution without policy changes."

tldr:
  q: How can I mask Kafka message fields based on tags stored in a schema registry?
  a: |
    1. Register an Avro schema in a Confluent Schema Registry and tag the sensitive fields.
    1. Create a Schema Validation policy (consume phase) to parse records against the registry.
    1. Nest a Mask Fields policy that computes the fields to mask from the schema tags.

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
  - text: Mask sensitive fields in Kafka messages
    url: /event-gateway/mask-kafka-message-fields/
  - text: Schema Validation policy
    url: /event-gateway/policies/schema-validation-consume/
  - text: Schema Registry entity
    url: /event-gateway/entities/schema-registry/
  - text: Validate Avro messages with Confluent Schema Registry
    url: /event-gateway/validate-avro-messages-with-schema-registry/
---

## Overview

In this guide, you'll learn how to redact fields of Kafka messages based on tags stored in a Confluent Schema Registry.

Instead of listing field paths in the policy, you tag the sensitive fields in the schema itself. The {{site.event_gateway_short}} reads
the tags of each record's schema and masks every tagged field. When the schema evolves and a new field gets tagged,
the {{site.event_gateway_short}} masks it without any policy change.

We'll use a `customers` topic that holds customer records with personal data. Producers write complete records to Kafka.
Consumers that connect through the virtual cluster receive the same records with the tagged fields redacted, so the raw
data stays intact in the broker.

Here's how the data flows through the system:

{% mermaid %}
flowchart LR
    P[Producer] --> K[Kafka <br>Broker<br/>raw records]
    SR[(Schema Registry<br/>fields tagged PII)] -.-> SV

    subgraph consume [Event Gateway Consume policy chain]
        SV[Schema Validation<br/>Confluent Schema Registry] --> MF[Mask Fields<br/>paths from PII tags]
    end

    K --> SV
    MF --> CO[Consumer<br/>masked records]
{% endmermaid %}

{:.info}
> The Mask Fields policy only works on `string` fields. A field that doesn't exist is ignored.
> A field that isn't a string is a policy failure, handled by the `failure_mode` setting.

## Create a backend cluster

{% include knep/create-backend-cluster.md insecure=true %}

## Create a virtual cluster

Create a virtual cluster that consumers connect to:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: customers_vc
  destination:
    id: $BACKEND_CLUSTER_ID
  dns_label: customers
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
  name: customers_listener
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
  name: forward_to_customers_vc
  config:
    type: port_mapping
    advertised_host: localhost
    destination:
      id: $VIRTUAL_CLUSTER_ID
{% endkonnect_api_request %}
<!--vale on-->

## Create a Schema Registry entity

Create a [Schema Registry](/event-gateway/entities/schema-registry/) entity that points to the Confluent Schema Registry
running locally. Since the {{site.event_gateway_short}} data plane runs in the same Docker network as the Schema Registry,
use the container hostname `schema-registry`:

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

## Register an Avro schema with PII tags

Register an Avro schema for the `customers` topic in the Confluent Schema Registry.
The schema defines four fields: `name`, `email`, `ssn`, and `city`.

Alongside the schema, the registration body carries a `metadata` block that tags the three personal fields as `PII`:

<!--vale off-->
{% validation custom-command %}
command: |
  cat <<EOF > schema.json
  {
    "schemaType": "AVRO",
    "schema": "{\"type\": \"record\", \"name\": \"Customer\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}, {\"name\": \"email\", \"type\": \"string\"}, {\"name\": \"ssn\", \"type\": \"string\"}, {\"name\": \"city\", \"type\": \"string\"}]}",
    "metadata": {
      "properties": {"owner": "compliance-team"},
      "tags": {
        "name": ["PII"],
        "email": ["PII"],
        "ssn": ["PII"]
      }
    }
  }
  EOF
  curl -sS --fail -X POST http://localhost:8081/subjects/customers-value/versions \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    -d @schema.json
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The subject name `customers-value` follows Confluent's default [TopicNameStrategy](https://docs.confluent.io/platform/current/schema-registry/fundamentals/serdes-develop/index.html#subject-name-strategy), which uses the pattern `<topic>-value`.

Each key of `tags` is a field path in the record, and each value lists the tags carried by that field.
Use the same path that the field has in the message, for example `profile.ssn` for a field nested under `profile`.
The {{site.event_gateway_short}} passes the tag keys through as-is, so a key that doesn't match a field path in the record is never masked.

## Create a Schema Validation policy

Create a [Schema Validation policy](/event-gateway/policies/schema-validation-consume/) that parses Avro records
against the Confluent Schema Registry during the consume phase.
The Mask Fields policy needs a parsed record and the schema tags, so it must be nested under this policy:

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
    validate_value: true
    failure_mode: skip
extract_body:
  - name: id
    variable: SCHEMA_VALIDATION_POLICY_ID
capture:
  - variable: SCHEMA_VALIDATION_POLICY_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

The `validate_value: true` setting validates the record value against the schema, and `failure_mode: skip` means
a record that can't be decoded or doesn't conform to the schema is never delivered to the consumer.
This fails closed: a record the {{site.event_gateway_short}} can't parse also can't be masked, so it must not reach the client.

## Create a Mask Fields policy

Create the Mask Fields policy nested under the Schema Validation policy.
Instead of static paths, the `paths` field holds an expression that reads the `PII` tag from the record's schema metadata
and returns the tagged field paths:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/consume-policies
status_code: 201
method: POST
body:
  type: mask_fields
  name: mask_pii_from_schema
  parent_policy_id: $SCHEMA_VALIDATION_POLICY_ID
  config:
    failure_mode: skip
    mask_fields:
      - paths: 'record.value.schema.metadata.tags["PII"]'
        strategy:
          type: replace
          replace:
            phrase: REDACTED
{% endkonnect_api_request %}
<!--vale on-->

`record.value.schema.metadata.tags` is a map from tag name to the field paths carrying that tag.
It's populated by the parent Schema Validation policy, so the expression returns `["name", "email", "ssn"]` for
records that use the registered schema. The strategy applies to all returned paths, so every tagged field
is replaced with `REDACTED`. The untagged `city` field passes through unchanged.

The policy uses `failure_mode: skip`, so a record the policy can't mask is never delivered.
For a redaction policy, choose between `skip` and `error` to not let unmasked data through.
Prefer `skip`, because `error` blocks the whole batch and leaves consumers stuck on the problematic offset
until someone intervenes.

## Configure kafkactl

Create a kafkactl configuration with a `direct` context that connects to Kafka, and a `vc` context that connects
through the virtual cluster. Both contexts point to the Schema Registry, so kafkactl can serialize records to Avro
and deserialize them for display:

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
      schemaRegistry:
        url: http://localhost:8081
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Create a topic and produce records

Create the `customers` topic:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context direct create topic customers
expected:
  message: "topic created: customers"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Produce two customer records through the virtual cluster.
kafkactl serializes them to Avro using the schema from the registry:

<!--vale off-->
{% validation custom-command %}
command: |
  echo '{"name":"John Doe","email":"john.doe@example.com","ssn":"098-76-5432","city":"San Francisco"}
  {"name":"Maria Silva","email":"maria.silva@example.com","ssn":"123-45-6789","city":"Boston"}' | kafkactl -C kafkactl.yaml --context vc produce customers
expected:
  message: "2 messages produced"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Validate

### Consume directly from Kafka

Consume the records straight from the broker to confirm that Kafka stores them unchanged:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context direct consume customers --from-beginning --exit
expected:
  message: '"ssn":"098-76-5432"'
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Both records come back with the personal data in plaintext:

```json
{"name":"John Doe","email":"john.doe@example.com","ssn":"098-76-5432","city":"San Francisco"}
{"name":"Maria Silva","email":"maria.silva@example.com","ssn":"123-45-6789","city":"Boston"}
```
{:.no-copy-code}

### Consume through the virtual cluster

Consume the same records through the virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc consume customers --from-beginning --exit
expected:
  message: '"ssn":"REDACTED"'
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The tagged fields are redacted, and `city` is untouched:

```json
{"name":"REDACTED","email":"REDACTED","ssn":"REDACTED","city":"San Francisco"}
{"name":"REDACTED","email":"REDACTED","ssn":"REDACTED","city":"Boston"}
```
{:.no-copy-code}
