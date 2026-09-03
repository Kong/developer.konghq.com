---
title: Mistral AI with Kong AI Gateway
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
  ai-gateway: '2.0'
categories:
  - llm
  - access-control
featured: false
popular: false

# Machine-readable fields for AI agent setup
entities:
  - ai-model-provider
  - ai-model
  - ai-auth-strategy
  - ai-consumer
requires_embeddings: false
providers:
  - mistral

hint: "Requires a Mistral API key and Python 3.11+."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This recipe uses {{site.konnect_product_name}}. You will provision a {{site.ai_gateway_name}} and a local Data Plane with the quickstart script.

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused by every `kongctl` command below:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Run the {{site.ai_gateway_name}} quickstart:

           ```bash
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This creates a {{site.ai_gateway_name}} named `ai-quickstart`, starts a local Data Plane connected to it, and prints the `export` lines for the rest of the session. Paste those into your shell:

           ```bash
           export AI_GATEWAY_ID='...'
           export KONNECT_CONTROL_PLANE_URL='https://us.api.konghq.com'
           export KONNECT_PROXY_URL='http://localhost:8000'
           ```
    - title: kongctl
      content: |
        This recipe uses [kongctl](/kongctl/) to declare {{site.ai_gateway_name}} entities.

        1. Install **kongctl** version 1.15 or later from [developer.konghq.com/kongctl](/kongctl/).
        1. Verify the version:

           ```bash
           kongctl version
           ```
    - title: Mistral
      icon_url: /assets/icons/mistral.svg
      content: |
        This recipe uses Mistral as the upstream AI provider.

        1. [Create a Mistral account](https://console.mistral.ai/).
        1. [Get an API key](https://console.mistral.ai/api-keys/).
        1. Export the key, and the `Authorization` header value {{site.ai_gateway_name}} sends upstream:

           ```bash
           export MISTRAL_API_KEY='YOUR_MISTRAL_API_KEY'
           export MISTRAL_AUTH_HEADER="Bearer $MISTRAL_API_KEY"
           ```

           The `Bearer` prefix matters. {{site.ai_gateway_name}} stores this header value verbatim and replays it on every upstream call.
    - title: Python 3.11+
      icon_url: /assets/icons/python.svg
      content: |
        The demo script uses the OpenAI SDK, because {{site.ai_gateway_name}} exposes Mistral in OpenAI format:

        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        pip install 'openai>=1.0.0'
        ```

overview: |
  Put Mistral behind {{site.ai_gateway_name}} so that application code never holds a Mistral API key. By
  the end of this recipe you will have two endpoints, one for chat and one for embeddings, backed by
  `mistral-small-latest` and `mistral-embed`. Both are reachable only with a per-application key you can
  revoke on its own, and every request is attributed and costed in {{site.konnect_short_name}}.
---

## The problem

Mistral's API is OpenAI-compatible, which makes the first integration trivial: change `base_url`, change the key, ship it. That simplicity is also the trap, because the key is what gets copied.

- **One key, every service.** A Mistral API key is a single bearer token with account-wide scope. Once three services hold it, you can't tell which one caused a spike, and you can't revoke access for one of them without rotating the key for all three.
- **No identity at the edge.** Mistral's usage reporting is per key, not per caller. When a key is shared, per-team attribution has to be reconstructed from application logs that may not exist.
- **Model names leak into application code.** `mistral-small-latest`, `mistral-medium-latest`, and `codestral-latest` differ in price and capability. When those strings are hardcoded across services, moving a workload to a cheaper model becomes a coordinated redeploy.
- **Chat and embeddings drift apart.** A RAG service needs `mistral-embed` while a chat service needs a generative model. Wired directly, they become two independent integrations, with two copies of the credential and two places to change.

## The solution

