---
title: Set up AI Proxy Advanced with OpenAI in {{site.base_gateway}}
permalink: /how-to/set-up-ai-proxy-advanced-with-openai/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI Proxy Advanced plugin to create a chat route using OpenAI.

products:
  - ai-gateway
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I use the AI Proxy Advanced plugin with OpenAI?
  a: Create a Gateway Service and a Route, then enable the AI Proxy Advanced plugin and configure it with the OpenAI provider, the gpt-4o model, and your OpenAI API key.

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
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

To set up AI Proxy Advanced with OpenAI, specify the [model](https://platform.openai.com/docs/models) and set the appropriate authentication header.

In this example, we'll use the GPT-4o model:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            model:
              provider: openai
              name: gpt-4o
              options:
                max_tokens: 512
                temperature: 1.0
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
