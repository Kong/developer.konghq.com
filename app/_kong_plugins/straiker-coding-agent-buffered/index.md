---
title: 'Straiker Coding Agent Buffered'
name: 'Straiker Coding Agent Buffered'

content_type: plugin

publisher: straiker
description: 'Hold Claude Code and other Anthropic Messages coding agent responses until Straiker Defend scores them, so a denied tool call never reaches the agent'

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
  - straiker coding agent buffered
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
  - text: Straiker coding agent streaming plugin
    url: /plugins/straiker-coding-agent-streaming/
---

Use the {{page.name}} plugin (`straiker-coding-agent-buffered`) to hold a Claude Code or other Anthropic Messages coding agent response until Straiker Defend scores it, so a denied `tool_use` never reaches the agent to run.

Coding agents call tools on the developer's machine, outside the request/response cycle a gateway can inspect.
{{site.base_gateway}} sees the wire, not the endpoint: interactive permission decisions, `cwd`, and `permission_mode` aren't visible to this plugin.
What {{page.name}} does see is tool calls that fail and `@`-mention file reads that never become a tool call, both of which endpoint-based tooling often misses.

{{page.name}} ships in the same LuaRock as the [Straiker](/plugins/straiker/) and [Straiker coding agent streaming](/plugins/straiker-coding-agent-streaming/) plugins, but only one Straiker plugin should be attached to a given Route.
Never attach both coding-agent plugins to the same Route.

{:.warning}
> **Note**: This plugin is built for {{site.ai_gateway}} running on {{site.base_gateway}}. It has not been validated against {{site.ai_gateway}} 2.0.

## Which Straiker plugin do I need?

The right plugin depends on the client sending the traffic:

{% include_cached plugins/straiker/plugin-selector-diagram.md %}

Benefits of using the {{page.name}} plugin:

- **Stops a tool call before it runs**: The only Straiker plugin that can prevent the agent from ever seeing a denied `tool_use`.
- **Detects indirect prompt injection**: Denies a poisoned `tool_result` on the next request too, in case a tool already ran.
- **Centralizes AI security enforcement**: Applies Straiker Defend policy at the gateway instead of relying on endpoint agents alone.
- **Fits unattended automation**: Suited to CI and unattended agents, where the added time to first token is an acceptable trade-off for pre-execution enforcement.

## How it works

A tool runs locally, so the model's decision to call a tool first appears in the response, and the tool's result appears in the developer's next request.
{{page.name}} holds that response until Straiker Defend scores it, so the agent never sees a denied `tool_use`:

{% mermaid %}
sequenceDiagram
    autonumber
    participant Agent as Claude Code
    participant Plugin as {{site.base_gateway}}<br/>buffered plugin
    participant Defend as Straiker Defend
    participant LLM as Anthropic

    Agent->>Plugin: POST /v1/messages
    Plugin->>Defend: request phase
    Defend-->>Plugin: verdict
    alt Request denied
        Plugin-->>Agent: HTTP 200 end_turn
    else Allowed
        Plugin->>LLM: Forward
        LLM-->>Plugin: Full response (held)
        Plugin->>Defend: response-sync
        Defend-->>Plugin: verdict
        alt tool_use denied
            Plugin-->>Agent: HTTP 200 end_turn<br/>tool never reaches the agent
        else Allowed
            Plugin-->>Agent: Model response
        end
    end
{% endmermaid %}

{{page.name}} runs in the `access` and `response` phases:

- `access`: Sends the incoming request to Straiker Defend and denies it before it reaches the model if the verdict says to.
- `response`: Holds the full model response, sends it to Straiker Defend for synchronous scoring, and only forwards it to the agent once the scan passes.

Holding the response adds latency to the first token, typically around 1.2 times the median time-to-first-token, because the agent doesn't see anything until generation finishes and scoring completes.
Use the [streaming](/plugins/straiker-coding-agent-streaming/) plugin instead for interactive developers who need immediate tool execution.

