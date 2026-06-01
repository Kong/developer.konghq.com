---
title: Set up a model with AI proxy
permalink: /how-to/set-up-a-model-with-ai-proxy
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Configure the AI Proxy plugin to create a chat route.

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
  - deepseek

tldr:
  q: How do I use the AI Proxy plugin?
  a: Create a Gateway Service and a Route, then enable the AI Proxy plugin and configure it with a provider, model, and API key.

tools:
  - deck

prereqs:
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

To set up AI Proxy specify a provider and a compatible model and set the appropriate authentication header and optionally an upstream URL. 

Additionally, you will need an API key from the upstream API provider.

In this minimal example, we'll use the OpenAI provider and the `gpt-5.5` model:

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
          name: gpt-5.5
          options:
            max_tokens: 512
            temperature: 1.0
variables:
  api_key:
    value: $API_KEY
{% endentity_examples %}

Further information can be found in the [AI proxy configuration reference](/plugins/ai-proxy-advanced/reference/).

## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
