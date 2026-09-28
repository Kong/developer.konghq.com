---
title: Encrypt Kafka message fields selected by schema registry tags with {{site.event_gateway}}
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/encrypt-kafka-message-fields-from-schema/

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

description: "Encrypt fields tagged in a Confluent Schema Registry, so encryption follows schema evolution without policy changes."

tldr:
  q: How can I encrypt Kafka message fields based on tags stored in a schema registry?
  a: |
    1. Register an Avro schema in a Confluent Schema Registry and tag the sensitive fields.
    1. Create a static key.
    1. Create a Schema Validation produce policy with a nested Encrypt Fields policy that computes the fields to encrypt from the schema tags.
    1. Create a Schema Validation consume policy with a nested Decrypt Fields policy that uses the same expression.

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
  - text: Mask Kafka message fields selected by schema registry tags
    url: /event-gateway/mask-kafka-message-fields-from-schema/
  - text: Encrypt and decrypt Kafka fields in message values
    url: /event-gateway/encrypt-kafka-message-fields-with-event-gateway/
  - text: Encrypt Fields policy
    url: /event-gateway/policies/encrypt-fields/
  - text: Decrypt Fields policy
    url: /event-gateway/policies/decrypt-fields/
  - text: Schema Registry entity
    url: /event-gateway/entities/schema-registry/
  - text: Static keys
    url: /event-gateway/entities/static-key/
---

## Overview

In this guide, you'll learn how to encrypt fields of Kafka messages based on tags stored in a Confluent Schema Registry.

Instead of listing field paths in the policies, you tag the sensitive fields in the schema itself. The {{site.event_gateway_short}} reads
the tags of each record's schema, encrypts every tagged field before the record reaches Kafka, and decrypts the same fields
for consumers. When the schema evolves and a new field gets tagged, the {{site.event_gateway_short}} encrypts it without any policy change.

We'll use a `customers` topic that holds customer records with personal data. Producers and consumers that connect through
the virtual cluster work with plaintext records, while the broker only stores the tagged fields in encrypted form.
Anyone with direct access to the broker or to its backups can't read the personal data.

Here's how the data flows through the system:

<!--vale off-->
{% mermaid %}
sequenceDiagram
  autonumber
  participant producer as Producer
  participant egw as {{site.event_gateway_short}}
  participant sr as Schema Registry
  participant broker as Kafka broker
  participant consumer as Consumer

  producer->>egw: produce record
  egw->>sr: get schema and PII tags
  egw->>egw: encrypt tagged fields
  egw->>broker: store record with encrypted fields
  consumer->>egw: consume request
  egw->>broker: fetch records
  broker->>egw: return records with encrypted fields
  egw->>sr: get schema and PII tags
  egw->>egw: decrypt tagged fields
  egw->>consumer: return plaintext record
{% endmermaid %}
<!--vale on-->

{:.info}
> The Encrypt Fields policy only works on `string` fields. A field that doesn't exist is ignored.
> A field that isn't a string is a policy failure, handled by the `failure_mode` setting.

## Create a backend cluster

{% include knep/create-backend-cluster.md insecure=true %}

## Create a virtual cluster

Create a virtual cluster that clients connect to:

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
{% endkonnect_api_request %}
<!--vale on-->

## Create a static key

Use OpenSSL to generate a 256-bit key that encrypts and decrypts the fields:

<!--vale off-->
{% env_variables %}
MY_KEY: $(openssl rand -base64 32)
{% endenv_variables %}
<!--vale on-->

Create a [static key](/event-gateway/entities/static-key/) named `my-key` with the generated key:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/static-keys
status_code: 201
method: POST
body:
  name: my-key
  value: $MY_KEY
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
The {{site.event_gateway_short}} passes the tag keys through as-is, so a key that doesn't match a field path in the record is never encrypted.

## Encrypt tagged fields on produce

Create a [Schema Validation policy](/event-gateway/policies/schema-validation-produce/) that parses Avro records
against the Confluent Schema Registry during the produce phase.
The Encrypt Fields policy needs a parsed record and the schema tags, so it must be nested under this policy:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/produce-policies
status_code: 201
method: POST
body:
  type: schema_validation
  name: validate_avro_produce
  config:
    type: confluent_schema_registry
    schema_registry:
      name: local-schema-registry
    validate_value: true
    failure_mode: reject
extract_body:
  - name: id
    variable: PRODUCE_SCHEMA_VALIDATION_ID
capture:
  - variable: PRODUCE_SCHEMA_VALIDATION_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

The `failure_mode: reject` setting rejects a batch with a record that can't be decoded or doesn't conform to the schema.
A record the {{site.event_gateway_short}} can't parse also can't be encrypted, so it must not reach the broker.

