---
title: Basic LLM Routing
description: Route requests to any supported LLM provider through {{site.ai_gateway_name}} with AI Consumer authentication and per-request model selection.
url: "/cookbooks/basic-llm-routing/"
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
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - key-auth
  - ai-model
  - ai-model-provider
requires_embeddings: false
providers:
  - openai
  - anthropic
  - bedrock
  - azure
  - gemini
  - mistral

hint: "Requires API credentials for your chosen LLM provider and Python 3.11+."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. You'll provision a recipe-scoped {{site.ai_gateway}} and local data plane via the [quickstart script](https://get.konghq.com/ai).

        1. Create a new personal access token by opening the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. You reuse the same token later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='basic-llm-routing-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `basic-llm-routing-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
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
        Pick the provider you want to route to and export its credentials. Every apply tab below reuses the same credentials.

        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        This tutorial uses OpenAI:

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key as an environment variable:

           ```sh
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
        {% endnavtab %}
        {% navtab "Anthropic" %}
        This tutorial uses Anthropic:

        1. [Create an Anthropic account](https://console.anthropic.com/).
        1. [Get an API key](https://console.anthropic.com/settings/keys).
        1. Export the API key and the [Messages API schema version](https://docs.claude.com/en/api/versioning) Kong should send upstream on every request:

           ```sh
           export DECK_ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
           export DECK_ANTHROPIC_VERSION='2023-06-01'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        This tutorial uses AWS Bedrock:

        1. Ensure you have an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled.
        1. Export your AWS credentials:

           ```sh
           export DECK_AWS_ACCESS_KEY_ID='your-access-key'
           export DECK_AWS_SECRET_ACCESS_KEY='your-secret-key'
           export DECK_AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% navtab "Azure OpenAI" %}
        This tutorial uses Azure OpenAI. Azure binds each deployment to a single model at deployment time, and the deployment ID determines the upstream model ([Azure OpenAI REST API reference](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference)). To demonstrate alias routing across two model tiers, you need **two** Azure deployments: one for the `fast` alias and one for `smart`.

        1. [Create an Azure OpenAI resource](https://portal.azure.com/#create/Microsoft.CognitiveServicesOpenAI).
        1. Deploy two models in your resource (for example, `gpt-4o-mini` for the fast tier and `gpt-4o` for the smart tier). Note both deployment IDs, plus your instance name and API version.
        1. Export your credentials:

           ```sh
           export DECK_AZURE_API_KEY='your-azure-api-key'
           export DECK_AZURE_INSTANCE='your-instance-name'
           export DECK_AZURE_DEPLOYMENT_ID_1='your-fast-deployment-id'    # the "fast" alias target
           export DECK_AZURE_DEPLOYMENT_ID_2='your-smart-deployment-id'   # the "smart" alias target
           export DECK_AZURE_API_VERSION='YOUR-API-VERSION'  # check Azure docs for current version
           ```

           If you only have one deployment available, point both variables at the same value. The recipe still applies, but both aliases route to the same upstream model.
        {% endnavtab %}
        {% navtab "Google Gemini" %}
        This tutorial uses Google Gemini via Vertex AI:

        1. [Create a Google Cloud project](https://console.cloud.google.com/) with Vertex AI enabled.
        1. Create a service account and mount the JSON key file in your Kong container.
        1. Export your project details:

           ```sh
           export DECK_GCP_API_ENDPOINT='your-api-endpoint'
           export DECK_GCP_PROJECT_ID='your-project-id'
           export DECK_GCP_LOCATION_ID='us-central1'
           ```
        {% endnavtab %}
        {% navtab "Mistral" %}
        This tutorial uses Mistral:

        1. [Create a Mistral account](https://console.mistral.ai/).
        1. [Get an API key](https://console.mistral.ai/api-keys/).
        1. Export the API key as an environment variable:

           ```sh
           export DECK_MISTRAL_TOKEN='Bearer your-mistral-key'
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
  Route chat requests to any supported LLM provider through {{site.ai_gateway_name}}, with per-app
  AI Consumer authentication and per-request model selection. By the end of this recipe, you'll have
  a `/basic-llm-routing` endpoint that accepts OpenAI-format requests carrying a per-consumer
  API key, validates the key against an AI Consumer credential in Kong, and routes the request to
  one of two upstream models based on the `model` field in the request body.
---

## The problem

