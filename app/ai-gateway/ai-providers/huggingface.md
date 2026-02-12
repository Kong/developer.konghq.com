---
title: "Hugging Face provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Hugging Face provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/huggingface/

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
  gateway: '3.9'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Hugging Face tutorials
    url: /how-to/?tags=huggingface
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - huggingface
    description: true
    view_more: false
---


{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Hugging Face" %}

{% include plugins/ai-proxy/providers/native-routes.md providers=site.data.plugins.ai-proxy provider_name="Hugging Face" %}

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
      header_value: Bearer ${token}
    model:
      provider: huggingface
      name: Qwen/Qwen3-4B-Instruct-2507

variables:
  token:
    value: $HUGGINGFACE_TOKEN
    description: The token to use to connect to Hugging Face.
{% endentity_example %}

{:.success}
> For more configuration options and examples, see:
> - [AI Proxy examples](/plugins/ai-proxy/examples/)
> - [AI Proxy Advanced examples](/plugins/ai-proxy-advanced/examples/)

{% include plugins/ai-proxy/providers/how-tos.md %}