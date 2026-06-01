---
title: "Vertex AI provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Azure OpenAI provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/vertex/

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
  gateway: '3.8'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Vertex AI tutorials
    url: /how-to/?tags=vertex-ai
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - vertex-ai
    description: true
    view_more: false
---

{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Gemini Vertex" %}

{% include plugins/ai-proxy/providers/native-routes.md providers=site.data.plugins.ai-proxy provider_name="Gemini Vertex" %}

## Configure {{ provider.name }} with AI Proxy

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [provider](/ai-gateway/entities/ai-provider/). You can then access supported [models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

Here's a minimal configuration for chat completions:

{% entity_example %}
type: plugin
data:
  name: ai-proxy
  config:
    route_type: llm/v1/chat
    model:
      provider: gemini
      name: gemini-2.0-flash-exp
      options:
        gemini:
          api_endpoint: Bearer ${gcp_api_endpoint}
          project_id: Bearer ${gcp_project_id}
          location_id: Bearer ${gcp_location_id}
    auth:
      gcp_use_service_account: true
      gcp_service_account_json: Bearer ${gcp_service_account_json}
variables:
  gcp_project_id:
    value: $GCP_PROJECT_ID
  gcp_location_id:
    value: $GCP_LOCATION_ID
  gcp_service_account_json:
    value: $GCP_SERVICE_ACCOUNT_JSON
  gcp_api_endpoint:
    value: $GCP_API_ENDPOINT
{% endentity_example %}

{:.success}
> For more configuration options and examples, see:
> - [Set up a provider](/ai-gateway/entities/ai-provider/#set-up-a-provider)
> - [Set up a model](/ai-gateway/entities/ai-model/#set-up-a-model)
> - [How to set up a model with AI proxy](/how-to/set-up-a-model-with-ai-proxy)

## Authentication with GCP IAM

Using {{ provider.name }} requires credentials from Google Cloud Platform (GCP).

The authentication chain follows the same order of precedence as the `gcloud` tool:
1. Service account JSON defined directly in the AI Proxy or AI Proxy Advanced plugin: `auth.gcp_service_account_json`.
1. Service account JSON defined in environment variable `GCP_SERVICE_ACCOUNT`.
1. Workload IAM Role (for example, a GKE or Deployment Service Account).
1. VM Instance defined IAM Role.

{% include plugins/ai-proxy/providers/how-tos.md %}