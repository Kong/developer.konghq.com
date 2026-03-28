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

how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - vllm
    description: true
    view_more: false
---

{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="vLLM" %}

## Configuration example

Configure the [AI Proxy plugin](/plugins/ai-proxy/) to route chat requests to your vLLM server.

{% entity_example %}
type: plugin
data:
  name: ai-proxy
  config:
    route_type: llm/v1/chat
    model:
      provider: vllm
      name: vllm-llama-3-8b
      options:
        upstream_url: ${upstream_url}
    # auth is optional — omit if your vLLM server has no API key configured
    auth:
      header_name: Authorization
      header_value: Bearer ${key}
variables:
  upstream_url:
    value: $VLLM_UPSTREAM_URL
  key:
    value: $VLLM_API_KEY
{% endentity_example %}

{% include plugins/ai-proxy/providers/how-tos.md %}
