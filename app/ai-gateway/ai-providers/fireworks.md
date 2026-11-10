---
title: "Fireworks AI provider"
layout: reference
content_type: reference
description: Reference for supported capabilities and configuration for the Fireworks AI provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/fireworks/

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
  - text: Fireworks AI documentation
    url: https://docs.fireworks.ai/
---

<!--
TODO(AI-164 OQ1): the runtime capability matrix isn't confirmed. Verify Rerank support before GA.
-->

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Fireworks AI" %}

## Configure a {{ provider.name }} provider

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/).
You can then route [AI Models](/ai-gateway/entities/ai-model/) to {{ provider.name }}.

Create an AI Model Provider entity to store your {{ provider.name }} API key.
{{ provider.name }} authenticates with an `Authorization: Bearer` header:

{% entity_example %}
type: model-provider
data:
  display_name: Fireworks AI Production
  name: my-fireworks-account
  type: fireworks
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: ${key}
variables:
  key:
    value: $FIREWORKS_API_KEY
    secret: true
    description: "The API key used to connect to Fireworks AI. Include the `Bearer` prefix, for example `Bearer <your-api-key>`."
{% endentity_example %}

## Configure a {{ provider.name }} model

{{ provider.name }} supports chat completions, completions, the Responses API, embeddings, and rerank through the OpenAI format, and the Messages API through the Anthropic format.

By default, {{site.ai_gateway}} sends requests to `https://api.fireworks.ai/inference/v1`.
Set the target `name` to the full {{ provider.name }} model ID, for example `accounts/fireworks/models/llama-v3p1-70b-instruct`.
{{site.ai_gateway}} sends the name to {{ provider.name }} unchanged.

{% entity_example %}
type: model
data:
  display_name: Llama 3.1 70B on Fireworks AI
  name: llama-3-1-70b
  type: model
  capabilities:
    - generate
  config:
    route:
      paths:
        - /fireworks
  targets:
    - name: accounts/fireworks/models/llama-v3p1-70b-instruct
      provider: my-fireworks-account
      config:
        type: fireworks
{% endentity_example %}

## US-only region

To keep {{ provider.name }} requests in the US, set the target `upstream_url` to the {{ provider.name }} US endpoint:

```yaml
targets:
  - name: accounts/fireworks/models/llama-v3p1-70b-instruct
    provider: my-fireworks-account
    config:
      type: fireworks
      upstream_url: https://us.api.fireworks.ai/inference/v1
```

## Errors

{{site.ai_gateway}} returns upstream errors from {{ provider.name }} to the client unchanged.
{{site.ai_gateway}} also returns errors caused by `max_tokens` truncation unchanged.
