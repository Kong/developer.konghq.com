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
      icon_url: /assets/icons/qwen.svg
      content: |
        Install Node.js 18+ (verify with `node --version`), then install the Qwen Code CLI:

        ```sh
        npm install -g @qwen-code/qwen-code
        ```

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
    ai_gateway: !lookup name:ai-quickstart
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
    ai_gateway: !lookup name:ai-quickstart
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

## Verify traffic through {{site.ai_gateway}}

Before starting Qwen Code CLI, confirm the route works by sending a Chat Completions request directly (expect `200`):

```sh
curl -sS http://localhost:8000/qwen-dashscope/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"my-qwen-dashscope","messages":[{"role":"user","content":"Reply with just: ok"}]}'
```

## Point Qwen Code CLI at {{site.ai_gateway}}

Open a new terminal and set `OPENAI_BASE_URL` to the local {{site.ai_gateway}} endpoint. Qwen Code CLI requires `OPENAI_API_KEY` to be set even though the real key lives on the gateway, so a placeholder is fine:

```sh
export OPENAI_API_KEY=sk-placeholder
export OPENAI_BASE_URL=http://localhost:8000/qwen-dashscope/chat/completions
```

## Run Qwen Code CLI

Run Qwen Code CLI against the model configured in the AI Model entity's `targets`:

```sh
qwen --model my-qwen-dashscope
```

Ask a simple question to confirm that requests reach {{site.ai_gateway}}:

```text
Explain the singleton pattern in Python.
```

Qwen Code CLI returns a response, proxied through {{site.ai_gateway}} to the upstream DashScope Qwen model.