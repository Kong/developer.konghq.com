---
title: Set up AI Proxy Advanced with Vertex AI in {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI Proxy Advanced plugin to create a chat route using Vertex AI.

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
  - vertex-ai

tldr:
  q: How do I use the AI Proxy Advanced plugin with Vertex AI?
  a: Create a Gateway Service and a Route, then enable the AI Proxy Advanced plugin and configure it with the Vertex AI provider and add the model and your API key.

tools:
  - deck

prereqs:
  inline:
    - title: Vertex AI
      include_content: prereqs/vertex-ai
      icon_url: /assets/icons/gcp.svg
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

To set up AI Proxy Advanced with Vertex AI, specify the model and set the appropriate authentication header.

In this example, we'll use the Gemini 2.5 Flash model:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        route_type: llm/v1/chat
        auth:
          param_name: key
          param_value: ${gemini_api_key}
          param_location: query
        model:
          provider: gemini
          name: gemini-1.5-flash
variables:
  gemini_api_key:
    value: $GEMINI_API_KEY
    description: The API key to use to connect to Gemini.
formats:
  - deck
  - admin-api
  - konnect-api
  - kic
  - terraform
{% endentity_examples %}  
<!--vale on-->

## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