{{site.ai_gateway_name}} 2.0 splits this into entities that map onto the problem. One **AI Model Provider** holds the Mistral credential. Two **AI Models** expose it, one for `generate` and one for `embeddings`, each with its own path and its own client-facing alias. An **AI Auth Strategy** with **AI Consumers** issues a separate key per application, so revoking one app is a single delete, and the Mistral key itself never leaves {{site.konnect_short_name}}.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client app
    participant K as {{site.ai_gateway_name}}
    participant M as Mistral API

    C->>K: POST /mistral/chat/completions (apikey, model: mistral-chat)
    activate K
    K->>K: AI Auth Strategy - validate apikey, attach AI Consumer
    K->>K: AI Model - resolve alias to mistral-small-latest
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
  - entity: "AI Model Provider (`mistral`)"
    job: Stores the Mistral API key once and injects it into every upstream call.
  - entity: "AI Model (`mistral-chat`)"
    job: Exposes `/mistral/chat/completions` in OpenAI format, routed to `mistral-small-latest`.
  - entity: "AI Model (`mistral-embeddings`)"
    job: Exposes `/mistral/embeddings` in OpenAI format, routed to `mistral-embed`.
  - entity: "AI Auth Strategy (`mistral-key-auth`)"
    job: Requires an `apikey` header on both endpoints.
  - entity: "AI Consumer (`rag-service`)"
    job: The application identity a key belongs to, and the unit you revoke.
{% endtable %}

## How it works

### AI Model Provider: one place for the Mistral credential

The [AI Model Provider](/ai-gateway/entities/ai-model-provider/) is the only entity that knows the Mistral key. Its `type: mistral` selects Mistral's API surface and resolves the upstream base URL, so you don't configure a hostname. `config.auth` declares the header to send upstream, and marking the value with `!secret` makes it write-only: `kongctl` sends it to {{site.konnect_short_name}} and never reads it back, so it won't surface in a plan or a diff.

Because the credential lives on the provider rather than on each model, rotating it is one apply. Every AI Model whose targets reference this provider picks up the new value.

### AI Model: two capabilities, two endpoints

An [AI Model](/ai-gateway/entities/ai-model/) is a virtual model. It declares a client-facing format, a base path, a set of capabilities, and one or more targets pointing at concrete upstream models.

Mistral supports two capabilities through {{site.ai_gateway_name}}: `generate` and `embeddings`. They need separate AI Models, because the capability determines the endpoint the gateway exposes. `generate` appends `/chat/completions` to the base path, `embeddings` appends `/embeddings`. Both AI Models here use the same `/mistral` base path, which is what puts them on one clean prefix.

`formats: [type: openai]` is what lets the OpenAI SDK work unchanged. The gateway accepts an OpenAI-shaped request, translates it for Mistral, and translates the response back. On each target, `config.type: mistral` and `config.format: openai` tell the gateway which upstream contract to speak.

`config.route.model` decouples the client from the upstream model name. Clients send `mistral-chat`; the gateway routes to `mistral-small-latest`. Moving that workload to `mistral-medium-latest` later is a change to the target, not to any client.

### AI Auth Strategy and AI Consumers: per-app keys

The [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) is inbound authentication, and it's separate from the outbound credential on the provider. A `key-auth` strategy makes the gateway look for an `apikey` header, match it to an [AI Consumer's](/ai-gateway/entities/ai-consumer/) credential, and reject anything else with `401` before a single token of Mistral quota is spent. Because `hide_credentials` defaults to `true`, the gateway also strips that header before forwarding upstream.

Each application gets its own AI Consumer and its own generated credential. Revoking one app is a delete on that credential; the other apps and the Mistral key are untouched.

{:.info}
> An AI Auth Strategy only takes effect once it's referenced from an AI Model's `access.auth_strategies` array. Creating the strategy on its own leaves the endpoints open.

## Create the Mistral AI Model Provider

Store the Mistral credential once:

```bash
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" << 'EOF'
ai_gateway_model_providers:
  - ref: mistral
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: mistral
    display_name: "Mistral"
    type: mistral
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env MISTRAL_AUTH_HEADER}
EOF
```

The plan marks the credential as write-only before applying it:

```text
  ai_gateway_model_provider (1 resources):
    + mistral
      /config/auth/headers/0/value: write requested (current value unavailable; deferred source)

Executing changes:
[1/1] [namespace: default] Creating ai_gateway_model_provider: mistral... ✓
```
{:.no-copy-code}