Most teams start by integrating LLM providers directly: import the provider's SDK, embed API keys in
environment variables, and call the provider's API from application code. This works for a single
service talking to a single provider, but breaks down as usage grows.

- **Provider credential blast radius.** Every service that makes LLM calls needs its own copy of the
  provider's API key. A leaked key affects every team using the provider, and rotating a key requires
  coordinated redeploys across every service that holds it. There is no per-app or per-team
  credential to revoke independently.
- **No client identity at the edge.** Without an authentication layer between the client and the
  provider, the gateway can't attribute usage to a tenant, enforce per-tenant quotas, or revoke
  access for a single misbehaving app.
- **Provider-specific auth and request formats.** Each provider uses a different authentication
  mechanism: OpenAI expects `Authorization: Bearer sk-...`, Anthropic uses `x-api-key: ...`, AWS
  Bedrock requires SigV4 request signing, Azure uses `api-key: ...` with instance-specific endpoints.
  Beyond auth, each provider has its own request and response body shape. Switching providers means
  rewriting auth and translation logic, not swapping a key.
- **Coarse model selection.** Most production workloads need to route different requests to different
  models, a cheap model for simple completions and a stronger model for hard ones, but provider SDKs
  expose this only as a per-request `model` parameter pointing at a provider-specific identifier.
  Hardcoding model IDs across application code makes it hard to swap models or absorb model version
  changes without coordinated redeploys.

The root issue is coupling. Application code is bound to provider auth, provider request format, and
provider model identifiers, and there is no shared layer where a platform team can enforce identity,
quotas, or routing policy.

## The solution

{{site.ai_gateway_name}} inserts an AI Model between clients and providers, backed by an AI Model Provider that holds the upstream credentials. A Key Auth AI Auth Strategy authenticates each request against a per-app credential, the AI Model picks the upstream target based on a `model` field in the request body so clients can choose between tiers without changing endpoints, and the AI Model Provider injects the provider's credentials and translates request/response formats so client apps never hold a provider key. The result is one endpoint that gives the platform team a place to enforce identity, routing, and credential policy without coupling client code to any provider.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant L as LLM Provider

    C->>K: POST /basic-llm-routing (apikey, model: fast or smart)
    activate K
    K->>K: key-auth Auth Strategy: validate apikey, attach Consumer
    K->>K: AI Model: match model to a route.model.values alias
    K->>K: AI Model Provider: inject provider auth
    K->>L: Forwarded request (translated to provider native format)
    activate L
    L-->>K: Native response
    deactivate L
    K-->>C: OpenAI-format response (+ X-Kong-LLM-Model)
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
    responsibility: "Sends OpenAI-format requests with an `apikey` header that identifies the AI Consumer, plus `model: fast` or `model: smart`"
  - component: Key Auth AI Auth Strategy
    responsibility: Looks up the API key against a registered AI Consumer credential, attaches the matching AI Consumer to the request
  - component: AI Model
    responsibility: "Matches the request's `model` field against its alias, applies routing and streaming settings, and selects the target that serves the request"
  - component: AI Model Provider
    responsibility: Holds the upstream provider credentials, injects them into the request, and translates the request/response body to and from the provider's native format
  - component: AI Consumer
    responsibility: Represents the identity attached to authenticated requests, used for rate limiting, ACLs, and analytics attribution
  - component: LLM provider
    responsibility: Processes the prompt and returns a completion
{% endtable %}

## How it works

Kong processes each request in three stages: authentication, routing, and proxying.

1. A client sends a chat completion request (OpenAI format) to `/basic-llm-routing` with an `apikey` header and a `model` field set to either `fast` or `smart`.
2. The Key Auth strategy reads the `apikey` header and looks the key up in Kong's AI Consumer credential store. If the key is missing or unknown, Kong short-circuits with `401` before any upstream call. On a match, it attaches the matching AI Consumer to the request, which is what downstream policies and analytics use to attribute usage.
3. Kong matches the request's `model` field against the AI Models attached to this route: one AI Model answers to `fast`, the other to `smart`. Each is a separate entity because an AI Model accepts exactly one alias in `route.model.values`.
4. The matched AI Model's target references an AI Model Provider, which supplies the upstream credentials for the selected provider tab. Kong strips the client's `apikey` header, injects the provider credentials, and (if the upstream uses a different format) translates the OpenAI-format body to the provider's native format.
5. Kong forwards the request to the LLM provider's API endpoint, normalizes the response back to OpenAI format, and returns it to the client with `X-Kong-LLM-Model` (the upstream model that served the request) and latency headers attached.

