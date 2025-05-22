---
title: 'AI Proxy'
name: 'AI Proxy'

content_type: plugin

publisher: kong-inc
description: The AI Proxy plugin lets you transform and proxy requests to a number of AI providers and models.


products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.6'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: ai-proxy.png

categories:
  - ai

tags:
  - ai

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model

related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Gateway providers
    url: /ai-gateway/ai-providers/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Get started with AI Gateway
    url: /ai-gateway/get-started/

examples_groups:
  - slug: open-ai
    text: OpenAI use cases
---

{% include plugins/ai-proxy/overview.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}

## Request and response formats
{% include plugins/ai-proxy/formats.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}

## Templating {% new_in 3.7 %}

{% include plugins/ai-proxy/templating.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}
