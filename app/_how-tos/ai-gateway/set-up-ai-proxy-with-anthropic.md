---
title: Set up AI Proxy with Anthropic in {{site.base_gateway}}
permalink: /how-to/set-up-ai-proxy-with-anthropic/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Configure the AI Proxy plugin to create a chat route using Anthropic.

products:
    - ai-gateway
    - gateway

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
    - anthropic

tldr:
    q: How do I use the AI Proxy plugin with Anthropic?
    a: Create a Gateway Service and a Route, then enable the AI Proxy plugin and configure it with the Anthropic provider and add the model and your API key.

tools:
    - deck

prereqs:
  inline:
  - title: Anthropic
    include_content: prereqs/anthropic
    icon_url: /assets/icons/anthropic.svg
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

To set up AI Proxy with Anthropic, we need to specify the [model](https://docs.anthropic.com/en/docs/about-claude/models#model-names) and [Anthropic API version](https://docs.anthropic.com/en/api/versioning#version-history) to use.

In this example, we'll use the Claude claude-sonnet-4-5 model and version 2023-06-01 of the API:

{% entity_examples %}
entities:
    plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
            header_name: x-api-key
            header_value: ${anthropic_api_key}
        model:
            provider: anthropic
            name: claude-sonnet-4-5
            options:
                anthropic_version: "2023-06-01"
                max_tokens: 1024
variables:
  anthropic_api_key:
    value: $ANTHROPIC_API_KEY
{% endentity_examples %}

## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
