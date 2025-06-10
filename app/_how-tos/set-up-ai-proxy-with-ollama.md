---
title: Set up AI Proxy Advanced with Ollama
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI Proxy Advanced plugin to create a chat route using Ollama.

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
  - openai

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

To set up AI Proxy Advanced with OpenAI, specify the [model](https://platform.openai.com/docs/models) and set the appropriate authentication header.

In this example, we'll use the GPT-4o model:

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
                    upstream_url: http://llama2-server.local:11434/api/chat

{% endentity_examples %}

## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
