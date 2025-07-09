---
title: Use the AI Prompt Template plugin
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Configure the

products:
  - gateway
  - ai-gateway

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
  - openai

tldr:
  q: How do I use
  a: Create

tools:
  - deck

prereqs:
  inline:
    - title: Mistral
      include_content: prereqs/mistral
      icon_url: /assets/icons/mistral.svg
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


{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${key}
        model:
          provider: mistral
          name: mistral-small-2506
          options:
            mistral_format: openai
            upstream_url: https://api.mistral.ai/v1/chat/completions

variables:
  key:
    value: $MISTRAL_API_KEY
    description: The API key to use to connect to Mistral.
{% endentity_examples %}


## Configure the AI Prompt Template plugin


{% entity_examples %}
entities:
  plugins:
    - name: ai-prompt-template
      config:
        templates:
          - name: summarizer
            template: |-
              {
                  "messages": [
                    {
                      "role": "system",
                      "content": "You summarize long texts into concise bullet points."
                    },
                    {
                      "role": "user",
                      "content": "Summarize the following text:\n\n{{text}}"
                    }
                  ]
              }
          - name: code-explainer
            template: |-
              {
                  "messages": [
                    {
                      "role": "system",
                      "content": "You are a helpful assistant who explains code to beginners."
                    },
                    {
                      "role": "user",
                      "content": "Explain what the following code does:\n\n{{code}}"
                    }
                  ]
              }
          - name: email-drafter
            template: |-
              {
                  "messages": [
                    {
                      "role": "system",
                      "content": "You write professional emails based on user input."
                    },
                    {
                      "role": "user",
                      "content": "Draft an email about {{topic}} to {{recipient}}."
                    }
                  ]
              }
          - name: product-describer
            template: |-
              {
                  "messages": [
                    {
                      "role": "system",
                      "content": "You write engaging product descriptions."
                    },
                    {
                      "role": "user",
                      "content": "Describe the product: {{product_name}}, which has the following features: {{features}}."
                    }
                  ]
              }
          - name: qna
            template: |-
              {
                  "messages": [
                    {
                      "role": "system",
                      "content": "You answer questions clearly and accurately."
                    },
                    {
                      "role": "user",
                      "content": "Answer the following question:\n\n{{question}}"
                    }
                  ]
              }
{% endentity_examples %}


## Validate your configuration
