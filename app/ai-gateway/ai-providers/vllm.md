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

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/model-providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: vllm Production
  name: my-vllm-account
  type: vllm
  config:
    auth:
      type: basic
{% endkonnect_api_request %}
<!--vale on-->

## Configure a target

Beyond the common [target](/ai-gateway/entities/ai-model/#targets) options (`name`, `provider`, `weight`), a target routing to {{ provider.name }} requires:

* **`upstream_url`**: the URL of your self-hosted vLLM server.

```yaml
targets:
  - name: my-vllm-model
    provider: my-vllm-account
    config:
      type: vllm
      upstream_url: http://my-vllm-server.internal:8000
```
