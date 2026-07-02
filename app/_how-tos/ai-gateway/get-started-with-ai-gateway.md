---
title: Get started with {{site.ai_gateway}}
content_type: how_to
permalink: /ai-gateway/get-started/
description: Learn how to quickly get started with {{site.ai_gateway}}
products:
    - ai-gateway

works_on:
    - konnect

tags:
    - get-started
    - ai
    - openai

tldr:
  q: What is {{site.ai_gateway}}, and how can I get started with it?
  a: |
    With {{site.ai_gateway}}, you can deploy AI infrastructure for traffic
    that is sent to one or more LLMs.

tools:
    - deck

prereqs:
  inline:
    - title: OpenAI
      content: |
        This tutorial uses the AI Proxy plugin with OpenAI. You'll need to [create an OpenAI account](https://auth.openai.com/create-account) and [get an API key](https://platform.openai.com/api-keys). Once you have your API key, create an environment variable:

        ```sh
        export OPENAI_API_KEY='<api-key>'
        ```

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.ai_gateway}} container
      include_content: cleanup/products/ai-gateway
      icon_url: /assets/icons/ai-gateway.svg

min_version:
    ai-gateway: '2.0'
---

## Placeholder

lorem ipsum