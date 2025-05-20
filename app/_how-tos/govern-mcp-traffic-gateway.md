---
title: How to govern end-user requests in MCP Traffic Gateway
content_type: how_to
permalink: /mcp/govern-mcp/
breadcrumbs:
    - /mcp/
description: Learn how to govern end-user requests in your MCP Traffic Gateway
products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

plugins:
  - ai-proxy
  - ai-semantic-prompt-guard
  - ai-prompt-guard

entities:
  - plugin

tags:
    - get-started
    - ai

tldr:
  q: How do I govern my MCP Traffic Gateway?
  a: |
    You can use...

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: Claude account and Claude desktop
      content: |
        To complete this tutorial, you'll need to have [Claude](https://claude.ai) account and [Claude desktop](https://claude.ai/download).
      icon_url: /assets/icons/third-party/claude.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.6'

next_steps:
  - text: Set up load balancing using AI Proxy Advanced plugin
    url: /plugins/ai-proxy-advanced/
  - text: Cache traffic using the AI Semantic cache plugin
    url: /plugins/ai-semantic-cache/
  - text: Secure traffic with the AI Prompt Guard
    url: /plugins/ai-prompt-guard/
  - text: Learn about all the AI plugins
    url: /plugins/?category=ai


automated_tests: false
---

## Configure the AI Prompt Guard plugin

{% entity_examples %}
entities:
  plugins:
    - name: ai-prompt-guard
      config:
        deny_patterns:
          - ".*(W|w)ar.*"
          - ".*(C|c)onflict.*"
{% endentity_examples %}

Now, for any requests that include phrases that match the deny pattern, will not be passed through the MCP Traffic Gateway.

## Configure the AI Semantic Prompt Guard plugin

To further secure conversational control over Kong Konnect with MCP Traffic Gateway, you can configure the AI Semantic Prompt Guard plugin that block prompts based on a list of similar prompts, helping to prevent misuse of `llm/v1/chat` or `llm/v1/completions` requests. In this case, the plugin is set to:
- Block prompts that are closely related to denied phrases such as "hijacking an LLM prompt," "questions about prompt injections," and "questions about prompt jailbreaking"
- Match against the entire conversation history for thorough filtering


{% entity_examples %}
entities:
  plugins:
    - name: ai-semantic-prompt-guard
      config:
        embeddings:
          auth:
            header_name: Authorization
            header_value: ${api_key}
          model:
            name: text-embedding-3-small
            provider: openai
        search:
          threshold: 0.7
        vectordb:
          strategy: redis
          distance_metric: cosine
          threshold: 0.5
          dimensions: 1024
          redis:
            host: localhost
            port: 6379
        rules:
          match_all_conversation_history: true
          deny_prompts:
            - hijacking an LLM prompt
            - questions about prompt injections
            - questions about prompt jailbreaking
variables:
  api_key:
    value: OPENAI_API_KEY
{% endentity_examples %}


## Test the configuration

Using this configuration, given the following AI Chat request:

```json
"messages": [
    {
      "role": "user",
      "content": "Say something about war!"
    }
  ]
```

Or

```json
sample
```

The caller will receive a `400` response, and the messages will not be passed through the MCP Traffic Gateway


