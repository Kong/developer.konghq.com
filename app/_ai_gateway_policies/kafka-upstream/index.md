---
description: 'Transform requests into Kafka messages in a Kafka topic.'
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: Kafka Log Policy
    url: /ai-gateway/policies/kafka-log/reference/
  - text: Kafka Consume Policy
    url: /ai-gateway/policies/kafka-consume/
---

This Policy converts requests into [Apache Kafka](https://kafka.apache.org/) messages and publishes them to a specified Kafka topic.
For more details, see [Kafka topics](https://kafka.apache.org/documentation/#intro_concepts_and_terms).

{{site.ai_gateway}} also offers a separate [Kafka Log](/ai-gateway/policies/kafka-log/reference/) Policy for streaming logs to Kafka topics.

{:.info}
> This Policy does not support message compression.

## Implementation details

This Policy uses the [lua-resty-kafka](https://github.com/kong/lua-resty-kafka) client.

Control which parts of the request are included in the message with [`config.forward_body`](./reference/#schema--config-forward-body) (enabled by default), [`config.forward_headers`](./reference/#schema--config-forward-headers), [`config.forward_method`](./reference/#schema--config-forward-method), and [`config.forward_uri`](./reference/#schema--config-forward-uri).

When encoding request bodies, several things happen:

* For requests with a content-type header of `application/x-www-form-urlencoded`, `multipart/form-data`,
  or `application/json`, this Policy passes the raw request body in the `body` attribute, and tries
  to return a parsed version of those arguments in `body_args`.
  If this parsing fails, the Policy returns an error message and the message isn't sent.
* If the `content-type` is not `text/plain`, `text/html`, `application/xml`, `text/xml`, or `application/soap+xml`,
  then the body will be base64-encoded to ensure that the message can be sent as JSON. In that case,
  the message has an extra attribute called `body_base64` set to `true`.

## Schema registry support

{% include_cached md/ai-gateway/v2/policies/kafka/schema-registry.md name='Kafka Upstream' workflow='producer' %}

## Authentication

{% include_cached md/ai-gateway/v2/policies/kafka/auth.md name='Kafka Upstream' %}

## Example

The following example creates a global Kafka Upstream Policy that publishes each request to the `kong-upstream` topic, authenticating to the brokers with SASL/PLAIN:

{% entity_example %}
type: policy
data:
  display_name: Kafka Upstream
  name: kafka-upstream
  type: kafka-upstream
  enabled: true
  global: true
  config:
    bootstrap_servers:
      - host: broker.internal
        port: 9092
    topic: kong-upstream
    forward_body: true
    forward_headers: true
    forward_method: true
    forward_uri: true
    authentication:
      strategy: sasl
      mechanism: PLAIN
      user: kafka-user
      password: kafka-password
    security:
      ssl: true
formats:
  - kongctl
{% endentity_example %}
