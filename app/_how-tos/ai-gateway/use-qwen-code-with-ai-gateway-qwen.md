---
title: Route Qwen Code CLI traffic through {{site.ai_gateway}} and DashScope
permalink: /ai-gateway/use-qwen-code-with-ai-gateway-qwen/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Route Qwen Code CLI traffic through {{site.ai_gateway}} and OpenAI
    url: /ai-gateway/use-qwen-code-with-ai-gateway-openai/

description: Configure {{site.ai_gateway}} to proxy Qwen Code CLI traffic to an Alibaba Cloud DashScope model

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
  - dashscope

tldr:
  q: How do I run Qwen Code CLI through {{site.ai_gateway}} against a DashScope model?
  a: Create an AI Model Provider for Alibaba Cloud DashScope and an AI Model with the `generate` capability that targets it, then point Qwen Code CLI's `OPENAI_BASE_URL` at your local {{site.ai_gateway}} endpoint so all requests pass through the gateway for monitoring and control.

tools:
  - kongctl

prereqs:
  inline:
    - title: DashScope
      icon_url: /assets/icons/alibaba-cloud.svg
      content: |
        Get an API key from the [Alibaba Cloud DashScope console](https://dashscope.aliyuncs.com/) and export it as the **full `Authorization` header value** (including the `Bearer` prefix):

        ```sh
        export DASHSCOPE_AUTH_HEADER="Bearer YOUR_DASHSCOPE_KEY"
        ```
    - title: Qwen Code CLI
      include_content: md/ai-gateway/v2/prereqs/qwen-code-cli
      icon_url: /assets/icons/qwen.svg

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

---

## Create an AI Model Provider and AI Model

DashScope serves the Qwen model family through an OpenAI-compatible Chat Completions API, so Qwen Code CLI can talk to it natively.

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection and store your authentication credentials.

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Model Provider to use.

{% entity_examples %}
ai_gateway_model_providers:
  - ref: dashscope
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: dashscope
    display_name: "Alibaba Cloud DashScope"
    type: dashscope
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !env DASHSCOPE_AUTH_HEADER
ai_gateway_models:
  - ref: my-qwen-dashscope
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-qwen-dashscope
    display_name: "my-qwen-dashscope"
    type: model
    formats: [{ type: openai }]
    config:
      route:
        paths: [/qwen-dashscope]
        model:
          body_param: model
          values: [my-qwen-dashscope]
    targets:
      - name: qwen-plus
        provider: dashscope
        config:
          type: dashscope
          international: true
    capabilities: [generate]
{% endentity_examples %}

This example uses the following settings:

* `targets`: Sends requests to `qwen-plus` through the `dashscope` provider.
* `targets[0].config.international: true`: Uses DashScope's international endpoint (`dashscope-intl.aliyuncs.com`); set it to `false` if your DashScope key belongs to a mainland China account.
* `capabilities: [generate]`: Exposes the model at a `/qwen/chat/completions` endpoint.

## Run Qwen Code CLI

Run Qwen Code CLI against the model configured in the AI Model entity's `targets`:

<!--vale off-->
{% validation qwen %}
open_api_key: sk-placeholder
base_url: http://localhost:8000/qwen-dashscope/chat/completions
model: my-qwen-dashscope
auth-type: openai
prompt: Explain the singleton pattern in Python.
{% endvalidation %}
<!--vale on-->

Qwen Code CLI returns a response, proxied through {{site.ai_gateway}} to the upstream DashScope Qwen model.

{:.info}
> The Qwen Code CLI requires `OPENAI_API_KEY` to be set even though the real key lives on the {{site.ai_gateway}}, so setting a placeholder is fine.