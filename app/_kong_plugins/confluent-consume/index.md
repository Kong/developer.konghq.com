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
  - protocol mediation

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

{% include /plugins/confluent-kafka-consume/implementation-details.md %}

## Message delivery guarantees

{% include /plugins/confluent-kafka-consume/message-delivery.md %}

## Schema registry support {% new_in 3.11 %}

{% include_cached /plugins/confluent-kafka-consume/schema-registry.md name=page.name slug=page.slug workflow='consumer' %}