### Key Auth: API key authentication and AI Consumer mapping

Authentication in {{site.ai_gateway_name}} 2.0 is an AI Auth Strategy, not a policy. AI Policies are reserved for AI-specific behavior like guardrails and rate limiting. The Key Auth strategy sits in front of routing and gates every request. Each AI Consumer holds one or more API key credentials. When a request arrives, the strategy reads the configured header (`apikey`), looks the key up in Kong's AI Consumer credential store, and attaches the matching AI Consumer identity to the request. Downstream policies like rate limiters and analytics use that identity to attribute usage. The pattern scales naturally to multi-tenant scenarios: add an AI Consumer per app or per team, each with its own key.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_auth_strategies:
  - ref: basic-llm-routing-auth
    type: key-auth
    display_name: "basic-llm-routing key auth"
    config:
      key_names:
        - apikey
      hide_credentials: true

ai_gateway_consumers:
  - ref: basic-llm-routing-consumer
    name: basic-llm-routing-consumer
    display_name: "basic-llm-routing demo consumer"
    type: api-key
    credentials:
      - ref: basic-llm-routing-credential
        name: basic-llm-routing-credential
        display_name: "basic-llm-routing demo API key"
        type: api-key
        api_key: !secret {source: !env CONSUMER_API_KEY}
```
{% endraw -%}
{:.no-copy-code}

**`key_names: [apikey]`**. The headers (or query parameters) checked for the API key. The recipe uses `apikey` because this check performs an exact string match on the header value and doesn't inspect `Authorization` for Bearer tokens. The OpenAI SDK's `api_key` field always serializes as `Authorization: Bearer <key>`, which Kong would read as the literal string `Bearer <key>` and fail to match against any stored credential. The "Try it out" section below points at a pre-function pattern that bridges the SDK's Bearer token to the `apikey` header server-side.

**`hide_credentials: true`**. Strips the API key from the request before forwarding upstream. The provider never sees the AI Consumer's API key.

**`api_key` is write-only.** An AI Consumer credential's `api_key` field must be a `!secret` reference. Kong rejects a plain string here, even for a demo value like this recipe's. You export `CONSUMER_API_KEY` once in [Apply the Kong configuration](#apply-the-kong-configuration) and reuse it across every provider tab.

**The AI Consumer and its credential are separate entities from the AI Auth Strategy.** An AI Consumer (`type: api-key`) represents the caller's identity; its nested `credentials` list holds the actual key values checked against incoming requests. Every AI Model in this recipe references the same `basic-llm-routing-auth` strategy via `access.auth_strategies`, so one AI Consumer credential authenticates against either alias.

**Anonymous fallback.** Set `anonymous: <consumer-id>` on the Key Auth AI Auth Strategy to let unauthenticated requests fall through to a designated "anonymous" AI Consumer with their own restricted policies, instead of returning `401`. Anonymous fallback is useful for public or free-tier endpoints. See `kongctl explain ai_gateway_auth_strategies --extended` for the full set of options.

**Scaling to a real IdP.** When the platform is ready for end-user identity instead of static API keys, swap the Key Auth AI Auth Strategy for an OpenID Connect strategy and map JWT claims to AI Consumers. Application code only changes the auth header it sends; the rest of this recipe (model aliases, AI Model targets, AI Consumer mappings) stays put. See the [Claude Code SSO recipe](/cookbooks/claude-code-sso/) for an end-to-end example with Okta.

### AI Model and AI Model Provider: alias routing and provider translation

An AI Model Provider holds the credentials for one upstream account; an AI Model routes requests to targets that reference an AI Model Provider. The recipe defines one AI Model Provider per tab and two Models, `basic-llm-routing-fast` and `basic-llm-routing-smart`, both sharing the `/basic-llm-routing` path but each declaring a different value in `config.route.model.values`. When a request arrives, Kong reads the `model` field from the request body and dispatches to whichever Model declares that value, then that Model's single target uses the AI Model Provider's credentials and format translation. This combination replaces what would otherwise require per-provider SDKs, hand-rolled credential management, and per-model client logic.

#### Configuration details

The following example shows the OpenAI tab's configuration. Every provider tab follows the same shape; only the AI Model Provider's `type`/`config.auth` and each target's `config` differ:

{%- raw %}
```yaml
ai_gateway_model_providers:
  - ref: basic-llm-routing-provider
    type: openai
    display_name: "basic-llm-routing"
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env DECK_OPENAI_TOKEN}

