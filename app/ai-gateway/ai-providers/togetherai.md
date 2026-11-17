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
          value: ${key}
variables:
  key:
    value: $TOGETHER_API_KEY
    secret: true
    description: "The API key used to connect to Together AI. Include the `Bearer` prefix, for example `Bearer <your-api-key>`."
{% endentity_example %}

## Configure a {{ provider.name }} model

{{ provider.name }} supports chat completions and completions through the OpenAI format.
Streaming uses server-sent events (SSE).

By default, {{site.ai_gateway}} sends requests to `https://api.together.xyz/v1`.
Set the target `name` to the {{ provider.name }} model ID, for example `meta-llama/Llama-3.3-70B-Instruct-Turbo`.
{{site.ai_gateway}} sends the name to {{ provider.name }} unchanged.

{% entity_example %}
type: model
data:
  display_name: Llama 3.3 70B on Together AI
  name: llama-3-3-70b
  type: model
  capabilities:
    - generate
  config:
    route:
      paths:
        - /togetherai
  targets:
    - name: meta-llama/Llama-3.3-70B-Instruct-Turbo
      provider: my-togetherai-account
      config:
        type: togetherai
{% endentity_example %}

To use a different base URL, set `upstream_url` on the target.
