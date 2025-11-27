---
title: Route Claude CLI traffic through Kong AI Gateway and Azure
content_type: how_to

related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: File Log
    url: /plugins/file-log/

description: Configure AI Gateway to proxy Claude CLI traffic using Azure OpenAI models

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
  a: Install Claude CLI, configure its API key helper, create a Gateway Service and Route, attach the AI Proxy plugin to forward requests to Claude, enable file-log to inspect traffic, and point Claude CLI to the local proxy endpoint so all LLM requests pass through the AI Gateway for monitoring and control.

tools:
  - deck

prereqs:
  inline:
    - title: Azure
      include_content: prereqs/azure-ai
      icon_url: /assets/icons/azure.svg
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

            Inside, put a dummy API key:

            ```sh
            echo "x"
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

First, let's configure the AI Proxy plugin for the Azure provider. This setup uses the default `llm/v1/chat` route. Claude Code sends its requests to this route. The configuration also raises the maximum request body size to 512 KB to support larger prompts. You do not pass the API key here, because the client-side steps store and supply it through the [helper script](/how-to/use-claude-code-with-ai-gateway/#claude-code-cli).

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        logging:
          log_statistics: true
          log_payloads: true
        route_type: llm/v1/chat
        llm_format: anthropic
        auth:
          header_name: Authorization
          header_value: Bearer ${azure_key}
        model:
          provider: azure
          options:
            azure_api_version: "2025-01-01-preview"
            azure_instance: ${azure_instance}
            azure_deployment_id: ${azure_deployment}
variables:
  azure_key:
    value: "$AZURE_OPENAI_API_KEY"
  azure_instance:
    value: "$AZURE_INSTANCE_NAME"
  azure_deployment:
    value: "$AZURE_DEPLOYMENT_ID"
{% endentity_examples %}

## Configure the File Log plugin

Now, let's enable the File Log plugin on the service, to inspect the LLM traffic between Claude and the AI Gateway. This creates a local `claude.json` file on your machine. The file records each request and response so you can review what Claude sends through the AI Gateway.

{% entity_examples %}
entities:
  plugins:
    - name: file-log
      config:
        path: "/tmp/claude.json"
{% endentity_examples %}

## Verify traffic through Kong

Now, we can start a Claude Code session that points it to the local AI Gateway endpoint:

{:.warning}
> Ensure that `ANTHROPIC_MODEL` matches the model you deployed in Azure.

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/anything \
ANTHROPIC_MODEL=<your_azure_model> \
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

Select **Yes, continue**. The session starts. Ask a simple question to confirm that requests reach the Gateway.

```text
Tell me about Vienna Oribasius manuscript.
```

Claude Code might prompt you approve its web search for answering the question. When you select **Yes** Claude will produce a full-length response to your request:

```text
The "Vienna Oribasius manuscript" refers to a famous illustrated medical
codex that preserves the works of Oribasius of Pergamon, a noted Greek
physician who lived in the 4th century CE. Oribasius was a compiler of
earlier medical knowledge, and his writings form an important link in the
transmission of Greco-Roman medical science to the Byzantine, Islamic, and
later European worlds.
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
    "meta": {
        "request_mode": "oneshot",
        "response_model": "gpt-4.1-2025-04-14",
        "request_model": "gpt-4.1",
        "llm_latency": 4606,
        "provider_name": "azure",
        "azure_deployment_id": "gpt-4.1",
        "plugin_id": "22122dc5-456e-4707-aec9-7ae3a0250ad5",
        "azure_api_version": "2024-12-01-preview",
        "azure_instance_id": "test-azyre-openai"
      },
      "usage": {
        "completion_tokens": 414,
        "completion_tokens_details": {
          "accepted_prediction_tokens": 0,
          "audio_tokens": 0,
          "rejected_prediction_tokens": 0,
          "reasoning_tokens": 0
        },
        "total_tokens": 11559,
        "cost": 0,
        "time_per_token": 11.125603864734,
        "time_to_first_token": 4605,
        "prompt_tokens": 11145,
        "prompt_tokens_details": {
          "audio_tokens": 0,
          "cached_tokens": 11008,
          "cached_tokens_details": {}
        }
      }
    }
  },
```
{:.no-copy-code}

This output confirms that Claude Code routed the request through Kong AI Gateway using the `gpt-4.1` Azure AI model we selected while starting Claude Code session.
