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

related_resources:
  - text: Confluent plugin
    url: /plugins/confluent/
  - text: Kafka Consume plugin
    url: /plugins/kafka-consume/
---

This plugin consumes messages from [Confluent Cloud](https://confluent.io/cloud) Kafka topics and makes them available through HTTP endpoints.
For more information, see the [Confluent Cloud documentation](https://docs.confluent.io/).

{% include /plugins/confluent-kafka-consume/limitations.md %}

Kong also provides a [plugin for publishing messages to Confluent Cloud](/plugins/confluent/).

## Implementation details

{% include /plugins/confluent-kafka-consume/implementation-details.md %}

## Message delivery guarantees

{% include /plugins/confluent-kafka-consume/message-delivery.md %}