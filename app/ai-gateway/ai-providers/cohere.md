---
title: "Cohere provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Cohere provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/cohere/

works_on:
 - on-prem
 - konnect

products:
  - gateway
  - ai-gateway

tags:
  - ai

tools:
  - admin-api
  - konnect-api
  - deck
  - kic
  - terraform

plugins:
  - ai-proxy-advanced
  - ai-proxy

min_version:
  gateway: '3.6'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Cohere tutorials
    url: /how-to/?tags=cohere
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

faqs:
  - q: How do I use Cohere's document-grounded chat for RAG pipelines?
    a: |
      {% include faqs/cohere-rerank.md %}

how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - cohere
    description: true
    view_more: false
---


{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Cohere" %}

{% include plugins/ai-proxy/providers/native-routes.md providers=site.data.plugins.ai-proxy provider_name="Cohere" %}

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
      header_name: Authorization
      header_value: Bearer ${key}
    model:
      provider: cohere
      name: command-a-03-2025
      options:
        max_tokens: 512
        temperature: 1.0

variables:
  key:
    value: $COHERE_API_KEY
    description: The API key to use to connect to Cohere.
{% endentity_example %}

{:.success}
> For more configuration options and examples, see:
> - [Set up a provider](/ai-gateway/entities/ai-provider/#set-up-a-provider)
> - [Set up a model](/ai-gateway/entities/ai-model/#set-up-a-model)
> - [How to set up a model with AI proxy](/how-to/set-up-a-model-with-ai-proxy)

{% include plugins/ai-proxy/providers/how-tos.md %}