{:.info}
> If your {{site.ai_gateway_name}} is not in the default US region, pass the region to every `kongctl` command, for example `--region eu`. The region is the subdomain in the `KONNECT_CONTROL_PLANE_URL` the quickstart printed.

## Expose Mistral chat and embeddings

Create both AI Models, the AI Auth Strategy they share, and the AI Consumer that will hold a key. Applying them together lets `kongctl` resolve the references in one pass:

```bash
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" << 'EOF'
ai_gateway_auth_strategies:
  - ref: mistral-key-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: mistral-key-auth
    display_name: "Mistral key auth"
    type: key-auth
    config:
      key_names:
        - apikey

ai_gateway_consumers:
  - ref: rag-service
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: rag-service
    display_name: "RAG service"
    type: api-key
    policies: []

ai_gateway_models:
  - ref: mistral-chat
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: mistral-chat
    display_name: "mistral-chat"
    type: model
    formats:
      - type: openai
    access:
      auth_strategies:
        - mistral-key-auth
    config:
      route:
        paths:
          - /mistral
        model:
          body_param: model
          values:
            - mistral-chat
    targets:
      - name: mistral-small-latest
        provider: mistral
        config:
          type: mistral
          format: openai
    policies: []
    capabilities:
      - generate

  - ref: mistral-embeddings
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: mistral-embeddings
    display_name: "mistral-embeddings"
    type: model
    formats:
      - type: openai
    access:
      auth_strategies:
        - mistral-key-auth
    config:
      route:
        paths:
          - /mistral
        model:
          body_param: model
          values:
            - mistral-embeddings
    targets:
      - name: mistral-embed
        provider: mistral
        config:
          type: mistral
          format: openai
    policies: []
    capabilities:
      - embeddings
EOF
```
{:.collapsible}

```text
Executing changes:
[1/4] [namespace: default] Creating ai_gateway_auth_strategy: mistral-key-auth... ✓
[2/4] [namespace: default] Creating ai_gateway_consumer: rag-service... ✓
[3/4] [namespace: default] Creating ai_gateway_model: mistral-chat... ✓
[4/4] [namespace: default] Creating ai_gateway_model: mistral-embeddings... ✓
```
{:.no-copy-code}

{:.warning}
> Mistral gates its larger models by subscription tier. If you target `mistral-large-latest` on a key that isn't entitled to it, the request reaches Mistral and comes back as `403` with `{"type": "tier_not_allowed"}`. That's an upstream response passed through by the gateway, not a configuration error. `mistral-small-latest` and `mistral-embed` are available on every tier.

## Add per-application API keys

The AI Consumer exists, but it has no credential yet. Credentials are created through the {{site.ai_gateway_name}} API rather than declaratively, because the key is generated server-side and returned exactly once.

Look up the AI Consumer's ID and create its key:

```bash
CONSUMER_ID=$(curl -s "$KONNECT_CONTROL_PLANE_URL/v1/ai-gateways/$AI_GATEWAY_ID/consumers" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  | jq -r '.data[] | select(.name=="rag-service") | .id')

curl -s -X POST \
  "$KONNECT_CONTROL_PLANE_URL/v1/ai-gateways/$AI_GATEWAY_ID/consumers/$CONSUMER_ID/credentials" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H "Content-Type: application/json" \
  --json '{"display_name":"RAG service key","name":"rag-service-key","type":"api-key"}' | jq
```

```json
{
  "api_key": "rXKq7mB2vTnZ4wYpL8sJfH3dGcA6eNu9",
  "created_at": "2026-09-03T19:55:39Z",
  "display_name": "RAG service key",
  "id": "3f1c9a02-7d55-4e18-9b6a-2c84ef07b1da",
  "name": "rag-service-key",
  "type": "api-key"
}
```
{:.no-copy-code}

{:.warning}
> `api_key` is shown once and cannot be retrieved later. Store it in your secret manager now. To rotate, create a second credential on the same AI Consumer, roll the application over, then delete the old one.

