---
title: "Azure OpenAI provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Azure OpenAI provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/azure/

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
  - text: Azure OpenAI tutorials
    url: /how-to/?tags=azure&tags=ai
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

faqs:
  - q: Can I authenticate to Azure AI with Azure Identity?
    a: |
      {% include faqs/azure-identity.md %}

how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - azure
    description: true
    view_more: false
---

{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Azure" %}

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
      header_value: Bearer ${azure_key}
    model:
      provider: azure
      options:
        azure_api_version: "2025-01-01-preview"
        azure_instance: ${azure_instance}
        azure_deployment_id: ${azure_deployment}
variables:
  azure_key:
    value: "$AZURE_OPENAI_API_KEY"
  azure_instance:
    value: "$AZURE_INSTANCE_NAME"
  azure_deployment:
    value: "$AZURE_DEPLOYMENT_ID"
{% endentity_example %}

{:.success}
> For more configuration options and examples, see:
> - [Set up a provider](/ai-gateway/entities/ai-provider/#set-up-a-provider)
> - [Set up a model](/ai-gateway/entities/ai-model/#set-up-a-model)
> - [How to set up a model with AI proxy](/how-to/set-up-a-model-with-ai-proxy)

{% include plugins/ai-proxy/providers/how-tos.md %}