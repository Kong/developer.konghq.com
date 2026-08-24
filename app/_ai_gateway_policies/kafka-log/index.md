---
description: 'Publish logs to a Kafka topic.'
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
  - text: Kafka Consume Policy
    url: /ai-gateway/policies/kafka-consume/
  - text: HTTP Log Policy
    url: /ai-gateway/policies/http-log/
---

Publish request and response logs to an [Apache Kafka](https://kafka.apache.org/) topic.
For more information, see [Kafka topics](https://kafka.apache.org/documentation/#intro_concepts_and_terms).

{{site.ai_gateway}} also provides a Kafka Policy for request transformations. See [Kafka Upstream](/ai-gateway/policies/kafka-upstream/reference/).

{:.info}
> This Policy does not support message compression.

## Log format

{% include md/ai-gateway/v2/policies/log-format.md %}

## Implementation details

This Policy uses the [lua-resty-kafka](https://github.com/kong/lua-resty-kafka) client.

When encoding request bodies, several things happen:

* For requests with a content-type header of `application/x-www-form-urlencoded`, `multipart/form-data`,
  or `application/json`, this Policy passes the raw request body in the `body` attribute, and tries
  to return a parsed version of those arguments in `body_args`.
  If this parsing fails, the Policy returns an error message and the message isn't sent.
* If the `content-type` is not `text/plain`, `text/html`, `application/xml`, `text/xml`, or `application/soap+xml`,
  then the body will be base64-encoded to ensure that the message can be sent as JSON. In that case,
  the message has an extra attribute called `body_base64` set to `true`.

## Custom fields by Lua

Use [`config.custom_fields_by_lua`](./reference/#schema--config-custom-fields-by-lua) to dynamically modify log fields with Lua code. The field accepts a map of log field names to Lua expressions. Set a field to `nil` to remove it from the log entry.

## Schema registry support

{% include_cached md/ai-gateway/v2/policies/kafka/schema-registry.md name='Kafka Log' workflow='producer' %}

## Authentication

{% include_cached md/ai-gateway/v2/policies/kafka/auth.md name='Kafka Log' %}

## Example

The following example creates a global Kafka Log Policy that publishes logs for all {{site.ai_gateway}} traffic to the `kong-log` topic, authenticating to the brokers with SASL/PLAIN:

{% entity_example %}
type: policy
data:
  display_name: Kafka Log
  name: kafka-log
  type: kafka-log
  enabled: true
  global: true
  config:
    bootstrap_servers:
      - host: broker.internal
        port: 9092
    topic: kong-log
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
