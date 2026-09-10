---
title: "Llama provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Llama provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/llama/

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
  ai-gateway: '2.0'

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

---


{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Llama2" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

Here's a minimal configuration for chat completions:

{% entity_example %}
type: model-provider
data:
  display_name: Llama2 Production
  name: my-llama2-account
  type: llama2
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: ${key}
variables:
  key:
    value: $LLAMA_API_KEY
    secret: true
    description: "The API key used to connect to your Llama2 endpoint. Include the `Bearer` prefix, for example `Bearer <your-api-key>`."
{% endentity_example %}

## Configure a model target for {{ provider.name }}

A [target](/ai-gateway/entities/ai-model/#targets) is an entry in the `targets` array on the AI Model entity, not the AI Model Provider. Beyond the common target options (`name`, `provider`, `weight`), a target routing to {{ provider.name }} requires:

* **`upstream_url`**: The URL of your self-hosted Llama model endpoint.
* **`format`**: The request format your endpoint expects. One of `ollama`, `openai`, or `raw`.

```yaml
targets:
  - name: llama-3-70b
    provider: my-llama2-account
    config:
      type: llama2
      upstream_url: https://my-llama-endpoint.internal:8000
      format: openai
```
