---
title: Route Claude CLI traffic through {{site.ai_gateway}} and Hugging Face
content_type: how_to
permalink: /ai-gateway/use-claude-code-with-ai-gateway-huggingface/

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic to a Hugging Face model

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

prereqs:
  inline:
    - title: Configure kongctl
      include_content: md/ai-gateway/v2/prereqs/kongctl
    - title: Hugging Face
      content: |
        1. Create a [Hugging Face access token](https://huggingface.co/settings/tokens) with inference permissions.
        1. Export the token as a bearer header value:
           ```bash
           export HUGGINGFACE_AUTH_HEADER='Bearer YOUR_HUGGINGFACE_TOKEN'
           ```

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - huggingface

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} against a Hugging Face model?
  a: Create an AI Provider entity to store your Hugging Face token, create an AI Policy that strips fields Claude CLI sends that Hugging Face's API rejects, create an AI Model entity with an Anthropic-compatible format that routes to Hugging Face through that provider, then point Claude CLI's `ANTHROPIC_BASE_URL` at your local {{site.ai_gateway}} endpoint so all LLM requests pass through the gateway for monitoring and control.

---

## Create an AI Provider entity

Create an [AI Provider](/ai-gateway/entities/ai-provider/) entity to define your connection to Hugging Face and store your access token:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
ai_gateways:
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: "ai-quickstart"

ai_gateway_model_providers:
  - ref: my-huggingface-account
    ai_gateway: ai-quickstart
    name: my-huggingface-account
    display_name: "Hugging Face"
    type: huggingface
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !env HUGGINGFACE_AUTH_HEADER
EOF
```

## Create an AI Policy entity

{{ site.claude_code }} sends beta headers and fields that Hugging Face's API rejects. Create an [AI Policy](/ai-gateway/entities/ai-policy/) with a `request-transformer-advanced` config that strips the `anthropic-beta` header, `beta` query string parameter, and `model`/`output_config` body fields before the request reaches Hugging Face:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
ai_gateways:
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: "ai-quickstart"

ai_gateway_policies:
  - ref: strip-claude-beta-info
    ai_gateway: ai-quickstart
    name: strip-claude-beta-info
    display_name: "Strip Claude beta info"
    type: request-transformer-advanced
    config:
      remove:
        headers:
          - anthropic-beta
        querystring:
          - beta
        body:
          - model
          - output_config
EOF
```

{:.info}
> {{ site.claude_code }} beta features vary by version and may add other incompatible fields over time. If you still see a `400` error mentioning an unexpected field after applying this Policy, add that field to the appropriate `remove` list and re-apply.

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream model is available and how client requests are routed. `formats: [type: anthropic]` accepts requests in Anthropic format even though the upstream is Hugging Face:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
ai_gateways:
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: "ai-quickstart"

ai_gateway_model_providers:
  - ref: my-huggingface-account
    ai_gateway: ai-quickstart
    _external:
      selector:
        matchFields:
          name: "my-huggingface-account"

ai_gateway_policies:
  - ref: strip-claude-beta-info
    ai_gateway: ai-quickstart
    _external:
      selector:
        matchFields:
          name: "strip-claude-beta-info"

ai_gateway_models:
  - ref: my-claude-huggingface
    ai_gateway: ai-quickstart
    name: my-claude-huggingface
    display_name: "my-claude-huggingface"
    type: model
    formats:
      - type: anthropic
    config:
      route:
        paths:
          - /
      model:
        alias: my-claude-huggingface
    targets:
      - name: meta-llama/Llama-3.3-70B-Instruct
        provider: my-huggingface-account
        config:
          type: huggingface
    policies:
      - !ref strip-claude-beta-info#name
    capabilities:
      - generate
EOF
```

## Validate the AI Model

Send a test request directly to confirm the setup works before pointing {{ site.claude_code }} at it:

```sh
curl -i -X POST http://localhost:8000/v1/messages \
  -H 'Content-Type: application/json' \
  -H 'anthropic-version: 2023-06-01' \
  --data '{
    "model": "my-claude-huggingface",
    "max_tokens": 1024,
    "messages": [
      {"role": "user", "content": "hello"}
    ]
  }'
```

## Verify traffic through Kong

{{ site.claude_code }}'s experimental beta features send fields that Hugging Face rejects even with the AI Policy in place. Disable them, then start a session pointed at your local {{site.ai_gateway}} endpoint:

```sh
export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1

ANTHROPIC_BASE_URL=http://localhost:8000/ \
ANTHROPIC_MODEL=my-claude-huggingface \
claude
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

Select **Yes, continue**. The session starts. Ask a simple question to confirm that requests reach {{site.ai_gateway}} and are routed to Hugging Face.
