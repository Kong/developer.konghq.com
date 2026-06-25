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
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/policies/
  - text: AI Providers
    url: /ai-gateway/ai-providers/

faqs:
  - q: Can I authenticate to Azure AI with Azure Identity?
    a: |
      {% include faqs/azure-identity.md %}

---

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Azure OpenAI" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Provider](/ai-gateway/entities/ai-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

Here's a minimal configuration for chat completions:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: Azure Production
  name: my-azure-account
  type: azure
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: Bearer $AZURE_OPENAI_API_KEY
{% endkonnect_api_request %}
<!--vale on-->

## Authentication with Azure IAM

You can also use {{ provider.name }} with Azure credentials by setting `auth` to `azure` and specifying:

* **`use_managed_identity`**: Set to `true` to use Azure Managed Identity (recommended for deployments in Azure). When true, the system uses the identity of the current Azure resource (VM, container, function app, etc.).
* **`client_id`** (optional): Entra ID (formerly AAD) application client ID. Required if using a user-assigned managed identity or service principal instead of system-assigned managed identity.
* **`client_secret`** (optional): Client secret for the Entra ID application. Required if `client_id` is set.
* **`tenant_id`** (optional): Azure tenant ID (directory ID). Required if using service principal credentials.
* **`instance`** (optional): Azure cloud instance (e.g. `china`, `government`). Defaults to public cloud.
