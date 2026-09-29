---
title: 'NVIDIA Switchyard AI Routing'
name: 'NVIDIA Switchyard AI Routing'

publisher: kong-inc

min_version:
  ai-gateway: '2.1'
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
  - text: NVIDIA Switchyard AI Routing plugin (classic {{site.base_gateway}})
    url: /plugins/ai-routing-provider/
  - text: NVIDIA NeMo Switchyard
    url: https://github.com/NVIDIA-NeMo/Switchyard
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: Custom policies
    url: /ai-gateway/custom-policies/

icon: nvidia.svg
---

The AI Routing Provider Policy is the {{site.ai_gateway}} 2.0 equivalent of the
[NVIDIA Switchyard AI Routing plugin](/plugins/ai-routing-provider/): it asks the NVIDIA
Switchyard Decision API which model should serve each request, then sends the request
to an [AI Model](/ai-gateway/entities/ai-model/) entity you've already configured on this
{{site.ai_gateway}}.

This Policy resolves the selected target directly against your {{site.ai_gateway}}'s own AI
Model entities, and {{site.ai_gateway}}'s native routing takes over from there.
Unlike the classic {{site.base_gateway}} plugin, it doesn't need [AI Proxy Advanced](/plugins/ai-proxy-advanced/) in front of it.

This Policy runs the same `schema.lua` and `handler.lua` that back the
[NVIDIA Switchyard AI Routing plugin](/plugins/ai-routing-provider/), registered as a
**custom policy** rather than installed as a plugin.

Benefits of using the AI Routing Provider Policy:

- **Native dispatch**: Routes directly to an AI Model entity instead of rewriting a model alias for another plugin to resolve.
- **Keep the gateway in control**: The decision service selects from a list of targets you configure. It can't introduce a model, a provider, or a URL that you didn't already authorize.
- **Keep prompts inside the gateway**: By default, the Policy redacts every message before the decision request leaves {{site.ai_gateway}}, so routing doesn't cost you prompt disclosure.
- **Fail open by default**: If the decision service is slow, down, or returns something unusable, traffic is still served by a configured default target.
- **Adopt it without risk**: The Policy starts in `observe_only`, where decisions are logged but never applied.

## How it works

The Policy runs in the access phase. It builds a decision request from the incoming
request, submits it to the Switchyard Decision API, and validates the returned
`selected.target` against its own `targets` map.

