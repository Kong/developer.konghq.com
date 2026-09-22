---
title: Enforce rules on Kafka requests with {{site.event_gateway}}
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/enforce-kafka-request-rules/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: "Reject Kafka requests that break platform conventions, like topic naming, partition limits, and producer acknowledgements."

tldr:
  q: How can I enforce conventions on Kafka requests that Kafka ACLs can't express?
  a: |
    1. Create a Request Rule Validator cluster policy on your virtual cluster.
    1. Add rules that describe the valid state of a request, for example a topic naming convention or a partition limit.
    1. Try to break the rules. {{site.event_gateway}} rejects the requests.

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
  - text: Request Rule Validator policy
    url: /event-gateway/policies/request-rule-validator/
  - text: Expressions reference
    url: /event-gateway/expressions/
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Kafka ACL policy
    url: /event-gateway/policies/acl/
  - text: "{{site.event_gateway_short}} Control Plane API"
    url: /api/konnect/event-gateway/
---

## Overview

In this guide, you'll learn how to reject Kafka requests that break your platform conventions.

Kafka [ACLs](/event-gateway/policies/acl/) control who can do what, but they can't read the content of a request.
They can say who may create topics, but not which names or partition counts are allowed.
The Request Rule Validator policy checks the content of each request. Every rule is a boolean expression over the
request fields, and {{site.event_gateway}} rejects requests that break a rule.

We'll act as a platform team that runs a shared Kafka cluster. Teams create topics and produce records through a
virtual cluster, and the platform enforces three rules:

<!--vale off-->
{% table %}
columns:
  - title: Kafka request
    key: request
  - title: Rule
    key: rule
rows:
  - request: "`CreateTopics`"
    rule: Topic names must start with the team prefix `team-a.`
  - request: "`CreateTopics`"
    rule: A topic can have at most 5 partitions
  - request: "`Produce`"
    rule: Producers must require acknowledgements from all in-sync replicas, so no record is lost if a broker fails
{% endtable %}
<!--vale on-->

The Request Rule Validator is a cluster policy, which means it runs on all Kafka API commands that pass through the
virtual cluster, before the requests reach the backend cluster:

{% mermaid %}
flowchart LR
    P[kafkactl] --> RR

    subgraph GW [Event Gateway virtual cluster]
        RR[Request Rule<br/>Validator]
    end

    RR -->|valid| K[Kafka<br/>broker]
    RR -.->|rule violated| X[Request<br/>rejected]
{% endmermaid %}

{:.info}
> Every rule carries a `description`. When a request violates the rule, {{site.event_gateway}} returns this text in the
error, so clients learn why the request was rejected.

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

## Create the Request Rule Validator policy

Create a Request Rule Validator cluster policy on the virtual cluster.
The `requests` array groups rules by Kafka request type, and this guide configures two types:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/cluster-policies
status_code: 201
method: POST
body:
  type: request_rule_validator
  name: topic_governance
  config:
    requests:
      - type: create_topics
        rules:
          - description: Topic names must start with the team prefix team-a.
            rule: topic.name.startsWith("team-a.")
            action: reject
          - description: Topics can have at most 5 partitions
            rule: topic.num_partitions <= 5
            action: reject
      - type: produce
        rules:
          - description: Producers must require acknowledgements from all in-sync replicas
            rule: produce.acks == -1
            action: reject
extract_body:
  - name: id
    variable: POLICY_ID
capture:
  - variable: POLICY_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

In this configuration:
* Each rule is a boolean expression that describes the valid state of a request. The action runs when the expression
evaluates to `false`. An expression that can't be evaluated, for example because a value has an unexpected format,
also counts as `false`.
* `topic.name.startsWith("team-a.")` and `topic.num_partitions <= 5` are evaluated against each topic in a
`CreateTopics` request. A single request can create several topics, and each topic is checked independently.
* `produce.acks == -1` is evaluated against every `Produce` request. The value `-1` means the producer waits for
acknowledgements from all in-sync replicas.
* `action: reject` fails the request with the `POLICY_VIOLATION` error code. The alternative is `passthrough`, which
lets the request continue and only logs the violation. Use `passthrough` to test a rule before you start enforcing it.

## Configure kafkactl

Create a kafkactl configuration with a `vc` context that connects through the virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  cat <<EOF > kafkactl.yaml
  contexts:
    vc:
      brokers:
        - localhost:19092
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Create a topic

Create the `team-a.orders` topic with 3 partitions. The request matches both `create_topics` rules, so the
{{site.event_gateway_short}} forwards it to the backend cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc create topic team-a.orders --partitions 3
expected:
  message: "topic created: team-a.orders"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

kafkactl prints the name of the created topic:

```shell
topic created: team-a.orders
```
{:.no-copy-code}

## Validate

### Violate the naming rule

Try to create a topic whose name doesn't start with `team-a.`:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc create topic team-b.orders --partitions 3
expected:
  message: "Topic names must start with the team prefix team-a."
  return_code: 1
render_output: false
{% endvalidation %}
<!--vale on-->

The request fails with the `POLICY_VIOLATION` error code, and the error contains the rule description:

```shell
failed to create topic: kafka server: Request parameters do not satisfy the configured policy - Topic names must start with the team prefix team-a.
```
{:.no-copy-code}

### Violate the partition limit

Try to create a topic with more than 5 partitions:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc create topic team-a.big --partitions 50
expected:
  message: "Topics can have at most 5 partitions"
  return_code: 1
render_output: false
{% endvalidation %}
<!--vale on-->

```shell
failed to create topic: kafka server: Request parameters do not satisfy the configured policy - Topics can have at most 5 partitions
```
{:.no-copy-code}

### Reject records produced without full acknowledgement

Produce a record and require an acknowledgement from the leader only, which violates the `produce` rule:

<!--vale off-->
{% validation custom-command %}
command: |
  echo '{"order":{"id":"1","item":"coffee","qty":2}}' | kafkactl -C kafkactl.yaml --context vc produce team-a.orders --required-acks WaitForLocal
expected:
  message: "Request parameters do not satisfy the configured policy"
  return_code: 1
render_output: false
{% endvalidation %}
<!--vale on-->

kafkactl prints `1 messages produced`, but that line is misleading. The produce request was rejected with the
`POLICY_VIOLATION` error code, kafkactl exits with code 1, and the record never reaches the backend cluster:

```shell
1 messages produced
Failed to produce message: kafka server: Request parameters do not satisfy the configured policy
```
{:.no-copy-code}

Unlike topic creation, the error doesn't contain the rule description, because the `Produce` response doesn't
carry it. The record never reaches the backend cluster.

### Produce with full acknowledgement

Produce a different record with `--required-acks WaitForAll`, which maps to the value `-1` that the rule requires:

<!--vale off-->
{% validation custom-command %}
command: |
  echo '{"order":{"id":"2","item":"tea","qty":1}}' | kafkactl -C kafkactl.yaml --context vc produce team-a.orders --required-acks WaitForAll
expected:
  message: "1 messages produced"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Consume the topic to confirm that only the compliant record was stored:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc consume team-a.orders --from-beginning --exit
expected:
  message: '"item":"tea"'
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

```shell
{"order":{"id":"2","item":"tea","qty":1}}
```
{:.no-copy-code}
