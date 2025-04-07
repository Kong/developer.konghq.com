---
title: 'Kafka Upstream'
name: 'Kafka Upstream'

content_type: plugin

publisher: kong-inc
description: 'Transform requests into Kafka messages in a Kafka topic.'


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
icon: kafka-upstream.png

categories:
  - transformations

search_aliases:
  - kafka-upstream
---

This plugin transforms requests into [Kafka](https://kafka.apache.org/) messages
in an [Apache Kafka](https://kafka.apache.org/) topic. For more information, see
[Kafka topics](https://kafka.apache.org/documentation/#intro_concepts_and_terms).

Kong also provides a Kafka Log plugin for publishing logs to a Kafka topic.
See [Kafka Log](/plugins/kafka-log/).

## Implementation details

This plugin uses the [lua-resty-kafka](https://github.com/kong/lua-resty-kafka) client.

When encoding request bodies, several things happen:

* For requests with a content-type header of `application/x-www-form-urlencoded`, `multipart/form-data`,
  or `application/json`, this plugin passes the raw request body in the `body` attribute, and tries
  to return a parsed version of those arguments in `body_args`. If this parsing fails, an error message is
  returned and the message is not sent.
* If the `content-type` is not `text/plain`, `text/html`, `application/xml`, `text/xml`, or `application/soap+xml`,
  then the body will be base64-encoded to ensure that the message can be sent as JSON. In such a case,
  the message has an extra attribute called `body_base64` set to `true`.

## Known issues and limitations

Known limitations:

1. Message compression is not supported.
2. In {{site.base_gateway}} 3.9 or earlier, the message format is not customizable.
