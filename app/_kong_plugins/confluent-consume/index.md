---
title: 'Confluent Consume'
name: 'Confluent Consume'

content_type: plugin

publisher: kong-inc
description: 'Consume messages from Confluent Cloud Kafka topics and make them available through HTTP endpoints'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.10'

on_prem:
  - hybrid
  - db-less
  - traditional
konnect_deployments:
  - hybrid
  - cloud-gateways
  - serverless

premium_partner: true

icon: confluent-consume.png

categories:
    - traffic-control

search_aliases:
  - confluent-consume
  - events
  - confluent cloud
  - kafka
---

This plugin consumes messages from [Confluent Cloud](https://confluent.io/cloud) Kafka topics and makes them available through HTTP endpoints.
For more information, see the [Confluent Cloud documentation](https://docs.confluent.io/).

{:.info}
> **Note**: This plugin has the following known limitations:
> * Message compression is not supported.
> * The message format is not customizable.

Kong also provides a [plugin for publishing messages to Confluent Cloud](/plugins/confluent/).

## Implementation details

The plugin supports two modes of operation:
* `http-get`: Consume messages via HTTP GET requests (default)
* `server-sent-events`: Stream messages using [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)

## Message delivery guarantees

When running multiple data plane nodes, there is no thread-safe behavior between nodes. In high-load scenarios, you may observe the same message being delivered multiple times across different data plane nodes

To minimize duplicate message delivery in a multi-node setup, consider:
* Using a single data plane node for consuming messages from specific topics
* Implementing idempotency handling in your consuming application
* Monitoring consumer group offsets across your data plane nodes