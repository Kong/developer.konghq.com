---
title: Set up AI Proxy with DeepSeek in {{site.base_gateway}}
permalink: /how-to/set-up-ai-proxy-with-deepseek/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Configure the AI Proxy plugin to create a chat route using DeepSeek.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai
  - deepseek

tldr:
  q: How do I use the AI Proxy plugin with DeepSeek?
  a: Create a Gateway Service and a Route, then enable the AI Proxy plugin and configure it with the OpenAI provider, a DeepSeek model, and your DeepSeek API key.

tools:
  - deck

prereqs:
  inline:
    - title: DeepSeek
      include_content: prereqs/deepseek
      icon_url: /assets/icons/deepseek.svg
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

To set up AI Proxy with DeepSeek, use the `openai` provider, specify the [model](https://api-docs.deepseek.com/quick_start/pricing) and set the appropriate authentication header and upstream URL.

In this example, we'll use the `deepseek-chat` model:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        - route_type: llm/v1/chat
          auth:
            header_name: Authorization
            header_value: Bearer ${api_key}
          model:
            provider: openai
            name: deepseek-chat
            options:
              upstream_url: https://api.deepseek.com/chat/completions
              max_tokens: 512
              temperature: 1.0
variables:
  api_key:
    value: $DEEPSEEK_API_KEY
{% endentity_examples %}

## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
