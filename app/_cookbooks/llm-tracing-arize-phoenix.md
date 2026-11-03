---
title: LLM tracing with Arize Phoenix
description: Export {{site.ai_gateway_name}} chat completions to Arize Phoenix over OTLP and fill Sessions, user, Input/Output, and Messages with AI Policies.
url: "/cookbooks/llm-tracing-arize-phoenix/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
canonical: true
works_on:
  - konnect
min_version:
  gateway: '3.14'
  ai-gateway: '2.0'
categories:
  - observability
  - llm
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - ai-model
  - ai-model-provider
  - key-auth
  - request-transformer-advanced
  - opentelemetry
  - post-function
requires_embeddings: false
providers:
  - openai

hint: "Requires an OpenAI API key and an Arize Phoenix instance the data plane can reach over HTTP."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped {{site.ai_gateway}} and local data plane.

        1. Create a new personal access token by opening the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. You reuse the same token later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script. The two `-e` flags pass tracing settings into the data plane container. The [OpenTelemetry](/ai-gateway/policies/opentelemetry/) Policy doesn't export traces unless you start the data plane with `KONG_TRACING_INSTRUMENTATIONS` enabled, and the default sampling rate (`0.01`) drops 99% of spans before the policy sees them:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='llm-tracing-arize-phoenix-recipe'
           curl -Ls https://get.konghq.com/ai | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_TRACING_INSTRUMENTATIONS=all \
               -e KONG_TRACING_SAMPLING_RATE=1.0
           ```

           The script provisions an {{site.ai_gateway}} named `llm-tracing-arize-phoenix-recipe`, a local data plane connected to it with tracing enabled, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: OpenAI
      content: |
        This tutorial uses OpenAI:

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key as an environment variable:

           ```sh
           export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
    - title: Arize Phoenix
      content: |
        [Arize Phoenix](https://arize.com/docs/phoenix) receives OpenTelemetry traces over OTLP/HTTP. Phoenix maps Kong's `gen_ai.*` attributes to an LLM span at ingest (model name, token counts). Sessions, the user column, spans-table Input/Output, and the Messages view need extra OpenInference keys that this recipe writes from AI Policies.

        The Kong data plane must reach Phoenix on the network. The control plane never sends traces.

        {% navtabs "Phoenix" %}
        {% navtab "Local Phoenix" %}
        1. Install and start Phoenix. A local `phoenix serve` listens on port `6006`.
        1. Export the OTLP/HTTP traces URL the data plane container can reach, and the Phoenix project name:

           ```bash
           export PHOENIX_OTLP_ENDPOINT='http://host.docker.internal:6006/v1/traces'
           export PHOENIX_PROJECT_NAME='kong-ai-gateway'
           ```

           `host.docker.internal` is the host machine from inside the local data plane container. Point at the Phoenix service name instead if Phoenix runs on the same Docker network.
        {% endnavtab %}
        {% navtab "Hosted Phoenix" %}
        1. Copy the OTLP/HTTP traces URL for your Phoenix deployment. Kong's OpenTelemetry Policy needs the full `/v1/traces` path, not the UI origin alone.
        1. If the instance requires authentication, copy an API key from Phoenix **Settings**.
        1. Export the endpoint, project name, and (when auth is on) the Authorization header:

           ```bash
           export PHOENIX_OTLP_ENDPOINT='https://YOUR_PHOENIX_HOST/v1/traces'
           export PHOENIX_PROJECT_NAME='kong-ai-gateway'
           export PHOENIX_AUTH_HEADER='Bearer YOUR_PHOENIX_API_KEY'
           ```

           A local `phoenix serve` doesn't need `PHOENIX_AUTH_HEADER`. Kong doesn't read `PHOENIX_API_KEY` from the environment unless you add it into the policy config.
        {% endnavtab %}
        {% endnavtabs %}
    - title: Python 3.11+
      icon_url: /assets/icons/python.svg
      content: |
        The demo script requires Python 3.11 or later. Set up an isolated environment:

        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        pip install 'openai>=1.0.0'
        ```

overview: |
  LLM applications that call providers through {{site.ai_gateway_name}} already sit on a hop that sees every chat completion. An AI Model writes OpenTelemetry GenAI attributes (`gen_ai.*`) on every request it proxies. The [OpenTelemetry](/ai-gateway/policies/opentelemetry/) Policy posts those spans to [Arize Phoenix](https://arize.com/docs/phoenix). Phoenix turns `gen_ai.*` into an LLM span at ingest.

  That export path proves a call happened. Phoenix Sessions, the user column, the spans-table Input/Output cells, and the LLM Messages view read OpenInference keys Kong leaves empty unless you set them on the span. This recipe adds a Key Auth AI Auth Strategy plus [Request Transformer Advanced](/ai-gateway/policies/request-transformer-advanced/) and [Post-Function](/ai-gateway/policies/post-function/) Policies so those screens fill without OpenInference instrumentation in the application.

  By the end, you'll have one AI Model (`/llm-tracing-arize-phoenix`) behind an AI Consumer API key. Each request produces a Kong root span (`CHAIN`) and an LLM child span in the Phoenix project named by `x-project-name`.
---

## The problem

Phoenix is built around OpenInference. Most Phoenix tutorials attach an SDK instrumentation library in the application (LangChain, the OpenAI Python SDK, and similar). That works when you own the client. It doesn't help when the only shared hop is the gateway, or when you want gateway-enforced identity on the trace.

- **Every chat completion crosses one shared hop, but capture is usually duplicated per service.** Duplicating capture in every microservice means another SDK, another exporter, and traces that disagree about who called the model.
- **`gen_ai.*` isn't the Phoenix UI contract.** OpenTelemetry GenAI attributes map to model name and token counts in Phoenix. Sessions, user, Input/Output in the spans table, and Messages look for OpenInference keys (`session.id`, `user.id`, `input.value`, `llm.input_messages.*`). Those keys stay empty unless something on the request path writes them.
- **Client headers aren't identity.** A caller can send `x-user-id: admin`. Phoenix `user.id` should come from an authenticated identity, not from a header the client chooses.
- **App-side OpenInference is still the right tool for agents and RAG.** Tool calls, retrievers, and evaluations live in application code. This recipe covers the gateway hop. It doesn't replace that instrumentation.

## The solution

Place {{site.ai_gateway_name}} between the client and the LLM. A Key Auth AI Auth Strategy authenticates each request and identifies the caller. An AI Model normalizes correlation headers and a matched AI Model Provider proxies the request, then AI Policies export the trace and stamp OpenInference attributes from Lua.

{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibility
    key: responsibility
rows:
  - component: Key Auth AI Auth Strategy
    responsibility: "Requires an AI Consumer API key. Phoenix `user.id` is the AI Consumer's identity, never the key."
  - component: Request Transformer Advanced Policy
    responsibility: Drops client `x-user-id`. If `x-correlation-id` is missing, copies `x-request-id` or `x-session-id` onto it.
  - component: AI Model and AI Model Provider
    responsibility: Match the request to `/llm-tracing-arize-phoenix`, inject the OpenAI credential, and record `gen_ai.*` on the proxied request.
  - component: OpenTelemetry Policy
    responsibility: Posts OTLP/HTTP to Phoenix from the data plane. `x-project-name` selects the Phoenix project.
  - component: Post-Function Policy
    responsibility: Writes `CHAIN`, `session.id`, `user.id`, `input.value` / `output.value`, and `llm.*_messages` on the LLM span.
  - component: Arize Phoenix
    responsibility: Maps `gen_ai.*` to an LLM span at ingest and renders OpenInference keys in the UI.
{% endtable %}

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant L as LLM provider
    participant P as Arize Phoenix

    C->>K: POST /llm-tracing-arize-phoenix (apikey, chat JSON)
    activate K
    K->>K: key-auth Auth Strategy (Consumer identity, else 401)
    K->>K: Request Transformer Advanced (drop x-user-id, set x-correlation-id)
    K->>K: AI Model and AI Model Provider (inject provider auth, gen_ai.*)
    K->>L: Chat completion
    activate L
    L-->>K: OpenAI-format response
    deactivate L
    K->>K: Post-Function (OpenInference attributes, span status)
    K->>P: OTLP/HTTP /v1/traces
    K-->>C: Chat response
    deactivate K
{% endmermaid %}
<!-- vale on -->

Every resource attaches directly to the {{site.ai_gateway}} the quickstart provisions. There is no separate Service or Route to configure, and the control plane never sends traces; only the data plane exports OTLP.

## How it works

A request flowing through Kong passes through authentication, header normalization, the AI Model's proxy step, and trace export, in that order.

1. The Key Auth AI Auth Strategy reads the `apikey` header and looks it up against the AI Consumer's credential. A missing or unknown key gets `401` before any upstream call, so `kong.client.get_consumer()` returns the AI Consumer for every request that reaches the policies below.
2. The Request Transformer Advanced Policy drops any client-supplied `x-user-id` header and, if the request has no `x-correlation-id`, copies `x-request-id` or `x-session-id` onto it. The policy runs before the Post-Function Policy reads the header, so the correlation id is stable.
3. The AI Model matches the request to `/llm-tracing-arize-phoenix` and its target, backed by the AI Model Provider, proxies the request to OpenAI and creates the LLM child span (`gen_ai.operation.name`, or a span name that starts with `chat `).
4. The Post-Function Policy runs after those steps. Its `access` phase enables request buffering and writes input attributes onto the spans; its `header_filter` phase sets span status from the HTTP status and writes output plus LLM message attributes once the upstream response is available.
5. The OpenTelemetry Policy exports whatever spans exist when the request finishes to Phoenix's OTLP/HTTP endpoint.

{:.info}
> **AI Policy ordering is unverified.** {{site.ai_gateway}} 2.0's AI Policy schema (`kongctl explain ai_gateway_policies --extended`) has no field equivalent to 1.0's `ordering.after.access`, so this recipe cannot declare that Post-Function must run after Request Transformer Advanced and the AI Model's own proxy step. Post-Function's underlying Kong plugin has the lowest built-in priority of any stock plugin, which should still put it last in practice, but this has not been confirmed against a live {{site.ai_gateway}}.

### Key Auth: AI Consumer identity as the Phoenix user

The Key Auth AI Auth Strategy authenticates the caller before any policy or proxy logic runs. Phoenix `user.id` is the AI Consumer's identity. The credential itself must not appear on a span.

#### Configuration details

```yaml
ai_gateway_auth_strategies:
  - ref: llm-tracing-arize-phoenix-auth
    type: key-auth
    display_name: "llm-tracing-arize-phoenix key auth"
    config:
      key_names:
        - apikey
        - x-api-key
      key_in_header: true
      key_in_query: false
      hide_credentials: true

ai_gateway_consumers:
  - ref: llm-tracing-arize-phoenix-consumer
    name: phoenix-client
    display_name: "Phoenix demo consumer"
    type: api-key
    credentials:
      - ref: llm-tracing-arize-phoenix-credential
        name: llm-tracing-arize-phoenix-credential
        display_name: "llm-tracing-arize-phoenix demo API key"
        type: api-key
        api_key: !secret {source: !env CONSUMER_API_KEY}
```
{:.no-copy-code}

- **`key_names`**. Headers the AI Auth Strategy reads. Clients send `apikey: <key>`. The OpenAI SDK puts the SDK key in `Authorization: Bearer`, which doesn't match a stored credential unless you copy it onto `apikey` with a [Pre-Function](/ai-gateway/policies/pre-function/) Policy.
- **`key_in_header` / `key_in_query`**. Restrict credentials to headers only. Query-string keys end up in access logs and browser history, so this recipe keeps `key_in_query: false` explicit.
- **`hide_credentials: true`**. Strips the key before the request reaches the LLM provider. Keep the key off the span as well.
- **AI Consumer `name`**. Post-Function reads `kong.client.get_consumer().username` and writes it to Phoenix `user.id`. This recipe sets the AI Consumer's `name` to `phoenix-client` so you can recognize the identity in the Phoenix UI.
- **`api_key` is write-only.** An AI Consumer credential's `api_key` field must be a `!secret` reference. Kong rejects a plain string here, even for a demo value like this recipe's. You export `CONSUMER_API_KEY` once in [Apply the Kong configuration](#apply-the-kong-configuration).

### Request Transformer Advanced: Session id without spoofed users

The [Request Transformer Advanced](/ai-gateway/policies/request-transformer-advanced/) Policy drops a client-supplied user header and gives Post-Function a stable correlation id to read.

#### Configuration details

```yaml
ai_gateway_policies:
  - ref: llm-tracing-arize-phoenix-header-normalize
    type: request-transformer-advanced
    display_name: "llm-tracing-arize-phoenix header normalize"
    config:
      remove:
        headers:
          - x-user-id
      add:
        headers:
          - 'x-correlation-id:$(headers["x-request-id"] or headers["x-session-id"] or "")'
```
{:.no-copy-code}

- **`remove.headers: x-user-id`**. Stops the client from choosing Phoenix `user.id`. The AI Consumer identity is what Post-Function uses instead.
- **`add.headers: x-correlation-id`**. If the client omits `x-correlation-id`, the policy copies `x-request-id` or `x-session-id` onto it. An empty expression leaves the header unset, and Post-Function falls back to `kong.request.get_id()`.

### AI Model and AI Model Provider: GenAI spans

The AI Model matches the request to this recipe's path and target, and its AI Model Provider injects the OpenAI credential and translates the request and response body. Kong records `gen_ai.*` attributes on this hop, which Phoenix maps to model name and token counts.

#### Configuration details

```yaml
ai_gateway_model_providers:
  - ref: llm-tracing-arize-phoenix-provider
    type: openai
    display_name: "llm-tracing-arize-phoenix"
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_TOKEN}

