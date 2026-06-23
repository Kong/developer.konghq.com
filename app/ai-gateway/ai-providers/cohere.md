---
title: "Cohere provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Cohere provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/cohere/

works_on:
 - konnect

products:
  - ai-gateway

tags:
  - ai

tools:
  - konnect-api

min_version:
  ai-ateway: '2.0'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Cohere tutorials
    url: /how-to/?tags=cohere
  - text: "{{site.ai_gateway}} Policies"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

faqs:
  - q: How do I use Cohere's document-grounded chat for RAG pipelines?
    a: |
      {% include faqs/cohere-rerank.md %}

---


{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Cohere" %}

{% include md/ai-gateway/v2/native-routes.md providers=site.data.ai-gateway.v2.providers provider_name="Cohere" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [Provider](/ai-gateway/entities/ai-provider/). You can then access supported [Models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

Here's a minimal configuration for chat completions:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: Cohere Production
  name: my-cohere-account
  type: cohere
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: Bearer $COHERE_API_KEY
{% endkonnect_api_request %}
<!--vale on-->