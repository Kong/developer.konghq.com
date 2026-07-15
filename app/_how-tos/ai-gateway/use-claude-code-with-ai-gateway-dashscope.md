---
title: Route Claude CLI traffic through {{site.ai_gateway}} and DashScope
permalink: /ai-gateway/use-claude-code-with-ai-gateway-dashscope/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic
    url: /ai-gateway/use-claude-code-with-ai-gateway-anthropic/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic to an Alibaba Cloud DashScope (Qwen) model.

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - dashscope

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} against a DashScope Qwen model?
  a: Create an AI Model Provider for Alibaba Cloud DashScope and an AI Model with the `anthropic` format that targets it, then point {{ site.claude_code }}'s `ANTHROPIC_BASE_URL` at your local {{site.ai_gateway}} endpoint so all requests pass through the gateway for monitoring and control.

prereqs:
  inline:
    - title: DashScope
      icon_url: /assets/icons/dashscope.svg
      content: |
        Get an API key from the [Alibaba Cloud DashScope console](https://dashscope.aliyuncs.com/) and export it as the **full `Authorization` header value** (including the `Bearer ` prefix):

        ```sh
        export DASHSCOPE_AUTH_HEADER="Bearer sk-..."
        ```
    - title: Claude Code CLI
      icon_url: /assets/icons/third-party/claude.svg
      include_content: prereqs/claude-code

---

## Create the AI Model Provider and AI Model

DashScope serves the Qwen model family through a native Anthropic-compatible Messages API, so {{ site.claude_code }} can talk to it with no client-side translation and no request-transformer policy. Create both the [AI Model Provider](/ai-gateway/entities/ai-model-provider/) and the [AI Model](/ai-gateway/entities/ai-model/) in a **single apply** so the model can reference the provider:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: dashscope-qwen

ai_gateways:
  # Reference your existing gateway by name without managing it (its control
  # plane and data plane are owned by the AI Gateway quickstart).
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: ai-quickstart

    model_providers:
      - ref: dashscope
        name: dashscope
        type: dashscope
        display_name: "Alibaba Cloud DashScope"
        config:
          auth:
            type: basic
            headers:
              - name: Authorization
                value: !env DASHSCOPE_AUTH_HEADER

    models:
      - ref: claude-code-qwen
        name: claude-code-qwen
        display_name: "Claude Code - DashScope Qwen"
        type: model
        enabled: true
        formats: [{ type: anthropic }]
        config:
          route: { paths: [/], methods: [GET, POST] }
          model: { alias: qwen-plus, name_header: true }
        capabilities: [generate]
        targets:
          - name: qwen-plus
            provider: dashscope
            config:
              type: dashscope
              international: true
              max_tokens: 8192
              temperature: 1.0
EOF
```

In this example:

 * `type: dashscope`: Connects to the Alibaba Cloud DashScope API.
 * `capabilities: [generate]`: For a model using the `anthropic` format, `generate` creates a `/messages` endpoint matching Anthropic's native Messages API, so combined with the base path clients send requests to `/v1/messages` — exactly what {{ site.claude_code }} sends.
 * `formats: [{ type: anthropic }]`: Accepts Anthropic-format requests, matching what {{ site.claude_code }} sends natively, even though the upstream model is a DashScope Qwen model.
 * `config.model.alias: qwen-plus`: The model name {{ site.claude_code }} sends in each request (`ANTHROPIC_MODEL` / `--model`).
 * `route.paths: [/]`: The base path {{ site.claude_code }} points at through `ANTHROPIC_BASE_URL`.
 * `targets[0].config.international: true`: Uses DashScope's international endpoint (`dashscope-intl.aliyuncs.com`). This is the default. If your DashScope key belongs to a mainland China account, set this to `false` so requests reach `dashscope.aliyuncs.com` instead.

## Verify the AI Model

Before starting {{ site.claude_code }}, confirm the route works by sending an Anthropic Messages API request directly (expect `200`):

```sh
curl -sS http://localhost:8000/v1/messages \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen-plus","max_tokens":16,"messages":[{"role":"user","content":"Reply with just: ok"}]}'
```

## Point Claude Code at {{site.ai_gateway}}

Open a new terminal and set `ANTHROPIC_BASE_URL` to the local {{site.ai_gateway}} endpoint. {{ site.claude_code }} requires an auth token to be set even though the real key lives on the gateway, so a placeholder is fine. Set `ANTHROPIC_SMALL_FAST_MODEL` as well so {{ site.claude_code }}'s background requests also route to a valid model:

```sh
export ANTHROPIC_BASE_URL=http://localhost:8000/
export ANTHROPIC_AUTH_TOKEN=placeholder
export ANTHROPIC_SMALL_FAST_MODEL=qwen-plus
```

## Start and use Claude Code

Run {{ site.claude_code }}, selecting the model you configured:

```sh
claude --model 'qwen-plus'
```

When {{ site.claude_code }} asks for permission to work with your files, select **Yes, continue**. The session starts. Ask a simple question to confirm traffic flows through {{site.ai_gateway}} to the upstream Qwen model:

```text
Say hello in one sentence.
```