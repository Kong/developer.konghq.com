---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Consume messages from Confluent Cloud Kafka topics and make them available through HTTP, server-sent events, or WebSocket endpoints.'
categories:
  - traffic-control
tags:
  - confluent
  - traffic-control
  - ai
search_aliases:
  - confluent-consume
  - events
  - confluent cloud
  - kafka
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
  - text: Kafka Consume Policy
    url: /ai-gateway/policies/kafka-consume/reference/
  - text: Confluent Policy
    url: /ai-gateway/policies/confluent/reference/
---

Clients that need Kafka event data, such as audit events or notifications, usually need a Kafka client library.
The Confluent Consume [AI Policy](/ai-gateway/entities/ai-policy/) reads messages from [Confluent Cloud](https://confluent.io/cloud) Kafka topics and serves them from an {{site.ai_gateway}} endpoint over HTTP, server-sent events, or WebSocket.
Attach it to an [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) to expose the topics on that entity's route.

{{site.ai_gateway}} also provides the [Confluent Policy](/ai-gateway/policies/confluent/reference/) for publishing messages to Confluent Cloud.

## Consume messages

The Policy serves messages on the route of the entity it's attached to.
Reference it from the `policies` array on an AI Model, AI Agent, or AI MCP Server that defines `config.route`, then send requests to that path.
For an AI Model, send a `POST` request to the model's `chat/completions` path.
For an AI Agent or AI MCP Server, send a `GET` request to the entity's path.

In `http-get` mode, the Policy returns the records available for every topic in [`config.topics`](/ai-gateway/policies/confluent-consume/reference/#schema--config-topics), keyed by topic name and then by partition:

```json
{
  "ai-events": {
    "partitions": {
      "0": {
        "high_watermark": 3,
        "last_stable_offset": 3,
        "errcode": 0,
        "records": [
          {
            "value": {"event": "prompt_received", "n": 1},
            "offset": 0,
            "timestamp": 1794215129672
          }
        ],
        "aborted_transactions": {}
      }
    }
  }
}
```

When [`config.message_deserializer`](/ai-gateway/policies/confluent-consume/reference/#schema--config-message-deserializer) is `json`, `value` is a parsed object.
When it's `noop` (default), `value` is the raw message as a string.

### Offsets and repeated reads

The Confluent Consume Policy reads topics as a Kafka consumer group.
By default ([`config.commit_strategy`](/ai-gateway/policies/confluent-consume/reference/#schema--config-commit-strategy) is `auto`), the Policy commits offsets after each read, so a repeated request returns only new messages.
When no new messages exist, `records` is an empty object.
Set `commit_strategy` to `off` to return the same records on every request.

Where a new consumer group starts reading depends on [`config.auto_offset_reset`](/ai-gateway/policies/confluent-consume/reference/#schema--config-auto-offset-reset):
- `earliest` (default) reads from the beginning of the topic.
- `latest` reads only messages produced after the Policy starts consuming.
  Also set [`config.enforce_latest_offset_reset`](/ai-gateway/policies/confluent-consume/reference/#schema--config-enforce-latest-offset-reset) to `true`.
  Without it, the first read still returns the messages already on the topic.

## Modes

Set [`config.mode`](/ai-gateway/policies/confluent-consume/reference/#schema--config-mode) to choose how the Policy delivers messages:
- `http-get` (default): returns the available messages in one response.
- `server-sent-events`: streams each message as a [server-sent event](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events) with the fields `data`, `event`, `id`, and `topic`, and sends keep-alive comments while no messages arrive.
  Clients typically send `Accept: text/event-stream`.
- `websocket`: sends each message as a JSON text frame over a [WebSocket](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API) connection. Each frame has the fields `data`, `event`, `id`, and `topic`.

## Transform messages

Use [`config.message_by_lua_functions`](/ai-gateway/policies/confluent-consume/reference/#schema--config-message-by-lua-functions) to run custom Lua code on each message in `server-sent-events` mode.
The function receives each message as a table with fields such as `value` and returns the modified message.
String and boolean fields you add to the returned message appear as extra fields on the event.

The following function marks every message as processed:

```lua
return function(message)
  local m = type(message) == "table" and message or { value = message }
  m.processed_by_lua = true
  return m
end
```

## Authentication

The Confluent Consume Policy authenticates to Confluent Cloud with a cluster API key and secret over SASL.
Set [`config.cluster_api_key`](/ai-gateway/policies/confluent-consume/reference/#schema--config-cluster-api-key) and [`config.cluster_api_secret`](/ai-gateway/policies/confluent-consume/reference/#schema--config-cluster-api-secret) to the key and secret for your cluster.
The Policy connects to the brokers over TLS and verifies the broker certificate by default, through [`config.security.ssl_verify`](/ai-gateway/policies/confluent-consume/reference/#schema--config-security-ssl-verify).
If the credentials are wrong, requests fail with a `502` status code.

## Limitations

- Messages that fail JSON deserialization aren't sent to the dead-letter topic, even when [`config.enable_dlq`](/ai-gateway/policies/confluent-consume/reference/#schema--config-enable-dlq) and [`config.dlq_topic`](/ai-gateway/policies/confluent-consume/reference/#schema--config-dlq-topic) are set.

## Scopes

Attach the Confluent Consume Policy to an AI Model, AI Agent, AI MCP Server, or AI Consumer to serve Kafka messages for that entity only, or apply it globally.
For an AI Consumer, the Policy takes effect only after the client authenticates.

For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

## Example

The following example creates a Confluent Consume Policy that reads from one topic over HTTP GET and parses messages as JSON.
Reference it from the `policies` array on an entity that defines `config.route`, as described in [Consume messages](#consume-messages):

{% entity_example %}
type: policy
data:
  name: confluent-consume
  display_name: Confluent Consume
  type: confluent-consume
  global: false
  config:
    bootstrap_servers:
      - host: pkc-xxxxx.us-east-1.aws.confluent.cloud
        port: 9092
    cluster_api_key: CLUSTER_API_KEY
    cluster_api_secret: CLUSTER_API_SECRET
    topics:
      - name: ai-events
    mode: http-get
    message_deserializer: json
formats:
  - konnect-api
  - kongctl
{% endentity_example %}
