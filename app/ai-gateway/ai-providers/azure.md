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

tags:
  - ai

plugins:
  - ai-proxy-advanced
  - ai-proxy

min_version:
  gateway: '3.10'

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
      * [`config.auth.azure_use_managed_identity`](./reference/#schema--config-targets-auth-azure-use-managed-identity) to `true` to use an Azure-Assigned Managed Identity.
      * [`config.targets.auth.azure_use_managed_identity`](./reference/#schema--config-targets-auth-azure-use-managed-identity) to `true` and an [`config.targets.auth.azure_client_id`](./reference/#schema--config-targets-auth-azure-client-id) to use a User-Assigned Identity.

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

{% include plugins/ai-proxy/providers/how-tos.md %}