When [`config.dispatch`](/ai-gateway/policies/ai-routing-provider/reference/#schema--config-dispatch)
is set to `konnect_model`, a match resolves the target's `model` against this {{site.ai_gateway}}'s own
AI Model entities (by name, then by alias) and sets that model as the request's active model.
{{site.ai_gateway}} then proxies to whichever provider that AI Model is configured with.
On anything else, unknown target, drift, timeout, or error, the Policy falls back to
`default_target` and logs why.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant Client
    participant Policy as AI Routing Provider
    participant Switchyard as NVIDIA Switchyard<br/>Decision API
    participant AIGW as {{site.ai_gateway}}<br/>native routing
    participant LLM

    Client->>Policy: Send AI request
    Policy->>Switchyard: POST /v1/decision
    Switchyard->>Policy: selected.target, selected.model

    alt Target is configured and the binding matches
        Policy->>AIGW: Set the resolved AI Model as active
    else Unknown target, drift, timeout, or error
        Policy->>AIGW: Use default_target, log the fallback
    end

    AIGW->>LLM: Forward to the selected model's provider
    LLM->>Client: Return response
{% endmermaid %}
<!--vale on-->

The decision service names a target. The Policy resolves that name against its own
configuration and this {{site.ai_gateway}}'s AI Model entities, and never accepts a URL or an
unlisted model from the response. For the full safety and prompt-disclosure model shared
with the classic plugin, see [How it works](/plugins/ai-routing-provider/#how-it-works) on
the {{site.base_gateway}} plugin page.

## Register the custom policy

The AI Routing Provider Policy is registered as a **streaming custom policy**: you upload the
plugin's `schema.lua` and `handler.lua` directly, and {{site.konnect_short_name}} distributes
and runs the handler for you, without a custom data plane image or a self-managed data plane.
See [Custom policies](/ai-gateway/custom-policies/) for the full deployment and lifecycle
mechanics shared by every custom policy.

Create a [`schema.lua` file](https://github.com/kong-partner-solutions/nvidia-switchyard-plugin/blob/main/kong-plugin/kong/plugins/ai-routing-provider/schema.lua) that defines the plugin’s configuration fields:
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
          { prompt_disclosure = {
              type    = "string",
              default = "none",
              one_of  = {
                "none", "latest_user_prompt", "recent_message_window", "full",
              },
              description = "Scope of prompt content disclosed to Switchyard ('none', 'latest_user_prompt', 'recent_message_window', 'full').",
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

          -- Derive session_id from a hash of the first user message when no
          -- X-Session-Id header is present. Harbor cannot set headers, and the
          -- request_id fallback makes every request its own session.
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
}

-- Messages sent verbatim under recent_message_window. Not configurable: a wider
-- window is more prompt content leaving Kong, so it is a code change, not a
-- knob.
local RECENT_WINDOW = 4


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

  -- Find the index of the last message with role == "user".
  local last_user_idx = nil
  for i = total, 1, -1 do
    if type(messages[i]) == "table" and messages[i].role == "user" then
      last_user_idx = i
      break
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

      elseif disclosure == "recent_message_window" then
        keep = (i > total - RECENT_WINDOW)
      end
      -- disclosure == "none": keep stays false for every message

      if keep then
        table.insert(filtered, { role = msg.role, content = msg.content })
      else
        table.insert(filtered, { role = msg.role, content = redact(msg.content) })
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


-- Derives request_id and session_id from request context, with fallbacks.
--
-- request_id:
--   1. Inbound X-Switchyard-Request-Id header (caller-assigned)
--   2. Kong's request ID (generated by Kong core / correlation-id plugin)
--
-- session_id:
--   1. Inbound X-Switchyard-Session-Id header (explicit session)
--   2. If conf.session_from_prompt is true: hash of the first user prompt.
--      A multi-turn conversation that preserves message history produces the
--      same hash on every turn, giving the stage router the affinity it needs
--      even through callers like Harbor that cannot send custom headers.
--   3. Fallback: request_id. Every request is its own session; stage routing
--      collapses to turn 0, which is safe.
local function derive_ids(conf, body)
  local req_header = kong.request.get_header(HEADER_REQUEST_ID)
  local ses_header = kong.request.get_header(HEADER_SESSION_ID)

  local request_id = req_header or kong.request.get_header("Kong-Request-Id")
  if not request_id or request_id == "" then
    -- Last-ditch request ID so the decision service never sees an empty header.
    request_id = string.format("%08x%08x", math.random(0, 0x7fffffff), math.random(0, 0x7fffffff))
  end

  local session_id = ses_header
  if (not session_id or session_id == "") and conf.session_from_prompt and body then
    local prompt = first_user_prompt(body)
    if prompt and prompt ~= "" then
      session_id = "p-" .. hash_string(prompt)
    end
  end

  if not session_id or session_id == "" then
    session_id = request_id
  end

  return request_id, session_id
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
> **Note**: Data planes must be started with `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED` to accept
> streamed custom policies.
> This registers the policy type once per {{site.ai_gateway}}. You still need to configure and
> attach an instance of it, in the next section.

## Configure the policy

After registering the custom policy type, attach and configure it the same way as any
other {{site.ai_gateway}} Policy, referencing it by the `name` you registered above:

{% entity_example %}
type: policy
data:
  display_name: AI Routing Provider
  name: ai-routing-provider
  type: ai-routing-provider
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
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

Each `targets.*.model` must match the `name` or an alias of an
[AI Model](/ai-gateway/entities/ai-model/) entity already configured on this {{site.ai_gateway}}.
Start with `mode: observe_only` to see what the decision service would do without
changing behavior, then switch to `enforce`.


## Limitations

- **Routing quality depends on the Switchyard route type**, not on this Policy.
  A `random` route proves the mechanism but makes no claim about choosing well.
  Evaluating routing quality is separate work.
- **`/v1/decision` doesn't return the confidence or reason code.**
  A well-formed `selected.target` is the only validity signal available, so a route whose classifier failed still returns a usable decision that happens to be its default.
  Read the decision service's `/v1/stats` to tell routing from falling back.
- **Narrowing AI Model targets per request isn't possible.**
  Its `filters/acl` configuration is static.
  This Policy therefore dispatches by rewriting the model alias.
- **Streaming responses haven't been exercised.**
- **The decision call isn't retried.**
  It's advisory and fails open, so a retry would double the worst-case added latency during an outage without improving the outcome.
- **`dispatch: model_alias` and `dispatch: upstream` don't apply here.** They target
  [AI Proxy Advanced](/plugins/ai-proxy-advanced/) or a Service's upstream directly,
  neither of which this Policy runs alongside. Use `dispatch: konnect_model`.
