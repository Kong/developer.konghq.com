---
title: LLM Tracing with Arize Phoenix
description: Export {{site.ai_gateway_name}} chat completions to Arize Phoenix over OTLP and fill Sessions, user, Input/Output, and Messages with AI Policies.
url: "/cookbooks/llm-tracing-arize-phoenix/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
works_on:
  - konnect
min_version:
  ai-gateway: '2.0'
categories:
  - observability
  - llm
featured: false
popular: false
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

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script. The two `-e` flags start the data plane with tracing turned on. Kong records spans for the OpenTelemetry Policy only when `KONG_TRACING_INSTRUMENTATIONS` is set (default `off`). `KONG_TRACING_SAMPLING_RATE=1.0` samples every request (default `0.01`):

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='llm-tracing-arize-phoenix-recipe'
           curl -Ls https://get.konghq.com/ai | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_TRACING_INSTRUMENTATIONS=all \
               -e KONG_TRACING_SAMPLING_RATE=1.0
           ```

           This provisions an {{site.ai_gateway}} named `llm-tracing-arize-phoenix-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
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
        This tutorial routes chat requests to OpenAI.

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key:

           ```sh
           export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
    - title: Arize Phoenix
      content: |
        [Arize Phoenix](https://arize.com/docs/phoenix) receives the traces over OTLP/HTTP. The data plane sends them, so the data plane container must reach Phoenix.

        1. Run Phoenix locally. Phoenix serves its UI and the OTLP/HTTP endpoint on port `6006`. `PHOENIX_ENABLE_AUTH=False` turns off authentication, because the `latest` image otherwise rejects unauthenticated traces with `401 Invalid token`:

           ```bash
           docker run -d --name phoenix -p 6006:6006 -e PHOENIX_ENABLE_AUTH=False arizephoenix/phoenix:latest
           ```

        1. Export the traces URL that the data plane container can reach, and the Phoenix project for the traces:

           ```sh
           export PHOENIX_OTLP_ENDPOINT='http://host.docker.internal:6006/v1/traces'
           export PHOENIX_PROJECT_NAME='kong-ai-gateway'
           ```
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
  Trace each chat completion that passes through {{site.ai_gateway_name}} in Arize Phoenix, with Sessions, users, inputs, outputs, and messages filled in, and no tracing code in the application. You'll set up:

  * An `/llm-tracing-arize-phoenix` endpoint that accepts only requests with a valid AI Consumer API key
  * OTLP export of Kong's spans to a Phoenix project
  * OpenInference attributes on each span, so that Phoenix shows the AI Consumer as the user and groups requests into Sessions

  This cookbook traces the gateway hop. Agent steps, tool calls, and retrieval inside the application still need OpenInference instrumentation in the application.
---

## What this cookbook solves

Most teams trace LLM calls with an instrumentation library in each application, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Each service that calls an LLM needs its own instrumentation library and exporter, and services that skip it leave gaps in the traces."
    solution: "The OpenTelemetry Policy exports a trace for each request that passes through the AI Model, with no code in the client."
  - problem: "OpenTelemetry GenAI attributes (`gen_ai.*`) give Phoenix the model name and token counts, but Phoenix Sessions, users, inputs, outputs, and messages read OpenInference attributes."
    solution: "The Post-Function Policy writes the OpenInference attributes `session.id`, `user.id`, and `input.value` on Kong's root span. Kong's LLM span already carries the messages as `gen_ai.*` attributes."
  - problem: "When a trace takes the user from a request header, any client can claim to be any user."
    solution: "The Key Auth AI Auth Strategy identifies the AI Consumer, the Request Transformer Advanced Policy removes the client's `x-user-id` header, and Phoenix shows the AI Consumer as the user."
  - problem: "Requests from one conversation show up as unrelated traces."
    solution: "The Post-Function Policy copies the `x-correlation-id` header to `session.id`, so Phoenix groups the requests of one conversation into one Session."
{% endtable %}

## Try it out

Apply the configuration, run a demo script that sends an invalid key, a spoofed user header, and three chat turns, then open the traces in Phoenix.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your OpenAI credentials, a Key Auth AI Auth Strategy, an AI Consumer with a demo API key, three AI Policies (Request Transformer Advanced, OpenTelemetry, and Post-Function), and an AI Model that uses them. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the demo AI Consumer's API key. The credential's `api_key` field is write-only, so its value must come from an environment variable, even for a fixed demo key:

```bash
export CONSUMER_API_KEY='demo-api-key'
```

Export the chat model. The OpenAI and Phoenix values come from the prerequisites:

```bash
export CHAT_MODEL='gpt-4o-mini'
```

Apply the Kong configuration:

```bash
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
        corr = ngx.var.request_id
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
      if type(parsed) ~= "table" then
        return
      end
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
      model:
        body_param: model
        values:
        - !env 'CHAT_MODEL'
  targets:
  - name: !env 'CHAT_MODEL'
    provider: llm-tracing-arize-phoenix-provider
    config:
      type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