ai_gateway_models:
  - ref: llm-tracing-arize-phoenix-model
    type: model
    display_name: "llm-tracing-arize-phoenix"
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - llm-tracing-arize-phoenix-auth
    policies:
      - llm-tracing-arize-phoenix-header-normalize
      - llm-tracing-arize-phoenix-otel
      - llm-tracing-arize-phoenix-oi-span-attrs
    config:
      max_request_body_size: 10485760
      response_streaming: deny
      logging:
        payloads: true
      route:
        paths:
          - /llm-tracing-arize-phoenix
    targets:
      - name: !env CHAT_MODEL
        provider: llm-tracing-arize-phoenix-provider
        config:
          type: openai
```
{:.no-copy-code}

- **`formats: [{type: openai}]`**. Accepts an OpenAI-format chat-completion body. See the [AI Model entity reference](/ai-gateway/entities/ai-model/) for the full list of supported formats and providers.
- **`policies`**. References the three policies documented in this section, in the order this recipe expects them to run. See the policy-ordering note above.
- **`max_request_body_size`**. Set for the recipe's expected payload size. Raise it if you send large conversation contexts or file uploads through this Model.
- **`response_streaming: deny`**. Post-Function reads the complete response body in its `header_filter` phase to write `output.value` and `llm.output_messages.*`. A streamed response isn't available as a single buffered body, so this recipe requires full responses.
- **`logging.payloads`**. Kong logs request and response payloads on this Model. Phoenix Messages still comes from Post-Function, not from this flag.

Kong emits `gen_ai.*` span attributes on every AI Model request, following the [OpenTelemetry GenAI semantic conventions](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/):

{% table %}
columns:
  - title: Attribute
    key: attribute
  - title: Description
    key: description
rows:
  - attribute: "`gen_ai.provider.name`"
    description: Provider identifier (for example `openai`)
  - attribute: "`gen_ai.request.model`"
    description: Model name from the request
  - attribute: "`gen_ai.operation.name`"
    description: Operation type (`chat`, `embeddings`)
  - attribute: "`gen_ai.usage.input_tokens`"
    description: Input token count
  - attribute: "`gen_ai.usage.output_tokens`"
    description: Output token count
{% endtable %}

### OpenTelemetry: export to Phoenix

The [OpenTelemetry](/ai-gateway/policies/opentelemetry/) Policy runs on the data plane. Point `traces_endpoint` at Phoenix's OTLP/HTTP traces URL.

#### Configuration details

```yaml
ai_gateway_policies:
  - ref: llm-tracing-arize-phoenix-otel
    type: opentelemetry
    display_name: "llm-tracing-arize-phoenix OpenTelemetry export"
    config:
      traces_endpoint: !env PHOENIX_OTLP_ENDPOINT
      headers:
        x-project-name: !env PHOENIX_PROJECT_NAME
      resource_attributes:
        service.name: kong-gateway
      sampling_rate: 1
      propagation:
        default_format: w3c
        extract:
          - w3c
        inject:
          - w3c
