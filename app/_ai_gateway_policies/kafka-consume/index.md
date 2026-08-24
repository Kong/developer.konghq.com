---
description: 'Consume messages from Kafka topics and make them available through HTTP endpoints.'
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
  - text: Kafka Upstream Policy
    url: /ai-gateway/policies/kafka-upstream/reference/
  - text: Confluent Consume Policy
    url: /ai-gateway/policies/confluent-consume/reference/
---

This Policy consumes messages from [Apache Kafka](https://kafka.apache.org/) topics and makes them available through HTTP endpoints.
For more information, see [Kafka topics](https://kafka.apache.org/documentation/#intro_concepts_and_terms).

{:.info}
> This Policy has the following known limitations:
> * Message compression is not supported.
> * The message format is not customizable.

{{site.ai_gateway}} also provides Kafka Policies for publishing messages:
* [Kafka Log](/ai-gateway/policies/kafka-log/reference/)
* [Kafka Upstream](/ai-gateway/policies/kafka-upstream/reference/)

## Implementation details

The Policy supports the following modes of operation, set with [`config.mode`](./reference/#schema--config-mode):
* `http-get`: Consume messages via HTTP GET requests (default)
* `server-sent-events`: Stream messages using [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
* `websocket`: Stream messages over a [WebSocket](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API) connection

### WebSocket mode

{% include md/ai-gateway/v2/policies/kafka/websocket.md broker='Kafka' name='Kafka Consume' %}

## Consume messages

The Policy serves messages on the Route of the entity it's attached to. Reference it from the `policies` array on an [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) that defines `config.route`, then send requests to that path. A global Kafka Consume Policy runs on every {{site.ai_gateway}} Route, so requests only reach it where a Route already exists.

In `http-get` mode, send a `GET` request to the path with no query parameters. The Policy returns the records available for every topic in [`config.topics`](./reference/#schema--config-topics), keyed by topic name and then by partition:

```json
{
  "ai-events": {
    "partitions": {
      "0": {
        "high_watermark": 1,
        "last_stable_offset": 1,
        "errcode": 0,
        "records": [
          {
            "value": {"event": "prompt_received", "model": "gpt-4o"},
            "key": "",
            "timestamp": 1787305085262,
            "offset": 0
          }
        ],
        "aborted_transactions": {}
      }
    }
  }
}
```

Each entry in `records` carries the message `value`, `key`, `timestamp`, and `offset`. When [`config.message_deserializer`](./reference/#schema--config-message-deserializer) is `json`, `value` is a parsed object. When it's `noop`, `value` is the raw message as a string.

Which records a request returns depends on [`config.auto_offset_reset`](./reference/#schema--config-auto-offset-reset). When it's set to `latest` (default), it returns only messages produced after the Policy started consuming. `earliest` returns messages from the beginning of the topic.

{:.info}
> Responses aren't immediate. A request can take several seconds to return, even when records are already available on the topic.

## Message delivery guarantees

{% include md/ai-gateway/v2/policies/kafka/message-delivery.md %}

## Schema registry support

{% include_cached md/ai-gateway/v2/policies/kafka/schema-registry.md name='Kafka Consume' workflow='consumer' %}

## Filter and transform messages

You can use the [`config.message_by_lua_functions`](./reference/#schema--config-message-by-lua-functions) parameter to specify custom Lua code that will filter or transform Kafka messages.

## Authentication

{% include_cached md/ai-gateway/v2/policies/kafka/auth.md name='Kafka Consume' %}

## Example

The following example creates a Kafka Consume Policy that reads from two topics over HTTP GET, authenticating to the brokers with SASL/PLAIN. Reference it from the `policies` array on an entity that defines `config.route` to make it reachable, as described in [Consume messages](#consume-messages):

{% entity_example %}
type: policy
data:
  display_name: Kafka Consume
  name: kafka-consume
  type: kafka-consume
  enabled: true
  global: false
  config:
    bootstrap_servers:
      - host: broker.internal
        port: 9092
    topics:
      - name: ai-events
      - name: ai-audit
    mode: http-get
    message_deserializer: json
    auto_offset_reset: latest
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