ai_gateway_models:
  - ref: basic-llm-routing-fast
    type: model
    display_name: "basic-llm-routing (fast)"
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - basic-llm-routing-auth
    config:
      max_request_body_size: 10485760
      response_streaming: allow
      logging:
        payloads: true
      route:
        paths:
          - /basic-llm-routing
        model:
          body_param: model
          values:
            - fast
    targets:
      - name: !env CHAT_MODEL_1
        provider: basic-llm-routing-provider
        config:
          type: openai
```
{% endraw -%}
{:.no-copy-code}

**`config.auth`** (on the AI Model Provider). Kong holds provider credentials here and injects them into every upstream request that routes through this AI Model Provider.

**`formats: [{type: openai}]`**. Declares the wire format this Model accepts and normalizes responses to. Kong accepts an OpenAI-format chat-completion body and converts it to whatever the upstream provider expects (Anthropic's `messages` API, Bedrock's `invoke-model` body, etc.).

**`route.model.values`**. The alias this Model answers to. When the request body's `model` field equals this value, Kong routes to this Model. An AI Model accepts exactly one alias, so a second tier needs a second Model entity, as this recipe does for `fast` and `smart`.

**`targets[].name`**. The upstream model identifier. Change it and re-apply to swap models without changing client code.

**`targets[].config`**. Provider-specific target fields, for example Bedrock's `region` or Azure's `deployment_id`/`api_version`, live here, alongside the `type` discriminator matching the AI Model Provider.

**`max_request_body_size`** and **`response_streaming`**. The recipe sets a 10 MB request limit (large enough for typical conversation contexts and modest RAG injections) and allows streaming responses (the natural choice for interactive chat). Tighten or relax both based on the workload you expect.

**Alternative configurations worth knowing about:**

- **Native provider formats.** The recipe uses `formats: [{type: openai}]`, which accepts OpenAI-format requests and normalizes all provider responses back to OpenAI format. Set the format to a provider's native format (for example, `anthropic`) to pass requests through without transformation. Native format only supports providers that speak that format, so you can't route across providers with different native formats on a single Model. See the [AI Model entity reference](/ai-gateway/entities/ai-model/) for the supported formats.
- **Routing strategies beyond aliases.** This recipe routes by the `model` field in the body. The same entity also supports routing by request header, by path, and by load-balancing across multiple targets on one Model using `config.balancer`. See the [AI Model entity reference](/ai-gateway/entities/ai-model/) for the full set of balancer algorithms and routing strategies.
- **Additional capabilities.** A single AI Model declares one or more `capabilities` (`generate`, `embeddings`, and others). This recipe uses `generate` for chat completions; see the [AI Model entity reference](/ai-gateway/entities/ai-model/) for the current list.

{:.info}
> **Production credentials.** This recipe stores the AI Consumer's demo API key and the LLM provider credentials directly in configuration and environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference both from your preferred secret manager (AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, Azure Key Vault) instead.

### Example response

The same OpenAI-format request goes through Kong. The header that proves alias routing happened is `X-Kong-LLM-Model`, which echoes the upstream model the request was routed to. Two requests with the same body but different `model` values land on different upstream models:

Request body (identical for both calls, only the `model` field changes):

```json
{
  "model": "fast",
  "messages": [
    { "role": "user", "content": "What is the capital of France?" }
  ]
}
```
{:.no-copy-code}

Response headers from the `model: "fast"` call:

```text
HTTP/1.1 200 OK
X-Kong-LLM-Model: openai/gpt-4o-mini
X-Kong-Upstream-Latency: 312
X-Kong-Proxy-Latency: 6
```
{:.no-copy-code}

Response headers from the `model: "smart"` call:

```text
HTTP/1.1 200 OK
X-Kong-LLM-Model: openai/gpt-4o
X-Kong-Upstream-Latency: 891
X-Kong-Proxy-Latency: 6
```
{:.no-copy-code}

Kong adds the following response headers:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-Kong-LLM-Model`"
    description: "Upstream model that served the request, prefixed with the provider name and resolved from the matched AI Model target"
  - header: "`X-Kong-Upstream-Latency`"
    description: Time (ms) Kong spent waiting for the provider to respond
  - header: "`X-Kong-Proxy-Latency`"
    description: Time (ms) Kong spent processing the request (excluding upstream)
{% endtable %}

