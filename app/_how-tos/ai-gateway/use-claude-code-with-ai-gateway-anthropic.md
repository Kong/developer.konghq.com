---
title: Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic
permalink: /how-to/use-claude-code-with-ai-gateway-anthropic/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: File Log
    url: /plugins/file-log/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic

products:
  - ai-gateway
  - gateway

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
  - anthropic

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}}?
  a: Install Claude CLI, configure its API key helper, create a Gateway Service and Route, attach the AI Proxy plugin to forward requests to Claude, enable file-log to inspect traffic, and point Claude CLI to the local proxy endpoint so all LLM requests pass through the {{site.ai_gateway}} for monitoring and control.

tools:
  - deck

prereqs:
  inline:
    - title: Anthropic
      icon_url: /assets/icons/anthropic.svg
      include_content: prereqs/anthropic
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

First, configure the AI Proxy plugin for the [Anthropic provider](/ai-gateway/ai-providers/#anthropic).
* This setup uses the default `llm/v1/chat` route. Claude Code sends its requests to this route.
* The configuration also raises the maximum request body size to 512 KB to support larger prompts.

Set `llm_format: anthropic` to tell {{site.ai_gateway}} that requests and responses use Claude's native API format. This parameter controls schema validation and prevents format mismatches between Claude Code and the gateway.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        logging:
          log_statistics: true
          log_payloads: false
        auth:
          header_name: x-api-key
          header_value: ${key}
        model:
          name: claude-sonnet-4-5-20250929
          provider: anthropic
          options:
            anthropic_version: '2023-06-01'
        llm_format: anthropic
        logging:
          log_statistics: true
        max_request_body_size: 524288
        route_type: llm/v1/chat
variables:
  key:
    value: $ANTHROPIC_API_KEY
    description: The API key to use to connect to Anthropic.
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

## Verify traffic through Kong

Now, we can start a Claude Code session that points it to the local {{site.ai_gateway}} endpoint:

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/anything \
ANTHROPIC_MODEL=claude-sonnet-4-5-20250929 \
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
Tell me about Madrid Skylitzes manuscript.
```

Claude Code might prompt you approve its web search for answering the question. When you select **Yes**, Claude will produce a full-length response to your request:

```text
The Madrid Skylitzes is a remarkable 12th-century illuminated Byzantine
manuscript that represents one of the most important surviving examples
of medieval historical documentation. Here are the key details:

What it is

The Madrid Skylitzes is the only surviving illustrated manuscript of John
Skylitzes' "Synopsis of Histories" (Σύνοψις Ἱστοριῶν), which chronicles
Byzantine history from 811 to 1057 CE - covering the period from the death
of Emperor Nicephorus I to the deposition of Michael VI.

Artistic Significance

- 574 miniature paintings (with about 100 lost over time)
- Lavishly decorated with gold leaf, vibrant pigments, and intricate
detailing
- Depicts everything from imperial coronations and battles to daily life
in Byzantium
- The only surviving Byzantine illuminated chronicle written in Greek

Unique Collaboration

The manuscript is believed to be the work of 7 different artists from
various backgrounds:
- 4 Italian artists
- 1 English or French artist
- 2 Byzantine artists
```
{:.no-copy-code}

Next, inspect the {{site.ai_gateway}} logs to verify that the traffic was proxied through it:

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
        "prompt_tokens": 1,
        "completion_tokens_details": {},
        "completion_tokens": 85,
        "total_tokens": 86,
        "cost": 0,
        "time_per_token": 38.941176470588,
        "time_to_first_token": 2583,
        "prompt_tokens_details": {}
      },
      "meta": {
        "request_model": "claude-sonnet-4-20250514",
        "response_model": "claude-sonnet-4-20250514",
        "llm_latency": 3310,
        "plugin_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        "request_mode": "stream",
        "provider_name": "anthropic"
      }
    }
  },
  ...
}
```
{:.no-copy-code}

This output confirms that Claude Code routed the request through {{site.ai_gateway}} using the `claude-sonnet-4-5-20250929` model we selected while starting the Claude Code session.
