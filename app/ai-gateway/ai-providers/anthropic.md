---
title: "Anthropic provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Anthropic provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/anthropic/

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
  - text: Anthropic tutorials
    url: /how-to/?tags=anthropic
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/policies/
  - text: AI Providers
    url: /ai-gateway/ai-providers/

---


{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Anthropic" %}

{% include md/ai-gateway/v2/native-routes.md providers=site.data.ai-gateway.v2.providers provider_name="Anthropic" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Provider](/ai-gateway/entities/ai-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from {{ provider.name }}.

Here's a minimal configuration for chat completions:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: Anthropic Production
  name: my-anthropic-account
  type: anthropic
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: Bearer $ANTHROPIC_API_KEY
        - name: "anthropic-version"
          value: "2023-06-01"
{% endkonnect_api_request %}
<!--vale on-->
 