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
  ai-gateway: '2.0.0'
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayModel

works_on:
 - konnect

products:
  - gateway
  - ai-gateway

tools:
  - admin-api
  - konnect-api
  - deck
  - kic
  - terraform

tags:
  - ai

plugins:
  - ai-proxy-advanced
  - ai-proxy

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - kimi
      - ai-proxy
    description: true
    view_more: false
---


{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Kimi" %}

## Configure {{ provider.name }} with AI Proxy

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [provider](/ai-gateway/entities/ai-provider/) as follows:

{% entity_example %}
type: provider
data:
  display_name: Kimi AI
  name: my-kimi-account
  type: kimi
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: Bearer <your-api-key>
{% endentity_example %}

You can then access supported [models](/ai-gateway/entities/ai-model/) from  {{ provider.name }} as follows:

{% entity_example %}
type: model
data:
  display_name: kimi k2.6 Production
  name: kimi-k2.6-production
  type: model
  enabled: true
  capabilities:
    - chat
    - responses
  formats:
    - type: openai
  acls:
    allow:
      - internal-teams
    deny: []
  policies: []
  target_models:
    - name: kimi-k2.6
      provider:
        name: my-kimi-account
      config:
        temperature: 0.7
        max_tokens: 4096
        input_cost: 0.0000025
        output_cost: 0.000010
  config:
    logging:
      statistics: true
      payloads: false
    response_streaming: allow
    max_request_body_size: 1048576
    model:
      name_header: true
    balancer:
      algorithm: round-robin
      retries: 3
      connect_timeout: 60000
      read_timeout: 60000
      write_timeout: 60000
{% endentity_example %}
