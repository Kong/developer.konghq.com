---
title: Configure topic aliases with {{site.event_gateway}}
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/configure-topic-aliases/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: "Use topic aliases to expose backend Kafka topics under user-friendly names."

tldr:
  q: How can I expose Kafka topics under different names?
  a: |
    Use topic aliases on a virtual cluster to map client-visible names to backend topic names:
    1. Create a backend cluster connected to your Kafka brokers.
    1. Create a virtual cluster with `topic_aliases` that map friendly names to backend topics.
    1. Create a listener to route traffic to the virtual cluster.
    1. Clients produce and consume using the alias names.

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

related_resources:
  - text: Productize Kafka topics with {{site.event_gateway}}
    url: /event-gateway/productize-kafka-topics/
  - text: "{{site.event_gateway_short}} Control Plane API"
    url: /api/konnect/event-gateway/
---

## Overview

Topic aliases let you expose backend Kafka topics under different, client-friendly names.
This is useful when backend topics follow internal naming conventions (like `team-alpha-orders-v2`) that you don't want to expose to consumers.

{% mermaid %}
flowchart LR
    A[Kafka client] -->|produces to 'orders'| B[{{site.event_gateway_short}}]
    B -->|resolves to 'team-alpha-orders-v2'| C[Kafka cluster]
{% endmermaid %}

## Create Kafka topics

Create the backend topics that we'll expose through aliases:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context direct create topic \
  team-alpha-orders-v2 analytics-raw-clicks
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Create a backend cluster

{% include knep/create-backend-cluster.md insecure=true %}

## Create a virtual cluster with topic aliases

Create a virtual cluster that maps friendly alias names to the backend topics:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: aliased_cluster
  dns_label: aliased
  destination:
    id: $BACKEND_CLUSTER_ID
  authentication:
    - type: anonymous
  acl_mode: passthrough
  topic_aliases:
    - alias: orders
      topic: team-alpha-orders-v2
    - alias: clicks
      topic: analytics-raw-clicks
extract_body:
  - name: id
    variable: VC_ID
capture:
  - variable: VC_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Clients connecting to this virtual cluster will see `orders` and `clicks` as topic names. The original backend names (`team-alpha-orders-v2`, `analytics-raw-clicks`) also remain accessible.

## Create a listener

Create a listener with a port forwarding policy to route traffic to the virtual cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners
status_code: 201
method: POST
body:
  name: alias_listener
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

Create the port mapping policy:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: forward_to_virtual_cluster
  name: forward_to_aliased_cluster
  config:
    type: port_mapping
    advertised_host: localhost
    destination:
      id: $VC_ID
{% endkonnect_api_request %}
<!--vale on-->

## Configure kafkactl

Create a kafkactl configuration with contexts for both direct Kafka access and the virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  cat <<EOF > alias-config.yaml
  contexts:
    direct:
      brokers:
        - localhost:9094
    vc:
      brokers:
        - localhost:19092
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Validate

### List topics through the virtual cluster

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C alias-config.yaml --context vc list topics
expected:
  return_code: 0
  message: orders
render_output: false
{% endvalidation %}

You should see both the aliases and the original backend topic names:

```sh
TOPIC                    PARTITIONS     REPLICATION FACTOR
analytics-raw-clicks     1              1
clicks                   1              1
orders                   1              1
team-alpha-orders-v2     1              1
```
{:.no-copy-code}
<!--vale on-->

### Produce via alias, consume from backend

Produce a message using the alias name `orders`:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C alias-config.yaml --context vc produce orders --value='{"id": 123, "item": "widget"}'
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Consume from the backend topic `team-alpha-orders-v2` directly to verify the message arrived:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C alias-config.yaml --context direct consume team-alpha-orders-v2 --from-beginning --exit
expected:
  return_code: 0
  message: '{"id": 123, "item": "widget"}'
render_output: false
{% endvalidation %}

You should see:

```sh
{"id": 123, "item": "widget"}
```
{:.no-copy-code}
<!--vale on-->

The message produced to the alias `orders` is stored in the backend topic `team-alpha-orders-v2`.
