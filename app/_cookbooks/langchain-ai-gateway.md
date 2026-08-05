---
title: LangChain with Kong AI Gateway
description: Route LangChain (ChatOpenAI) requests through {{site.ai_gateway_name}} by overriding the base URL, with Consumer authentication and centrally managed provider credentials.
url: "/cookbooks/langchain-ai-gateway/"
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
  gateway: '3.6'
categories:
  - llm
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - key-auth
  - ai-proxy
requires_embeddings: false
providers:
  - openai

hint: "Requires an OpenAI API key and Python 3.10+."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. You will provision a recipe-scoped Control Plane and local Data Plane via the [quickstart script](https://get.konghq.com/quickstart).

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped Control Plane name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='langchain-ai-gateway-recipe'
           curl -Ls https://get.konghq.com/quickstart | bash -s -- -k $KONNECT_TOKEN --deck-output
           ```

           This provisions a Konnect Control Plane named `langchain-ai-gateway-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars. Paste those into your shell when prompted.
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
      icon_url: /assets/icons/openai.svg
      content: |
        This tutorial routes to OpenAI:

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Create a decK variable with the API key. {{site.base_gateway}} injects this credential into every upstream request, so your LangChain code never holds it:

           ```sh
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
    - title: Python 3.10+
      icon_url: /assets/icons/python.svg
      content: |
        The demo script requires Python 3.10 or later. Set up an isolated environment and install the LangChain OpenAI integration:

        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        pip install -U langchain-openai
        ```

overview: |
  Point your existing LangChain code at {{site.ai_gateway_name}} instead of directly at OpenAI. LangChain's `ChatOpenAI` accepts a `base_url`, and {{site.ai_gateway_name}} speaks the OpenAI wire format, so the only change to your application is the URL it talks to and the key it presents.

  By the end of this recipe you will have a single `/langchain` endpoint that authenticates each request against a Consumer credential, injects the OpenAI provider key server-side, and proxies the call. Your LangChain chains, agents, and tools keep working unchanged.
---

## The problem

Teams usually wire LangChain straight to a provider: import `langchain-openai`, put an OpenAI key in an environment variable, and call the API from application code. That is fine for one service, but it does not scale across a team.

- **Provider keys spread across every app.** Each service that runs a chain needs its own copy of the OpenAI key. A leaked key affects everyone, and rotating it means a coordinated redeploy of every service that holds it.
- **No identity at the edge.** With the app talking directly to OpenAI, there is nowhere to attribute usage to a team, enforce a per-app quota, or cut off a single misbehaving app without rotating the shared provider key.
- **Model choice is baked into code.** The upstream model is a string in application code. Swapping models, or absorbing a model version change, means editing and redeploying every chain.
- **No shared control point.** Retries, rate limits, logging, and cost attribution each get reimplemented per app, because there is no layer between LangChain and the provider where a platform team can apply policy once.

The root issue is coupling: LangChain code is bound to the provider's endpoint, the provider's credential, and the provider's model identifier.

## The solution

{{site.ai_gateway_name}} inserts a Service and Route between LangChain and OpenAI. LangChain still constructs an OpenAI-format request, but sends it to a Kong Route instead of `api.openai.com`. The Route authenticates the request against a Consumer credential, injects the real OpenAI key from Kong's configuration, and proxies the call. Your application only ever holds a Kong-issued key, and the model and provider credentials live in one place the platform team controls.

The only change in your LangChain code is the `base_url` and `api_key` you pass to `ChatOpenAI`.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as LangChain app
    participant K as {{site.ai_gateway_name}}
    participant O as OpenAI

    C->>K: POST /langchain/chat/completions (Authorization Bearer Kong key)
    activate K
    K->>K: key-auth validates key, attaches Consumer
    K->>K: ai-proxy strips client key, injects OpenAI credential
    K->>O: Forwarded chat completion request
    activate O
    O-->>K: Completion
    deactivate O
    K-->>C: OpenAI-format response
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
  - component: LangChain app
    responsibility: "Constructs OpenAI-format requests with `ChatOpenAI`, pointed at the Kong Route via `base_url`, authenticating with a Kong-issued key"
  - component: Key Auth Plugin
    responsibility: Validates the key against a registered Consumer credential and attaches the Consumer identity to the request
  - component: AI Proxy Plugin
    responsibility: "Strips the client key, injects the OpenAI provider credential, and proxies the request to OpenAI"
  - component: Kong Consumer
    responsibility: Identity attached to authenticated requests, used for rate limiting, ACLs, and analytics attribution
  - component: OpenAI
    responsibility: Processes the prompt and returns a completion
{% endtable %}

## How it works

A request from LangChain is processed in three stages: authentication, credential injection, and proxying.

1. LangChain sends a chat completion request (OpenAI format) to `/langchain` with an `Authorization: Bearer <key>` header. The `ChatOpenAI` client appends the `/chat/completions` path to the `base_url` you configure, exactly as it would against OpenAI.
2. The Key Auth Plugin reads the `Authorization` header and looks the key up in Kong's Consumer credential store. If the key is missing or unknown, Kong returns `401` before any upstream call. On a match, it attaches the matching Consumer to the request.
3. The AI Proxy Plugin strips the client's key, injects the OpenAI credential from its own configuration, and forwards the request to OpenAI. The response is returned to LangChain in the OpenAI format it already expects.

### Key Auth: authentication and the Bearer header

LangChain's `ChatOpenAI` serializes its `api_key` parameter as an `Authorization: Bearer <key>` header, the same as a direct OpenAI call. The Key Auth Plugin does an exact string match on the header value, so this recipe registers the Consumer credential *with* the `Bearer ` prefix and configures key-auth to read the `Authorization` header. That lets LangChain code pass a plain key (`api_key="my-api-key"`) while Kong matches the full `Bearer my-api-key` string.

#### Configuration details

```yaml
- name: key-auth
  config:
    key_names:
      - Authorization
    hide_credentials: true
```
{:.no-copy-code}

- **`key_names: [Authorization]`**: The header Kong reads the key from. It matches the exact header value, including the `Bearer ` prefix, against stored credentials.
- **`hide_credentials: true`**: Strips the `Authorization` header before the request continues, so the client's Kong key never leaks upstream. The AI Proxy Plugin then sets its own `Authorization` header with the OpenAI credential.

{:.info}
> For production identity, swap key-auth for [OpenID Connect](/plugins/openid-connect/) and map JWT claims to Consumers. Only the auth header your LangChain code sends changes; the rest of this recipe stays put. See the [claude-code-sso recipe](/cookbooks/claude-code-sso/) for an end-to-end example with Okta.

### AI Proxy: credential injection and proxying

The [AI Proxy](/plugins/ai-proxy/) Plugin holds the OpenAI credential and the upstream model, and proxies the request. Because it owns the provider credential, your LangChain app never holds an OpenAI key.

#### Configuration details

{%- raw %}
```yaml
- name: ai-proxy
  config:
    route_type: llm/v1/chat
    auth:
      header_name: Authorization
      header_value: ${{ env "DECK_OPENAI_TOKEN" }}
    model:
      provider: openai
      name: gpt-4o
```
{% endraw -%}
{:.no-copy-code}

- **`route_type: llm/v1/chat`**: Selects the chat-completions path. Kong accepts an OpenAI-format chat body and, for non-OpenAI providers, translates it to the provider's native format. For OpenAI it passes through.
- **`auth`**: Kong injects this credential into every upstream request. `DECK_OPENAI_TOKEN` holds the full `Bearer sk-...` value.
- **`model`**: The upstream provider and model. Change `name` and re-apply to swap the model without touching LangChain code.

{:.info}
> **Production credentials.** This recipe stores the Consumer key in Plugin config and the OpenAI key in an environment variable for simplicity. In production, use [Kong Vaults](/gateway/secrets-management/) to reference both from your secret manager instead.

## Apply the Kong configuration

The following configuration creates a {{site.base_gateway}} Service and Route at `/langchain`, attaches [key-auth](/plugins/key-auth/) to identify Consumers via the `Authorization` header, and attaches [ai-proxy](/plugins/ai-proxy/) to inject the OpenAI credential and proxy the request. All resources are scoped with `select_tags` and a kongctl `namespace` so they tear down cleanly.

First, adopt the quickstart Control Plane into a kongctl namespace:

```bash
kongctl adopt control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Apply the configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - langchain-ai-gateway-recipe
services:
- name: langchain-ai-gateway
  url: http://localhost
  routes:
  - name: langchain-ai-gateway
    paths:
    - /langchain
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: key-auth
    instance_name: langchain-ai-gateway-auth
    config:
      key_names:
      - Authorization
      hide_credentials: true
  - name: ai-proxy
    instance_name: langchain-ai-gateway-proxy
    config:
      route_type: llm/v1/chat
      auth:
        header_name: Authorization
        header_value: ${{ env "DECK_OPENAI_TOKEN" }}
      model:
        provider: openai
        name: gpt-4o
consumers:
- username: langchain-app
  keyauth_credentials:
  - key: Bearer my-api-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: langchain-ai-gateway-recipe
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

## Try it out

The demo script runs three LangChain calls against the Route: a basic completion, a streamed completion, and a tool-calling request. It then presents an invalid key to show Kong rejecting the request with `401` before any upstream call.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""LangChain through Kong AI Gateway."""

import os

from langchain_openai import ChatOpenAI
from langchain_core.tools import tool

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")

# base_url points at the Kong Route. LangChain appends /chat/completions.
# api_key is sent as "Authorization: Bearer my-api-key", which Kong's
# key-auth matches against the registered Consumer credential.
llm = ChatOpenAI(
    base_url=f"{PROXY_URL}/langchain",
    model="gpt-4o",
    api_key="my-api-key",
)


def basic():
    print("\n== Basic completion ==")
    response = llm.invoke("What is the capital of France?")
    print(response.content)


def streaming():
    print("\n== Streaming ==")
    for chunk in llm.stream("Write a one-sentence haiku about gateways."):
        print(chunk.content, end="", flush=True)
    print()


def tool_calling():
    print("\n== Tool calling ==")

    @tool
    def get_weather(location: str) -> str:
        """Get the current weather for a location."""
        return f"Sunny, 72F in {location}"

    model_with_tools = llm.bind_tools([get_weather])
    response = model_with_tools.invoke("What's the weather in NYC?")
    print("tool calls:", response.tool_calls)


def rejected():
    print("\n== Invalid key (Kong rejects before reaching OpenAI) ==")
    bad_llm = ChatOpenAI(
        base_url=f"{PROXY_URL}/langchain",
        model="gpt-4o",
        api_key="not-a-real-key",
    )
    try:
        bad_llm.invoke("This should never reach OpenAI.")
    except Exception as e:
        print(f"blocked: {e}")


if __name__ == "__main__":
    basic()
    streaming()
    tool_calling()
    rejected()
EOF
```
{:.collapsible}

Run it:

```bash
python demo.py
```

The response should look like this:

```text
== Basic completion ==
The capital of France is Paris.

== Streaming ==
Gates open, tokens flow, requests find their path home.

== Tool calling ==
tool calls: [{'name': 'get_weather', 'args': {'location': 'NYC'}, 'id': 'call_...', 'type': 'tool_call'}]

== Invalid key (Kong rejects before reaching OpenAI) ==
blocked: Error code: 401 - {'message': 'No credentials found for given apikey'}
```
{:.no-copy-code}

### What happened

1. **LangChain talked to Kong, not OpenAI.** Setting `base_url` to the Kong Route is the only change from a direct OpenAI integration. `ChatOpenAI` appended `/chat/completions` and sent an ordinary OpenAI-format request.
2. **Chains, streaming, and tools work unchanged.** `invoke`, `stream`, and `bind_tools` behave exactly as they do against OpenAI. Whether tool calling succeeds depends on the upstream model, the same as calling that model directly.
3. **Kong enforced auth before any upstream call.** The invalid-key request was rejected by key-auth in a few milliseconds. OpenAI was never contacted and no provider quota was consumed.
4. **The OpenAI key never left Kong.** LangChain only ever held the Kong-issued key `my-api-key`. The `Bearer sk-...` provider credential lived in `DECK_OPENAI_TOKEN` on the Kong side and was injected by the AI Proxy Plugin.

### Explore in Konnect

Open [Konnect](https://cloud.konghq.com/) and navigate to **API Gateway** → **Gateways** → **langchain-ai-gateway-recipe**:

- **Gateway services** → **langchain-ai-gateway**: the Service, with tabs for Configuration, Routes, Plugins, and Analytics.
  - **Plugins** tab: the `langchain-ai-gateway-auth` (key-auth) and `langchain-ai-gateway-proxy` (ai-proxy) instances.
- **Consumers** → **langchain-app**: the Consumer the key maps to.

The **Analytics** tab shows request counts, error rates, latency, and token usage for traffic through this recipe.

## Variations and next steps

**Use with LangChain agents.** `create_agent` takes a model instance, so the `ChatOpenAI` client above works unchanged:

```python
from langchain.agents import create_agent

agent = create_agent(model=llm, tools=[get_weather])
result = agent.invoke({"messages": [{"role": "user", "content": "What's the weather in NYC?"}]})
```

**Async.** The async methods (`ainvoke`, `astream`) work the same way against the Route, since they hit the same endpoint with the same auth.

**Embeddings.** LangChain's `OpenAIEmbeddings` uses a different route type (`llm/v1/embeddings`, available in {{site.base_gateway}} 3.11+). Add a second Route and AI Proxy instance for embeddings, then point `OpenAIEmbeddings` at it. The `genai_category: text/embeddings` setting is required so the plugin treats the route as embeddings rather than chat:

{%- raw %}
```yaml
- name: langchain-ai-gateway-embeddings
  paths:
  - /langchain-embeddings
  plugins:
  - name: ai-proxy
    config:
      genai_category: text/embeddings
      route_type: llm/v1/embeddings
      auth:
        header_name: Authorization
        header_value: ${{ env "DECK_OPENAI_TOKEN" }}
      model:
        provider: openai
        name: text-embedding-3-small
```
{% endraw -%}
{:.no-copy-code}

```python
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings(
    base_url=f"{PROXY_URL}/langchain-embeddings",
    model="text-embedding-3-small",
    api_key="my-api-key",
)
vectors = embeddings.embed_documents(["Hello world", "Goodbye world"])
```

**Add per-Consumer rate limits.** With key-auth mapping requests to Consumers, attach [ai-rate-limiting-advanced](/plugins/ai-rate-limiting-advanced/) to apply token quotas per Consumer. See the [llm-cost-optimization recipe](/cookbooks/llm-cost-optimization/).

**Route across providers or models.** To pick between models per request, swap [ai-proxy](/plugins/ai-proxy/) for [ai-proxy-advanced](/plugins/ai-proxy-advanced/) and configure targets with `model_alias`. See the [basic-llm-routing recipe](/cookbooks/basic-llm-routing/).

## Cleanup

The recipe scoped all resources with `select_tags` and a kongctl `namespace`, so this teardown removes only this recipe's configuration:

```bash
export KONNECT_CONTROL_PLANE_NAME='langchain-ai-gateway-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```
