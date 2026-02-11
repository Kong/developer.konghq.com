---
title: Set up AI Proxy Advanced with DashScope (Alibaba Cloud) in {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI Proxy Advanced plugin to create a chat route using DashScope (Alibaba Cloud).

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
  - dashscope

tldr:
  q: How do I use the AI Proxy Advanced plugin with DashScope (Alibaba Cloud)?
  a: Create a Gateway Service and a Route, then enable the AI Proxy Advanced plugin and configure it with the DashScope (Alibaba Cloud) provider and add the model and your API key.

tools:
  - deck

prereqs:
  inline:
    - title: DashScope
      icon_url: /assets/icons/dashscope.svg
      content: |
        You need an active DashScope account with API access. Sign up at the [Alibaba Cloud DashScope platform](https://dashscope.aliyuncs.com/), obtain your API key from the API-KEY interface, and export it to your environment:
        ```sh
        export DECK_DASHSCOPE_API_KEY='YOUR DASHSCOPE API KEY'
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

To set up AI Proxy Advanced with DashScope (Alibaba Cloud), specify the model and set the appropriate authentication header.

In this example, we'll use the Qwen Plus model:

{% entity_examples %}
entities:
  plugins:
  - name: ai-proxy-advanced
    config:
      targets:
        - route_type: llm/v1/chat
          auth:
            header_name: Authorization
            header_value: Bearer ${key}
          model:
            provider: dashscope
            name: qwen-plus
            options:
              dashscope:
                international: true
              max_tokens: 512
              temperature: 1.0
variables:
  key:
    value: $DASHSCOPE_API_KEY
{% endentity_examples %}

## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
