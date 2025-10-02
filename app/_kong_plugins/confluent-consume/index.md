---
title: 'Confluent Consume'
name: 'Confluent Consume'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Consume messages from Confluent Cloud Kafka topics and make them available through HTTP endpoints'


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

tags:
  - confluent
  - traffic-control
  
premium_partner: true

icon: confluent-consume.png

categories:
    - traffic-control

search_aliases:
  - confluent-consume
  - events
  - confluent cloud
  - kafka

related_resources:
  - text: Confluent plugin
    url: /plugins/confluent/
  - text: Kafka Consume plugin
    url: /plugins/kafka-consume/
  - text: " {{site.base_gateway}} traffic control and routing"
    url: /gateway/traffic-control-and-routing/
---

This plugin consumes messages from [Confluent Cloud](https://confluent.io/cloud) Kafka topics and makes them available through HTTP endpoints.
For more information, see the [Confluent Cloud documentation](https://docs.confluent.io/).

{% include /plugins/confluent-kafka-consume/limitations.md %}

Kong also provides a [plugin for publishing messages to Confluent Cloud](/plugins/confluent/).

## Implementation details

The plugin supports the following modes of operation:
* `http-get`: Consume messages via HTTP GET requests (default)
* `server-sent-events`: Stream messages using [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
* `websocket` {% new_in 3.12 %}: Streams messages over a [WebSocket](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API) connection

### WebSocket mode {% new_in 3.12 %}

{% include /plugins/confluent-kafka-consume/websocket.md slug=page.slug broker='Confluent Cloud' name=page.name %}

## Message delivery guarantees

{% include /plugins/confluent-kafka-consume/message-delivery.md %}

## Schema registry support {% new_in 3.11 %}

{% include_cached /plugins/confluent-kafka-consume/schema-registry.md name=page.name slug=page.slug workflow='consumer' %}

## Filter and transform messages {% new_in 3.12 %}

You can use the `config.message_by_lua_functions` parameter to specify custom Lua code that will filter or transform Kafka messages. 

For examples, see the following:
* [Transform messages with Lua custom filter code](/plugins/confluent-consume/examples/transform-messages/)
* [Filter messages with Lua custom filter code](/plugins/confluent-consume/examples/filter-messages/)