Kong attaches `X-Consumer-Username` and related headers to the **upstream** request (so the LLM provider sees who's calling) but doesn't echo them back to the downstream client. Per-consumer attribution shows up in {{site.konnect_short_name}}'s analytics views. See "Explore in {{site.konnect_short_name}}" below.

## Apply the Kong configuration

The following configuration creates an AI Model Provider holding your chosen provider's credentials, a Key Auth AI Auth Strategy and an AI Consumer with a demo API key, and two AI Models (`fast` and `smart`) that route to that AI Model Provider. A kongctl namespace scopes every resource, so you can tear the configuration down cleanly without affecting other configurations on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on federated configuration management.

First, adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply commands can manage it.

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

The provider credentials come from the environment variables you set in the prerequisites. Each tab below only sets the model env vars (which are recipe-specific) and runs the apply.

{% navtabs "Providers" %}
{% tab OpenAI %}

Export the model env vars:

```bash
export CHAT_MODEL_1='gpt-4o-mini'  # the "fast" alias
export CHAT_MODEL_2='gpt-4o'        # the "smart" alias
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
ai_gateway_model_providers:
- ref: basic-llm-routing-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-provider
  display_name: basic-llm-routing
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'DECK_OPENAI_TOKEN'}
ai_gateway_auth_strategies:
- ref: basic-llm-routing-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-auth
  display_name: basic-llm-routing key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: basic-llm-routing-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-consumer
  display_name: basic-llm-routing demo consumer
  type: api-key
  credentials:
  - ref: basic-llm-routing-credential
    name: basic-llm-routing-credential
    display_name: basic-llm-routing demo API key
    type: api-key
    api_key: demo-api-key
ai_gateway_models:
- ref: basic-llm-routing-fast
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-fast
  display_name: basic-llm-routing (fast)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - fast
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: basic-llm-routing-provider
    config:
      type: openai
- ref: basic-llm-routing-smart
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-smart
  display_name: basic-llm-routing (smart)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - smart
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: basic-llm-routing-provider
    config:
      type: openai
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Anthropic %}

Export the model env vars:

```bash
export CHAT_MODEL_1='claude-haiku-4-5-20251001'      # the "fast" alias
export CHAT_MODEL_2='claude-sonnet-4-5-20250929'      # the "smart" alias
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
ai_gateway_model_providers:
- ref: basic-llm-routing-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-provider
  display_name: basic-llm-routing
  type: anthropic
  config:
    auth:
      type: basic
      headers:
      - name: x-api-key
        value: !secret {source: !env 'DECK_ANTHROPIC_TOKEN'}
ai_gateway_auth_strategies:
- ref: basic-llm-routing-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-auth
  display_name: basic-llm-routing key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: basic-llm-routing-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-consumer
  display_name: basic-llm-routing demo consumer
  type: api-key
  credentials:
  - ref: basic-llm-routing-credential
    name: basic-llm-routing-credential
    display_name: basic-llm-routing demo API key
    type: api-key
    api_key: demo-api-key
ai_gateway_models:
- ref: basic-llm-routing-fast
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-fast
  display_name: basic-llm-routing (fast)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - fast
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: basic-llm-routing-provider
    config:
      version: !env 'DECK_ANTHROPIC_VERSION'
      type: anthropic
- ref: basic-llm-routing-smart
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-smart
  display_name: basic-llm-routing (smart)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - smart
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: basic-llm-routing-provider
    config:
      version: !env 'DECK_ANTHROPIC_VERSION'
      type: anthropic
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab AWS Bedrock %}

Export the model env vars:

