---
title: "Cerebras provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Cerebras provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/cerebras/

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
  - text: Cerebras tutorials
    url: /how-to/?tags=cerebras
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/policies/
  - text: AI Providers
    url: /ai-gateway/ai-providers/

---

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Cerebras" %}

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
  display_name: Cerebras Production
  name: my-cerebras-account
  type: cerebras
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: Bearer $CEREBRAS_API_KEY
{% endkonnect_api_request %}
<!--vale on-->