{:.warning}
> **Caution**: Don't attach {{page.name}} to a Route that also uses [AI Proxy](/plugins/ai-proxy/) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/).
> AI Proxy clears {{site.base_gateway}}'s response buffering (`ctx.buffered_proxying`) whenever the client streams, and coding agents always stream.
> {{page.name}} then silently stops enforcing while still returning an HTTP 200 with `x-straiker-verdict: allow`.
> Inject the upstream credential with [Request Transformer](/plugins/request-transformer/) instead.
> <br><br>
> If you need [AI Proxy](/plugins/ai-proxy/) in front of your coding-agent traffic, use the [streaming](/plugins/straiker-coding-agent-streaming/) plugin on that Route instead. 
> It still inspects prompts and tool results, and isn't affected by this restriction.

### Plugin priority

{{page.name}} runs at priority 1000, so it reads the client body before [AI Proxy](/plugins/ai-proxy/) (priority 770) would translate it. For more information, see [plugin priority](/gateway/entities/plugin/#plugin-priority).

### Body buffer

Set this before attaching {{page.name}}. At {{site.base_gateway}}'s 8 KB default `client_body_buffer_size`, a Claude Code request body (often 138 KB, over 1 MB with a large tool set) spills to an nginx temp file, the plugin can't read the raw body, and traffic is proxied without inspection, returning HTTP 200 with `x-straiker-verdict: fail-open-no-body`.

```
nginx_http_client_body_buffer_size = 32m
```

Or set `KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=32m`. Also raise `nginx_http_client_max_body_size` to `64m`. This setting is node-level and needs a restart to take effect. If you can't set it, for example on a fully {{site.konnect_short_name}}-managed data plane, request-body inspection isn't possible.

### Path matching

{{page.name}} only inspects paths that end in `/v1/messages`, not `/v1/messages/count_tokens`. If your Route rewrites that suffix away, there's no `x-straiker-verdict` header at all.

### Fail-closed risk

Unlike [`straiker`](/plugins/straiker/), setting `config.fail_open` to `false` on {{page.name}} also applies to the response phase.
Because the model's answer is only generated once, setting `fail_open` to `false` can return a 503 for a request whose response was already produced by the model, if Straiker Defend is unreachable when the response is scored.

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
  --data "{\"lua_schema\": $(jq -Rs '.' kong/plugins/straiker-coding-agent-buffered/schema.lua)}"
```

Install the rock (or a custom image containing it) on every data plane node, including `KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=32m`. Uploading a changed schema doesn't push it to data planes on its own. Touch another entity afterward so data planes pull the new payload.

{% endnavtab %}
{% endnavtabs %}

## Enable the plugin

{{page.name}} proxies Anthropic Messages traffic directly, for example to `https://api.anthropic.com`, rather than sitting behind [AI Proxy](/plugins/ai-proxy/).

See the [Enable Straiker coding agent buffered example](/plugins/straiker-coding-agent-buffered/examples/enable-straiker-coding-agent-buffered/).

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

### Enforcement silently stops on streamed traffic

**Symptoms:** {{page.name}} is attached, but `tool_use` calls the agent shouldn't be running still reach it, even though `x-straiker-verdict` says `allow`.

**Possible solutions:**
- Confirm [AI Proxy](/plugins/ai-proxy/) isn't also attached to the Route. AI Proxy clears response buffering on streamed requests, which coding agents always send. See [How it works](#how-it-works).

### Plugin not found

**Symptoms:** {{site.base_gateway}} returns `plugin 'straiker-coding-agent-buffered' not enabled`.

**Possible solutions:**
- Confirm the plugin files are installed on every data plane node.
- Confirm `KONG_PLUGINS` includes `straiker-coding-agent-buffered` and still includes `bundled`.
- Restart or reload {{site.base_gateway}} after installation.
- In {{site.konnect_short_name}} hybrid mode, confirm the plugin schema was uploaded to the control plane.
