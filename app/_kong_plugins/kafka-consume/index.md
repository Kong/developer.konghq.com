---
title: 'Kafka Consume'
name: 'Kafka Consume'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Consume messages from Kafka topics and make them available through HTTP endpoints'


products:
    - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.10'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: kafka-consume.png

categories:
   - traffic-control

tags:
  - traffic-control
  - events
  - kafka

search_aliases:
  - events
  - event gateway

related_resources:
  - text: Kafka Log plugin
    url: /plugins/kafka-log/
  - text: Kafka Upstream plugin
    url: /plugins/kafka-upstream/
  - text: Confluent plugin
    url: /plugins/confluent/
  - text: Confluent Consume plugin
    url: /plugins/confluent-consume/
---

This plugin consumes messages from [Apache Kafka](https://kafka.apache.org/) topics and makes them available through HTTP endpoints.
For more information, see [Kafka topics](https://kafka.apache.org/documentation/#intro_concepts_and_terms).

{% include /plugins/confluent-kafka-consume/limitations.md %}

Kong also provides Kafka plugins for publishing messages:
* [Kafka Log](/plugins/kafka-log/)
* [Kafka Upstream](/plugins/kafka-upstream/)

## Implementation details

{% include /plugins/confluent-kafka-consume/implementation-details.md slug=page.slug %}


## WebSocket mode {% new_in 3.11 %}

In `websocket` mode, the plugin maintains a bi-directional WebSocket connection with the client. This allows:
* Continuous delivery of Kafka messages to the client
* Optional client acknowledgments (`client-acks`) for each message or batch, enabling `at-least-once` delivery semantics
* Real-time message flow without the limitations of HTTP polling

To consume messages via WebSocket:
1. Establish a WebSocket connection to the route where the plugin is enabled and `mode` is set to `websocket`
1. Optionally, send acknowledgment messages to indicate successful processing
1. Messages will be streamed as text frames in JSON format

This mode provides parity with HTTP-based consumption, including support for:
* Message keys
* Topic filtering
* Kafka authentication and TLS
* Auto or manual offset commits

## Message delivery guarantees

{% include /plugins/confluent-kafka-consume/message-delivery.md %}

## Schema registry support {% new_in 3.11 %}

{% include_cached /plugins/confluent-kafka-consume/schema-registry.md name=page.name slug=page.slug workflow='consumer' %}

## Migration Considerations for Kong 3.12 {% new_in 3.12 %}

**Important:**
The `kafka-consume` plugin **no longer supports scoping to a Service**.

- **Fresh installations**
  If you try to scope this plugin to a Service on a fresh {{site.base_gateway}} instance, a *schema violation* error will be returned.

- **Upgrading existing configurations**

  **Traditional mode**
  - During startup, Kong will log an *error-level* message if a `kafka-consume` plugin scoped to a Service is detected.
  - Kong will still start successfully, but the plugin configuration **must be updated after startup**.
  - Until the configuration is updated, requests to the previous plugin URL will continue to be forwarded to the upstream Service, and responses will be returned to the downstream client as before.

  **DB-less mode**
  - If the declarative configuration file contains a `kafka-consume` plugin scoped to a Service, Kong will **fail to start**.
  - In this case, you must **update the declarative configuration** before restarting Kong.

  **Hybrid mode**
  - If such a plugin exists in PostgreSQL, upgrading and restarting the **Control Plane (CP)** will succeed.
  - However, before updating the **Data Plane (DP)**, you must update the plugin configuration.
  - Otherwise, once the DP is upgraded and restarted, it will fail to sync the configuration due to validation errors.
