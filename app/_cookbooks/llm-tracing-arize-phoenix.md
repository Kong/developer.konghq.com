---
title: LLM tracing with Arize Phoenix
description: Export {{site.ai_gateway_name}} chat completions to Arize Phoenix over OTLP and fill Sessions, user, Input/Output, and Messages with Gateway plugins.
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
categories:
  - observability
  - llm
featured: false
popular: false

plugins:
  - ai-proxy-advanced
  - opentelemetry
  - key-auth
  - request-transformer-advanced
  - post-function
requires_embeddings: false
providers:
  - openai

hint: "Requires an OpenAI API key and an Arize Phoenix instance the Data Plane can reach over HTTP."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: Kong Konnect
      content: |
        This tutorial uses {{site.konnect_product_name}}. The [quickstart script](https://get.konghq.com/quickstart) provisions a recipe-scoped Control Plane and local Data Plane.

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped Control Plane name and run the quickstart script. The two `-e` flags pass tracing settings into the Data Plane container. The [OpenTelemetry](/plugins/opentelemetry/) plugin does not export traces unless the Data Plane is started with `KONG_TRACING_INSTRUMENTATIONS` enabled, and the default sampling rate (`0.01`) drops 99% of spans before the plugin sees them:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='llm-tracing-arize-phoenix-recipe'
           curl -Ls https://get.konghq.com/quickstart | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_TRACING_INSTRUMENTATIONS=all \
               -e KONG_TRACING_SAMPLING_RATE=1.0 \
               --deck-output
           ```

           This provisions a Konnect Control Plane named `llm-tracing-arize-phoenix-recipe`, a local Data Plane connected to it with tracing enabled, and prints `export` lines for the rest of the session vars. Paste those into your shell when prompted.
    - title: kongctl + decK
      content: |
        This tutorial uses [kongctl](/kongctl/) and [decK](/deck/) to manage Kong configuration.

        1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
        1. Install **decK** version 1.43 or later from [docs.konghq.com/deck](https://docs.konghq.com/deck/).
        1. Verify both are installed:

           ```bash
           kongctl version
           deck version
           ```
    - title: OpenAI
      content: |
        This tutorial uses OpenAI:

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the key in the form Kong injects upstream:

           ```bash
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
    - title: Arize Phoenix
      content: |
        [Arize Phoenix](https://arize.com/docs/phoenix) receives OpenTelemetry traces over OTLP/HTTP. Phoenix maps Kong's `gen_ai.*` attributes to an LLM span at ingest (model name, token counts). Sessions, the user column, spans-table Input/Output, and the Messages view need extra OpenInference keys that this recipe writes from Gateway plugins.

        The Kong Data Plane must reach Phoenix on the network. The Control Plane never sends traces.

        {% navtabs "Phoenix" %}
        {% navtab "Local Phoenix" %}
        1. Install and start Phoenix. A local `phoenix serve` listens on port `6006`.
        1. Export the OTLP/HTTP traces URL the Data Plane container can reach, and the Phoenix project name:

           ```bash
           export DECK_PHOENIX_OTLP_ENDPOINT='http://host.docker.internal:6006/v1/traces'
           export DECK_PHOENIX_PROJECT_NAME='kong-ai-gateway'
           ```

           `host.docker.internal` is the host machine from inside the local Data Plane container. Point at the Phoenix service name instead if Phoenix runs on the same Docker network.
        {% endnavtab %}
        {% navtab "Hosted Phoenix" %}
        1. Copy the OTLP/HTTP traces URL for your Phoenix deployment. Kong's OpenTelemetry plugin needs the full `/v1/traces` path, not the UI origin alone.
        1. If the instance requires authentication, copy an API key from Phoenix **Settings**.
        1. Export the endpoint, project name, and (when auth is on) the Authorization header:

           ```bash
           export DECK_PHOENIX_OTLP_ENDPOINT='https://YOUR_PHOENIX_HOST/v1/traces'
           export DECK_PHOENIX_PROJECT_NAME='kong-ai-gateway'
           export DECK_PHOENIX_AUTH_HEADER='Bearer YOUR_PHOENIX_API_KEY'
           ```

           A local `phoenix serve` does not need `DECK_PHOENIX_AUTH_HEADER`. Kong does not read `PHOENIX_API_KEY` from the environment unless you template it into the plugin config.
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
  LLM applications that call providers through {{site.ai_gateway_name}} already sit on a hop that sees every chat completion. [AI Proxy Advanced](/plugins/ai-proxy-advanced/) writes OpenTelemetry GenAI attributes (`gen_ai.*`). The [OpenTelemetry](/plugins/opentelemetry/) plugin posts those spans to [Arize Phoenix](https://arize.com/docs/phoenix). Phoenix turns `gen_ai.*` into an LLM span at ingest.

  That export path proves a call happened. Phoenix Sessions, the user column, the spans-table Input/Output cells, and the LLM Messages view read OpenInference keys Kong leaves empty unless you set them on the span. This recipe adds [Key Auth](/plugins/key-auth/), [Request Transformer Advanced](/plugins/request-transformer-advanced/), and [Post-Function](/plugins/post-function/) so those screens fill without OpenInference instrumentation in the application.

  By the end, you will have one chat Route (`/llm-tracing-arize-phoenix`) behind a Consumer API key. Each request produces a Kong root span (`CHAIN`) and an LLM child span in the Phoenix project named by `x-project-name`.

faqs:
  - q: Why does Phoenix show a chat call but leave Messages empty?
    a: Phoenix Messages does not parse `input.value`. Role and content bubbles come from `llm.input_messages.{i}.message.role` / `.content` and the matching `llm.output_messages` keys, and only on a span whose kind is LLM. AI Proxy writes `gen_ai.*`. The Post-Function in this recipe writes the OpenInference message keys.
  - q: Can I use AI Proxy instead of AI Proxy Advanced?
    a: Yes, for a single upstream target. Keep `log_payloads` on if you want Kong to record request and response bodies. Phoenix still needs the Post-Function for OpenInference message keys.
  - q: Do I have to use Request Transformer Advanced?
    a: No. That plugin is {{site.ee_product_name}}. The open-source Request Transformer plugin can add and remove the same headers. Update `ordering.after.access` on Post-Function to list `request-transformer` instead of `request-transformer-advanced`.
---

## The problem

Phoenix is built around OpenInference. Most Phoenix tutorials attach an SDK instrumentation library in the application (LangChain, the OpenAI Python SDK, and similar). That works when you own the client. It does not help when the only shared hop is the gateway, or when you want gateway-enforced identity on the trace.

- **Every chat completion crosses one shared hop, but capture is usually duplicated per service.** Duplicating capture in every microservice means another SDK, another exporter, and traces that disagree about who called the model.
- **`gen_ai.*` is not the Phoenix UI contract.** OpenTelemetry GenAI attributes map to model name and token counts in Phoenix. Sessions, user, Input/Output in the spans table, and Messages look for OpenInference keys (`session.id`, `user.id`, `input.value`, `llm.input_messages.*`). Those keys stay empty unless something on the request path writes them.
- **Client headers are not identity.** A caller can send `x-user-id: admin`. Phoenix `user.id` should come from an authenticated identity, not from a header the client chooses.
- **App-side OpenInference is still the right tool for agents and RAG.** Tool calls, retrievers, and evaluations live in application code. This recipe covers the gateway hop. It does not replace that instrumentation.

## The solution

Place {{site.ai_gateway_name}} between the client and the LLM. Authenticate with Key Auth, normalize correlation headers, proxy with AI Proxy Advanced, export with OpenTelemetry, then stamp OpenInference attributes from Post-Function Lua.

{% table %}
columns:
  - title: Component
    key: component
  - title: Role
    key: role
rows:
  - component: "`llm-tracing-arize-phoenix` Service"
    role: Chat completions Route at `/llm-tracing-arize-phoenix`
  - component: Key Auth plugin
    role: Requires a Consumer API key. Phoenix `user.id` is the Consumer username, never the key.
  - component: Request Transformer Advanced plugin
    role: Drops client `x-user-id`. If `x-correlation-id` is missing, copies `x-request-id` or `x-session-id` onto it.
  - component: AI Proxy Advanced plugin
    role: Injects the provider credential, records `gen_ai.*`, optional payload logging
  - component: OpenTelemetry plugin
    role: Data Plane posts OTLP/HTTP to Phoenix. `x-project-name` selects the Phoenix project.
  - component: Post-Function plugin
    role: Writes `CHAIN`, `session.id`, `user.id`, `input.value` / `output.value`, and `llm.*_messages` on the LLM span
  - component: Arize Phoenix
    role: Maps `gen_ai.*` to an LLM span at ingest and renders OpenInference keys in the UI
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
    K->>K: key-auth (Consumer username, else 401)
    K->>K: request-transformer-advanced (drop x-user-id, set x-correlation-id)
    K->>K: ai-proxy-advanced (inject provider auth, gen_ai.*)
    K->>L: Chat completion
    activate L
    L-->>K: OpenAI-format response
    deactivate L
    K->>K: post-function (OpenInference attributes, span status)
    K->>P: OTLP/HTTP /v1/traces
    K-->>C: Chat response
    deactivate K
{% endmermaid %}
<!-- vale on -->

Declare Plugins on the **control plane** ({{site.konnect_product_name}}, or decK). The **data plane** exports OTLP. The control plane never sends traces.

## How it works

Plugin order matters.

1. **Key Auth** runs first so `kong.client.get_consumer()` is populated.
2. **Request Transformer Advanced** runs next so `x-correlation-id` is stable before Lua reads it.
3. **AI Proxy Advanced** creates the LLM child span (`gen_ai.operation.name` or a span name that starts with `chat `).
4. **Post-Function** runs after those three. Access enables request buffering and writes input attributes. Header filter sets span status from the HTTP status and writes output plus LLM messages.

The OpenTelemetry plugin can sit on the Route or globally. It exports whatever spans exist when the request finishes.

{% table %}
columns:
  - title: Kong plugin
    key: plugin
  - title: What you configure
    key: configure
  - title: What Phoenix shows
    key: phoenix
rows:
  - plugin: "[Key Auth](/plugins/key-auth/)"
    configure: Require a Consumer API key. Turn on `hide_credentials`.
    phoenix: After auth, copy the Consumer username onto `user.id`. That value is the **user** column and the session user. Never put the API key on a span.
  - plugin: "[Request Transformer Advanced](/plugins/request-transformer-advanced/)"
    configure: Drop client `x-user-id`. If `x-correlation-id` is missing, copy `x-request-id` or `x-session-id` onto it.
    phoenix: Post-Function reads that header into `session.id`. Phoenix **Sessions** groups traces that share the id. Identity stays on the Consumer.
  - plugin: "[Post-Function](/plugins/post-function/)"
    configure: Lua that calls `span:set_attribute` and `span:set_status` on Kong tracing spans.
    phoenix: "Root span: `openinference.span.kind=CHAIN`, `session.id`, `user.id`, chat JSON on `input.value` / `output.value`. LLM span: `llm.input_messages.*` / `llm.output_messages.*`. HTTP status below 400 sets span **OK**; 400 and above set **ERROR**."
{% endtable %}

### Key Auth: Consumer username as Phoenix user

The [Key Auth](/plugins/key-auth/) plugin authenticates the caller before any AI Proxy logic runs. Phoenix `user.id` is the Consumer **username**. The credential itself must not appear on a span.

#### Configuration details

```yaml
consumers:
  - username: phoenix-client
    keyauth_credentials:
      - key: phoenix-recipe-key
plugins:
  - name: key-auth
    config:
      key_names:
        - apikey
        - x-api-key
      key_in_header: true
      key_in_query: false
      hide_credentials: true
```
{:.no-copy-code}

- **`key_names`**. Headers the plugin reads. Clients send `apikey: phoenix-recipe-key`. The OpenAI SDK puts the SDK key in `Authorization: Bearer`. That value will not match a stored Key Auth credential unless you copy it onto `apikey` with [Pre-Function](/plugins/pre-function/). See [Authenticate OpenAI SDK clients with Key Auth](https://developer.konghq.com/how-to/authenticate-openai-sdk-clients-with-key-auth/).
- **`key_in_header` / `key_in_query`**. Restrict credentials to headers only. Query-string keys end up in access logs and browser history, so this recipe keeps `key_in_query: false` explicit.
- **`hide_credentials: true`**. Strips the key before the request reaches the LLM provider. Keep the key off the span as well.
- **`consumers[].username`**. This string is what Post-Function writes to `user.id`.

### Request Transformer Advanced: Session id without spoofed users

The [Request Transformer Advanced](/plugins/request-transformer-advanced/) plugin is {{site.ee_product_name}}. Use it to drop a client-supplied user header and to give Post-Function a stable correlation id.

#### Configuration details

```yaml
plugins:
  - name: request-transformer-advanced
    instance_name: llm-tracing-arize-phoenix-header-normalize
    config:
      remove:
        headers:
          - x-user-id
      add:
        headers:
          - 'x-correlation-id:$(headers["x-request-id"] or headers["x-session-id"] or "")'
```
{:.no-copy-code}

- **`remove.headers: x-user-id`**. Stops the client from choosing Phoenix `user.id`. The Consumer username is the identity.
- **`add.headers: x-correlation-id`**. If the client omitted `x-correlation-id`, copy `x-request-id` or `x-session-id`. An empty expression leaves the header unset. Post-Function then falls back to `kong.request.get_id()`.
- **Open-source alternative.** The [Request Transformer](/plugins/request-transformer/) plugin can add and remove the same headers. Change Post-Function `ordering.after.access` to `request-transformer`.

### AI Proxy Advanced: GenAI spans

The [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin injects the provider credential and records `gen_ai.*` on the LLM hop. Phoenix maps those attributes to model name and token counts.

#### Configuration details

```yaml
plugins:
  - name: ai-proxy-advanced
    config:
      max_request_body_size: 10485760
      response_streaming: deny
      targets:
        - route_type: llm/v1/chat
          model:
            provider: openai
            name: gpt-4o-mini
          auth:
            header_name: Authorization
            header_value: "Bearer <openai-key>"
          logging:
            log_statistics: true
            log_payloads: true
```
{:.no-copy-code}

- **`route_type: llm/v1/chat`**. Accepts OpenAI-format chat completions. See the [AI Proxy Advanced reference](/plugins/ai-proxy-advanced/reference/) for the full list of supported route types and providers.
- **`max_request_body_size`**. Set for the recipe's expected payload size. Raise it if you send large conversation contexts or file uploads through this Route.
- **`response_streaming: deny`**. The Post-Function reads the complete response body in its header filter phase to write `output.value` and `llm.output_messages.*`. A streamed response is not available as a single buffered body, so this recipe requires full responses.
- **`logging.log_statistics`**. Token counts on the AI Proxy hop. These become `gen_ai.usage.*` on the span.
- **`logging.log_payloads`**. Kong log payloads. Phoenix Messages still comes from Post-Function, not from this flag.

Kong emits `gen_ai.*` span attributes on AI Proxy requests (Gateway 3.13+), following the [OpenTelemetry GenAI semantic conventions](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/):

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

### OpenTelemetry: Export to Phoenix

The [OpenTelemetry](/plugins/opentelemetry/) plugin runs on the Data Plane. Point `traces_endpoint` at Phoenix's OTLP/HTTP traces URL.

#### Configuration details

```yaml
plugins:
  - name: opentelemetry
    config:
      traces_endpoint: "http://host.docker.internal:6006/v1/traces"
      headers:
        x-project-name: kong-ai-gateway
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
- **`sampling_rate: 1`**. Sample everything while you validate the recipe. Lower this in production.
- **`propagation`**. W3C extract and inject keep an application `traceparent` when the request crosses Kong. App OpenInference spans can then parent the gateway hop.
- **Authentication.** If Phoenix requires an API key, add `Authorization: Bearer <key>` to `headers`. Template it from an environment variable. Do not commit the key.

### Post-Function: OpenInference attributes Phoenix renders

The [Post-Function](/plugins/post-function/) plugin runs Lua after the other plugins. It uses `kong.tracing.get_spans()` to stamp OpenInference keys.

Access phase:

- `kong.service.request.enable_buffering()` so header filter can read the upstream body
- Root span: `openinference.span.kind=CHAIN`, `session.id`, `user.id`, `input.value` (JSON)
- LLM span: `input.value` plus `llm.input_messages.{i}.message.role` / `.content` from `messages[]` (string `content` only)

Header filter phase:

- Span status **OK** (1) when HTTP status is below 400, **ERROR** (2) otherwise, only if status is still unset
- Root and LLM: `output.value`
- LLM: `llm.output_messages.*` from `choices[].message`

{:.info}
> Phoenix Messages does not parse `input.value`. The blob is what the table and the Raw toggle display.

#### Configuration details

The Lua is long. Expand the block to copy the full plugin.

```yaml
plugins:
  - name: post-function
    instance_name: llm-tracing-arize-phoenix-oi-span-attrs
    ordering:
      after:
        access:
          - key-auth
          - request-transformer-advanced
          - ai-proxy-advanced
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

Post-Function executes arbitrary Lua. If your organization disables serverless plugins, set [`untrusted_lua`](/gateway/configuration/#untrusted-lua) accordingly. Do not run Lua that has not been reviewed on a shared Control Plane.

{:.info}
> In production, store the OpenAI token and any Phoenix API key in [Kong Vaults](/gateway/secrets-management/) using {%raw%}`{vault://backend/key}`{%endraw%} references. Payload attributes on spans may contain prompts. Review retention before you enable this in production.

## Apply the Kong configuration

This section configures the Control Plane in two parts. First, adopt the quickstart Control Plane into a kongctl namespace so the apply command below can manage it. The recipe's `select_tags` and the `llm-tracing-arize-phoenix-recipe` namespace scope every resource so teardown removes only this recipe's configuration.

```bash
kongctl adopt control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the Control Plane.

{% navtabs "Providers" %}
{% tab OpenAI %}

Export your environment variables:

```bash
export DECK_CHAT_MODEL='gpt-4o-mini'  # or gpt-4o, o3
```

`DECK_OPENAI_TOKEN` is already exported during the OpenAI prereq, and `KONNECT_CONTROL_PLANE_NAME` during the Kong Konnect prereq, so neither needs to be re-exported here.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - llm-tracing-arize-phoenix-recipe
services:
- name: llm-tracing-arize-phoenix
  url: http://localhost
  routes:
  - name: llm-tracing-arize-phoenix
    paths:
    - /llm-tracing-arize-phoenix
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: key-auth
    instance_name: llm-tracing-arize-phoenix-auth
    config:
      key_names:
      - apikey
      - x-api-key
      key_in_header: true
      key_in_query: false
      hide_credentials: true
  - name: request-transformer-advanced
    instance_name: llm-tracing-arize-phoenix-header-normalize
    config:
      remove:
        headers:
        - x-user-id
      add:
        headers:
        - x-correlation-id:$(headers["x-request-id"] or headers["x-session-id"] or
          "")
  - name: ai-proxy-advanced
    instance_name: llm-tracing-arize-phoenix-proxy
    config:
      max_request_body_size: 10485760
      response_streaming: deny
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: openai
          name: ${{ env "DECK_CHAT_MODEL" }}
  - name: opentelemetry
    instance_name: llm-tracing-arize-phoenix-otel
    config:
      traces_endpoint: ${{ env "DECK_PHOENIX_OTLP_ENDPOINT" }}
      headers:
        x-project-name: ${{ env "DECK_PHOENIX_PROJECT_NAME" }}
      resource_attributes:
        service.name: kong-gateway
      sampling_rate: 1
      propagation:
        default_format: w3c
        extract:
        - w3c
        inject:
        - w3c
  - name: post-function
    instance_name: llm-tracing-arize-phoenix-oi-span-attrs
    ordering:
      after:
        access:
        - key-auth
        - request-transformer-advanced
        - ai-proxy-advanced
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
consumers:
- username: phoenix-client
  keyauth_credentials:
  - key: phoenix-recipe-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: llm-tracing-arize-phoenix-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% endnavtabs %}

If you exported `DECK_PHOENIX_AUTH_HEADER`, add it under the OpenTelemetry plugin `headers.Authorization` in the heredoc above before you apply.

## Try it out

{:.info}
> The demo passes the API key via `default_headers` because the OpenAI SDK reserves `api_key` for the `Authorization: Bearer` header. To let clients pass the key through `api_key` directly, attach a [pre-function](/plugins/pre-function/) plugin that copies the Bearer token to the `apikey` header server-side. See [Authenticate OpenAI SDK clients with Key Auth](https://developer.konghq.com/how-to/authenticate-openai-sdk-clients-with-key-auth/) for the pattern.

`demo.py` sends a chat completion with an invalid key (expecting `401`), a request with a spoofed `x-user-id` header (expecting Kong to drop it), and three chat turns split across two Phoenix Sessions using `x-correlation-id`. Tracing does not change any HTTP response; the script cannot confirm what Phoenix rendered. Open Phoenix after the run to see that.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""LLM tracing with Arize Phoenix demo. See README for context.

Sends chat completions through Kong AI Gateway's `/llm-tracing-arize-phoenix`
Route and prints what each request proves about the tracing setup:

  - An invalid `apikey` is rejected with 401 before any provider call (key-auth).
  - Two turns share one `x-correlation-id` so they land in the same Phoenix
    Session; a third omits the header so Kong falls back to the request id
    (request-transformer-advanced + the post-function Session read).
  - A client-supplied `x-user-id` is dropped; the Consumer username
    (`phoenix-client`) is what Phoenix shows as `user.id`.
  - Token usage and the resolved model come back as Kong response headers
    (`x-kong-llm-model`, `x-kong-llm-tokens-*`), the same numbers the
    `gen_ai.*` span attributes carry into Phoenix.

This script cannot confirm what Phoenix rendered. Post-function writes
OpenInference attributes onto Kong's spans; whether Sessions, the user
column, Input/Output, and Messages populated correctly is only visible in
the Phoenix UI. Run `python demo.py`, then open the project named by
`DECK_PHOENIX_PROJECT_NAME` in Phoenix and confirm what the printed Session
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
PHOENIX_API_KEY = os.getenv("PHOENIX_API_KEY", "phoenix-recipe-key")
PHOENIX_PROJECT_NAME = os.getenv("DECK_PHOENIX_PROJECT_NAME", "kong-ai-gateway")
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

    Confirms key-auth is enforced on the Route before any upstream call, so
    an unauthenticated caller never reaches OpenAI or produces a trace.
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

    request-transformer-advanced removes x-user-id before the request
    reaches AI Proxy Advanced or the post-function, so this value never
    becomes Phoenix's user.id. The Consumer username (phoenix-client) does.
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
    print(f"  {DIM('Phoenix user.id will read the Consumer username instead: ')}{BLUE(BOLD('phoenix-client'))}")


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
    x-correlation-id, so the post-function falls back to
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
  Phoenix user.id will read the Consumer username instead: phoenix-client

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

1. The first call sent `apikey: not-a-real-key`. Key Auth rejected it with `401` before the request reached AI Proxy Advanced or OpenAI, so no span was ever created for it.
2. The second call sent `x-user-id: admin` alongside a valid key. Request Transformer Advanced dropped that header before Post-Function ran, so the root span's `user.id` reads the Consumer username `phoenix-client`, not the client-supplied value.
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

Open the project named in `DECK_PHOENIX_PROJECT_NAME` (default `kong-ai-gateway`).

You should see:

- A Kong root span with kind **CHAIN**, user `phoenix-client`, two Sessions (one grouping turns 1 and 2, one holding turn 3 alone), and JSON Input/Output on the spans table
- An LLM child span for the AI Proxy hop, with model and token counts from `gen_ai.*`
- Messages on the LLM span (role and content bubbles), not only a Raw JSON blob
- Span status **OK** for HTTP 200, and **ERROR** on the auth-rejected call if it ever produced a span

If the root row shows `--` for Input/Output, the listed span is missing `input.value` / `output.value`. Confirm Post-Function ran after AI Proxy and that buffering is enabled.

If Messages is empty, confirm you opened the LLM span, not the CHAIN root. CHAIN ignores `llm.input_messages.*`.

### Explore in Konnect

Open [Konnect](https://cloud.konghq.com/) and navigate to **API Gateway** → **Gateways** → **`llm-tracing-arize-phoenix-recipe`**. The recipe created the following resources on this Control Plane:

- **Gateway services** → **`llm-tracing-arize-phoenix`**: the Service the recipe registered. Its detail page has tabs for Configuration, Routes, Plugins, and Analytics.
  - **Routes** tab: the `/llm-tracing-arize-phoenix` Route, scoped by the `llm-tracing-arize-phoenix-recipe` `select_tags` you used at apply time.
  - **Plugins** tab: `key-auth`, `request-transformer-advanced`, `ai-proxy-advanced`, `opentelemetry`, and `post-function` instances.
- **Consumers** → **`phoenix-client`**: the Consumer whose username the Post-Function copies onto Phoenix `user.id`.

The **Analytics** tab on the Gateway service shows request counts, error rates, and latency for this recipe's traffic. For a deeper dive into these analytics, plus platform-wide analytics across every Control Plane, head to the **Observability** L1 menu in Konnect.

## Variations and next steps

**Self-managed Gateway.** Skip the Konnect quickstart. Apply the same deck file with `deck gateway sync --select-tag llm-tracing-arize-phoenix-recipe`. Set `DECK_PHOENIX_OTLP_ENDPOINT` to a hostname the Data Plane can resolve (`http://phoenix:6006/v1/traces` on a shared Docker network).

**Open-source Request Transformer.** Replace `request-transformer-advanced` with [Request Transformer](/plugins/request-transformer/) and update Post-Function `ordering.after.access`.

**AI Proxy (single target).** Use [AI Proxy](/plugins/ai-proxy/) instead of AI Proxy Advanced when you have one model. Keep Post-Function `ordering` pointed at `ai-proxy`.

**App OpenInference plus gateway.** Leave W3C extract and inject on. The application opens the parent span and sends `traceparent`. Kong's LLM hop nests under that trace in Phoenix. Agent graphs and RAG still need SDK instrumentation in the app.

**Swap the OTLP backend.** The same plugins export to any OTLP/HTTP collector. Phoenix-specific behavior is the `x-project-name` header and OpenInference keys this recipe writes. Langfuse, Jaeger, and Grafana Tempo will store the spans but will not render Phoenix Sessions or Messages.

## Cleanup

The recipe's `select_tags` and kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the control plane from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='llm-tracing-arize-phoenix-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```
