---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Publish requests to a Confluent Cloud Kafka topic as Kafka messages.'
categories:
  - transformations
tags:
  - kafka
  - data-streaming
  - confluent
  - transformations
  - ai
search_aliases:
  - confluent
  - kafka
  - confluent cloud
  - protocol mediation
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
  - text: Confluent Consume Policy
    url: /ai-gateway/policies/confluent-consume/reference/
  - text: Kafka Consume Policy
    url: /ai-gateway/policies/kafka-consume/reference/
---

The Confluent [AI Policy](/ai-gateway/entities/ai-policy/) publishes requests to a topic in [Confluent Cloud](https://www.confluent.io/confluent-cloud/) as Kafka messages.
Use it to stream the requests that reach an AI Model, AI Agent, or AI MCP Server into your data pipeline without changing the application that sends them.

{{site.ai_gateway}} also provides the [Confluent Consume Policy](/ai-gateway/policies/confluent-consume/reference/) for reading messages from Confluent Cloud.

## Publish messages

The Confluent Policy builds a Kafka message from each request that reaches the entity it's attached to and publishes it to the topic in [`config.topic`](/ai-gateway/policies/confluent/reference/#schema--config-topic).
The Policy needs the following settings:
* [`config.bootstrap_servers`](/ai-gateway/policies/confluent/reference/#schema--config-bootstrap-servers): The Confluent Cloud brokers to connect to.
* [`config.topic`](/ai-gateway/policies/confluent/reference/#schema--config-topic): The topic to publish to.
* [`config.cluster_api_key`](/ai-gateway/policies/confluent/reference/#schema--config-cluster-api-key) and [`config.cluster_api_secret`](/ai-gateway/policies/confluent/reference/#schema--config-cluster-api-secret): The credentials for the cluster.

After the Policy publishes the message, it ends the request.
{{site.ai_gateway}} returns a `200` response with the following body to the caller and ends the request before it reaches the upstream, so an AI Model with this Policy never calls its LLM provider:

```json
{"message": "message sent"}
```
{:.no-copy-code}

By default, the message value contains the raw request body in `body` and the parsed body in `body_args`:

```json
{
  "body": "{\"max_tokens\":5,\"messages\":[{\"content\":\"hello\",\"role\":\"user\"}],\"model\":\"gpt-5.1\"}",
  "body_args": {
    "max_tokens": 5,
    "model": "gpt-5.1",
    "messages": [{"role": "user", "content": "hello"}]
  }
}
```
{:.no-copy-code}

For an AI Model, the `model` field holds the provider model name that the AI Model sends upstream, not the name the caller used in the request.

## Choose what goes into the message

Four Confluent Policy settings control which parts of the request the Policy adds to the message value:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Adds to the message
    key: adds
rows:
  - setting: "[`config.forward_body`](/ai-gateway/policies/confluent/reference/#schema--config-forward-body)"
    adds: "`body` and `body_args`"
  - setting: "[`config.forward_headers`](/ai-gateway/policies/confluent/reference/#schema--config-forward-headers)"
    adds: "`headers`"
  - setting: "[`config.forward_method`](/ai-gateway/policies/confluent/reference/#schema--config-forward-method)"
    adds: "`method`"
  - setting: "[`config.forward_uri`](/ai-gateway/policies/confluent/reference/#schema--config-forward-uri)"
    adds: "`uri` and `uri_args`"
{% endtable %}

At least one of the four settings must be `true`.
{{site.ai_gateway}} rejects a configuration where all four are `false`.

For example, when only `forward_method` is `true`, the message value is `{"method": "POST"}`.

{:.warning}
> **Important:** The `headers` field contains every request header as the Policy receives it, including the `Authorization` header that an AI Model adds for its LLM provider.
> A message with `forward_headers` enabled therefore contains the provider API key.
> Enable `forward_headers` only when you control who can read the topic.

## Set the message key and topic per request

Callers can choose the message key and the topic with query parameters.
Set [`config.key_query_arg`](/ai-gateway/policies/confluent/reference/#schema--config-key-query-arg) and [`config.topics_query_arg`](/ai-gateway/policies/confluent/reference/#schema--config-topics-query-arg) to the names of the query parameters.
For example, with `key_query_arg` set to `k` and `topics_query_arg` set to `t`, the request path `/chat/completions?k=order-42&t=orders` publishes a message with the key `order-42` to the `orders` topic.

Each topic that callers choose must exist in the cluster.
To limit which topics callers can choose, set [`config.allowed_topics`](/ai-gateway/policies/confluent/reference/#schema--config-allowed-topics).
A request for a topic outside the list receives a `403` response with the error `one or more target topics are not in the allowed topics list`, and the Policy doesn't publish the message.

## Authentication

The Confluent Policy authenticates to Confluent Cloud with a cluster API key and secret.
The Policy connects to the brokers over TLS and verifies the broker certificate.

## Schema registry support

{% include_cached md/ai-gateway/v2/policies/kafka/schema-registry.md name='Confluent' workflow='producer' %}

## Responses

The Policy returns the following responses to the caller:

{% table %}
columns:
  - title: Status
    key: status
  - title: Body
    key: body
  - title: When
    key: when
rows:
  - status: "`200`"
    body: "`{\"message\": \"message sent\"}`"
    when: "The Policy published the message."
  - status: "`403`"
    body: "`one or more target topics are not in the allowed topics list`"
    when: "The request chose a topic that isn't in `config.allowed_topics`."
  - status: "`500`"
    body: "`could not create a Kafka Producer from given configuration`"
    when: "The Policy can't connect to the brokers."
{% endtable %}

The Policy connects again when the brokers become reachable, so requests succeed without a configuration change.

## Limitations

The Confluent Policy doesn't support Kafka record headers, message compression, or OAuth bearer authentication to the brokers.

## Scopes

Attach the Confluent Policy to an [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), [AI MCP Server](/ai-gateway/entities/ai-mcp-server/), or [AI Consumer](/ai-gateway/entities/ai-consumer/) to publish messages for that entity only, or apply it globally.
For an AI Consumer, the Policy takes effect only after the client authenticates.

A global Confluent Policy ends every request it applies to.
To publish only some requests, add a [`condition`](/ai-gateway/entities/ai-policy/#conditional-ai-policy-execution) to the Policy.

For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).
