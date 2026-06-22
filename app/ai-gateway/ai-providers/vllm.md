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
  - text: vLLM tutorials
    url: /how-to/?tags=vllm
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI providers
    url: /ai-gateway/ai-providers/

---

{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="vLLM" %}

## Configure {{ provider.name }} with AI Proxy

To use {{ provider.name }} with {{site.ai_gateway}}, configure the [AI Proxy](/plugins/ai-proxy/) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin.

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
