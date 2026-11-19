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
works_on:
  - konnect
min_version:
  ai-gateway: '2.0'
categories:
  - llm
  - access-control
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
           export KONNECT_CONTROL_PLANE_NAME='mistral-ai-with-kong-ai-gateway-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `mistral-ai-with-kong-ai-gateway-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: Mistral
      content: |
        The AI Model Provider sends your Mistral API key to Mistral as a Bearer token ([Mistral API key quickstart](https://docs.mistral.ai/getting-started/quickstarts/studio/activate-and-generate-api-key)).

        1. [Create a Mistral account](https://console.mistral.ai/).
        1. [Get an API key](https://console.mistral.ai/api-keys/).
        1. Export the API key with the `Bearer` prefix:

           ```sh
           export MISTRAL_TOKEN='Bearer your-mistral-key'
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
  Put Mistral chat and embedding models behind one {{site.ai_gateway_name}} endpoint, so that each application uses its own API key and your Mistral key stays in {{site.ai_gateway}}. You'll set up:

  * A `/mistral` endpoint that serves chat completions and embeddings in OpenAI format
  * Two model aliases, `mistral-chat` and `mistral-embeddings`, that clients select with the `model` field
  * An AI Consumer key for an application, which you can revoke without rotating the Mistral key
---

## What this cookbook solves

Mistral's API is easy to call directly, so teams copy the Mistral API key into each service that needs it, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Each service holds a copy of the Mistral API key. A leaked key affects every service, and rotating it needs coordinated redeploys."
    solution: "The AI Model Provider keeps the Mistral key in Kong and adds it to each upstream request. Applications only hold an AI Consumer key."
  - problem: "When several services share one key, nothing attributes usage to a service or revokes access for one service."
    solution: "The Key Auth AI Auth Strategy maps each API key to an AI Consumer and rejects unknown keys with `401` before any upstream call."
  - problem: "Model names such as `mistral-small-latest` are hardcoded in application code, so moving a workload to another model needs a redeploy."
    solution: "The AI Models answer to the aliases `mistral-chat` and `mistral-embeddings`. You change the upstream model in Kong, and clients keep the same alias."
  - problem: "Chat and embeddings become two separate integrations, with two copies of the key and two places to change."
    solution: "Two AI Models, one for chat and one for embeddings, share the `/mistral` path, the AI Model Provider, and the AI Auth Strategy. Clients use one base URL and one key."
{% endtable %}

## Try it out

Apply the configuration, then run a demo script that sends a chat request, a streamed chat request, an embeddings request, and one request with an invalid API key.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your Mistral credentials, a Key Auth AI Auth Strategy, an AI Consumer with a demo API key, and two AI Models on `/mistral`: one for chat (`mistral-chat`) and one for embeddings (`mistral-embeddings`). A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

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

The tab exports `CHAT_MODEL`, the upstream model for the `mistral-chat` alias, and `EMBEDDINGS_MODEL`, the upstream model for the `mistral-embeddings` alias, then applies the configuration. The Mistral credentials come from the prerequisites. Pick models that your Mistral plan includes ([Mistral models](https://docs.mistral.ai/models)).

{% navtabs "Providers" %}
{% navtab "Mistral" %}

Export the model env vars:

```bash
export CHAT_MODEL='mistral-small-latest'
export EMBEDDINGS_MODEL='mistral-embed'
```

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

{% endnavtab %}
{% endnavtabs %}

### Run the demo

The script sends a chat request with `model: mistral-chat`, the same request streamed, an embeddings request with `model: mistral-embeddings`, and one chat request with an invalid API key. In the output, look for the upstream model on each `[ROUTED TO]` line, the chunk count on the `[STREAMED]` line, and the `401` for the invalid key.

{:.info}
> The demo passes the API key in `default_headers` because the OpenAI SDK always sends `api_key` as an `Authorization: Bearer` header. To let clients use `api_key` directly, add a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy (`global: true`) that copies the Bearer token to the `apikey` header. A global Pre-Function Policy runs before authentication, while one attached to the AI Model runs after it.

Create the demo script:

```bash
cat <<'EOF' > demo.py
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
[BLOCKED] 401 Error code: 401 - Unauthorized  (6ms)

======================================================================
Done.
======================================================================
```
{:.no-copy-code}

### Check the results

The output confirms the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Alias routing for chat"
    evidence: "The `[ROUTED TO]` line shows `mistral/mistral-small-latest` for `mistral-chat`, from the `X-Kong-LLM-Model` header. The client sent only the alias."
  - behavior: "Streaming"
    evidence: "The `[STREAMED]` line shows several chunks for the same alias on the same path, because the chat AI Model allows streamed responses."
  - behavior: "Embeddings on the same path"
    evidence: "The embeddings request used the same base URL and key. The `[ROUTED TO]` line shows `mistral/mistral-embed`, and the response has 1024-dimension vectors."
  - behavior: "Authentication before any upstream call"
    evidence: "The invalid key gets `401` in a few milliseconds, far less than the upstream latency of the chat request. Kong never contacted Mistral."
  - behavior: "Mistral key stays in Kong"
    evidence: "The script only held the AI Consumer key. The AI Model Provider added the Mistral key to each upstream request."
{% endtable %}

To review the created entities, and per-consumer usage, open the `mistral-ai-with-kong-ai-gateway-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Kong authenticates each request with the Key Auth AI Auth Strategy, selects the AI Model whose alias matches the `model` field, and sends the request to Mistral with the AI Model Provider's credentials. The chat AI Model serves `/mistral/chat/completions`, and the embeddings AI Model serves `/mistral/embeddings`.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant M as Mistral API

    C->>K: POST /mistral/chat/completions (apikey header, model mistral-chat)
    activate K
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: AI Model resolves mistral-chat to CHAT_MODEL
    K->>M: Request with the Mistral key
    activate M
    M-->>K: Completion and token usage
    deactivate M
    K-->>C: OpenAI-format response with X-Kong-LLM-Model
    deactivate K
{% endmermaid %}
<!-- vale on -->

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. Both AI Models reference the same Key Auth AI Auth Strategy, which matches the `apikey` header to an AI Consumer credential and rejects unknown keys with `401`. The AI Consumer `rag-service` is the identity that analytics use. Each application gets its own AI Consumer, and deleting its credential revokes only that application.

The following settings configure the Key Auth AI Auth Strategy and the AI Consumer:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`key_names: [apikey]`"
    purpose: "The header that Kong reads the key from."
  - setting: "`key_in_header: true`, `key_in_query: false`, `key_in_body: false`"
    purpose: "Kong reads the key only from the header, so keys don't end up in URLs or request bodies."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the `apikey` header before it forwards the request, so Mistral never sees the AI Consumer key."
  - setting: "`ai_gateway_consumers[].credentials`"
    purpose: "The AI Consumer's `api-key` credential. The `api_key` field is write-only, so it reads `CONSUMER_API_KEY` with `!secret`."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Usage for each AI Consumer appears in {{site.konnect_short_name}} analytics.

### AI Model Provider and AI Models

The AI Model Provider holds the Mistral key. `type: mistral` selects Mistral's hosted API, so the configuration has no hostname. The two AI Models share the `/mistral` path, and each one has one capability and answers to one alias. Both targets reference the same AI Model Provider, so a key rotation is one change.

The following settings configure the AI Model Provider and the AI Models:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Provider)"
    purpose: "Sends `MISTRAL_TOKEN` in the `Authorization` header of each upstream request. The value is write-only, so it uses `!secret`."
  - setting: "`formats: [{type: openai}]`"
    purpose: "Both AI Models accept OpenAI-format requests, so clients use the OpenAI SDK without a Mistral library."
  - setting: "`capabilities`"
    purpose: "`generate` on the chat AI Model exposes `/chat/completions`. `embeddings` on the embeddings AI Model exposes `/embeddings`."
  - setting: "`access.auth_strategies`"
    purpose: "Each request must have a valid AI Consumer key."
  - setting: "`config.route.paths: [/mistral]`"
    purpose: "Both AI Models share one base path, so one `base_url` covers chat and embeddings."
  - setting: "`config.route.model`"
    purpose: "Kong reads the `model` field of the request body (`body_param: model`) and selects the AI Model whose value matches: `mistral-chat` or `mistral-embeddings`. An AI Model accepts one value, so each alias needs its own AI Model."
  - setting: "`targets[].name`"
    purpose: "The upstream model, from `CHAT_MODEL` or `EMBEDDINGS_MODEL`. Change it and re-apply to switch models without changing clients."
  - setting: "`targets[].config.format: openai`"
    purpose: "The request format that Kong uses with Mistral. The other value is `ollama`."
  - setting: "`config.response_streaming`"
    purpose: "`allow` on the chat AI Model passes streamed responses to the client. `deny` on the embeddings AI Model, because embeddings return one payload."
  - setting: "`config.max_request_body_size: 10485760`"
    purpose: "Accepts request bodies up to 10 MB, instead of the 8 MB default, for long conversations and large embedding batches."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads for audits. The default is `false`."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key and the Mistral key in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

## Variations and next steps

You can change or extend this configuration in the following ways:

{% table %}
columns:
  - title: Variation
    key: variation
  - title: How
    key: how
rows:
  - variation: "Switch the upstream model"
    how: "Change `CHAT_MODEL` or `EMBEDDINGS_MODEL` and re-apply the configuration from [Apply the Kong configuration](#apply-the-kong-configuration). Clients keep the same alias."
  - variation: "Add a model tier"
    how: "Add an AI Model on `/mistral` with its own alias, for example `mistral-large`, and a target for a larger Mistral model. Clients pick the tier with the `model` field."
  - variation: "Track cost"
    how: "Set `input_cost` and `output_cost` on each target, the cost for 1 million tokens. This cookbook hasn't confirmed against a live {{site.ai_gateway}} whether {{site.konnect_short_name}} reports Mistral cost without them. See [Model cost management](/ai-gateway/model-cost-management/)."
  - variation: "Budget each application"
    how: "Attach an [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to the AI Models to limit the tokens of each AI Consumer."
  - variation: "Add guardrails"
    how: "Attach the [AI Prompt Guard](/ai-gateway/policies/ai-prompt-guard/) Policy to filter prompts by pattern, or the [AI PII Sanitizer](/ai-gateway/policies/ai-sanitizer/) Policy to remove personal data before it reaches Mistral."
  - variation: "Fail over to another provider"
    how: "Add a second AI Model Provider and a second target to the chat AI Model, then set `config.balancer`. See [Load balancing](/ai-gateway/load-balancing/)."
  - variation: "Use a self-hosted Mistral endpoint"
    how: "Set `upstream_url` on the target's `config` to route to your own Mistral-compatible endpoint. The AI Model Provider and the aliases don't change."
  - variation: "Accept tokens from your identity provider"
    how: "Add an [OpenID Connect](/ai-gateway/openid-connect/) AI Auth Strategy to `access.auth_strategies`. An AI Model supports one Key Auth AI Auth Strategy and one OpenID Connect AI Auth Strategy at the same time."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='mistral-ai-with-kong-ai-gateway-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

If you created the Mistral API key only for this cookbook, delete it in the [Mistral console](https://console.mistral.ai/api-keys/).