```bash
export CHAT_MODEL_1='amazon.nova-lite-v1:0'                                   # the "fast" alias
export CHAT_MODEL_2='global.anthropic.claude-sonnet-4-5-20250929-v1:0'        # the "smart" alias
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
ai_gateway_model_providers:
- ref: basic-llm-routing-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-provider
  display_name: basic-llm-routing
  type: bedrock
  config:
    auth:
      type: aws
      access_key_id: !env 'DECK_AWS_ACCESS_KEY_ID'
      secret_access_key: !secret {source: !env 'DECK_AWS_SECRET_ACCESS_KEY'}
ai_gateway_auth_strategies:
- ref: basic-llm-routing-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-auth
  display_name: basic-llm-routing key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: basic-llm-routing-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-consumer
  display_name: basic-llm-routing demo consumer
  type: api-key
  credentials:
  - ref: basic-llm-routing-credential
    name: basic-llm-routing-credential
    display_name: basic-llm-routing demo API key
    type: api-key
    api_key: demo-api-key
ai_gateway_models:
- ref: basic-llm-routing-fast
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-fast
  display_name: basic-llm-routing (fast)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - fast
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: basic-llm-routing-provider
    config:
      region: !env 'DECK_AWS_REGION'
      type: bedrock
- ref: basic-llm-routing-smart
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-smart
  display_name: basic-llm-routing (smart)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - smart
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: basic-llm-routing-provider
    config:
      region: !env 'DECK_AWS_REGION'
      type: bedrock
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Azure OpenAI %}

Export the model env vars. Kong records the model names in the `X-Kong-LLM-Model` header for analytics, but the deployment IDs you exported in the AI Credentials prereq drive Azure's upstream selection:

```bash
export CHAT_MODEL_1='gpt-4o-mini'  # the "fast" alias. must match the model in DECK_AZURE_DEPLOYMENT_ID_1
export CHAT_MODEL_2='gpt-4o'        # the "smart" alias. must match the model in DECK_AZURE_DEPLOYMENT_ID_2
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
ai_gateway_model_providers:
- ref: basic-llm-routing-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-provider
  display_name: basic-llm-routing
  type: azure
  config:
    auth:
      type: basic
      headers:
      - name: api-key
        value: !secret {source: !env 'DECK_AZURE_API_KEY'}
    service: azure-openai
    instance: !env 'DECK_AZURE_INSTANCE'
ai_gateway_auth_strategies:
- ref: basic-llm-routing-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-auth
  display_name: basic-llm-routing key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: basic-llm-routing-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-consumer
  display_name: basic-llm-routing demo consumer
  type: api-key
  credentials:
  - ref: basic-llm-routing-credential
    name: basic-llm-routing-credential
    display_name: basic-llm-routing demo API key
    type: api-key
    api_key: demo-api-key
ai_gateway_models:
- ref: basic-llm-routing-fast
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-fast
  display_name: basic-llm-routing (fast)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - fast
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: basic-llm-routing-provider
    config:
      api_version: !env 'DECK_AZURE_API_VERSION'
      deployment_id: !env 'DECK_AZURE_DEPLOYMENT_ID_1'
      type: azure
- ref: basic-llm-routing-smart
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-smart
  display_name: basic-llm-routing (smart)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - smart
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: basic-llm-routing-provider
    config:
      api_version: !env 'DECK_AZURE_API_VERSION'
      deployment_id: !env 'DECK_AZURE_DEPLOYMENT_ID_2'
      type: azure
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Google Gemini %}

Export the model env vars:

```bash
export CHAT_MODEL_1='gemini-2.0-flash'  # the "fast" alias
export CHAT_MODEL_2='gemini-1.5-pro'    # the "smart" alias
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
ai_gateway_model_providers:
- ref: basic-llm-routing-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-provider
  display_name: basic-llm-routing
  type: gemini
  config:
    auth:
      type: gcp
      use_gcp_service_account: true
ai_gateway_auth_strategies:
- ref: basic-llm-routing-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-auth
  display_name: basic-llm-routing key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: basic-llm-routing-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-consumer
  display_name: basic-llm-routing demo consumer
  type: api-key
  credentials:
  - ref: basic-llm-routing-credential
    name: basic-llm-routing-credential
    display_name: basic-llm-routing demo API key
    type: api-key
    api_key: demo-api-key
ai_gateway_models:
- ref: basic-llm-routing-fast
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-fast
  display_name: basic-llm-routing (fast)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - fast
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: basic-llm-routing-provider
    config:
      gcp_environment:
        api_endpoint: !env 'DECK_GCP_API_ENDPOINT'
        project_id: !env 'DECK_GCP_PROJECT_ID'
        location_id: !env 'DECK_GCP_LOCATION_ID'
      type: gemini
- ref: basic-llm-routing-smart
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-smart
  display_name: basic-llm-routing (smart)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - smart
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: basic-llm-routing-provider
    config:
      gcp_environment:
        api_endpoint: !env 'DECK_GCP_API_ENDPOINT'
        project_id: !env 'DECK_GCP_PROJECT_ID'
        location_id: !env 'DECK_GCP_LOCATION_ID'
      type: gemini
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Mistral %}

Export the model env vars:

```bash
export CHAT_MODEL_1='mistral-small-latest'  # the "fast" alias
export CHAT_MODEL_2='mistral-large-latest'   # the "smart" alias
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
ai_gateway_model_providers:
- ref: basic-llm-routing-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-provider
  display_name: basic-llm-routing
  type: mistral
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'DECK_MISTRAL_TOKEN'}
ai_gateway_auth_strategies:
- ref: basic-llm-routing-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-auth
  display_name: basic-llm-routing key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: basic-llm-routing-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-consumer
  display_name: basic-llm-routing demo consumer
  type: api-key
  credentials:
  - ref: basic-llm-routing-credential
    name: basic-llm-routing-credential
    display_name: basic-llm-routing demo API key
    type: api-key
    api_key: demo-api-key