```
{:.no-copy-code}

- **`traces_endpoint`**. Full OTLP/HTTP path, including `/v1/traces`. Phoenix's `x-project-name` header works on HTTP only, not gRPC.
- **`headers.x-project-name`**. Phoenix project. Traces land here even when `service.name` is set.
- **`sampling_rate: 1`**. Sample everything while you validate the recipe. Lower this in production. This policy setting only takes effect once the data plane records exportable spans at all, which requires the `KONG_TRACING_INSTRUMENTATIONS` and `KONG_TRACING_SAMPLING_RATE` data plane settings from the {{site.konnect_product_name}} prerequisite.
- **`propagation`**. W3C extract and inject keep an application `traceparent` when the request crosses Kong. App OpenInference spans can then parent the gateway hop.
- **Authentication.** If Phoenix requires an API key, add `Authorization: Bearer <key>` to `headers`. Reference it from an environment variable with `!env` (Policy config doesn't accept `!secret`). Do not commit the key.

### Post-Function: OpenInference attributes Phoenix renders

The [Post-Function](/ai-gateway/policies/post-function/) Policy runs Lua after Kong authenticates, normalizes, and proxies the request. It uses `kong.tracing.get_spans()` to stamp OpenInference keys.

Access phase:

- `kong.service.request.enable_buffering()` so the header filter phase can read the upstream body
- Root span: `openinference.span.kind=CHAIN`, `session.id`, `user.id`, `input.value` (JSON)
- LLM span: `input.value` plus `llm.input_messages.{i}.message.role` / `.content` from `messages[]` (string `content` only)

Header filter phase:

- Span status **OK** (1) when HTTP status is below 400, **ERROR** (2) otherwise, only if status is still unset
- Root and LLM: `output.value`
- LLM: `llm.output_messages.*` from `choices[].message`

{:.info}
> Phoenix Messages doesn't parse `input.value`. The blob is what the table and the Raw toggle display.

#### Configuration details

The Lua is long. Expand the block to copy the full policy.

```yaml
ai_gateway_policies:
  - ref: llm-tracing-arize-phoenix-oi-span-attrs
    type: post-function
    display_name: "llm-tracing-arize-phoenix OpenInference span attributes"
    config:
      access:
        - |
          kong.service.request.enable_buffering()
          local cjson = require("cjson.safe")
          local function nonempty(v)
            return type(v) == "string" and v ~= ""
          end
          local function is_llm(span)
            local attrs = span.attributes
            return (attrs and attrs["gen_ai.operation.name"])
              or (type(span.name) == "string" and span.name:find("^chat ", 1, false))
          end
          local corr = kong.request.get_header("x-correlation-id")
          if not nonempty(corr) then
            corr = kong.request.get_id()
          end
          local consumer = kong.client.get_consumer()
          local user = consumer and consumer.username
          local input = kong.request.get_raw_body()
          if type(input) ~= "string" or input == "" then
            input = nil
          elseif #input > 65536 then
            input = input:sub(1, 65536)
          end
          local parsed = input and cjson.decode(input)
          local function set_json(span, prefix, value)
            span:set_attribute(prefix .. ".value", value)
            span:set_attribute(prefix .. ".mime_type", "application/json")
          end
          local spans = kong.tracing.get_spans()
          local n = spans and spans[0] or 0
          for i = 1, n do
            local span = spans[i]
            if span and i == 1 then
              span:set_attribute("openinference.span.kind", "CHAIN")
              if nonempty(corr) then
                span:set_attribute("session.id", corr)
              end
              if nonempty(user) then
                span:set_attribute("user.id", user)
              end
              if input then
                set_json(span, "input", input)
              end
            elseif span and is_llm(span) and input then
              set_json(span, "input", input)
              -- string content only; content[] parts need a walk
              if type(parsed) == "table" and type(parsed.messages) == "table" then
                for j, msg in ipairs(parsed.messages) do
                  if type(msg) == "table" then
                    local idx = j - 1
                    if nonempty(msg.role) then
                      span:set_attribute("llm.input_messages." .. idx .. ".message.role", msg.role)
                    end
                    if nonempty(msg.content) then
                      span:set_attribute("llm.input_messages." .. idx .. ".message.content", msg.content)
                    end
                  end
                end
              end
            end
          end
      header_filter:
        - |
          local cjson = require("cjson.safe")
          local function nonempty(v)
            return type(v) == "string" and v ~= ""
          end
          local function is_llm(span)
            local attrs = span.attributes
            return (attrs and attrs["gen_ai.operation.name"])
              or (type(span.name) == "string" and span.name:find("^chat ", 1, false))
          end
          local http_status = kong.response.get_status() or 0
          local otel_status = http_status >= 400 and 2 or 1
          local spans = kong.tracing.get_spans()
          local n = spans and spans[0] or 0
          for i = 1, n do
            local span = spans[i]
            if span and (span.status or 0) == 0 then
              span:set_status(otel_status)
            end
          end
          local ok, body = pcall(kong.service.response.get_raw_body)
          if not ok or type(body) ~= "string" or body == "" then
            return
          end
          if #body > 65536 then
            body = body:sub(1, 65536)
          end
          local parsed = cjson.decode(body)
          for i = 1, n do
            local span = spans[i]
            if span and (i == 1 or is_llm(span)) then
              span:set_attribute("output.value", body)
              span:set_attribute("output.mime_type", "application/json")
            end
            if span and is_llm(span) and type(parsed) == "table" and type(parsed.choices) == "table" then
              for j, choice in ipairs(parsed.choices) do
                local msg = type(choice) == "table" and choice.message
                if type(msg) == "table" then
                  local idx = j - 1
                  if nonempty(msg.role) then
                    span:set_attribute("llm.output_messages." .. idx .. ".message.role", msg.role)
                  end
                  if nonempty(msg.content) then
                    span:set_attribute("llm.output_messages." .. idx .. ".message.content", msg.content)
                  end
                end
              end
            end
          end
