---
title: Route Claude CLI traffic through {{site.ai_gateway}} and AWS Bedrock
permalink: /how-to/use-claude-code-with-ai-gateway-bedrock/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: File Log
    url: /plugins/file-log/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic using AWS Bedrock models

products:
  - ai-gateway
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.13'

plugins:
  - ai-proxy
  - file-log

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - bedrock

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} with AWS Bedrock?
  a: Install Claude CLI, configure its API key helper, create a Gateway Service and Route, attach the AI Proxy plugin to forward requests to AWS Bedrock, enable file-log to inspect traffic, and point Claude CLI to the local proxy endpoint so all LLM requests pass through the {{site.ai_gateway}} for monitoring and control.

tools:
  - deck

prereqs:
  prereqs:
  inline:
    - title: AWS Bedrock
      icon_url: /assets/icons/bedrock.svg
      content: |
        1. Enable model access in AWS Bedrock:
           - Sign in to the AWS Management Console
           - Navigate to Amazon Bedrock
           - Select **Model access** in the left navigation
           - Request access to Claude models (for example, `us.anthropic.claude-haiku-4-5-20251001-v1:0`)
           - Wait for access approval (typically immediate for most models)

        2. Create an IAM user with Bedrock permissions:
           - Navigate to IAM in the AWS Console
           - Create a new user or select an existing user
           - Attach the `AmazonBedrockFullAccess` policy or create a custom policy with `bedrock:InvokeModel` permissions
           - Create access keys for the user

        3. Export the Access Key ID, Secret Access Key and AWS region to your environment:
           ```sh
           export DECK_AWS_ACCESS_KEY_ID='YOUR AWS ACCESS KEY ID'
           export DECK_AWS_SECRET_ACCESS_KEY='YOUR AWS SECRET ACCESS KEY'
           export DECK_AWS_REGION='YOUR AWS REGION'
           ```
    - title: Claude Code CLI
      icon_url: /assets/icons/third-party/claude.svg
      include_content: prereqs/claude-code
  entities:
    services:
      - example-service
    routes:
      - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Configure the AI Proxy plugin

Configure the AI Proxy plugin for the [AWS Bedrock provider](/ai-gateway/ai-providers/#bedrock).

* This setup uses the default `llm/v1/chat` route. Claude Code sends its requests to this route.
* The configuration also raises the maximum token count to 8192 KB to support larger prompts.

The `llm_format: anthropic` parameter tells {{site.ai_gateway}} to expect request and response payloads that match Claude's native API format. Without this setting, the gateway would default to OpenAI's format, which would cause request failures when Claude Code communicates with the Bedrock endpoint.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        llm_format: anthropic
        route_type: llm/v1/chat
        logging:
          log_statistics: true
          log_payloads: false
        auth:
          allow_override: false
          aws_access_key_id: ${aws_access_key_id}
          aws_secret_access_key: ${aws_secret_access_key}
        model:
          provider: bedrock
          name: us.anthropic.claude-haiku-4-5-20251001-v1:0
          options:
            anthropic_version: bedrock-2023-05-31
            bedrock:
              aws_region: ${aws_region}
            max_tokens: 8192
variables:
  aws_access_key_id:
    value: $AWS_ACCESS_KEY_ID
  aws_secret_access_key:
    value: $AWS_SECRET_ACCESS_KEY
  aws_region:
    value: $AWS_REGION
{% endentity_examples %}

## Configure the File Log plugin

Enable the [File Log](/plugins/file-log/) plugin on the service to inspect the LLM traffic between Claude and the {{site.ai_gateway}}. This creates a local `claude.json` file on your machine. The file records each request and response so you can review what Claude sends through the {{site.ai_gateway}}.

{% entity_examples %}
entities:
  plugins:
    - name: file-log
      config:
        path: "/tmp/claude.json"
{% endentity_examples %}

## Verify traffic through Kong

Start a Claude Code session that points to the local {{site.ai_gateway}} endpoint:

{:.warning}
> Ensure that `ANTHROPIC_MODEL` matches the model you configured in the AI Proxy plugin (for example, `us.anthropic.claude-haiku-4-5-20251001-v1:0`).

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/anything \
ANTHROPIC_MODEL=us.anthropic.claude-haiku-4-5-20251001-v1:0 \
claude
```

Claude Code asks for permission before it runs tools or interacts with files:

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
Tell me about Anna Komnene's Alexiad.
```

Claude Code might prompt you to approve its web search for answering the question. When you select **Yes**, Claude will produce a full-length response to your request:

```text
Anna Komnene (1083-1153?) was a Byzantine princess, scholar, physician,
hospital administrator, and historian. She is known for writing the
Alexiad, a historical account of the reign of her father, Emperor Alexios
I Komnenos (r. 1081-1118). The Alexiad is a valuable primary source for
understanding Byzantine history and the First Crusade.
```
{:.no-copy-code}

Next, inspect the {{site.ai_gateway}} logs to verify that the traffic was proxied through it:

```sh
docker exec kong-quickstart-gateway cat /tmp/claude.json | jq
```

You should find an entry that shows the upstream request made by Claude Code. A typical log record looks like this:

```json
{
  ...
  "method": "POST",
  "headers": {
    "user-agent": "claude-cli/2.0.37 (external, cli)",
    "content-type": "application/json"
  },
  ...
  "ai": {
    "proxy": {
      "tried_targets": [
        {
          "provider": "bedrock",
          "model": "us.anthropic.claude-haiku-4-5-20251001-v1:0",
          "port": 443,
          "upstream_scheme": "https",
          "host": "bedrock-runtime.us-west-2.amazonaws.com",
          "upstream_uri": "/model/us.anthropic.claude-haiku-4-5-20251001-v1:0/invoke",
          "route_type": "llm/v1/chat",
          "ip": "xxx.xxx.xxx.xxx"
        }
      ],
      "meta": {
        "request_model": "us.anthropic.claude-haiku-4-5-20251001-v1:0",
        "request_mode": "oneshot",
        "response_model": "us.anthropic.claude-haiku-4-5-20251001-v1:0",
        "provider_name": "bedrock",
        "llm_latency": 1542,
        "plugin_id": "13f5c57a-77b2-4c1f-9492-9048566db7cf"
      },
      "usage": {
        "completion_tokens": 124,
        "completion_tokens_details": {},
        "total_tokens": 11308,
        "cost": 0,
        "time_per_token": 12.435483870968,
        "time_to_first_token": 1542,
        "prompt_tokens": 11184,
        "prompt_tokens_details": {}
      }
    }
  }
  ...
}
```
{:.no-copy-code}

This output confirms that Claude Code routed the request through {{site.ai_gateway}} using AWS Bedrock with the `us.anthropic.claude-haiku-4-5-20251001-v1:0` model.