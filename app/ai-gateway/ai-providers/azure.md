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
  - text: Kong AI Gateway
    url: /ai-gateway/
  - text: Kong AI Gateway plugins
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

faqs:
  - q: Can I authenticate to Azure AI with Azure Identity?
    a: |
      Yes, if {{site.base_gateway}} is running on Azure, AI Proxy Advanced can detect the designated Managed Identity or User-Assigned Identity of that Azure Compute resource, and use it accordingly.
      In your AI Proxy Advanced configuration, set the following parameters:
      * [`config.auth.azure_use_managed_identity`](/plugins/ai-proxy/reference/#schema--config-targets-auth-azure-use-managed-identity) to `true` to use an Azure-Assigned Managed Identity.
      * [`config.targets.auth.azure_use_managed_identity`](/plugins/ai-proxy/reference/#schema--config-targets-auth-azure-use-managed-identity) to `true` and an [`config.targets.auth.azure_client_id`](/plugins/ai-proxy/reference/#schema--config-targets-auth-azure-client-id) to use a User-Assigned Identity.

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

To use {{ provider.name }} with Kong AI Gateway, configure the [AI Proxy](/plugins/ai-proxy/) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/).

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
> - [AI Proxy examples](/plugins/ai-proxy/examples/)
> - [AI Proxy Advanced examples](/plugins/ai-proxy-advanced/examples/)

{% include plugins/ai-proxy/providers/how-tos.md %}