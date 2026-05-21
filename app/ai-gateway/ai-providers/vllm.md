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
  - on-prem
  - konnect

products:
  - gateway
  - ai-gateway

tools:
  - admin-api
  - konnect-api
  - deck
  - kic
  - terraform

tags:
  - ai
  - vllm

plugins:
  - ai-proxy-advanced
  - ai-proxy

min_version:
  gateway: '3.14'

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

{% entity_example %}
type: plugin
data:
  name: ai-proxy
  config:
    route_type: llm/v1/chat
    model:
      provider: vllm
      name: ai/smollm2
      options:
        upstream_url: ${upstream_url}
variables:
  upstream_url:
    value: $VLLM_UPSTREAM_URL
{% endentity_example %}

{:.success}
> For more configuration options and examples, see:
> - [AI Proxy examples](/plugins/ai-proxy/examples/)
> - [AI Proxy Advanced examples](/plugins/ai-proxy-advanced/examples/)