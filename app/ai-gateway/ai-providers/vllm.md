---
title: "vLLM provider"
layout: reference
content_type: reference
description: "Reference for supported capabilities for vLLM"
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/vllm/

works_on:
  - konnect

products:
  - ai-gateway

tools:
  - konnect-api
  - kongctl

tags:
  - ai
  - vllm


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

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="vLLM" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from {{ provider.name }}.

Here's a minimal configuration for chat completions:

{% entity_example %}
type: model-provider
data:
  display_name: vllm Production
  name: my-vllm-account
  type: vllm
  config:
    auth:
      type: basic
{% endentity_example %}

## Configure a model target for {{ provider.name }}

A [target](/ai-gateway/entities/ai-model/#targets) is an entry in the `targets` array on the AI Model entity, not the AI Model Provider. Beyond the common target options (`name`, `provider`, `weight`), a target routing to {{ provider.name }} requires:

* **`upstream_url`**: The URL of your self-hosted vLLM server.

```yaml
targets:
  - name: my-vllm-model
    provider: my-vllm-account
    config:
      type: vllm
      upstream_url: http://my-vllm-server.internal:8000
```
