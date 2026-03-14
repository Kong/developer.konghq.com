---
title: Set up AI Proxy Advanced with Cerebras in {{site.base_gateway}}
permalink: /how-to/set-up-ai-proxy-advanced-with-cerebras/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI Proxy Advanced plugin to create a chat route using Cerebras .

products:
    - gateway
    - ai-gateway

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
    - cerebras

tldr:
    q: How do I use the AI Proxy Advanced plugin with Cerebras?
    a: Create a Gateway Service and a Route, then enable the AI Proxy Advanced plugin and configure it with the Cerebras provider and add the model and your API key.

tools:
    - deck

prereqs:
  inline:
  - title: Cerebras
    content: |
        This tutorial uses Cerebras:
        1. [Create a Cerebras account](https://chat.cerebras.ai).
        1. Get an API key. 
        1. Create a decK variable with the API key:

           ```sh
           export DECK_CEREBRAS_API_KEY='YOUR CEREBRAS API KEY'
           ```
    icon_url: /assets/icons/cerebras.svg
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

To set up AI Proxy Advanced with Cerebras, we need to specify the model to use.

In this example, we'll use the gpt-oss-120b model:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${cerebras_api_key}
            model:
              provider: cerebras
              name: gpt-oss-120b
              options:
                max_tokens: 512
                temperature: 1.0
variables:
  cerebras_api_key:
    value: $CEREBRAS_API_KEY
    description: The API key to use to connect to Cerebras.
formats:
  - deck
{% endentity_examples %}
<!--vale on-->

## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