### Run the demo

The script sends one request with an invalid API key, one request with a spoofed `x-user-id` header, and three chat turns. The spoofed request and the first two turns share one `x-correlation-id`. The third turn has none. Tracing doesn't change the HTTP responses, so the script prints only what the client sees. Phoenix shows the rest.

{:.info}
> The demo passes the API key in `default_headers` because the OpenAI SDK always sends `api_key` as an `Authorization: Bearer` header. To let clients use `api_key` directly, add a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy (`global: true`) that copies the Bearer token to the `apikey` header. A global Pre-Function Policy runs before authentication, while one attached to the AI Model runs after it.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""LLM tracing with Arize Phoenix demo for Kong AI Gateway.

Shows four things:
  1. A request with an invalid apikey gets 401 from Kong before any provider call.
  2. A client-supplied x-user-id header is dropped by Kong, so Phoenix shows the
     AI Consumer (phoenix-client) as user.id instead.
  3. Two turns that share one x-correlation-id land in the same Phoenix Session.
  4. A turn without x-correlation-id lands in its own Session, keyed by the request ID.

Expected output: a [BLOCKED] 401 line, one [LLM] line for the x-user-id check, and one
[LLM] line for each of the three turns, with the model and token counts. The script
can't see what Phoenix renders: open the Phoenix project after the run.

Run: python demo.py (set PROXY_URL if the data plane is not at http://localhost:8000,
CONSUMER_API_KEY if you changed the demo key, and PHOENIX_PROJECT_NAME if you changed
the project name).
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
CONSUMER_API_KEY = os.getenv("CONSUMER_API_KEY", "demo-api-key")
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

