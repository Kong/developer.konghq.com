---
title: Route Claude CLI traffic through {{site.ai_gateway}} and DashScope
permalink: /how-to/use-claude-code-with-ai-gateway-dashscope/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: File Log
    url: /plugins/file-log/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic using Alibaba Cloud DashScope models

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
  - dashscope

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} with DashScope?
  a: Install Claude CLI, configure its API key helper, create a Gateway Service and Route, attach the AI Proxy plugin to forward requests to DashScope, enable file-log to inspect traffic, and point Claude CLI to the local proxy endpoint so all LLM requests pass through the {{site.ai_gateway}} for monitoring and control.

tools:
  - deck

prereqs:
  prereqs:
  inline:
    - title: DashScope
      icon_url: /assets/icons/dashscope.svg
      content: |
        You need an active DashScope account with API access. Sign up at the [Alibaba Cloud DashScope platform](https://dashscope.aliyuncs.com/), obtain your API key from the API-KEY interface, and export it to your environment:
        ```sh
        export DECK_DASHSCOPE_API_KEY='YOUR DASHSCOPE API KEY'
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

## Configure the AI Proxy plugin

Configure the AI Proxy plugin for the DashScope provider.
* This setup uses the default `llm/v1/chat` route. Claude Code sends its requests to this route.
* The configuration also raises the maximum token count size to 8192 to support larger prompts.

The `llm_format: anthropic` parameter tells {{site.ai_gateway}} to expect request and response payloads that match Claude's native API format. Without this setting, the gateway would default to OpenAI's format, which would cause request failures when Claude Code communicates with the DashScope endpoint.

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
          header_value: Bearer ${dashscope_api_key}
        model:
          provider: dashscope
          name: qwen-plus
          options:
            max_tokens: 8192
            temperature: 1.0
variables:
  dashscope_api_key:
    value: $DASHSCOPE_API_KEY
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
> Ensure that `ANTHROPIC_MODEL` matches the model you configured in the AI Proxy plugin (for example, `qwen-plus`).

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/anything \
ANTHROPIC_MODEL=qwen-plus \
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
Tell me who Niketas Choniates was.
```

Claude Code might prompt you to approve its web search for answering the question. When you select **Yes**, Claude will produce a full-length response to your request:

```text
Niketas Choniates was a Byzantine Greek historian and government official
who lived from around 1155 to 1217. He is best known for his historical
work "Historia" (also called "Chronike Diegesis"), which chronicles the
reigns of the Byzantine emperors from 1118 to 1207, covering the period of
  the Komnenos and Angelos dynasties.

Choniates served as a high-ranking official in the Byzantine Empire,
eventually becoming the governor of Athens. His historical writings are
particularly valuable because they provide a detailed eyewitness account
of the Fourth Crusade and the subsequent sack of Constantinople in 1204,
an event he personally experienced and fled from. His account is
considered one of the most important sources for understanding this
pivotal moment in Byzantine history.
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
  "upstream_uri": "/compatible-mode/v1/chat/completions?beta=true",
  "request": {
    "method": "POST",
    "headers": {
      "user-agent": "claude-cli/2.0.57 (external, cli)",
      "content-type": "application/json",
      "anthropic-version": "2023-06-01"
    }
  },
  ...
  "ai": {
    "proxy": {
      "usage": {
        "completion_tokens": 493,
        "completion_tokens_details": {},
        "total_tokens": 13979,
        "cost": 0,
        "time_per_token": 34.539553752535,
        "time_to_first_token": 17027,
        "prompt_tokens": 13486,
        "prompt_tokens_details": {
          "cached_tokens": 0
        }
      },
      "meta": {
        "response_model": "qwen-plus",
        "plugin_id": "63199335-6c5a-4798-a0ad-f2cbf13cc497",
        "request_model": "qwen-plus",
        "request_mode": "oneshot",
        "provider_name": "dashscope",
        "llm_latency": 17028
      }
    }
  },
  "response": {
    "headers": {
      "x-kong-llm-model": "dashscope/qwen-plus",
      "x-dashscope-call-gateway": "true"
    }
  }
  ...
}
```
{:.no-copy-code}

This output confirms that Claude Code routed the request through {{site.ai_gateway}} using DashScope with the `qwen-plus` model.