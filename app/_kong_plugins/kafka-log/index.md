---
title: 'Kafka Log'
name: 'Kafka Log'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Publish logs to a Kafka topic'


products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: kafka-log.png

categories:
  - logging

tags:
  - logging
  - events
  - kafka

search_aliases:
  - kafka-log
  - events
  - event-gateway

min_version:
  gateway: '1.3'
---

Publish request and response logs to an [Apache Kafka](https://kafka.apache.org/) topic. This plugin does not support message compression.
For more information, see [Kafka topics](https://kafka.apache.org/documentation/#intro_concepts_and_terms).

Kong also provides a Kafka plugin for request transformations. See [Kafka Upstream](/plugins/kafka-upstream/).

## Log format

{:.info}
> **Note:** If the `max_batch_size` argument > 1, a request is logged as an array of JSON objects.

{% include /plugins/logging/log-format.md %}

## Implementation details

This plugin uses the [lua-resty-kafka](https://github.com/kong/lua-resty-kafka) client.

When encoding request bodies, several things happen:

* For requests with a content-type header of `application/x-www-form-urlencoded`, `multipart/form-data`,
  or `application/json`, this plugin passes the raw request body in the `body` attribute, and tries
  to return a parsed version of those arguments in `body_args`. 
  If this parsing fails, the plugin returns an error message and the message isn't sent.
* If the `content-type` is not `text/plain`, `text/html`, `application/xml`, `text/xml`, or `application/soap+xml`,
  then the body will be base64-encoded to ensure that the message can be sent as JSON. In that case,
  the message has an extra attribute called `body_base64` set to `true`.


## Custom fields by Lua

{% include /plugins/logging/log-custom-fields-by-lua.md %}

## Schema registry support {% new_in 3.11 %}

{% include_cached /plugins/confluent-kafka-consume/schema-registry.md name=page.name slug=page.slug workflow='producer' %}