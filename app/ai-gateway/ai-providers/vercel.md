---
title: "Vercel provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Vercel provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/vercel/

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
  gateway: '2.0.0'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - vercel
    description: true
    view_more: false
---


{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Vercel" %}

## Configure a {{ provider.name }} provider

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [provider](/ai-gateway/entities/provider/). You can then access supported [models](/ai-gateway/entities/model/) from  {{ provider.name }}.

Note that, {{ site.vercel }} hosts [models](https://vercel.com/ai-gateway/models) from other providers so in this example we use `openai/gpt-5.5`.

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
      provider: vercel
      name: openai/gpt-5.5

variables:
  key:
    value: "$VERCEL_API_KEY"
{% endentity_example %}
