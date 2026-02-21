---
title: Set up AI Proxy Advanced with Ollama
permalink: /how-to/set-up-ai-proxy-advanced-with-ollama/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI Proxy Advanced plugin to create a chat route using Ollama.

products:
  - ai-gateway
  - gateway

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
  - llama

tldr:
  q: How do I use the AI Proxy Advanced plugin with Ollama?
  a: Create a Gateway Service and a Route, then enable the AI Proxy Advanced plugin and configure it with the Ollama provider, and the Llama2 model.

tools:
  - deck

prereqs:
  inline:
    - title: Ollama
      include_content: prereqs/ollama
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

Set up the AI Proxy Advanced plugin to route chat requests to Ollama’s Llama2 model by configuring the model options, including the ollama format and the upstream_url pointing to your local Ollama instance.


{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
            - route_type: llm/v1/chat
              model:
                provider: llama2
                name: llama2
                options:
                    llama2_format: ollama
                    upstream_url: ${ollama_upstream_url}
variables:
  ollama_upstream_url:
    value: $OLLAMA_UPSTREAM_URL
{% endentity_examples %}


## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
