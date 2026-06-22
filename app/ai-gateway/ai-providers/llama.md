---
title: "Llama provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Llama provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/llama/

works_on:
 - konnect

products:
  - ai-gateway

tools:
  - konnect-api

tags:
  - ai

min_version:
  ai-gateway: '2.0'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Llama tutorials
    url: /how-to/?tags=llama
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

---


{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Llama2" %}

## Configure {{ provider.name }} with AI Proxy

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [Provider](/ai-gateway/entities/ai-provider/). You can then access supported [Models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

Here's a minimal configuration for chat completions:

{% entity_example %}
type: plugin
data:
  name: ai-proxy
  config:
    route_type: llm/v1/chat
    model:
      provider: llama2
      name: llama2
      options:
        llama2_format: ollama
        upstream_url: http://llama2-server.local:11434/api/chat
{% endentity_example %}
