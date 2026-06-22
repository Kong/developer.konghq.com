---
title: "Kimi provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Kimi provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/kimi/

min_version:
  ai-gateway: '2.0'

schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayModel

works_on:
  - konnect

tools:
  - konnect-api

products:
  - ai-gateway

tags:
  - ai
  - kimi

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} Policies"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

---


{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Kimi" %}

## Configure {{ provider.name }} with AI Proxy

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [Provider](/ai-gateway/entities/ai-provider/) as follows:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: Kimi Production
  name: my-kimi-account
  type: kimi
  config:
    auth:
      type: basic
      - name: Authorization
          value: Bearer $KIMI_TOKEN
{% endkonnect_api_request %}
<!--vale on-->
