---
title: Route Claude CLI traffic through {{site.ai_gateway}} and AWS Bedrock
content_type: how_to
permalink: /ai-gateway/use-claude-code-with-ai-gateway-bedrock/

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic
    url: /ai-gateway/use-claude-code-with-ai-gateway-anthropic/
  - text: Route Claude CLI traffic through {{site.ai_gateway}} and OpenAI
    url: /ai-gateway/use-claude-code-with-ai-gateway-openai/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic to an AWS Bedrock model

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

prereqs:
  gateway:
    - name: KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=2m
  konnect:
     - name: KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=2m
  inline:
    - title: AWS Bedrock
      content: |
        1. Enable model access in AWS Bedrock:
           1. Sign in to the AWS Management Console.
           1. Navigate to Amazon Bedrock.
           1. Select **Model access** in the left navigation.
           1. Request access to Claude models (for example, `us.anthropic.claude-haiku-4-5-20251001-v1:0`).
        1. Create an IAM user with Bedrock permissions:
           1. Navigate to IAM in the AWS Console.
           1. Create a new user or select an existing user.
           1. Attach the `AmazonBedrockFullAccess` policy, or create a custom policy with `bedrock:InvokeModel` permissions.
           1. Create access keys for the user.
        1. Export your AWS credentials and region:
           ```bash
           export AWS_ACCESS_KEY_ID='YOUR_AWS_ACCESS_KEY_ID'
           export AWS_SECRET_ACCESS_KEY='YOUR_AWS_SECRET_ACCESS_KEY'
           export AWS_REGION='YOUR_AWS_REGION'
           ```

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - bedrock

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} against an AWS Bedrock model?
  a: Create an AI Provider entity to store your AWS credentials, create an AI Policy that strips fields Claude CLI sends that Bedrock rejects, create an AI Model entity with an Anthropic-compatible format that routes to Bedrock through that provider, then point Claude CLI's `ANTHROPIC_BASE_URL` at your local {{site.ai_gateway}} endpoint so all LLM requests pass through the gateway for monitoring and control.

---

## Create an AI Provider entity

Create an [AI Provider](/ai-gateway/entities/ai-provider/) entity to define your connection to AWS Bedrock and store your IAM credentials:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
ai_gateways:
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: "ai-quickstart"

ai_gateway_model_providers:
  - ref: my-aws-account
    ai_gateway: ai-quickstart
    name: my-aws-account
    display_name: "AWS Production"
    type: bedrock
    config:
      auth:
        type: aws
        access_key_id: !env AWS_ACCESS_KEY_ID
        secret_access_key: !env AWS_SECRET_ACCESS_KEY
    _external:
      selector:
        matchFields:
          name: "my-aws-account"
EOF
```

## Create an AI Policy entity

{{ site.claude_code }} sends beta headers and fields that Bedrock's API rejects. Create an [AI Policy](/ai-gateway/entities/ai-policy/) with a `request-transformer` config that strips the `anthropic-beta` header, `beta` query string parameter, and beta-gated body fields before the request reaches Bedrock. Don't strip `model`: {{site.ai_gateway}} uses that field to select the target, and removing it breaks routing.

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
    type: request-transformer
    config:
      remove:
        headers:
          - anthropic-beta
        querystring:
          - beta
        body:
          - output_config
          - context_management
          - mcp_servers
          - container
          - service_tier
    _external:
      selector:
        matchFields:
          name: "strip-claude-beta-info"
EOF
```

{:.info}
> {{ site.claude_code }} beta features vary by version and may add other incompatible fields over time. If you still see a `400` error mentioning an unexpected field after applying this Policy, add that field to the appropriate `remove` list and re-apply.

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream model is available and how client requests are routed. `formats: [type: anthropic]` accepts requests in Anthropic format even though the upstream is Bedrock:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
ai_gateways:
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: "ai-quickstart"

ai_gateway_model_providers:
  - ref: my-aws-account
    ai_gateway: ai-quickstart
    name: my-aws-account
    display_name: "AWS Production"
    type: bedrock
    config:
      auth:
        type: aws
        access_key_id: !env AWS_ACCESS_KEY_ID
        secret_access_key: !env AWS_SECRET_ACCESS_KEY

ai_gateway_policies:
  - ref: strip-claude-beta-info
    ai_gateway: ai-quickstart
    name: strip-claude-beta-info
    display_name: "Strip Claude beta info"
    type: request-transformer
    config:
      remove:
        headers:
          - anthropic-beta
        querystring:
          - beta
        body:
          - output_config
          - context_management
          - mcp_servers
          - container
          - service_tier

ai_gateway_models:
  - ref: my-claude-bedrock
    ai_gateway: ai-quickstart
    name: my-claude-bedrock
    display_name: "my-claude-bedrock"
    type: model
    formats:
      - type: anthropic
    config:
      route:
        paths:
          - /
      model:
        alias: my-claude-bedrock
    targets:
      - name: us.anthropic.claude-haiku-4-5-20251001-v1:0
        provider: my-aws-account
        config:
          type: bedrock
          region: !env AWS_REGION
    policies:
      - !ref strip-claude-beta-info#name
    capabilities:
      - generate
EOF
```

## Verify traffic through Kong

{{ site.claude_code }}'s experimental beta features send fields that Bedrock rejects even with the AI Policy in place. Disable them, then start a session pointed at your local {{site.ai_gateway}} endpoint:

```sh
export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1

ANTHROPIC_BASE_URL=http://localhost:8000/ \
ANTHROPIC_MODEL=my-claude-bedrock \
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

Select **Yes, continue**. The session starts. Ask a simple question to confirm that requests reach {{site.ai_gateway}} and are routed to Bedrock.
