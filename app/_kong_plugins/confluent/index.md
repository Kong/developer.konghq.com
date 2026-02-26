---
title: 'Confluent'
name: 'Confluent'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Transform requests into Kafka messages in a Confluent Kafka topic.'

tags:
  - kafka
  - data-streaming
  - confluent
  - transformations

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.8'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: confluent.png

categories:
  - transformations

related_resources:
  - text: Kafka Log
    url: /plugins/kafka-log/
  - text: Kafka Upstream
    url: /plugins/kafka-upstream/

search_aliases:
  - kafka
  - protocol mediation

premium_partner: true
---

With Kafka at its core, [Confluent](https://confluent.io) offers complete, fully managed, cloud-native data streaming that's available everywhere your data and applications reside. Using the Confluent plugin, you can send HTTP request data to Apache Kafka by constructing Kafka messages from incoming {{site.base_gateway}} HTTP requests.

{{site.base_gateway}} also provides Kafka Log and Kafka Upstream plugins for publishing logs and messages to an Apache Kafka [topic](https://docs.confluent.io/confluent-cli/current/command-reference/kafka/topic/index.html):

* See [Kafka Log](/plugins/kafka-log/)
* See [Kafka Upstream](/plugins/kafka-upstream/)

{:.info} 
> **Note**: This plugin has the following known limitations:
> * Message compression is not supported.
> * The message format is not customizable.
> * {{site.base_gateway}} supports Kafka 4.0 starting from version 3.10.

## Schema registry support {% new_in 3.11 %}

{% include_cached /plugins/confluent-kafka-consume/schema-registry.md name=page.name slug=page.slug workflow='producer' %}