Create the [Encrypt Fields policy](/event-gateway/policies/encrypt-fields/) nested under the Schema Validation policy.
Instead of static paths, the `paths` field holds an expression that reads the `PII` tag from the record's schema metadata
and returns the tagged field paths:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/produce-policies
status_code: 201
method: POST
body:
  type: encrypt_fields
  name: encrypt_pii_from_schema
  parent_policy_id: $PRODUCE_SCHEMA_VALIDATION_ID
  config:
    failure_mode: reject
    encrypt_fields:
      - paths: 'record.value.schema.metadata.tags["PII"]'
        encryption_key:
          type: static
          key:
            name: my-key
{% endkonnect_api_request %}
<!--vale on-->

`record.value.schema.metadata.tags` is a map from tag name to the field paths carrying that tag.
It's populated by the parent Schema Validation policy, so the expression returns `["name", "email", "ssn"]` for
records that use the registered schema. The policy encrypts all returned paths with `my-key`.
The untagged `city` field is stored in plaintext.

The policy uses `failure_mode: reject`, so a record the policy can't encrypt never reaches the broker in plaintext.

## Decrypt tagged fields on consume

Create a [Schema Validation policy](/event-gateway/policies/schema-validation-consume/) that parses Avro records
during the consume phase:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/consume-policies
status_code: 201
method: POST
body:
  type: schema_validation
  name: validate_avro_consume
  config:
    type: confluent_schema_registry
    schema_registry:
      name: local-schema-registry
    validate_value: true
    failure_mode: skip
extract_body:
  - name: id
    variable: CONSUME_SCHEMA_VALIDATION_ID
capture:
  - variable: CONSUME_SCHEMA_VALIDATION_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Create the [Decrypt Fields policy](/event-gateway/policies/decrypt-fields/) nested under the Schema Validation policy.
It uses the same expression, so it decrypts the same fields that the Encrypt Fields policy encrypted:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/consume-policies
status_code: 201
method: POST
body:
  type: decrypt_fields
  name: decrypt_pii_from_schema
  parent_policy_id: $CONSUME_SCHEMA_VALIDATION_ID
  config:
    failure_mode: mark
    key_sources:
      - type: static
    decrypt_fields:
      paths: 'record.value.schema.metadata.tags["PII"]'
{% endkonnect_api_request %}
<!--vale on-->

The Decrypt Fields policy reads the key reference from the `kong/enc` header that the Encrypt Fields policy adds to each record,
and looks up the key in the static keys.

The policy uses `failure_mode: mark`. A failed decryption never exposes plaintext, so the record is delivered with
the fields still encrypted and a `kong/policy-failure-<id>` header that explains the failure.

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

Consume the records straight from the broker, with their headers, to confirm that Kafka stores the tagged fields encrypted:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context direct consume customers --from-beginning --exit --print-headers
expected:
  message: 'static://'
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The `name`, `email`, and `ssn` fields are encrypted, and `city` is in plaintext.
Each record carries a `kong/enc` header that identifies the static key by its ID:

```shell
kong/enc:  -static://<static-key-id>#{"name":"AOrXosB8U5J2\/pSY4WSJFCe\/DJCW5noJ0F+H1fg\/CY6y3F2WxA==","email":"ABIVUSkoQFyoECpFYkf6zYPUZOgW7Dw\/Nee8XKeDNHuODq7DjLAou4cXtEb4tRCANw==","ssn":"ALVdciwDnNQHwH3YdEHmDGGqDhkNwXfztmWjsOT34Ql0OdxzXkhq0w==","city":"San Francisco"}
kong/enc:  -static://<static-key-id>#{"name":"AFvtXJdxtNR+GNIJ8DHCsd6mYQksB3maNBiPsz2zrxoTBoDh\/0NsSw==","email":"AJTOt1CUPeATneZNxUMKCqxIUS0S+zryDXFs6G\/lYv65zmLeLCXqDmq2dI8MDh5WYWxbGQ==","ssn":"AOIAev91oOpQ9YVotwe8bm5ZHVVpfTIhTwjDeoEjjkJJdpuchQ6f2g==","city":"Boston"}
```
{:.no-copy-code}

### Consume through the virtual cluster

Consume the same records through the virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc consume customers --from-beginning --exit
expected:
  message: '"ssn":"098-76-5432"'
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The tagged fields are decrypted, and consumers receive the original records:

```json
{"name":"John Doe","email":"john.doe@example.com","ssn":"098-76-5432","city":"San Francisco"}
{"name":"Maria Silva","email":"maria.silva@example.com","ssn":"123-45-6789","city":"Boston"}
```
{:.no-copy-code}