ai_gateway_models:
- ref: basic-llm-routing-fast
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-fast
  display_name: basic-llm-routing (fast)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - fast
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: basic-llm-routing-provider
    config:
      format: openai
      type: mistral
- ref: basic-llm-routing-smart
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-smart
  display_name: basic-llm-routing (smart)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - smart
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: basic-llm-routing-provider
    config:
      format: openai
      type: mistral
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% endnavtabs %}

## Try it out

The demo script makes three calls. The first two send the same prompt with different `model` values (`fast` then `smart`) and print the `X-Kong-LLM-Model` header so you can confirm Kong routed each request to a different upstream model. The third call presents an invalid API key and shows Kong rejecting it with `401` before any upstream call.

{:.info}
> The demo passes the API key via `default_headers` because the OpenAI SDK reserves `api_key` for the `Authorization: Bearer` header. To let clients pass the key through `api_key` directly, attach a [Pre-Function](/ai-gateway/policies/pre-function/) Policy that copies the Bearer token to the `apikey` header server-side.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""Basic LLM routing demo. See README for context."""

import os
import sys
import time

from openai import APIStatusError, OpenAI

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
API_KEY = "demo-api-key"
PROMPT = "What is the capital of France?"

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
    """Construct an OpenAI client that sends the given API key in the apikey header."""
    return OpenAI(
        base_url=f"{PROXY_URL}/basic-llm-routing",
        api_key="unused",  # required by the SDK; Kong reads the apikey header instead
        default_headers={"apikey": api_key},
    )


def call(client: OpenAI, model_alias: str) -> None:
    """Send one chat request and print the model Kong routed it to."""
    print(f"\n{BOLD('[REQUEST]')} model={model_alias!r} prompt={PROMPT!r}")
    start_ms = round(time.time() * 1000)
    try:
        raw = client.chat.completions.with_raw_response.create(
            model=model_alias,
            messages=[{"role": "user", "content": PROMPT}],
        )
    except APIStatusError as e:
        elapsed_ms = round(time.time() * 1000) - start_ms
        print(f"{RED(BOLD('[BLOCKED]'))} {RED(BOLD(str(e.status_code)))} {e.message}  ({elapsed_ms}ms)")
        return

    elapsed_ms = round(time.time() * 1000) - start_ms
    completion = raw.parse()
    upstream_latency = raw.headers.get("x-kong-upstream-latency", ".")
    proxy_latency = raw.headers.get("x-kong-proxy-latency", ".")
    upstream_model = raw.headers.get("x-kong-llm-model", ".")
    answer = completion.choices[0].message.content

    print(f"[RESPONSE] {DIM(answer)}")
    # Routed-to model is the headline of this demo — make it pop.
    print(f"{GREEN(BOLD('[ROUTED TO]'))} alias={model_alias!r} -> upstream model={CYAN(BOLD(upstream_model))}")
    print(f"[LATENCY] {DIM(f'upstream={upstream_latency}ms  proxy={proxy_latency}ms  total={elapsed_ms}ms')}")


def section(title: str) -> None:
    bar = "=" * 70
    print(f"\n{bar}\n{BOLD(title)}\n{bar}")


def main() -> None:
    section("1. Same client, same prompt, two model aliases")
    client = make_client(API_KEY)
    call(client, "fast")
    call(client, "smart")

    section("2. Invalid API key. Kong rejects before reaching the upstream provider")
    bad_client = make_client("not-a-real-key")
    call(bad_client, "fast")

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

Example output (using the OpenAI tab's model env vars):

```text
======================================================================
1. Same client, same prompt, two model aliases
======================================================================

[REQUEST] model='fast' prompt='What is the capital of France?'
[RESPONSE] The capital of France is Paris.
[ROUTED TO] alias='fast' -> upstream model='openai/gpt-4o-mini'
[LATENCY] upstream=1311ms  proxy=12ms  total=1488ms

[REQUEST] model='smart' prompt='What is the capital of France?'
[RESPONSE] The capital of France is Paris.
[ROUTED TO] alias='smart' -> upstream model='openai/gpt-4o'
[LATENCY] upstream=1071ms  proxy=4ms  total=1083ms

======================================================================
2. Invalid API key. Kong rejects before reaching the upstream provider
======================================================================

[REQUEST] model='fast' prompt='What is the capital of France?'
[BLOCKED] 401 Error code: 401 - {'message': 'Unauthorized'}  (30ms)

======================================================================
Done.
======================================================================
```
{:.no-copy-code}

### What happened

1. **Both aliases resolved on the same path.** The OpenAI SDK sent two `POST /basic-llm-routing` requests with identical bodies except for the `model` field (`fast` vs `smart`). The `X-Kong-LLM-Model` header on each response shows the actual upstream model Kong routed to: `openai/gpt-4o-mini` for `fast` and `openai/gpt-4o` for `smart`. No client code change, no separate endpoint, just a different value in the request body.
2. **AI Consumer identity attached to every successful request.** Kong matched the `apikey` header to the `basic-llm-routing-consumer` AI Consumer's credential and made that identity available to downstream policies. (Kong adds `X-Consumer-Username` to the upstream request, not the downstream response. See the {{site.konnect_short_name}} {{site.observability}} views in the next subsection for per-consumer attribution.) The AI Consumer is the unit you attach rate limits, ACLs, and quota policies to.
3. **Kong enforced auth before any upstream call.** The third request used a key that no AI Consumer holds. The Key Auth AI Auth Strategy rejected it in roughly 30 ms, well below normal upstream latency. Kong never contacted the provider, the request consumed no provider quota, and the failure surfaced as a clean `401` to the client.
4. **Provider credentials never left Kong.** The OpenAI SDK only ever held the AI Consumer's API key. The `Bearer sk-...` provider credential lived in `DECK_OPENAI_TOKEN` on the Kong side, and the AI Model Provider injected it into the upstream call.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `basic-llm-routing-recipe`. The recipe created an AI Model Provider holding your chosen provider's credentials, two AI Models (`basic-llm-routing-fast` and `basic-llm-routing-smart`), a Key Auth AI Auth Strategy, and an AI Consumer with a demo API key credential, all scoped to this recipe by the kongctl namespace applied above.

For platform-wide traffic analysis across every {{site.ai_gateway}}, head to the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

**Swap models by changing one env var.** Update `CHAT_MODEL_1` or `CHAT_MODEL_2` to a different model on the same provider and re-apply. Client code stays the same: `model="fast"` and `model="smart"` keep working; they just resolve to different upstream models. This is the most common production use of alias routing: an ops team can move the `claude-sonnet` alias from a version-pinned model ID like `claude-sonnet-4-5-20250929` to a newer pinned version when it's vetted, without coordinating with every team that consumes the alias. Stay within the same model class. Swapping `fast` from a small model to a large one is a behavioral change clients should be in on.

**Add per-consumer rate limits.** With the Key Auth AI Auth Strategy mapping requests to AI Consumers, attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to apply token quotas per AI Consumer or per AI Consumer Group. Each app holds its own API key, so each app gets its own budget. See the [LLM cost optimization recipe](/cookbooks/llm-cost-optimization/) for a worked example of cost-based tiered rate limiting.

**Switch to OpenID Connect for production identity.** Static API keys are simple, but they aren't user identities. When the platform integrates Okta, Keycloak, Auth0, or another OIDC provider, swap the [Key Auth AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) for an [OpenID Connect AI Auth Strategy](/ai-gateway/openid-connect/) and let JWT claims map users to AI Consumers automatically based on roles or team membership. The rest of the recipe (model aliases, AI Model targets, AI Consumer mappings) stays put. See the [Claude Code SSO recipe](/cookbooks/claude-code-sso/) for an end-to-end example with Okta.

**Switch providers.** Select a different provider tab above and re-apply. The client interface, including the `apikey` header auth and the `model: "fast"` / `model: "smart"` aliases, doesn't change. For setups that route to multiple providers from the same alias, see the [AI Model entity reference](/ai-gateway/entities/ai-model/) for load-balancing across targets.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='basic-llm-routing-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
