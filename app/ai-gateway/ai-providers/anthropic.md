---
title: "Anthropic provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Anthropic provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/anthropic/

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
  gateway: '3.6'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Anthropic tutorials
    url: /how-to/?tags=anthropic
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - anthropic
    description: true
    view_more: false
---


{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Anthropic" %}

{% include plugins/ai-proxy/providers/native-routes.md providers=site.data.plugins.ai-proxy provider_name="Anthropic" %}

## Configure {{ provider.name }} with AI Proxy

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [provider](/ai-gateway/entities/ai-provider/). You can then access supported [models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

Here's a minimal configuration for chat completions:

{% entity_example %}
type: plugin
data:
  name: ai-proxy
  config:
    route_type: llm/v1/chat
    auth:
      header_name: x-api-key
      header_value: ${key}
    model:
      provider: anthropic
      name: claude-sonnet-4-6
      options:
        anthropic_version: "2023-06-01"
        max_tokens: 512
        temperature: 1.0
{% endentity_example %}

{:.success}
> For more configuration options and examples, see:
> - [Set up a provider](/ai-gateway/entities/ai-provider/#set-up-a-provider)
> - [Set up a model](/ai-gateway/entities/ai-model/#set-up-a-model)
> - [How to set up a model with AI proxy](/how-to/set-up-a-model-with-ai-proxy)

{% include plugins/ai-proxy/providers/how-tos.md %}