---
title: Filter Kafka records by classification headers
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/filter-records-by-classification/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: "Classify records at produce time and filter them at consume time based on user identity."

tldr:
  q: How can I filter Kafka records based on user identity?
  a: |
    1. Create a Schema Validation policy (produce phase) to parse JSON records.
    1. Nest a Modify Headers policy to classify records with a header based on content.
    1. Create a Skip Records policy (consume phase) to filter records based on the header and principal name.

tools:
    - konnect-api

prereqs:
  inline:
    - title: Install kafkactl
      position: before
      include_content: knep/kafkactl
    - title: Define a context for kafkactl
      position: before
      include_content: knep/kafka-context
    - title: Start a local Kafka cluster
      position: before
      include_content: knep/docker-compose-start

cleanup:
  inline:
    - title: Clean up {{site.event_gateway}} resources
      include_content: cleanup/products/event-gateway
      icon_url: /assets/icons/gateway.svg

related_resources:
  - text: Modify Headers policy
    url: /event-gateway/policies/modify-headers/
  - text: Skip Records policy
    url: /event-gateway/policies/skip-record/
  - text: Schema Validation policy
    url: /event-gateway/policies/schema-validation-produce/
  - text: Expressions language
    url: /event-gateway/expressions/
---

## Overview

In this guide, you'll learn how to classify Kafka records at produce time and filter them at consume time based on user identity.

We'll use a logging scenario where an `app_logs` topic contains log entries with different severity levels, aimed at two different groups of users:
* The SRE team needs debug and trace logs, which are verbose and useful for troubleshooting issues.
* Regular developers only need info, warn, and error logs.

The approach uses two policies:
1. **Produce phase**: A [Schema Validation policy](/event-gateway/policies/schema-validation-produce/) parses JSON records, and a nested [Modify Headers policy](/event-gateway/policies/modify-headers/) adds an `x-internal: true` header to debug and trace logs.
2. **Consume phase**: A [Skip Records policy](/event-gateway/policies/skip-record/) filters out internal logs for users who aren't on the SRE team.

Here's how the data flows through the system:

{% mermaid %}
flowchart LR
    P[Producer] --> SV

    subgraph produce [Event Gateway Produce policy chain]
        SV[Schema <br>Validation<br/>Parse JSON] --> MH{Modify Headers<br/>level <br>= debug/trace?}
        MH -->|Yes| H1[Add <br>x-internal: true]
        MH -->|No| H2[No header <br>added]
    end

    subgraph consume [Event Gateway Consume policy chain]
        SR{Skip Records<br/>x-internal = true<br/>AND<br> user ≠ sre_user?}
        SR -->|Yes| DROP[Record <br>skipped]
        SR -->|No| C[Send to <br>consumer]
    end

    H1 --> K[Kafka <br>Broker]
    H2 --> K
    K --> SR
    C --> CO[Consumer]
{% endmermaid %}

{:.success}
> **Performance tip**: Classifying records at produce time is more efficient than at consume time. Parsing JSON once during production avoids repeated deserialization for each consumer group.

## Create a Kafka topic

Create an `app_logs` topic in the Kafka cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context direct create topic app_logs
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Create a backend cluster

{% include knep/create-backend-cluster.md %}

## Create a virtual cluster

Create a virtual cluster with two users (`principals`):
- `sre_user`: Can see all logs including debug and trace
- `dev_user`: Only sees info, warn, and error logs

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
    - type: sasl_plain
      mediation: terminate
      principals:
        - username: sre_user
          password: sre_password
        - username: dev_user
          password: dev_password
  acl_mode: passthrough
extract_body:
  - name: id
    variable: VIRTUAL_CLUSTER_ID
capture: VIRTUAL_CLUSTER_ID
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
capture: LISTENER_ID
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

## Create a Schema Validation policy

Create a [Schema Validation policy](/event-gateway/policies/schema-validation-produce/) that parses JSON records during the produce phase. This allows nested policies to access record content:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/produce-policies
status_code: 201
method: POST
body:
  type: schema_validation
  name: parse_json_logs
  config:
    type: json
    value_validation_action: reject
