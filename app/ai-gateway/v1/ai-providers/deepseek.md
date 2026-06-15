---
title: "DeepSeek provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for DeepSeek provider
breadcrumbs:
  - /ai-gateway/v1/
  - /ai-gateway/v1/ai-providers/

permalink: /ai-gateway/v1/ai-providers/deepseek/

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

plugins:
  - ai-proxy-advanced
  - ai-proxy

min_version:
  gateway: '3.14'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/v1/
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/v1/ai-providers/
how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - deepseek
    description: true
    view_more: false
major_version:
  ai-gateway: 1

---


{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="DeepSeek" %}

## Configure {{ provider.name }} with AI Proxy

To use {{ provider.name }} with {{site.ai_gateway}}, configure the [AI Proxy](/plugins/ai-proxy/) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin.

Here's a minimal configuration for chat completions:

{% entity_example %}
type: plugin
data:
  name: ai-proxy
  config:
    route_type: llm/v1/chat
    auth:
      header_name: Authorization
      header_value: Bearer ${key}
    model:
      provider: deepseek
      name: deepseek-chat

variables:
  key:
    value: "$DEEPSEEK_API_KEY"
{% endentity_example %}

{:.success}
> For more configuration options and examples, see:
> - [AI Proxy examples](/plugins/ai-proxy/examples/)
> - [AI Proxy Advanced examples](/plugins/ai-proxy-advanced/examples/)

{% include plugins/ai-proxy/providers/how-tos.md %}