The key above is an example; yours will differ. Export your own value for the demo:

```bash
export DEMO_API_KEY='rXKq7mB2vTnZ4wYpL8sJfH3dGcA6eNu9'
```

Confirm the endpoint is closed without it, and open with it:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -X POST "$KONNECT_PROXY_URL/mistral/chat/completions" \
  -H "Content-Type: application/json" \
  --json '{"model":"mistral-chat","messages":[{"role":"user","content":"hi"}]}'
```

```text
401
```
{:.no-copy-code}

```bash
curl -s -X POST "$KONNECT_PROXY_URL/mistral/chat/completions" \
  -H "Content-Type: application/json" \
  -H "apikey: $DEMO_API_KEY" \
  --json '{"model":"mistral-chat","messages":[{"role":"user","content":"Reply with exactly: pong"}]}'
```

```json
{"id":"be735cb07cf94040997e1c74badaa6ff","model":"mistral-small-latest","usage":{"prompt_tokens":21,"total_tokens":24,"completion_tokens":3},"object":"chat.completion","choices":[{"index":0,"finish_reason":"stop","message":{"role":"assistant","content":"pong"}}]}
```
{:.no-copy-code}

## Try it out

The demo script exercises all four behaviors through the OpenAI SDK: a chat call, the same call streamed, an embeddings call, and a call with an invalid key.

{:.info}
> The script passes the key through `default_headers` because the OpenAI SDK reserves `api_key` for the `Authorization: Bearer` header, and this AI Auth Strategy reads `apikey`. Both endpoints share one `base_url`, because both AI Models sit on the `/mistral` base path.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""Mistral through Kong AI Gateway. See the cookbook for context."""

import os
import sys
import time

from openai import APIStatusError, OpenAI

PROXY_URL = os.getenv("KONNECT_PROXY_URL", "http://localhost:8000")
API_KEY = os.environ["DEMO_API_KEY"]

# ANSI color codes. Disabled when stdout isn't a TTY or NO_COLOR is set.
_USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ
def _c(code: str, s: str) -> str:
    return f"\033[{code}m{s}\033[0m" if _USE_COLOR else s
BOLD  = lambda s: _c("1", s)
DIM   = lambda s: _c("2", s)
GREEN = lambda s: _c("32", s)
CYAN  = lambda s: _c("36", s)
RED   = lambda s: _c("31", s)


def make_client(api_key: str) -> OpenAI:
    """Kong reads the apikey header; the SDK reserves api_key for Authorization."""
    return OpenAI(
        base_url=f"{PROXY_URL}/mistral",
        api_key="unused",
        default_headers={"apikey": api_key},
    )


def section(title: str) -> None:
    bar = "=" * 70
    print(f"\n{bar}\n{BOLD(title)}\n{bar}")


def chat(client: OpenAI, prompt: str) -> None:
    print(f"\n{BOLD('[REQUEST]')} model='mistral-chat' prompt={prompt!r}")
    start_ms = round(time.time() * 1000)
    try:
        raw = client.chat.completions.with_raw_response.create(
            model="mistral-chat",
            messages=[{"role": "user", "content": prompt}],
        )
    except APIStatusError as e:
        elapsed_ms = round(time.time() * 1000) - start_ms
        print(f"{RED(BOLD('[BLOCKED]'))} {RED(BOLD(str(e.status_code)))} {e.message}  ({elapsed_ms}ms)")
        return

    elapsed_ms = round(time.time() * 1000) - start_ms
    completion = raw.parse()
    upstream_model = raw.headers.get("x-kong-llm-model", ".")
    upstream_latency = raw.headers.get("x-kong-upstream-latency", ".")
    proxy_latency = raw.headers.get("x-kong-proxy-latency", ".")
    usage = completion.usage

    print(f"[RESPONSE] {DIM(completion.choices[0].message.content)}")
    print(f"{GREEN(BOLD('[ROUTED TO]'))} alias='mistral-chat' -> upstream model={CYAN(BOLD(upstream_model))}")
    print(f"[TOKENS] {DIM(f'prompt={usage.prompt_tokens} completion={usage.completion_tokens} total={usage.total_tokens}')}")
    print(f"[LATENCY] {DIM(f'upstream={upstream_latency}ms  proxy={proxy_latency}ms  total={elapsed_ms}ms')}")


def stream(client: OpenAI, prompt: str) -> None:
    print(f"\n{BOLD('[REQUEST]')} model='mistral-chat' stream=True prompt={prompt!r}")
    start_ms = round(time.time() * 1000)
    first_token_ms = None
    chunks = 0
    text = []
    for chunk in client.chat.completions.create(
        model="mistral-chat",
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


def embed(client: OpenAI, texts: list[str]) -> None:
    print(f"\n{BOLD('[REQUEST]')} model='mistral-embeddings' inputs={len(texts)}")
    start_ms = round(time.time() * 1000)
    raw = client.embeddings.with_raw_response.create(model="mistral-embeddings", input=texts)
    elapsed_ms = round(time.time() * 1000) - start_ms
    result = raw.parse()
    upstream_model = raw.headers.get("x-kong-llm-model", ".")

    print(f"[RESPONSE] {DIM(f'{len(result.data)} vectors of {len(result.data[0].embedding)} dimensions')}")
    print(f"{GREEN(BOLD('[ROUTED TO]'))} alias='mistral-embeddings' -> upstream model={CYAN(BOLD(upstream_model))}")
    print(f"[TOKENS] {DIM(f'prompt={result.usage.prompt_tokens} total={result.usage.total_tokens}')}")
    print(f"[LATENCY] {DIM(f'total={elapsed_ms}ms')}")


def main() -> None:
    client = make_client(API_KEY)

    section("1. Chat, in OpenAI format, answered by Mistral")
    chat(client, "In one sentence, what is an API gateway?")

    section("2. The same endpoint, streamed")
    stream(client, "Name three French cities, comma separated.")

    section("3. Embeddings, same credential, same provider")
    embed(client, [
        "Kong AI Gateway sits between clients and Mistral.",
        "The AI Model Provider holds the Mistral API key.",
    ])

    section("4. Revoked or unknown key. Kong rejects before calling Mistral")
    chat(make_client("not-a-real-key"), "In one sentence, what is an API gateway?")

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

```text
======================================================================
1. Chat, in OpenAI format, answered by Mistral
======================================================================

