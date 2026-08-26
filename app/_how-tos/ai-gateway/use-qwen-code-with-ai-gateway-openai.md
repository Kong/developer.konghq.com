---
title: Route Qwen Code CLI traffic through {{site.ai_gateway}} and OpenAI
permalink: /ai-gateway/use-qwen-code-with-ai-gateway-openai/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Configure {{site.ai_gateway}} to proxy Qwen Code CLI traffic to an OpenAI model

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-model-provider
  - ai-model

tags:
  - ai
  - openai

tldr:
  q: How do I run Qwen Code CLI through {{site.ai_gateway}}?
  a: Create an AI Model Provider for OpenAI and an AI Model with the `generate` capability, then point Qwen Code CLI's `OPENAI_BASE_URL` at your local {{site.ai_gateway}} endpoint so all requests pass through the gateway for monitoring and control.

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
      icon_url: /assets/icons/openai.svg
    - title: Qwen Code CLI
      include_content: md/ai-gateway/v2/prereqs/qwen-code-cli
      icon_url: /assets/icons/qwen.svg

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

---

## Create an AI Model Provider and AI Model

Qwen Code CLI speaks OpenAI's Chat Completions format natively.

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection and store your authentication credentials.

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Model Provider to use.

{% entity_examples %}
ai_gateway_model_providers:
  - ref: generic-openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: generic-openai
    display_name: "generic-openai"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_AUTH_HEADER}
ai_gateway_models:
  - ref: my-qwen-openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-qwen-openai
    display_name: "my-qwen-openai"
    type: model
    formats: [{ type: openai }]
    config:
      route:
        paths: [/qwen]
        model:
          body_param: model
          values: [my-qwen-openai]
    targets:
      - name: gpt-5-mini
        provider: generic-openai
        config:
          type: openai
    capabilities: [generate]
{% endentity_examples %}

This example uses the following settings:
* `targets`: Sends requests to `gpt-5-mini` through the `generic-openai` provider.
* `capabilities: [generate]`: Exposes the model at a `/qwen/chat/completions` endpoint.

## Run Qwen Code CLI

Run Qwen Code CLI against the model configured in the AI Model entity's `targets`:

<!--vale off-->
{% validation qwen %}
base_url: http://localhost:8000/qwen/chat/completions
model: my-qwen-openai
auth-type: openai
prompt: Explain the singleton pattern in Python.
{% endvalidation %}
<!--vale on-->

Qwen Code CLI returns a response, proxied through {{site.ai_gateway}} to the OpenAI model.

{:.info}
> The Qwen Code CLI requires `OPENAI_API_KEY` to be set even though the real key lives on the {{site.ai_gateway}}.
