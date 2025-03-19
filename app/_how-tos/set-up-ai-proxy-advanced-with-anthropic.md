---
title: Set up AI Proxy Advanced with Anthropic in {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.8'


plugins:
  - ai-proxy-advanced

entities: 
  - service
  - route
  - plugin

tags:
    - ai-gateway
    - anthropic

tldr:
    q: How do I use the AI Proxy Advanced plugin with Anthropic?
    a: Create a Gateway Service and a Route, then enable the AI Proxy Advanced plugin, configure it with the Anthropic provider, then add the model and your API key.

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

## 1. Configure the plugin

To set up AI Proxy Advanced with Anthropic, we need to specify the [model](https://docs.anthropic.com/en/docs/about-claude/models#model-names) and [Anthropic API version](https://docs.anthropic.com/en/api/versioning#version-history) to use. 

In this example, we'll use the Claude 2.1 model and version 2023-06-01 of the API:

{% entity_examples %}
entities:
    plugins:
    - name: ai-proxy-advanced
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: x-api-key
              header_value: ${anthropic_api_key}
            model:
              provider: anthropic
              name: claude-2.1
              options:
                  anthropic_version: "2023-06-01"
variables:
  anthropic_api_key:
    value: $ANTHROPIC_API_KEY
{% endentity_examples %}

## 2. Validate

{% include how-tos/steps/ai-proxy-validate.md %}
