---
title: "Vertex AI provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Vertex AI provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/vertex/

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
  - text: AI Provider entity
    url: /ai-gateway/entities/ai-provider/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/

---

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Gemini Vertex" %}

{% include md/ai-gateway/v2/native-routes.md providers=site.data.ai-gateway.v2.providers provider_name="Gemini Vertex" %}

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
  display_name: Vertex Production
  name: my-vertex-account
  type: vertex
  config:
    project_id: $VERTEX_PROJECT
    auth:
      type: gcp
      service_account_json: $GCP_ACCOUNT_JSON
{% endkonnect_api_request %}
<!--vale on-->

## Authentication with GCP IAM

Using {{ provider.name }} requires credentials from Google Cloud Platform (GCP).

The authentication chain follows the same order of precedence as the `gcloud` tool:
1. Service account JSON defined directly in the Provider: `auth.gcp_service_account_json`.
1. Service account JSON defined in environment variable `GCP_SERVICE_ACCOUNT`.
1. Workload IAM Role (for example, a GKE or Deployment Service Account).
1. VM Instance defined IAM Role.
