---
title: Set up AI Proxy with {{ site.edenai }} in {{site.base_gateway}}
permalink: /how-to/set-up-ai-proxy-with-edenai/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Configure the AI Proxy plugin to create a chat route using Eden AI.

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
  - edenai

tldr:
  q: How do I use the AI Proxy plugin with Eden AI?
  a: Create a Gateway Service and a Route, then enable the AI Proxy plugin and configure it with the OpenAI provider, an Eden AI model, your Eden AI API key, and Eden AI's upstream URL.

tools:
  - deck

prereqs:
  inline:
    - title: Eden AI
      content: |
        This tutorial requires an [Eden AI](https://www.edenai.co/) API key.

        1. [Create an Eden AI account](https://app.edenai.run/user/register).
        1. Open **Settings** and copy your API key.
        1. Create a decK variable with the API key:

           ```sh
           export DECK_EDENAI_API_KEY='YOUR EDEN AI API KEY'
           ```
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

[Eden AI](https://www.edenai.co/) exposes an OpenAI-compatible API, so you can reach it with the `openai` provider by pointing `upstream_url` at Eden AI's endpoint. Eden AI is EU-based and GDPR-compliant, and a single key gives you access to models from many providers (OpenAI, Anthropic, Mistral, Google, and more) with provider fallback.

The model name is Eden AI's own `provider/model` identifier. In this example, we'll use the `openai/gpt-4o-mini` model:

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
          name: openai/gpt-4o-mini
          options:
            upstream_url: https://api.edenai.run/v3/chat/completions
            max_tokens: 512
            temperature: 1.0
variables:
  api_key:
    value: $EDENAI_API_KEY
    description: The API key to use to connect to Eden AI.
{% endentity_examples %}

{:.info}
> For strict EU data residency, point `upstream_url` at Eden AI's EU endpoint (`https://api.eu.edenai.run/v3/chat/completions`) and use an EU-hosted model, for example `amazon/mistral.mistral-large-2402-v1:0`. The EU endpoint only serves EU-region models, so US-only models such as `openai/gpt-4o-mini` aren't available there.

## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
