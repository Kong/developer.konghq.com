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
  - kongctl

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
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/

---

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Gemini Vertex" %}

{% include md/ai-gateway/v2/native-routes.md providers=site.data.ai-gateway.v2.providers provider_name="Gemini Vertex" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

Here's a minimal configuration for chat completions:

{% entity_example %}
type: model-provider
data:
  display_name: Vertex Production
  name: my-vertex-account
  type: vertex
  config:
    auth:
      type: gcp
      use_gcp_service_account: true
      service_account_json: ${account}
variables:
  account:
    value: $GCP_ACCOUNT_JSON
    description: The contents of your GCP service account JSON key file.
{% endentity_example %}

## Authentication with GCP IAM

Using {{ provider.name }} requires credentials from Google Cloud Platform (GCP).

The authentication chain follows the same order of precedence as the `gcloud` tool:
1. Service account JSON defined directly in the Provider: `auth.service_account_json`.
1. Service account JSON defined in environment variable `GCP_SERVICE_ACCOUNT`.
1. Workload IAM Role (for example, a GKE or Deployment Service Account).
1. VM Instance defined IAM Role.
