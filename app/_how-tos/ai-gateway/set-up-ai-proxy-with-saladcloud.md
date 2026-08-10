---
title: Set up AI Proxy with SaladCloud AI Gateway
permalink: /how-to/set-up-ai-proxy-with-saladcloud/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Configure the AI Proxy plugin to create a chat route using SaladCloud AI Gateway.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.14'

plugins:
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I use the AI Proxy plugin with SaladCloud AI Gateway?
  a: Create a Gateway Service and a Route, then enable the AI Proxy plugin with the OpenAI provider, the SaladCloud upstream URL, and your SaladCloud API key.

tools:
  - deck

prereqs:
  inline:
    - title: SaladCloud AI Gateway
      include_content: prereqs/saladcloud
      icon_url: /assets/icons/saladcloud.svg
  entities:
    services:
      - example-service
    routes:
      - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Configure the plugin

SaladCloud AI Gateway supports the OpenAI chat completions API. Configure the AI Proxy plugin with the `openai` provider and the SaladCloud chat completions URL.

This example uses the `qwen3.6-35b-a3b` model:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${api_key}
        model:
          provider: openai
          name: qwen3.6-35b-a3b
          options:
            upstream_url: https://ai.salad.cloud/v1/chat/completions
            max_tokens: 512
            temperature: 1.0
variables:
  api_key:
    value: $SALADCLOUD_API_KEY
{% endentity_examples %}

## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
