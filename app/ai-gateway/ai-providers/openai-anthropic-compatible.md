---
title: "OpenAI-compatible and Anthropic-compatible providers"
layout: reference
content_type: reference
description: Reference for the openai-compatible and anthropic-compatible provider types, which connect AI Gateway to any vendor that exposes an OpenAI or Anthropic compatible API
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/openai-anthropic-compatible/

works_on:
 - konnect

products:
  - ai-gateway

tools:
  - konnect-api
  - kongctl

tags:
  - ai

min_version:
  ai-gateway: '2.4'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Providers
    url: /ai-gateway/ai-providers/
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: OpenAI provider
    url: /ai-gateway/ai-providers/openai/
  - text: Anthropic provider
    url: /ai-gateway/ai-providers/anthropic/
---

<!--
TODO(AI-166) open questions to resolve before GA:
OQ1: Is a provider_alias equal to a built-in provider type, such as `openai` or `anthropic`, rejected?
OQ2: Should provider_alias stay required, or default to the AI Model Provider `name`?
OQ3: How is a trailing `/v1` in base_url handled? Does the gateway strip it or append the path as is?
OQ4: What is the relationship to dedicated providers such as `baseten`? Which should users pick when both apply?
Also: the AI Gateway 2.4 release isn't in app/_data/products/ai-gateway.yml yet. Confirm min_version
resolves correctly once the release entry lands.
-->

{% new_in 2.4 %} Use the `openai-compatible` and `anthropic-compatible` provider types to connect {{site.ai_gateway}} to any vendor that exposes an OpenAI or Anthropic compatible API but doesn't have a dedicated {{site.ai_gateway}} provider.
You set the vendor's `base_url`, authentication, and a `provider_alias` that identifies the vendor in analytics, logs, and OpenTelemetry data.

| Provider type | API format | Standard paths |
|---------------|------------|----------------|
| `openai-compatible` | [OpenAI](/ai-gateway/ai-providers/openai/) | `/v1/chat/completions`, `/v1/embeddings` |
| `anthropic-compatible` | [Anthropic](/ai-gateway/ai-providers/anthropic/) | `/v1/messages` |

If a dedicated provider exists for your vendor, use it instead.
<!-- TODO(AI-166 OQ4): clarify the relationship to dedicated providers such as `baseten`. -->

## How requests are routed

{{site.ai_gateway}} sends each request to the provider `base_url` plus the standard OpenAI or Anthropic path for the route type.
For example, with a `base_url` of `https://inference.baseten.co`, a chat request goes to `https://inference.baseten.co/v1/chat/completions`.
<!-- TODO(AI-166 OQ3): confirm how a trailing `/v1` in base_url is handled. Until then, omit the path from base_url. -->

The compatible provider types support the same route types and streaming modes as the `openai` and `anthropic` providers.
The vendor must implement the endpoints that your AI Model uses.

## Provider configuration

Set the following fields in the `config` of the AI Model Provider. All fields are required.

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`auth`"
    description: |
      Authentication for the vendor. Set `type` to `basic` and provide either one header (`name` and `value`) or one query parameter (`name`, `value`, and `location`). Values can reference a secret in a vault.
  - field: "`base_url`"
    description: |
      The vendor's base URL, for example `https://inference.baseten.co`. Must be an HTTP or HTTPS URI of 1 to 2048 characters.
  - field: "`provider_alias`"
    description: |
      A short name for the vendor, for example `baseten`. Must be 1 to 64 characters, lowercase letters, numbers, and hyphens, and must start and end with a letter or number (`^[a-z0-9]([a-z0-9-]*[a-z0-9])?$`). {{site.ai_gateway}} reports this value as the provider name in analytics, logs, and OpenTelemetry instead of the generic provider type.
{% endtable %}
<!-- TODO(AI-166 OQ1): confirm whether a provider_alias that matches a built-in provider type is rejected. -->
<!-- TODO(AI-166 OQ2): confirm whether provider_alias stays required or defaults to the AI Model Provider name. -->

## Configure an OpenAI-compatible provider

The following example creates an AI Model Provider for a vendor with an OpenAI compatible API:

{% entity_example %}
type: model-provider
data:
  display_name: Baseten Compatible
  name: my-openai-compatible
  type: openai-compatible
  config:
    base_url: https://inference.baseten.co
    provider_alias: baseten
    auth:
      type: basic
      headers:
        - name: Authorization
          value: ${key}
variables:
  key:
    value: $VENDOR_API_KEY
    secret: true
    description: "The API key for the vendor. Include any prefix the vendor requires, for example `Bearer <your-api-key>`."
{% endentity_example %}

Then create an AI Model with a target that uses the same `type`.
Set the target `name` to the vendor's model ID:

{% entity_example %}
type: model
data:
  display_name: DeepSeek V4 Pro
  name: deepseek-v4-pro
  type: model
  capabilities:
    - generate
  config:
    route:
      paths:
        - /compatible-chat
  targets:
    - name: deepseek-ai/DeepSeek-V4-Pro-0813
      provider: my-openai-compatible
      config:
        type: openai-compatible
{% endentity_example %}

## Configure an Anthropic-compatible provider

The setup is the same, with the `anthropic-compatible` type:

```yaml
type: model-provider
data:
  name: my-anthropic-compatible
  type: anthropic-compatible
  config:
    base_url: https://api.example-vendor.com
    provider_alias: example-vendor
    auth:
      type: basic
      headers:
        - name: x-api-key
          value: ${key}
```

An `anthropic-compatible` target also accepts a `version` option.
{{site.ai_gateway}} sends it as the `anthropic-version` header.
The default is `2023-06-01`.

```yaml
targets:
  - name: VENDOR_MODEL_ID
    provider: my-anthropic-compatible
    config:
      type: anthropic-compatible
      version: '2023-06-01'
```

## Target options

Targets of both types support the standard target options, such as `max_tokens`, `temperature`, `top_k`, `top_p`, costs, and `upstream_url`.
See the [AI Model entity](/ai-gateway/entities/ai-model/#targets) for the full list.

## Analytics and observability

{{site.ai_gateway}} reports the `provider_alias` value as the provider name in analytics, logs, and OpenTelemetry data.
This lets you tell vendors apart even though they share a provider type.
