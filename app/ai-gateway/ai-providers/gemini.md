---
title: "Gemini provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Azure OpenAI provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/gemini/

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
  gateway: '3.8'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Gemini tutorials
    url: /how-to/?tags=gemini
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

faqs:
  - q: How can I set model generation parameters when calling Gemini?
    a: |
      {% include faqs/gemini-model-params.md %}
  - q: How do I use Gemini's `googleSearch` tool for real-time web searches?
    a: |
      {% include faqs/gemini-search.md %}
  - q: How do I control aspect ratio and resolution for Gemini image generation?
    a: |
      {% include faqs/gemini-image.md %}
  - q: How do I get reasoning traces from Gemini models?
    a: |
      {% include faqs/gemini-thinking.md %}

how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - gemini
    description: true
    view_more: false
---

{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Gemini" %}

{% include plugins/ai-proxy/providers/native-routes.md providers=site.data.plugins.ai-proxy provider_name="Gemini" %}

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
      param_name: key
      param_value: ${key}
      param_location: query
    model:
      provider: gemini
      name: gemini-2.5-flash

variables:
  key:
    value: $GEMINI_API_KEY
    description: The API key to use to connect to Gemini.
{% endentity_example %}

{:.success}
> For more configuration options and examples, see:
> - [AI Proxy examples](/plugins/ai-proxy/examples/)
> - [AI Proxy Advanced examples](/plugins/ai-proxy-advanced/examples/)

{% include plugins/ai-proxy/providers/how-tos.md %}