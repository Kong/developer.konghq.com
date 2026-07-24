---
title: "Gemini provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Gemini provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/gemini/

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

faqs:
  - q: How can I set model generation parameters when calling Gemini?
    a: |
      {% include md/ai-gateway/v2/faqs/gemini-model-params.md %}
  - q: How do I use Gemini's `googleSearch` tool for real-time web searches?
    a: |
      {% include md/ai-gateway/v2/faqs/gemini-search.md %}
  - q: How do I control aspect ratio and resolution for Gemini image generation?
    a: |
      {% include md/ai-gateway/v2/faqs/gemini-image.md %}
  - q: How do I get reasoning traces from Gemini models?
    a: |
      {% include md/ai-gateway/v2/faqs/gemini-thinking.md %}

---

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Gemini" %}

{% include md/ai-gateway/v2/native-routes.md providers=site.data.ai-gateway.v2.providers provider_name="Gemini" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

Here's a minimal configuration for chat completions:

{% entity_example %}
type: model-provider
data:
  display_name: Gemini Production
  name: my-gemini-account
  type: gemini
  config:
    auth:
      type: basic
      headers:
        - name: x-goog-api-key
          value: $GEMINI_API_KEY
{% endentity_example %}

Replace the following with your actual values:
* `$GEMINI_API_KEY`: The API key used to connect to Gemini.

## Authentication with GCP IAM

You can also use {{ provider.name }} with Google Cloud Platform (GCP) credentials by setting `auth` to `gcp`.

The authentication chain follows the same order of precedence as the `gcloud` tool:
1. Service account JSON defined directly in the Provider: `auth.service_account_json`.
1. Service account JSON defined in environment variable `GCP_SERVICE_ACCOUNT`.
1. Workload IAM Role (for example, a GKE or Deployment Service Account).
1. VM Instance defined IAM Role.

For restricted networks, override the default endpoints with `auth.metadata_url` or `auth.oauth_token_url`.
