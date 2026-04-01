---
title: Set up AI Proxy for image generation with Grok
permalink: /how-to/set-up-ai-proxy-for-image-generation-with-grok/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Configure the AI Proxy plugin to create an image generation route using xAI Grok.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.13'

plugins:
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - xai

tldr:
  q: How do I use the AI Proxy plugin to generate images with xAI?
  a: Create a Gateway Service and a Route, then enable the AI Proxy plugin and configure it with the `image/v1/images/generations` route type, the xAI provider, the Grok model, and your xAI API key.

tools:
  - deck

prereqs:
  inline:
    - title: xAI
      include_content: prereqs/xai
      icon_url: /assets/icons/xai.svg
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

Set up AI Proxy to use the `image/v1/images/generations` route type and the xAI [Grok 2 Image Gen](https://docs.x.ai/docs/models/grok-2-image) model:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: image/v1/images/generations
        genai_category: image/generation
        auth:
          header_name: Authorization
          header_value: Bearer ${xai_api_key}
        model:
          provider: xai
          name: grok-2-image
variables:
  xai_api_key:
    value: $XAI_API_KEY
{% endentity_examples %}

## Validate

Send a request containing a prompt and a response format to validate:

{% validation request-check %}
url: /anything
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    prompt: Generate an image of King Kong
    response_format: url
{% endvalidation %}
