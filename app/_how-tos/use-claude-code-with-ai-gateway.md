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
      icon_url: /assets/icons/claude.svg
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

First, let's configure the AI Proxy plugin for Claude. In this setup, we use the default route because the Claude CLI sends requests there. We specify the anthropic provider and model version in the plugin. We also increase the maximum request body size to 512 KB to handle larger prompts.

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

Finally, to inspect the LLM traffic between Claude and the AI Gateway, let's enable the File Log plugin on the service. This creates a local log file so we can review requests and responses as Claude runs through Kong.

{% entity_examples %}
entities:
  plugins:
    - name: file-log
      service: codex-service
      config:
        path: "/tmp/claude.json"
{% endentity_examples %}

## Verify traffic through Kong

Run a test query in Claude:

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/anything \
ANTHROPIC_MODEL=claude-sonnet-4-20250514 \
claude
```

Claude Code will then prompt you to give permission:


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

Enter Yes. Let's generate some traffic over Claude code:

```text
What's the Stokes' theorem?
```

Claude Code should produce the following output:

```text
Stokes' theorem is a fundamental result in vector calculus that generalizes several important theorems and provides a relationship between surface integrals and line integrals.

Statement

For a smooth oriented surface S bounded by a simple closed curve C, and a
  vector field F that is continuously differentiable on S:

  ∮_C F · dr = ∬_S (∇ × F) · n dS

Where:
  - The left side is a line integral around the boundary curve C
  - The right side is a surface integral over the surface S
  - ∇ × F is the curl of the vector field F
  - n is the unit normal vector to the surface S
  - The orientation of C and S must be consistent (right-hand rule)
```

Now, let's inspect traffic through AI Gateway:

``` sh
docker exec kong-quickstart-gateway cat /tmp/claude.json | jq
```

Look for entries showing upstream requests to Claude, including `route_type` and `provider: anthropic`.