---
title: Mask sensitive fields in Kafka messages with {{site.event_gateway}}
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/mask-kafka-message-fields/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: "Redact sensitive fields of Kafka messages at consume time, so the raw data stays in the broker."

tldr:
  q: How can I hide sensitive fields from Kafka consumers without changing the stored data?
  a: |
    1. Create a Schema Validation policy (consume phase) to parse JSON records.
    1. Nest a Mask Fields policy that selects the sensitive fields and a masking strategy for each one.

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
  - text: Schema Validation policy
    url: /event-gateway/policies/schema-validation-consume/
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Encrypt and decrypt Kafka message fields
    url: /event-gateway/encrypt-kafka-message-fields-with-event-gateway/
  - text: "{{site.event_gateway_short}} Control Plane API"
    url: /api/konnect/event-gateway/
---

## Overview

In this guide, you'll learn how to redact sensitive fields of Kafka messages before they reach consumers.

We'll use a `customers` topic that holds customer records with personal data. Producers write complete records to Kafka.
Consumers that connect through the virtual cluster receive the same records with the personal fields redacted, so the raw data
stays intact in the broker and remains available to systems that are allowed to see it.

Masking runs in the consume phase, which means the stored records are never modified.
If you need the data to reach the broker already redacted, apply the same policy in the produce phase instead. That change is irreversible.

The Mask Fields policy supports three strategies, and this guide uses all of them:

<!--vale off-->
{% table %}
columns:
  - title: Strategy
    key: strategy
  - title: Description
    key: description
rows:
  - strategy: "`keep_chars`"
    description: Keeps a number of leading and trailing characters and replaces the middle with a fixed phrase.

  - strategy: "`email`"
    description: Applies a separate strategy to the local part and to the domain of an email address.

  - strategy: "`replace`"
    description: Replaces the whole value with a fixed phrase.
{% endtable %}
<!--vale on-->

Here's how the data flows through the system:

{% mermaid %}
flowchart LR
    P[Producer] --> K[Kafka <br>Broker<br/>raw records]

    subgraph consume [Event Gateway Consume policy chain]
        SV[Schema <br>Validation<br/>Parse JSON] --> MF[Mask Fields<br/>redact name,<br/>email, ssn]
    end

    K --> SV
    MF --> CO[Consumer<br/>masked records]
{% endmermaid %}

{:.info}
> The Mask Fields policy only works on `string` fields. A field that doesn't exist is ignored.
A field that isn't a string is a policy failure, handled by the `failure_mode` setting.

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

For demo purposes, we're using port mapping, which assigns each Kafka broker to a dedicated port on the {{site.event_gateway_short}}.
In production, we recommend using [SNI routing](/event-gateway/architecture/#hostname-mapping) instead.

## Create a Schema Validation policy

Create a [Schema Validation policy](/event-gateway/policies/schema-validation-consume/) that parses JSON records during the consume phase.
The Mask Fields policy needs a parsed record, so it must be nested under this policy:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/consume-policies
status_code: 201
method: POST
body:
  type: schema_validation
  name: parse_json
  config:
    type: json
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

The `failure_mode: skip` setting means a record whose value isn't valid JSON is never delivered to the consumer.
This fails closed: a record the {{site.event_gateway_short}} can't parse also can't be masked, so it must not reach the client.

## Create a Mask Fields policy

Create the Mask Fields policy nested under the Schema Validation policy.
Each entry of `mask_fields` selects a set of field paths and the strategy that redacts them:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/consume-policies
status_code: 201
method: POST
body:
  type: mask_fields
  name: mask_customer_pii
  parent_policy_id: $SCHEMA_VALIDATION_POLICY_ID
  config:
    failure_mode: skip
    mask_fields:
      - paths:
          - match: customer.ssn
        strategy:
          type: keep_chars
          keep_chars:
            first: 0
            last: 4
            phrase: "***-**-"
      - paths:
          - match: customer.email
        strategy:
          type: email
          email:
            local_part:
              type: keep_chars
              keep_chars:
                first: 1
                last: 0
                phrase: "***"
            domain:
              type: keep_all
      - paths:
          - match: customer.name
        strategy:
          type: replace
          replace:
            phrase: REDACTED
{% endkonnect_api_request %}
<!--vale on-->

In this configuration:
* `customer.ssn` keeps its last four characters, and the rest becomes `***-**-`. The phrase has a fixed length, so the masked value doesn't reveal how long the original was.
* `customer.email` keeps the first character of the local part and the whole domain, which is enough to recognize an account without exposing the address.
* `customer.name` is replaced entirely, because no part of a name is safe to show.
* `customer.city` isn't selected, so it passes through unchanged.

Both policies use `failure_mode: skip`, so a record the policy can't mask is never delivered. The alternatives are `error`, `passthrough`, and `mark`.
For a redaction policy, choose between `skip` and `error` to not let unmasked data through.
Prefer `skip`, because `error` blocks the whole batch and leaves consumers stuck on the problematic offset until someone intervenes.
Don't use `passthrough` or `mark` here, because both deliver the record with the sensitive fields still readable.

## Configure kafkactl

Create a kafkactl configuration with a `direct` context that connects to Kafka, and a `vc` context that connects through the virtual cluster:

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
    vc:
      brokers:
        - localhost:19092
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

Produce three customer records directly to Kafka, bypassing the {{site.event_gateway_short}}:

<!--vale off-->
{% validation custom-command %}
command: |
  echo '{"customer":{"name":"John Doe","email":"john.doe@example.com","ssn":"098-76-5432","city":"San Francisco"}}
  {"customer":{"name":"Maria Silva","email":"maria.silva@example.com","ssn":"123-45-6789","city":"Boston"}}
  {"customer":{"name":"Sam Poe","email":"sam.poe@example.com","ssn":987654321,"city":"Austin"}}' | kafkactl -C kafkactl.yaml --context direct produce customers
expected:
  message: "3 messages produced"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The third record holds an `ssn` that's a number instead of a string. We'll use it to show what happens when the policy can't mask a field.

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

All three records come back with the personal data in plaintext:

```json
{"customer":{"name":"John Doe","email":"john.doe@example.com","ssn":"098-76-5432","city":"San Francisco"}}
{"customer":{"name":"Maria Silva","email":"maria.silva@example.com","ssn":"123-45-6789","city":"Boston"}}
{"customer":{"name":"Sam Poe","email":"sam.poe@example.com","ssn":987654321,"city":"Austin"}}
```
{:.no-copy-code}

### Consume through the virtual cluster

Now consume the same records through the virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc consume customers --from-beginning --exit
expected:
  message: '"ssn":"***-**-5432"'
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The personal fields are redacted, and `city` is untouched:

```json
{"customer":{"name":"REDACTED","email":"j***@example.com","ssn":"***-**-5432","city":"San Francisco"}}
{"customer":{"name":"REDACTED","email":"m***@example.com","ssn":"***-**-6789","city":"Boston"}}
```
{:.no-copy-code}

Only two records arrive. The third one, whose `ssn` isn't a string, couldn't be masked, so `failure_mode: skip` dropped it
instead of delivering it with the personal data exposed.
