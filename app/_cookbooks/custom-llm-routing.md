---
title: Custom LLM Routing
description: Route chat requests to a small or large model by applying a Pre-function Policy that estimates input token size and rewrites the request model alias.
url: "/cookbooks/custom-llm-routing/"
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
  - llm
  - cost-optimization
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - key-auth
  - datakit
  - ai-model
  - ai-model-provider
requires_embeddings: false
providers:
  - openai

hint: "Requires an OpenAI API key and Python 3.11+."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: Kong Konnect
      content: |
        This tutorial uses {{site.konnect_product_name}}. You will provision a recipe-scoped {{site.ai_gateway}} and local Data Plane via the [quickstart script](https://get.konghq.com/ai).

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped AI Gateway name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='custom-llm-routing-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an AI Gateway named `custom-llm-routing-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
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
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
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
  Route each chat request to a small or large OpenAI model from a custom rule that runs
  on the gateway before proxying. This recipe uses a [datakit](/ai-gateway/policies/datakit/)
  AI Policy on a public Model to estimate input size, call an internal small or large
  [AI Model](/ai-gateway/entities/ai-model/), and return that response. Model dispatch is final
  before Policies run, so pre-function cannot steer between Model aliases. By the end, you have a single endpoint where clients do not choose the
  model. Kong does.
---

## The problem

Platform teams often want the gateway to choose a model tier from a **rule on the request itself**, then keep one OpenAI-format endpoint for every client. Built-in {{site.ai_gateway}} routing already covers many of those decisions:

- **Client-selected aliases.** Apps send `model: fast` or `model: smart`, and the gateway
  maps the alias to an upstream model. See [Basic LLM Routing](/cookbooks/basic-llm-routing/).
- **Meaning-based routing.** Semantic balancers and classifier LLMs pick a tier from prompt
  intent (for example, greeting vs multi-step reasoning). See
  [Model-Based Routing](/cookbooks/model-based-routing/).
- **Usage-based load balancing.** Algorithms such as `lowest-usage` with
  `tokens_count_strategy: prompt-tokens` spread traffic from measured usage across targets.
  See [Load balancing](/ai-gateway/load-balancing/).

Built-in options cover many cases. When the policy is a rule on this request's body, such as input length or a keyword, you add a small custom step and still use model aliases. For example, this applies when routing is needed based on **expected input length** (short prompts to small models, long contexts to large models) or **specific words or phrases** in the prompt (product code, locale marker, workflow keyword). These rules require a deterministic policy for the current request body. If such a policy is required, the gateway can calculate the tier through a simple custom step and pass the result to alias routing already in use.

## The solution

{{site.ai_gateway_name}} resolves which AI Model serves a request **before** attached Policies run, so rewriting `model` in a pre-function cannot switch aliases. This recipe puts a **datakit** Policy on a public `/custom-llm-routing` Model: jq estimates tokens as `ceil(utf8-bytes / 4)`, a branch calls an internal small or large Model, and exit returns that response with `X-LLM-Tier` / `X-Prompt-Est-Tokens`. The shared AI Model Provider injects OpenAI credentials. Clients keep sending OpenAI-format chat requests.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant O as OpenAI

    C->>K: POST /custom-llm-routing (apikey, any model)
    activate K
    K->>K: key-auth Auth Strategy  - validate apikey (else 401)
    K->>K: pre-function Policy  - estimate tokens, set model small or large
    K->>K: AI Model  - match route.model.values alias, select target
    K->>K: AI Model Provider  - inject OpenAI auth
    K->>O: chat completions
    activate O
    O-->>K: completion
    deactivate O
    K-->>C: OpenAI response + X-LLM-Tier + X-Prompt-Est-Tokens + X-Kong-LLM-Model
    deactivate K
{% endmermaid %}
<!-- vale on -->

{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibility
    key: responsibility
rows:
  - component: Client application
    responsibility: "Sends OpenAI-format chat requests with an `apikey` header. The `model` field is ignored after rewrite."
  - component: key-auth Auth Strategy
    responsibility: Validates the API key and attaches the Consumer.
  - component: pre-function Policy
    responsibility: Estimates input tokens, rewrites `model` to `small` or `large`, sets `X-LLM-Tier` and `X-Prompt-Est-Tokens`.
  - component: AI Models (small / large)
    responsibility: "Share `/custom-llm-routing`; each matches one alias via `config.route.model.values` and selects its target."
  - component: AI Model Provider
    responsibility: Holds the OpenAI credential and injects it upstream.
  - component: OpenAI
    responsibility: Serves the completion from the selected model.
{% endtable %}

## How it works

A request flowing through Kong is processed in three stages: authentication, custom rule,
and alias routing.

1. A client sends a chat completion request to `/custom-llm-routing` with an `apikey` header.
   The `model` value in the body does not matter for this recipe.
2. The key-auth AI Auth Strategy validates the key. Missing or unknown keys return `401` before any
   LLM call.
3. The pre-function AI Policy runs in `access`. It sums the UTF-8 byte
   length of `messages[].content`, estimates tokens as `ceil(bytes / 4)`, compares that value
   to a threshold of `80`, and sets `model` to `small` or `large`.
4. The matching AI Model selects the target for that alias, and the AI Model Provider
   injects the OpenAI credential and forwards the request.
5. Kong returns the OpenAI-format response with `X-LLM-Tier`, `X-Prompt-Est-Tokens`, and
   `X-Kong-LLM-Model`.

### Key Auth: API key authentication and Consumer mapping

In {{site.ai_gateway_name}} 2.0, authentication is an AI Auth Strategy rather than a Policy. The recipe registers one Consumer with a demo API key. Successful matches attach that Consumer for analytics and later policies such as token rate limits.

#### Configuration details

```yaml
ai_gateway_auth_strategies:
- type: key-auth
  config:
    key_names:
      - apikey
    hide_credentials: true
```
{:.no-copy-code}

**`key_names: [apikey]`**. Header that carries the Consumer API key. The OpenAI SDK's
`api_key` field becomes `Authorization: Bearer ...`, which Key Auth does not treat as an
API key match. The demo sends `apikey` through `default_headers`.

**`hide_credentials: true`**. Strips the Consumer key before the upstream call so OpenAI
doesn't receive it.

### Pre-function: custom routing rules

The [pre-function](/ai-gateway/policies/pre-function/) AI Policy runs sandboxed Lua in the `access` phase. Both AI Models attach this Policy so the body rewrite happens before alias matching. This recipe's rule is estimated input size. The same pattern works for other request-derived rules: a header value, a JSON field, or a path capture.

{:.warning}
> **Policy-before-auth ordering is not required here.** Unlike recipes that rewrite `Authorization` into `apikey` for Key Auth, this Policy only rewrites the JSON `model` field after authentication. Confirm Policy attachment order with `kongctl explain` if you extend the Lua to touch auth headers.

#### Configuration details

```yaml
ai_gateway_policies:
- type: pre-function
  config:
    access:
      - |
        local cjson = require("cjson.safe")
        local data = cjson.decode(kong.request.get_raw_body() or "{}") or {}
        local chars = 0
        local function add(s)
          if type(s) == "string" then
            chars = chars + #s
          elseif type(s) == "table" then
            for _, v in ipairs(s) do
              add(type(v) == "table" and (v.text or v) or v)
            end
          end
        end
        for _, msg in ipairs(data.messages or {}) do
          add(msg.content)
        end
        local tokens = math.max(1, math.ceil(chars / 4))
        local threshold = 80
        local tier = tokens >= threshold and "large" or "small"
        data.model = tier
        kong.service.request.set_raw_body(cjson.encode(data))
        kong.response.set_header("X-Prompt-Est-Tokens", tostring(tokens))
        kong.response.set_header("X-LLM-Tier", tier)
```
{:.no-copy-code}

**`ceil(bytes / 4)`**. A cheap estimate of input tokens for demo and policy thresholds. It
is not a provider tokenizer. Replace the estimate with a tokenizer call in production if you
need exact counts.

**`threshold = 80`**. Cutoff in estimated tokens. Prompts at or above this value use
`large`. Change the number in the Pre-function body and re-apply to retune. Keep the demo's
`DECK_TOKEN_THRESHOLD` export aligned with this value so assertions stay honest.

**Response headers.** `X-Prompt-Est-Tokens` and `X-LLM-Tier` make the decision visible without
querying Gateway internals.

**Alternative rules.** Swap the size heuristic for any sandboxed logic that sets
`data.model` to an alias string: route VIP Consumers to `large`, honor an
`X-Model-Tier` header, or branch on a JSON field such as `metadata.priority`.

### AI Models: alias routing

Two [AI Models](/ai-gateway/entities/ai-model/) share path `/custom-llm-routing`. After the pre-function rewrites the body, Kong matches `model` to each Model's `config.route.model.values` (`small` or `large`) and sends the request to the configured OpenAI target. Clients can keep sending a placeholder `model` value. Kong overwrites it.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_models:
- name: custom-llm-routing-small
  config:
    route:
      paths:
        - /custom-llm-routing
      model:
        body_param: model
        values:
          - small
  targets:
    - name: ${DECK_CHAT_MODEL_1}
      provider: custom-llm-routing-provider
- name: custom-llm-routing-large
  config:
    route:
      paths:
        - /custom-llm-routing
      model:
        body_param: model
        values:
          - large
  targets:
    - name: ${DECK_CHAT_MODEL_2}
      provider: custom-llm-routing-provider
```
{% endraw -%}
{:.no-copy-code}

**`config.route.model.values`**. Client-facing (or Pre-function-written) alias for the Model.

**Shared path.** Both Models listen on `/custom-llm-routing`. Alias matching selects which Model handles the request.

**Provider credentials.** Kong holds the OpenAI credential on the AI Model Provider and injects it upstream. Clients only hold the Consumer API key.

{:.info}
> In production, store credentials in [Kong Vaults](/gateway/latest/kong-enterprise/secrets-management/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. Kong supports HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the Konnect Config Store.

## Apply the Kong configuration

The following configuration creates an AI Model Provider holding your OpenAI credentials, a key-auth AI Auth Strategy and a Consumer with a demo API key, a pre-function Policy for token-size routing, and two AI Models (`small` and `large`) that share `/custom-llm-routing`. Every resource is scoped using a kongctl namespace so it can be cleanly torn down without affecting other configurations on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on federated configuration management.

First, adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply commands can manage it.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the {{site.ai_gateway}}.

Export the demo Consumer's API key. The Consumer credential's `api_key` field is write-only and must come from an env var, even for this fixed demo value:

```bash
export DECK_CONSUMER_API_KEY='demo-api-key'
```

Export the model env vars. `DECK_CHAT_MODEL_1` is the small tier. `DECK_CHAT_MODEL_2` is the
large tier. Align `DECK_TOKEN_THRESHOLD` with the Pre-function threshold (`80`):

```bash
export DECK_CHAT_MODEL_1='gpt-4o-mini'  # small alias
export DECK_CHAT_MODEL_2='gpt-4o'        # large alias
export DECK_TOKEN_THRESHOLD='80'
```

Apply the Kong configuration:

```bash
{%- raw %}
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
        value: !secret {source: !env 'DECK_OPENAI_TOKEN'}
ai_gateway_auth_strategies:
- ref: custom-llm-routing-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: custom-llm-routing-auth
  display_name: custom-llm-routing key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
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
    api_key: !secret {source: !env 'DECK_CONSUMER_API_KEY'}
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
    - name: EXTRACT_AUTH
      type: jq
      input: request.headers
      jq: '{apikey: (.apikey // .Apikey // .APIKEY)}'
    - name: ESTIMATE_TIER
      type: jq
      input: request.body
      jq: "(
  [ (.messages // [])[]
    | .content
    | if type == \"string\"\
        \ then length
      elif type == \"array\" then
        ([.[] | if type\
        \ == \"object\" then ((.text // \"\") | length) elif type == \"string\" then\
        \ length else 0 end] | add // 0)
      else 0 end
  ] | add // 0
) as $chars
\
        | ([ ($chars / 4 | ceil), 1 ] | max) as $tokens
| {
    tokens: $tokens,
\
        \    tier: (if $tokens >= 80 then \"large\" else \"small\" end)
  }
"
    - name: BUILD_DIAG_HEADERS
      type: jq
      input: ESTIMATE_TIER
      jq: "{
  \"X-LLM-Tier\": .tier,
  \"X-Prompt-Est-Tokens\": (.tokens | tostring)
\
        }
"
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
      url: http://localhost:8000/custom-llm-routing-small
      method: POST
      inputs:
        body: EXTRACT_PROMPT
        headers: EXTRACT_AUTH
    - name: CALL_LARGE
      type: call
      url: http://localhost:8000/custom-llm-routing-large
      method: POST
      inputs:
        body: EXTRACT_PROMPT
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
  - name: !env 'DECK_CHAT_MODEL_1'
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
  - name: !env 'DECK_CHAT_MODEL_2'
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
  targets:
  - name: !env 'DECK_CHAT_MODEL_1'
    provider: custom-llm-routing-provider
    config:
      type: openai

EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

## Try it out

The demo sends a short prompt (`hi`) and a long prompt (`x` repeated 400 times). Both use
`model: ignored-by-router`. Kong should set `X-LLM-Tier` to `small` then `large`, and
`X-Kong-LLM-Model` should follow the alias mapping.

{:.info}
> The demo passes the API key via `default_headers` because the OpenAI SDK reserves `api_key` for the `Authorization: Bearer` header. To let clients pass the key through `api_key` directly, attach a [pre-function](/ai-gateway/policies/pre-function/) Policy that copies the Bearer token to the `apikey` header server-side. See [Authenticate OpenAI SDK clients with Key Auth](/how-to/authenticate-openai-sdk-clients-with-key-auth/) for the pattern.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""Custom LLM routing demo.

Sends a short and a long prompt through Kong. The pre-function Policy estimates
input size, rewrites the request model to small or large, and AI Models route
to the matching OpenAI target. The client model field is ignored.

Expected output:
  - Short prompt -> X-LLM-Tier=small and X-Kong-LLM-Model ending in the small model
  - Long prompt  -> X-LLM-Tier=large and X-Kong-LLM-Model ending in the large model

Run:
  export PROXY_URL=http://localhost:8000
  python demo.py
"""

from __future__ import annotations

import os
import sys
import time

from openai import APIStatusError, OpenAI

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
API_KEY = "demo-api-key"
THRESHOLD = int(os.getenv("DECK_TOKEN_THRESHOLD", "80"))

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


def YELLOW(s: str) -> str:
    return _c("33", s)


def make_client() -> OpenAI:
    return OpenAI(
        base_url=f"{PROXY_URL}/custom-llm-routing",
        api_key="unused",
        default_headers={"apikey": API_KEY},
    )


def est_tokens(content: str) -> int:
    # Matches the Pre-function heuristic: ceil(utf8-bytes / 4).
    return max(1, (len(content.encode("utf-8")) + 3) // 4)


def call(client: OpenAI, label: str, content: str) -> None:
    tokens = est_tokens(content)
    expected = "large" if tokens >= THRESHOLD else "small"
    print(f"\n{BOLD('[REQUEST]')} {label}")
    print(
        f"  {DIM(f'est_tokens={tokens} threshold={THRESHOLD} expected_tier={expected}')}"
    )
    print(f"  {DIM(f'client model field=ignored-by-router prompt_preview={content[:48]!r}')}")

    start_ms = round(time.time() * 1000)
    try:
        raw = client.chat.completions.with_raw_response.create(
            model="ignored-by-router",
            messages=[{"role": "user", "content": content}],
        )
    except APIStatusError as e:
        elapsed_ms = round(time.time() * 1000) - start_ms
        print(
            f"{RED(BOLD('[ERROR]'))} {RED(BOLD(str(e.status_code)))} "
            f"{e.message}  ({elapsed_ms}ms)"
        )
        raise SystemExit(1) from e

    elapsed_ms = round(time.time() * 1000) - start_ms
    completion = raw.parse()
    tier = raw.headers.get("x-llm-tier", ".")
    est = raw.headers.get("x-prompt-est-tokens", ".")
    upstream_model = raw.headers.get("x-kong-llm-model", ".")
    answer = (completion.choices[0].message.content or "")[:120]

    print(f"[RESPONSE] {DIM(answer)}")
    print(
        f"{GREEN(BOLD('[ROUTED TO]'))} tier={GREEN(BOLD(tier))} "
        f"est_tokens={YELLOW(BOLD(est))} "
        f"upstream={CYAN(BOLD(upstream_model))}"
    )
    print(f"[LATENCY] {DIM(f'total={elapsed_ms}ms')}")

    if tier != expected:
        print(
            f"{RED(BOLD('[MISMATCH]'))} expected tier={expected!r}, got={tier!r}"
        )
        raise SystemExit(1)


def section(title: str) -> None:
    bar = "=" * 70
    print(f"\n{bar}\n{BOLD(title)}\n{bar}")


def main() -> None:
    section("1. Short prompt routes to small")
    client = make_client()
    call(client, "short", "hi")

    section("2. Long prompt routes to large")
    long_prompt = "x" * 400
    call(client, "long", long_prompt)

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
1. Short prompt routes to small
======================================================================

[REQUEST] short
  est_tokens=1 threshold=80 expected_tier=small
  client model field=ignored-by-router prompt_preview='hi'
[RESPONSE] Hello! How can I help you today?
[ROUTED TO] tier=small est_tokens=1 upstream=openai/gpt-4o-mini
[LATENCY] total=812ms

======================================================================
2. Long prompt routes to large
======================================================================

[REQUEST] long
  est_tokens=100 threshold=80 expected_tier=large
  client model field=ignored-by-router prompt_preview='xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
[RESPONSE] It looks like your message is a long string of x characters...
[ROUTED TO] tier=large est_tokens=100 upstream=openai/gpt-4o
[LATENCY] total=1404ms

======================================================================
Done.
======================================================================
```
{:.no-copy-code}

### What happened

1. **Short prompt used the small alias.** `hi` estimates to 1 token, below the threshold of
   80. Pre-function set `model` to `small`. `X-Kong-LLM-Model` shows `openai/gpt-4o-mini`.
2. **Long prompt used the large alias.** Four hundred `x` characters estimate to 100 tokens.
   Pre-function set `model` to `large`. `X-Kong-LLM-Model` shows `openai/gpt-4o`.
3. **The client `model` field was ignored.** Both calls sent `ignored-by-router`. Kong
   overwrote it before AI Model alias matching.
4. **Provider credentials stayed on Kong.** The SDK only held the Consumer API key.
   `DECK_OPENAI_TOKEN` was injected by the AI Model Provider.

### Explore in Konnect

Open [Konnect](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `custom-llm-routing-recipe`. The recipe created an AI Model Provider holding your OpenAI credentials, two AI Models (`custom-llm-routing-small` and `custom-llm-routing-large`), a key-auth AI Auth Strategy, a pre-function Policy, and a Consumer with a demo API key credential, all scoped to this recipe by the kongctl namespace applied above.

For platform-wide traffic analysis across every {{site.ai_gateway}}, head to the **Observability** L1 menu in Konnect.

## Variations and next steps

**Change the custom rule.** Keep the pre-function + alias shape and replace the size
heuristic. Route from a request header, a JSON field, or Consumer metadata. The AI Model
targets stay the same as long as you write `small` or `large` into `model`.

**Retune the threshold.** Edit `local threshold = 80` in the Pre-function body, re-apply, and
set `DECK_TOKEN_THRESHOLD` to the same value before running the demo.

**Use a provider tokenizer.** Replace `ceil(bytes / 4)` with a provider tokenizer when exact
billing alignment matters. Keep the rewrite-to-alias step.

**Combine with meaning-based routing.** Use [Model-Based Routing](/cookbooks/model-based-routing/)
when the decision is prompt complexity, then add a Pre-function size gate for context-window
or cost ceilings on top.

**Add per-Consumer token budgets.** Attach the
[ai-rate-limiting-advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy after Key Auth so each app
gets its own token quota. See [LLM Cost Optimization](/cookbooks/llm-cost-optimization/).

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local Data Plane and delete the {{site.ai_gateway}} from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='custom-llm-routing-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
