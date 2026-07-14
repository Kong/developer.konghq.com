---
title: Route Claude CLI traffic through {{site.ai_gateway}} and OpenAI
content_type: how_to
permalink: /ai-gateway/use-claude-code-with-ai-gateway-openai/

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic
    url: /ai-gateway/use-claude-code-with-ai-gateway-anthropic/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic to an OpenAI model

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - openai

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} against an OpenAI model?
  a: Create an AI Provider entity to store your OpenAI API key, create an AI Model entity with an Anthropic-compatible format that routes to OpenAI through that provider, then point Claude CLI's `ANTHROPIC_BASE_URL` at your local {{site.ai_gateway}} endpoint so all LLM requests pass through the gateway for monitoring and control.

---

## Create an AI Provider entity

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection to OpenAI and store your authentication credentials:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: ai-gateway-get-started

ai_gateways:
  - ref: ai-quickstart
    name: ai-quickstart
    display_name: "ai-quickstart"

ai_gateway_model_providers:
  - ref: generic-openai
    ai_gateway: ai-quickstart
    name: generic-openai
    display_name: "generic-openai"
    type: openai
    config:
      auth:
        type: basic
        headers:
        - name: Authorization
          value: !env OPENAI_AUTH_HEADER
EOF
```

In this example, we're setting up the AI Model Provider with:

* `type: openai`: Specifies that this provider connects to the OpenAI service using OpenAI's standard API format.
* `name: generic-openai`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth`: Stores your OpenAI API key. `header_value: !env OPENAI_AUTH_HEADER` loads the value from your environment at apply time instead of embedding it in the YAML, and `kongctl` redacts it in plan and diff output. {{site.ai_gateway}} securely manages this credential and injects it into upstream requests automatically, eliminating the need for clients to pass API keys.

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Provider to use:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: ai-gateway-get-started

ai_gateways:
  - ref: ai-quickstart
    name: ai-quickstart
    display_name: "ai-quickstart"

ai_gateway_models:
  - ref: my-claude-openai
    ai_gateway: ai-quickstart
    name: my-claude-openai
    display_name: "my-claude-openai"
    type: model
    formats:
      - type: anthropic
    config:
      route:
        paths:
          - /
      model:
        alias: my-claude-openai
    targets:
      - name: gpt-5-mini
        provider: generic-openai
        config:
          type: openai
    policies: []
    capabilities:
      - generate
EOF
```

In this example, we're setting up the AI Model with:

* `type: model`: Specifies this is a synchronous model for request/response workloads.
* `name: my-claude-openai`: A unique identifier for this model.
* `formats: [type: anthropic]`: Declares that this model accepts requests in Anthropic-compatible format, matching what {{ site.claude_code }} sends natively, even though the upstream model is OpenAI.
* `config.route.paths: [/]`: Configures the custom base path where this model's Routes will be accessible. Setting this to a unique value avoids clashes when you have multiple AI Models.
* `capabilities: [generate]`: Enables the text generation capability. For a model using the `anthropic` format, the `generate` capability creates a `/messages` endpoint matching Anthropic's native Messages API, so combined with your base path, clients send requests to `/v1/messages`.
* `targets`: Specifies which upstream AI Provider model to route requests to. Here, `provider: generic-openai` references the AI Provider we created earlier, and `name: gpt-5-mini` specifies which OpenAI model to call upstream.

## Verify traffic through Kong

Now, we can start a {{ site.claude_code }} session that points it to the local {{site.ai_gateway}} endpoint:

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/ ANTHROPIC_MODEL=my-claude-openai claude
```

{{ site.claude_code }} asks for permission before it runs tools or interacts with files:

```text
I'll need permission to work with your files.

This means I can:
- Read any file in this folder
- Create, edit, or delete files
- Run commands (like npm, git, tests, ls, rm)
- Use tools defined in .mcp.json

Learn more ( https://docs.claude.com/s/claude-code-security )

❯ 1. Yes, continue
2. No, exit
```
{:.no-copy-code}

Select **Yes, continue**. The session starts. Ask a simple question to confirm that requests reach {{site.ai_gateway}}.

```text
Tell me about Procopius' Secret History.
```

{{ site.claude_code }} might prompt you approve its web search for answering the question. When you select **Yes**, {{ site.claude }} will produce a full-length response to your request, proxied through {{site.ai_gateway}} to the OpenAI model configured in the AI Model entity's `targets`.
