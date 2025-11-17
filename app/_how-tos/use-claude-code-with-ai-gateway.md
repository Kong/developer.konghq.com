---
title: Route Claude CLI traffic through Kong AI Gateway
content_type: how_to

related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: File Log
    url: /plugins/file-log/

description: Configure AI Gateway to proxy Claude CLI traffic

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.13'

plugins:
  - ai-proxy-advanced
  - file-log

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I run Claude CLI through Kong AI Gateway?
  a: Install Claude CLI, configure its API key helper, create a Gateway Service and Route, attach the AI Proxy plugin to forward requests to Claude, enable file-log to inspect traffic, and point Claude CLI to the local proxy endpoint so all LLM requests pass through the Gateway for monitoring and control.

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: Claude Code CLI
      icon_url: /assets/icons/third-party/claude.svg
      content: |
        1. Install Claude:

            ```sh
            curl -fsSL https://claude.ai/install.sh | bash
            ```

        2. Create or edit the Claude settings file:

            ```sh
            mkdir -p ~/.claude
            nano ~/.claude/settings.json
            ```

            Put this exact content in the file:

            ```json
            {
              "apiKeyHelper": "~/.claude/anthropic_key.sh"
            }
            ```

        3. Create the API key helper script:

            ```sh
            nano ~/.claude/anthropic_key.sh
            ```

            Inside, put your real API key:

            ```sh
            echo "sk-your-real-anthropic-key-here"
            ```

        4. Make the script executable:

            ```sh
            chmod +x ~/.claude/anthropic_key.sh
            ```

        5. Verify it works by running the script:

            ```sh
            ~/.claude/anthropic_key.sh
            ```

            You should see only your API key printed.
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

First, let's configure the AI Proxy plugin for the Anthropic provider. This setup uses the default llm/v1/chat route. Claude Code sends its requests to this route. The configuration also raises the maximum request body size to 512 KB to support larger prompts. You do not pass the API key here, because the client-side steps store and supply it through the [helper script](/how-to/use-claude-code-with-ai-gateway/#claude-code-cli).

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        model:
          provider: anthropic
          options:
            anthropic_version: "2023-06-01"
        llm_format: anthropic
        logging:
          log_statistics: true
        max_request_body_size: 524288
        route_type: llm/v1/chat
{% endentity_examples %}

## Configure the File Log plugin

Now, let's enable the File Log plugin on the service, to inspect the LLM traffic between Claude and the AI Gateway. This creates a local log file `claude.json` so we can review requests and responses as Claude runs through the AI Gateway.

{% entity_examples %}
entities:
  plugins:
    - name: file-log
      config:
        path: "/tmp/claude.json"
{% endentity_examples %}

## Verify traffic through Kong

Now, we can start a Claude Code session that points it to the local AI Gateway endpoint:

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/anything \
ANTHROPIC_MODEL=claude-sonnet-4-20250514 \
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

Choose **Yes, continue**. The session starts. Ask a simple question to confirm that requests reach the Gateway.

```text
What's the Stokes' theorem?
```

Claude Code responds with a complete explanation of the theorem. This confirms that the CLI can reach your proxy endpoint and that the model works as expected:

```text
Stokes' theorem is a fundamental result in vector calculus thatgeneralizes several important theorems and provides a relationship between surface integrals and line integrals.

Statement

For a smooth oriented surface S bounded by a simple closed curve C, and avector field F that is continuously differentiable on S:

  ∮_C F · dr = ∬_S (∇ × F) · n dS

Where:
- The left side is a line integral around the boundary curve C
- The right side is a surface integral over the surface S
- ∇ × F is the curl of the vector field F
- n is the unit normal vector to the surface S
- The orientation of C and S must be consistent (right-hand rule)
```
{:.no-copy-code}

Next, inspect the Kong AI Gateway logs to verify that the traffic was proxied through it:

```sh
docker exec kong-quickstart-gateway cat /tmp/claude.json | jq
```

You should find an entry that shows the upstream request made by Claude Code. A typical log record looks like this:

```json
{
  "...": "...",
  "headers": {
    ...
    "user-agent": "claude-cli/2.0.37 (external, cli)",
    "content-type": "application/json",
    ...
  },
  "method": "POST",
  ...
  "ai": {
    "proxy": {
      "usage": {
        "prompt_tokens": 119,
        "prompt_tokens_details": {},
        "completion_tokens": 29,
        "total_tokens": 148,
        "cost": 0,
        "time_per_token": 48.793103448276,
        "time_to_first_token": 1286,
        "completion_tokens_details": {}
      },
      "meta": {
        "request_model": "claude-haiku-4-5-20251001",
        "response_model": "claude-haiku-4-5-20251001",
        "llm_latency": 1415,
        "plugin_id": "7705ed4d-2423-444f-b635-b5f5bb4b3331",
        "request_mode": "stream",
        "provider_name": "anthropic"
      }
    }
  }
  ...
}
```
{:.no-copy-code}

This output confirms that Claude Code routed the request through Kong AI Gateway using the `claude-haiku` model.
