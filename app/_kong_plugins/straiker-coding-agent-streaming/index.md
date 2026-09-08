---
title: 'Straiker Coding Agent Streaming'
name: 'Straiker Coding Agent Streaming'

content_type: plugin

publisher: straiker
description: 'Scan Claude Code and other Anthropic Messages coding agent traffic against Straiker Defend policy without touching the streamed response'

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

third_party: true

support_url: https://docs.straiker.ai

icon: straiker.svg

min_version:
  gateway: '3.14'

tags:
  - security
  - ai

search_aliases:
  - straiker coding agent streaming
  - straiker claude code
  - straiker defend
  - ai firewall
  - coding agent security

related_resources:
  - text: Coding-agent install notes
    url: https://docs.straiker.ai/defend-ai/kong-gateway-integration
  - text: Straiker Defend documentation
    url: https://docs.straiker.ai
  - text: Straiker plugin (chat applications)
    url: /plugins/straiker/
  - text: Straiker coding agent buffered plugin
    url: /plugins/straiker-coding-agent-buffered/
---

Use the {{page.name}} plugin (`straiker-coding-agent-streaming`) to scan Anthropic Messages traffic from Claude Code and other coding agents against Straiker Defend policy, without buffering or delaying the streamed response.

Coding agents call tools on the developer's machine, outside the request/response cycle a gateway can inspect.
{{site.base_gateway}} sees the wire, not the endpoint: interactive permission decisions, `cwd`, and `permission_mode` aren't visible to this plugin.
What {{page.name}} does see is tool calls that fail and `@`-mention file reads that never become a tool call, both of which endpoint-based tooling often misses.

{{page.name}} ships in the same LuaRock as the [Straiker](/plugins/straiker/) and [Straiker coding agent buffered](/plugins/straiker-coding-agent-buffered/) plugins, but only one Straiker plugin should be attached to a given Route.
Never attach both coding-agent plugins to the same Route.

{:.warning}
> **Note**: This plugin is built for {{site.ai_gateway}} running on {{site.base_gateway}}. It has not been validated against {{site.ai_gateway}} 2.0.

## Which Straiker plugin do I need?

The right plugin depends on the client sending the traffic:

{% include_cached plugins/straiker/plugin-selector-diagram.md %}

Benefits of using the {{page.name}} plugin:

- **No added latency to the first token**: The client's stream is forwarded untouched while scoring happens.
- **Detects indirect prompt injection**: Denies a poisoned `tool_result` on the next request, before the model consumes it.
- **Centralizes AI security enforcement**: Applies Straiker Defend policy at the gateway instead of relying on endpoint agents alone.
- **Fits interactive development**: Suited to developers who need immediate tool execution, unlike the [buffered](/plugins/straiker-coding-agent-buffered/) plugin.

## How it works

A tool runs locally, so the model's decision to call a tool first appears in the response, and the tool's result appears in the developer's next request:

{% mermaid %}
sequenceDiagram
    participant Agent as Coding agent
    participant Kong as {{site.base_gateway}}
    participant LLM

    Note over Agent,LLM: Turn N, the model decides to run a tool
    LLM-->>Kong: Response with tool_use
    Kong-->>Agent: Streaming, client already has tool_use
    Note over Agent: Tool runs on the developer's machine
    Agent->>Kong: Turn N+1, messages include tool_result
    Note over Kong: Straiker Defend can deny here,<br/>stopping the model from consuming a poisoned result
{% endmermaid %}

{{page.name}} runs in the `access` phase, and relays the response asynchronously when `config.relay_response` is enabled:

{% mermaid %}
sequenceDiagram
    autonumber
    participant Agent as Claude Code
    participant Plugin as {{site.base_gateway}}<br/>streaming plugin
    participant Defend as Straiker Defend
    participant LLM as Anthropic

    Agent->>Plugin: POST /v1/messages
    Plugin->>Defend: request phase
    Defend-->>Plugin: verdict
    alt Prompt or poisoned tool_result denied
        Plugin-->>Agent: HTTP 200 end_turn (policy text)
    else Allowed
        Plugin->>LLM: Forward
        LLM-->>Agent: Stream (untouched)
        Plugin-->>Defend: async response relay
    end
{% endmermaid %}

