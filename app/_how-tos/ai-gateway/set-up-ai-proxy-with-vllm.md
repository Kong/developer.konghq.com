---
title: "Set up AI Proxy with vLLM"
permalink: /how-to/set-up-ai-proxy-with-vllm/
content_type: how_to
description: "Configure the AI Proxy plugin to create a chat route using a self-hosted vLLM server."

breadcrumbs:
  - /ai-gateway/

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.14'

plugins:
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - vllm

tldr:
  q: "How do I use the AI Proxy plugin with vLLM?"
  a: "Create a Gateway Service and Route, then configure the AI Proxy plugin with the vLLM provider and the URL of your vLLM server."

tools:
  - deck

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy plugin
    url: /plugins/ai-proxy/
  - text: "vLLM provider"
    url: /ai-gateway/ai-providers/vllm/

prereqs:
  inline:
    - title: vLLM
      include_content: prereqs/vllm
      icon_url: /assets/icons/vllm.svg
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

## Configure the AI Proxy plugin

Configure the [AI Proxy plugin](/plugins/ai-proxy/) with your vLLM server details.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        model:
          provider: vllm
          name: vllm-llama-3-8b
          options:
            upstream_url: ${upstream_url}
        # auth is optional — omit if your vLLM server has no API key configured
        auth:
          header_name: Authorization
          header_value: Bearer ${key}
variables:
  upstream_url:
    value: $VLLM_UPSTREAM_URL
  key:
    value: $VLLM_API_KEY
{% endentity_examples %}

## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
