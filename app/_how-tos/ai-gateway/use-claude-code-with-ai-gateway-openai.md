---
title: Route Claude CLI traffic through {{site.ai_gateway}} and OpenAI
permalink: /how-to/use-claude-code-with-ai-gateway-openai/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: File Log
    url: /plugins/file-log/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic using OpenAI models

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
  q: How do I run Claude CLI through {{site.ai_gateway}}?
  a: Install Claude CLI, configure its API key helper, create a Gateway Service and Route, attach the AI Proxy plugin to forward requests to Claude, enable the File Log plugin to inspect traffic, and point Claude CLI to the local proxy endpoint so all LLM requests pass through the {{site.ai_gateway}} for monitoring and control.

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
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

First, configure the AI Proxy plugin for the [OpenAI provider](/ai-gateway/ai-providers/#openai):
 * This setup uses the default `llm/v1/chat` route. Claude Code sends its requests to this route.
 * The configuration also raises the maximum request body size to 512 KB to support larger prompts.

The `llm_format: anthropic` parameter tells {{site.ai_gateway}} to expect request and response payloads that match Claude's native API format. Without this setting, the Gateway would default to OpenAI's format, which would cause request failures when Claude Code communicates with the OpenAI endpoint.

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
          header_value: Bearer ${openai_key}
          allow_override: false
        model:
          provider: openai
          name: gpt-5-mini
        max_request_body_size: 524288
variables:
  openai_key:
    value: "$OPENAI_API_KEY"
{% endentity_examples %}

## Configure the File Log plugin

Now, let's enable the [File Log](/plugins/file-log/) plugin on the Service, to inspect the LLM traffic between Claude and the {{site.ai_gateway}}. This creates a local `claude.json` file on your machine. The file records each request and response so you can review what Claude sends through the {{site.ai_gateway}}.

{% entity_examples %}
entities:
  plugins:
    - name: file-log
      config:
        path: "/tmp/claude.json"
{% endentity_examples %}

## Verify traffic through {{site.ai_gateway}}

Now, we can start a Claude Code session that points it to the local {{site.ai_gateway}} endpoint:

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/anything \
ANTHROPIC_MODEL=gpt-5-mini \
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
Tell me about Procopius' Secret History.
```

Claude Code might prompt you approve its web search for answering the question. When you select **Yes**, Claude will produce a full-length response to your request:

```text
Procopius’ Secret History (Greek: Ἀνέκδοτα, Anekdota) is a fascinating and
notorious work of Byzantine literature written in the 6th century by the
court historian Procopius of Caesarea. Unlike his official histories
(“Wars” and “Buildings”), which paint the Byzantine Emperor Justinian I
and his wife Theodora in a generally positive and conventional manner, the
Secret History offers a scandalous, behind-the-scenes account that
sharply criticizes and even vilifies the emperor, the empress, and other
key figures of the time.
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
  "ai": {
    "meta": {
      "request_model": "gpt-5-mini",
      "request_mode": "oneshot",
      "response_model": "gpt-5-mini-2025-08-07",
      "provider_name": "openai",
      "llm_latency": 6786,
      "plugin_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    },
    "usage": {
      "completion_tokens": 456,
      "completion_tokens_details": {
        "accepted_prediction_tokens": 0,
        "audio_tokens": 0,
        "rejected_prediction_tokens": 0,
        "reasoning_tokens": 256
      },
      "total_tokens": 481,
      "cost": 0,
      "time_per_token": 14.881578947368,
      "time_to_first_token": 6785,
      "prompt_tokens": 25,
      "prompt_tokens_details": {
        "cached_tokens": 0,
        "audio_tokens": 0
      }
    }
  }
  ...
}
```
{:.no-copy-code}

This output confirms that Claude Code routed the request through {{site.ai_gateway}} using the `gpt-5-mini` model we selected while starting the Claude Code session.
