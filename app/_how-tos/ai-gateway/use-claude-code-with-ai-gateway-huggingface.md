---
title: Route Claude CLI traffic through {{site.ai_gateway}} and HuggingFace
permalink: /how-to/use-claude-code-with-ai-gateway-huggingface/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: Pre-function
    url: /plugins/pre-function/
  - text: File Log
    url: /plugins/file-log/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic using HuggingFace Inference API models

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.13'

plugins:
  - pre-function
  - ai-proxy
  - file-log

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - huggingface

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} with HuggingFace?
  a: Install Claude CLI, configure a pre-function plugin to remove the model field from requests, attach the AI Proxy plugin to forward requests to HuggingFace, enable file-log to inspect traffic, and point Claude CLI to the local proxy endpoint so all LLM requests pass through the {{site.ai_gateway}} for monitoring and control.

tools:
  - deck

prereqs:
  inline:
    - title: HuggingFace
      icon_url: /assets/icons/huggingface.svg
      content: |
        You need an active HuggingFace account with API access. Sign up at [HuggingFace](https://huggingface.co/) and obtain your API token from the [Access Tokens page](https://huggingface.co/settings/tokens). Ensure you have access to the HuggingFace Inference API, and export your token to your environment:
        ```sh
        export DECK_HUGGINGFACE_API_TOKEN='YOUR HUGGINGFACE API TOKEN'
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

automated_tests: false
---

## Configure the Pre-function plugin

Claude CLI automatically includes a `model` field in its request payload. However, when the AI Proxy plugin is configured with HuggingFace provider and specific model in its settings, this creates a conflict. The pre-function plugin removes the `model` field from incoming requests before they reach the AI Proxy plugin, ensuring the gateway uses the model you configured rather than the one Claude CLI sends.

{% entity_examples %}
entities:
  plugins:
    - name: pre-function
      config:
        access:
          - |
            local body = kong.request.get_body("application/json", nil, 10485760)
            if not body or body == "" then
              return
            end
            body.model = nil
            kong.service.request.set_body(body, "application/json")
{% endentity_examples %}

## Configure the AI Proxy plugin

Configure the AI Proxy plugin for the [HuggingFace provider](/ai-gateway/ai-providers/#huggingface). This setup uses the default `llm/v1/chat` route. Claude Code sends its requests to this route.

The `llm_format: anthropic` parameter tells {{site.ai_gateway}} to expect request and response payloads that match Claude's native API format. Without this setting, the gateway would default to OpenAI's format, which would cause request failures when Claude Code communicates with the HuggingFace endpoint.

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
          header_name: Authorization
          header_value: Bearer ${key}
        model:
          provider: huggingface
          name: meta-llama/Llama-3.3-70B-Instruct
variables:
  key:
    value: $HUGGINGFACE_API_TOKEN
    description: The API token to use to connect to HuggingFace Inference API.
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
> The `ANTHROPIC_MODEL` value can be any string since the pre-function plugin removes it. The actual model used is `meta-llama/Llama-3.3-70B-Instruct` as configured in the AI Proxy plugin.

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/anything \
ANTHROPIC_MODEL=any-model-name \
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
Try creating a logging.py that logs simple http logs.
```

Claude Code might prompt you to approve its web search for answering the question. When you select **Yes**, Claude will produce a full-length response to your request:

```text
Create file
╭───────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ logging.py                                                                                            │
│                                                                                                       │
│ import logging                                                                                        │
│                                                                                                       │
│ logging.basicConfig(filename='app.log', filemode='a', format='%(name)s - %(levelname)s -              │
│ %(message)s')                                                                                         │
│                                                                                                       │
│ def log_info(message):                                                                                │
│     logging.info(message)                                                                             │
│                                                                                                       │
│ def log_warning(message):                                                                             │
│     logging.warning(message)                                                                          │
│                                                                                                       │
│ def log_error(message):                                                                               │
│     logging.error(message)                                                                            │
╰───────────────────────────────────────────────────────────────────────────────────────────────────────╯
 Do you want to create logging.py?
 ❯ 1. Yes
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
  "upstream_uri": "/v1/chat/completions?beta=true",
  "request": {
    "method": "POST",
    "headers": {
      "user-agent": "claude-cli/2.0.58 (external, cli)",
      "content-type": "application/json",
      "anthropic-version": "2023-06-01"
    }
  },
  ...
  "ai": {
    "proxy": {
      "usage": {
        "completion_tokens": 26,
        "completion_tokens_details": {},
        "total_tokens": 178,
        "cost": 0,
        "time_per_token": 52.538461538462,
        "time_to_first_token": 1365,
        "prompt_tokens": 152,
        "prompt_tokens_details": {}
      },
      "meta": {
        "llm_latency": 1366,
        "request_mode": "oneshot",
        "plugin_id": "0000b82c-5826-4abf-93b0-2fa230f5e030",
        "provider_name": "huggingface",
        "response_model": "meta-llama/Llama-3.3-70B-Instruct",
        "request_model": "meta-llama/Llama-3.3-70B-Instruct"
      }
    }
  }
  ...
}
```
{:.no-copy-code}

This output confirms that Claude Code routed the request through {{site.ai_gateway}} using HuggingFace with the `meta-llama/Llama-3.3-70B-Instruct` model.