---
title: 'Straiker'
name: 'Straiker'

content_type: plugin

publisher: straiker
description: 'Scan LLM and coding agent prompts and responses against Straiker policy before they reach the upstream model or the client'

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
  - straiker
  - straiker defend
  - straiker ai security
  - straiker coding agent
  - prompt injection
  - ai firewall

related_resources:
  - text: Straiker + Kong use cases
    url: https://docs.straiker.ai/defend-ai/kong-gateway-integration
  - text: Straiker Defend documentation
    url: https://docs.straiker.ai
  - text: Straiker plugin repository
    url: https://github.com/straiker-ai/kong
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Custom plugins
    url: /custom-plugins/
---

Use the {{page.name}} plugin (`straiker`) to protect LLM traffic flowing through {{site.base_gateway}}. The plugin scans prompts before they reach the upstream model and scans model responses before they return to the client.

This plugin can protect chat applications and coding agents.
It speaks Anthropic Messages and OpenAI chat, so it also protects agents such as Claude Code.

Straiker evaluates each turn against the policies configured in the Straiker Console, and {{site.base_gateway}} forwards the traffic or replaces it with a policy message based on the verdict.

{:.warning}
> **Note**: This plugin is built for {{site.ai_gateway}} running on {{site.base_gateway}}. It has not been validated against {{site.ai_gateway}} 2.0.

With Straiker, you can:

- **Block unsafe traffic at the gateway**: Detect prompt injection, jailbreaks, sensitive data exposure, and unsafe model output.
- **Inspect indirect prompt injection**: Catch poisoned tool results arriving from a coding agent's local tool run.
- **Stop a tool call before it runs**: Prevent a model's tool call from reaching the agent, on routes configured for it.
- **Centralize AI security enforcement**: Apply one policy across applications, models, and providers.
- **Hold the upstream credential at the gateway**: Clients never carry a platform key.
- **Inspect streaming and multimodal traffic**: Evaluate AI traffic without adding an application SDK.

## Delivery mode

The {{page.name}} plugin enforces in one of two modes, selected by the `STRAIKER_KONG_MODE` environment variable on the {{site.base_gateway}} node. Set it to `buffered` (the default) or `streaming`.

{% table %}
columns:
  - title: Capability
    key: capability
  - title: "`buffered` (default)"
    key: buffered
  - title: "`streaming`"
    key: streaming
rows:
  - capability: Prompt and tool-result enforcement
    buffered: "Yes"
    streaming: "Yes"
  - capability: Stops a tool call before the client runs it
    buffered: "Yes"
    streaming: "No"
  - capability: Tokens reach the client as produced
    buffered: "No"
    streaming: "Yes"
  - capability: Time to first token
    buffered: The completion time
    streaming: Unchanged
  - capability: Typical route
    buffered: CI, automation, unattended agents
    streaming: Interactive developers
{% endtable %}

The mode applies to the whole node, so run two node pools if you need both modes.

The mode setting is an environment variable because {{site.base_gateway}} rejects a plugin that implements both the `response` and `body_filter` phases, and checks this at load time, before reading any configuration.

The {{page.name}} plugin doesn't require [AI Proxy](/plugins/ai-proxy/). It proxies provider traffic directly and injects the upstream credential itself.

{:.warning}
> **Caution**: If you use AI Proxy, keep it off nodes running `STRAIKER_KONG_MODE=buffered`. AI Proxy turns response buffering off whenever the client streams, which means the plugin's response phase never runs and enforcement stops silently. Use `streaming` mode on those routes instead.

## How it works

Before the request reaches the model:

1. **Credential injection**: The plugin replaces the client's upstream credential with the one the gateway holds.
1. **Request interception**: The plugin captures the incoming request body.
1. **Security scan**: The plugin sends the turn to Straiker for policy evaluation.
1. **Verdict enforcement**: {{site.base_gateway}} blocks the request or forwards it to the upstream model.

After the model responds:

1. **Response capture**: The plugin captures the model's answer. It holds the answer inline in `buffered` mode and passes it through as the model produces it in `streaming` mode.
1. **Response scan**: The plugin sends the answer to Straiker for evaluation.
1. **Final delivery**: In `buffered` mode, {{site.base_gateway}} replaces the answer if the verdict is a block. In `streaming` mode, the client already has the bytes and the verdict is advisory.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client
    participant straiker as Kong Gateway<br/>Straiker plugin
    participant detect as Straiker
    participant llm as Upstream AI service

    client->>straiker: Send request
    straiker->>detect: Send turn
    detect->>detect: Check against AI security policy
    detect-->>straiker: Verdict

    alt Prompt blocked
        straiker-->>client: Return policy message
    else Prompt allowed
        straiker->>llm: Forward allowed request
        llm-->>straiker: Return AI response
        straiker->>detect: Send answer
        detect-->>straiker: Verdict

        alt Answer blocked (buffered mode)
            straiker-->>client: Return policy message
        else Answer allowed
            straiker-->>client: Forward allowed response
        end
    end
{% endmermaid %}
<!--vale on-->

A block is returned as HTTP `200` carrying a completed assistant turn whose content is the policy text.
It's deliberately not a `4xx` or `5xx` response, because coding agent clients treat `403` as an authentication failure and retry `5xx`.
Set up alerts on the `x-straiker-verdict` response header instead of the HTTP status.

## Install the {{page.name}} plugin

The plugin is supported on self-managed {{site.base_gateway}}, {{site.konnect_short_name}} hybrid deployments with self-managed data planes, and {{site.konnect_short_name}} Dedicated Cloud Gateways. 

{{site.konnect_short_name}} Serverless Gateways don't support custom plugins.

### Prerequisites

Before installing the plugin, you need:

- {{site.base_gateway}} 3.14 or later.
- A Straiker account and integration key.
- Network egress from {{site.base_gateway}} data planes to the Straiker detect endpoint.
- `nginx_http_client_body_buffer_size` raised to `32m`. At the nginx default of 8 KB, a large request body spills to a temporary file, the plugin can't read it, and traffic proxies uninspected.
- `max_body_bytes` raised to match. The plugin skips scoring for a body larger than this limit, which defaults to 10 MiB.

### Installation steps

{% navtabs 'install' %}
{% navtab "Docker" %}

Build a custom image with the plugin installed:

```dockerfile
FROM kong/kong-gateway:3.15
USER root
COPY kong/plugins/straiker/ /usr/local/share/lua/5.1/kong/plugins/straiker/
USER kong
ENV KONG_PLUGINS=bundled,straiker
ENV STRAIKER_KONG_MODE=buffered
ENV KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=32m
ENV KONG_NGINX_HTTP_CLIENT_MAX_BODY_SIZE=64m
```

Keep `bundled` in `KONG_PLUGINS`. Omitting it replaces the enabled set and silently drops every bundled plugin.

{% endnavtab %}
{% navtab "LuaRocks" %}

1. Install the plugin:

   ```bash
   luarocks install kong-plugin-straiker
   ```

1. Enable the plugin, keeping `bundled` in the list:

   ```bash
   export KONG_PLUGINS=bundled,straiker
   ```

1. Reload {{site.base_gateway}}:

   ```bash
   kong reload
   ```

{% endnavtab %}
{% navtab "{{site.konnect_short_name}} hybrid" %}

Upload `kong/plugins/straiker/schema.lua` to the control plane, then install the rock or image on every data plane node.

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
  --data "{\"lua_schema\": $(jq -Rs '.' kong/plugins/straiker/schema.lua)}"
```

{% endnavtab %}
{% navtab "{{site.konnect_short_name}} Dedicated Cloud Gateways" %}

Dedicated Cloud Gateways stream the plugin from the control plane, so nothing is installed on a data plane. The plugin is exactly one `handler.lua` and one `schema.lua`. It doesn't ship sibling modules, and its schema doesn't call `require()`. This is the shape that streamed custom plugins accept.

Set `KONG_UNTRUSTED_LUA=lax` when creating the gateway. The {{site.base_gateway}} default is `strict`, which permits no network module, and the plugin won't load.

See the [plugin repository README](https://github.com/straiker-ai/kong) for the upload command and the full set of constraints.

{% endnavtab %}
{% endnavtabs %}

## Enable the plugin

Attach `straiker` to the Route carrying LLM traffic. The plugin scores any POST request on that Route and doesn't inspect the path, so scope the Route deliberately. A plain {{site.base_gateway}} path is a prefix match.

Declare `protocols` explicitly on the Route. Without it, {{site.base_gateway}} infers them from the Service URL, an `https://` upstream makes the Route HTTPS-only, and plain HTTP is rejected with `426 Upgrade Required` before any plugin runs.

See the [Enable Straiker example](/plugins/straiker/examples/enable-straiker/).