extract_body:
  - name: id
    variable: SCHEMA_VALIDATION_POLICY_ID
capture: SCHEMA_VALIDATION_POLICY_ID
jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

The `value_validation_action: reject` setting ensures data quality: if a producer sends a record that isn't valid JSON, the entire batch containing that record is rejected and the producer receives an error.

## Create a Modify Headers policy to classify logs

Create a [Modify Headers policy](/event-gateway/policies/modify-headers/) nested under the Schema Validation policy. This policy adds an `x-internal: true` header when the log level is `debug` or `trace`:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/produce-policies
status_code: 201
method: POST
body:
  type: modify_headers
  name: classify_internal_logs
  parent_policy_id: $SCHEMA_VALIDATION_POLICY_ID
  condition: "record.value.content[\"level\"] == \"debug\" || record.value.content[\"level\"] == \"trace\""
  config:
    actions:
      - op: set
        key: x-internal
        value: "true"
{% endkonnect_api_request %}
<!--vale on-->

## Create a Skip Records policy to filter logs

Create a [Skip Records policy](/event-gateway/policies/skip-record/) that filters out internal logs for non-SRE users during the consume phase:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/consume-policies
status_code: 201
method: POST
body:
  type: skip_record
  name: filter_internal_logs
  condition: "record.headers[\"x-internal\"] == \"true\" && context.auth.principal.name != \"sre_user\""
{% endkonnect_api_request %}
<!--vale on-->

## Configure kafkactl

Create a kafkactl configuration with contexts for both users:

<!--vale off-->
{% validation custom-command %}
command: |
  cat <<EOF > logs-cluster.yaml
  contexts:
    sre:
      brokers:
        - localhost:19092
      sasl:
        enabled: true
        username: sre_user
        password: sre_password
    dev:
      brokers:
        - localhost:19092
      sasl:
        enabled: true
        username: dev_user
        password: dev_password
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Validate
Now, let's validate that you can produce and consume log records as the two different user profiles.
### Produce log records

Produce log records with different severity levels:

<!--vale off-->
{% validation custom-command %}
command: |
  echo '{"level": "info", "message": "Application started"}
  {"level": "debug", "message": "Loading configuration from /etc/app/config.yaml"}
  {"level": "error", "message": "Failed to connect to database"}
  {"level": "trace", "message": "Entering function processRequest()"}
  {"level": "warn", "message": "High memory usage detected"}' | kafkactl -C logs-cluster.yaml --context sre produce app_logs
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

We've produced 5 log records:
- 2 internal logs (`debug`, `trace`) - will be classified with `x-internal: true`
- 3 regular logs (`info`, `error`, `warn`) - no classification header

### Consume as SRE user

Consume logs as the SRE user. You should see all 5 records:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C logs-cluster.yaml --context sre consume app_logs --from-beginning --exit --print-headers
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The output includes all logs, with `x-internal:true` header on debug and trace entries:

```sh
#{"level": "info", "message": "Application started"}
x-internal:true#{"level": "debug", "message": "Loading configuration from /etc/app/config.yaml"}
#{"level": "error", "message": "Failed to connect to database"}
x-internal:true#{"level": "trace", "message": "Entering function processRequest()"}
#{"level": "warn", "message": "High memory usage detected"}
```
{:.no-copy-code}

### Consume as developer user

Consume logs as the developer user. You should only see 3 records (debug and trace logs are filtered out):

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C logs-cluster.yaml --context dev consume app_logs --from-beginning --exit --print-headers
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The output excludes debug and trace logs:

```sh
#{"level": "info", "message": "Application started"}
#{"level": "error", "message": "Failed to connect to database"}
#{"level": "warn", "message": "High memory usage detected"}
```
{:.no-copy-code}

The developer user only sees the logs relevant to their work, while the verbose debug and trace logs are automatically filtered out.
