---
title: "Together AI provider"
layout: reference
content_type: reference
description: Reference for supported capabilities and configuration for the Together AI provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/togetherai/

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
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/policies/
  - text: AI Providers
    url: /ai-gateway/ai-providers/
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: Together AI documentation
    url: https://docs.together.ai/
---

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Together AI" %}

## Configure a {{ provider.name }} provider

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/).
You can then route [AI Models](/ai-gateway/entities/ai-model/) to {{ provider.name }}.

Create an AI Model Provider entity to store your {{ provider.name }} API key.
{{ provider.name }} authenticates with an `Authorization: Bearer` header:

{% entity_example %}
type: model-provider
data:
  display_name: Together AI Production
  name: my-togetherai-account
  type: togetherai
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: Bearer ${key}
variables:
  key:
    value: $TOGETHER_API_KEY
    secret: true
    description: "The API key used to connect to Together AI. Include the `Bearer` prefix, for example `Bearer <your-api-key>`."
{% endentity_example %}

## Configure a {{ provider.name }} model

{{ provider.name }} supports the following APIs:

* Chat completions through the OpenAI format, with the `generate` capability.
* The Responses API through the OpenAI format, with the `agentic` capability.
* The Messages API through the Anthropic format, with the `anthropic` format.

All three APIs support streaming.
Streaming uses server-sent events (SSE).
Chat completions also support tool calling.

By default, {{site.ai_gateway}} sends requests to `https://api.together.ai`.
Set the target `name` to the {{ provider.name }} model ID, for example `deepseek-ai/DeepSeek-V4.1-Flash`.
{{site.ai_gateway}} sends the name to {{ provider.name }} unchanged.

{% entity_example %}
type: model
data:
  display_name: DeepSeek V4.1 Flash on Together AI
  name: deepseek-v4-1-flash
  type: model
  capabilities:
    - generate
  config:
    route:
      paths:
        - /togetherai
  targets:
    - name: deepseek-ai/DeepSeek-V4.1-Flash
      provider: my-togetherai-account
      config:
        type: togetherai
{% endentity_example %}

To send requests to a different host, set `upstream_base_url` on the target to the scheme and host only, for example `https://api.together.ai`.