## Test the plugin

Send a benign prompt:

```bash
curl -i -X POST http://localhost:8000/v1/messages \
  --header "Content-Type: application/json" \
  --data '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 256,
    "system": "You are a helpful assistant.",
    "messages": [
      { "role": "user", "content": "What is the capital of France?" }
    ]
  }'
```

Expect HTTP `200` and `x-straiker-verdict: allow`.

If a request violates a blocking policy, {{site.base_gateway}} returns the policy message and the upstream model isn't called. If the policy is in detect-only mode, the request continues, the response is stamped `detect`, and the event appears in the Straiker Console for review.

Keep `max_tokens` generous while testing. A reply truncated at `stop_reason: max_tokens` can look like a block.

## Verdict header

The plugin stamps every response with an `x-straiker-verdict` header:

{% table %}
columns:
  - title: "`x-straiker-verdict`"
    key: verdict
  - title: Meaning
    key: meaning
rows:
  - verdict: "`allow`"
    meaning: Scored, nothing fired.
  - verdict: "`detect`"
    meaning: A control fired while the tenant is in detect mode. Not a block.
  - verdict: "`block`"
    meaning: Enforced. The answer was replaced.
  - verdict: "`degraded`"
    meaning: Straiker was unreachable or errored and `fail_closed` is `false`, so traffic passed uninspected.
  - verdict: "`unknown`"
    meaning: Straiker answered in an unrecognized shape. Traffic also passed uninspected.
{% endtable %}

Set up alerts on `degraded` and `unknown`. Both return a healthy-looking `200` while the control isn't running.

## Troubleshooting

### Plugin not found

**Symptoms:** {{site.base_gateway}} returns `plugin 'straiker' not enabled`.

**Possible solutions:**
- Confirm the plugin files are installed on every data plane node.
- Confirm `KONG_PLUGINS` includes `straiker` and still includes `bundled`.
- Restart or reload {{site.base_gateway}} after installation.
- In {{site.konnect_short_name}} hybrid mode, confirm the plugin schema was uploaded to the control plane.

### 426 Upgrade Required and no verdict header

**Symptoms:** Requests return `426 Upgrade Required` with no `x-straiker-verdict` header.

**Possible solutions:**
- Add `protocols: ["http", "https"]` to the Route. See [Enable the plugin](#enable-the-plugin).

### No events in Straiker

**Symptoms:** Traffic passes through {{site.base_gateway}}, but nothing appears in the Straiker Console.

**Possible solutions:**
- Confirm `config.api_key` is valid for the environment `config.detect_url` points at, and that data planes can reach that endpoint.
- Temporarily set `config.debug_preamble` to `true` and look for `[straiker]` entries in the {{site.base_gateway}} logs, then turn it off.

### Verdict is degraded or unknown

**Symptoms:** Responses carry `x-straiker-verdict: degraded` or `unknown`.

**Possible solutions:**
- For `degraded`, Straiker was unreachable or returned an error. Check egress, the key, and `config.timeout_ms`.
- For `unknown`, the response couldn't be interpreted. Check that `config.detect_url` points at a supported API version.

### Large multimodal requests fail

**Symptoms:** Requests with large inline images or PDFs fail.

**Possible solutions:**
- Inline images and PDFs increase request size because they're base64 encoded. Raise the {{site.base_gateway}} request body buffer and maximum body size.

## Limitations

- {{site.konnect_short_name}} Serverless Gateways don't support custom plugins.
- The delivery mode is set per node, not per Route. See [Delivery mode](#delivery-mode) for the mode trade-offs.
- `buffered` mode is incompatible with AI Proxy on streaming requests.
- Synchronous scoring adds latency to the request path.

## Security considerations

- Attribution follows the Route's authentication. The plugin reads the Kong Consumer when one is resolved and falls back to the static `user_ref` otherwise. It never reads an identity header from the client.
- Put an authentication plugin on any Route whose attribution you rely on.
- Store `api_key` and `upstream_api_key` as {{site.base_gateway}} Vault references. Both fields are referenceable.
- Keep `debug_preamble` set to `false` in production. It writes prompt content to the node's error log.
- Use TLS egress to Straiker.
- Alert on `degraded` and `unknown` verdicts so a degraded control is visible.
- Start with detect-only controls in the Straiker Console before enabling blocking for production applications.
- Review blocked and detected events regularly in the Straiker Console.
