---
title: 'NVIDIA Switchyard AI Routing'
name: 'NVIDIA Switchyard AI Routing'

content_type: plugin

publisher: nvidia

description: "Delegate per-request LLM model selection to the NVIDIA Switchyard Decision API, while {{site.base_gateway}} retains authority over which models can be reached."

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

third_party: true

icon: nvidia.svg

tags:
  - ai
  - routing

search_aliases:
  - switchyard
  - nemo switchyard
  - nvidia nemo
  - model routing
  - llm routing
  - ai-routing-provider

related_resources:
  - text: NVIDIA NeMo Switchyard
    url: https://github.com/NVIDIA-NeMo/Switchyard
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: "{{site.ai_gateway_name}}"
    url: /ai-gateway/

min_version:
  gateway: '3.14'
---

The NVIDIA Switchyard AI Routing plugin asks an external decision service which model should serve each AI request, then applies that answer through {{site.base_gateway}}'s own {{site.ai_gateway}} machinery.
The decision service returns the name of a target.
{{site.base_gateway}} decides what that name is allowed to mean.

Sending every prompt to your most capable model is expensive, and sending every prompt to your cheapest one is unreliable.
Deciding per request needs a model of prompt difficulty, which is a research problem rather than a gateway problem.
This plugin lets that decision live in [NVIDIA Switchyard](https://github.com/NVIDIA-NeMo/Switchyard) while routing, credentials, and policy stay in {{site.base_gateway}}.

Integrating the NVIDIA Switchyard AI Routing plugin into your {{site.base_gateway}} allows you to:

- **Route each request to an appropriate model**: Send hard prompts to a strong model and easy prompts to a cheaper one, decided per request rather than per route.
- **Keep the gateway in control**: The decision service selects from a list of targets you configure.
  It can't introduce a model, a provider, or a URL that you didn't already authorize.
- **Keep prompts inside the gateway**: By default the plugin redacts every message before the decision request leaves {{site.base_gateway}}, so routing costs you no prompt disclosure.
- **Fail open by default**: If the decision service is slow, down, or returns something unusable, traffic is still served by a configured default target.
- **Adopt it without risk**: The plugin starts in `observe_only`, where decisions are logged but never applied.

{:.info}
> **Note**: This plugin sets the model alias that [AI Proxy Advanced](/plugins/ai-proxy-advanced/) uses to select a target, and executes at a higher priority so its alias is in place first.
> It doesn't route traffic to an LLM directly.

## How it works

The plugin runs in the access phase, ahead of AI Proxy Advanced.
It builds a decision request from the incoming request, submits it to the Switchyard Decision API, and validates the returned `selected.target` against its own `targets` map.
On a match, it rewrites `body.model` to that target's `model_alias`, which is what AI Proxy Advanced matches on.
On anything else, it falls back to `default_target` and logs why.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant Client
    participant Plugin as Kong Gateway<br/>AI Routing Plugin
    participant Switchyard as NVIDIA Switchyard<br/>Decision API
    participant Proxy as AI Proxy Advanced
    participant LLM

    Client->>Plugin: Send AI request
    Plugin->>Switchyard: POST /v1/decision
    Switchyard->>Plugin: selected.target, selected.model

    alt Target is configured and the binding matches
        Plugin->>Proxy: Rewrite model to the target's alias
    else Unknown target, drift, timeout, or error
        Plugin->>Proxy: Use default_target, log the fallback
    end

    Proxy->>LLM: Forward to the selected model
    LLM->>Client: Return response
{% endmermaid %}
<!--vale on-->

The decision service names a target.
The plugin resolves that name against its own configuration and never accepts a URL or an unlisted model from the response.

### The safety property

A routing decision is advice, not an instruction.
The Decision API returns a `selected.target` that the plugin looks up in the `targets` map you configured.
A name it doesn't recognize is a failed decision, not an instruction to build a URL.

The plugin refuses a decision when:

{% table %}
columns:
  - title: Condition
    key: condition
  - title: Result
    key: result
rows:
  - condition: "`selected.target` is not a key in `targets`"
    result: "Fall back to `default_target`, log the outcome"
  - condition: "`selected.model` disagrees with the model bound to that target"
    result: "Fall back, log the drift"
  - condition: "`selected.llm_client.format` or `base_url` disagree with the binding"
    result: "Fall back, log the drift"
  - condition: "The response carries no well-formed `selected.target`"
    result: "Fall back, log the malformed body"
  - condition: "The call times out or fails"
    result: "Fall back, log the reason"
{% endtable %}

Nothing from the decision response reaches the network layer: `base_url` is read for comparison only.
This matters because the decision service is a separate system, often owned by a different team, and a compromised or misconfigured one shouldn't be able to redirect your traffic to an arbitrary host.

### What is sent to the decision service

`POST /v1/decision` takes a whole provider request.
It has no summary-only mode.
The plugin builds that request, so the disclosure boundary is enforced by {{site.base_gateway}} rather than requested of the decision service.

By default the plugin sends no prompt content.
Each message keeps its role and position, but its body is replaced with a `[redacted: N chars]` marker, so the decision service sees the conversation's shape and none of its text.

This is [`config.prompt_disclosure`](/plugins/ai-routing-provider/reference/#schema--config-prompt-disclosure) set to `none`.
Richer modes include prompt text, which routes more accurately at the cost of sending user content to another service.
Turning one on is a privacy decision, so the conservative mode is the default.

{% table %}
columns:
  - title: Mode
    key: mode
  - title: What the decision service receives
    key: receives
rows:
  - mode: "`none`"
    receives: "Roles, message count, and per-message size only"
  - mode: "`latest_user_prompt`"
    receives: "The most recent user message verbatim; the rest redacted"
  - mode: "`recent_message_window`"
    receives: "The last four messages verbatim; the rest redacted"
  - mode: "`full`"
    receives: "The conversation as it stands"
{% endtable %}

Redaction preserves conversation shape, so an algorithm that keys on shape still works.
An algorithm that reads text, such as a prompt classifier or a stage router scoring tool results, doesn't, and settles on its configured default.
That's the trade, and it's why `none` is the default rather than the only option.

### Protocol support

The Decision API fixes the pairing between an inbound protocol and its endpoint, so the plugin validates the two together:

{% table %}
columns:
  - title: protocol
    key: protocol
  - title: Required endpoint
    key: endpoint
rows:
  - protocol: "`openai_chat`"
    endpoint: "`/v1/chat/completions`"
  - protocol: "`openai_responses`"
    endpoint: "`/v1/responses`"
  - protocol: "`anthropic_messages`"
    endpoint: "`/v1/messages`"
{% endtable %}

{:.info}
> **Note**: Streaming responses haven't been exercised with this plugin.

## Install the NVIDIA Switchyard AI Routing plugin

The plugin is a pure Lua plugin with no external dependencies beyond those bundled with {{site.base_gateway}}.

### Prerequisites

Before installing the plugin, make sure you have:

- {{site.base_gateway}} 3.14 or later, for [`model_alias`](/plugins/ai-proxy-advanced/) support in AI Proxy Advanced.
  Earlier versions can use `dispatch: upstream`.
- A {{site.base_gateway}} Enterprise license, for AI Proxy Advanced.
- A reachable NVIDIA Switchyard Decision API, exposing `POST /v1/decision`.
- A route configured in Switchyard whose targets correspond to the models you intend to route between.

Set [`config.dispatch`](/plugins/ai-routing-provider/reference/#schema--config-dispatch) to `model_alias` for the production path, since it dispatches through AI Proxy Advanced.
Use `upstream` only to test the plugin without AI Proxy Advanced or an Enterprise license, since it changes the Service's upstream target directly instead of rewriting a model alias.

#### Run the Switchyard Decision API

Switchyard is built from source.
The decision endpoint is provided by the Rust server:

```bash
git clone https://github.com/NVIDIA-NeMo/Switchyard.git
cd Switchyard
cargo build --release -p switchyard-server
./target/release/switchyard-server --config config.toml --host 0.0.0.0 --port 4000
```

Confirm it's serving before continuing:

```bash
curl -s localhost:4000/health
```

```json
{"status":"ok"}
```
{:.no-copy-code}

For example, a minimal `config.toml` with two tiers:

```toml
schema_version = 1

[llm_clients.provider]
format = "openai_chat"
base_url = "https://openrouter.ai/api/v1"
api_key_env = "PROVIDER_API_KEY"

[targets.weak]
id = "z-ai/glm-5.3"
llm_client = "provider"

[targets.strong]
id = "google/gemini-3.8-flash"
llm_client = "provider"

[routes.kong-router]
id = "kong-router"
type = "random"
targets = ["strong", "weak"]
weights = [1.0, 0.0]
```

{:.info}
> **Note**: `api_key_env` is resolved when the server starts, not on first use.
> An unset variable stops the server booting rather than failing at request time.

### Installation steps

{% navtabs 'install' %}
{% navtab "Self-managed" %}

Install the plugin using one of the following options.

1. Install directly using LuaRocks:

   ```bash
   luarocks install kong-plugin-ai-routing-provider-0.1.0-1.rockspec
   ```

1. Enable the plugin on the node:

   ```bash
   export KONG_PLUGINS=bundled,ai-routing-provider
   ```

Alternatively, build a custom {{site.base_gateway}} image with the plugin installed:

```dockerfile
FROM kong/kong-gateway:3.15

USER root
COPY ./kong-plugin/kong/plugins/ai-routing-provider /usr/local/share/lua/5.1/kong/plugins/ai-routing-provider

ENV KONG_PLUGINS=bundled,ai-routing-provider

USER kong
```

Or, if you're managing plugins through `kong.conf` directly:

1. Copy the plugin directory to {{site.base_gateway}}'s plugin search path, for example `/usr/local/share/lua/5.1/kong/plugins/ai-routing-provider`.
1. In your [`kong.conf`](/gateway/configuration/), append the plugin name to the `plugins` field.
   Make sure the field isn't commented out:

   ```bash
   plugins = bundled,ai-routing-provider
   lua_package_path = /opt/?.lua;;
   ```

1. Restart {{site.base_gateway}}:

   ```bash
   kong restart
   ```

{% endnavtab %}
{% navtab "{{site.konnect_short_name}}" %}

In {{site.konnect_short_name}} hybrid mode, upload the plugin schema to the control plane and deploy the plugin code to each data plane node using a custom Docker image.

1. Clone the plugin repository and set your credentials:

   ```bash
   git clone https://github.com/kong-partner-solutions/nvidia-switchyard-plugin.git
   cd nvidia-switchyard-plugin
   export KONNECT_CP_ID="your-control-plane-id"
   export KONNECT_TOKEN="your-konnect-pat"
   ```

1. Upload the plugin schema using the [{{site.konnect_short_name}} API](/api/konnect/control-planes/):

   ```bash
   curl -X POST \
     "https://us.api.konghq.com/v2/control-planes/${KONNECT_CP_ID}/core-entities/plugin-schemas" \
     --header "Authorization: Bearer ${KONNECT_TOKEN}" \
     --header "Content-Type: application/json" \
     --data "{\"lua_schema\": $(jq -Rs . kong-plugin/kong/plugins/ai-routing-provider/schema.lua)}"
   ```

   Your control plane ID is visible in the URL when viewing the control plane in {{site.konnect_short_name}}, or on the control plane's overview page.

   {:.warning}
   > **Note**: Upload the schema before any decK sync that references the plugin.
   > {{site.konnect_short_name}} validates plugin configuration against the schema it holds, and without it the plugin is silently dropped from the configuration.

1. Run a data plane node with the plugin mounted and enabled:

   ```bash
   docker run -d \
     --name kong-dp-switchyard \
     --restart unless-stopped \
     -e "KONG_ROLE=data_plane" \
     -e "KONG_DATABASE=off" \
     -e "KONG_CLUSTER_MTLS=pki" \
     -e "KONG_CLUSTER_CONTROL_PLANE=YOUR_CP_ENDPOINT:443" \
     -e "KONG_CLUSTER_SERVER_NAME=YOUR_CP_ENDPOINT" \
     -e "KONG_CLUSTER_TELEMETRY_ENDPOINT=YOUR_TELEMETRY_ENDPOINT:443" \
     -e "KONG_CLUSTER_TELEMETRY_SERVER_NAME=YOUR_TELEMETRY_ENDPOINT" \
     -e "KONG_CLUSTER_CERT=/etc/kong/certs/tls.crt" \
     -e "KONG_CLUSTER_CERT_KEY=/etc/kong/certs/tls.key" \
     -e "KONG_LUA_SSL_TRUSTED_CERTIFICATE=system" \
     -e "KONG_KONNECT_MODE=on" \
     -e "KONG_PLUGINS=bundled,ai-routing-provider" \
     -e "KONG_LUA_PACKAGE_PATH=/opt/?.lua;;" \
     -v "$PWD/kong-plugin/kong/plugins/ai-routing-provider:/opt/kong/plugins/ai-routing-provider:ro" \
     -v "$PWD/certs:/etc/kong/certs:ro" \
     -p 8000:8000 \
     kong/kong-gateway:3.15
   ```

1. Confirm the node appears as connected in the API Gateway UI before proceeding.
   {{site.base_gateway}} fails to start if the module is missing, so a healthy data plane means the plugin loaded.

{% endnavtab %}
{% endnavtabs %}

## Enable the plugin

After installing the plugin, enable it on a Route.
See the following examples:

- [Enable NVIDIA Switchyard AI routing](/plugins/ai-routing-provider/examples/enable-ai-routing-provider/): a two-tier configuration in `enforce` mode.
- [Route between model tiers](/plugins/ai-routing-provider/examples/model-tier-routing/): the same configuration, with guidance on adopting it safely from `observe_only` to `enforce`.

The plugin sets a model alias.
AI Proxy Advanced resolves it.
Enable both on the same Route, and make sure each alias referenced here exists as a target there.

Start with `mode: observe_only` to see what the decision service would do without changing behavior, then switch to `enforce`.

### Plugin ordering

The plugin runs at priority `775`, ahead of AI Proxy Advanced.
This is required: the alias is only useful if it's set before AI Proxy Advanced reads it.

## Test the plugin

Send a chat completion request to the configured Route and inspect the routing headers:

```bash
curl -i -X POST http://localhost:8000/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"router","messages":[{"role":"user","content":"Say hello."}]}'
```

A request that was routed by a decision returns:

```
X-AI-Routing-Backend: strong
X-AI-Routing-Outcome: enforced
X-Kong-LLM-Model: openai/google/gemini-3.8-flash
```
{:.no-copy-code}

To confirm the gateway fails open, stop the decision service and repeat the request.
It should still return `200`, served by `default_target`:

```
X-AI-Routing-Backend: weak
X-AI-Routing-Outcome: fallback
```
{:.no-copy-code}

{{site.base_gateway}} logs a single structured line explaining every fallback, at `warn` level so it's visible without raising the log level:

```json
{"outcome":"fallback","mode":"enforce","backend_id":"weak","reason":"decision call failed: connection refused"}
```
{:.no-copy-code}

Enforced and observed decisions are logged the same way at `info` level, carrying `scope` and `fallbacks` instead of `reason`.

## Limitations

- **Routing quality depends on the Switchyard route type**, not on this plugin.
  A `random` route proves the mechanism but makes no claim about choosing well.
  Evaluating routing quality is separate work.
- **`/v1/decision` returns no confidence or reason code.**
  A well-formed `selected.target` is the only validity signal available, so a route whose classifier failed still returns a usable decision that happens to be its default.
  Read the decision service's `/v1/stats` to tell routing from falling back.
- **Narrowing AI Proxy Advanced targets per request isn't possible.**
  Its `filters/acl` configuration is static.
  This plugin therefore dispatches by rewriting the model alias.
- **Streaming responses haven't been exercised.**
- **The decision call isn't retried.**
  It's advisory and fails open, so a retry would double the worst-case added latency during an outage without improving the outcome.
