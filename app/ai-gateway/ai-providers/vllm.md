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
  - text: AI Provider entity
    url: /ai-gateway/entities/ai-provider/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/

---

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="vLLM" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Provider](/ai-gateway/entities/ai-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from {{ provider.name }}.

Here's a minimal configuration for chat completions:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: vllm Production
  name: my-vllm-account
  type: vllm
{% endkonnect_api_request %}
<!--vale on-->
