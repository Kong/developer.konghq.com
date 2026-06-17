---
title: GitHub Copilot BYOK Custom Endpoint
description: Route GitHub Copilot Chat and agent traffic through {{site.base_gateway}} via Copilot's Bring Your Own Key Custom Endpoint, with per-Consumer attribution, request normalization, and token rate limiting.
url: "/cookbooks/github-copilot-byok/"
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
  - access-control
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - pre-function
  - key-auth
  - ai-proxy-advanced
  - ai-rate-limiting-advanced
requires_embeddings: false
providers:
  - openai
  - azure
  - bedrock
extra_services:
  - name: GitHub Copilot Business or Enterprise
    env_vars: []
    hint: "Each developer needs a GitHub Copilot Business or Enterprise seat, and the org administrator must enable the 'Bring Your Own Language Model Key in VS Code' Copilot policy plus Editor Preview Features. See the GitHub Copilot section in Prerequisites."

hint: "Requires GitHub Copilot Business or Enterprise seats, VS Code 1.122 or later, an admin who can enable the BYOK Copilot policy, and one LLM provider credential (OpenAI, Azure OpenAI, or AWS Bedrock)."

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

        1. Set the recipe-scoped Control Plane name and run the quickstart script. The `-e` flags raise the data plane's nginx body buffer so Copilot's large request payloads (full conversation context, tool definitions, file contents) stay in memory instead of spilling to disk:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='github-copilot-byok-recipe'
           curl -Ls https://get.konghq.com/quickstart | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=16m \
               -e KONG_NGINX_HTTP_CLIENT_MAX_BODY_SIZE=16m \
               --deck-output
           ```

           This provisions a {{site.konnect_product_name}} Control Plane named `github-copilot-byok-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars. Paste those into your shell when prompted.
    - title: kongctl + decK + jq
      content: |
        This tutorial uses [kongctl](/kongctl/) and [decK](/deck/) to manage Kong configuration, plus [jq](https://jqlang.org/) for JSON processing in the apply and cleanup steps.

        1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
        1. Install **decK** version 1.43 or later from [developer.konghq.com/deck](/deck/).
        1. Install **jq** from [jqlang.org](https://jqlang.org/).

        You can verify all three are installed:

        ```bash
        kongctl version
        deck version
        jq --version
        ```
    - title: GitHub Copilot in VS Code
      content: |
        This recipe routes GitHub Copilot Chat and agent traffic through {{site.base_gateway}} using Copilot's **Bring Your Own Key Custom Endpoint**. The Custom Endpoint feature is currently in stable VS Code on Copilot Enterprise seats and in preview on Copilot Business seats. Verify the current availability matrix at the [VS Code language models docs](https://code.visualstudio.com/docs/copilot/customization/language-models) before you start.

        1. Install **VS Code** version 1.122 or later from [code.visualstudio.com](https://code.visualstudio.com/).
        1. Install the **GitHub Copilot** and **GitHub Copilot Chat** extensions and sign in with a GitHub account that has a Copilot Business or Enterprise seat.
        1. Have your **Copilot administrator** enable both of the following in the GitHub organization's Copilot policy settings:
           - **Bring Your Own Language Model Key in VS Code** (the BYOK policy gate).
           - **Editor Preview Features** (required as long as Custom Endpoint is preview on your seat type).

           Without these, the VS Code Chat picker will not surface the Custom Endpoint option, or will accept the configuration and reject every request at runtime.

        1. Generate two Consumer credentials. These become the API key values each developer enters into the VS Code **Add Models...** wizard. Export them now so the apply step picks them up:

           ```bash
           export DECK_COPILOT_KEY_ALICE="$(openssl rand -hex 24)"
           export DECK_COPILOT_KEY_BOB="$(openssl rand -hex 24)"
           ```

           When you later paste a key into VS Code, copy it with `printf '%s' "$DECK_COPILOT_KEY_ALICE"` rather than `echo "$DECK_COPILOT_KEY_ALICE"`. In zsh, output that lacks a trailing newline is rendered with a bold `%`. That character is not part of the key, and pasting it produces a `401 No API key found in request` from Key Auth.

           In production, generate one credential per developer (or one per VS Code workstation) and distribute through your secrets manager rather than shell exports.

        {:.warning}
        > **Inline ghost-text completions cannot be proxied.** Copilot's autocomplete (the gray suggestion text that appears as you type) always runs on GitHub's infrastructure and is not affected by the Custom Endpoint setting. The recipe governs Copilot Chat and agent (`@workspace`, `#editor`, Copilot CLI) traffic only.
    - title: AI Credentials
      content: |
        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        This tutorial uses OpenAI:

        1. [Create an OpenAI account](https://platform.openai.com/).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Create a decK variable for the API key. The `openai` provider expects the full `Authorization` value, including the `Bearer ` prefix:

           ```bash
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-OPENAI-KEY'
           ```
        {% endnavtab %}
        {% navtab "Azure OpenAI" %}
        This tutorial uses [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/):

        1. Ensure you have an Azure OpenAI resource with at least one chat deployment.
        1. Create decK variables for your resource. `DECK_AZURE_DEPLOYMENT_ID` is the deployment name you assigned in the Azure portal, not the underlying model name:

           ```bash
           export DECK_AZURE_API_KEY='YOUR-AZURE-OPENAI-KEY'
           export DECK_AZURE_INSTANCE='your-azure-resource'
           export DECK_AZURE_DEPLOYMENT_ID='your-deployment-name'
           export DECK_AZURE_API_VERSION='2024-10-21'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        This tutorial uses [AWS Bedrock](https://docs.aws.amazon.com/bedrock/):

        1. Ensure you have an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled for the chat model you plan to use.
        1. Create decK variables with your AWS credentials:

           ```bash
           export DECK_AWS_ACCESS_KEY_ID='your-access-key'
           export DECK_AWS_SECRET_ACCESS_KEY='your-secret-key'
           export DECK_AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% endnavtabs %}

overview: |
  This recipe puts {{site.ai_gateway_name}} in front of an LLM provider so every
  GitHub Copilot Chat and agent request from your engineering team flows through a
  control point you own. Kong holds the provider API key and injects it server-side,
  authenticates each developer with a Consumer-scoped credential, normalizes the
  request body so reasoning models accept it, and attributes every token to a named
  developer in {{site.konnect_short_name}} Analytics.

  The recipe configures Copilot's
  [Bring Your Own Key (BYOK) Custom Endpoint](https://code.visualstudio.com/docs/copilot/customization/language-models)
  in VS Code to post to a Kong Route at `/github-copilot/v1/chat/completions`, then
  uses four Kong Plugins on that Route: the [Pre-function](/plugins/pre-function/)
  Plugin to normalize the request, the [Key Auth](/plugins/key-auth/) Plugin to
  authenticate each developer, the [AI Proxy Advanced](/plugins/ai-proxy-advanced/)
  Plugin to inject the provider key and forward the request, and the
  [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) Plugin to enforce
  per-Consumer token budgets.

  Scope: this recipe governs Copilot Chat and agent traffic (the Chat view, agent
  modes, and Copilot CLI). Inline ghost-text code completions always run on
  GitHub's infrastructure and cannot be proxied through Kong, regardless of the
  Custom Endpoint setting.
---

## The problem

Routing GitHub Copilot through a central control point breaks down on three independent fronts at once. Each one is a real wall teams hit; together they are why naive provider-credential reuse falls apart.

**Credentials live on developer machines.** A team that enables Copilot BYOK without a gateway distributes provider API keys directly to every engineer through 1Password, shell profiles, or chat. Every request is indistinguishable on the provider bill, every leaked key is a fleet-wide rotation, and there is no way to revoke one developer without touching everyone.

**Copilot pins request fields that some upstreams reject.** VS Code's Custom Endpoint client posts requests with `temperature: 0.1` hard-coded into the body, and Copilot's BYOK schema does not expose a field for changing it. When the upstream is a reasoning model (gpt-5 family, o-series), the provider returns:

```text
400 ... 'temperature' does not support 0.1 ... Only the default (1) value is supported
```
{:.no-copy-code}

There is nowhere in VS Code's BYOK configuration to fix this. The request has to be normalized at the gateway.

**Org-policy model allowlists reject the wrong name.** GitHub Copilot Business and Enterprise let admins pin an allowlist of model IDs that BYOK requests are permitted to claim. A request that names any other model is rejected by Copilot before it ever leaves VS Code, with:

```text
400 "cannot use own model - must be: gpt-5-mini"
```
{:.no-copy-code}

This is enforced by GitHub's policy layer, not by the LLM provider or by Kong. It means the model ID a developer types into VS Code (`models[].id` in the BYOK config) has to match the org's allowlist, regardless of what model Kong actually forwards to upstream.

**No per-developer attribution.** Even when traffic reaches the provider, the bill is a single line item. There is no built-in way to see which developer used how many tokens, which model, or how often a developer is approaching the team's monthly budget. Cost decisions become retroactive.

The root issue is that trust, normalization, and accounting all need to happen on a server you control before the request hits the provider. That control point is what this recipe builds.

## The solution

This recipe puts {{site.base_gateway}} between VS Code and the LLM provider so every Copilot Chat or agent request flows through a server you control:

- **Developers never hold the provider key.** Kong holds it and injects it server-side. Each developer authenticates to Kong with their own short-lived Consumer credential, which is the value they paste into VS Code's `apiKey` field. Rotating one developer is a single deck-config change; rotating the provider key is also one change, not a fleet-wide push.
- **Per-Consumer attribution.** Every request is attributed to a named Consumer in {{site.konnect_short_name}} Analytics, so cost, token usage, and model mix can be sliced per developer.
- **Server-side request normalization.** A Pre-function Plugin instance runs ahead of every other Plugin on the Route and rewrites two things in the request before any other Plugin sees it: it converts Copilot's `Authorization: Bearer <apiKey>` header into the `apikey` header that the Key Auth Plugin expects, and it strips `temperature` from the JSON body so reasoning models accept the request.
- **Token-budget rate limiting.** Each Consumer has a per-minute token budget enforced by the AI Rate Limiting Advanced Plugin. Exhaustion returns `429 Too Many Requests` until the window resets.
- **Org-allowlist alignment.** The Kong target's `model_alias` is parameterized by `DECK_CHAT_MODEL`, so the same env var pins both the name VS Code sends and the name Kong matches against. If the org policy mandates `gpt-5-mini`, you set the env var to `gpt-5-mini`, and the VS Code `id` field uses the same value. Kong's `model.name` independently controls what is actually sent upstream.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant VS as VS Code Copilot
    participant K as Kong Gateway
    participant L as LLM Provider

    VS->>K: POST /github-copilot/v1/chat/completions<br/>Authorization: Bearer &lt;apiKey&gt;<br/>body: {model, messages, temperature: 0.1}
    activate K
    K->>K: pre-function (Bearer to apikey, strip temperature)
    K->>K: key-auth (validate apikey, attach Consumer)
    K->>K: ai-proxy-advanced (alias match, inject provider key)
    K->>K: ai-rate-limiting-advanced (per-Consumer token budget)
    K->>L: Forwarded request (provider auth + normalized body)
    activate L
    L-->>K: Provider response
    deactivate L
    K-->>VS: OpenAI-format response (+ X-AI-RateLimit headers)
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
  - component: "VS Code GitHub Copilot extension"
    responsibility: "Posts Chat and agent requests to the Custom Endpoint URL using the OpenAI Chat Completions API shape."
  - component: "Kong, [Pre-function](/plugins/pre-function/) Plugin"
    responsibility: "Rewrites `Authorization: Bearer` to `apikey` so Key Auth can match it; strips `temperature` from the body so reasoning models accept it."
  - component: "Kong, [Key Auth](/plugins/key-auth/) Plugin"
    responsibility: "Validates the per-developer credential and attaches the request to the matching Consumer for downstream attribution and rate-limit counting."
  - component: "Kong, [AI Proxy Advanced](/plugins/ai-proxy-advanced/) Plugin"
    responsibility: "Matches the body's `model` against `model_alias`, injects the provider API key server-side, translates to the upstream's native format if needed, and forwards."
  - component: "Kong, [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) Plugin"
    responsibility: "Counts prompt + completion tokens against the Consumer's per-window budget and returns `429` on exhaustion."
  - component: "LLM provider"
    responsibility: "Model inference. Receives the Kong-injected credential and the normalized request body."
{% endtable %}

## How it works

When a developer asks Copilot Chat a question, the request flows through Kong before reaching the LLM provider. Here is the complete lifecycle:

1. **Request from VS Code.** The Copilot extension posts `POST /github-copilot/v1/chat/completions` to Kong with the developer's Consumer credential in the `Authorization: Bearer <apiKey>` header and an OpenAI-format chat body. The body's `model` field equals the value of `models[].id` in `chatLanguageModels.json`, which the recipe pins to `DECK_CHAT_MODEL`.

1. **Header and body normalization.** The Pre-function Plugin runs first (priority approximately 1,000,000, above every other Plugin on the Route). It checks the `Authorization` header, strips the `Bearer ` prefix, and writes the bare credential into a new `apikey` header that the Key Auth Plugin will read. In the same pass it decodes the JSON body, removes the `temperature` field if present, and writes the body back. From this point on, all subsequent Plugins see a normalized request.

1. **Per-developer authentication.** The Key Auth Plugin reads the `apikey` header, looks up the matching credential in the Control Plane, and attaches the request to the corresponding Consumer (`copilot-developer-alice` or `copilot-developer-bob` in this recipe). Unknown credentials are rejected with `401 Unauthorized`.

1. **Alias matching and provider-key injection.** The AI Proxy Advanced Plugin reads the body's `model` field and matches it against the `model_alias` configured on each target. The recipe configures one target whose `model_alias` equals `DECK_CHAT_MODEL`, so a request that uses any other model name is rejected with `400 model not configured`. On a match, Kong injects the provider API key into the upstream request and, if the upstream uses a non-OpenAI format (Bedrock), translates the body from OpenAI to the upstream format.

1. **Token rate limiting.** The AI Rate Limiting Advanced Plugin counts prompt and completion tokens against the Consumer's per-window budget. Rate-limit headers (`X-AI-RateLimit-Remaining-*`) are added to the response. Exhaustion returns `429 Too Many Requests` with a `Retry-After` header.

1. **Response back to VS Code.** The provider response flows back through Kong to VS Code. Copilot renders the chat reply or runs the requested tool call.

### Pre-function: request normalization

The Pre-function Plugin runs Lua in the `access` phase before any other Plugin on the Route. The recipe uses it to fix two things Copilot's BYOK client cannot fix itself: it converts `Authorization: Bearer <apiKey>` into the `apikey` header that Key Auth expects, and it strips the hard-coded `temperature: 0.1` field from the body so reasoning models accept the request. Both rewrites have to happen before Key Auth and AI Proxy Advanced run, which is why Pre-function (priority around 1,000,000) is the right tool: it has the highest access-phase priority of any standard Kong Plugin.

#### Configuration details

{%- raw %}
```yaml
plugins:
  - name: pre-function
    config:
      access:
        - |
          local cjson = require "cjson.safe"

          local auth = kong.request.get_header("Authorization")
          if auth and string.sub(string.lower(auth), 1, 7) == "bearer " then
            ngx.req.set_header("apikey", string.sub(auth, 8))
          end

          local body = kong.request.get_raw_body()
          if body then
            local json = cjson.decode(body)
            if json and json.temperature ~= nil then
              json.temperature = nil
              kong.service.request.set_raw_body(cjson.encode(json))
            end
          end
```
{% endraw -%}
{:.no-copy-code}

**`access`**. An array of Lua source strings, each of which becomes a function executed during the `access` phase. Each function has full access to the [Kong PDK](/gateway/pdk/reference/) and the `ngx` namespace.

**`ngx.req.set_header("apikey", ...)`**. The standard PDK function `kong.service.request.set_header` only mutates headers sent upstream; it does not change what later Plugins see. The Authorization-to-apikey rewrite has to be visible to the next Plugin in the chain (Key Auth), so the recipe drops down to `ngx.req.set_header`, which mutates the underlying nginx request and is visible to every PDK reader for the remainder of the request lifecycle.

**Body rewrite via `kong.service.request.set_raw_body`**. Replaces the body that gets forwarded upstream. For OpenAI and Azure OpenAI (passthrough paths), this is the body the provider sees. For AWS Bedrock with `llm_format: openai`, the AI Proxy Advanced Plugin translates the request from OpenAI to Bedrock format on the way out and emits its own upstream body; verify that the temperature normalization survives that translation in your environment if you point this recipe at Bedrock with a reasoning-style upstream.

{:.warning}
> **VS Code Copilot pins `temperature: 0.1` with no UI override.** Reasoning models (gpt-5 family, o-series) reject any temperature other than the default 1 with `400 ... 'temperature' does not support 0.1 ... Only the default (1) value is supported`. The Pre-function strip above is what makes those models usable as Copilot BYOK upstreams. If you remove this Plugin, requests against reasoning models fail with this exact error.

### Key Auth: per-developer authentication

The Key Auth Plugin authenticates each request against a Consumer credential. The recipe ships two Consumers (`copilot-developer-alice` and `copilot-developer-bob`) so the per-Consumer attribution in {{site.konnect_short_name}} Analytics is visible from the first apply. Each developer enters their assigned credential into the VS Code **Add Models... → Custom Endpoint → Chat Completions** wizard, which stores it in the OS keychain and writes a `${input:chat.lm.secret.<id>}` placeholder into `chatLanguageModels.json`. The Pre-function Plugin above ensures Key Auth sees the rewritten value in the `apikey` header it expects.

#### Configuration details

```yaml
plugins:
  - name: key-auth
    config:
      key_names:
        - apikey
      hide_credentials: true
```
{:.no-copy-code}

**`key_names: [apikey]`**. The header name Key Auth reads. Pre-function normalizes Copilot's `Authorization: Bearer` into this header, so a single name suffices and no fallback to query string or other headers is needed.

**`hide_credentials: true`**. Strips the `apikey` header from the request before it is forwarded upstream. The provider never sees the Consumer's gateway credential. In {{site.base_gateway}} 3.14 and later, this defaults to `true`; the recipe sets it explicitly to document intent.

**Consumer scaling.** Add one Consumer per developer (or per VS Code workstation) with its own `keyauth_credentials` entry. The recipe defines two for demonstration; production deployments typically generate Consumers programmatically as part of developer onboarding.

### AI Proxy Advanced: provider routing and format translation

The AI Proxy Advanced Plugin holds the provider API key, matches the request body's `model` field against the `model_alias` on a target, and forwards. With one target on the recipe, the `model_alias` acts as a hard gate: any model name VS Code sends other than `DECK_CHAT_MODEL` is rejected with `400 model not configured`. This is what makes the org-policy allowlist alignment work. Set `DECK_CHAT_MODEL` to the name your Copilot admin requires, and the VS Code `id` field has to match, or Kong refuses the request.

#### Configuration details

{%- raw %}
```yaml
plugins:
  - name: ai-proxy-advanced
    config:
      llm_format: openai
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
            model_alias: ${{ env "DECK_CHAT_MODEL" }}
            provider: openai
            name: ${{ env "DECK_CHAT_MODEL" }}
            options:
              input_cost: 0.25
              output_cost: 2.00
```
{% endraw -%}
{:.no-copy-code}

**`llm_format: openai`**. Copilot speaks the OpenAI Chat Completions API. For OpenAI and Azure OpenAI upstreams the request passes through natively. For AWS Bedrock the Plugin translates the request from OpenAI to Bedrock's `InvokeModel` shape and the response back, so Copilot's client sees an OpenAI-shaped response in both cases.

**`route_type: llm/v1/chat`**. Selects the chat-completions translation path. See the [AI Proxy Advanced reference](/plugins/ai-proxy-advanced/reference/) for the full list of supported Route types.

**`model.model_alias`** equals **`model.name`** in this recipe. The alias is what VS Code sends in the body and what Kong matches; the name is what Kong sends upstream. For OpenAI and Azure OpenAI both are the same value (the user-visible model ID); for Bedrock, the alias can be a friendly bare name while the upstream `name` is the long Bedrock model ID. Change the env var pair if you want the user-facing alias to differ from the upstream name.

**`auth`**. The credential block injected on every upstream request. The shape varies by provider; the Apply section's per-provider navtabs show the OpenAI, Azure OpenAI, and Bedrock variants. The provider key is never sent to VS Code and never sits on the developer's machine.

**`max_request_body_size: 10485760`**. Sets the maximum allowed body to 10 MB. Copilot Chat conversations accumulate large context (chat history, open files, workspace symbols), and the default body limit can reject these requests.

**`response_streaming: allow`**. Lets the Plugin pass Server-Sent Events streaming responses from the provider back to VS Code. Copilot Chat renders streamed token output progressively.

**`logging.log_statistics`** and **`logging.log_payloads`**. Emit token-usage data and request/response bodies to any attached logging Plugin (for example, [HTTP Log](/plugins/http-log/) or [File Log](/plugins/file-log/)) for per-developer audit and cost attribution. {{site.konnect_short_name}} Analytics captures token usage independently of these fields.

**`model.options.input_cost`** and **`model.options.output_cost`**. USD per 1,000,000 tokens for prompt and completion respectively. Kong multiplies the reported `prompt_tokens` and `completion_tokens` by these rates per request and emits the result as the `cost` metric to {{site.konnect_short_name}} Analytics, which is what populates the **Total cost** tile on the dashboard. The recipe ships with `0.25` / `2.00`. Reasonable for a small reasoning-class model like `gpt-5-mini`; replace with the published rates for whatever provider/model your `DECK_CHAT_MODEL` resolves to (for example, `gpt-4o` is roughly `2.50` / `10.00`). Without these fields Konnect would have to look up the rate from its own internal price list, which lags newly released models. Set them explicitly to avoid empty cost tiles.

{:.warning}
> **The GitHub org-policy allowlist runs in front of Kong.** Copilot Business and Enterprise let admins pin an allowlist of models BYOK requests are permitted to claim. When the policy is set and your request names a different model, VS Code returns `400 "cannot use own model - must be: gpt-5-mini"` before the request ever reaches Kong. To resolve, set `DECK_CHAT_MODEL` (and the matching VS Code `models[].id`) to the model the policy mandates; if you want Kong to actually forward to a different upstream model, change `model.name` (the upstream name) independently of `model_alias` (the VS Code-facing name).

### AI Rate Limiting Advanced: per-Consumer token budgets

The AI Rate Limiting Advanced Plugin counts prompt and completion tokens against a per-Consumer budget. Counting tokens, not requests, is the correct unit for LLM cost control. A single Copilot agent run can be 30K+ tokens once workspace context, tool definitions, and conversation history are included. When a Consumer exhausts its budget, Kong returns `429 Too Many Requests` until the window resets.

#### Configuration details

```yaml
plugins:
  - name: ai-rate-limiting-advanced
    config:
      policies:
        - limits:
            - limit: 50000
              window_size: 60
          window_type: sliding
      identifier: consumer
      tokens_count_strategy: total_tokens
      strategy: local
      llm_format: openai
```
{:.no-copy-code}

**`policies`** is an array of rate-limiting policies. Each policy has a `limits` array of limit + window pairs and an optional `match` block for targeting specific providers or models. With no `match` block the policy applies to every request. The recipe configures 50,000 total tokens per 60-second sliding window per Consumer.

**`identifier: consumer`** scopes the counter to the Kong Consumer attached by Key Auth. Each developer gets their own bucket. Without Key Auth attaching a Consumer, this identifier would degrade to a single shared bucket; the Pre-function header rewrite is what makes per-Consumer counting work for Copilot's Bearer-style auth.

**`tokens_count_strategy: total_tokens`** counts both prompt (input) and completion (output) tokens. Alternatives are `prompt_tokens`, `completion_tokens`, or `cost`.

**`window_type: sliding`** uses a sliding-window algorithm. `fixed` is the alternative and resets all counters at the window boundary.

**`strategy: local`** keeps counters in memory on each Kong node. Fine for single-node and development. For multi-node production, switch to `strategy: redis` with a shared Redis instance so counters stay consistent across nodes.

**`llm_format: openai`** must match the AI Proxy Advanced Plugin's `llm_format` so the rate limiter parses token counts from the response correctly.

Kong returns token rate-limit headers with every response:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-AI-RateLimit-Limit-{window}-{provider}`"
    description: "Maximum tokens allowed in the window."
  - header: "`X-AI-RateLimit-Remaining-{window}-{provider}`"
    description: "Tokens remaining in the current window."
  - header: "`X-AI-RateLimit-Reset`"
    description: "Seconds until the quota is restored."
  - header: "`X-AI-RateLimit-Retry-After`"
    description: "Seconds clients should wait before retrying after a `429` response."
{% endtable %}

When the token limit is exceeded, Kong returns `429 Too Many Requests` with a `Retry-After` header.

{:.info}
> In production, store provider credentials in [Kong Vaults](/gateway/secrets-management/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. Kong supports HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the Konnect Config Store. Per-developer Consumer credentials are also good vault candidates as the team scales beyond a handful of seats.


## Apply the Kong configuration

This section configures the Control Plane in two parts. First, adopt the quickstart Control Plane into a kongctl namespace so the apply commands below can manage it. The recipe's `select_tags` and the `github-copilot-byok-recipe` namespace scope every resource so teardown removes only this recipe's configuration.

```bash
kongctl adopt control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the Control Plane.

The provider tabs below create a Service and Route at `/github-copilot`, a Pre-function Plugin for header and body normalization, a Key Auth Plugin scoped to the Service, an AI Proxy Advanced Plugin for provider-key injection and OpenAI-format passthrough or translation, an AI Rate Limiting Advanced Plugin for per-Consumer token budgets, and two demonstration Consumers with key-auth credentials. See the [kongctl documentation](/kongctl/) for more on federated configuration management.

Select your provider below, export the required environment variables, and apply.

{% navtabs "Providers" %}
{% navtab "OpenAI" %}

Export your environment variables. Set `DECK_CHAT_MODEL` to whatever model name the Copilot org policy permits. If the policy is unrestricted, pick any OpenAI chat model your account has access to:

```bash
export DECK_CHAT_MODEL='gpt-4o'   # must match VS Code's models[].id and the org Copilot allowlist
```

{:.warning}
> `DECK_CHAT_MODEL` is the contract between Copilot's policy, VS Code's `models[].id`, and Kong's `model_alias`. If your Copilot administrator has pinned a specific model (for example, `gpt-5-mini`), set this env var to that exact value and use the same string in `chatLanguageModels.json`. A mismatch fails as either `400 "cannot use own model - must be: ..."` (rejected by GitHub policy before Kong) or `400 model not configured` (rejected by Kong).

`KONNECT_CONTROL_PLANE_NAME`, `DECK_OPENAI_TOKEN`, `DECK_COPILOT_KEY_ALICE`, and `DECK_COPILOT_KEY_BOB` are already exported during the Prerequisites, so they do not need to be re-exported per tab.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - github-copilot-byok-recipe
services:
- name: github-copilot-byok
  url: http://localhost
  routes:
  - name: github-copilot-byok
    paths:
    - /github-copilot
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: pre-function
    instance_name: github-copilot-byok-normalize
    config:
      access:
      - |
        local cjson = require "cjson.safe"

        local auth = kong.request.get_header("Authorization")
        if auth and string.sub(string.lower(auth), 1, 7) == "bearer " then
          ngx.req.set_header("apikey", string.sub(auth, 8))
        end

        local body = kong.request.get_raw_body()
        if body then
          local json = cjson.decode(body)
          if json and json.temperature ~= nil then
            json.temperature = nil
            kong.service.request.set_raw_body(cjson.encode(json))
          end
        end
  - name: key-auth
    instance_name: github-copilot-byok-auth
    config:
      key_names:
      - apikey
      hide_credentials: true
  - name: ai-proxy-advanced
    instance_name: github-copilot-byok-proxy
    config:
      llm_format: openai
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
          model_alias: ${{ env "DECK_CHAT_MODEL" }}
          provider: openai
          name: ${{ env "DECK_CHAT_MODEL" }}
          options:
            input_cost: 0.25
            output_cost: 2.00
  - name: ai-rate-limiting-advanced
    instance_name: github-copilot-byok-ratelimit
    config:
      policies:
      - limits:
        - limit: 50000
          window_size: 60
        window_type: sliding
      identifier: consumer
      tokens_count_strategy: total_tokens
      strategy: local
      llm_format: openai
consumers:
- username: copilot-developer-alice
  keyauth_credentials:
  - key: ${{ env "DECK_COPILOT_KEY_ALICE" }}
- username: copilot-developer-bob
  keyauth_credentials:
  - key: ${{ env "DECK_COPILOT_KEY_BOB" }}
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: github-copilot-byok-recipe
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

{% endnavtab %}
{% navtab "Azure OpenAI" %}

Export your environment variables. For Azure OpenAI, `DECK_CHAT_MODEL` is sent as the body's `model` field, which Azure largely ignores in favor of the deployment in the URL path. It still has to match the VS Code `models[].id` and the Copilot org allowlist:

```bash
export DECK_CHAT_MODEL='gpt-4o'   # must match VS Code's models[].id and the org Copilot allowlist
```

{:.warning}
> `DECK_CHAT_MODEL` is the contract between Copilot's policy, VS Code's `models[].id`, and Kong's `model_alias`. If your Copilot administrator has pinned a specific model (for example, `gpt-5-mini`), set this env var to that exact value and use the same string in `chatLanguageModels.json`. A mismatch fails as either `400 "cannot use own model - must be: ..."` (rejected by GitHub policy before Kong) or `400 model not configured` (rejected by Kong).

`KONNECT_CONTROL_PLANE_NAME`, the `DECK_AZURE_*` credentials, `DECK_COPILOT_KEY_ALICE`, and `DECK_COPILOT_KEY_BOB` are already exported during the Prerequisites, so they do not need to be re-exported per tab.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - github-copilot-byok-recipe
services:
- name: github-copilot-byok
  url: http://localhost
  routes:
  - name: github-copilot-byok
    paths:
    - /github-copilot
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: pre-function
    instance_name: github-copilot-byok-normalize
    config:
      access:
      - |
        local cjson = require "cjson.safe"

        local auth = kong.request.get_header("Authorization")
        if auth and string.sub(string.lower(auth), 1, 7) == "bearer " then
          ngx.req.set_header("apikey", string.sub(auth, 8))
        end

        local body = kong.request.get_raw_body()
        if body then
          local json = cjson.decode(body)
          if json and json.temperature ~= nil then
            json.temperature = nil
            kong.service.request.set_raw_body(cjson.encode(json))
          end
        end
  - name: key-auth
    instance_name: github-copilot-byok-auth
    config:
      key_names:
      - apikey
      hide_credentials: true
  - name: ai-proxy-advanced
    instance_name: github-copilot-byok-proxy
    config:
      llm_format: openai
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
          model_alias: ${{ env "DECK_CHAT_MODEL" }}
          provider: azure
          name: ${{ env "DECK_CHAT_MODEL" }}
          options:
            azure_api_version: ${{ env "DECK_AZURE_API_VERSION" }}
            azure_deployment_id: ${{ env "DECK_AZURE_DEPLOYMENT_ID" }}
            azure_instance: ${{ env "DECK_AZURE_INSTANCE" }}
            input_cost: 0.25
            output_cost: 2.00
  - name: ai-rate-limiting-advanced
    instance_name: github-copilot-byok-ratelimit
    config:
      policies:
      - limits:
        - limit: 50000
          window_size: 60
        window_type: sliding
      identifier: consumer
      tokens_count_strategy: total_tokens
      strategy: local
      llm_format: openai
consumers:
- username: copilot-developer-alice
  keyauth_credentials:
  - key: ${{ env "DECK_COPILOT_KEY_ALICE" }}
- username: copilot-developer-bob
  keyauth_credentials:
  - key: ${{ env "DECK_COPILOT_KEY_BOB" }}
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: github-copilot-byok-recipe
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

{% endnavtab %}
{% navtab "AWS Bedrock" %}

Export your environment variables. Bedrock model IDs include a `provider.model-version-vN:M` shape, and the value here is what Kong sends upstream **and** what VS Code's `models[].id` has to match:

```bash
export DECK_CHAT_MODEL='anthropic.claude-sonnet-4-5-20250929-v1:0'   # must match VS Code's models[].id
```

{:.warning}
> `DECK_CHAT_MODEL` is the contract between Copilot's policy, VS Code's `models[].id`, and Kong's `model_alias`. If your Copilot administrator has pinned a specific model (for example, `gpt-5-mini`), set this env var to that exact value and use the same string in `chatLanguageModels.json`. For Bedrock, you can split the user-facing alias from the upstream model name by editing the deck config so that `model_alias` references one env var (matching VS Code and the policy) and `model.name` references a different one (the real Bedrock model ID). A mismatch fails as either `400 "cannot use own model - must be: ..."` (rejected by GitHub policy before Kong) or `400 model not configured` (rejected by Kong).

`KONNECT_CONTROL_PLANE_NAME`, the `DECK_AWS_*` credentials, `DECK_COPILOT_KEY_ALICE`, and `DECK_COPILOT_KEY_BOB` are already exported during the Prerequisites, so they do not need to be re-exported per tab.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - github-copilot-byok-recipe
services:
- name: github-copilot-byok
  url: http://localhost
  routes:
  - name: github-copilot-byok
    paths:
    - /github-copilot
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: pre-function
    instance_name: github-copilot-byok-normalize
    config:
      access:
      - |
        local cjson = require "cjson.safe"

        local auth = kong.request.get_header("Authorization")
        if auth and string.sub(string.lower(auth), 1, 7) == "bearer " then
          ngx.req.set_header("apikey", string.sub(auth, 8))
        end

        local body = kong.request.get_raw_body()
        if body then
          local json = cjson.decode(body)
          if json and json.temperature ~= nil then
            json.temperature = nil
            kong.service.request.set_raw_body(cjson.encode(json))
          end
        end
  - name: key-auth
    instance_name: github-copilot-byok-auth
    config:
      key_names:
      - apikey
      hide_credentials: true
  - name: ai-proxy-advanced
    instance_name: github-copilot-byok-proxy
    config:
      llm_format: openai
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
          model_alias: ${{ env "DECK_CHAT_MODEL" }}
          provider: bedrock
          name: ${{ env "DECK_CHAT_MODEL" }}
          options:
            bedrock:
              aws_region: ${{ env "DECK_AWS_REGION" }}
            input_cost: 0.25
            output_cost: 2.00
  - name: ai-rate-limiting-advanced
    instance_name: github-copilot-byok-ratelimit
    config:
      policies:
      - limits:
        - limit: 50000
          window_size: 60
        window_type: sliding
      identifier: consumer
      tokens_count_strategy: total_tokens
      strategy: local
      llm_format: openai
consumers:
- username: copilot-developer-alice
  keyauth_credentials:
  - key: ${{ env "DECK_COPILOT_KEY_ALICE" }}
- username: copilot-developer-bob
  keyauth_credentials:
  - key: ${{ env "DECK_COPILOT_KEY_BOB" }}
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: github-copilot-byok-recipe
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

{% endnavtab %}
{% endnavtabs %}


### Create the Copilot Usage dashboard

Create a custom dashboard at the org level, pre-filtered to this recipe's Gateway Service. The dashboard surfaces cost, token usage, request volume, model mix, per-developer (Consumer) usage, and latency for traffic through the `github-copilot-byok` Service. The dashboard JSON is in the code block below; if a labeled dashboard from a prior apply already exists, the block reuses it instead of creating a duplicate.

```bash
# Look up the Control Plane and Service IDs so the dashboard's gateway_service
# preset filter resolves to the scoped UUID Konnect expects.
CP_ID=$(kongctl get gateway control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}" -o json --jq '.id' -r)
SERVICE_ID=$(kongctl api get "/v2/control-planes/${CP_ID}/core-entities/services" \
  --pat "${KONNECT_TOKEN}" -o json \
  --jq '.data[] | select(.name=="github-copilot-byok") | .id' -r)

if [ -z "${CP_ID}" ] || [ -z "${SERVICE_ID}" ]; then
  echo "Refusing to create dashboard: CP_ID='${CP_ID}' SERVICE_ID='${SERVICE_ID}'."
  echo "Confirm the apply step succeeded and the Service is visible in Konnect, then retry."
  exit 1
fi

EXISTING_DASHBOARDS=$(kongctl api get "/v2/dashboards?filter%5Blabels.recipe%5D=github-copilot-byok-recipe" \
  --pat "${KONNECT_TOKEN}" -o json --jq '.data | length')

if [ "${EXISTING_DASHBOARDS}" -gt 0 ]; then
  echo "Copilot Usage dashboard already exists. Reusing."
else
  cat <<'EOF' | jq --arg ref "${CP_ID}:${SERVICE_ID}" '.definition.preset_filters[0].value = [$ref]' > copilot-usage-dashboard.json
{
  "name": "Copilot Usage",
  "definition": {
    "tiles": [
      {
        "id": "c0f1ee01-0000-4000-8000-000000000001",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 1 }, "position": { "col": 0, "row": 0 } },
        "definition": {
          "chart": { "type": "single_value", "chart_title": "Total cost ($)" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["cost"],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000002",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 1 }, "position": { "col": 2, "row": 0 } },
        "definition": {
          "chart": { "type": "single_value", "chart_title": "Total tokens" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["total_tokens"],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000003",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 1 }, "position": { "col": 4, "row": 0 } },
        "definition": {
          "chart": { "type": "single_value", "chart_title": "Total Copilot requests" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000004",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 0, "row": 1 } },
        "definition": {
          "chart": { "type": "top_n", "chart_title": "Top Copilot models by usage" },
          "query": {
            "limit": 10,
            "filters": [],
            "metrics": ["total_tokens", "ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000005",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 3, "row": 1 } },
        "definition": {
          "chart": { "type": "timeseries_line", "stacked": false, "chart_title": "Model usage trend (top 5)" },
          "query": {
            "limit": 5,
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["total_tokens"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model", "time"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000006",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 0, "row": 3 } },
        "definition": {
          "chart": { "type": "donut", "chart_title": "Copilot health check" },
          "query": {
            "filters": [
              { "field": "gateway_service", "operator": "not_empty" },
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["status_code_grouped"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000007",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 2, "row": 3 } },
        "definition": {
          "chart": { "type": "donut", "chart_title": "Copilot provider usage" },
          "query": {
            "filters": [
              { "field": "gateway_service", "operator": "not_empty" },
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["ai_provider"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000008",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 4, "row": 3 } },
        "definition": {
          "chart": { "type": "timeseries_bar", "stacked": true, "chart_title": "LLM latency (avg)" },
          "query": {
            "filters": [
              { "field": "ai_request_model", "operator": "not_empty" },
              { "field": "ai_request_model", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["llm_latency_average"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model", "time"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000009",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 0, "row": 9 } },
        "definition": {
          "chart": { "type": "horizontal_bar", "stacked": true, "chart_title": "Copilot usage by developer (requests)" },
          "query": {
            "filters": [
              { "field": "consumer", "operator": "not_empty" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["consumer"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-00000000000a",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 3, "row": 9 } },
        "definition": {
          "chart": { "type": "vertical_bar", "stacked": true, "chart_title": "Copilot usage by developer (tokens)" },
          "query": {
            "filters": [
              { "field": "consumer", "operator": "not_empty" }
            ],
            "metrics": ["total_tokens"],
            "datasource": "llm_usage",
            "dimensions": ["consumer"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-00000000000b",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 0, "row": 11 } },
        "definition": {
          "chart": { "type": "vertical_bar", "stacked": true, "chart_title": "AI security report (401 / 403 / 429)" },
          "query": {
            "filters": [
              { "field": "status_code", "value": ["401", "403", "429"], "operator": "in" }
            ],
            "metrics": ["request_count"],
            "datasource": "api_usage",
            "dimensions": ["status_code", "consumer"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-00000000000c",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 2, "row": 11 } },
        "definition": {
          "chart": { "type": "timeseries_bar", "stacked": true, "chart_title": "Monthly spend trends" },
          "query": {
            "limit": 10,
            "filters": [],
            "metrics": ["cost"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model", "time"],
            "time_range": { "type": "relative", "time_range": "30d" },
            "granularity": "daily"
          }
        }
      }
    ],
    "template_id": "AI_GATEWAY",
    "preset_filters": [
      { "field": "gateway_service", "value": [], "operator": "in" }
    ]
  },
  "labels": {
    "recipe": "github-copilot-byok-recipe"
  }
}
EOF
  DASHBOARD_ID=$(kongctl api post /v2/dashboards \
    -f copilot-usage-dashboard.json \
    --pat "${KONNECT_TOKEN}" -o json --jq '.id' -r)
  rm -f copilot-usage-dashboard.json
  echo "Created Copilot Usage dashboard (id: ${DASHBOARD_ID}). Open it in Konnect at Observability → Custom dashboards → 'Copilot Usage'."
fi
```
{: data-test-step="block" .collapsible }


## Try it out

With the configuration applied, configure VS Code Copilot to post Chat and agent requests to Kong, then ask a question and watch the request, attribution, and rate-limit headers flow through {{site.konnect_short_name}} Analytics.

{:.warning}
> **Do not paste a raw API key into `chatLanguageModels.json`.** The `apiKey` field only accepts a `${input:chat.lm.secret.<id>}` placeholder, which VS Code mints when you enter a key into the **Add Models... → Custom Endpoint → Chat Completions** wizard. A raw value in that field is silently dropped: VS Code sends `Authorization: Bearer` with no key, and Kong returns `401 No API key found in request`.

### Add the Custom Endpoint to VS Code

VS Code stores Custom Endpoint API keys in its encrypted OS-keychain secret storage. `chatLanguageModels.json` only ever sees a `${input:chat.lm.secret.<id>}` placeholder that resolves to the stored value at request time. The only supported way to mint that placeholder is the **Add Models...** wizard, which prompts for the key and writes both the secret entry and the placeholder for you.

In VS Code:

1. Open the **Chat** view (`Ctrl+Alt+I` / `Cmd+Ctrl+I`).
1. Click the **model picker** at the bottom of the Chat input.
1. Select **Manage Language Models...**.
1. Click **Add Models...** → **Custom Endpoint** → **Chat Completions**.
1. When VS Code prompts for an **API key**, paste the value of `$DECK_COPILOT_KEY_ALICE`. Copy it with `printf '%s' "$DECK_COPILOT_KEY_ALICE"` (not `echo`) so a trailing zsh `%` marker is never included. That character is a prompt artifact, not part of the key, and pasting it produces a `401` from Key Auth.

VS Code stores the literal key in the OS keychain and opens `chatLanguageModels.json` with a generated stub entry whose `apiKey` field is already filled in with a `${input:chat.lm.secret.<id>}` placeholder. Edit the `name`, `models[].id`, `models[].name`, and `models[].url` fields to match this recipe. **Leave the `apiKey` line exactly as the wizard wrote it**:

```json
[
  {
    "name": "Kong AI Gateway",
    "vendor": "customendpoint",
    "apiKey": "${input:chat.lm.secret.157fd74e}",
    "apiType": "chat-completions",
    "models": [
      {
        "id": "gpt-4o",
        "name": "GPT-4o (via Kong)",
        "url": "http://localhost:8000/github-copilot/v1/chat/completions",
        "toolCalling": true,
        "vision": true,
        "maxInputTokens": 128000,
        "maxOutputTokens": 16000
      }
    ]
  }
]
```
{:.no-copy-code}

The hex suffix after `chat.lm.secret.` is per-entry. Yours will differ from the example. Four behaviors are load-bearing:

- **`apiKey`** is a `${input:chat.lm.secret.<id>}` reference, not a literal. Re-running the **Add Models...** wizard mints a new secret and a new placeholder; replacing the wizard-generated value with a raw key disables auth entirely. To rotate, open **Manage Language Models...** → select the entry → **Edit API Key** and VS Code updates the stored secret behind the same placeholder.
- **`models[].id`** must equal `DECK_CHAT_MODEL` exactly. VS Code sends this string as the body's `model` field, and Kong's `model_alias` rejects anything else with `400 model not configured`. If your Copilot administrator has pinned an allowlist (for example, `gpt-5-mini`), set this value AND `DECK_CHAT_MODEL` to that exact name.
- **`models[].url`** is the **full** chat-completions path. VS Code posts to the URL verbatim; it does not append `/chat/completions` for you.
- **Window reload after edits.** After editing `chatLanguageModels.json`, run **Developer: Reload Window** so VS Code re-parses the file. The Chat model picker shows the new entry. Select **GPT-4o (via Kong)**.

### Ask Copilot a question

In the Chat view, with **GPT-4o (via Kong)** selected, ask any question. For example:

```text
> Explain what a Kong Consumer is in one sentence.
```
{:.no-copy-code}

Copilot Chat sends the request through Kong, which authenticates the developer, normalizes the body, injects the provider key, and forwards. The response streams back into the Chat view. Subsequent requests reuse the same credential silently.

### Confirm Bearer-to-apikey rewrite and temperature strip

The Pre-function Plugin is doing two invisible-to-the-developer rewrites on every request. To verify them, you can inspect the request payload in {{site.konnect_short_name}} Analytics or with `log_payloads: true` going to a logging Plugin sink. Two signals confirm correctness:

- Key Auth attributes the request to the matching Consumer (`copilot-developer-alice` or `copilot-developer-bob`), visible in the **Top developers** tiles on the **Copilot Usage** dashboard.
- The upstream payload (visible in `log_payloads: true` output) does not contain a `temperature` field. If you point this Kong Service at a reasoning model (gpt-5, o-series) and Copilot Chat returns answers instead of `400`, the strip is working.

If you want to see the rewrites live during local development, temporarily insert two `kong.log.notice` lines at the top of the Pre-function access block to dump the inbound headers and body, then watch the data plane logs:

{% raw %}
```bash
docker logs -f $(docker ps --filter ancestor=kong/kong-gateway --format '{{.Names}}') 2>&1 \
  | grep -iE 'authorization|apikey'
```
{% endraw %}

Remove the diagnostic lines once you have confirmed `"authorization":"Bearer <key>"` is arriving. Leaving them in writes the full prompt, tool definitions, and file contents from every Copilot request into your gateway logs.

### Hit the model-alias gate

To see the alias guardrail in action, edit `chatLanguageModels.json` and change `models[].id` to a different model name, for example `gpt-3.5-turbo`. Save. Re-select the model in the picker and ask Copilot another question. Kong rejects the request:

```text
Request failed: 400 model not configured
```
{:.no-copy-code}

Change `id` back to the value of `DECK_CHAT_MODEL` and the request succeeds again. This is the Kong-side enforcement boundary: developers cannot use a model the platform team has not configured a target for, even if VS Code's UI offers it.

### Hit the per-Consumer rate limit

The recipe configures 50,000 total tokens per 60-second sliding window per Consumer. Copilot agent runs with workspace context routinely consume 30,000+ tokens per turn. A single multi-tool reply can come close to exhausting the window on its own. Send two or three prompts in quick succession that each include meaningful file context (for example, ask Copilot to summarize a file in your repo) and Kong returns:

```text
Request failed: 429 Too Many Requests
```
{:.no-copy-code}

The response includes a `Retry-After` header indicating how many seconds remain in the window. Because `identifier: consumer` scopes the bucket to the developer, the other Consumer (`copilot-developer-bob`) still has its full budget at the same instant — rotate VS Code's stored credential via **Manage Language Models... → Edit API Key** to the value of `$DECK_COPILOT_KEY_BOB` to verify.

### Explore in Konnect

Open [{{site.konnect_product_name}}](https://cloud.konghq.com/) to see the recipe's resources in place.

**Copilot Usage dashboard**

Navigate to **Observability → Custom dashboards → `Copilot Usage`**. The dashboard is pre-filtered to the `github-copilot-byok` Gateway Service and surfaces:

- Total cost, total tokens, and request count for the recipe's traffic.
- Top Copilot models by token and request volume, plus a model-usage trend line.
- Health-check, provider-share, and average-latency breakdowns.
- Per-developer (Consumer) usage broken out by request count and token volume — the per-developer ceilings the rate limiter enforces are directly visible here.
- An AI security report scoped to 4XX responses on the recipe's Route.

LLM analytics data takes 2–5 minutes to surface after the first successful request. If the dashboard remains empty beyond that, see [Troubleshooting](#troubleshooting) below.

**Gateway resources**

Navigate to **API Gateway → Gateways → `github-copilot-byok-recipe`**. The Control Plane the quickstart provisioned and `kongctl adopt` attached to this namespace surfaces:

- **Gateway services → `github-copilot-byok`**. The Service the apply block registered. Its detail page has tabs for Configuration, Routes, Plugins, and Analytics.
  - **Routes** tab: the `/github-copilot` Route.
  - **Plugins** tab: Pre-function, Key Auth, AI Proxy Advanced, and AI Rate Limiting Advanced, all scoped to the Service.
- **Consumers**: `copilot-developer-alice` and `copilot-developer-bob`, each with a Key Auth credential.

The Gateway Service's **Analytics** tab and the **Observability** L1 menu remain available for deeper exploration beyond the curated dashboard above.

## Troubleshooting

### `401 No API key found in request` from VS Code

Kong's Key Auth Plugin returns this when the `apikey` header is missing. Which, for Copilot, means the `Authorization` header was either absent or arrived as a bare `Bearer` with no value. Verify in this order:

1. **Confirm the request reached Kong with a non-empty Bearer value.** Add the diagnostic `kong.log.notice` lines described in the [Confirm Bearer-to-apikey rewrite](#confirm-bearer-to-apikey-rewrite-and-temperature-strip) section and look for `"authorization":"Bearer <key>"`. If the value is literally `Bearer` with nothing after, VS Code did not resolve the secret placeholder.
1. **Re-mint the placeholder.** Open **Manage Language Models...**, remove the {{site.ai_gateway_name}} entry, run **Add Models... → Custom Endpoint → Chat Completions** again, and paste the key when prompted. A `chatLanguageModels.json` entry whose `apiKey` was hand-typed (rather than wizard-generated) is silently invalid even if its shape looks identical to a working one.
1. **Strip stray characters from the key.** Copy the value with `printf '%s' "$DECK_COPILOT_KEY_ALICE"`. zsh's trailing `%` marker for newline-less output is a common silent-401 source.

### Dashboard is empty after a few minutes

If **Observability → Custom dashboards → `Copilot Usage`** shows no data 5+ minutes after a successful request, work outward from the data plane:

1. **Confirm requests reached the data plane.** Tail `docker logs` on the Kong container and trigger a Copilot prompt; you should see access-log lines for `POST /github-copilot/v1/chat/completions`. If the access log is silent, the request never left VS Code or never hit Kong — fix the client side first.

1. **Confirm the data plane is reporting to Konnect telemetry.** A data plane that was relaunched (for example, recreated with new env vars) sometimes fails to reconnect to the telemetry endpoint:

   {% raw %}
   ```bash
   docker logs $(docker ps --filter ancestor=kong/kong-gateway --format '{{.Names}}') 2>&1 \
     | grep -iE 'telemetry|cluster_telemetry|connected to.*tp\.konghq'
   ```
   {% endraw %}

   A healthy node shows a successful connection to `<region>.tp.konghq.com:443`. Repeated TLS or DNS errors mean telemetry is silently dropping; restart the container and re-check.

1. **Confirm raw requests are landing in Konnect.** Open **Observability → Analytics → Requests**, scope to the `github-copilot-byok-recipe` Control Plane, and verify recent 2xx entries appear. If this view is populated but the custom dashboard is not, the dashboard's filter or tiles are the issue. If this view is also empty, telemetry is the issue (step 2).

1. **Confirm the dashboard filter resolved to a real Service ID.** The dashboard's `preset_filters[0].value` is set by jq to `${CP_ID}:${SERVICE_ID}` during creation. Re-run the lookups and verify both IDs return non-empty values:

   ```bash
   CP_ID=$(kongctl get gateway control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
     --pat "${KONNECT_TOKEN}" -o json --jq '.id' -r)
   echo "CP_ID=${CP_ID}"
   kongctl api get "/v2/control-planes/${CP_ID}/core-entities/services" \
     --pat "${KONNECT_TOKEN}" -o json \
     --jq '.data[] | select(.name=="github-copilot-byok") | .id' -r
   ```

   If either is empty, delete the dashboard via the cleanup block below and re-run the dashboard creation step.

1. **Send a few more requests if tiles still look empty.** Several tiles filter out `ai_provider = UNSPECIFIED`. Brand-new gateways occasionally tag the first request or two as `UNSPECIFIED` while the AI Proxy Advanced Plugin reports provider metadata back to Konnect; a handful of additional Copilot prompts brings the tiles to life.

## Variations and next steps

- **Add SSO with Consumer Group tiers.** Replace Key Auth with the [OpenID Connect](/plugins/openid-connect/) Plugin pointed at your IdP, define Consumer Groups for `copilot-standard-users` and `copilot-power-users`, scope separate AI Proxy Advanced Plugins to each group, and let the user's group claim drive which model they can access. The [Claude Code SSO](/cookbooks/claude-code-sso/) recipe demonstrates this pattern end-to-end.
- **Add code-secret PII redaction.** Add the [AI Sanitizer](/plugins/ai-sanitizer/) Plugin before AI Proxy Advanced to redact API keys, tokens, and other secrets from prompts before they reach the LLM provider. Developers pasting `.env` snippets into Copilot Chat is a real exfiltration risk; this Plugin catches it server-side.
- **Switch to monthly token budgets.** The 60-second window here is intentionally aggressive for the demo so a few prompts visibly exhaust it. Production teams usually enforce monthly budgets, for example {%raw%}`limits: [{limit: 5000000, window_size: 2592000}]`{%endraw%} for a 5 million token monthly ceiling per Consumer. Combine multiple `limits` entries to enforce burst and sustained budgets simultaneously.
- **Multi-node rate limiting with Redis.** The recipe uses `strategy: local`, which keeps counters in memory on each Kong node. For multi-node clusters, switch to `strategy: redis` and point to a shared Redis instance.
- **Move credentials into a vault.** Use [Kong Vaults](/gateway/secrets-management/) to source provider keys and Consumer credentials from HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, or the Konnect Config Store. Replace {% raw %}`${{ env "DECK_OPENAI_TOKEN" }}`{% endraw %} style references with `{vault://backend/key}` references.
- **Cover non-Copilot OpenAI-format clients.** This recipe works for any client that speaks the OpenAI Chat Completions API and authenticates with `Authorization: Bearer`. Cursor, Continue, and similar IDE assistants can point at the same Route with their own Consumer credential.

## Cleanup

The recipe's `select_tags` and kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration.

Delete the **Copilot Usage** custom dashboard. The dashboard is an org-level resource and outlives the Control Plane, so remove it before tearing down Kong:

```bash
DASHBOARD_IDS=$(kongctl api get "/v2/dashboards?filter%5Blabels.recipe%5D=github-copilot-byok-recipe" \
  --pat "${KONNECT_TOKEN}" -o json --jq '.data[].id' -r)

if [ -z "${DASHBOARD_IDS}" ]; then
  echo "No Copilot Usage dashboard found. Skipping."
else
  for id in ${DASHBOARD_IDS}; do
    if kongctl api delete "/v2/dashboards/${id}" --pat "${KONNECT_TOKEN}"; then
      echo "Deleted Copilot Usage dashboard ${id}."
    else
      echo "Failed to delete dashboard ${id}."
    fi
  done
fi
```

Tear down Kong by deleting the local data plane and the {{site.konnect_product_name}} Control Plane:

```bash
export KONNECT_CONTROL_PLANE_NAME='github-copilot-byok-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```

Remove the {{site.ai_gateway_name}} entry from VS Code. Open the Chat view → model picker → **Manage Language Models...** → select **{{site.ai_gateway_name}}** → **Remove**. This deletes the entry from `chatLanguageModels.json` AND the stored secret from the OS keychain. Copilot resumes routing to GitHub's hosted models for the seat.
