---
title: "Vercel provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Vercel provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/vercel/

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
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/
---


{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Vercel" %}

## Configure a {{ provider.name }} provider

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [Provider](/ai-gateway/entities/ai-provider/). You can then access supported [Models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

Note that, {{ site.vercel }} hosts [models](https://vercel.com/ai-gateway/models) from other providers so in this example we use `openai/gpt-5.5`.

Here's a minimal configuration for chat completions:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: Vercel Production
  name: my-vercel-account
  type: vercel
  config:
    auth:
      type: basic
      - name: Authorization
          value: Bearer $VERCEL_API_KEY
{% endkonnect_api_request %}
<!--vale on-->