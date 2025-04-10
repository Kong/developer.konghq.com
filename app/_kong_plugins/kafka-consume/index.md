---
title: 'Kafka Consume'
name: 'Kafka Consume'

content_type: plugin

publisher: kong-inc
description: 'Consume messages from Kafka topics and make them available through HTTP endpoints'


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

icon: kafka-consume.png

categories:
   - traffic-control

related_resources:
  - text: Kafka Log plugin
    url: /plugins/kafka-log/
  - text: Kafka Upstream plugin
    url: /plugins/kafka-upstream/
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

{% include /plugins/confluent-kafka-consume/implementation-details.md %}

## Message delivery guarantees

{% include /plugins/confluent-kafka-consume/message-delivery.md %}
