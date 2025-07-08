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
  - slug: multimodal-open-ai
    text: Multimodal route types for OpenAI
  - slug: openai-processing
    text: File, batch, and realtime routes

faqs:
  - q: Can I authenticate to Azure AI with Azure Identity?
    a: |
      Yes, if {{site.base_gateway}} is running on Azure, AI Proxy can detect the designated Managed Identity or User-Assigned Identity of that Azure Compute resource, and use it accordingly.
      In your AI Proxy configuration, set the following parameters:
      * [`config.auth.azure_use_managed_identity`](./reference/#schema--config-auth-azure-use-managed-identity) to `true` to use an Azure-Assigned Managed Identity.
      * [`config.auth.azure_use_managed_identity`](./reference/#schema--config-auth-azure-use-managed-identity) to `true` and an [`config.auth.azure_client_id`](./reference/#schema--config-auth-azure-client-id) to use a User-Assigned Identity.
---

{% include plugins/ai-proxy/overview.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}

## Request and response formats
{% include plugins/ai-proxy/formats.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}

## Templating {% new_in 3.7 %}

{% include plugins/ai-proxy/templating.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}
