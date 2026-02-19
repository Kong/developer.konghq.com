---
title: "xAI provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for xAI provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/xai/

works_on:
 - on-prem
 - konnect

products:
  - ai-gateway
  - gateway

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
  gateway: '3.13'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: xAI tutorials
    url: /how-to/?tags=xai
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - xai
    description: true
    view_more: false
---


{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="xAI" %}

{% include plugins/ai-proxy/providers/native-routes.md providers=site.data.plugins.ai-proxy provider_name="xAI" %}

## Configure {{ provider.name }} with AI Proxy

To use {{ provider.name }} with {{site.ai_gateway}}, configure the [AI Proxy](/plugins/ai-proxy/) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/).

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
      provider: xai
      name: grok-4
      options:
        max_tokens: 512
        temperature: 1.0

variables:
  key:
    value: $XAI_API_KEY
    description: The API key to use to connect to xAI.
{% endentity_example %}

{:.success}
> For more configuration options and examples, see:
> - [AI Proxy examples](/plugins/ai-proxy/examples/)
> - [AI Proxy Advanced examples](/plugins/ai-proxy-advanced/examples/)

{% include plugins/ai-proxy/providers/how-tos.md %}