---
title: "OpenAI provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for OpenAI provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/openai/

tools:
  - konnect-api

works_on:
 - konnect

products:
  - ai-gateway

tags:
  - ai

min_version:
  ai-gateway: '2.0'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: OpenAI tutorials
    url: /how-to/?tags=openai
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

---

{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="OpenAI" %}

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
      provider: openai
      name: gpt-5.1
      options:
        max_tokens: 512
        temperature: 1.0
variables:
  key:
    value: $OPENAI_API_KEY
    description: The API key to use to connect to OpenAI.
{% endentity_example %}