```
{:.collapsible}

Post-Function executes arbitrary Lua. If your organization disables serverless plugins, set [`untrusted_lua`](/gateway/configuration/#untrusted-lua) accordingly. Do not run Lua that nobody has reviewed on a shared {{site.ai_gateway}}.

{:.info}
> In production, store the OpenAI token and any Phoenix API key in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. Payload attributes on spans may contain prompts. Review retention before you capture payloads in production.

## Apply the Kong configuration

The following configuration creates an AI Model Provider holding your OpenAI credentials, a Key Auth AI Auth Strategy and an AI Consumer with a demo API key, three AI Policies (Request Transformer Advanced, OpenTelemetry, Post-Function), and an AI Model that routes to the AI Model Provider with all three policies attached. A kongctl namespace scopes every resource, so you can tear down the recipe cleanly without affecting other configurations on the same {{site.ai_gateway}}.

First, adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply command can manage it.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the {{site.ai_gateway}}.

Export the demo AI Consumer's API key. The AI Consumer credential's `api_key` field is write-only and must come from an env var, even for this fixed demo value:

```bash
export CONSUMER_API_KEY='demo-api-key'
```

Export the chat model:

```bash
export CHAT_MODEL='gpt-4o-mini'  # or gpt-4o, o3
```

You already exported `OPENAI_TOKEN` in the OpenAI prerequisite and `KONNECT_CONTROL_PLANE_NAME` in the {{site.konnect_product_name}} prerequisite, so you don't need to export them again. If you exported `PHOENIX_AUTH_HEADER`, add it under the OpenTelemetry Policy's `headers.Authorization` in the following apply command before you run it.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: llm-tracing-arize-phoenix-recipe
ai_gateway_model_providers:
- ref: llm-tracing-arize-phoenix-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-tracing-arize-phoenix-provider
  display_name: llm-tracing-arize-phoenix
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'OPENAI_TOKEN'}
ai_gateway_auth_strategies:
- ref: llm-tracing-arize-phoenix-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-tracing-arize-phoenix-auth
  display_name: llm-tracing-arize-phoenix key auth
  type: key-auth
  config:
    key_names:
    - apikey
    - x-api-key
    key_in_header: true
    key_in_query: false
    hide_credentials: true
ai_gateway_consumers:
- ref: llm-tracing-arize-phoenix-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: phoenix-client
  display_name: Phoenix demo consumer
  type: api-key
  credentials:
  - ref: llm-tracing-arize-phoenix-credential
    name: llm-tracing-arize-phoenix-credential
    display_name: llm-tracing-arize-phoenix demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_policies:
- ref: llm-tracing-arize-phoenix-header-normalize
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-tracing-arize-phoenix-header-normalize
  display_name: llm-tracing-arize-phoenix header normalize
  type: request-transformer-advanced
  config:
    remove:
      headers:
      - x-user-id
    add:
      headers:
      - x-correlation-id:$(headers["x-request-id"] or headers["x-session-id"] or "")
- ref: llm-tracing-arize-phoenix-otel
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-tracing-arize-phoenix-otel
  display_name: llm-tracing-arize-phoenix OpenTelemetry export
  type: opentelemetry
  config:
    traces_endpoint: !env 'PHOENIX_OTLP_ENDPOINT'
    headers:
      x-project-name: !env 'PHOENIX_PROJECT_NAME'
    resource_attributes:
      service.name: kong-gateway
    sampling_rate: 1
    propagation:
      default_format: w3c
      extract:
      - w3c
      inject:
      - w3c
- ref: llm-tracing-arize-phoenix-oi-span-attrs
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-tracing-arize-phoenix-oi-span-attrs
  display_name: llm-tracing-arize-phoenix OpenInference span attributes
  type: post-function
  config:
    access:
    - |
      kong.service.request.enable_buffering()
      local cjson = require("cjson.safe")
      local function nonempty(v)
        return type(v) == "string" and v ~= ""
      end
      local function is_llm(span)
        local attrs = span.attributes
        return (attrs and attrs["gen_ai.operation.name"])
          or (type(span.name) == "string" and span.name:find("^chat ", 1, false))
      end
      local corr = kong.request.get_header("x-correlation-id")
      if not nonempty(corr) then
        corr = kong.request.get_id()
      end
      local consumer = kong.client.get_consumer()
      local user = consumer and consumer.username
      local input = kong.request.get_raw_body()
      if type(input) ~= "string" or input == "" then
        input = nil
      elseif #input > 65536 then
        input = input:sub(1, 65536)
      end
      local parsed = input and cjson.decode(input)
      local function set_json(span, prefix, value)
        span:set_attribute(prefix .. ".value", value)
        span:set_attribute(prefix .. ".mime_type", "application/json")
      end
      local spans = kong.tracing.get_spans()
      local n = spans and spans[0] or 0
      for i = 1, n do
        local span = spans[i]
        if span and i == 1 then
          span:set_attribute("openinference.span.kind", "CHAIN")
          if nonempty(corr) then
            span:set_attribute("session.id", corr)
          end
          if nonempty(user) then
            span:set_attribute("user.id", user)
          end
          if input then
            set_json(span, "input", input)
          end
        elseif span and is_llm(span) and input then
          set_json(span, "input", input)
          -- string content only; content[] parts need a walk
          if type(parsed) == "table" and type(parsed.messages) == "table" then
            for j, msg in ipairs(parsed.messages) do
              if type(msg) == "table" then
                local idx = j - 1
                if nonempty(msg.role) then
                  span:set_attribute("llm.input_messages." .. idx .. ".message.role", msg.role)
                end
                if nonempty(msg.content) then
                  span:set_attribute("llm.input_messages." .. idx .. ".message.content", msg.content)
                end
              end
            end
          end
        end
      end
    header_filter:
    - |
      local cjson = require("cjson.safe")
      local function nonempty(v)
        return type(v) == "string" and v ~= ""
      end
      local function is_llm(span)
        local attrs = span.attributes
        return (attrs and attrs["gen_ai.operation.name"])
          or (type(span.name) == "string" and span.name:find("^chat ", 1, false))
      end
      local http_status = kong.response.get_status() or 0
      local otel_status = http_status >= 400 and 2 or 1
      local spans = kong.tracing.get_spans()
      local n = spans and spans[0] or 0
      for i = 1, n do
        local span = spans[i]
        if span and (span.status or 0) == 0 then
          span:set_status(otel_status)
        end
      end
      local ok, body = pcall(kong.service.response.get_raw_body)
      if not ok or type(body) ~= "string" or body == "" then
        return
      end
      if #body > 65536 then
        body = body:sub(1, 65536)
      end
      local parsed = cjson.decode(body)
      for i = 1, n do
        local span = spans[i]
        if span and (i == 1 or is_llm(span)) then
          span:set_attribute("output.value", body)
          span:set_attribute("output.mime_type", "application/json")
        end
        if span and is_llm(span) and type(parsed) == "table" and type(parsed.choices) == "table" then
          for j, choice in ipairs(parsed.choices) do
            local msg = type(choice) == "table" and choice.message
            if type(msg) == "table" then
              local idx = j - 1
              if nonempty(msg.role) then
                span:set_attribute("llm.output_messages." .. idx .. ".message.role", msg.role)
              end
              if nonempty(msg.content) then
                span:set_attribute("llm.output_messages." .. idx .. ".message.content", msg.content)
              end
            end
          end
        end
      end
ai_gateway_models:
- ref: llm-tracing-arize-phoenix-model
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-tracing-arize-phoenix-model
  display_name: llm-tracing-arize-phoenix
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - llm-tracing-arize-phoenix-auth
  policies:
  - llm-tracing-arize-phoenix-header-normalize
  - llm-tracing-arize-phoenix-otel
  - llm-tracing-arize-phoenix-oi-span-attrs
  config:
    max_request_body_size: 10485760
    response_streaming: deny
    logging:
      payloads: true
    route:
      paths:
      - /llm-tracing-arize-phoenix
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: !env 'CHAT_MODEL'
    provider: llm-tracing-arize-phoenix-provider
    config:
      type: openai
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

## Try it out

`demo.py` sends a chat completion with an invalid key (expecting `401`), a request with a spoofed `x-user-id` header (expecting Kong to drop it), and three chat turns split across two Phoenix Sessions using `x-correlation-id`. Tracing doesn't change any HTTP response, so the script can't confirm what Phoenix rendered. Open Phoenix after the run to see the traces.

{:.info}
> The demo passes the API key via `default_headers` because the OpenAI SDK reserves `api_key` for the `Authorization: Bearer` header. To let clients pass the key through `api_key` directly, attach a [Pre-Function](/ai-gateway/policies/pre-function/) Policy that copies the Bearer token to the `apikey` header server-side.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""LLM tracing with Arize Phoenix demo. See README for context.

Sends chat completions through Kong AI Gateway's `/llm-tracing-arize-phoenix`
Model and prints what each request proves about the tracing setup:

  - An invalid `apikey` is rejected with 401 before any provider call (key-auth).
  - Two turns share one `x-correlation-id` so they land in the same Phoenix
    Session; a third omits the header so Kong falls back to the request id
    (Request Transformer Advanced + the Post-Function Session read).
  - A client-supplied `x-user-id` is dropped; the Consumer identity
    (`phoenix-client`) is what Phoenix shows as `user.id`.
  - Token usage and the resolved model come back as Kong response headers
    (`x-kong-llm-model`, `x-kong-llm-tokens-*`), the same numbers the
    `gen_ai.*` span attributes carry into Phoenix.

This script cannot confirm what Phoenix rendered. Post-Function writes
OpenInference attributes onto Kong's spans; whether Sessions, the user
column, Input/Output, and Messages populated correctly is only visible in
the Phoenix UI. Run `python demo.py`, then open the project named by
`PHOENIX_PROJECT_NAME` in Phoenix and confirm what the printed Session
ID and turns look like there.

Requires: `pip install -r requirements.txt`. Expects `PROXY_URL` (default
`http://localhost:8000`) and `CHAT_MODEL` (default `gpt-4o-mini`) as needed.
"""

import os
import sys
import time
import uuid

from openai import APIStatusError, OpenAI

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
CHAT_MODEL = os.getenv("CHAT_MODEL", "gpt-4o-mini")
# Matches the Consumer credential's CONSUMER_API_KEY value from the Apply section.
PHOENIX_API_KEY = os.getenv("PHOENIX_API_KEY", "demo-api-key")
PHOENIX_PROJECT_NAME = os.getenv("PHOENIX_PROJECT_NAME", "kong-ai-gateway")
SESSION_ID = os.getenv("SESSION_ID", f"phoenix-demo-{uuid.uuid4().hex[:12]}")

# ANSI color codes. Disabled when stdout isn't a TTY or NO_COLOR is set.
_USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ
def _c(code: str, s: str) -> str:
    return f"\033[{code}m{s}\033[0m" if _USE_COLOR else s
BOLD = lambda s: _c("1", s)
DIM = lambda s: _c("2", s)
GREEN = lambda s: _c("32", s)
BLUE = lambda s: _c("34", s)
CYAN = lambda s: _c("36", s)
RED = lambda s: _c("31", s)
MAGENTA = lambda s: _c("35", s)


# ---------------------------------------------------------------------------
# Kong-pointed client (key-auth via apikey header in default_headers)
# ---------------------------------------------------------------------------
#
# The OpenAI SDK reserves api_key for the Authorization: Bearer header. Kong
# reads the recipe's key-auth credential from the apikey header instead, so
# it's passed through default_headers. x-correlation-id is set per call
# below so each turn can vary it.

def make_client(correlation_id=None, api_key=PHOENIX_API_KEY):
    headers = {"apikey": api_key}
    if correlation_id is not None:
        headers["x-correlation-id"] = correlation_id
    return OpenAI(
        base_url=f"{PROXY_URL}/llm-tracing-arize-phoenix",
        api_key="placeholder",
        default_headers=headers,
    )


# ---------------------------------------------------------------------------
# Negative path: invalid key-auth credential
# ---------------------------------------------------------------------------

def check_auth_boundary():
    """Send a request with an invalid key, expecting Kong to return 401.

    Confirms key-auth is enforced before any upstream call, so an
    unauthenticated caller never reaches OpenAI or produces a trace.
    """
    bad_client = make_client(api_key="not-a-real-key")
    print(f"  Attempting apikey={RED('not-a-real-key')!r}")
    try:
        bad_client.chat.completions.create(
            model=CHAT_MODEL,
            messages=[{"role": "user", "content": "ping"}],
        )
    except APIStatusError as exc:
        print(f"  {GREEN(BOLD('[BLOCKED]'))} {RED(BOLD(str(exc.status_code)))} {exc.message[:80]}")
        return exc.status_code
    print(f"  {RED(BOLD('[AUTH]'))} unexpected: invalid key was accepted")
    return None


# ---------------------------------------------------------------------------
# Client-supplied identity is dropped
# ---------------------------------------------------------------------------

def send_spoofed_user_header():
    """Send a request with a client-chosen x-user-id header.

    Request Transformer Advanced removes x-user-id before the request
    reaches the AI Model or Post-Function, so this value never becomes
    Phoenix's user.id. The Consumer identity (phoenix-client) does.
    """
    client = make_client(correlation_id=SESSION_ID)
    completion = client.chat.completions.with_raw_response.create(
        model=CHAT_MODEL,
        messages=[{"role": "user", "content": "Who am I talking to?"}],
        extra_headers={"x-user-id": "admin"},
    )
    parsed = completion.parse()
    print(f"  Sent header {DIM('x-user-id: admin')} (client-supplied, dropped by Kong)")
    print(f"  {CYAN(BOLD('[LLM]'))} \"{parsed.choices[0].message.content}\"")
    print(f"  {DIM('Phoenix user.id will read the Consumer identity instead: ')}{BLUE(BOLD('phoenix-client'))}")


# ---------------------------------------------------------------------------
# Session grouping via x-correlation-id
# ---------------------------------------------------------------------------

def chat_turn(client, message, label):
    start = time.perf_counter()
    raw = client.chat.completions.with_raw_response.create(
        model=CHAT_MODEL,
        messages=[{"role": "user", "content": message}],
    )
    elapsed = time.perf_counter() - start
    completion = raw.parse()

    reply = completion.choices[0].message.content
    usage = completion.usage
    kong_model = raw.headers.get("x-kong-llm-model", CHAT_MODEL)

    print(f"\n{BOLD(label)}")
    print(f"  {CYAN(BOLD('[LLM]'))} \"{reply}\"")
    stats = (
        f"Model: {kong_model}  "
        f"Tokens: {usage.prompt_tokens} in / {usage.completion_tokens} out  "
        f"({elapsed:.3f}s)"
    )
    print(f"         {DIM(stats)}")


def run_session_grouping_demo():
    """Two turns share SESSION_ID; a third omits x-correlation-id entirely.

    The first two land in the same Phoenix Session. The third has no
    x-correlation-id, so Post-Function falls back to
    kong.request.get_id() and appears as its own Session.
    """
    session_client = make_client(correlation_id=SESSION_ID)
    chat_turn(session_client, "What is Kong AI Gateway?", "Turn 1 (session: " + SESSION_ID + ")")
    chat_turn(session_client, "Summarize that in five words.", "Turn 2 (session: " + SESSION_ID + ")")

    no_session_client = make_client(correlation_id=None)
    chat_turn(no_session_client, "What is Arize Phoenix?", "Turn 3 (no x-correlation-id -> falls back to request id)")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print(BOLD("LLM Tracing with Arize Phoenix Demo"))
    print("=" * 60)
    print(f"Kong Proxy:   {PROXY_URL}")
    print(f"Chat Model:   {CYAN(BOLD(CHAT_MODEL))}")
    print(f"Session ID:   {BLUE(BOLD(SESSION_ID))}")

    print(f"\n{DIM('Checking key-auth boundary...')}")
    check_auth_boundary()

    print(f"\n{DIM('Checking that a client-supplied x-user-id is dropped...')}")
    send_spoofed_user_header()

    print(f"\n{DIM('Running session-grouping turns...')}")
    run_session_grouping_demo()

    print()
    print("=" * 60)
    print(f"{BOLD('Done.')} Open Phoenix -> project {MAGENTA(BOLD(PHOENIX_PROJECT_NAME))} -> Sessions -> {BLUE(BOLD(SESSION_ID))}")
    print("Confirm: user column reads 'phoenix-client', Input/Output are populated,")
    print("and the LLM span's Messages view shows role/content bubbles for each turn.")
    sys.exit(0)
EOF
```
{:.collapsible}

Run it:

```bash
python demo.py
```

Example output:

```text
LLM Tracing with Arize Phoenix Demo
============================================================
Kong Proxy:   http://localhost:8000
Chat Model:   gpt-4o-mini
Session ID:   phoenix-demo-a1b2c3d4e5f6

Checking key-auth boundary...
  Attempting apikey='not-a-real-key'
  [BLOCKED] 401 Unauthorized

Checking that a client-supplied x-user-id is dropped...
  Sent header x-user-id: admin (client-supplied, dropped by Kong)
  [LLM] "I don't have information identifying who you are..."
  Phoenix user.id will read the Consumer identity instead: phoenix-client

Running session-grouping turns...

Turn 1 (session: phoenix-demo-a1b2c3d4e5f6)
  [LLM] "Kong AI Gateway is a layer that manages, secures, and observes traffic to LLM providers."
         Model: gpt-4o-mini  Tokens: 14 in / 19 out  (0.812s)

Turn 2 (session: phoenix-demo-a1b2c3d4e5f6)
  [LLM] "A managed proxy for LLM traffic."
         Model: gpt-4o-mini  Tokens: 38 in / 8 out  (0.431s)

Turn 3 (no x-correlation-id -> falls back to request id)
  [LLM] "Arize Phoenix is an open-source LLM observability and evaluation platform."
         Model: gpt-4o-mini  Tokens: 13 in / 15 out  (0.734s)

============================================================
Done. Open Phoenix -> project kong-ai-gateway -> Sessions -> phoenix-demo-a1b2c3d4e5f6
Confirm: user column reads 'phoenix-client', Input/Output are populated,
and the LLM span's Messages view shows role/content bubbles for each turn.
```
{:.no-copy-code}

### What happened

1. The first call sent `apikey: not-a-real-key`. The Key Auth AI Auth Strategy rejected it with `401` before the request reached the AI Model or OpenAI, so Kong never created a span for it.
2. The second call sent `x-user-id: admin` alongside a valid key. Request Transformer Advanced dropped that header before Post-Function ran, so the root span's `user.id` reads the AI Consumer identity `phoenix-client`, not the client-supplied value.
3. The next two calls reused `SESSION_ID` as `x-correlation-id`. Post-Function reads that header into `session.id` on the root span, so both turns group into one Phoenix Session.
4. The final call omitted `x-correlation-id`. Post-Function fell back to `kong.request.get_id()`, so this turn lands in its own Session.
5. Every call's response headers carried `x-kong-llm-model` and the OpenAI SDK's `usage` object carried token counts. Those same numbers are what `gen_ai.usage.*` attributes carry into the Phoenix LLM span.

A request/response pair looks like this over the wire:

```json
{
  "model": "gpt-4o-mini",
  "messages": [{"role": "user", "content": "What is Kong AI Gateway?"}]
}
```
{:.no-copy-code}

```json
{
  "id": "chatcmpl-...",
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "Kong AI Gateway is a layer that manages, secures, and observes traffic to LLM providers."
      }
    }
  ],
  "usage": {"prompt_tokens": 14, "completion_tokens": 19, "total_tokens": 33}
}
```
{:.no-copy-code}

Post-Function writes the request body verbatim onto `input.value` and the response body onto `output.value`, and walks `messages[]` / `choices[].message` into the `llm.input_messages.*` / `llm.output_messages.*` keys Phoenix Messages reads.

### Verify in Phoenix

Open the project named in `PHOENIX_PROJECT_NAME` (default `kong-ai-gateway`).

You should see:

- A Kong root span with kind **CHAIN**, user `phoenix-client`, two Sessions (one grouping turns 1 and 2, one holding turn 3 alone), and JSON Input/Output on the spans table
- An LLM child span for the AI Model hop, with model and token counts from `gen_ai.*`
- Messages on the LLM span (role and content bubbles), not only a Raw JSON blob
- Span status **OK** for HTTP 200, and **ERROR** on the auth-rejected call if it ever produced a span

If the root row shows `--` for Input/Output, the listed span is missing `input.value` / `output.value`. Confirm Post-Function is attached after the header-normalize policy and that request buffering is enabled.

If Messages is empty, confirm you opened the LLM span, not the CHAIN root. CHAIN ignores `llm.input_messages.*`.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `llm-tracing-arize-phoenix-recipe`. The recipe created an AI Model Provider holding your OpenAI credentials, an AI Model (`llm-tracing-arize-phoenix-model`) with the Request Transformer Advanced, OpenTelemetry, and Post-Function Policies attached, a Key Auth AI Auth Strategy, and an AI Consumer (`phoenix-client`) with a demo API key credential, all scoped to this recipe by the kongctl namespace applied above.

For platform-wide traffic analysis across every {{site.ai_gateway}}, open the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

**Swap the OTLP backend.** The same policies export to any OTLP/HTTP collector. Phoenix-specific behavior is the `x-project-name` header and OpenInference keys this recipe writes. Langfuse, Jaeger, and Grafana Tempo store the spans but don't render Phoenix Sessions or Messages.

**Switch to OpenID Connect for production identity.** When the platform integrates a real IdP, swap the Key Auth AI Auth Strategy for `openid-connect` and let JWT claims map users to AI Consumers. The rest of the recipe (policies, AI Model, correlation headers) stays put. See the [Claude Code SSO recipe](/cookbooks/claude-code-sso/) for an end-to-end example with Okta.

**Combine app OpenInference with the gateway span.** Leave W3C extract and inject on. The application opens the parent span and sends `traceparent`. Kong's LLM hop nests under that trace in Phoenix. Agent graphs and RAG still need SDK instrumentation in the app.

**Add per-consumer rate limits.** With Key Auth mapping requests to AI Consumers, attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to apply token quotas per AI Consumer. See the [LLM cost optimization recipe](/cookbooks/llm-cost-optimization/) for a worked example.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='llm-tracing-arize-phoenix-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