[REQUEST] model='mistral-chat' prompt='In one sentence, what is an API gateway?'
[RESPONSE] An **API gateway** is a server that acts as a single entry point for client requests to multiple backend services, routing, filtering, and managing API traffic.
[ROUTED TO] alias='mistral-chat' -> upstream model=mistral/mistral-small-latest
[TOKENS] prompt=25 completion=33 total=58
[LATENCY] upstream=753ms  proxy=3ms  total=1779ms

======================================================================
2. The same endpoint, streamed
======================================================================

[REQUEST] model='mistral-chat' stream=True prompt='Name three French cities, comma separated.'
[RESPONSE] Paris, Marseille, Lyon
[STREAMED] 3 chunks  first token=492ms  total=521ms

======================================================================
3. Embeddings, same credential, same provider
======================================================================

[REQUEST] model='mistral-embeddings' inputs=2
[RESPONSE] 2 vectors of 1024 dimensions
[ROUTED TO] alias='mistral-embeddings' -> upstream model=mistral/mistral-embed
[TOKENS] prompt=27 total=27
[LATENCY] total=319ms

======================================================================
4. Revoked or unknown key. Kong rejects before calling Mistral
======================================================================

[REQUEST] model='mistral-chat' prompt='In one sentence, what is an API gateway?'
[BLOCKED] 401 Error code: 401 - {'message': 'Unauthorized'}  (8ms)

