---
title: "Gemini provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Azure OpenAI provider
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

tags:
  - ai

min_version:
  ai-gateway: '2.0'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Gemini tutorials
    url: /how-to/?tags=gemini
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/policies/
  - text: AI Providers
    url: /ai-gateway/ai-providers/

faqs:
  - q: How can I set model generation parameters when calling Gemini?
    a: |
      {% include faqs/gemini-model-params.md %}
  - q: How do I use Gemini's `googleSearch` tool for real-time web searches?
    a: |
      {% include faqs/gemini-search.md %}
  - q: How do I control aspect ratio and resolution for Gemini image generation?
    a: |
      {% include faqs/gemini-image.md %}
  - q: How do I get reasoning traces from Gemini models?
    a: |
      {% include faqs/gemini-thinking.md %}

---

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Gemini" %}

{% include md/ai-gateway/v2/native-routes.md providers=site.data.ai-gateway.v2.providers provider_name="Gemini" %}

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
  display_name: Gemini Production
  name: my-gemini-account
  type: gemini
  config:
    auth:
      type: gcp
      service_account_json: "$GCP_SERVICE_ACCOUNT_JSON"
{% endkonnect_api_request %}
<!--vale on-->
