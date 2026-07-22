---
title: Route Claude CLI traffic through {{site.ai_gateway}} and DashScope
permalink: /ai-gateway/use-claude-code-with-ai-gateway-dashscope/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic
    url: /ai-gateway/use-claude-code-with-ai-gateway-anthropic/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic to an Alibaba Cloud DashScope model.

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
  q: How do I run Claude CLI through {{site.ai_gateway}} against a DashScope model?
  a: Create an AI Model Provider for Alibaba Cloud DashScope and an AI Model with the `anthropic` format that targets it, then point {{ site.claude_code }}'s `ANTHROPIC_BASE_URL` at your local {{site.ai_gateway}} endpoint so all requests pass through the gateway for monitoring and control.

prereqs:
  inline:
    - title: DashScope
      icon_url: /assets/icons/dashscope.svg
      content: |
        Get an API key from the [Alibaba Cloud DashScope console](https://dashscope.aliyuncs.com/) and export it as the **full `Authorization` header value** (including the `Bearer` prefix):

        ```sh
        export DASHSCOPE_AUTH_HEADER="Bearer YOUR_DASHSCOPE_KEY"
        ```
    - title: Claude Code CLI
      icon_url: /assets/icons/third-party/claude.svg
      include_content: prereqs/claude-code

---

## Create the AI Model Provider and AI Model

DashScope serves the Qwen model family through a native Anthropic-compatible Messages API, so {{ site.claude_code }} can talk to it natively. 

Create both an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) and an [AI Model](/ai-gateway/entities/ai-model/) with a single `kongctl` apply command:

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
          route: { paths: [/], methods: [GET, POST], model: { body: { model: [qwen-plus] } } }
          model: { name_header: true }
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

In this example we set:

 * `type: dashscope`: Connects to the Alibaba Cloud DashScope API as an AI Model Provider.
 * `capabilities: [generate]`: For a model using the `anthropic` format, `generate` creates a `/v1/messages` endpoint matching Anthropic's native Messages API.
 * `formats: [{ type: anthropic }]`: Accepts Anthropic-format requests to the AI Model entity, matching what {{ site.claude_code }} sends.
 * `config.route.model.body: { model: [qwen-plus] }`: The model name {{ site.claude_code }} should send in each request, which you can set with the `ANTHROPIC_MODEL` variable or `--model` option.
 * `route.paths: [/]`: Configures the custom base path where this model's routes will be accessible. Setting this to a unique value avoids clashes when you have multiple AI Models.
 * `targets[0].config.international: true`: Uses DashScope's international endpoint (`dashscope-intl.aliyuncs.com`). This is the default. If your DashScope key belongs to a mainland China account, set this to `false` so requests reach `dashscope.aliyuncs.com` instead.

## Verify traffic through {{site.ai_gateway}}

Before starting {{ site.claude_code }}, confirm the route works by sending an Anthropic Messages API request directly:

```sh
curl -sS http://localhost:8000/v1/messages \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen-plus","max_tokens":16,"messages":[{"role":"user","content":"Reply with just: ok"}]}'
```

## Start and use Claude Code

Run {{ site.claude_code }}, selecting the model you configured:

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/ claude --model 'qwen-plus'
```

When {{ site.claude_code }} asks for permission to work with your files, select **Yes, continue**. The session will start. Ask a question to confirm traffic flows through {{site.ai_gateway}} to the upstream Qwen model:

```text
Say hello in one sentence.
```
