---
title: Mistral AI with {{site.ai_gateway_name}}
description: Put Mistral chat and embedding models behind one {{site.ai_gateway_name}} endpoint, with per-application API keys, so no client ever holds your Mistral key.
url: "/cookbooks/mistral-ai-with-kong-ai-gateway/"
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
  - access-control
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - ai-model-provider
  - ai-model
  - ai-auth-strategy
  - ai-consumer
requires_embeddings: true
providers:
  - mistral

hint: "Requires a Mistral API key and Python 3.11+."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: Kong Konnect
      content: |
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped {{site.ai_gateway}} and local Data Plane.

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='mistral-ai-with-kong-ai-gateway-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `mistral-ai-with-kong-ai-gateway-recipe`, a local Data Plane connected to it, and prints `export` lines (including `AI_GATEWAY_ID`) for the rest of the session vars. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install [**kongctl**](/kongctl/.
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: Mistral
      content: |
        This tutorial uses Mistral:

        1. [Create a Mistral account](https://console.mistral.ai/).
        1. [Get an API key](https://console.mistral.ai/api-keys/).
        1. Set an environment variable with the API key. The `Bearer` prefix is part of the value:

           ```sh
           export MISTRAL_TOKEN='Bearer YOUR-MISTRAL-KEY'
           ```

        1. Set the API key that this recipe's AI Consumer will present to Kong. This is the key your application sends, not your Mistral key:

           ```sh
           export CONSUMER_API_KEY='demo-api-key'
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
  Put Mistral behind {{site.ai_gateway_name}} so that application code never holds a Mistral API
  key. By the end of this recipe you will have one `/mistral` endpoint serving two capabilities,
  chat through `mistral-small-latest` and embeddings through `mistral-embed`, both reachable only
  with a per-application key you can revoke on its own.

  Because the AI Model exposes Mistral in OpenAI format, the demo talks to Kong with the stock
  OpenAI SDK and never imports a Mistral library.
---

## The problem

Mistral's API is OpenAI-compatible, which makes the first integration trivial: change `base_url`, change the key, ship it. That same key is what gets copied into every service that needs it.

- **One key, every service.** A Mistral API key is a single bearer token with account-wide scope. Once three services hold it, you can't tell which one caused a spike, and you can't revoke access for one of them without rotating the key for all three.
- **No identity at the edge.** Usage reporting is per key, not per caller. When a key is shared, per-team attribution has to be reconstructed from application logs that may not exist.
- **Model names leak into application code.** `mistral-small-latest`, `mistral-medium-latest`, and `codestral-latest` differ in price and capability. When those strings are hardcoded across services, moving a workload to a cheaper model becomes a coordinated redeploy.
- **Chat and embeddings drift apart.** A retrieval service needs an embedding model while a chat service needs a generative one. Wired directly, they become two independent integrations, with two copies of the credential and two places to change.

The root issue is coupling. Application code holds the provider credential, names the provider's models directly, and repeats that wiring per capability, so there's no single place to enforce identity or change routing.

## The solution

{{site.ai_gateway_name}} splits this into entities that map onto the problem. One [AI Model Provider](/ai-gateway/entities/ai-model-provider/) holds the Mistral credential. Two [AI Models](/ai-gateway/entities/ai-model/) expose it, one for `generate` and one for `embeddings`, sharing a single base path and each answering to its own client-facing alias. An [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) with an [AI Consumer](/ai-gateway/entities/ai-consumer/) issues a separate key per application, so revoking one app is a single delete and the Mistral key never leaves {{site.konnect_short_name}}.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client app
    participant K as {{site.ai_gateway_name}}
    participant M as Mistral API

    C->>K: POST /mistral/chat/completions (apikey, model: mistral-chat)
    activate K
    K->>K: AI Auth Strategy - validate apikey, attach AI Consumer (else 401)
    K->>K: AI Model - resolve alias mistral-chat to mistral-small-latest
    K->>K: AI Model Provider - inject Authorization header
    K->>M: POST /v1/chat/completions (Bearer MISTRAL_API_KEY)
    M-->>K: completion and token usage
    K->>K: record tokens, latency, cost
    K-->>C: OpenAI-format response
    deactivate K
{% endmermaid %}
<!-- vale on -->

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Job in this recipe
    key: job
rows:
  - entity: "AI Model Provider"
    job: Stores the Mistral API key once and injects it into every upstream call.
  - entity: "AI Model (chat)"
    job: Exposes `/mistral/chat/completions` in OpenAI format, routed to `mistral-small-latest`.
  - entity: "AI Model (embeddings)"
    job: Exposes `/mistral/embeddings` in OpenAI format, routed to `mistral-embed`.
  - entity: "AI Auth Strategy"
    job: Requires an `apikey` header on both endpoints and strips it before the upstream call.
  - entity: "AI Consumer"
    job: The application identity a key belongs to, and the unit you revoke.
{% endtable %}

## How it works

A chat request through this recipe passes four stages:

1. **Route match.** The data plane matches `POST /mistral/chat/completions`. The `/mistral` prefix comes from the AI Model's `config.route.paths`, and `/chat/completions` is the endpoint the `generate` capability exposes. An embeddings request matches `/mistral/embeddings` on the second AI Model, which shares the same prefix.
2. **Authentication.** The AI Auth Strategy reads the `apikey` header and matches it to an AI Consumer credential. An unknown key terminates with `401` here, before Kong opens a connection to Mistral, so no Mistral quota is spent on rejected traffic.
3. **Model selection.** The AI Model reads the `model` field from the request body. `mistral-chat` is an alias declared in `config.route.model.values`; Kong resolves it to the target's upstream model name and reports the result in the `X-Kong-LLM-Model` response header.
4. **Upstream call and translation.** The AI Model Provider attaches the stored `Authorization` header, Kong translates the OpenAI-shaped request into Mistral's contract, and translates the response back. Token counts, latency, and cost are recorded on the way through.

### AI Model Provider: one place for the Mistral credential

The AI Model Provider is the only entity that knows the Mistral key. Its `type: mistral` selects Mistral's API surface and resolves the upstream base URL, so the recipe never configures a hostname. Because the credential lives on the provider rather than on each model, rotating it is a single apply, and every AI Model whose targets reference this provider picks up the new value.

#### Configuration details

```yaml
ai_gateway_model_providers:
- ref: mistral-ai-with-kong-ai-gateway-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: mistral-ai-with-kong-ai-gateway-provider
  display_name: mistral-ai-with-kong-ai-gateway
  type: mistral
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'MISTRAL_TOKEN'}
```
{:.no-copy-code}

- **`type: mistral`**: selects the Mistral provider and its default endpoint. See [Mistral provider](/ai-gateway/ai-providers/mistral/) for the supported capabilities.
- **`config.auth.type: basic`**: header-based upstream auth. Mistral expects a bearer token, so the header value carries the `Bearer` prefix.
- **`!secret {source: !env 'MISTRAL_TOKEN'}`**: the credential field is write-only. kongctl sends the value to {{site.konnect_short_name}} and never reads it back, so it can't surface in a plan or a diff. A plain string in this field is rejected.
- **No endpoint is configured here.** `type: mistral` resolves Mistral's hosted API. To route to a self-hosted or Mistral-compatible endpoint instead, set `upstream_url` on the target's `config` block rather than on the provider.

### AI Model: two capabilities behind one path

An AI Model is a virtual model: it declares the wire format it speaks, the base path it answers on, the capabilities it exposes, and the upstream targets it routes to. Mistral supports two capabilities through {{site.ai_gateway_name}}, `generate` and `embeddings`, and each needs its own AI Model because the capability determines the endpoint. Both models in this recipe declare the same `/mistral` base path, so one `base_url` in the client covers chat and embeddings.

`formats: [{type: openai}]` is what lets the stock OpenAI SDK work against Mistral unchanged, and `config.route.model` decouples the client from the upstream model name.

Some providers also offer a native wire format, which passes requests upstream without translation at the cost of locking the AI Model to that provider. Mistral has no native format, so `openai` is the format this recipe uses. See [AI Model](/ai-gateway/entities/ai-model/) for the formats each provider supports.

#### Configuration details

```yaml
ai_gateway_models:
- ref: mistral-ai-with-kong-ai-gateway-chat
  name: mistral-ai-with-kong-ai-gateway-chat
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - mistral-ai-with-kong-ai-gateway-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    route:
      paths:
      - /mistral
      protocols: [http, https]
      model:
        body_param: model
        values: [mistral-chat]
  targets:
  - name: !env 'CHAT_MODEL'
    provider: mistral-ai-with-kong-ai-gateway-provider
    config:
      format: openai
      type: mistral
```
{:.no-copy-code}

- **`capabilities: [generate]`**: exposes `/chat/completions` under the base path. The embeddings model instead declares `capabilities: [embeddings]`, which exposes `/embeddings`.
- **`config.route.model`**: lets clients send `mistral-chat` instead of `mistral-small-latest`. Pointing the target at a different Mistral model is then invisible to callers. Each AI Model accepts exactly one alias value.
- **`response_streaming: allow`**: permits streamed chat responses. The embeddings model sets `deny`, since embeddings return a single payload.
- **`targets[].config.format: openai`**: tells Kong which contract to speak to Mistral. This is the 2.0 replacement for the 1.0 `mistral_format` option.
- **`access.auth_strategies`**: attaches inbound authentication. Authentication is not a policy in 2.0. The `policies` field is reserved for guardrails, caching, and rate limiting.

### AI Auth Strategy and AI Consumers: per-application keys

Inbound authentication is separate from the outbound credential on the provider. A `key-auth` strategy makes Kong look for an `apikey` header, match it to an AI Consumer's credential, and reject anything else with `401`. Because `hide_credentials: true`, Kong strips that header before forwarding upstream, so the consumer key never reaches Mistral. Each application gets its own AI Consumer and its own credential, and revoking one application is a delete on that credential rather than a rotation of the Mistral key.

#### Configuration details

```yaml
ai_gateway_auth_strategies:
- ref: mistral-ai-with-kong-ai-gateway-auth
  name: mistral-ai-with-kong-ai-gateway-auth
  type: key-auth
  config:
    key_names: [apikey]
    key_in_header: true
    key_in_query: false
    key_in_body: false
    hide_credentials: true

ai_gateway_consumers:
- ref: mistral-ai-with-kong-ai-gateway-consumer
  name: rag-service
  type: api-key
  credentials:
  - ref: mistral-ai-with-kong-ai-gateway-consumer-key
    name: rag-service-key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
```
{:.no-copy-code}

- **`key_in_query: false` and `key_in_body: false`**: restrict the credential to the header, keeping keys out of access logs and request bodies.
- **`credentials`**: nests directly inside the AI Consumer. The `api_key` field is write-only and rejects a plain string, so even a demo value is wrapped in `!secret`.
- **To add a second application**, add another `ai_gateway_consumers` entry with its own credential. Both reference the same auth strategy, and each can be deleted independently.

{:.info}
> In production, store credentials in [Kong Vaults](/gateway/secrets-management/) rather than environment variables. Kong supports HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the Konnect Config Store.

## Apply the Kong configuration

This section configures the {{site.ai_gateway}} in two parts. First, adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the apply command below can manage it. The recipe's `mistral-ai-with-kong-ai-gateway-recipe` namespace scopes the gateway so teardown removes only this recipe's configuration.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the {{site.ai_gateway}}.

{% navtabs "Providers" %}
{% tab Mistral %}

Export your environment variables:

```bash
export CHAT_MODEL='mistral-small-latest'   # served as the mistral-chat alias
export EMBEDDINGS_MODEL='mistral-embed'    # served as the mistral-embeddings alias
```

`KONNECT_CONTROL_PLANE_NAME`, `AI_GATEWAY_ID`, `MISTRAL_TOKEN`, and `CONSUMER_API_KEY` are already exported during the prerequisites, so they do not need to be re-exported here.

{:.warning}
> Mistral gates its larger models by subscription tier. If you set `CHAT_MODEL` to a model your key isn't entitled to, the request reaches Mistral and returns `403` with `"type": "tier_not_allowed"`. That's an upstream response passed through by Kong, not a configuration error. `mistral-small-latest` and `mistral-embed` are available on every tier.

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: mistral-ai-with-kong-ai-gateway-recipe
ai_gateway_model_providers:
- ref: mistral-ai-with-kong-ai-gateway-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: mistral-ai-with-kong-ai-gateway-provider
  display_name: mistral-ai-with-kong-ai-gateway
  type: mistral
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'MISTRAL_TOKEN'}
ai_gateway_auth_strategies:
- ref: mistral-ai-with-kong-ai-gateway-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: mistral-ai-with-kong-ai-gateway-auth
  display_name: mistral-ai-with-kong-ai-gateway key auth
  type: key-auth
  config:
    key_names:
    - apikey
    key_in_header: true
    key_in_query: false
    key_in_body: false
    hide_credentials: true
ai_gateway_consumers:
- ref: mistral-ai-with-kong-ai-gateway-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: rag-service
  display_name: RAG service
  type: api-key
  credentials:
  - ref: mistral-ai-with-kong-ai-gateway-consumer-key
    name: rag-service-key
    display_name: RAG service key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_models:
- ref: mistral-ai-with-kong-ai-gateway-chat
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: mistral-ai-with-kong-ai-gateway-chat
  display_name: mistral-ai-with-kong-ai-gateway (chat)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - mistral-ai-with-kong-ai-gateway-auth
  policies: []
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /mistral
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
        - mistral-chat
  targets:
  - name: !env 'CHAT_MODEL'
    provider: mistral-ai-with-kong-ai-gateway-provider
    config:
      format: openai
      type: mistral
- ref: mistral-ai-with-kong-ai-gateway-embeddings
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: mistral-ai-with-kong-ai-gateway-embeddings
  display_name: mistral-ai-with-kong-ai-gateway (embeddings)
  type: model
  formats:
  - type: openai
  capabilities:
  - embeddings
  access:
    auth_strategies:
    - mistral-ai-with-kong-ai-gateway-auth
  policies: []
  config:
    max_request_body_size: 10485760
    response_streaming: deny
    logging:
      payloads: true
    route:
      paths:
      - /mistral
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
        - mistral-embeddings
  targets:
  - name: !env 'EMBEDDINGS_MODEL'
    provider: mistral-ai-with-kong-ai-gateway-provider
    config:
      format: openai
      type: mistral
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% endnavtabs %}

## Try it out

The demo script exercises all four behaviors through the OpenAI SDK: a chat call, the same call streamed, an embeddings call, and a call with an invalid key.

{:.info}
> The script passes the key through `default_headers` because the OpenAI SDK reserves `api_key` for the `Authorization: Bearer` header, while this auth strategy reads the `apikey` header. The SDK still requires `api_key` to be set to something, so the demo passes the literal string `unused`.

A chat request through Kong looks like this:

```bash
curl -s -X POST "$KONNECT_PROXY_URL/mistral/chat/completions" \
  -H "Content-Type: application/json" \
  -H "apikey: $CONSUMER_API_KEY" \
  --json '{"model":"mistral-chat","messages":[{"role":"user","content":"Reply with exactly: pong"}]}'
```

```json
{"id":"54c390f45d7343e994cd0f648121795f","created":1789107525,"model":"mistral-small-latest","usage":{"prompt_tokens":21,"total_tokens":24,"completion_tokens":3},"object":"chat.completion","choices":[{"index":0,"finish_reason":"stop","message":{"role":"assistant","content":"pong"}}]}
```
{:.no-copy-code}

The response carries `X-Kong-LLM-Model: mistral/mistral-small-latest`, the upstream model Kong resolved the `mistral-chat` alias to.

Save the demo script as `demo.py`:

```python
"""Mistral chat and embeddings through Kong AI Gateway.

Demonstrates that a single Kong endpoint fronts two Mistral capabilities while the
Mistral API key stays on the AI Model Provider, never in this script:

  1. Chat completion via the `mistral-chat` alias, showing the upstream model Kong
     resolved it to in the X-Kong-LLM-Model response header.
  2. The same endpoint streamed, proving response_streaming: allow.
  3. Embeddings via the `mistral-embeddings` alias on the same base path.
  4. A call with an invalid key, proving the key-auth AI Auth Strategy rejects it
     before any Mistral quota is spent.

Run:
    export PROXY_URL="$KONNECT_PROXY_URL"
    export CONSUMER_API_KEY='demo-api-key'
    python demo.py
"""

import os
import sys
import time

from openai import APIStatusError, OpenAI

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
API_KEY = os.getenv("CONSUMER_API_KEY", "demo-api-key")

# Client-facing aliases declared in each AI Model's config.route.model.values.
# Kong resolves these to the upstream Mistral model names.
CHAT_MODEL = "mistral-chat"
EMBEDDINGS_MODEL = "mistral-embeddings"

# ANSI color codes. Disabled when stdout isn't a TTY or NO_COLOR is set.
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
    """Kong reads the apikey header; the OpenAI SDK reserves api_key for Authorization."""
    return OpenAI(
        base_url=f"{PROXY_URL}/mistral",
        api_key="unused",
        default_headers={"apikey": api_key},
    )


def section(title: str) -> None:
    bar = "=" * 70
    print(f"\n{bar}\n{BOLD(title)}\n{bar}")


def chat(client: OpenAI, prompt: str) -> None:
    print(f"\n{BOLD('[REQUEST]')} model={CHAT_MODEL!r} prompt={prompt!r}")
    start_ms = round(time.time() * 1000)
    try:
        raw = client.chat.completions.with_raw_response.create(
            model=CHAT_MODEL,
            messages=[{"role": "user", "content": prompt}],
        )
    except APIStatusError as e:
        elapsed_ms = round(time.time() * 1000) - start_ms
        print(f"{RED(BOLD('[BLOCKED]'))} {RED(BOLD(str(e.status_code)))} {e.message}  ({elapsed_ms}ms)")
        return

    elapsed_ms = round(time.time() * 1000) - start_ms
    completion = raw.parse()
    usage = completion.usage
    upstream_model = raw.headers.get("x-kong-llm-model", ".")
    upstream_latency = raw.headers.get("x-kong-upstream-latency", ".")
    proxy_latency = raw.headers.get("x-kong-proxy-latency", ".")

    print(f"[RESPONSE] {DIM(completion.choices[0].message.content)}")
    print(f"{GREEN(BOLD('[ROUTED TO]'))} alias={CHAT_MODEL!r} -> upstream model={CYAN(BOLD(upstream_model))}")
    print(f"[TOKENS] {DIM(f'prompt={usage.prompt_tokens} completion={usage.completion_tokens} total={usage.total_tokens}')}")
    print(f"[LATENCY] {DIM(f'upstream={upstream_latency}ms  proxy={proxy_latency}ms  total={elapsed_ms}ms')}")


def stream(client: OpenAI, prompt: str) -> None:
    print(f"\n{BOLD('[REQUEST]')} model={CHAT_MODEL!r} stream=True prompt={prompt!r}")
    start_ms = round(time.time() * 1000)
    first_token_ms = None
    chunks = 0
    text = []
    for chunk in client.chat.completions.create(
        model=CHAT_MODEL,
        messages=[{"role": "user", "content": prompt}],
        stream=True,
    ):
        piece = chunk.choices[0].delta.content
        if piece:
            if first_token_ms is None:
                first_token_ms = round(time.time() * 1000) - start_ms
            chunks += 1
            text.append(piece)
    elapsed_ms = round(time.time() * 1000) - start_ms
    print(f"[RESPONSE] {DIM(''.join(text))}")
    print(f"{GREEN(BOLD('[STREAMED]'))} {chunks} chunks  {DIM(f'first token={first_token_ms}ms  total={elapsed_ms}ms')}")


def embed(client: OpenAI, texts) -> None:
    print(f"\n{BOLD('[REQUEST]')} model={EMBEDDINGS_MODEL!r} inputs={len(texts)}")
    start_ms = round(time.time() * 1000)
    raw = client.embeddings.with_raw_response.create(model=EMBEDDINGS_MODEL, input=texts)
    elapsed_ms = round(time.time() * 1000) - start_ms
    result = raw.parse()
    upstream_model = raw.headers.get("x-kong-llm-model", ".")

    print(f"[RESPONSE] {DIM(f'{len(result.data)} vectors of {len(result.data[0].embedding)} dimensions')}")
    print(f"{GREEN(BOLD('[ROUTED TO]'))} alias={EMBEDDINGS_MODEL!r} -> upstream model={CYAN(BOLD(upstream_model))}")
    print(f"[TOKENS] {DIM(f'prompt={result.usage.prompt_tokens} total={result.usage.total_tokens}')}")
    print(f"[LATENCY] {DIM(f'total={elapsed_ms}ms')}")


def main() -> None:
    client = make_client(API_KEY)

    section("1. Chat, in OpenAI format, answered by Mistral")
    chat(client, "In one sentence, what is an API gateway?")

    section("2. The same endpoint, streamed")
    stream(client, "Name three French cities, comma separated.")

    section("3. Embeddings, same credential, same base path")
    embed(client, [
        "Kong AI Gateway sits between clients and Mistral.",
        "The AI Model Provider holds the Mistral API key.",
    ])

    bad_key = "not-a-real-key"
    section("4. Revoked or unknown key. Kong rejects before calling Mistral")
    print(f"{DIM(f'attempting with apikey={bad_key!r}')}")
    chat(make_client(bad_key), "In one sentence, what is an API gateway?")

    section("Done.")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
```
{:.collapsible}

Point the script at the gateway and run it:

```bash
export PROXY_URL="$KONNECT_PROXY_URL"
python demo.py
```

```text
======================================================================
1. Chat, in OpenAI format, answered by Mistral
======================================================================

[REQUEST] model='mistral-chat' prompt='In one sentence, what is an API gateway?'
[RESPONSE] An **API gateway** is a server that acts as an intermediary between clients and backend services, routing requests, aggregating responses, and enforcing policies like authentication, rate limiting, and load balancing.
[ROUTED TO] alias='mistral-chat' -> upstream model=mistral/mistral-small-latest
[TOKENS] prompt=25 completion=41 total=66
[LATENCY] upstream=881ms  proxy=6ms  total=1171ms

======================================================================
2. The same endpoint, streamed
======================================================================

[REQUEST] model='mistral-chat' stream=True prompt='Name three French cities, comma separated.'
[RESPONSE] Paris, Lyon, Marseille
[STREAMED] 3 chunks  first token=395ms  total=424ms

======================================================================
3. Embeddings, same credential, same base path
======================================================================

[REQUEST] model='mistral-embeddings' inputs=2
[RESPONSE] 2 vectors of 1024 dimensions
[ROUTED TO] alias='mistral-embeddings' -> upstream model=mistral/mistral-embed
[TOKENS] prompt=27 total=27
[LATENCY] total=1167ms

======================================================================
4. Revoked or unknown key. Kong rejects before calling Mistral
======================================================================
attempting with apikey='not-a-real-key'

[REQUEST] model='mistral-chat' prompt='In one sentence, what is an API gateway?'
[BLOCKED] 401 Error code: 401 - {'message': 'Unauthorized'}  (6ms)

======================================================================
Done.
======================================================================
```
{:.no-copy-code}

### What happened

1. **The OpenAI SDK talked to Mistral without knowing it.** The client set `base_url` to Kong and sent an OpenAI-shaped request. `formats: [{type: openai}]` on the AI Model translated it into Mistral's contract and translated the reply back. No Mistral SDK is installed; the only dependency is `openai`.
2. **The client sent an alias, not a model name.** Every call used `model: mistral-chat`, which `config.route.model` resolved to the `mistral-small-latest` target. `X-Kong-LLM-Model` reports what actually served the request. Re-pointing that target is a one-line change, invisible to callers.
3. **Streaming worked over the same endpoint.** Adding `stream=True` produced incremental chunks with a first token at 395 ms, with no separate route or model.
4. **Chat and embeddings shared one credential and one provider.** The embeddings call went to `/mistral/embeddings` and returned 1024-dimension vectors from `mistral-embed`, authenticated by the same AI Consumer key and backed by the same AI Model Provider. Two capabilities, one base path, one credential.
5. **The invalid key never reached Mistral.** Kong rejected it in 6 ms, against the 881 ms the real call above took once it reached Mistral. No Mistral quota was spent, and no token was billed.
6. **The Mistral key stayed in {{site.konnect_short_name}}.** The script only ever held the AI Consumer credential. The Mistral key lived on the AI Model Provider as a write-only field and was injected server-side.

### Explore in Konnect

Open [Konnect](https://cloud.konghq.com/) and select the `mistral-ai-with-kong-ai-gateway-recipe` {{site.ai_gateway}}. It holds five resources created by this recipe:

- One AI Model Provider, `mistral-ai-with-kong-ai-gateway-provider`, holding the Mistral credential. The key is write-only and is never displayed after creation.
- Two AI Models, `mistral-ai-with-kong-ai-gateway-chat` and `mistral-ai-with-kong-ai-gateway-embeddings`, each with its own capability, alias rule, and target.
- One AI Auth Strategy, `mistral-ai-with-kong-ai-gateway-auth`, referenced by both AI Models.
- One AI Consumer, `rag-service`, and its credential. Deleting that credential revokes the application immediately, without touching the Mistral key.

You can list the same resources from the API:

```bash
curl -s "$KONNECT_CONTROL_PLANE_URL/v1/ai-gateways/$AI_GATEWAY_ID/models" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  | jq -r '.data[] | "\(.name)  \(.capabilities)  \(.config.route.paths)"'
```

```text
mistral-ai-with-kong-ai-gateway-embeddings  ["embeddings"]  ["/mistral"]
mistral-ai-with-kong-ai-gateway-chat  ["generate"]  ["/mistral"]
```
{:.no-copy-code}

{{site.ai_gateway_name}} records token consumption, request latency, and per-provider cost for every AI Model with no extra configuration, so you can monitor spend and see which AI Models drive the most usage. Platform-wide telemetry lives under the [Observability](/observability/) menu.

## Variations and next steps

- **Add a second tier.** Add a third AI Model on the same provider with its own alias and a `mistral-medium-latest` target, and let callers pick per request. Set `input_cost` and `output_cost` on each target so {{site.konnect_short_name}} reports spend per tier. See [Model cost management](/ai-gateway/model-cost-management/).
- **Budget each application.** Attach an [ai-rate-limiting-advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) AI Policy to cap tokens per AI Consumer, so one misbehaving application can't drain the account. The AI policy counts tokens rather than requests, which is the correct unit for LLM cost control.
- **Add guardrails.** Attach [ai-prompt-guard](/ai-gateway/policies/ai-prompt-guard/) to filter prompts by pattern, or [ai-sanitizer](/ai-gateway/policies/ai-sanitizer/) to strip PII before it reaches Mistral.
- **Fail over to another provider.** An AI Model can hold targets from different AI Model Providers. Add a second provider and target alongside the Mistral one, then set `config.balancer` to distribute or fail over between them. See [Load balancing](/ai-gateway/load-balancing/).
- **Swap keys for tokens.** Replace the `key-auth` AI Auth Strategy with `openid-connect` to accept tokens your identity provider already issues. An AI Model supports one of each simultaneously.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local Data Plane and delete the {{site.ai_gateway}} from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='mistral-ai-with-kong-ai-gateway-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

Then delete the Mistral API key in the [Mistral console](https://console.mistral.ai/api-keys/) if it was created only for this recipe.
