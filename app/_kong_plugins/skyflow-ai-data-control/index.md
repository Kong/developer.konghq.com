---
title: 'Skyflow De-identify'
name: 'Skyflow De-identify'

content_type: plugin

publisher: skyflow
description: "Skyflow sanitization plugin for {{site.ai_gateway_name}}."

products:
    - gateway

works_on:
    - on-prem
    - konnect

third_party: true
support_url: https://github.com/SkyflowFoundry/skyflow-gateway-kong/issues

icon: skyflow.svg

related_resources:
  - text: Skyflow plugin source code
    url: https://github.com/SkyflowFoundry/skyflow-gateway-kong
  - text: Skyflow de-identification
    url: https://docs.skyflow.com/docs/de-identification/overview

min_version:
  gateway: '3.15'
---

Use the Skyflow De-identify plugin (`skyflow-ai-data-control`) to put {{site.base_gateway}} in front of any LLM, MCP server, or API and guarantee that PII, PHI, secrets, and other regulated data is tokenized before it leaves your trust boundary, then transparently restored for authorized callers on the way back.

Applications increasingly send prompts, tool arguments, and JSON payloads to LLM providers, MCP servers, and third-party APIs, often carrying regulated data.
Once that data reaches a third party, you've lost control of it. The data can be logged, trained on, cached, or subpoenaed.
This plugin makes {{site.base_gateway}} the enforcement point and the [Skyflow Data Privacy Vault](https://docs.skyflow.com/docs/fundamentals/product-overview#the-skyflow-data-privacy-vault) the system of record.
Skyflow's [Detect APIs](https://docs.skyflow.com/docs/de-identification/overview) handle the detection, reversible tokenization, and policy-governed re-identification, so the model provider only ever sees tokens.

Benefits of using the Skyflow De-identify plugin:

- **Reversible, policy-governed tokenization**: Values become Skyflow vault tokens that can be re-identified per-caller under Skyflow roles, context-aware policies, and audit logging, not just one-way masking.
- **300+ entity detectors and transformations**: Names, emails, SSNs, credit cards, healthcare identifiers, and more, plus transformations like date-shifting and multiple token formats (`VAULT_TOKEN`, `ENTITY_ONLY`, `ENTITY_UNQ_COUNTER`).
- **Composes with {{site.ai_gateway}}**: Sits alongside `ai-proxy` using a nested-proxy pattern so the model provider (OpenAI, Anthropic, and others) receives only tokens.
- **Fail-closed by default**: If Skyflow is unreachable or a response can't be re-identified, the configured posture (`deny`) blocks rather than leaks. A `dry_run` mode logs detections without altering traffic.
- **Deployable on {{site.konnect_short_name}} and self-managed**: Ships as two self-contained files that {{site.konnect_short_name}} Dedicated Cloud Gateways and hybrid data planes accept as a streamed custom plugin, with no third-party rock dependencies, and as a LuaRock for self-managed installs.

## How it works

When you enable this plugin on a Route, it acts in two {{site.base_gateway}} request-lifecycle phases:

1. `access`: Runs before the request is proxied upstream.
  The plugin reads the request body, extracts the target text spans based on the wire format detected from the body (OpenAI, Anthropic, or MCP) plus any explicit JSONPath selectors, calls Skyflow De-identify (`POST /v2/detect/deidentify/string`), and rewrites the outbound body so the upstream receives only tokens, for example `[NAME_aB3xQ]`.
  A request-scoped token-to-value map is stashed for the response phase.
1. `response`: Runs after the full upstream response is buffered but before any byte reaches the client.
  When `reidentify.enabled = true`, the plugin restores the original values using either `mapping_only` (the request-scoped map) or `reidentify_text` (a vault-authoritative call to `POST /v2/detect/reidentify/string`), then rewrites the response body.
  The end user sees real values; the provider never does.

{% mermaid %}
sequenceDiagram
    autonumber
    participant C as Client
    participant K as {{site.base_gateway}}<br/>skyflow-ai-data-control
    participant S as Skyflow Detect
    participant U as Upstream<br/>LLM / MCP / API

    C->>K: Request containing sensitive values
    Note over K: access phase
    K->>S: POST /v2/detect/deidentify/string
    S-->>K: Tokens + token/value map

    alt Skyflow unreachable and on_error.skyflow = deny
        K-->>C: 502 - request blocked, nothing forwarded
    else De-identified
        K->>U: Forward request - tokens only
        U-->>K: Response referring to tokens
        Note over K: response phase
        K->>S: POST /v2/detect/reidentify/string
        S-->>K: Original values
        K-->>C: Response with real values restored
    end

    Note over K: log phase - entity counts by type, never values
{% endmermaid %}

The plugin attaches to {{site.base_gateway}} Routes and Services and talks to the Skyflow Detect API over HTTPS using a bearer token minted from the configured credential.
It emits metrics and structured logs of detected-entity counts by type, never the values themselves.

With `VAULT_TOKEN`, the same input value always maps to the same token, so multi-message and multi-turn conversations stay coherent even though the provider only ever saw opaque tokens.

### Composing with the AI Proxy plugin

The Skyflow De-identify plugin can't share a Route with `ai-proxy`.
`ai-proxy` transforms the LLM response in its `header_filter`, while re-identify must run in the `response` phase (it calls Skyflow over a cosocket, which {{site.base_gateway}} disallows in `body_filter`).
On one Route, the two plugins contend for the buffered body, and `ai-proxy` returns `500 "no response body found when transforming response"` when the upstream body is gzip-encoded, which real OpenAI always is ([Kong #14380](https://github.com/Kong/kong/issues/14380)).

The fix is a nested-proxy topology with two Routes and two independent buffered cycles.

{% mermaid %}
flowchart TB
    C["Client<br/>Email Jane Doe at jane@acme.com"]
    F["/ai/chat - front route<br/>skyflow-ai-data-control only<br/>access: de-identify · response: re-identify"]
    I["/_ai_upstream - internal route<br/>ai-proxy only"]
    P["Provider<br/>OpenAI · Anthropic · …<br/>sees only tokens"]
    S[("Skyflow<br/>Detect")]

    C -- "sensitive values" --> F
    F -- "tokens only<br/>loopback 127.0.0.1:8000" --> I
    I --> P
    P -- "tokens" --> I
    I -- "tokens" --> F
    F -- "values restored" --> C
    F -. "deidentify · reidentify" .-> S
{% endmermaid %}

Each Route runs its own buffered request/response cycle, which keeps the two plugins out of each other's way.
The internal Route is not externally reachable: an `ip-restriction` plugin bound to `127.0.0.1/32` refuses all other traffic, because that Route doesn't carry authentication or de-identification.

### Agent traffic

Beyond simple JSON bodies, the plugin handles coding-agent and MCP traffic.
It reads large bodies that nginx spools to disk, re-identifies values inside `tool_calls[].function.arguments` (not just message content), and buffers streaming (`stream: true`) responses.
Re-identification runs on the full completion, which is then re-emitted as SSE, so a token split across chunks is never leaked.

## Install the Skyflow De-identify plugin

The Skyflow De-identify plugin is available as a LuaRock or as a pair of self-contained Lua source files.

{% navtabs 'install' %}
{% navtab "Self-managed" %}

{:.info}
> Prerequisites: install `lua >= 5.1` and `lua-resty-http >= 0.17`.
> You don't need to install `resty.http` and `cjson`, as they are provided by the {{site.base_gateway}}/OpenResty runtime.

1. Install the plugin using LuaRocks.
   The rockspec lives with the plugin source, not at the repository root:

   ```bash
   luarocks make ./plugin/kong/plugins/skyflow-ai-data-control/skyflow-ai-data-control-0.7.0-1.rockspec
   ```

1. Enable the plugin on the node:

   ```bash
   export KONG_PLUGINS=bundled,skyflow-ai-data-control
   ```


{% endnavtab %}
{% navtab "{{site.konnect_short_name}}" %}

To install the plugin {{site.konnect_short_name}}, upload the two self-contained files (`schema.lua` and `handler.lua`) to the control plane as a custom plugin.

1. In the {{site.konnect_short_name}} menu, navigate to **Plugins**.
1. Click **Custom Plugins**.
1. Upload `schema.lua` and `handler.lua`.
1. Select **Streamed** as the installation type.
   Streamed plugins require no image rebuild or data plane restart.

The two files depend only on libraries that {{site.base_gateway}} already ships (`resty.http`, `cjson`, and `resty.openssl.pkey` for service-account JWT signing), all of which are on the streamed-plugin sandbox allowlist.

Set the following environment variables on each data plane node:

```bash
KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on
KONG_UNTRUSTED_LUA=lax
KONG_PLUGINS=bundled
```

{:.warning}
> **Note**: Do not add `skyflow-ai-data-control` to `KONG_PLUGINS` on data plane nodes.
> {{site.base_gateway}} will demand local code at boot before streaming arrives, causing the node to fail.
> List only `bundled` and let the control plane stream the plugin code.

If your plugin configuration references `{vault://env/...}` values, also set:

```bash
KONG_VAULTS=bundled
```

{% endnavtab %}
{% endnavtabs %}

## Enable the plugin

After installing the plugin, enable it on a Route or Service.
See the following examples:

- [De-identify only](/plugins/skyflow-ai-data-control/examples/deidentify-only/): tokenizes outbound traffic; the caller also receives tokens. Use this for a strict egress posture.
- [De-identify and re-identify](/plugins/skyflow-ai-data-control/examples/deidentify-and-reidentify/): the upstream provider sees tokens; the caller sees real values restored. This is the default posture.

{:.info}
> **Note**: There is no field for selecting the API format.
> OpenAI, Anthropic, and MCP payloads are detected per request from the body shape, so one configuration serves all three.
> A body shape the plugin does not recognize is refused rather than forwarded unscanned.

Configuration constraints enforced when you save:

- `reidentify.strategy = reidentify_text` requires `deidentify.token_format = VAULT_TOKEN`, because only vault tokens exist in the vault to resolve.
- `mapping_only` requires a format other than `ENTITY_ONLY`, because one-way tokens cannot be reversed.
- `deidentify.configuration_source = config_id` requires `config_id`.
