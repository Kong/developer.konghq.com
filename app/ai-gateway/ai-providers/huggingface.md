---
title: "Hugging Face provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Hugging Face provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/huggingface/

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
  - text: Hugging Face tutorials
    url: /how-to/?tags=huggingface
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

---


{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Hugging Face" %}

{% include plugins/ai-proxy/providers/native-routes.md providers=site.data.plugins.ai-proxy provider_name="Hugging Face" %}

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
  display_name: Huggingface Production
  name: my-huggingface-account
  type: huggingface
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: Bearer $HUGGINGFACE_TOKEN
{% endkonnect_api_request %}
<!--vale on-->