Because {{page.name}} can't hold the response, it can't stop a `tool_use` before the client runs it. Use the [buffered](/plugins/straiker-coding-agent-buffered/) plugin when a tool call must be stopped before it runs, for example in CI or unattended agents.

### Plugin priority

{{page.name}} runs at priority 1000, so it reads the client body before [AI Proxy](/plugins/ai-proxy/) (priority 770) would translate it. For more information, see [plugin priority](/gateway/entities/plugin/#plugin-priority).

[AI Proxy](/plugins/ai-proxy/) can front {{page.name}}. It still inspects prompts and tool results normally.

### Body buffer

Set this before attaching {{page.name}}. At {{site.base_gateway}}'s 8 KB default `client_body_buffer_size`, a Claude Code request body (often 138 KB, over 1 MB with a large tool set) spills to an nginx temp file, the plugin can't read the raw body, and traffic is proxied without inspection, returning HTTP 200 with `x-straiker-verdict: fail-open-no-body`.

```
nginx_http_client_body_buffer_size = 32m
```

Or set `KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=32m`. Also raise `nginx_http_client_max_body_size` to `64m`. This setting is node-level and needs a restart to take effect. If you can't set it, for example on a fully {{site.konnect_short_name}}-managed data plane, request-body inspection isn't possible.

### Path matching

{{page.name}} only inspects paths that end in `/v1/messages`, not `/v1/messages/count_tokens`. If your Route rewrites that suffix away, there's no `x-straiker-verdict` header at all.

## Install the {{page.name}} plugin

LuaRock name: `kong-plugin-straiker` (current version `0.11.0-1`). This single rock provides all three Straiker plugins: `straiker`, `straiker-coding-agent-streaming`, and `straiker-coding-agent-buffered`.

### Prerequisites

Before installing the plugin, you need:

- {{site.base_gateway}} 3.14 or later.
- A Straiker account and Straiker Defend API key. Contact your Straiker team for enterprise API keys and sandbox access.
- Network egress from {{site.base_gateway}} data planes to Straiker Defend.
- `nginx_http_client_body_buffer_size` raised, as described in [Body buffer](#body-buffer).
- Optional: Kong authentication plugins configured to map callers to Consumers.

{{site.konnect_short_name}} Serverless and Dedicated Cloud Gateways aren't supported. Custom plugins are rejected on those topologies. Use self-managed {{site.base_gateway}} or {{site.konnect_short_name}} hybrid mode instead.

### Installation steps

{% navtabs 'install' %}
{% navtab "Self-managed" %}

1. Install the plugin using LuaRocks:

   ```bash
   luarocks make kong-plugin-straiker-0.11.0-1.rockspec
   ```

   Or install a published release:

   ```bash
   luarocks install https://github.com/straiker-ai/kong/releases/download/v0.11.0/kong-plugin-straiker-0.11.0-1.all.rock
   ```

1. Keep `bundled` in your plugins list and add the plugin names you need:

   ```bash
   export KONG_PLUGINS=bundled,straiker,straiker-coding-agent-streaming,straiker-coding-agent-buffered
   ```

   Omitting `bundled` replaces the enabled set and silently drops `key-auth`, `request-transformer`, and every other bundled plugin.
   Enable only the names you need, but attach only one Straiker plugin per Route.

1. Set the body buffer size, then restart {{site.base_gateway}}:

   ```bash
   export KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=32m
   ```

{% endnavtab %}
{% navtab "Docker" %}

Build a custom image with all three Straiker plugins installed:

```dockerfile
FROM kong/kong-gateway:3.14
USER root
COPY kong/plugins/straiker/ /usr/local/share/lua/5.1/kong/plugins/straiker/
COPY kong/plugins/straiker-coding-agent-streaming/ /usr/local/share/lua/5.1/kong/plugins/straiker-coding-agent-streaming/
COPY kong/plugins/straiker-coding-agent-buffered/ /usr/local/share/lua/5.1/kong/plugins/straiker-coding-agent-buffered/
USER kong
ENV KONG_PLUGINS=bundled,straiker,straiker-coding-agent-streaming,straiker-coding-agent-buffered
ENV KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=32m
```

{% endnavtab %}
{% navtab "{{site.konnect_short_name}}" %}

{{site.konnect_short_name}} hybrid mode (self-managed data planes) is supported. {{site.konnect_short_name}} Serverless and Dedicated Cloud Gateways can't run custom plugins.

The coding-agent plugin schemas are self-contained, with no `require()` calls, which {{site.konnect_short_name}} requires for uploaded schemas.

Set your {{site.konnect_short_name}} credentials:

```bash
export KONNECT_TOKEN="your-konnect-personal-access-token"
export CONTROL_PLANE_ID="your-control-plane-id"
```

Then upload the schema:

```bash
curl -i -X POST \
  "https://us.api.konghq.com/v2/control-planes/${CONTROL_PLANE_ID}/core-entities/plugin-schemas" \
  --header "Authorization: Bearer ${KONNECT_TOKEN}" \
  --header "Content-Type: application/json" \
  --data "{\"lua_schema\": $(jq -Rs '.' kong/plugins/straiker-coding-agent-streaming/schema.lua)}"
```

Install the rock (or a custom image containing it) on every data plane node, including `KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=32m`. Uploading a changed schema doesn't push it to data planes on its own. Touch another entity afterward so data planes pull the new payload.

{% endnavtab %}
{% endnavtabs %}

## Enable the plugin

{{page.name}} usually proxies Anthropic Messages traffic directly, for example to `https://api.anthropic.com`, rather than sitting behind [AI Proxy](/plugins/ai-proxy/).
See the [Enable Straiker coding agent streaming example](/plugins/straiker-coding-agent-streaming/examples/enable-straiker-coding-agent-streaming/).

Point Claude Code at your {{site.base_gateway}} Route:

```bash
export ANTHROPIC_BASE_URL=https://kong.example.com/claude-code
export ANTHROPIC_API_KEY=placeholder
```

Then start Claude Code:

```bash
claude
```

Claude Code appends `/v1/messages` to `ANTHROPIC_BASE_URL` itself, so don't include it in the URL.
If {{site.base_gateway}} injects the upstream credential, for example with [Request Transformer](/plugins/request-transformer/), `ANTHROPIC_API_KEY` can be a placeholder value.

{:.info}
> **Note**: A policy block is an HTTP 200 response with the Anthropic `stop_reason` set to `end_turn`, not an HTTP error. Claude Code treats a 403 as an auth failure and retries a 5xx, so alert on the `x-straiker-verdict` header and the `straiker` object in your log serializer output, not on HTTP status.

## Test the plugin

Send a minimal request with a tool defined:

```bash
curl -i -X POST https://kong.example.com/claude-code/v1/messages \
  -H 'content-type: application/json' \
  -H 'x-api-key: placeholder' \
  -H 'anthropic-version: 2023-06-01' \
  -H 'x-claude-code-session-id: install-check-1' \
  -d '{"model":"claude-sonnet-4-5-20250929","max_tokens":32,"stream":true,
       "tools":[{"name":"Bash","description":"run","input_schema":{"type":"object"}}],
       "messages":[{"role":"user","content":[{"type":"text","text":"say OK"}]}]}'
```

You want an HTTP 200 response, an SSE stream, and `x-straiker-verdict: allow`. A `fail-open-*` value means traffic is flowing but inspection is degraded.

## Troubleshooting

### No `x-straiker-verdict` header on coding-agent traffic

**Symptoms:** Requests reach the upstream model, but there's no `x-straiker-verdict` header in the response.

**Possible solutions:**
- Confirm the request path ends in `/v1/messages`, not `/v1/messages/count_tokens`.
- Confirm {{page.name}} is attached to that Route.
- A `fail-open-no-body` verdict means the request body spilled past the buffer. See [Body buffer](#body-buffer).
- A `fail-open-no-key` verdict means a vault reference didn't resolve. If you're using the environment vault, also set `KONG_NGINX_MAIN_ENV`.

### Plugin not found

**Symptoms:** {{site.base_gateway}} returns `plugin 'straiker-coding-agent-streaming' not enabled`.

**Possible solutions:**
- Confirm the plugin files are installed on every data plane node.
- Confirm `KONG_PLUGINS` includes `straiker-coding-agent-streaming` and still includes `bundled`.
- Restart or reload {{site.base_gateway}} after installation.
- In {{site.konnect_short_name}} hybrid mode, confirm the plugin schema was uploaded to the control plane.
