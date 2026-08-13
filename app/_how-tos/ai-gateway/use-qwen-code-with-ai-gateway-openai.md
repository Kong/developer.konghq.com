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

Qwen Code CLI speaks OpenAI's Chat Completions format natively. Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) for your OpenAI credentials and an [AI Model](/ai-gateway/entities/ai-model/) that routes to it, in a single `kongctl` apply command so the model can reference the provider:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: generic-openai
    ai_gateway: !lookup name:ai-quickstart
    name: generic-openai
    display_name: "generic-openai"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !env OPENAI_AUTH_HEADER
ai_gateway_models:
  - ref: my-qwen-openai
    ai_gateway: !lookup name:ai-quickstart
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

`targets` sends requests to `gpt-5-mini` through the `generic-openai` provider. The `generate` capability combined with `config.route.paths: [/qwen]` exposes the model at `/qwen/chat/completions`.

## Verify the AI Model

Before starting Qwen Code CLI, confirm the route works by sending a Chat Completions request directly (expect `200`):

```sh
curl -sS http://localhost:8000/qwen/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"my-qwen-openai","messages":[{"role":"user","content":"Reply with just: ok"}]}'
```

## Point Qwen Code CLI at {{site.ai_gateway}}

Open a new terminal and set `OPENAI_BASE_URL` to the local {{site.ai_gateway}} endpoint. Qwen Code CLI requires `OPENAI_API_KEY` to be set even though the real key lives on the gateway, so a placeholder is fine:

```sh
export OPENAI_API_KEY=sk-placeholder
export OPENAI_BASE_URL=http://localhost:8000/qwen/chat/completions
```

## Start and use Qwen Code CLI

Run Qwen Code CLI against the model configured in the AI Model entity's `targets`:

```sh
qwen --model my-qwen-openai
```

Ask a simple question to confirm that requests reach {{site.ai_gateway}}:

```text
Explain the singleton pattern in Python.
```

Qwen Code CLI returns a response, proxied through {{site.ai_gateway}} to the OpenAI model.
