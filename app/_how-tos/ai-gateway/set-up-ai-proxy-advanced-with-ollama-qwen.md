---
title: Set up AI Proxy Advanced with Ollama and a Qwen model
permalink: /how-to/set-up-ai-proxy-advanced-with-ollama-qwen/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI Proxy Advanced plugin to create a chat route using the Ollama provider with a Qwen model.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.14'

plugins:
  - ai-proxy-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - ollama

tldr:
  q: How do I use the AI Proxy Advanced plugin with Ollama and a Qwen model?
  a: Create a Gateway Service and a Route, then enable the AI Proxy Advanced plugin and configure it with the Ollama provider and the qwen3 model.

tools:
  - deck

prereqs:
  inline:
    - title: Ollama
      include_content: prereqs/ollama-qwen
      icon_url: /assets/icons/ollama.svg
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

Set up the AI Proxy Advanced plugin to route chat requests to Ollama’s Qwen 3 model by configuring the model options, including the `upstream_url` pointing to your local Ollama instance:


{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
            - route_type: llm/v1/chat
              model:
                provider: ollama
                name: qwen3
                options:
                    upstream_url: ${ollama_upstream_url}
variables:
  ollama_upstream_url:
    value: $OLLAMA_UPSTREAM_URL
{% endentity_examples %}


## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
