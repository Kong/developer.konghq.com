---
title: Custom LLM Routing
description: Route each chat request to a small or a large model with a Datakit Policy that estimates the size of the prompt.
url: "/cookbooks/custom-llm-routing/"
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
  - llm-routing
  - cost-optimization
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

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='custom-llm-routing-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `custom-llm-routing-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: AI Credentials
      content: |
        Export the credentials of the provider that the AI Models call. The provider's tab in [Apply the Kong configuration](#apply-the-kong-configuration) reads these variables.

        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key:

           ```sh
           export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
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
  Route each chat request to a small or a large OpenAI model based on the size of its prompt, so that short prompts don't pay large-model prices and clients never choose a model. You'll set up:

  * One `/custom-llm-routing` endpoint that accepts only requests with a valid AI Consumer API key
  * A workflow in {{site.ai_gateway}} that estimates the prompt's token count and sends the prompt to the small or the large model
  * Response headers that show the estimate and the chosen tier
---

## What this cookbook solves

Most teams send every prompt to one model, or let each client choose a model, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "A large model charges the same per-token price for a one-line question as for a long document, so short prompts cost more than they need to."
    solution: "The Datakit Policy estimates the token count of each prompt and sends prompts under 80 estimated tokens to the small AI Model."
  - problem: "Long inputs, for example documents or long conversations, need a more capable model than short questions do."
    solution: "Prompts of 80 estimated tokens or more go to the large AI Model."
  - problem: "When clients choose the model, each team repeats the same size rule, and nothing stops a caller from always choosing the large model."
    solution: "Clients send `model: auto` to one endpoint. {{site.ai_gateway}} chooses the model, and the `X-LLM-Tier` and `X-Prompt-Est-Tokens` response headers show the decision."
  - problem: "Each service holds a copy of the OpenAI API key."
    solution: "The AI Model Provider keeps the key in Kong. Clients hold an AI Consumer key, and the Key Auth AI Auth Strategy rejects unknown keys with `401` before any upstream call."
{% endtable %}

## Try it out

Apply the configuration, then run a demo script that sends a short prompt, a long prompt, and one request with an invalid API key to `/custom-llm-routing`.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your OpenAI API key, a Key Auth AI Auth Strategy, an AI Consumer with a demo API key, a [Datakit](/ai-gateway/policies/datakit/) Policy, and three AI Models: the public `/custom-llm-routing` AI Model and the small and large AI Models that it calls.

Adopt the quickstart {{site.ai_gateway}} into a [kongctl namespace](/kongctl/). Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the demo AI Consumer's API key. The credential's `api_key` field is write-only, so its value must come from an environment variable, even for a fixed demo key:

```bash
export CONSUMER_API_KEY='demo-api-key'
```

Select your provider. The tab exports `CHAT_MODEL_1`, the model of the small AI Model, and `CHAT_MODEL_2`, the model of the large AI Model, then applies the configuration. Provider credentials come from the prerequisites.

{% navtabs "Providers" %}
{% navtab "OpenAI" %}

Export the model env vars:

```bash
export CHAT_MODEL_1='gpt-4o-mini'
export CHAT_MODEL_2='gpt-4o'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: custom-llm-routing-recipe
ai_gateway_model_providers:
- ref: custom-llm-routing-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: custom-llm-routing-provider
  display_name: custom-llm-routing
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'OPENAI_TOKEN'}
ai_gateway_auth_strategies:
- ref: custom-llm-routing-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: custom-llm-routing-auth
  display_name: custom-llm-routing key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: false
ai_gateway_consumers:
- ref: custom-llm-routing-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: custom-llm-routing-consumer
  display_name: custom-llm-routing demo consumer
  type: api-key
  credentials:
  - ref: custom-llm-routing-credential
    name: custom-llm-routing-credential
    display_name: custom-llm-routing demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_policies:
