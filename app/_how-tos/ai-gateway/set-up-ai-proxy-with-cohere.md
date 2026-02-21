---
title: Set up AI Proxy with Cohere in {{site.base_gateway}}
permalink: /how-to/set-up-ai-proxy-with-cohere/

content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Configure the AI Proxy plugin to create a chat route using Cohere.

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
  - cohere

tldr:
  q: How do I use the AI Proxy plugin with Cohere?
  a: Create a Gateway Service and a Route, then enable the AI Proxy plugin and configure it with the Cohere provider and add the model and your API key.

tools:
  - deck

prereqs:
  inline:
    - title: Cohere
      include_content: prereqs/cohere
      icon_url: /assets/icons/cohere.svg
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

To set up AI Proxy with Cohere, configure API key authentication and specify the Cohere model to use. 

In this example, we'll use the Cohere command model:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${cohere_api_key}
        model:
          provider: cohere
          name: command-a-03-2025
          options:
            max_tokens: 512
            temperature: 1.0
variables:
  cohere_api_key:
    value: $COHERE_API_KEY
{% endentity_examples %}
<!--vale on-->

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