======================================================================
Done.
======================================================================
```
{:.no-copy-code}

### What happened

1. **The OpenAI SDK talked to Mistral without knowing it.** The client set `base_url` to the gateway and sent an OpenAI-shaped request. `formats: [type: openai]` on the AI Model translated it into Mistral's contract and translated the reply back. The `X-Kong-LLM-Model` response header reports what actually served the request: `mistral/mistral-small-latest`.
2. **The client sent an alias, not a model name.** Every call used `model: mistral-chat`, which `config.route.model` resolved to the `mistral-small-latest` target. Repointing that target at a different Mistral model is a one-line change to the AI Model, invisible to callers.
3. **Streaming worked over the same endpoint.** Adding `stream=True` produced incremental chunks with a first token at 492 ms, with no separate route, model, or configuration flag.
4. **Chat and embeddings shared one credential and one provider.** The embeddings call went to `/mistral/embeddings` and returned 1024-dimension vectors from `mistral-embed`, authenticated by the same AI Consumer key and backed by the same AI Model Provider.
5. **The invalid key never reached Mistral.** The gateway rejected it in 8 ms, roughly two orders of magnitude below the ~750 ms upstream latency of a real call. No Mistral quota was spent, and no token was billed.
6. **The Mistral key stayed in {{site.konnect_short_name}}.** The script only ever held `rXKq7mB2vTnZ4wYpL8sJfH3dGcA6eNu9`, an AI Consumer credential. The `Bearer` Mistral key lived on the AI Model Provider and was injected server-side.

### Explore in Konnect

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and select your {{site.ai_gateway_name}}. The recipe created five entities you can inspect:

- The **Mistral** AI Model Provider. Its credential is write-only and is never displayed after creation.
- The **mistral-chat** and **mistral-embeddings** AI Models, each with its capability, base path, alias rule, and target.
- The **Mistral key auth** AI Auth Strategy, referenced by both AI Models.
- The **RAG service** AI Consumer and its credential. Deleting that credential revokes the application immediately, without touching the Mistral key.

You can also list the same entities from the API:

```bash
curl -s "$KONNECT_CONTROL_PLANE_URL/v1/ai-gateways/$AI_GATEWAY_ID/models" \
  -H "Authorization: Bearer $KONNECT_TOKEN" | jq -r '.data[] | "\(.name)  \(.capabilities)  \(.config.route.paths)"'
```

```text
mistral-embeddings  ["embeddings"]  ["/mistral"]
mistral-chat  ["generate"]  ["/mistral"]
```
{:.no-copy-code}

{{site.ai_gateway_name}} records tokens, latency, and cost for every request with no extra configuration, so analytics break usage down by AI Model and AI Consumer without any additional policy.

## Variations and next steps

- **Add a second tier.** Add a `mistral-medium-latest` AI Model on the same provider with its own alias, and let callers pick per request. Set `input_cost` and `output_cost` on each target so {{site.konnect_short_name}} reports spend per tier. See [Model cost management](/ai-gateway/model-cost-management/).
- **Fail over to another provider.** An AI Model can hold targets from different AI Model Providers. Add an OpenAI target alongside the Mistral one and set `config.balancer` to distribute or fail over between them. See [Load balancing](/ai-gateway/load-balancing/).
- **Budget each application.** Attach an [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) AI Policy to cap tokens per AI Consumer, so one misbehaving app can't drain the account.
- **Add guardrails.** Attach [AI Prompt Guard](/ai-gateway/policies/ai-prompt-guard/) to filter prompts, or [AI Sanitizer](/ai-gateway/policies/ai-sanitizer/) to strip PII before it reaches Mistral.
- **Swap keys for tokens.** Replace the `key-auth` AI Auth Strategy with `openid-connect` to accept tokens your IdP already issues. An AI Model can carry one of each. See [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/).
- **Point at a self-hosted Mistral.** Mistral's open-weight models can run behind an OpenAI-compatible server. Set `upstream_url` on the target to keep the same client contract against your own deployment.

## Cleanup

Remove the local Data Plane and the {{site.ai_gateway_name}} the quickstart created:

```bash
curl -Ls https://get.konghq.com/ai | bash -s -- -d
```

Then delete the Mistral API key in the [Mistral console](https://console.mistral.ai/api-keys/) if it was created only for this recipe.
