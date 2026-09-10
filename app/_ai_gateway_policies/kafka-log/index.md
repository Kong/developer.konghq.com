---
description: 'Publish logs to a Kafka topic.'
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
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

This Policy uses the [lua-resty-kafka](https://github.com/kong/lua-resty-kafka) client.

{:.info}
> This Policy does not support message compression.

## Log format

{% include md/ai-gateway/v2/policies/log-format.md %}

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
