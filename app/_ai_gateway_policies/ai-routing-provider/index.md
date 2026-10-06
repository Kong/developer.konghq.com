---
title: 'NVIDIA Switchyard AI Routing Policy'
name: 'NVIDIA Switchyard AI Routing Policy'

publisher: kong-inc

min_version:
  ai-gateway: '2.2'
third_party: true
works_on:
  - konnect

products:
  - ai-gateway

content_type: plugin

description: 'Delegate per-request LLM model selection to the NVIDIA Switchyard Decision API, dispatched natively as an {{site.ai_gateway}} custom policy.'

categories:
  - ai

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
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: Custom policies
    url: /ai-gateway/custom-policies/
  - text: Streaming custom plugins
    url: /custom-plugins/streaming-plugins/

icon: nvidia.svg
---

The AI Routing Provider Policy asks the [NVIDIA Switchyard](https://github.com/NVIDIA-NeMo/Switchyard) Decision API which model should serve each request, then sends the request to an [AI Model](/ai-gateway/entities/ai-model/) entity you've already configured on this {{site.ai_gateway}}.

This policy resolves the selected target directly against your {{site.ai_gateway}}'s own AI Model entities, and {{site.ai_gateway}}'s native routing takes over from there.

It's registered as a **streaming [custom policy](/ai-gateway/custom-policies/)** from a `schema.lua` and a `handler.lua` file.
{{site.konnect_short_name}} stores both files and streams them to every data plane, so the data plane runs the stock {{site.ai_gateway}} image.

Benefits of using the AI Routing Provider Policy:

- **Native dispatch**: Routes directly to an AI Model entity.
- **Keep the gateway in control**: The decision service selects from a list of targets you configure.
  It can't introduce a model, a provider, or a URL that you didn't already authorize.
- **Keep prompts inside the gateway**: By default, the policy redacts every message before the decision request leaves {{site.ai_gateway}}, so routing doesn't cost you prompt disclosure.
- **Govern Switchyard's own model calls**: Judge and decision-time answer calls can go through {{site.ai_gateway}} too, so Switchyard holds no provider credential and every model call shows up in {{site.ai_gateway}} analytics.
- **Fail open by default**: If the decision service is slow, down, or returns something unusable, traffic is still served by a configured default target.
- **Adopt it without risk**: The policy starts in `observe_only`, where decisions are logged but never applied.

## How it works

The policy runs in the access phase, at priority `956`, directly after {{site.ai_gateway}}'s `ai-model-selector` (`957`), so the model it sets replaces the one the selector matched.
It builds a decision request from the incoming request, submits it to the Switchyard Decision API, and validates the returned `selected.target` against its own `targets` map.

When [`config.dispatch`](/ai-gateway/policies/ai-routing-provider/reference/#schema--config-dispatch) is set to `konnect_model`, a match resolves the target's `model` against this {{site.ai_gateway}}'s own AI Model entities (by name, then by alias, cached in the data plane) and sets that model as the request's active model.
{{site.ai_gateway}} then proxies to whichever provider that AI Model is configured with.
On an unknown target, drift, timeout, or error, the policy falls back to `default_target` and logs why.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant Client
    participant policy as AI Routing Provider
    participant Switchyard as NVIDIA Switchyard<br/>Decision API
    participant AIGW as {{site.ai_gateway}}<br/>native routing
    participant LLM

    Client->>policy: Send AI request
    policy->>Switchyard: POST /v1/decision (messages filtered by prompt_disclosure)

    opt Judged routes (llm_classifier, composite, escalation, advisor)
        Switchyard->>AIGW: Judge or answer call on an AI Model with no routing policy
        AIGW->>LLM: Forward with AI Gateway's provider credential
        LLM-->>AIGW: Verdict or answer
        AIGW-->>Switchyard: Verdict or answer
    end

    Switchyard->>policy: selected.target, selected.model

    alt Target is configured and the binding matches
        policy->>AIGW: Look up the target's AI Model, set it as active
    else Unknown target, drift, timeout, or error
        policy->>AIGW: Use default_target, log the fallback
    end

    AIGW->>LLM: Forward to the selected model's provider
    LLM->>Client: Return response
{% endmermaid %}
<!--vale on-->

The decision service names a target.
The policy resolves that name against its own configuration and this {{site.ai_gateway}}'s AI Model entities, and never accepts a URL or an unlisted model from the response.

Every response carries two headers that show what the policy did:

{% table %}
columns:
  - title: "Header"
    key: c0
  - title: "Value"
    key: c1
rows:
  - c0: "`X-AI-Routing-Backend`"
    c1: "The target key that served the request"
  - c0: "`X-AI-Routing-Outcome`"
    c1: "`enforced`, `observed` (`observe_only` mode), or `fallback`"
{% endtable %}

Fallbacks are logged at `warn` level as a single JSON line with the `reason`, for example `unknown target 'rogue'` or `decision call failed: timeout`.

### What is sent to the decision service

`POST /v1/decision` takes a whole provider request and has no summary-only mode.
The policy builds that request, so the disclosure boundary is enforced by {{site.ai_gateway}} rather than requested of the decision service.
The request carries only the route name (`decision_route`) and the filtered `messages`.
Generation settings such as `max_tokens`, `temperature`, and `tools` aren't sent.

[`config.prompt_disclosure`](/ai-gateway/policies/ai-routing-provider/reference/#schema--config-prompt-disclosure) controls how much message text leaves {{site.ai_gateway}}.
Every message that isn't disclosed keeps its role and position, but its content is replaced with a `[redacted N chars]` marker.

{% table %}
columns:
  - title: "Mode"
    key: c0
  - title: "What the decision service receives"
    key: c1
rows:
  - c0: "`none` (default)"
    c1: "Roles, message count, and per-message size only"
  - c0: "`latest_user_prompt`"
    c1: "The most recent user message verbatim; the rest redacted"
  - c0: "`task_and_latest_user_prompt`"
    c1: "The first and the most recent user messages verbatim; the rest redacted, including system prompts, assistant turns, and tool results"
  - c0: "`recent_message_window`"
    c1: "The last four messages verbatim; the rest redacted"
  - c0: "`task_and_recent_window`"
    c1: "Every user message before the first assistant reply, and the last 28 non-system messages, tool calls and results included; system and developer prompts and older turns redacted"
  - c0: "`full`"
    c1: "The conversation as it stands"
{% endtable %}

A Switchyard route that reads text routes on whatever it's given.
If the text it needs is redacted, the route settles on its configured default.
Pick the narrowest mode that covers what the route actually reads:

{% table %}
columns:
  - title: "Switchyard route type"
    key: c0
  - title: "What it reads"
    key: c1
  - title: "Mode"
    key: c2
rows:
  - c0: "`random`"
    c1: "Nothing"
    c2: "`none`"
  - c0: "`stage_router`, `auto`"
    c1: "Recent turns and tool results"
    c2: "`recent_message_window`"
  - c0: "`llm_classifier` (`mode = \"capability\"`), `composite`"
    c1: "The opening task and the latest user follow-up"
    c2: "`task_and_latest_user_prompt`"
  - c0: "`llm_classifier` (`mode = \"escalation\"`)"
    c1: "The task framing and a trailing window of 28 messages (`recent_turn_window`)"
    c2: "`task_and_recent_window`"
{% endtable %}

The window of 28 matches the default `recent_turn_window` of Switchyard's escalation judge.
A route that widens its window past 28 sees redaction markers at the old end.

Redaction keeps tool traffic well-formed, because escalation and advisor routes replay the conversation to a model while deciding, and Switchyard rejects a `tool` message without a `tool_call_id`:

- A disclosed message keeps `tool_calls`, `tool_call_id`, and `name` verbatim.
- A redacted `tool` message keeps its `tool_call_id`, an opaque correlation token.
- Each redacted assistant tool call becomes `{"id": "<id>", "type": "function", "function": {"name": "redacted", "arguments": "{\"redacted_chars\":N}"}}`.
  Tool names and arguments are content, so they don't leave {{site.ai_gateway}}.

### Session identity

Several Switchyard routes keep state per session: the `stage_router` capable-tier hold (`capable_hold_turns`), a `composite` or `llm_classifier` route with `classify_trigger = "user_turn"`, the escalation latch, and the advisor's `max_reviews` budget.
The policy always sends `x-switchyard-session-id`, which tops Switchyard's own precedence list, and resolves it in this order:

1. `X-Switchyard-Session-Id`, if the client sent one.
1. A coding-harness session header, in Switchyard's precedence order: `x-claude-code-session-id`, `x-nemo-relay-session-id`, `x-session-id`, the `session_id` field of the `x-codex-turn-metadata` JSON value, then `session-id`.
1. If [`config.session_from_prompt`](/ai-gateway/policies/ai-routing-provider/reference/#schema--config-session-from-prompt) is `true`: `p-` followed by an 8-hex-digit hash of the first user message.
   A conversation that replays its history produces the same value on every turn.
1. The request ID.
   Every request is then its own session, and stateful routes never hold state across requests.

Blank header values are ignored.
The request ID is resolved from `X-Switchyard-Request-Id`, `X-Request-Id`, `X-Client-Request-Id`, then `Kong-Request-Id`.

Turn `session_from_prompt` on for stateful routes whose clients can't send a session header.
Leave it off for sub-agent routes, because sub-agent requests are told apart by their agent-ID headers, and a prompt-hash session could merge unrelated parent and child state.

The policy also forwards Switchyard's sub-agent and harness correlation headers (`x-switchyard-agent-id`, `x-switchyard-is-subagent`, `x-claude-code-agent-id`, `x-codex-parent-thread-id`, and others) and `User-Agent`, which Switchyard reads to tell whether a Claude Code client can identify its sub-agents.

## Register the custom policy

The AI Routing Provider Policy is registered as a **streaming custom policy**: you upload the `schema.lua` and `handler.lua` files directly, and {{site.konnect_short_name}} distributes and runs the handler for you, without a custom data plane image or a self-managed data plane.
See [Custom policies](/ai-gateway/custom-policies/) for the full deployment and lifecycle mechanics shared by every custom policy.

### Data plane prerequisites

The handler calls Switchyard with `resty.http` and looks up AI Models through `kong.db.ai_models`.
A streamed handler is compiled in the `untrusted_lua` sandbox, so the data plane needs both of these settings:

{% table %}
columns:
  - title: "Setting"
    key: c0
  - title: "Value"
    key: c1
  - title: "Why"
    key: c2
rows:
  - c0: "`KONG_CUSTOM_PLUGIN_STREAMING_ENABLED`"
    c1: "`true`"
    c2: "Accept streamed custom policies"
  - c0: "`KONG_UNTRUSTED_LUA`"
    c1: "`on`"
    c2: "The runtime default, `strict`, doesn't allow `require(\"resty.http\")`, and `lax` doesn't expose `kong.db.ai_models`"
{% endtable %}

{:.warning}
> **Important**: With the default `KONG_UNTRUSTED_LUA=strict`, the handler fails to load,
> and the data plane rejects the **whole** synced configuration at the `custom_plugins`
> entry. It never becomes ready and serves no routes at all, not only the routes this
> policy is attached to.
>
> `KONG_UNTRUSTED_LUA=on` turns the sandbox off for every untrusted Lua on the data plane,
> including other streamed policies and `pre-function`/`post-function`. A narrower setting
> that also works is the deprecated `KONG_UNTRUSTED_LUA=sandbox` with
> `KONG_UNTRUSTED_LUA_SANDBOX_REQUIRES=resty.http,cjson.safe`. It limits `require` to those
> two modules but still exposes almost all of the `kong` and `ngx` global variables, and the value
> is deprecated. Choose deliberately for production.

Streaming custom policies need {{site.ai_gateway}} 2.2 or later.
The control plane and data plane versions must match exactly, including patch and pre-release, or configuration sync is rejected.

### Upload the policy code

Create a [`schema.lua` file](https://github.com/kong-partner-solutions/nvidia-switchyard-plugin/blob/main/kong-plugin/kong/plugins/ai-routing-provider/schema.lua) that defines the policy's configuration fields:
```sh
cat <<'LUA_EOF' > schema.lua
-- Copyright 2024-2026 Kong Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local typedefs = require "kong.db.schema.typedefs"

-- Protocol/endpoint pairs are fixed by the Switchyard Decision API contract.
-- Source: crates/switchyard-server/README.md on upstream main.
local PROTOCOL_ENDPOINT = {
  openai_chat        = "/v1/chat/completions",
  openai_responses   = "/v1/responses",
  anthropic_messages = "/v1/messages",
}

local PROTOCOLS = { "openai_chat", "openai_responses", "anthropic_messages" }

-- A Kong-owned binding. The decision service returns a key into this map and
-- nothing else -- it can never supply a URL.
--
-- `model` is the real provider model. `model_alias` is what Kong's
-- ai-proxy-advanced matches on. Keeping both lets us verify a decision against
-- its binding (target-drift detection) while still dispatching by alias.
local target_record = {
  type = "record",
  fields = {
    -- Used when dispatch = "upstream" (stub/no-license testing).
    { upstream_url = {
        type = "string",
        description = "Target upstream base URL when dispatch is 'upstream'.",
    } },
    -- Used when dispatch = "model_alias" (Kong-native, via ai-proxy-advanced).
    { model_alias  = {
        type = "string",
        description = "Model alias recognized by ai-proxy-advanced when dispatch is 'model_alias'.",
    } },
    -- Real provider model name. Checked against the decision to catch drift.
    { model        = {
        type = "string",
        description = "Underlying LLM model name. Verified against decision to prevent drift.",
    } },
    -- Informational. Not used for dispatch.
    { provider     = {
        type = "string",
        description = "Optional provider name for informational and telemetry purposes.",
    } },
    { protocol     = {
        type = "string",
        default = "openai_chat",
        one_of = PROTOCOLS,
        description = "Protocol format used by the target LLM provider.",
    } },
    -- The decision service's own base URL for this target, echoed back as
    -- `selected.llm_client.base_url`. Set it to assert that Switchyard has not
    -- been repointed at a provider Kong never approved.
    { base_url     = {
        type = "string",
        description = "Approved base URL for target to assert Switchyard has not been repointed.",
    } },
  },
}

local function validate(config)
  if type(config.targets) ~= "table" or next(config.targets) == nil then
    return nil, "'targets' must contain at least one entry"
  end

  if config.targets[config.default_target] == nil then
    return nil, "'default_target' must reference a key in 'targets' (got '"
                .. tostring(config.default_target) .. "')"
  end

  for id, target in pairs(config.targets) do
    if config.dispatch == "upstream" then
      if not target.upstream_url or target.upstream_url == "" then
        return nil, "target '" .. id ..
                    "' requires 'upstream_url' when dispatch = 'upstream'"
      end
      if not target.upstream_url:match("^https?://[^/]+") then
        return nil, "target '" .. id ..
                    "' has a malformed 'upstream_url' (want http(s)://host[:port][/path])"
      end

    elseif config.dispatch == "model_alias" then
      if not target.model_alias or target.model_alias == "" then
        return nil, "target '" .. id ..
                    "' requires 'model_alias' when dispatch = 'model_alias'"
      end
    end

    -- Protocol/endpoint pairs are fixed by the Decision API contract; a
    -- mismatch here would make target-drift checks meaningless.
    local want = PROTOCOL_ENDPOINT[target.protocol or "openai_chat"]
    if want == nil then
      return nil, "target '" .. id .. "' has an unknown protocol '" ..
                  tostring(target.protocol) .. "'"
    end
  end

  -- Same contract applies to the inbound side we advertise.
  local want_inbound = PROTOCOL_ENDPOINT[config.inbound_profile or "openai_chat"]
  if config.inbound_endpoint and config.inbound_endpoint ~= ""
     and config.inbound_endpoint ~= want_inbound then
    return nil, "'inbound_profile' " .. tostring(config.inbound_profile) ..
                " requires 'inbound_endpoint' '" .. want_inbound ..
                "' (got '" .. config.inbound_endpoint .. "')"
  end

  return true
end

return {
  name = "ai-routing-provider",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { decision_api_url = typedefs.url {
              required = true,
              description = "Endpoint URL for the external routing decision service (e.g. http://switchyard:4000/v1/decision).",
          } },

          -- Sent as the nested request's `model`. Names a route in the
          -- decision service's own config, e.g. `switchyard/general`.
          { decision_route = {
              type = "string",
              required = true,
              description = "Route or profile name configured in Switchyard server.",
          } },

          -- How much of the live conversation the decision request may carry.
          -- `/v1/decision` has no server-side summary mode, so this is enforced
          -- by Kong: under "none" every message is replaced by a size marker
          -- before encoding, and prompt content never leaves Kong. Anything
          -- richer is a privacy decision, hence the default.
          -- "task_and_latest_user_prompt" discloses exactly the two user messages
          -- Switchyard's llm_classifier judge reads by default -- the opening task
          -- and the latest follow-up -- and redacts everything between, tool
          -- results included.
          -- "task_and_recent_window" discloses what Switchyard's escalation judge
          -- reads: the task framing (every user message before the first
          -- assistant reply) and the last 28 non-system messages, tool calls and
          -- results included. System and developer prompts stay redacted.
          { prompt_disclosure = {
              type    = "string",
              default = "none",
              one_of  = {
                "none", "latest_user_prompt", "task_and_latest_user_prompt",
                "recent_message_window", "task_and_recent_window", "full",
              },
              description = "Scope of prompt content disclosed to Switchyard ('none', 'latest_user_prompt', 'task_and_latest_user_prompt', 'recent_message_window', 'task_and_recent_window', 'full').",
          } },

          -- Inbound protocol advertised to the decision service. The pairing
          -- is fixed by the Switchyard contract, so the two are validated
          -- together rather than set independently.
          { inbound_profile = {
              type    = "string",
              default = "openai_chat",
              one_of  = PROTOCOLS,
              description = "Protocol format of inbound client requests sent to Kong.",
          } },

          { inbound_endpoint = {
              type = "string",
              default = "/v1/chat/completions",
              description = "Inbound request URI matching the advertised profile.",
          } },

          -- Derive session_id from a hash of the first user message when the
          -- caller sent neither X-Switchyard-Session-Id nor a harness session
          -- header (x-claude-code-session-id, x-session-id, session-id, ...).
          -- Harbor cannot set headers, and the request_id fallback makes every
          -- request its own session, so stateful routes never hold state.
          { session_from_prompt = {
              type = "boolean",
              default = false,
              description = "Derive session ID from prompt hash when client does not supply a session header.",
          } },

          { targets = {
              type        = "map",
              required    = true,
              keys        = { type = "string" },
              values      = target_record,
              description = "Map of pre-approved target configurations that Switchyard decisions are permitted to select.",
          } },

          { default_target = {
              type = "string",
              required = true,
              description = "Fallback target ID used when Switchyard is unreachable or decision is rejected.",
          } },

          -- Every environment starts in observe_only. Flipping to enforce is
          -- an explicit, reviewable config change.
          { mode = {
              type    = "string",
              default = "observe_only",
              one_of  = { "observe_only", "enforce" },
              description = "Operational mode: 'observe_only' evaluates routing without modifying traffic; 'enforce' actively routes request.",
          } },

          -- How an enforced decision is applied:
          --   model_alias   -> rewrite body.model so ai-proxy-advanced selects
          --                    the target (the supported production path)
          --   upstream      -> retarget only. body.model is left alone, so this
          --                    reaches a stub, not a provider.
          --   konnect_model -> queries the datastore for the corresponding "konnect aigw model"
          --                    and sets up the targeting accordingly.
          --                    this should make it fully compatible with Kong's new AIGW product.
          { dispatch = {
              type    = "string",
              default = "model_alias",
              one_of  = { "model_alias", "upstream", "konnect_model" },
              description = "Dispatch mechanism: 'model_alias' rewrites model for ai-proxy-advanced; 'upstream' overrides service upstream.",
          } },

          { timeout_ms = {
              type = "number",
              default = 300,
              between = { 1, 60000 },
              description = "HTTP timeout in milliseconds when querying Switchyard Decision API.",
          } },

          { keepalive_timeout = {
              type = "number",
              default = 60000,
              description = "Keepalive idle timeout in milliseconds for HTTP connections to Switchyard.",
          } },

          { keepalive_pool = {
              type = "integer",
              default = 10,
              description = "Maximum idle connections kept in the pool for the Decision API client.",
          } },
        },
    } },
  },
}
LUA_EOF
```
{:.collapsible}

Create a [`handler.lua` file](https://github.com/kong-partner-solutions/nvidia-switchyard-plugin/blob/main/kong-plugin/kong/plugins/ai-routing-provider/handler.lua):

```sh
cat <<'LUA_EOF' > handler.lua
-- Copyright 2024-2026 Kong Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- ai-routing-provider
--
-- Calls out to a routing-decision service, validates the answer against
-- Kong-owned targets, and dispatches through Kong's own machinery.
--
-- One capability is off unless configured, so the default behaviour is a plain
-- decision-API client:
--   session_from_prompt  derive a session key when the caller cannot send one
--
-- SAFETY PROPERTY (do not weaken):
--   A decision may only select among targets already present in `conf.targets`.
--   The decision service returns `selected.target`; we look it up locally. A
--   name we do not recognise is a failed decision, not an instruction to build
--   a URL. In particular `selected.llm_client.base_url` is read for drift
--   checking only -- nothing from the decision response ever reaches the
--   network layer.

local http  = require "resty.http"
local cjson = require "cjson.safe"

local kong = kong


local AiRoutingProvider = {
  -- Must run after ai-model-selector so the model alias we set is forcefully
  -- replaced by what we read here. ai-model-selector is 957 (in September 2026).
  PRIORITY = 956,
  VERSION  = "0.1.0",
}


local OUTCOME_ENFORCED = "enforced"
local OUTCOME_OBSERVED = "observed"
local OUTCOME_FALLBACK = "fallback"


local function log_decision(entry)
  -- Structured single line: greppable in tests, parseable by a log sink.
  --
  -- A fallback means a routing decision was unusable -- the service was down,
  -- or it named a target this route is not allowed to use. Traffic is still
  -- served, so it is not an error, but it is the line an operator needs to see
  -- without turning the log level up. Everything else is routine.
  -- Kong already tags the line with the plugin name, so the payload is just
  -- the JSON.
  local line = cjson.encode(entry)
  if entry.outcome == OUTCOME_FALLBACK then
    kong.log.warn(line)
  else
    kong.log.info(line)
  end
end


-- Session correlation headers read by the decision service.
-- Source: crates/protocol/src/metadata.rs on upstream main.
local HEADER_SESSION_ID = "x-switchyard-session-id"
local HEADER_REQUEST_ID = "x-switchyard-request-id"

-- Harness session headers Switchyard resolves when x-switchyard-session-id is
-- absent, in its precedence order (HEADER_CONFIG in metadata.rs). The plugin
-- always sends x-switchyard-session-id, and that header wins upstream, so the
-- plugin has to resolve these itself: a synthesized value would otherwise
-- override the session a coding harness already sent. Codex's session id sits
-- inside the x-codex-turn-metadata JSON value and is read separately.
local HARNESS_SESSION_HEADERS_BEFORE_CODEX = {
  "x-claude-code-session-id",
  "x-nemo-relay-session-id",
  "x-session-id",
}
local HEADER_CODEX_TURN_METADATA = "x-codex-turn-metadata"
local HARNESS_SESSION_HEADER_AFTER_CODEX = "session-id"

-- Request-id aliases Switchyard falls back to after x-switchyard-request-id.
local HARNESS_REQUEST_ID_HEADERS = {
  "x-request-id",
  "x-client-request-id",
}

-- Forwarded subagent and harness correlation headers.
-- These allow Switchyard's subagent, escalation, and session affinity routers
-- to observe delegated sub-agents and turn lineage.
local FORWARD_CORRELATION_HEADERS = {
  "x-switchyard-agent-id",
  "x-switchyard-parent-agent-id",
  "x-switchyard-is-subagent",
  "x-switchyard-agent-kind",
  "x-switchyard-agent-role",
  "x-switchyard-task-id",
  "x-switchyard-task-kind",
  "x-switchyard-turn-id",
  "x-switchyard-session-final",
  "x-openai-subagent",
  "x-claude-code-session-id",
  "x-claude-code-agent-id",
  "x-claude-code-parent-agent-id",
  "x-codex-turn-metadata",
  "x-codex-parent-thread-id",
  "x-nemo-relay-session-id",
  "x-nemo-relay-subagent-id",
  "x-dynamo-session-id",
  "x-dynamo-parent-session-id",
  "x-dynamo-session-final",
  "thread-id",
  "x-task-id",
  -- Switchyard reads the harness build from User-Agent to tell whether a
  -- Claude Code client can identify its sub-agents at all.
  "user-agent",
}

-- Messages sent verbatim under recent_message_window. Not configurable: a wider
-- window is more prompt content leaving Kong, so it is a code change, not a
-- knob.
local RECENT_WINDOW = 4

-- Trailing messages sent verbatim under task_and_recent_window. Equals the
-- default `recent_turn_window` of Switchyard's escalation judge (28,
-- EscalationJudgeConfig in crates/libsy/src/algorithms/util/escalation.rs),
-- which the demo's kong-escalation route also sets explicitly. A route that
-- widens its window past this sees redaction markers at the old end.
local TASK_WINDOW = 28

-- Fields of a kept message that carry tool traffic. A trajectory judge reads
-- the tool call an assistant made as well as the result it got back.
local TOOL_FIELDS = { "tool_calls", "tool_call_id", "name" }


-- `POST /v1/decision` takes a whole provider request -- there is no server-side
-- "send me a summary instead" mode. Disclosure is therefore enforced here, by
-- deciding what Kong is willing to put in that request in the first place.
--
-- Redaction preserves the shape the routing algorithms actually read -- message
-- count, role order, and per-message size -- while replacing the text. A
-- redacted turn still gives a stage router its turn depth; it gives a prompt
-- classifier an indication of size; it gives the decision service zero
-- bytes of customer text.
--
-- Returns a marker of the form "[redacted <N> chars]".
local function redact(content)
  local len = 0
  if type(content) == "string" then
    len = #content
  elseif type(content) == "table" then
    -- Content-part array (multimodal / tools). Sum text parts, count others.
    for _, part in ipairs(content) do
      if type(part) == "table" and type(part.text) == "string" then
        len = len + #part.text
      else
        len = len + 64 -- generic estimate for non-text parts
      end
    end
  end
  return string.format("[redacted %d chars]", len)
end

-- A redacted message, still well-formed for a provider. Escalation and advisor
-- routes replay the conversation to the weak model while deciding, and
-- Switchyard's client rejects a `tool` message without `tool_call_id` (HTTP 400
-- from /v1/decision). So structure survives redaction: the tool-call ID, which
-- is an opaque correlation token, and one placeholder call per original call.
-- The tool name and arguments are content and do not leave Kong; the
-- arguments keep their size, like message text does.
local function redact_message(msg)
  local out = { role = msg.role, content = redact(msg.content) }

  if type(msg.tool_call_id) == "string" then
    out.tool_call_id = msg.tool_call_id
  end

  if type(msg.tool_calls) == "table" then
    local calls = {}
    for _, call in ipairs(msg.tool_calls) do
      if type(call) == "table" and type(call.id) == "string" then
        local fn = type(call["function"]) == "table" and call["function"] or {}
        local args = type(fn.arguments) == "string" and fn.arguments or ""
        table.insert(calls, {
          id         = call.id,
          type       = "function",
          ["function"] = {
            name      = "redacted",
            arguments = string.format('{"redacted_chars":%d}', #args),
          },
        })
      end
    end
    if #calls > 0 then
      out.tool_calls = calls
    end
  end

  return out
end


-- System and developer prompts: instructions to the agent, not its trajectory.
local function is_instruction(msg)
  return msg.role == "system" or msg.role == "developer"
end


-- Walks inbound messages and decides, per message, whether its text may leave
-- Kong under the configured prompt_disclosure policy.
local function filter_messages(conf, messages)
  if type(messages) ~= "table" then
    return {}
  end

  local disclosure = conf.prompt_disclosure or "none"

  if disclosure == "full" then
    return messages
  end

  local total = #messages
  local filtered = {}

  -- Indexes of the first and last messages with role == "user", and of the
  -- first assistant reply.
  local first_user_idx, last_user_idx, first_assistant_idx = nil, nil, nil
  for i = 1, total do
    local msg = messages[i]
    if type(msg) == "table" then
      if msg.role == "user" then
        first_user_idx = first_user_idx or i
        last_user_idx = i
      elseif msg.role == "assistant" then
        first_assistant_idx = first_assistant_idx or i
      end
    end
  end

  -- task_and_recent_window mirrors how Switchyard's escalation judge builds
  -- its transcript (summarize_for_judge upstream): every user message before
  -- the first assistant reply is task framing and always shown; after that,
  -- the last TASK_WINDOW non-instruction messages. System and developer
  -- messages stay redacted: the judge caps them hard because they carry no
  -- trajectory signal, and harness system prompts are large.
  local window_start = total + 1
  if disclosure == "task_and_recent_window" then
    local seen = 0
    for i = total, 1, -1 do
      local msg = messages[i]
      local framing = type(msg) == "table" and msg.role == "user"
                      and (not first_assistant_idx or i < first_assistant_idx)
      if type(msg) == "table" and not framing and not is_instruction(msg) then
        if seen == TASK_WINDOW then
          break
        end
        seen = seen + 1
        window_start = i
      end
    end
  end

  for i, msg in ipairs(messages) do
    if type(msg) ~= "table" then
      -- Pass unparseable elements through redacted rather than drop them;
      -- preserves turn count.
      table.insert(filtered, { role = "user", content = redact(nil) })
    else
      local keep = false

      if disclosure == "latest_user_prompt" then
        keep = (i == last_user_idx)

      elseif disclosure == "task_and_latest_user_prompt" then
        -- The opening task and the latest follow-up: what Switchyard's
        -- llm_classifier judge reads by default (task_messages() upstream),
        -- and nothing it does not.
        keep = (i == first_user_idx or i == last_user_idx)

      elseif disclosure == "task_and_recent_window" then
        if not is_instruction(msg) then
          local framing = msg.role == "user"
                          and (not first_assistant_idx or i < first_assistant_idx)
          keep = framing or i >= window_start
        end

      elseif disclosure == "recent_message_window" then
        keep = (i > total - RECENT_WINDOW)
      end
      -- disclosure == "none": keep stays false for every message

      if keep then
        local out = { role = msg.role, content = msg.content }
        for _, field in ipairs(TOOL_FIELDS) do
          out[field] = msg[field]
        end
        table.insert(filtered, out)
      else
        table.insert(filtered, redact_message(msg))
      end
    end
  end

  return filtered
end


-- djb2 string hash. Deliberately simple: runs inside the request path on
-- short strings, needs no external library, stable across LuaJIT restarts.
-- Returned as 8 hex chars.
local function hash_string(str)
  local hash = 5381
  for i = 1, #str do
    hash = (hash * 33 + str:byte(i)) % 0x100000000
  end
  return string.format("%08x", hash)
end


-- Pulls the text of the first user message out of an OpenAI-format body.
-- Used as a last-resort session key when the caller provides no correlation
-- headers at all. Returns nil if the body has no user message.
local function first_user_prompt(body)
  if type(body) ~= "table" or type(body.messages) ~= "table" then
    return nil
  end

  for _, msg in ipairs(body.messages) do
    if type(msg) == "table" and msg.role == "user" then
      if type(msg.content) == "string" then
        return msg.content
      elseif type(msg.content) == "table" then
        for _, part in ipairs(msg.content) do
          if type(part) == "table" and type(part.text) == "string" then
            return part.text
          end
        end
      end
    end
  end

  return nil
end


-- Returns the header's value, or nil when it is missing or blank.
local function header_value(name)
  local val = kong.request.get_header(name)
  if type(val) == "string" and val:find("%S") then
    return val
  end
  return nil
end


-- The session a coding harness sent, resolved in Switchyard's own precedence
-- order. Returns nil when the caller sent none.
local function harness_session_id()
  for _, hname in ipairs(HARNESS_SESSION_HEADERS_BEFORE_CODEX) do
    local val = header_value(hname)
    if val then
      return val
    end
  end

  local codex = header_value(HEADER_CODEX_TURN_METADATA)
  if codex then
    local meta = cjson.decode(codex)
    if type(meta) == "table" and type(meta.session_id) == "string"
       and meta.session_id:find("%S") then
      return meta.session_id
    end
  end

  return header_value(HARNESS_SESSION_HEADER_AFTER_CODEX)
end


-- Derives request_id and session_id from request context, with fallbacks.
--
-- request_id:
--   1. Inbound X-Switchyard-Request-Id header (caller-assigned)
--   2. Inbound X-Request-Id, then X-Client-Request-Id (Switchyard's aliases)
--   3. Kong's request ID (generated by Kong core / correlation-id plugin)
--
-- session_id:
--   1. Inbound X-Switchyard-Session-Id header (explicit session)
--   2. A harness session header (Claude Code, NeMo Relay, OpenCode, Codex,
--      generic `session-id`), in Switchyard's precedence order. Without this
--      step the fallbacks below would override a session the client did send.
--   3. If conf.session_from_prompt is true: hash of the first user prompt.
--      A multi-turn conversation that preserves message history produces the
--      same hash on every turn, which is what stateful routes (classifier
--      `user_turn`, escalation latch, advisor review budget) key on, even
--      through callers like Harbor that cannot send custom headers.
--   4. Fallback: request_id. Every request is its own session; stage routing
--      collapses to turn 0, which is safe.
local function derive_ids(conf, body)
  local request_id = header_value(HEADER_REQUEST_ID)
  if not request_id then
    for _, hname in ipairs(HARNESS_REQUEST_ID_HEADERS) do
      request_id = header_value(hname)
      if request_id then
        break
      end
    end
  end
  request_id = request_id or header_value("Kong-Request-Id")
  if not request_id then
    -- Last-ditch request ID so the decision service never sees an empty header.
    request_id = string.format("%08x%08x", math.random(0, 0x7fffffff), math.random(0, 0x7fffffff))
  end

  local session_id = header_value(HEADER_SESSION_ID) or harness_session_id()
  if not session_id and conf.session_from_prompt and body then
    local prompt = first_user_prompt(body)
    if prompt and prompt ~= "" then
      session_id = "p-" .. hash_string(prompt)
    end
  end

  return request_id, session_id or request_id
end


-- Builds the payload for `POST /v1/decision`.
--
-- Upstream contract:
--   input_format: matches inbound_profile (e.g. "openai_chat")
--   request.model: names the Switchyard route to evaluate
--   request.messages: filtered under prompt_disclosure
local function build_decision_request(conf, body)
  local messages
  if type(body) == "table" and type(body.messages) == "table" then
    messages = filter_messages(conf, body.messages)
  else
    messages = { { role = "user", content = redact(nil) } }
  end

  return {
    input_format = conf.inbound_profile,
    request = {
      model    = conf.decision_route,
      messages = messages,
    },
  }
end


-- Normalizes a `/v1/decision` body into the flat shape the rest of this plugin
-- works with. Returns nil + reason on anything unexpected.
--
-- The response carries no schema tag and no confidence score, so the presence
-- of a well-formed `selected.target` is the only validity signal available.
local function normalize_decision(decoded)
  local selected = decoded.selected
  if type(selected) ~= "table" or type(selected.target) ~= "string" then
    return nil, "decision response missing 'selected.target'"
  end

  local client = type(selected.llm_client) == "table" and selected.llm_client or {}

  return {
    backend_id = selected.target,
    model      = selected.model,
    protocol   = client.format,
    base_url   = client.base_url,
    fallbacks  = type(decoded.fallbacks) == "table" and #decoded.fallbacks or 0,
  }
end


-- Returns decision table, or nil + reason. Never throws.
local function fetch_decision(conf, body)
  local httpc, err = http.new()
  if not httpc then
    return nil, "http client unavailable: " .. tostring(err)
  end

  httpc:set_timeout(conf.timeout_ms)

  local payload = cjson.encode(build_decision_request(conf, body))
  local request_id, session_id = derive_ids(conf, body)

  local headers = {
    ["Content-Type"]    = "application/json",
    [HEADER_SESSION_ID] = session_id,
    [HEADER_REQUEST_ID] = request_id,
  }

  for _, hname in ipairs(FORWARD_CORRELATION_HEADERS) do
    local val = kong.request.get_header(hname)
    if val then
      headers[hname] = val
    end
  end

  -- Deliberately no retry. The call is advisory and fails open, so a retry buys
  -- a marginally better chance of a decision at the cost of doubling the delay
  -- added to every request during an outage. Serving promptly from
  -- default_target is the better trade.
  local res, rerr = httpc:request_uri(conf.decision_api_url, {
    method            = "POST",
    body              = payload,
    headers           = headers,
    keepalive_timeout = conf.keepalive_timeout or 60000,
    keepalive_pool    = conf.keepalive_pool or 10,
  })

  if not res then
    return nil, "decision call failed: " .. tostring(rerr)
  end

  if res.status ~= 200 then
    return nil, "decision service returned HTTP " .. tostring(res.status)
  end

  local decoded = cjson.decode(res.body or "")
  if type(decoded) ~= "table" then
    return nil, "malformed decision body"
  end

  return normalize_decision(decoded)
end


-- Validates a decision against the binding it claims to select.
--
-- The Decision API echoes the target's model and client settings alongside its
-- name. Where a bound value exists, they must match exactly; a mismatch means
-- the decision service and the gateway disagree about what that target *is*,
-- which is target drift and must fail open rather than dispatch.
--
-- `base_url` is the sharpest of the three: it is the field that would send
-- traffic somewhere Kong never approved, so a Switchyard target repointed at a
-- new provider is caught here even when the model name is unchanged.
local function check_binding(target, decision)
  local checks = {
    { field = "model",    bound = target.model,    got = decision.model },
    { field = "protocol", bound = target.protocol, got = decision.protocol },
    { field = "base_url", bound = target.base_url, got = decision.base_url },
  }

  for _, c in ipairs(checks) do
    -- Only assert on fields the decision actually asserted.
    if type(c.got) == "string" and c.bound and c.bound ~= "" and c.got ~= c.bound then
      return false, "target drift: decision " .. c.field .. " '" .. c.got ..
                    "' does not match bound '" .. c.bound .. "'"
    end
  end

  return true
end


local function parse_url(url)
  local scheme, hostport, path = url:match("^(https?)://([^/]+)(.*)$")
  if not scheme then
    return nil
  end

  local host, port = hostport:match("^([^:]+):?(%d*)$")
  port = tonumber(port) or (scheme == "https" and 443 or 80)

  if path == "" then
    path = "/"
  end

  return scheme, host, port, path
end

-- Load ai_model(s) object from the datastore in RAM
local function load_ai_model(model_string)
  local entity, err = kong.db.ai_models:select_by_name(model_string)
  if err then
    return nil, err
  end
  if entity then
    return entity
  end

  -- name miss: fall back to the (optional) alias. Name precedence is preserved
  -- because select_by_name is tried first.
  entity, err = kong.db.ai_models:select_by_alias(model_string)
  if err then
    return nil, err
  end
  return entity
end

-- Applies a validated target. Returns true, or false + reason so the caller
-- can fall back rather than fail the request.
local function apply_target(conf, target, body)
  if conf.dispatch == "upstream" then
    local scheme, host, port, path = parse_url(target.upstream_url)
    if not scheme then
      return false, "unparseable upstream_url"
    end

    -- Retarget only. The body still names whatever model the client asked for,
    -- so this mode reaches a stub, not a provider -- see the schema notes.
    kong.service.set_target(host, port)
    kong.service.request.set_scheme(scheme)
    kong.service.request.set_path(path)
    return true

  elseif conf.dispatch == "konnect_model" then
    -- Query datastore for the selected model 'alias' from SwitchYard (OpenRouter?)
    local cache_key = kong.db.ai_models:cache_key(target.model)
    local entity, err = kong.cache:get(cache_key, nil, load_ai_model, target.model)
    if (not entity) or err then
      kong.log.err("error finding model ", target.model, " in datastore: ", err)

      return kong.response.exit(400, {
        error = true,
        message = "unable to find model " .. (target.model or "NONE_SENT") .. " in deployed Konnect AI Gateway models"
      })
    end

    ngx.ctx.ai_model = entity
    kong.log.notice("Set '", entity.alias or entity.name, "' (", entity.id, ") as the active model")

    return true
  end

  -- dispatch == "model_alias": rewrite the model to the target's alias so
  -- ai-proxy-advanced's extract-model-alias filter selects the matching
  -- target. Kong still owns credentials, provider config and dispatch.
  if type(body) ~= "table" then
    return false, "cannot rewrite model alias: request body is not JSON"
  end

  body.model = target.model_alias
  local encoded = cjson.encode(body)
  if not encoded then
    return false, "failed to re-encode request body"
  end

  kong.service.request.set_raw_body(encoded)
  return true
end


function AiRoutingProvider:access(conf)
  local ctx = kong.ctx.plugin

  local raw  = kong.request.get_raw_body()
  local body = raw and cjson.decode(raw) or nil

  local decision, reason = fetch_decision(conf, body)

  local backend_id, fallbacks
  if decision then
    -- The safety property, enforced here and nowhere else.
    local target = conf.targets[decision.backend_id]
    if target then
      local ok, drift = check_binding(target, decision)
      if ok then
        backend_id = decision.backend_id
        fallbacks  = decision.fallbacks
      else
        reason = drift
      end
    else
      reason = "unknown target '" .. decision.backend_id .. "'"
    end
  end

  if not backend_id then
    -- Fallback path. A routing-decision failure must never become a
    -- user-facing error.
    backend_id = conf.default_target
    ctx.outcome = OUTCOME_FALLBACK
    ctx.backend_id = backend_id
    log_decision({
      outcome    = OUTCOME_FALLBACK,
      mode       = conf.mode,
      backend_id = backend_id,
      reason     = reason,
    })

    if conf.mode == "enforce" then
      apply_target(conf, conf.targets[backend_id], body)
    end
    return
  end

  if conf.mode == "observe_only" then
    -- Log what we would have done; leave routing untouched.
    ctx.outcome = OUTCOME_OBSERVED
    ctx.backend_id = backend_id
    log_decision({
      outcome    = OUTCOME_OBSERVED,
      mode       = conf.mode,
      backend_id = backend_id,
      fallbacks  = fallbacks,
    })
    return
  end

  local ok, apply_err = apply_target(conf, conf.targets[backend_id], body)
  if not ok then
    backend_id = conf.default_target
    ctx.outcome = OUTCOME_FALLBACK
    ctx.backend_id = backend_id
    log_decision({
      outcome    = OUTCOME_FALLBACK,
      mode       = conf.mode,
      backend_id = backend_id,
      reason     = apply_err,
    })
    apply_target(conf, conf.targets[backend_id], body)
    return
  end

  ctx.outcome = OUTCOME_ENFORCED
  ctx.backend_id = backend_id
  log_decision({
    outcome    = OUTCOME_ENFORCED,
    mode       = conf.mode,
    backend_id = backend_id,
    fallbacks  = fallbacks,
  })
end


function AiRoutingProvider:header_filter(conf)
  local ctx = kong.ctx.plugin
  if ctx.backend_id then
    kong.response.set_header("X-AI-Routing-Backend", ctx.backend_id)
    kong.response.set_header("X-AI-Routing-Outcome", ctx.outcome or "unknown")
  end
end


return AiRoutingProvider
LUA_EOF
```
{:.collapsible}

From the directory where your `schema.lua` and `handler.lua` files are, register it once per {{site.ai_gateway}}:
```sh
curl -i -X POST \
  https://us.api.konghq.com/v1/ai-gateways/$AI_GATEWAY_ID/custom-policies \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $KONNECT_TOKEN" \
  --data "$(jq -n \
    --arg name "ai-routing-provider" \
    --arg type "streaming" \
    --arg display_name "NVIDIA Switchyard AI Routing" \
    --rawfile schema ./schema.lua \
    --rawfile handler ./handler.lua \
    '{name: $name, type: $type, display_name: $display_name, schema: $schema, handler: $handler}')"
```

{:.info}
> **Note**: This registers the policy type once per {{site.ai_gateway}}. You still need to
> [configure and attach an instance of it](#configure-the-policy).

### Update the policy code

Registering again doesn't update the code: a second `POST` returns `409 Conflict`.
To ship a new `handler.lua`, `PUT` the custom policy by name:

```sh
curl -i -X PUT \
  https://us.api.konghq.com/v1/ai-gateways/$AI_GATEWAY_ID/custom-policies/ai-routing-provider \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $KONNECT_TOKEN" \
  --data "$(jq -n \
    --arg name "ai-routing-provider" \
    --arg type "streaming" \
    --arg display_name "NVIDIA Switchyard AI Routing" \
    --rawfile schema ./schema.lua \
    --rawfile handler ./handler.lua \
    '{name: $name, type: $type, display_name: $display_name, schema: $schema, handler: $handler}')"
```

For a schema change, follow the migration path in [Custom policies](/ai-gateway/custom-policies/): create a new version, move instances to the new schema, then delete the old version.

## Configure the policy

To use the AI Routing Provider Policy, create an instance of the registered custom policy type the same way as any other {{site.ai_gateway}} policy, setting `type` to the `name` you registered.
Then attach the instance to the AI Model that clients call, through that model's `policies` array.
When `global` is `false`, the policy runs only on the AI Models that reference it.

{:.warning}
> **Important**: Set `dispatch: konnect_model` explicitly. The schema defaults `dispatch`
> to `model_alias`, which doesn't apply on {{site.ai_gateway}} 2.x.

### Konnect API

```bash
curl -X POST https://{region}.api.konghq.com/v1/ai-gateways/{AIGatewayId}/policies \
    --header "accept: application/json" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $KONNECT_TOKEN" \
    --data '
    {
      "display_name": "AI Routing Provider",
      "name": "ai-routing-provider",
      "type": "ai-routing-provider",
      "enabled": true,
      "global": false,
      "config": {
        "decision_api_url": "http://switchyard:4000/v1/decision",
        "decision_route": "kong-router",
        "mode": "observe_only",
        "dispatch": "konnect_model",
        "default_target": "weak",
        "prompt_disclosure": "none",
        "timeout_ms": 2000,
        "targets": {
          "weak": {
            "model": "z-ai/glm-5.3",
            "provider": "openai",
            "protocol": "openai_chat",
            "base_url": "https://openrouter.ai/api/v1"
          },
          "strong": {
            "model": "google/gemini-3.8-flash",
            "provider": "openai",
            "protocol": "openai_chat",
            "base_url": "https://openrouter.ai/api/v1"
          }
        }
      }
    }
    '
```

Then add the returned policy `id` to the `policies` array of the AI Model that clients call.

### kongctl

```yaml
ai_gateway_policies:
  - ref: ai-routing-provider
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: AI Routing Provider
    name: ai-routing-provider
    type: ai-routing-provider
    enabled: true
    global: false
    config:
      decision_api_url: http://switchyard:4000/v1/decision
      decision_route: kong-router
      mode: observe_only
      dispatch: konnect_model
      default_target: weak
      prompt_disclosure: none
      timeout_ms: 2000
      targets:
        weak:
          model: z-ai/glm-5.3
          provider: openai
          protocol: openai_chat
          base_url: https://openrouter.ai/api/v1
        strong:
          model: google/gemini-3.8-flash
          provider: openai
          protocol: openai_chat
          base_url: https://openrouter.ai/api/v1

ai_gateway_models:
  # The model clients call. It matches `"model": "router"` on /ai-chat and
  # carries the Policy, which replaces it with the selected model.
  - ref: router
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: router
    type: model
    formats:
      - type: openai
    config:
      route:
        paths:
          - /ai-chat
        model:
          values:
            - router
    targets:
      # Placeholder. It isn't dialed once the Policy sets the active model.
      - name: nowhere
        provider: PROVIDER_NAME
        config:
          type: openai
          upstream_url: https://openrouter.ai/api/v1/chat/completions
    policies:
      - !ref ai-routing-provider
    capabilities:
      - generate
```
{: data-file="policy.yaml" data-tool="kongctl" }

Make sure to replace the following placeholders with your own values:

* `AI_GATEWAY_ID`: The `id` of your {{site.ai_gateway}}.
* `PROVIDER_NAME`: The `name` of an [AI Model Provider](/ai-gateway/entities/ai-provider/) on this {{site.ai_gateway}}.

Each target needs its own AI Model on this {{site.ai_gateway}}, on the same route path, with no routing policy (`policies: []`).
Bind the target fields as follows:

* `targets.*.model`: The model value the target's AI Model matches on its route (`config.route.model.values`), for example `google/gemini-3.8-flash`.
  The data plane stores that value as the model's alias, and the policy looks the model up by name, then by alias.
  An AI Model named `google-gemini-3.8-flash` that matches `google/gemini-3.8-flash` is found by its alias.
  If no AI Model matches, the request fails with `400` (`unable to find model … in deployed Konnect AI Gateway models`).
* `targets.*.base_url`, `targets.*.protocol`: The `base_url` and `format` of the Switchyard `llm_client` that target uses.
  Switchyard echoes them as `selected.llm_client`, and a mismatch is treated as target drift.

Start with `mode: observe_only` to see what the decision service would do without changing behavior, then switch to `enforce`.

### Decision timeout

`timeout_ms` defaults to `300` and accepts `1` to `60000`.
Size it for the Switchyard route, because a decision that overruns it falls back to `default_target`:

{% table %}
columns:
  - title: "Switchyard route"
    key: c0
  - title: "Model calls while deciding"
    key: c1
  - title: "Suggested `timeout_ms`"
    key: c2
rows:
  - c0: "`random`, `stage_router`, `auto`"
    c1: "None"
    c2: "`2000`"
  - c0: "`llm_classifier` (capability), `composite`"
    c1: "One judge call"
    c2: "`30000`"
  - c0: "`llm_classifier` (escalation), `advisor`"
    c1: "An answer call, then a judge or review call, in series"
    c2: "`60000`"
{% endtable %}

Keep the `timeout_ms` of Switchyard's own `llm_clients` below this value, so a slow judge fails open inside Switchyard rather than timing out the whole decision.

{:.warning}
> **Important**: {{site.konnect_short_name}} accepts a `timeout_ms` above `60000`, but the data plane rejects it.
> The data plane then stops syncing **all** configuration and keeps serving its previous
> configuration for every route, with no visible error to clients. After every change,
> check the data plane log for `sync_handler()` errors.

## Route Switchyard's model calls through {{site.ai_gateway}}

`llm_classifier`, `composite`, escalation, and advisor routes call models while deciding: a judge, and for escalation and advisor routes, an answer from a target model.
When left alone, Switchyard calls the provider itself with a key of its own, outside {{site.ai_gateway}}'s governance and analytics.

Point those calls at {{site.ai_gateway}} instead:

1. Create an AI Model for each model Switchyard calls (the judge, and each target), on a path of its own, with:
   - `policies: []`.
     A routing policy on these models would ask Switchyard which model should answer Switchyard's own call, and the two would loop without bound.
   - `config.balancer.retries: 0`.
     Switchyard retries inside its own client deadline.
     {{site.ai_gateway}} must not retry on top of it.
1. In Switchyard's `config.toml`, point the `llm_clients` at {{site.ai_gateway}}, with no `api_key_env`.
   Switchyard posts to `{base_url}/chat/completions`:

   ```toml
   [llm_clients.kong-models]
   format = "openai_chat"
   base_url = "http://kong:8000/ai-switchyard"
   timeout_ms = 30000

   [llm_clients.kong-judge]
   format = "openai_chat"
   base_url = "http://kong:8000/ai-judge"
   timeout_ms = 25000

   [targets.weak]
   id = "z-ai/glm-5.3"
   llm_client = "kong-models"
   extra_body = { max_tokens = 2048 }

   [targets.strong]
   id = "google/gemini-3.8-flash"
   llm_client = "kong-models"
   extra_body = { max_tokens = 2048 }

   [targets.classifier]
   id = "openai/gpt-5.6-luna-pro"
   llm_client = "kong-judge"
   ```

1. Set each policy target's `base_url` to the Switchyard client's `base_url` (`http://kong:8000/ai-switchyard` above), since that's what the decision echoes.

The decision request carries no `max_tokens`, so `extra_body` bounds Switchyard's own answer calls.
Switchyard merges it only when the request lacks the key, and the policy ignores the echoed `extra_body`.

## Limitations

- **Routing quality depends on the Switchyard route type**, not on this policy.
  A `random` route proves the mechanism but makes no claim about choosing well.
  Evaluating routing quality is separate work.
- **`/v1/decision` doesn't return the confidence or reason code.** A well-formed `selected.target` is the only validity signal available, so a route whose classifier failed still returns a usable decision that happens to be its default.
  Read the decision service's `/v1/stats` to tell routing from falling back.
- **An unresolvable target model fails the request.** If the selected or default target's `model` matches no AI Model on this {{site.ai_gateway}}, the policy returns `400` rather than falling back.
- **Escalation and advisor routes bill a turn twice.** While deciding, Switchyard has a model answer the turn and returns it as `response`.
  The policy reads only `selected.target` and doesn't serve `response`, because it answers the conversation as disclosed (redacted, without the client's tools or generation settings), not the client's request.
  {{site.ai_gateway}} then calls the selected model again.
  A latched escalation session goes straight to the strong target with no answer call.
- **The advisor's rewritten request never reaches the model.** A REDO verdict rewrites the request with the advisor's plan, but `/v1/decision` has no field for a rewritten request, so {{site.ai_gateway}} sends the client's original request to the executor.
  In decision-only mode an `advisor` route always serves its executor target.
- **Target settings that only Switchyard applies don't reach {{site.ai_gateway}}.** A target's `system_prompt` and `reasoning_effort`, and stage `handoff_notes`, change only the calls Switchyard makes itself.
- **Prompt-hash sessions can collide.** `session_from_prompt` uses a 32-bit hash of the first user message, so conversations that open with identical text share a session.
  A client that can send `X-Switchyard-Session-Id` should.
- **Streaming responses haven't been exercised.**
- **The decision call isn't retried.** It's advisory and fails open, so a retry would double the worst-case added latency during an outage without improving the outcome.
- **`dispatch: model_alias` and `dispatch: upstream` don't apply here.** Use `dispatch: konnect_model`.