def make_client(correlation_id=None, api_key=CONSUMER_API_KEY):
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
    unauthenticated caller never reaches OpenAI.
    """
    bad_key = "not-a-real-key"
    print(f"  Trying apikey={bad_key!r}")
    bad_client = make_client(api_key=bad_key)
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
    reaches the Post-Function Policy, so this value never becomes
    Phoenix's user.id. The AI Consumer (phoenix-client) does.
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
    print(f"  {DIM('Phoenix user.id shows the AI Consumer instead: ')}{BLUE(BOLD('phoenix-client'))}")


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
    x-correlation-id, so the Post-Function Policy falls back to the request
    ID and the turn appears as its own Session.
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
  Trying apikey='not-a-real-key'
  [BLOCKED] 401 Error code: 401 - Unauthorized

Checking that a client-supplied x-user-id is dropped...
  Sent header x-user-id: admin (client-supplied, dropped by Kong)
  [LLM] "I don't have information identifying who you are."
  Phoenix user.id shows the AI Consumer instead: phoenix-client

Running session-grouping turns...

Turn 1 (session: phoenix-demo-a1b2c3d4e5f6)
  [LLM] "Kong AI Gateway is a layer that manages, secures, and observes traffic to LLM providers."
         Model: openai/gpt-4o-mini  Tokens: 14 in / 19 out  (0.812s)

Turn 2 (session: phoenix-demo-a1b2c3d4e5f6)
  [LLM] "A managed proxy for LLM traffic."
         Model: openai/gpt-4o-mini  Tokens: 38 in / 8 out  (0.431s)

Turn 3 (no x-correlation-id -> falls back to request id)
  [LLM] "Arize Phoenix is an open-source LLM observability and evaluation platform."
         Model: openai/gpt-4o-mini  Tokens: 13 in / 15 out  (0.734s)

============================================================
Done. Open Phoenix -> project kong-ai-gateway -> Sessions -> phoenix-demo-a1b2c3d4e5f6
Confirm: user column reads 'phoenix-client', Input/Output are populated,
and the LLM span's Messages view shows role/content bubbles for each turn.
```
{:.no-copy-code}

### Open the traces in Phoenix

Open Phoenix at `http://localhost:6006`, then open the project named in `PHOENIX_PROJECT_NAME`. Each successful request is one trace with a Kong root span and an LLM span. Open **Sessions** and find the Session ID that the demo printed. It groups the spoofed request and the first two turns. The third turn is in its own Session, keyed by the request ID. This cookbook hasn't confirmed the OpenInference attributes against a live {{site.ai_gateway}}, so check each column in the following table.

### Check the results

The demo output and Phoenix confirm the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Authentication before any provider call"
    evidence: "The invalid key gets `401`. Kong rejected it before the AI Model sent anything to OpenAI."
  - behavior: "The user comes from the AI Consumer"
    evidence: "The user column in Phoenix shows `phoenix-client` for the request that sent `x-user-id: admin`."
  - behavior: "Session grouping"
    evidence: "The Session with the printed ID holds three traces. The third turn has its own Session."
  - behavior: "Inputs, outputs, and messages"
    evidence: "The Input column shows the request JSON. Kong's LLM span carries the role and content of each message in its `gen_ai.*` attributes. The Output column stays empty when the provider compresses its response, as OpenAI does."
  - behavior: "Model and token counts"
    evidence: "The LLM span shows the same model and token counts that the demo prints from the response."
{% endtable %}

To review the created entities, and per-consumer usage, open the `llm-tracing-arize-phoenix-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Kong authenticates the request, normalizes its headers, and sends it to OpenAI. The Post-Function Policy adds OpenInference attributes to the spans, and the OpenTelemetry Policy exports them to Phoenix.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant L as OpenAI
    participant P as Arize Phoenix

    C->>K: POST /llm-tracing-arize-phoenix (apikey, x-correlation-id)
    activate K
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: Request Transformer Advanced Policy removes x-user-id
    K->>K: Post-Function Policy writes input attributes
    K->>L: Chat completion with the AI Model Provider's credentials
    activate L
    L-->>K: Response
    deactivate L
    K->>K: Post-Function Policy writes output attributes
    K-->>C: Response
    K->>P: OpenTelemetry Policy exports spans over OTLP/HTTP
    deactivate K
{% endmermaid %}
<!-- vale on -->

The AI Model lists the three AI Policies in `policies`. The [Post-Function](/ai-gateway/policies/post-function/) Policy runs after the other AI Policies in each phase and after authentication, so it reads the headers that the Request Transformer Advanced Policy already changed.

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the key from a request header and matches it against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, analytics, and in this cookbook, Phoenix's user column use.

The following settings configure the Key Auth AI Auth Strategy and the AI Consumer:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`key_names: [apikey, x-api-key]`"
    purpose: "Kong reads the key from the `apikey` or `x-api-key` header. Key Auth compares the whole header value, so it can't read a key from an `Authorization: Bearer` header. The note in [Run the demo](#run-the-demo) shows the workaround."
  - setting: "`key_in_header: true`, `key_in_query: false`"
    purpose: "Kong accepts keys only in headers. Keys in a query string end up in access logs."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the key before it forwards the request, so OpenAI never sees the AI Consumer key."
  - setting: "`name: phoenix-client` (AI Consumer)"
    purpose: "The Post-Function Policy reads `kong.client.get_consumer().username` and writes it to `user.id`. The AI Consumer schema has `name` but no `username`. This cookbook hasn't confirmed that `username` returns the AI Consumer's `name` on a live {{site.ai_gateway}}."
  - setting: "`credentials[].api_key`"
    purpose: "The AI Consumer's key. The field is write-only, so it takes a `!secret` reference to `CONSUMER_API_KEY`, even for a demo value."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### Request Transformer Advanced Policy

The [Request Transformer Advanced](/ai-gateway/policies/request-transformer-advanced/) Policy changes the request headers before the Post-Function Policy reads them. It runs `remove` before `add`.

The following settings configure the Request Transformer Advanced Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`remove.headers: [x-user-id]`"
    purpose: "Removes a client-supplied user header, so that only the AI Consumer identity reaches the trace."
  - setting: "`add.headers: x-correlation-id`"
    purpose: "Sets `x-correlation-id` from `x-request-id` or `x-session-id` when the client sends one of them. The template is a Lua expression, so `or` picks the first header that is set. This cookbook hasn't confirmed that `add` keeps a client's own `x-correlation-id`. If the value is empty, the Post-Function Policy uses the request ID instead."
{% endtable %}

### AI Model Provider and AI Model

The AI Model Provider holds the OpenAI credentials. The AI Model matches requests on `/llm-tracing-arize-phoenix`, runs the three AI Policies, and sends the request to OpenAI. When tracing is on, Kong adds `gen_ai.*` attributes to the spans, for example the model and the token counts. See the [Gen AI OpenTelemetry spans attributes reference](/ai-gateway/llm-open-telemetry/) for the full list.

The following settings configure the AI Model Provider and the AI Model:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Provider)"
    purpose: "The OpenAI credentials. Kong adds them to each upstream request."
  - setting: "`formats: [{type: openai}]`"
    purpose: "The AI Model accepts OpenAI-format chat completion requests."
  - setting: "`policies`"
    purpose: "Attaches the Request Transformer Advanced, OpenTelemetry, and Post-Function Policies to this AI Model only."
  - setting: "`config.route.model`"
    purpose: "The AI Model answers to the `CHAT_MODEL` value in the body's `model` field (`body_param: model`), which the demo sends. Without a selector, an AI Model accepts only its own name as `model`."
  - setting: "`targets[].name`"
    purpose: "The upstream model, from `CHAT_MODEL`. Change it and re-apply to swap models without changing clients."
  - setting: "`config.response_streaming: deny`"
    purpose: "Clients can't set `stream=true`. The Post-Function Policy reads the complete response body to write `output.value` and the output messages."
  - setting: "`config.max_request_body_size: 10485760`"
    purpose: "Accepts request bodies up to 10 MB, instead of the 8 MB default, for long conversation contexts."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. The default is `false`."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so you can call the local data plane at `http://localhost:8000`."
  - setting: "`config.route.strip_path: true`"
    purpose: "Kong removes `/llm-tracing-arize-phoenix` from the path before it forwards the request."
{% endtable %}

### OpenTelemetry Policy

The [OpenTelemetry](/ai-gateway/policies/opentelemetry/) Policy sends the spans from the data plane to Phoenix. The data plane settings from the {{site.konnect_product_name}} prerequisite decide whether Kong records spans at all.

The following settings configure the OpenTelemetry Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`traces_endpoint`"
    purpose: "The Phoenix OTLP/HTTP URL, from `PHOENIX_OTLP_ENDPOINT`, including the `/v1/traces` path."
  - setting: "`headers.x-project-name`"
    purpose: "The Phoenix project, from `PHOENIX_PROJECT_NAME`. Phoenix creates the project on the first span. The header works only on the OTLP/HTTP endpoint, not on gRPC."
  - setting: "`resource_attributes.service.name`"
    purpose: "The service name on each span: `kong-gateway`."
  - setting: "`sampling_rate: 1`"
    purpose: "Samples every request. This value overrides the data plane's sampling rate. Lower it for production traffic."
  - setting: "`propagation`"
    purpose: "Reads and writes W3C `traceparent` headers. When an application sends `traceparent`, Kong's spans join the application's trace."
{% endtable %}

### Post-Function Policy

The Post-Function Policy runs Lua in two phases. It reads the spans with `kong.tracing.get_spans()`. The first span is Kong's root span, and a span with a `gen_ai.operation.name` attribute or a name that starts with `chat ` is the LLM span.

The following settings configure the Post-Function Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`access`"
    purpose: "Turns on response buffering, then writes `openinference.span.kind: CHAIN`, `session.id`, `user.id`, and `input.value` on the root span. The LLM span doesn't exist yet in the `access` phase, so the code can't write on it. `session.id` comes from `x-correlation-id`, or from the request ID (`ngx.var.request_id`) when the header is empty. Message parsing reads only string `content`."
  - setting: "`header_filter`"
    purpose: "Sets the span status to OK, or to ERROR for a status of `400` or higher. If the response body is JSON, it writes `output.value` on the root span and the LLM span, and `llm.output_messages.*` on the LLM span, each cut at 64 KB. If the provider compresses the response (OpenAI sends gzip), it skips them: a binary attribute value makes Phoenix reject the whole span batch with `422`."
{% endtable %}

The Lua uses only functions that the default `strict` Lua sandbox allows. See [Lua sandboxing in {{site.ai_gateway}}](/ai-gateway/sandboxing/) for the sandbox modes and the allowed functions.

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key and the OpenAI credentials in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault. Spans carry full prompts and responses, so review who can read the Phoenix project.

## Variations and next steps

You can change or extend this configuration in the following ways:

{% table %}
columns:
  - title: Variation
    key: variation
  - title: How
    key: how
rows:
  - variation: "Swap models"
    how: "Change `CHAT_MODEL` and re-apply. Clients and traces keep the same shape."
  - variation: "Send traces to a hosted Phoenix"
    how: "Set `PHOENIX_OTLP_ENDPOINT` to the `/v1/traces` URL of your Phoenix deployment. If it requires an API key, add an `Authorization` header with the value `Bearer <your-phoenix-api-key>` to the OpenTelemetry Policy's `headers`. Policy configuration doesn't accept `!secret`, so reference the value with `!env`. See the [Phoenix API keys documentation](https://arize.com/docs/phoenix/settings/api-keys)."
  - variation: "Join application traces"
    how: "Send `traceparent` from an application that uses OpenInference instrumentation. Kong's spans then nest under the application's trace, next to its agent and retrieval spans."
  - variation: "Add per-consumer token limits"
    how: "Attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to give each AI Consumer its own token budget. See the [LLM cost optimization cookbook](/cookbooks/llm-cost-optimization/) for an example."
  - variation: "Authenticate users with an identity provider"
    how: "Replace the Key Auth AI Auth Strategy with an [OpenID Connect AI Auth Strategy](/ai-gateway/openid-connect/) and map JWT claims to AI Consumers. The AI Policies and the AI Model don't change. See the [Claude Code SSO cookbook](/cookbooks/claude-code-sso/) for an example with Okta."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='llm-tracing-arize-phoenix-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

Remove the Phoenix container:

```bash
docker rm -f phoenix
```
