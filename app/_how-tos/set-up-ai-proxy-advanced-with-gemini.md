---
title: Set up AI Proxy with Gemini in {{site.base_gateway}}

content_type: how_to

related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI Proxy Advanced plugin to create a chat route using Gemini.

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
  - gemini

tldr:
  q: How do I use the AI Proxy Advanced plugin with Gemini?
  a: Create a Gateway Service and a Route, then enable the AI Proxy Advanced plugin and configure it with the Gemini provider and add the model and your API key.

tools:
  - deck

prereqs:
  inline:
    - title: 
      include_content: Gemini
      icon_url: /assets/icons/gemini.svg
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

To set up AI Proxy Advanced with Gemini, configure API key authentication and specify the Gemini model to use. 

In this example, we use the `gemini-2.0-flash-exp` model:
{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      service: gemini-service
      config:
        route_type: llm/v1/chat
        llm_format: gemini
        auth:
          param_name: key
          param_value: ${gemini_api_key}
          param_location: query
        model:
          provider: gemini
          name: gemini-2.0-flash-exp
variables:
  gemini_api_key:
    value: $GEMINI_API_KEY
formats:
  - deck
{% endentity_examples %}

## Validate
To validate, send a request to the Route:

{% validation request-check %}
url: /anything
status_code: 200
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  messages:
    - role: "system"
      content: "You are a mathematician."
    - role: "user"
      content: "What is 1+1?"
{% endvalidation %}