- ref: custom-llm-routing-orchestrator
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: custom-llm-routing-orchestrator
  display_name: custom-llm-routing token size orchestrator
  type: datakit
  config:
    nodes:
    - name: EXTRACT_PROMPT
      type: jq
      input: request.body
      jq: '{messages: .messages}'
    - name: BODY_SMALL
      type: jq
      input: EXTRACT_PROMPT
      jq: '. + {model: "custom-llm-routing-small"}'
    - name: BODY_LARGE
      type: jq
      input: EXTRACT_PROMPT
      jq: '. + {model: "custom-llm-routing-large"}'
    - name: EXTRACT_AUTH
      type: jq
      input: request.headers
      jq: '{apikey: (.apikey // .Apikey // .APIKey)}'
    - name: ESTIMATE_TIER
      type: jq
      input: request.body
      jq: |
        (
          [ (.messages // [])[]
            | .content
            | if type == "string" then length
              elif type == "array" then
                ([.[] | if type == "object" then ((.text // "") | length) elif type == "string" then length else 0 end] | add // 0)
              else 0 end
          ] | add // 0
        ) as $chars
        | ([ ($chars / 4 | ceil), 1 ] | max) as $tokens
        | {
            tokens: $tokens,
            tier: (if $tokens >= 80 then "large" else "small" end)
          }
    - name: BUILD_DIAG_HEADERS
      type: jq
      input: ESTIMATE_TIER
      jq: |
        {
          "X-LLM-Tier": .tier,
          "X-Prompt-Est-Tokens": (.tokens | tostring)
        }
    - name: IS_LARGE
      type: jq
      input: ESTIMATE_TIER
      jq: .tier == "large"
    - name: ROUTE_DECISION
      type: branch
      input: IS_LARGE
      then:
      - CALL_LARGE
      - RESPOND_LARGE
      else:
      - CALL_SMALL
      - RESPOND_SMALL
    - name: CALL_SMALL
      type: call
      url: http://localhost:8000/custom-llm-routing-small/chat/completions
      method: POST
      inputs:
        body: BODY_SMALL
        headers: EXTRACT_AUTH
    - name: CALL_LARGE
      type: call
      url: http://localhost:8000/custom-llm-routing-large/chat/completions
      method: POST
      inputs:
        body: BODY_LARGE
        headers: EXTRACT_AUTH
    - name: RESPOND_SMALL
      type: exit
      inputs:
        body: CALL_SMALL.body
        headers: BUILD_DIAG_HEADERS
    - name: RESPOND_LARGE
      type: exit
      inputs:
        body: CALL_LARGE.body
        headers: BUILD_DIAG_HEADERS
ai_gateway_models:
- ref: custom-llm-routing-small
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: custom-llm-routing-small
  display_name: custom-llm-routing (small internal)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - custom-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: deny
    logging:
      payloads: true
    route:
      paths:
      - /custom-llm-routing-small
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: custom-llm-routing-provider
    config:
      type: openai
- ref: custom-llm-routing-large
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: custom-llm-routing-large
  display_name: custom-llm-routing (large internal)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - custom-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: deny
    logging:
      payloads: true
    route:
      paths:
      - /custom-llm-routing-large
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: custom-llm-routing-provider
    config:
      type: openai
- ref: custom-llm-routing-chat
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: custom-llm-routing-chat
  display_name: custom-llm-routing (public)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - custom-llm-routing-auth
  policies:
  - custom-llm-routing-orchestrator
  config:
    max_request_body_size: 10485760
    response_streaming: deny
    logging:
      payloads: true
    route:
      paths:
      - /custom-llm-routing
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
        - auto
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: custom-llm-routing-provider
    config:
      type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% endnavtabs %}

### Run the demo

The script sends `hi` and a prompt of 400 characters, both with `model: auto`, then one request with an invalid API key. In the output, look for the `tier` and `upstream model` on each `[ROUTED TO]` line, and for the `[BLOCKED] 401` line.

{:.info}
> The demo passes the API key in `default_headers` because the OpenAI SDK always sends `api_key` as an `Authorization: Bearer` header. To let clients use `api_key` directly, add a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy (`global: true`) that copies the Bearer token to the `apikey` header. A global Pre-Function Policy runs before authentication, while one attached to the AI Model runs after it.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""Custom LLM routing demo for Kong AI Gateway.

Shows three things:
  1. A short prompt goes to the small model. The Datakit Policy estimates the
     prompt size and returns it in the X-Prompt-Est-Tokens and X-LLM-Tier headers.
  2. A long prompt goes to the large model. Both requests send model="auto",
     the alias of the public AI Model, so the client never chooses the model.
  3. A request with an invalid key gets 401 from Kong before any upstream call.

Expected output: a [ROUTED TO] line with tier=small for the short prompt and
tier=large for the long prompt, then a [BLOCKED] 401 line for the invalid key.

Run: python demo.py (set PROXY_URL if the data plane is not at http://localhost:8000,
and CONSUMER_API_KEY if you changed the demo key).
"""

import os
import sys

from openai import APIStatusError, OpenAI

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
API_KEY = os.getenv("CONSUMER_API_KEY", "demo-api-key")
THRESHOLD = 80

_USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ


def _c(code: str, s: str) -> str:
    return f"\033[{code}m{s}\033[0m" if _USE_COLOR else s


def BOLD(s: str) -> str:
    return _c("1", s)


def DIM(s: str) -> str:
    return _c("2", s)


def GREEN(s: str) -> str:
    return _c("32", s)


def CYAN(s: str) -> str:
    return _c("36", s)


def RED(s: str) -> str:
    return _c("31", s)


def make_client(api_key: str) -> OpenAI:
    """Construct an OpenAI client that sends the given API key in the apikey header."""
    return OpenAI(
        base_url=f"{PROXY_URL}/custom-llm-routing",
        api_key="unused",
        default_headers={"apikey": api_key},
    )


def est_tokens(content: str) -> int:
    """Estimate tokens the way the Datakit Policy does: ceil(characters / 4), at least 1."""
    return max(1, (len(content) + 3) // 4)


def send(client: OpenAI, content: str):
    return client.chat.completions.with_raw_response.create(
        model="auto",
        messages=[{"role": "user", "content": content}],
    )


def call(client: OpenAI, label: str, content: str) -> None:
    """Send one chat request and print the tier and model that answered."""
    tokens = est_tokens(content)
    expected = "large" if tokens >= THRESHOLD else "small"
    print(f"\n{BOLD('[REQUEST]')} {label}")
    print(f"  {DIM(f'est_tokens={tokens} threshold={THRESHOLD} expected_tier={expected}')}")
    print(f"  {DIM(f'model=auto prompt_preview={content[:48]!r}')}")

    try:
        raw = send(client, content)
    except APIStatusError as e:
        print(f"{RED(BOLD('[ERROR]'))} {RED(BOLD(str(e.status_code)))} {e.message}")
        raise SystemExit(1) from e

    completion = raw.parse()
    tier = raw.headers.get("x-llm-tier", ".")
    est = raw.headers.get("x-prompt-est-tokens", ".")
    answer = (completion.choices[0].message.content or "")[:120]

    print(f"[RESPONSE] {DIM(answer)}")
    print(
        f"{GREEN(BOLD('[ROUTED TO]'))} tier={GREEN(BOLD(tier))} "
        f"est_tokens={est} upstream model={CYAN(BOLD(completion.model))}"
    )

    if tier != expected:
        print(f"{RED(BOLD('[MISMATCH]'))} expected tier={expected!r}, got={tier!r}")
        raise SystemExit(1)


def call_invalid_key() -> None:
    """Send one request with a key that no AI Consumer has."""
    bad_key = "not-a-real-key"
    print(f"\nTrying apikey={bad_key!r}")
    try:
        send(make_client(bad_key), "hi")
    except APIStatusError as e:
        print(f"{RED(BOLD('[BLOCKED]'))} {RED(BOLD(str(e.status_code)))}")
        return
    print(f"{RED(BOLD('[ALLOWED]'))} Kong accepted the invalid key")
    raise SystemExit(1)


def section(title: str) -> None:
    bar = "=" * 70
    print(f"\n{bar}\n{BOLD(title)}\n{bar}")


def main() -> None:
    client = make_client(API_KEY)

    section("1. Short prompt routes to the small model")
    call(client, "short", "hi")

    section("2. Long prompt routes to the large model")
    call(client, "long", "x" * 400)

    section("3. Invalid API key. Kong rejects before any upstream call")
    call_invalid_key()

    section("Done.")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
EOF
```
{:.collapsible}

Run it:

```bash
python demo.py
```

Example output:

```text
======================================================================
1. Short prompt routes to the small model
======================================================================

[REQUEST] short
  est_tokens=1 threshold=80 expected_tier=small
  model=auto prompt_preview='hi'
[RESPONSE] Hello! How can I assist you today?
[ROUTED TO] tier=small est_tokens=1 upstream model=gpt-4o-mini-2024-07-18

======================================================================
2. Long prompt routes to the large model
======================================================================

[REQUEST] long
  est_tokens=100 threshold=80 expected_tier=large
  model=auto prompt_preview='xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
[RESPONSE] It looks like your message contains a long string of "x" characters. Could you please provide more details or let me kno
[ROUTED TO] tier=large est_tokens=100 upstream model=gpt-4o-2024-08-06

======================================================================
3. Invalid API key. Kong rejects before any upstream call
======================================================================

Trying apikey='not-a-real-key'
[BLOCKED] 401

======================================================================
Done.
======================================================================
```
{: .no-copy-code .collapsible }

### Check the results

The output confirms the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Routing by prompt size"
    evidence: "`hi` is estimated at 1 token and gets `tier=small`. The 400-character prompt is estimated at 100 tokens and gets `tier=large`. The `upstream model` is the model that OpenAI reports in the response body, so each prompt reached a different model."
  - behavior: "The client doesn't choose the model"
    evidence: "Both requests send `model: auto`, the alias of the public AI Model. The Datakit Policy sends each internal call the name of the AI Model that it calls, and that AI Model's target sets the upstream model."
  - behavior: "Authentication before routing"
    evidence: "The invalid key gets `401`. Kong rejected the request before the Datakit Policy ran, so the request reached neither internal AI Model nor OpenAI."
{% endtable %}

To review the created entities, and per-consumer usage, open the `custom-llm-routing-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Kong authenticates the request on the public AI Model. The Datakit Policy on that AI Model estimates the prompt's token count, calls the small or the large AI Model on the same data plane, and returns that response to the client.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway (/custom-llm-routing)
    participant T as Small or large AI Model
    participant O as OpenAI

    C->>K: POST /custom-llm-routing (apikey, model auto)
    activate K
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: Datakit Policy estimates tokens and picks small or large
    K->>T: Datakit call to /custom-llm-routing-small or /custom-llm-routing-large
    activate T
    T->>T: Key Auth AI Auth Strategy validates the forwarded apikey (else 401)
    T->>O: Request with the AI Model Provider's credentials
    activate O
    O-->>T: Completion
    deactivate O
    T-->>K: OpenAI-format response
    deactivate T
    K-->>C: Datakit exit returns the response with X-LLM-Tier and X-Prompt-Est-Tokens
    deactivate K
{% endmermaid %}
<!-- vale on -->

Kong selects the AI Model for a request before any AI Policy runs, so a policy that rewrites the `model` field can't move a request to another AI Model. The Datakit Policy works around this: it calls the other AI Models over HTTP and returns their response with an `exit` node.

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use. All three AI Models reference this AI Auth Strategy in `access.auth_strategies`, so the Datakit Policy forwards the client's key on each internal call.

The following settings configure the Key Auth AI Auth Strategy and the AI Consumer:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`key_names: [apikey]`"
    purpose: "Kong reads the key from the `apikey` header. Key Auth compares the whole header value, so it can't read a key from an `Authorization: Bearer` header. The note in [Run the demo](#run-the-demo) shows the workaround."
  - setting: "`hide_credentials: false`"
    purpose: "Kong keeps the `apikey` header on the request, because the Datakit Policy reads it and forwards it on the internal calls. With `true`, Kong removes the key before the Datakit Policy runs, and the internal calls fail with `401`. OpenAI also receives the `apikey` header, but the AI Model Provider replaces the `Authorization` header with its own credentials."
  - setting: "`credentials[].api_key`"
    purpose: "The AI Consumer's key. The field is write-only, so it takes a `!secret` reference to `CONSUMER_API_KEY`, even for a demo value."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### Datakit Policy

The Datakit Policy is attached to the public AI Model and runs the routing workflow as a graph of nodes. Its `call` nodes send requests to the data plane's own proxy listener at `http://localhost:8000`, at each internal AI Model's path plus `/chat/completions`, so each internal call goes through the same authentication as a client request.

The following nodes make up the workflow:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`EXTRACT_PROMPT`, `BODY_SMALL`, `BODY_LARGE`"
    purpose: "`jq` nodes that build each internal request body: the client's `messages` array and the name of the AI Model to call. The internal AI Models have no `config.route.model`, so each one accepts only its own name in `model`. The other fields of the client request, for example `temperature` or `max_tokens`, aren't forwarded."
  - setting: "`EXTRACT_AUTH`"
    purpose: "A `jq` node that copies the `apikey` header from the request headers, so the internal calls authenticate as the same AI Consumer."
  - setting: "`ESTIMATE_TIER`"
    purpose: "A `jq` node that counts the characters in each message's `content`: the string, or the `text` of each part when `content` is an array. It estimates tokens as `ceil(characters / 4)`, with a minimum of 1, and picks `large` at 80 estimated tokens or more. jq's [`length`](https://jqlang.org/manual/#length) counts Unicode code points, not bytes. The estimate isn't a tokenizer count. For exact counts, use a tokenizer such as OpenAI's [tiktoken](https://github.com/openai/tiktoken)."
  - setting: "`BUILD_DIAG_HEADERS`"
    purpose: "A `jq` node that turns the estimate into the `X-LLM-Tier` and `X-Prompt-Est-Tokens` response headers."
  - setting: "`IS_LARGE`, `ROUTE_DECISION`"
    purpose: "`IS_LARGE` turns the tier into a boolean. The `branch` node runs `CALL_LARGE` and `RESPOND_LARGE` when it's `true`, and `CALL_SMALL` and `RESPOND_SMALL` otherwise."
  - setting: "`CALL_SMALL`, `CALL_LARGE`"
    purpose: "`call` nodes that send `BODY_SMALL` or `BODY_LARGE` and the key to `/custom-llm-routing-small/chat/completions` or `/custom-llm-routing-large/chat/completions`. Without the `/chat/completions` operation path, no route matches the call."
  - setting: "`RESPOND_SMALL`, `RESPOND_LARGE`"
    purpose: "`exit` nodes that return the internal AI Model's response body, with the headers from `BUILD_DIAG_HEADERS`, to the client. They don't pass on the internal AI Model's response headers. {{site.ai_gateway}} then doesn't call the public AI Model's own target."
{% endtable %}

### AI Model Provider and AI Models

The AI Model Provider holds the OpenAI API key and adds it to each request to OpenAI. Clients call the public AI Model, `custom-llm-routing-chat`, on `/custom-llm-routing`. The small and large AI Models exist for the Datakit Policy, but a client with a valid key can also call them directly, because the internal calls use the client's own key.

The following settings configure the AI Model Provider and the AI Models:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Provider)"
    purpose: "The OpenAI API key, from `OPENAI_TOKEN`. Kong adds it to each request to OpenAI. The field is write-only, so {{site.konnect_short_name}} never returns it."
  - setting: "`targets[].name` (small and large AI Models)"
    purpose: "The upstream models, from `CHAT_MODEL_1` and `CHAT_MODEL_2`. Change them and re-apply to swap models without changing clients."
  - setting: "`config.route.model` (public AI Model)"
    purpose: "Kong reads the `model` field of the request body (`body_param: model`) and matches it against `auto`. Another value matches no AI Model and returns `500` with `failed the initial dns/balancer resolve for 'ai-gateway.upstream.local'`."
  - setting: "`policies` (public AI Model)"
    purpose: "Attaches the Datakit Policy to the public AI Model only. The internal calls don't run the workflow again."
  - setting: "`targets` (public AI Model)"
    purpose: "An AI Model needs at least one target. The `exit` nodes return before Kong uses it."
  - setting: "`config.route.paths`"
    purpose: "`/custom-llm-routing` for the public AI Model, and `/custom-llm-routing-small` and `/custom-llm-routing-large` for the internal ones. The `generate` capability adds `/chat/completions` to each path."
  - setting: "`config.response_streaming: deny`"
    purpose: "Clients can't set `stream=true` on any of the three AI Models. The Datakit Policy needs the complete response body to return it."
  - setting: "`config.max_request_body_size: 10485760`"
    purpose: "Accepts request bodies up to 10 MB, instead of the 8 MB default."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so you can call the local data plane at `http://localhost:8000`, and so the Datakit Policy can call the internal AI Models over HTTP."
  - setting: "`config.route.strip_path: true`"
    purpose: "Kong removes the route path before it forwards the request upstream."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. The default is `false`."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key and the OpenAI API key in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

### Response headers

The Datakit Policy adds the following headers to each routed response:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-LLM-Tier`"
    description: "The tier that the Datakit Policy picked: `small` or `large`."
  - header: "`X-Prompt-Est-Tokens`"
    description: "The estimated token count of the prompt, as `ceil(characters / 4)`."
{% endtable %}

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
    how: "Change `CHAT_MODEL_1` or `CHAT_MODEL_2` and re-apply the configuration from [Apply the Kong configuration](#apply-the-kong-configuration). Clients keep sending `model: auto`."
  - variation: "Change the threshold"
    how: "Change `80` in the `ESTIMATE_TIER` node and re-apply the configuration. Set `THRESHOLD` in `demo.py` to the same value, because the demo checks the tier against it."
  - variation: "Route on another request value"
    how: "Change the `ESTIMATE_TIER` node to pick the tier from another value, for example a keyword in the prompt, or a header that you add as an input from `request.headers`. The `branch`, `call`, and `exit` nodes don't change."
  - variation: "Forward other request parameters"
    how: "Build `BODY_SMALL` and `BODY_LARGE` from `request.body` with `.model` set to the AI Model name, instead of only from `messages`, so that fields such as `temperature` and `max_tokens` reach OpenAI."
  - variation: "Route by prompt complexity"
    how: "Replace the size estimate with a classifier call to a small model. See the [model-based routing cookbook](/cookbooks/model-based-routing/) for the same `call`, `branch`, and `exit` pattern with a classifier."
  - variation: "Add per-consumer token limits"
    how: "Attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to the small and large AI Models, which make the upstream calls. This cookbook hasn't confirmed separate budgets for each AI Consumer. See the [LLM cost optimization cookbook](/cookbooks/llm-cost-optimization/) for an example."
{% endtable %}

## Cleanup

The quickstart created an {{site.ai_gateway}} for this recipe only, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='custom-llm-routing-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

Leave the virtual environment and remove the files and environment variables that the recipe created:

```bash
deactivate
rm -rf .venv demo.py
unset CONSUMER_API_KEY CHAT_MODEL_1 CHAT_MODEL_2
```

If you created the OpenAI API key only for this recipe, delete it in the [OpenAI dashboard](https://platform.openai.com/api-keys).
