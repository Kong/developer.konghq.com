---
title: Basic LLM Routing
description: Route requests to any supported LLM provider through Kong AI Gateway with Consumer authentication and per-request model selection.
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
categories:
  - llm
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - key-auth
  - ai-proxy-advanced
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
    - title: Kong Konnect
      content: |
        This tutorial uses {{site.konnect_product_name}}. You will provision a recipe-scoped Control Plane and local Data Plane via the [quickstart script](https://get.konghq.com/quickstart).

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped Control Plane name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='basic-llm-routing-recipe'
           curl -Ls https://get.konghq.com/quickstart | bash -s -- -k $KONNECT_TOKEN --deck-output
           ```

           This provisions a Konnect Control Plane named `basic-llm-routing-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars. Paste those into your shell when prompted.
    - title: kongctl + decK
      content: |
        This tutorial uses [kongctl](/kongctl/) and [decK](/deck/) to manage Kong configuration.

        1. Install **kongctl** from [developer.konghq.com/kongctl](https://developer.konghq.com/kongctl/).
        1. Install **decK** version 1.43 or later from [docs.konghq.com/deck](https://docs.konghq.com/deck/).
        1. Verify both are installed:

           ```bash
           kongctl version
           deck version
           ```
    - title: AI Credentials
      content: |
        Pick the provider you want to route to and export its credentials. The same credentials are reused by every apply tab below.

        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        This tutorial uses OpenAI:

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Create a decK variable with the API key:

           ```sh
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
        {% endnavtab %}
        {% navtab "Anthropic" %}
        This tutorial uses Anthropic:

        1. [Create an Anthropic account](https://console.anthropic.com/).
        1. [Get an API key](https://console.anthropic.com/settings/keys).
        1. Create a decK variable with the API key:

           ```sh
           export DECK_ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        This tutorial uses AWS Bedrock:

        1. Ensure you have an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled.
        1. Create decK variables with your AWS credentials:

           ```sh
           export DECK_AWS_ACCESS_KEY_ID='your-access-key'
           export DECK_AWS_SECRET_ACCESS_KEY='your-secret-key'
           export DECK_AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% navtab "Azure OpenAI" %}
        This tutorial uses Azure OpenAI. Each Azure deployment is bound to a single model at deployment time, and the upstream model is determined by the deployment ID in the URL ([Azure OpenAI REST API reference](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference)). To demonstrate alias routing across two model tiers, you need **two** Azure deployments: one for the `fast` alias and one for `smart`.

        1. [Create an Azure OpenAI resource](https://portal.azure.com/#create/Microsoft.CognitiveServicesOpenAI).
        1. Deploy two models in your resource (e.g. `gpt-4o-mini` for the fast tier and `gpt-4o` for the smart tier). Note both deployment IDs, plus your instance name and API version.
        1. Create decK variables:

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
        1. Create decK variables:

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
        1. Create a decK variable with the API key:

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
  Consumer authentication and per-request model selection. By the end of this recipe, you will have
  a single `/basic-llm-routing` endpoint that accepts OpenAI-format requests carrying a per-Consumer
  API key, validates the key against a Consumer credential local to Kong, and routes the request to
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
  provider, the gateway cannot attribute usage to a tenant, enforce per-tenant quotas, or revoke
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

{{site.ai_gateway_name}} inserts a single Service and Route between clients and providers. The Route authenticates each request against a per-app credential, picks the upstream model based on a `model` field in the request body so clients can choose between tiers without changing endpoints, and injects the provider's credentials and translates request/response formats so client apps never hold a provider key. The result is one endpoint that gives the platform team a place to enforce identity, routing, and credential policy without coupling client code to any provider.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant L as LLM Provider

    C->>K: POST /basic-llm-routing (apikey, model: fast or smart)
    activate K
    K->>K: key-auth — validate apikey, attach Consumer
    K->>K: ai-proxy-advanced — match model_alias, inject provider auth
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
    responsibility: "Sends OpenAI-format requests with an `apikey` header that identifies the Consumer, plus `model: fast` or `model: smart`"
  - component: Key Auth Plugin
    responsibility: Looks up the API key against registered Consumer credentials, attaches the matching Kong Consumer to the request
  - component: AI Proxy Advanced Plugin
    responsibility: "Matches the request's `model` field to a target's `model_alias`, injects provider credentials, translates the request body, and routes to the upstream provider"
  - component: Kong Consumer
    responsibility: Identity attached to authenticated requests, used for rate limiting, ACLs, and analytics attribution
  - component: LLM provider
    responsibility: Processes the prompt and returns a completion
{% endtable %}

## How it works

A request flowing through Kong is processed in three stages: authentication, routing, and proxying.

1. A client sends a chat completion request (OpenAI format) to `/basic-llm-routing` with an `apikey` header and a `model` field set to either `fast` or `smart`.
2. The Key Auth Plugin reads the `apikey` header and looks the key up in Kong's Consumer credential store. If the key is missing or unknown, Kong short-circuits with `401` before any upstream call. On a match, the Plugin attaches the matching Consumer to the request, which is what downstream Plugins and analytics use to attribute usage.
3. The AI Proxy Advanced Plugin reads the `model` field from the request body, finds the target whose `model_alias` matches, and selects that target.
4. The Plugin strips the client's `apikey` header, injects the upstream provider's credentials from its configuration, and (if the upstream uses a different format) translates the OpenAI-format body to the provider's native format.
5. Kong forwards the request to the LLM provider's API endpoint, normalizes the response back to OpenAI format, and returns it to the client with `X-Kong-LLM-Model` (the upstream model that served the request) and latency headers attached.

### Key Auth: API key authentication and Consumer mapping

The Key Auth Plugin sits in front of the AI Proxy Advanced Plugin and gates every request. Each Consumer is registered with one or more API keys in the `keyauth_credentials` block. When a request arrives, the Plugin reads the configured header (`apikey`), looks the key up in Kong's Consumer credential store, and attaches the matching Consumer identity to the request. That identity is what downstream Plugins like rate limiters and analytics use to attribute usage. The Plugin scales naturally to multi-tenant scenarios. Add a Consumer per app or per team, each with its own key.

#### Configuration details

```yaml
- name: key-auth
  config:
    key_names:
      - apikey
    hide_credentials: true
```
{:.no-copy-code}

**`key_names: [apikey]`**. The headers (or query parameters) the Plugin looks in for the API key. The recipe uses `apikey` because the Key Auth Plugin performs an exact string match on the header value and does not inspect `Authorization` for Bearer tokens. The OpenAI SDK's `api_key` field always serializes as `Authorization: Bearer <key>`, which Kong would read as the literal string `Bearer <key>` and fail to match against any stored credential. The "Try it out" section below points at a pre-function pattern that bridges the SDK's Bearer token to the `apikey` header server-side; the [Authenticate OpenAI SDK clients with Key Auth](https://developer.konghq.com/how-to/authenticate-openai-sdk-clients-with-key-auth/) guide has the full pattern.

**`hide_credentials: true`**. Strips the API key from the request before forwarding upstream. The provider never sees the Consumer's API key. This is a 3.14 default but the recipe sets it explicitly for clarity and to remain portable to older Gateway versions.

**Anonymous fallback.** Set `anonymous: <consumer-id>` to let unauthenticated requests fall through to a designated "anonymous" Consumer with their own restricted policies, instead of returning `401`. Useful for public/free-tier endpoints. See the [key-auth reference](/plugins/key-auth/) for the full set of options.

**Scaling to a real IdP.** When the platform is ready for end-user identity instead of static API keys, swap key-auth for [openid-connect](/plugins/openid-connect/) and map JWT claims to Consumers. Application code only changes the auth header it sends; the rest of this recipe (model aliases, ai-proxy-advanced targets, Consumer mappings) stays put. See the [claude-code-sso recipe](/cookbooks/claude-code-sso/) for an end-to-end example with Okta.

### AI Proxy Advanced: model alias routing and provider translation

The AI Proxy Advanced Plugin sits behind the Key Auth Plugin and handles everything from the model-selection decision through the upstream call. The recipe configures two targets, each tagged with a `model_alias`. When a request arrives, the Plugin reads the `model` field from the request body, finds the target whose alias matches (`fast` or `smart`), and uses that target's `model.name` and `auth` configuration. This single Plugin replaces what would otherwise require per-provider SDKs, hand-rolled credential management, and per-model client logic.

#### Configuration details

{%- raw %}
```yaml
- name: ai-proxy-advanced
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    targets:
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          model_alias: fast
          provider: openai
          name: ${{ env "DECK_CHAT_MODEL_1" }}
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          model_alias: smart
          provider: openai
          name: ${{ env "DECK_CHAT_MODEL_2" }}
```
{% endraw -%}
{:.no-copy-code}

**`model.model_alias`**. The client-facing name for the target. When the request body's `model` field equals an alias, the Plugin routes to that target. With aliases configured, Kong uses alias matching as the primary routing decision. If no alias matches, the Plugin falls back to the configured load-balancing algorithm.

**`route_type: llm/v1/chat`**. Selects the chat-completions translation path. Kong accepts an OpenAI-format chat-completion body and converts it to whatever the upstream provider expects (Anthropic's `messages` API, Bedrock's `invoke-model` body, etc.). The response is normalised back to OpenAI format.

**`auth`**. Kong holds provider credentials in the Plugin config and injects them into every upstream request. Set `auth.allow_override: true` if you want client-provided credentials to pass through to the provider instead, useful when clients manage their own provider keys and Kong is purely a routing layer.

**`logging.log_statistics`**. When enabled, Kong appends token usage data (`prompt_tokens`, `completion_tokens`, `total_tokens`) to any attached logging Plugin's output. Useful for cost attribution.

**`logging.log_payloads`**. When enabled, the full request and response bodies are included in the output of any attached logging Plugin. Whether to enable this depends on your organization's observability and compliance requirements.

**`model.name`**. The upstream model identifier. With aliases in play, this is the actual provider model that serves the request when its alias is selected. Change it and re-apply to swap models without changing client code.

**`max_request_body_size`** and **`response_streaming`**. The recipe sets a 10 MB request limit (large enough for typical conversation contexts and modest RAG injections) and allows streaming responses (the natural choice for interactive chat). Tighten or relax both based on the workload you expect.

**Alternative configurations worth knowing about:**

- **`llm_format`**. The recipe uses the default (`openai`), which accepts OpenAI-format requests and normalizes all provider responses back to OpenAI format. Set `llm_format` to a provider's native format to pass requests through without transformation. Useful when you already have code using a provider's SDK or need provider-specific features that do not map to the OpenAI format. Native format only supports the matching provider, you cannot route across providers with different native formats on a single Plugin. See the [ai-proxy-advanced reference](/plugins/ai-proxy-advanced/) for the supported native formats.
- **Routing strategies beyond aliases.** This recipe routes by the `model` field in the body. The same Plugin also supports routing by request header (via Route or Service-level routing in front of the Plugin), by path (separate Routes per model), and by load-balancing algorithm across targets that share an alias. See the [ai-proxy-advanced reference](/plugins/ai-proxy-advanced/) for the full set of balancer algorithms and routing strategies.
- **Additional route types.** A single Plugin instance can have multiple targets for different route types, each with their own model and auth configuration. Beyond `llm/v1/chat`, the Plugin supports additional route types for embeddings, completions, responses, realtime, and multimodal traffic. See the [ai-proxy-advanced reference](/plugins/ai-proxy-advanced/) for the current list.

{:.info}
> **Production credentials.** This recipe stores the Consumer API key directly in Plugin config and the LLM provider credentials in environment variables for simplicity. In production, use [Kong Vaults](/gateway/latest/kong-enterprise/secrets-management/) to reference both from your preferred secret manager (AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, Azure Key Vault) instead.

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
    description: "Upstream model that served the request, prefixed with the provider name and resolved from the matched `model_alias`"
  - header: "`X-Kong-Upstream-Latency`"
    description: Time (ms) Kong spent waiting for the provider to respond
  - header: "`X-Kong-Proxy-Latency`"
    description: Time (ms) Kong spent processing the request (excluding upstream)
{% endtable %}

Kong attaches `X-Consumer-Username` and related headers to the **upstream** request (so the LLM provider sees who's calling) but does not echo them back to the downstream client. Per-Consumer attribution shows up in Konnect's analytics views. See "Explore in Konnect" below.

## Apply the Kong configuration

The following configuration creates a {{site.base_gateway}} Service and Route at `/basic-llm-routing`, attaches the [key-auth](/plugins/key-auth/) Plugin to identify Consumers via the `apikey` header, and attaches the [ai-proxy-advanced](/plugins/ai-proxy-advanced/) Plugin with two targets to handle alias routing, credential injection, and format translation. All resources are scoped using `select_tags` and a kongctl `namespace` so they can be cleanly torn down without affecting other configurations on the same Control Plane. See the [kongctl documentation](/kongctl/) for more on federated configuration management.

First, adopt the quickstart Control Plane into a kongctl namespace so the apply commands below can manage it.

```bash
kongctl adopt control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the Control Plane.

Provider credentials are exported once during Prerequisites. Each tab below only sets the model env vars (which are recipe-specific) and runs the apply.

{% navtabs "Providers" %}
{% tab OpenAI %}

Export the model env vars:

```bash
export DECK_CHAT_MODEL_1='gpt-4o-mini'  # the "fast" alias
export DECK_CHAT_MODEL_2='gpt-4o'        # the "smart" alias
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing-recipe
services:
- name: basic-llm-routing
  url: http://localhost
  routes:
  - name: basic-llm-routing
    paths:
    - /basic-llm-routing
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: key-auth
    instance_name: basic-llm-routing-auth
    config:
      key_names:
      - apikey
      hide_credentials: true
  - name: ai-proxy-advanced
    instance_name: basic-llm-routing-proxy
    config:
      max_request_body_size: 10485760
      response_streaming: allow
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          model_alias: fast
          provider: openai
          name: ${{ env "DECK_CHAT_MODEL_1" }}
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          model_alias: smart
          provider: openai
          name: ${{ env "DECK_CHAT_MODEL_2" }}
consumers:
- username: demo-app
  keyauth_credentials:
  - key: demo-api-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Anthropic %}

Export the model env vars:

```bash
export DECK_CHAT_MODEL_1='claude-haiku-4-5-20251001'      # the "fast" alias
export DECK_CHAT_MODEL_2='claude-sonnet-4-5-20250929'      # the "smart" alias
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing-recipe
services:
- name: basic-llm-routing
  url: http://localhost
  routes:
  - name: basic-llm-routing
    paths:
    - /basic-llm-routing
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: key-auth
    instance_name: basic-llm-routing-auth
    config:
      key_names:
      - apikey
      hide_credentials: true
  - name: ai-proxy-advanced
    instance_name: basic-llm-routing-proxy
    config:
      max_request_body_size: 10485760
      response_streaming: allow
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: x-api-key
          header_value: ${{ env "DECK_ANTHROPIC_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          model_alias: fast
          provider: anthropic
          name: ${{ env "DECK_CHAT_MODEL_1" }}
      - route_type: llm/v1/chat
        auth:
          header_name: x-api-key
          header_value: ${{ env "DECK_ANTHROPIC_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          model_alias: smart
          provider: anthropic
          name: ${{ env "DECK_CHAT_MODEL_2" }}
consumers:
- username: demo-app
  keyauth_credentials:
  - key: demo-api-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab AWS Bedrock %}

Export the model env vars:

```bash
export DECK_CHAT_MODEL_1='amazon.nova-lite-v1:0'                                   # the "fast" alias
export DECK_CHAT_MODEL_2='global.anthropic.claude-sonnet-4-5-20250929-v1:0'        # the "smart" alias
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing-recipe
services:
- name: basic-llm-routing
  url: http://localhost
  routes:
  - name: basic-llm-routing
    paths:
    - /basic-llm-routing
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: key-auth
    instance_name: basic-llm-routing-auth
    config:
      key_names:
      - apikey
      hide_credentials: true
  - name: ai-proxy-advanced
    instance_name: basic-llm-routing-proxy
    config:
      max_request_body_size: 10485760
      response_streaming: allow
      targets:
      - route_type: llm/v1/chat
        auth:
          aws_access_key_id: ${{ env "DECK_AWS_ACCESS_KEY_ID" }}
          aws_secret_access_key: ${{ env "DECK_AWS_SECRET_ACCESS_KEY" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          model_alias: fast
          provider: bedrock
          name: ${{ env "DECK_CHAT_MODEL_1" }}
          options:
            bedrock:
              aws_region: ${{ env "DECK_AWS_REGION" }}
      - route_type: llm/v1/chat
        auth:
          aws_access_key_id: ${{ env "DECK_AWS_ACCESS_KEY_ID" }}
          aws_secret_access_key: ${{ env "DECK_AWS_SECRET_ACCESS_KEY" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          model_alias: smart
          provider: bedrock
          name: ${{ env "DECK_CHAT_MODEL_2" }}
          options:
            bedrock:
              aws_region: ${{ env "DECK_AWS_REGION" }}
consumers:
- username: demo-app
  keyauth_credentials:
  - key: demo-api-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Azure %}

Export the model env vars. The model names are recorded by Kong in the `X-Kong-LLM-Model` header for analytics, but Azure's upstream selection is driven by the deployment IDs you exported in the AI Credentials prereq:

```bash
export DECK_CHAT_MODEL_1='gpt-4o-mini'  # the "fast" alias. must match the model in DECK_AZURE_DEPLOYMENT_ID_1
export DECK_CHAT_MODEL_2='gpt-4o'        # the "smart" alias. must match the model in DECK_AZURE_DEPLOYMENT_ID_2
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing-recipe
services:
- name: basic-llm-routing
  url: http://localhost
  routes:
  - name: basic-llm-routing
    paths:
    - /basic-llm-routing
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: key-auth
    instance_name: basic-llm-routing-auth
    config:
      key_names:
      - apikey
      hide_credentials: true
  - name: ai-proxy-advanced
    instance_name: basic-llm-routing-proxy
    config:
      max_request_body_size: 10485760
      response_streaming: allow
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: api-key
          header_value: ${{ env "DECK_AZURE_API_KEY" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          model_alias: fast
          provider: azure
          name: ${{ env "DECK_CHAT_MODEL_1" }}
          options:
            azure_api_version: ${{ env "DECK_AZURE_API_VERSION" }}
            azure_deployment_id: ${{ env "DECK_AZURE_DEPLOYMENT_ID_1" }}
            azure_instance: ${{ env "DECK_AZURE_INSTANCE" }}
      - route_type: llm/v1/chat
        auth:
          header_name: api-key
          header_value: ${{ env "DECK_AZURE_API_KEY" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          model_alias: smart
          provider: azure
          name: ${{ env "DECK_CHAT_MODEL_2" }}
          options:
            azure_api_version: ${{ env "DECK_AZURE_API_VERSION" }}
            azure_deployment_id: ${{ env "DECK_AZURE_DEPLOYMENT_ID_2" }}
            azure_instance: ${{ env "DECK_AZURE_INSTANCE" }}
consumers:
- username: demo-app
  keyauth_credentials:
  - key: demo-api-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Google Gemini %}

Export the model env vars:

```bash
export DECK_CHAT_MODEL_1='gemini-2.0-flash'  # the "fast" alias
export DECK_CHAT_MODEL_2='gemini-1.5-pro'    # the "smart" alias
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing-recipe
services:
- name: basic-llm-routing
  url: http://localhost
  routes:
  - name: basic-llm-routing
    paths:
    - /basic-llm-routing
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: key-auth
    instance_name: basic-llm-routing-auth
    config:
      key_names:
      - apikey
      hide_credentials: true
  - name: ai-proxy-advanced
    instance_name: basic-llm-routing-proxy
    config:
      max_request_body_size: 10485760
      response_streaming: allow
      targets:
      - route_type: llm/v1/chat
        auth:
          gcp_use_service_account: true
        logging:
          log_statistics: true
          log_payloads: true
        model:
          model_alias: fast
          provider: gemini
          name: ${{ env "DECK_CHAT_MODEL_1" }}
          options:
            gemini:
              api_endpoint: ${{ env "DECK_GCP_API_ENDPOINT" }}
              project_id: ${{ env "DECK_GCP_PROJECT_ID" }}
              location_id: ${{ env "DECK_GCP_LOCATION_ID" }}
      - route_type: llm/v1/chat
        auth:
          gcp_use_service_account: true
        logging:
          log_statistics: true
          log_payloads: true
        model:
          model_alias: smart
          provider: gemini
          name: ${{ env "DECK_CHAT_MODEL_2" }}
          options:
            gemini:
              api_endpoint: ${{ env "DECK_GCP_API_ENDPOINT" }}
              project_id: ${{ env "DECK_GCP_PROJECT_ID" }}
              location_id: ${{ env "DECK_GCP_LOCATION_ID" }}
consumers:
- username: demo-app
  keyauth_credentials:
  - key: demo-api-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Mistral %}

Export the model env vars:

```bash
export DECK_CHAT_MODEL_1='mistral-small-latest'  # the "fast" alias
export DECK_CHAT_MODEL_2='mistral-large-latest'   # the "smart" alias
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing-recipe
services:
- name: basic-llm-routing
  url: http://localhost
  routes:
  - name: basic-llm-routing
    paths:
    - /basic-llm-routing
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: key-auth
    instance_name: basic-llm-routing-auth
    config:
      key_names:
      - apikey
      hide_credentials: true
  - name: ai-proxy-advanced
    instance_name: basic-llm-routing-proxy
    config:
      max_request_body_size: 10485760
      response_streaming: allow
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_MISTRAL_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          model_alias: fast
          provider: mistral
          name: ${{ env "DECK_CHAT_MODEL_1" }}
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_MISTRAL_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          model_alias: smart
          provider: mistral
          name: ${{ env "DECK_CHAT_MODEL_2" }}
consumers:
- username: demo-app
  keyauth_credentials:
  - key: demo-api-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% endnavtabs %}

## Try it out

The demo script makes three calls. The first two send the same prompt with different `model` values (`fast` then `smart`) and print the `X-Kong-LLM-Model` header so you can confirm Kong routed each request to a different upstream model. The third call presents an invalid API key and shows Kong rejecting it with `401` before any upstream call.

{:.info}
> The demo passes the API key via `default_headers` because the OpenAI SDK reserves `api_key` for the `Authorization: Bearer` header. To let clients pass the key through `api_key` directly, attach a [pre-function](/plugins/pre-function/) Plugin that copies the Bearer token to the `apikey` header server-side. See [Authenticate OpenAI SDK clients with Key Auth](https://developer.konghq.com/how-to/authenticate-openai-sdk-clients-with-key-auth/) for the pattern.

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
[BLOCKED] 401 Error code: 401 - {'message': 'No credentials found for given apikey'}  (14ms)

======================================================================
Done.
======================================================================
```
{:.no-copy-code}

### What happened

1. **Both aliases resolved on the same Route.** The OpenAI SDK sent two `POST /basic-llm-routing` requests with identical bodies except for the `model` field (`fast` vs `smart`). The `X-Kong-LLM-Model` header on each response shows the actual upstream model Kong routed to: `openai/gpt-4o-mini` for `fast` and `openai/gpt-4o` for `smart`. No client code change, no separate endpoint, just a different value in the request body.
2. **Consumer identity attached to every successful request.** Kong matched the `apikey` header to the `demo-app` Consumer's credential and made that identity available to downstream Plugins. (`X-Consumer-Username` is added to the upstream request, not the downstream response. See the Konnect analytics views in the next subsection for per-Consumer attribution.) The Consumer is the unit you would attach rate limits, ACLs, and quota policies to.
3. **Kong enforced auth before any upstream call.** The third request used a key that no Consumer holds. Kong's Key Auth Plugin rejected it in roughly 5 ms, well below normal upstream latency. The provider was never contacted, no provider quota was consumed, and the failure surfaced as a clean `401` to the client.
4. **Provider credentials never left Kong.** The OpenAI SDK only ever held the Consumer's API key. The `Bearer sk-...` provider credential lived in `DECK_OPENAI_TOKEN` on the Kong side and was injected into the upstream call by the AI Proxy Advanced Plugin.

### Explore in Konnect

Open [Konnect](https://cloud.konghq.com/) and navigate to **API Gateway** → **Gateways** → **basic-llm-routing-recipe**. The recipe created the following resources on this Control Plane:

- **Gateway services** → **basic-llm-routing**: the Service the recipe registered. Its detail page has tabs for Configuration, Routes, Plugins, and Analytics.
  - **Routes** tab: the `/basic-llm-routing` Route, scoped by the `basic-llm-routing-recipe` `select_tags` you used at apply time.
  - **Plugins** tab: two Plugin instances, `basic-llm-routing-auth` (key-auth) and `basic-llm-routing-proxy` (ai-proxy-advanced). Open the AI Proxy Advanced Plugin to see the two targets and their `model_alias` values.
- **Consumers** → **demo-app**: the Consumer the API key maps to.

The **Analytics** tab on the Gateway service shows analytics tied to this recipe, including request counts, error rates, average latency, and a request-over-time chart. For a deeper dive into these analytics, plus platform-wide analytics across every Control Plane, head to the **Observability** L1 menu in Konnect.

## Cleanup

The recipe scoped all resources with `select_tags` and a kongctl `namespace`, so this teardown removes only this recipe's configuration. Tear down the local Data Plane and delete the Control Plane from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='basic-llm-routing-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```

## Variations and next steps

**Swap models by changing one env var.** Update `DECK_CHAT_MODEL_1` or `DECK_CHAT_MODEL_2` to a different model on the same provider and re-apply. Client code stays the same: `model="fast"` and `model="smart"` keep working, they just resolve to different upstream models. This is the most common production use of `model_alias`: an ops team can move the `claude-sonnet` alias from a version-pinned model ID like `claude-sonnet-4-5-20250929` to a newer pinned version when it's vetted, without coordinating with every team that consumes the alias. Stay within the same model class. Swapping `fast` from a small model to a large one is a behavioural change clients should be in on.

**Add per-Consumer rate limits.** With key-auth mapping requests to Consumers, attach the [ai-rate-limiting-advanced](/plugins/ai-rate-limiting-advanced/) Plugin to apply token quotas per Consumer or per Consumer Group. Each app holds its own API key, so each app gets its own budget. See the [llm-cost-optimization recipe](/cookbooks/llm-cost-optimization/) for a worked example of cost-based tiered rate limiting.

**Switch to OpenID Connect for production identity.** Static API keys are simple but they are not user identities. When the platform integrates Okta, Keycloak, Auth0, or another OIDC provider, swap the [key-auth](/plugins/key-auth/) Plugin for [openid-connect](/plugins/openid-connect/) and let JWT claims map users to Consumers automatically based on roles or team membership. The rest of the recipe (model aliases, ai-proxy-advanced targets, Consumer mappings) stays put. See the [claude-code-sso recipe](/cookbooks/claude-code-sso/) for an end-to-end example with Okta.

**Switch providers.** Select a different provider tab above and re-apply. The client interface, including the `apikey` header auth and the `model: "fast"` / `model: "smart"` aliases, does not change. For setups that route to multiple providers from the same Plugin instance, see the [AI Proxy Advanced load balancing documentation](/plugins/ai-proxy-advanced/).
