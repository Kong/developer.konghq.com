---
title: Set up AI Proxy Advanced with HuggingFace in {{site.base_gateway}}
permalink: /how-to/set-up-ai-proxy-advanced-with-huggingface/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI Proxy Advanced plugin to create a chat route using HuggingFace.

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
  - huggingface

tldr:
  q: How do I use the AI Proxy Advanced plugin with HuggingFace?
  a: Create a Gateway Service and a Route, then enable the AI Proxy Advanced plugin and configure it with the HuggingFace provider and add the model and your API key.

tools:
  - deck

prereqs:
  inline:
    - title: HuggingFace
      content: |
        You need an active HuggingFace account with API access. Sign up at [HuggingFace](https://huggingface.co/) and obtain your API token from the [Access Tokens page](https://huggingface.co/settings/tokens). Ensure you have access to the HuggingFace Inference API, and export your token to your environment:
        ```sh
        export DECK_HUGGINGFACE_TOKEN='YOUR HUGGINGFACE API TOKEN'
        ```
      icon_url: /assets/icons/huggingface.svg  
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

To set up AI Proxy Advanced with HuggingFace, we need to specify the model to use.

In this example, we'll use the Qwen3-4B-Instruct-2507 model:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${huggingface_token}
            model:
              provider: huggingface
              name: Qwen/Qwen3-4B-Instruct-2507
variables:
  huggingface_token:
    value: $HUGGINGFACE_TOKEN
    description: The token to use to connect to Hugging Face.
formats:
  - deck
{% endentity_examples %}  
<!--vale on-->

## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
