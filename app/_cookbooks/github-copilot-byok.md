---
title: GitHub Copilot BYOK Custom Endpoint
description: Route GitHub Copilot Chat and agent traffic through {{site.base_gateway}} via Copilot's Bring Your Own Key Custom Endpoint, with per-consumer attribution, request normalization, and token rate limiting.
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
  ai-gateway: '2.0'
categories:
  - llm
  - access-control
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - key-auth
  - ai-model
  - ai-model-provider
  - pre-function
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
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped {{site.ai_gateway}} and local data plane.

        1. Create a new personal access token by opening the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. You reuse the same token later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script. The `-e` flags raise the data plane's nginx body buffer so Copilot's large request payloads (full conversation context, tool definitions, file contents) stay in memory instead of spilling to disk:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='github-copilot-byok-recipe'
           curl -Ls https://get.konghq.com/ai | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=16m \
               -e KONG_NGINX_HTTP_CLIENT_MAX_BODY_SIZE=16m
           ```

           The script provisions an {{site.ai_gateway}} named `github-copilot-byok-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl and jq
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration, plus [jq](https://jqlang.org/) for JSON processing in the dashboard-creation and cleanup steps.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Install **jq** from [jqlang.org](https://jqlang.org/).

        Verify that both are installed:

        ```bash
        kongctl version
        jq --version
        ```
    - title: GitHub Copilot in VS Code
      content: |
        This recipe routes GitHub Copilot Chat and agent traffic through {{site.base_gateway}} using Copilot's **Bring Your Own Key Custom Endpoint**. The Custom Endpoint feature is currently in stable VS Code on Copilot Enterprise seats and in preview on Copilot Business seats. Verify the current availability matrix at the [VS Code language models docs](https://code.visualstudio.com/docs/copilot/customization/language-models) before you start.

        1. Install **VS Code** version 1.122 or later from [code.visualstudio.com](https://code.visualstudio.com/).
        1. Install the **GitHub Copilot** and **GitHub Copilot Chat** extensions and sign in with a GitHub account that has a Copilot Business or Enterprise seat.
        1. Have your **Copilot administrator** enable both of the following in the GitHub organization's Copilot policy settings:
           - **Bring Your Own Language Model Key in VS Code** (the BYOK policy gate).
           - **Editor Preview Features** (required as long as Custom Endpoint is in preview on your seat type).

           Without these policies, the VS Code Chat picker either doesn't surface the Custom Endpoint option, or accepts the configuration and rejects every request at runtime.

        1. Generate two AI Consumer credentials. These become the API key values each developer enters into the VS Code **Add Models...** wizard. Export them now so the apply step picks them up:

           ```bash
           export DECK_COPILOT_KEY_ALICE="$(openssl rand -hex 24)"
           export DECK_COPILOT_KEY_BOB="$(openssl rand -hex 24)"
           ```

           When you later paste a key into VS Code, copy it with `printf '%s' "$DECK_COPILOT_KEY_ALICE"` rather than `echo "$DECK_COPILOT_KEY_ALICE"`. zsh renders output that lacks a trailing newline with a bold `%`. That character isn't part of the key, and pasting it produces a `401 No API key found in request` from Kong.

           In production, generate one credential per developer (or one per VS Code workstation) and distribute through your secrets manager rather than shell exports.

        {:.warning}
        > **Kong cannot proxy inline ghost-text completions.** Copilot's autocomplete (the gray suggestion text that appears as you type) always runs on GitHub's infrastructure, and the Custom Endpoint setting does not affect it. The recipe governs Copilot Chat and agent (`@workspace`, `#editor`, Copilot CLI) traffic only.
    - title: AI Credentials
      content: |
        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        This tutorial uses OpenAI:

        1. [Create an OpenAI account](https://platform.openai.com/).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key as an environment variable:

           ```bash
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-OPENAI-KEY'
           ```
        {% endnavtab %}
        {% navtab "Azure OpenAI" %}
        This tutorial uses [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/):

        1. Ensure you have an Azure OpenAI resource with at least one chat deployment.
        1. Export your resource details. `DECK_AZURE_DEPLOYMENT_ID` is the deployment name you assigned in the Azure portal, not the underlying model name:

           ```bash
           export DECK_AZURE_API_KEY='YOUR-AZURE-OPENAI-KEY'
           export DECK_AZURE_INSTANCE='your-azure-resource'
           export DECK_AZURE_DEPLOYMENT_ID='your-deployment-name'
           export DECK_AZURE_API_VERSION='YOUR-API-VERSION'  # check Azure docs for current version
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        This tutorial uses [AWS Bedrock](https://docs.aws.amazon.com/bedrock/):

        1. Ensure you have an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled for the chat model you plan to use.
        1. Export your AWS credentials:

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
  authenticates each developer with a consumer-scoped credential, normalizes the
  request body so reasoning models accept it, and attributes every token to a named
  developer in {{site.konnect_short_name}} {{site.observability}}.

  The recipe configures Copilot's
  [Bring Your Own Key (BYOK) Custom Endpoint](https://code.visualstudio.com/docs/copilot/customization/language-models)
  in VS Code to post to an AI Model at `/github-copilot/v1/chat/completions`, then
  chains three pieces of {{site.ai_gateway_name}} config in front of it:
    * A [Pre-Function](/ai-gateway/policies/pre-function/) Policy to normalize the request
    * A Key Auth AI Auth Strategy to authenticate each developer
    * An [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to enforce
  per-consumer token budgets

  Scope: this recipe governs Copilot Chat and agent traffic (the Chat view, agent
  modes, and Copilot CLI). Inline ghost-text code completions always run on
  GitHub's infrastructure, and Kong can't proxy them, regardless of the
  Custom Endpoint setting.
---

## The problem

Routing GitHub Copilot through a central control point breaks down on three independent fronts at once. Each one is a real wall teams hit; together they are why provider-credential reuse falls apart.

**Credentials live on developer machines.** A team that enables Copilot BYOK without a gateway distributes provider API keys directly to every engineer through 1Password, shell profiles, or chat. Every request is indistinguishable on the provider bill, every leaked key is a fleet-wide rotation, and there is no way to revoke one developer without touching everyone.

**Copilot pins request fields that some upstreams reject.** VS Code's Custom Endpoint client posts requests with `temperature: 0.1` hard-coded into the body, and Copilot's BYOK schema doesn't expose a field for changing it. When the upstream is a reasoning model (gpt-5 family, o-series), the provider returns:

```text
400 ... 'temperature' does not support 0.1 ... Only the default (1) value is supported
```
{:.no-copy-code}

You can't fix this in VS Code's BYOK configuration. The request has to be normalized at the gateway.

**Org-policy model allowlists reject the wrong name.** GitHub Copilot Business and Enterprise let admins pin an allowlist of model IDs that BYOK requests are permitted to claim. Copilot rejects a request that names any other model before the request ever leaves VS Code, with:

```text
400 "cannot use own model - must be: gpt-5-mini"
```
{:.no-copy-code}

GitHub's policy layer enforces this allowlist, not the LLM provider or Kong. As a result, the model ID a developer types into VS Code (`models[].id` in the BYOK config) has to match the org's allowlist, regardless of what model Kong actually forwards to upstream.

**No per-developer attribution.** Even when traffic reaches the provider, the bill is a single line item. There is no built-in way to see which developer used how many tokens, which model, or how often a developer is approaching the team's monthly budget. Cost decisions become retroactive.

The root issue is that trust, normalization, and accounting all need to happen on a server you control before the request hits the provider. That control point is what this recipe builds.

## The solution

This recipe puts {{site.base_gateway}} between VS Code and the LLM provider so every Copilot Chat or agent request flows through a server you control:

- **Server-side provider credentials.** Developers never hold the provider key. An AI Model Provider holds it and injects it server-side. Each developer authenticates to Kong with their own short-lived AI Consumer credential, which is the value they paste into VS Code's `apiKey` field. Rotating one developer's credential is a single kongctl config change; rotating the provider key is also one change, not a fleet-wide push.
- **Per-consumer attribution.** Kong attributes every request to a named AI Consumer in {{site.konnect_short_name}} {{site.observability}}, so cost, token usage, and model mix can be sliced per developer.
- **Server-side request normalization.** A Pre-Function Policy runs ahead of the rest of the request chain and rewrites two things before anything else sees the request: it converts Copilot's `Authorization: Bearer <apiKey>` header into the `apikey` header the Key Auth AI Auth Strategy expects, and it strips `temperature` from the JSON body so reasoning models accept the request.
- **Token-budget rate limiting.** Each AI Consumer has a per-minute token budget enforced by an AI Rate Limiting Advanced Policy. Exhaustion returns `429 Too Many Requests` until the window resets.
- **Org-allowlist alignment.** The AI Model's route-level model selector is parameterized by `CHAT_MODEL`, so the same env var pins both the name VS Code sends and the name Kong matches against. If the org policy mandates `gpt-5-mini`, set the env var to `gpt-5-mini`, and use the same value in the VS Code `id` field. The upstream target's `name` independently controls what Kong actually sends to the provider.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant VS as VS Code Copilot
    participant K as Kong AI Gateway
    participant L as LLM Provider

    VS->>K: POST /github-copilot/v1/chat/completions<br/>Authorization: Bearer &lt;apiKey&gt;<br/>body: {model, messages, temperature: 0.1}
    activate K
    K->>K: pre-function policy (Bearer to apikey, strip temperature)
    K->>K: key-auth Auth Strategy (validate apikey, attach Consumer)
    K->>K: AI Model (match route.model.values, AI Model Provider injects credentials)
    K->>K: ai-rate-limiting-advanced policy (per-Consumer token budget)
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
  - component: "Pre-Function AI Policy"
    responsibility: "Rewrites `Authorization: Bearer` to `apikey` so the Key Auth AI Auth Strategy can match it; strips `temperature` from the body so reasoning models accept it."
  - component: "Key Auth AI Auth Strategy"
    responsibility: "Validates the per-developer credential and attaches the request to the matching AI Consumer for downstream attribution and rate-limit counting."
  - component: "AI Model and AI Model Provider"
    responsibility: "Matches the body's `model` against the route's model selector, injects the provider API key server-side, translates to the upstream's native format if needed, and forwards."
  - component: "AI Rate Limiting Advanced Policy"
    responsibility: "Counts prompt and completion tokens against the AI Consumer's per-window budget and returns `429` on exhaustion."
  - component: "LLM provider"
    responsibility: "Model inference. Receives the Kong-injected credential and the normalized request body."
{% endtable %}

## How it works

When a developer asks Copilot Chat a question, the request flows through Kong before reaching the LLM provider. Here is the complete lifecycle:

1. **Request from VS Code.** The Copilot extension posts `POST /github-copilot/v1/chat/completions` to Kong with the developer's AI Consumer credential in the `Authorization: Bearer <apiKey>` header and an OpenAI-format chat body. The body's `model` field equals the value of `models[].id` in `chatLanguageModels.json`, which the recipe pins to `CHAT_MODEL`.

1. **Header and body normalization.** The Pre-Function Policy checks the `Authorization` header, strips the `Bearer ` prefix, and writes the bare credential into a new `apikey` header that the Key Auth AI Auth Strategy reads. In the same pass it decodes the JSON body, removes the `temperature` field if present, and writes the body back.

1. **Per-developer authentication.** The Key Auth AI Auth Strategy reads the `apikey` header, looks up the matching credential, and attaches the request to the corresponding AI Consumer (`copilot-developer-alice` or `copilot-developer-bob` in this recipe). The AI Auth Strategy rejects unknown credentials with `401 Unauthorized`.

1. **Model gating and provider-key injection.** The AI Model matches the body's `model` field against its route-level model selector. The recipe configures one Model whose selector value equals `CHAT_MODEL`, so only requests naming that exact model reach it. On a match, the AI Model Provider injects the provider API key into the upstream request and, if the upstream uses a non-OpenAI format (Bedrock), translates the body from OpenAI to the upstream format.

1. **Token rate limiting.** The AI Rate Limiting Advanced Policy counts prompt and completion tokens against the AI Consumer's per-window budget. The policy adds rate-limit headers (`X-AI-RateLimit-Remaining-*`) to the response. Exhaustion returns `429 Too Many Requests` with a `Retry-After` header.

1. **Response back to VS Code.** The provider response flows back through Kong to VS Code. Copilot renders the chat reply or runs the requested tool call.

### Pre-Function: request normalization

The Pre-Function Policy runs Lua before the rest of the request chain. The recipe uses it to fix two things Copilot's BYOK client can't fix itself: it converts `Authorization: Bearer <apiKey>` into the `apikey` header the Key Auth AI Auth Strategy expects, and it strips the hard-coded `temperature: 0.1` field from the body so reasoning models accept the request.

{:.warning}
> **This ordering has not been confirmed against a live {{site.ai_gateway}}.** The Pre-Function header rewrite has to be visible to the Key Auth AI Auth Strategy check for authentication to work at all. {{site.ai_gateway_name}} 2.0 documents AI Auth Strategy evaluation and attached AI Policy execution as ordered ("Authentication runs first, through the AI Model's assigned AI Auth Strategy, not through an attached AI Policy"), but does not explicitly document whether a Pre-Function Policy is special-cased to run ahead of that check the way the 1.0 plugin's priority did. If Copilot requests fail with `401` before any Lua output appears in your data plane logs, this ordering is the first thing to verify.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_policies:
  - ref: github-copilot-byok-normalize
    type: pre-function
    display_name: "github-copilot-byok request normalization"
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

**`config.access`**. An array of Lua source strings, each of which becomes a function executed in the access phase. Each function has full access to the [Kong PDK](/gateway/pdk/reference/) and the `ngx` namespace.

**`ngx.req.set_header("apikey", ...)`**. The standard PDK function `kong.service.request.set_header` only mutates headers sent upstream; it doesn't change what later processing sees. The Authorization-to-apikey rewrite has to be visible to the Key Auth AI Auth Strategy, so the recipe drops down to `ngx.req.set_header`, which mutates the underlying nginx request.

**Body rewrite via `kong.service.request.set_raw_body`**. Replaces the body that gets forwarded upstream. For OpenAI and Azure OpenAI (passthrough paths), this is the body the provider sees. For AWS Bedrock, the AI Model Provider translates the request from OpenAI to Bedrock format on the way out; verify that the temperature normalization survives that translation in your environment if you point this recipe at Bedrock with a reasoning-style upstream.

{:.info}
> **VS Code Copilot pins `temperature: 0.1` with no UI override.** Reasoning models (gpt-5 family, o-series) reject any temperature other than the default 1. The Pre-Function strip above is what makes those models usable as Copilot BYOK upstreams.

### Key Auth: per-developer authentication and AI Consumer mapping

The Key Auth AI Auth Strategy authenticates each request against an AI Consumer credential. Authentication is an AI Auth Strategy, not a policy, in {{site.ai_gateway_name}} 2.0. The recipe ships two AI Consumers (`copilot-developer-alice` and `copilot-developer-bob`) so per-consumer attribution in {{site.konnect_short_name}} {{site.observability}} is visible from the first apply. Each developer enters their assigned credential into the VS Code **Add Models... → Custom Endpoint → Chat Completions** wizard, which stores it in the OS keychain and writes a `${input:chat.lm.secret.<id>}` placeholder into `chatLanguageModels.json`. The Pre-Function Policy above ensures the AI Auth Strategy sees the rewritten value in the `apikey` header it expects.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_auth_strategies:
  - ref: github-copilot-byok-auth
    type: key-auth
    display_name: "github-copilot-byok key auth"
    config:
      key_names:
        - apikey
      hide_credentials: true

ai_gateway_consumers:
  - ref: copilot-developer-alice
    name: copilot-developer-alice
    display_name: "Copilot developer: Alice"
    type: api-key
    credentials:
      - ref: copilot-developer-alice-credential
        name: copilot-developer-alice-credential
        display_name: "Alice's Copilot API key"
        type: api-key
        api_key: !secret {source: !env DECK_COPILOT_KEY_ALICE}
```
{% endraw -%}
{:.no-copy-code}

**`key_names: [apikey]`**. The header Kong reads for the API key. The Pre-Function Policy normalizes Copilot's `Authorization: Bearer` into this header, so a single name suffices and you don't need a fallback to the query string or other headers.

**`hide_credentials: true`**. Strips the `apikey` header from the request before Kong forwards it upstream. The provider never sees the AI Consumer's gateway credential.

**`api_key` is write-only.** An AI Consumer credential's `api_key` field must be a `!secret` reference. Kong rejects a plain string here, even for a demo value.

**AI Consumer scaling.** Add one AI Consumer per developer (or per VS Code workstation) with its own nested credential. The recipe defines two for demonstration; production deployments typically generate AI Consumers programmatically as part of developer onboarding.

### AI Model and AI Model Provider: provider routing and model gating

An AI Model Provider holds the credentials for one upstream account; an AI Model matches the request's `model` field against a route-level selector and forwards through a target that references the AI Model Provider. With one Model configured for this recipe, the selector acts as a hard gate: only a request whose body names the value in `CHAT_MODEL` reaches this Model. This is what makes the org-policy allowlist alignment work. Set `CHAT_MODEL` to the name your Copilot admin requires, and the VS Code `id` field has to match, or the request never reaches the target that holds the provider credentials.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_models:
  - ref: github-copilot-byok-model
    type: model
    display_name: "github-copilot-byok"
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - github-copilot-byok-auth
    policies:
      - github-copilot-byok-normalize
      - github-copilot-byok-ratelimit
    config:
      max_request_body_size: 10485760
      response_streaming: allow
      logging:
        payloads: true
      route:
        paths:
          - /github-copilot
        model:
          body_param: model
          values:
            - !env CHAT_MODEL
    targets:
      - name: !env CHAT_MODEL
        provider: github-copilot-byok-provider
        config:
          type: openai
          input_cost: 0.25
          output_cost: 2.00
```
{% endraw -%}
{:.no-copy-code}

**`formats: [{type: openai}]`**. Copilot speaks the OpenAI Chat Completions API. For OpenAI and Azure OpenAI upstreams the request passes through natively. For AWS Bedrock the AI Model Provider translates the request from OpenAI to Bedrock's `InvokeModel` shape and the response back, so Copilot's client sees an OpenAI-shaped response in both cases.

**`route.model.values`**. The value VS Code sends in the body and the value Kong matches. This field accepts exactly one value per AI Model, so pointing this recipe at a second model tier means adding a second Model entity, the same pattern the [Basic LLM Routing recipe](/cookbooks/basic-llm-routing/) uses for alias routing between two tiers.

**`targets[].name`** equals **`route.model.values`** in this recipe. The selector is what VS Code sends and what Kong matches; the target `name` is what Kong sends upstream. For OpenAI and Azure OpenAI both are the same value (the user-visible model ID); for Bedrock, `name` is the long Bedrock model ID your admin's allowlist entry has to reference. Change the env var if you want the VS Code-facing value to differ from the upstream name.

**`config.auth`** (on the AI Model Provider, not shown in the target snippet). The credential injected on every upstream request. The shape varies by provider; the Apply section's per-provider navtabs show the OpenAI, Azure OpenAI, and Bedrock variants. The provider key is never sent to VS Code and never sits on the developer's machine.

**`max_request_body_size: 10485760`**. Sets the maximum allowed body to 10 MB. Copilot Chat conversations accumulate large context (chat history, open files, workspace symbols), and the default limit can reject these requests.

**`response_streaming: allow`**. Lets responses stream back to VS Code as Server-Sent Events. Copilot Chat renders streamed token output progressively.

**`logging.payloads`**. Captures full request and response bodies for audit and cost attribution. The exact behavior of this field relative to 1.0's separate statistics-vs-payload logging fields hasn't been confirmed against a live {{site.ai_gateway}}; {{site.konnect_short_name}} {{site.observability}} captures token usage independently of this setting either way.

**`targets[].config.input_cost`** and **`output_cost`**. USD per 1,000,000 tokens for prompt and completion respectively. Kong multiplies the reported `prompt_tokens` and `completion_tokens` by these rates per request and emits the result as the `cost` metric to {{site.konnect_short_name}} {{site.observability}}, which is what populates the **Total cost** tile on the dashboard. The recipe ships with `0.25` / `2.00`, reasonable for a small reasoning-class model like `gpt-5-mini`. Replace with the published rates for whatever provider/model your `CHAT_MODEL` resolves to (for example, `gpt-4o` is roughly `2.50` / `10.00`). Without these fields, {{site.konnect_short_name}} looks up the rate from its own internal price list, which lags newly released models.

{:.warning}
> **The GitHub org-policy allowlist runs in front of Kong.** Copilot Business and Enterprise let admins pin an allowlist of models BYOK requests are permitted to claim. When the policy is set and your request names a different model, VS Code returns `400 "cannot use own model - must be: gpt-5-mini"` before the request ever reaches Kong. To resolve, set `CHAT_MODEL` (and the matching VS Code `models[].id`) to the model the policy mandates; if you want Kong to actually forward to a different upstream model, change `targets[].name` (the upstream name) independently of `route.model.values` (the VS Code-facing value).

### AI Rate Limiting Advanced: per-consumer token budgets

The AI Rate Limiting Advanced Policy counts prompt and completion tokens against a per-consumer budget. Counting tokens, not requests, is the correct unit for LLM cost control. A single Copilot agent run can be 30K+ tokens once workspace context, tool definitions, and conversation history are included. When an AI Consumer exhausts its budget, Kong returns `429 Too Many Requests` until the window resets.

#### Configuration details

```yaml
ai_gateway_policies:
  - ref: github-copilot-byok-ratelimit
    type: ai-rate-limiting-advanced
    display_name: "github-copilot-byok token rate limiting"
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

**`config.policies`** is an array of rate-limiting policies. Each has a `limits` array of limit and window pairs and an optional `match` block for targeting specific providers or models. With no `match` block the policy applies to every request. The recipe configures 50,000 total tokens per 60-second sliding window per AI Consumer.

**`identifier: consumer`** scopes the counter to the AI Consumer that the Key Auth AI Auth Strategy attaches. Each developer gets their own bucket. Without an AI Consumer attached to the request, this identifier degrades to a single shared bucket, which is why the Pre-Function header rewrite matters for per-consumer counting on Copilot's Bearer-style auth.

**`tokens_count_strategy: total_tokens`** counts both prompt (input) and completion (output) tokens. Alternatives are `prompt_tokens`, `completion_tokens`, or `cost`.

**`window_type: sliding`** uses a sliding-window algorithm. `fixed` is the alternative and resets all counters at the window boundary.

**`strategy: local`** keeps counters in memory on each Kong node. Fine for single-node and development. For multi-node production, switch to `strategy: redis` with a shared Redis instance so counters stay consistent across nodes.

**`llm_format: openai`** must match the AI Model's `formats` entry so the rate limiter parses token counts from the response correctly.

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

When an AI Consumer exceeds the token limit, Kong returns `429 Too Many Requests` with a `Retry-After` header.

{:.info}
> In production, store provider credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. AI Vaults support HashiCorp Vault, Azure, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store. Per-developer AI Consumer credentials are also good vault candidates as the team scales beyond a handful of seats.

## Apply the Kong configuration

This section configures the {{site.ai_gateway}} in two parts. First, adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply commands can manage it. The recipe's `github-copilot-byok-recipe` namespace scopes every resource so teardown removes only this recipe's configuration.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the {{site.ai_gateway}}.

The provider tabs below create an AI Model Provider holding your chosen provider's credentials, a Pre-Function Policy for header and body normalization, a Key Auth AI Auth Strategy, an AI Model for provider-key injection and OpenAI-format passthrough or translation, an AI Rate Limiting Advanced Policy for per-consumer token budgets, and two demonstration AI Consumers with API key credentials. See the [kongctl documentation](/kongctl/) for more on federated configuration management.

`KONNECT_CONTROL_PLANE_NAME`, `AI_GATEWAY_ID`, provider credentials, and `DECK_COPILOT_KEY_ALICE`/`DECK_COPILOT_KEY_BOB` are already exported from the prerequisites, so each tab below only sets the model env var and runs the apply.

{% navtabs "Providers" %}
{% tab OpenAI %}

Export the model env var. Set it to whatever model name the Copilot org policy permits. If the policy is unrestricted, pick any OpenAI chat model your account has access to:

```bash
export CHAT_MODEL='gpt-4o'   # must match VS Code's models[].id and the org Copilot allowlist
```

{:.warning}
> `CHAT_MODEL` is the contract between Copilot's policy, VS Code's `models[].id`, and Kong's model selector. If your Copilot administrator has pinned a specific model (for example, `gpt-5-mini`), set this env var to that exact value and use the same string in `chatLanguageModels.json`.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: github-copilot-byok-recipe
ai_gateway_model_providers:
- ref: github-copilot-byok-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-provider
  display_name: github-copilot-byok
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'DECK_OPENAI_TOKEN'}
ai_gateway_auth_strategies:
- ref: github-copilot-byok-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-auth
  display_name: github-copilot-byok key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: copilot-developer-alice
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: copilot-developer-alice
  display_name: 'Copilot developer: Alice'
  type: api-key
  credentials:
  - ref: copilot-developer-alice-credential
    name: copilot-developer-alice-credential
    display_name: Alice's Copilot API key
    type: api-key
    api_key: !secret {source: !env 'DECK_COPILOT_KEY_ALICE'}
- ref: copilot-developer-bob
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: copilot-developer-bob
  display_name: 'Copilot developer: Bob'
  type: api-key
  credentials:
  - ref: copilot-developer-bob-credential
    name: copilot-developer-bob-credential
    display_name: Bob's Copilot API key
    type: api-key
    api_key: !secret {source: !env 'DECK_COPILOT_KEY_BOB'}
ai_gateway_policies:
- ref: github-copilot-byok-normalize
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-normalize
  display_name: github-copilot-byok request normalization
  type: pre-function
  config:
    access:
    - "local cjson = require \"cjson.safe\"\n\n-- Rewrite Authorization: Bearer <key>\
      \ to apikey: <key> so the\n-- key-auth AI Auth Strategy can match the credential.\
      \ VS Code\n-- Copilot's BYOK Custom Endpoint follows the OpenAI client\n-- convention\
      \ and posts the apiKey as Authorization: Bearer <apiKey>.\nlocal auth = kong.request.get_header(\"\
      Authorization\")\nif auth and string.sub(string.lower(auth), 1, 7) == \"bearer\
      \ \" then\n  ngx.req.set_header(\"apikey\", string.sub(auth, 8))\nend\n\n--\
      \ Strip temperature from the request body. VS Code Copilot\n-- hard-codes temperature:\
      \ 0.1 with no UI override. Reasoning\n-- models (gpt-5, o-series) reject any\
      \ temperature other than the\n-- default 1, so the upstream returns:\n--   400\
      \ ... 'temperature' does not support 0.1 ... Only the\n--   default (1) value\
      \ is supported\n-- Stripping the field falls back to the provider's default.\n\
      local body = kong.request.get_raw_body()\nif body then\n  local json = cjson.decode(body)\n\
      \  if json and json.temperature ~= nil then\n    json.temperature = nil\n  \
      \  kong.service.request.set_raw_body(cjson.encode(json))\n  end\nend\n"
- ref: github-copilot-byok-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-ratelimit
  display_name: github-copilot-byok token rate limiting
  type: ai-rate-limiting-advanced
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
ai_gateway_models:
- ref: github-copilot-byok-model
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-model
  display_name: github-copilot-byok
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - github-copilot-byok-auth
  policies:
  - github-copilot-byok-normalize
  - github-copilot-byok-ratelimit
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /github-copilot
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
    provider: github-copilot-byok-provider
    config:
      type: openai
      input_cost: 0.25
      output_cost: 2.0
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Azure OpenAI %}

Export the model env var. For Azure OpenAI, `CHAT_MODEL` is sent as the body's `model` field, which Azure largely ignores in favor of the deployment in the URL path. The value still has to match the VS Code `models[].id` and the Copilot org allowlist:

```bash
export CHAT_MODEL='gpt-4o'   # must match VS Code's models[].id and the org Copilot allowlist
```

{:.warning}
> `CHAT_MODEL` is the contract between Copilot's policy, VS Code's `models[].id`, and Kong's model selector. If your Copilot administrator has pinned a specific model (for example, `gpt-5-mini`), set this env var to that exact value and use the same string in `chatLanguageModels.json`.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: github-copilot-byok-recipe
ai_gateway_model_providers:
- ref: github-copilot-byok-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-provider
  display_name: github-copilot-byok
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
- ref: github-copilot-byok-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-auth
  display_name: github-copilot-byok key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: copilot-developer-alice
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: copilot-developer-alice
  display_name: 'Copilot developer: Alice'
  type: api-key
  credentials:
  - ref: copilot-developer-alice-credential
    name: copilot-developer-alice-credential
    display_name: Alice's Copilot API key
    type: api-key
    api_key: !secret {source: !env 'DECK_COPILOT_KEY_ALICE'}
- ref: copilot-developer-bob
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: copilot-developer-bob
  display_name: 'Copilot developer: Bob'
  type: api-key
  credentials:
  - ref: copilot-developer-bob-credential
    name: copilot-developer-bob-credential
    display_name: Bob's Copilot API key
    type: api-key
    api_key: !secret {source: !env 'DECK_COPILOT_KEY_BOB'}
ai_gateway_policies:
- ref: github-copilot-byok-normalize
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-normalize
  display_name: github-copilot-byok request normalization
  type: pre-function
  config:
    access:
    - "local cjson = require \"cjson.safe\"\n\n-- Rewrite Authorization: Bearer <key>\
      \ to apikey: <key> so the\n-- key-auth AI Auth Strategy can match the credential.\
      \ VS Code\n-- Copilot's BYOK Custom Endpoint follows the OpenAI client\n-- convention\
      \ and posts the apiKey as Authorization: Bearer <apiKey>.\nlocal auth = kong.request.get_header(\"\
      Authorization\")\nif auth and string.sub(string.lower(auth), 1, 7) == \"bearer\
      \ \" then\n  ngx.req.set_header(\"apikey\", string.sub(auth, 8))\nend\n\n--\
      \ Strip temperature from the request body. VS Code Copilot\n-- hard-codes temperature:\
      \ 0.1 with no UI override. Reasoning\n-- models (gpt-5, o-series) reject any\
      \ temperature other than the\n-- default 1, so the upstream returns:\n--   400\
      \ ... 'temperature' does not support 0.1 ... Only the\n--   default (1) value\
      \ is supported\n-- Stripping the field falls back to the provider's default.\n\
      local body = kong.request.get_raw_body()\nif body then\n  local json = cjson.decode(body)\n\
      \  if json and json.temperature ~= nil then\n    json.temperature = nil\n  \
      \  kong.service.request.set_raw_body(cjson.encode(json))\n  end\nend\n"
- ref: github-copilot-byok-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-ratelimit
  display_name: github-copilot-byok token rate limiting
  type: ai-rate-limiting-advanced
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
ai_gateway_models:
- ref: github-copilot-byok-model
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-model
  display_name: github-copilot-byok
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - github-copilot-byok-auth
  policies:
  - github-copilot-byok-normalize
  - github-copilot-byok-ratelimit
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /github-copilot
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
    provider: github-copilot-byok-provider
    config:
      api_version: !env 'DECK_AZURE_API_VERSION'
      deployment_id: !env 'DECK_AZURE_DEPLOYMENT_ID'
      type: azure
      input_cost: 0.25
      output_cost: 2.0
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab AWS Bedrock %}

Export the model env var. Bedrock model IDs include a `provider.model-version-vN:M` shape, and the value here is what Kong sends upstream **and** what VS Code's `models[].id` has to match:

```bash
export CHAT_MODEL='anthropic.claude-sonnet-4-5-20250929-v1:0'   # must match VS Code's models[].id
```

{:.warning}
> `CHAT_MODEL` is the contract between Copilot's policy, VS Code's `models[].id`, and Kong's model selector. If your Copilot administrator has pinned a specific model (for example, `gpt-5-mini`), set this env var to that exact value and use the same string in `chatLanguageModels.json`.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: github-copilot-byok-recipe
ai_gateway_model_providers:
- ref: github-copilot-byok-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-provider
  display_name: github-copilot-byok
  type: bedrock
  config:
    auth:
      type: aws
      access_key_id: !env 'DECK_AWS_ACCESS_KEY_ID'
      secret_access_key: !secret {source: !env 'DECK_AWS_SECRET_ACCESS_KEY'}
ai_gateway_auth_strategies:
- ref: github-copilot-byok-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-auth
  display_name: github-copilot-byok key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: copilot-developer-alice
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: copilot-developer-alice
  display_name: 'Copilot developer: Alice'
  type: api-key
  credentials:
  - ref: copilot-developer-alice-credential
    name: copilot-developer-alice-credential
    display_name: Alice's Copilot API key
    type: api-key
    api_key: !secret {source: !env 'DECK_COPILOT_KEY_ALICE'}
- ref: copilot-developer-bob
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: copilot-developer-bob
  display_name: 'Copilot developer: Bob'
  type: api-key
  credentials:
  - ref: copilot-developer-bob-credential
    name: copilot-developer-bob-credential
    display_name: Bob's Copilot API key
    type: api-key
    api_key: !secret {source: !env 'DECK_COPILOT_KEY_BOB'}
ai_gateway_policies:
- ref: github-copilot-byok-normalize
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-normalize
  display_name: github-copilot-byok request normalization
  type: pre-function
  config:
    access:
    - "local cjson = require \"cjson.safe\"\n\n-- Rewrite Authorization: Bearer <key>\
      \ to apikey: <key> so the\n-- key-auth AI Auth Strategy can match the credential.\
      \ VS Code\n-- Copilot's BYOK Custom Endpoint follows the OpenAI client\n-- convention\
      \ and posts the apiKey as Authorization: Bearer <apiKey>.\nlocal auth = kong.request.get_header(\"\
      Authorization\")\nif auth and string.sub(string.lower(auth), 1, 7) == \"bearer\
      \ \" then\n  ngx.req.set_header(\"apikey\", string.sub(auth, 8))\nend\n\n--\
      \ Strip temperature from the request body. VS Code Copilot\n-- hard-codes temperature:\
      \ 0.1 with no UI override. Reasoning\n-- models (gpt-5, o-series) reject any\
      \ temperature other than the\n-- default 1, so the upstream returns:\n--   400\
      \ ... 'temperature' does not support 0.1 ... Only the\n--   default (1) value\
      \ is supported\n-- Stripping the field falls back to the provider's default.\n\
      local body = kong.request.get_raw_body()\nif body then\n  local json = cjson.decode(body)\n\
      \  if json and json.temperature ~= nil then\n    json.temperature = nil\n  \
      \  kong.service.request.set_raw_body(cjson.encode(json))\n  end\nend\n"
- ref: github-copilot-byok-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-ratelimit
  display_name: github-copilot-byok token rate limiting
  type: ai-rate-limiting-advanced
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
ai_gateway_models:
- ref: github-copilot-byok-model
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-model
  display_name: github-copilot-byok
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - github-copilot-byok-auth
  policies:
  - github-copilot-byok-normalize
  - github-copilot-byok-ratelimit
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /github-copilot
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
    provider: github-copilot-byok-provider
    config:
      region: !env 'DECK_AWS_REGION'
      type: bedrock
      input_cost: 0.25
      output_cost: 2.0
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% endnavtabs %}

### Create the Copilot Usage dashboard

Create a custom dashboard at the org level. The dashboard surfaces cost, token usage, request volume, model mix, per-developer (AI Consumer) usage, and latency for Copilot traffic. The dashboard JSON is in the code block below; if a labeled dashboard from a prior apply already exists, the block reuses it instead of creating a duplicate.

{:.info}
> **This dashboard is not scoped to a single {{site.ai_gateway}}.** {{site.ai_gateway_name}} 2.0 has no Service entity to filter a custom dashboard by. Until a confirmed per-AI-Gateway analytics dimension is available, the dashboard's tiles filter by provider, model, AI Consumer, and status code, which is enough to distinguish Copilot traffic from unrelated traffic on the same org as long as `copilot-developer-alice`/`copilot-developer-bob` (or your production AI Consumer names) aren't reused by another recipe.

```bash
EXISTING_DASHBOARDS=$(kongctl api get "/v2/dashboards?filter%5Blabels.recipe%5D=github-copilot-byok-recipe" \
  --pat "${KONNECT_TOKEN}" -o json --jq '.data | length')

if [ "${EXISTING_DASHBOARDS}" -gt 0 ]; then
  echo "Copilot Usage dashboard already exists. Reusing."
else
  cat <<'EOF' > copilot-usage-dashboard.json
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
    "template_id": "AI_GATEWAY"
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

With the configuration applied, configure VS Code Copilot to post Chat and agent requests to Kong, then ask a question and watch the request, attribution, and rate-limit headers flow through {{site.konnect_short_name}} {{site.observability}}.

{:.warning}
> **Do not paste a raw API key into `chatLanguageModels.json`.** The `apiKey` field only accepts a `${input:chat.lm.secret.<id>}` placeholder, which VS Code mints when you enter a key into the **Add Models... → Custom Endpoint → Chat Completions** wizard. VS Code silently drops a raw value in that field, sends `Authorization: Bearer` with no key, and Kong returns `401 No API key found in request`.

### Add the Custom Endpoint to VS Code

VS Code stores Custom Endpoint API keys in its encrypted OS-keychain secret storage. `chatLanguageModels.json` only ever sees a `${input:chat.lm.secret.<id>}` placeholder that resolves to the stored value at request time. The only supported way to mint that placeholder is the **Add Models...** wizard, which prompts for the key and writes both the secret entry and the placeholder for you.

In VS Code:

1. Open the **Chat** view (`Ctrl+Alt+I` / `Cmd+Ctrl+I`).
1. Click the **model picker** at the bottom of the Chat input.
1. Select **Manage Language Models...**.
1. Click **Add Models...** → **Custom Endpoint** → **Chat Completions**.
1. When VS Code prompts for an **API key**, paste the value of `$DECK_COPILOT_KEY_ALICE`. Copy it with `printf '%s' "$DECK_COPILOT_KEY_ALICE"` (not `echo`) so a trailing zsh `%` marker is never included. That character is a prompt artifact, not part of the key, and pasting it produces a `401` from Kong.

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

The hex suffix after `chat.lm.secret.` is per-entry. Yours differs from the example. Four behaviors are load-bearing:

- **`apiKey`** is a `${input:chat.lm.secret.<id>}` reference, not a literal. Re-running the **Add Models...** wizard mints a new secret and a new placeholder; replacing the wizard-generated value with a raw key disables auth entirely. To rotate, open **Manage Language Models...** → select the entry → **Edit API Key** and VS Code updates the stored secret behind the same placeholder.
- **`models[].id`** must equal `CHAT_MODEL` exactly. VS Code sends this string as the body's `model` field, and Kong's model selector only matches this exact value. If your Copilot administrator has pinned an allowlist (for example, `gpt-5-mini`), set this value AND `CHAT_MODEL` to that exact name.
- **`models[].url`** is the **full** chat-completions path. VS Code posts to the URL verbatim; it does not append `/chat/completions` for you.
- **`chatLanguageModels.json` edits** need a window reload. After editing the file, run **Developer: Reload Window** so VS Code re-parses it. The Chat model picker then shows the new entry. Select **GPT-4o (via Kong)**.

### Ask Copilot a question

In the Chat view, with **GPT-4o (via Kong)** selected, ask any question. For example:

```text
> Explain what a Kong Consumer is in one sentence.
```
{:.no-copy-code}

Copilot Chat sends the request through Kong, which authenticates the developer, normalizes the body, injects the provider key, and forwards. The response streams back into the Chat view. Subsequent requests reuse the same credential silently.

### Confirm Bearer-to-apikey rewrite and temperature strip

The Pre-Function Policy performs two rewrites on every request that the developer doesn't see. To verify them, inspect the request payload in {{site.konnect_short_name}} {{site.observability}} or in a logging destination that receives `logging.payloads: true` output. Two signals confirm correctness:

- The Key Auth AI Auth Strategy attributes the request to the matching AI Consumer (`copilot-developer-alice` or `copilot-developer-bob`), visible in the **Top developers** tiles on the **Copilot Usage** dashboard.
- The upstream payload doesn't contain a `temperature` field. If you point this recipe at a reasoning model (gpt-5, o-series) and Copilot Chat returns answers instead of `400`, the strip is working.

If you want to see the rewrites live during local development, temporarily insert two `kong.log.notice` lines at the top of the Pre-Function access block to dump the inbound headers and body, then watch the data plane logs:

{% raw %}
```bash
docker logs -f $(docker ps --filter ancestor=kong/kong-gateway --format '{{.Names}}') 2>&1 \
  | grep -iE 'authorization|apikey'
```
{% endraw %}

Remove the diagnostic lines once you have confirmed `"authorization":"Bearer <key>"` is arriving. Leaving them in writes the full prompt, tool definitions, and file contents from every Copilot request into your gateway logs.

### Hit the model selector gate

To see the model gate in action, edit `chatLanguageModels.json` and change `models[].id` to a different model name, for example `gpt-3.5-turbo`. Save. Re-select the model in the picker and ask Copilot another question. Kong rejects the request:

```text
Request failed: 400
```
{:.no-copy-code}

Change `id` back to the value of `CHAT_MODEL` and the request succeeds again. This is the Kong-side enforcement boundary: developers can't use a model the platform team hasn't configured a target for, even if VS Code's UI offers it.

### Hit the per-consumer rate limit

The recipe configures 50,000 total tokens per 60-second sliding window per AI Consumer. Copilot agent runs with workspace context routinely consume 30,000+ tokens per turn. A single multi-tool reply can come close to exhausting the window on its own. Send two or three prompts in quick succession that each include meaningful file context (for example, ask Copilot to summarize a file in your repo) and Kong returns:

```text
Request failed: 429 Too Many Requests
```
{:.no-copy-code}

The response includes a `Retry-After` header indicating how many seconds remain in the window. Because `identifier: consumer` scopes the bucket to the developer, the other AI Consumer (`copilot-developer-bob`) still has its full budget at the same instant. Rotate VS Code's stored credential via **Manage Language Models... → Edit API Key** to the value of `$DECK_COPILOT_KEY_BOB` to verify.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `github-copilot-byok-recipe`. The recipe created an AI Model Provider holding your chosen provider's credentials, an AI Model at `/github-copilot`, a Pre-Function Policy for request normalization, a Key Auth AI Auth Strategy, an AI Rate Limiting Advanced Policy, and two AI Consumers (`copilot-developer-alice`, `copilot-developer-bob`) with API key credentials, all scoped to this recipe by the kongctl namespace applied above.

**Copilot Usage dashboard**

Navigate to **Observability → Custom dashboards → `Copilot Usage`**. It surfaces total cost, total tokens, and request count; top models by usage; a health-check and provider-share breakdown; per-developer (AI Consumer) usage broken out by request count and token volume; and an AI security report scoped to 401/403/429 responses.

LLM analytics data takes 2 to 5 minutes to surface after the first successful request. If the dashboard remains empty beyond that, see [Troubleshooting](#troubleshooting) below.

For platform-wide traffic analysis across every {{site.ai_gateway}}, head to the **Observability** L1 menu in {{site.konnect_short_name}}.

## Troubleshooting

### 401 No API key found in request from VS Code

Kong returns this error when the `apikey` header is missing. For Copilot, a missing `apikey` header means the `Authorization` header was either absent or arrived as a bare `Bearer` with no value. Verify in this order:

1. **Confirm the request reached Kong with a non-empty Bearer value.** Add the diagnostic `kong.log.notice` lines described in the [Confirm Bearer-to-apikey rewrite](#confirm-bearer-to-apikey-rewrite-and-temperature-strip) section and look for `"authorization":"Bearer <key>"`. If the value is literally `Bearer` with nothing after, VS Code didn't resolve the secret placeholder.
1. **Re-mint the placeholder.** Open **Manage Language Models...**, remove the {{site.ai_gateway_name}} entry, run **Add Models... → Custom Endpoint → Chat Completions** again, and paste the key when prompted. A `chatLanguageModels.json` entry whose `apiKey` was hand-typed (rather than wizard-generated) is silently invalid even if its shape looks identical to a working one.
1. **Strip stray characters from the key.** Copy the value with `printf '%s' "$DECK_COPILOT_KEY_ALICE"`. zsh's trailing `%` marker for newline-less output is a common silent-401 source.
1. **Check whether the Pre-Function Policy runs before authentication.** This recipe's design assumes the Pre-Function Policy's header rewrite is visible to the Key Auth AI Auth Strategy check. That ordering hasn't been confirmed against a live {{site.ai_gateway}} (see the warning in [Pre-Function: request normalization](#pre-function-request-normalization)). If step 1 shows Kong receiving a valid `Authorization: Bearer <key>` header but still rejecting with `401`, this ordering is the likely cause and needs to be reported.

### Dashboard is empty after a few minutes

If **Observability → Custom dashboards → `Copilot Usage`** shows no data 5+ minutes after a successful request, work outward from the data plane:

1. **Confirm requests reached the data plane.** Tail `docker logs` on the Kong container and trigger a Copilot prompt; you should see access-log lines for `POST /github-copilot/v1/chat/completions`. If the access log is silent, the request never left VS Code or never hit Kong. Fix the client side first.

1. **Confirm the data plane is reporting to {{site.konnect_short_name}} telemetry.** A data plane that was relaunched (for example, recreated with new env vars) sometimes fails to reconnect to the telemetry endpoint:

   {% raw %}
   ```bash
   docker logs $(docker ps --filter ancestor=kong/kong-gateway --format '{{.Names}}') 2>&1 \
     | grep -iE 'telemetry|cluster_telemetry|connected to.*tp\.konghq'
   ```
   {% endraw %}

   A healthy node shows a successful connection to `{region}.tp.konghq.com:443`. Repeated TLS or DNS errors mean telemetry is silently dropping. Restart the container and re-check.

1. **Confirm raw requests are landing in {{site.konnect_short_name}}.** Open **Observability → Analytics → Requests**, scope to the `github-copilot-byok-recipe` {{site.ai_gateway}}, and verify recent 2xx entries appear. If this view shows data but the custom dashboard doesn't, the dashboard's filter or tiles are the issue. If this view is also empty, telemetry is the issue (step 2).

1. **Send a few more requests if tiles still look empty.** Several tiles filter out `ai_provider = UNSPECIFIED`. Brand-new gateways occasionally tag the first request or two as `UNSPECIFIED` while provider metadata reports back to {{site.konnect_short_name}}. A handful of additional Copilot prompts brings the tiles to life.

## Variations and next steps

- **Add SSO with AI Consumer Group tiers.** Replace the Key Auth AI Auth Strategy with an [OpenID Connect AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) pointed at your IdP, and let the user's group claim drive which model they can access. The [Claude Code SSO recipe](/cookbooks/claude-code-sso/) demonstrates this pattern end-to-end.
- **Add code-secret PII redaction.** Add an [AI Sanitizer](/ai-gateway/policies/ai-sanitizer/) Policy ahead of the AI Model to redact API keys, tokens, and other secrets from prompts before they reach the LLM provider. Developers pasting `.env` snippets into Copilot Chat is a real exfiltration risk; this policy catches it server-side.
- **Switch to monthly token budgets.** The 60-second window here is intentionally aggressive for the demo so a few prompts visibly exhaust it. Production teams usually enforce monthly budgets, for example {%raw%}`limits: [{limit: 5000000, window_size: 2592000}]`{%endraw%} for a 5 million token monthly ceiling per AI Consumer. Combine multiple `limits` entries to enforce burst and sustained budgets simultaneously.
- **Share rate-limit counters with Redis.** The recipe uses `strategy: local`, which keeps counters in memory on each Kong node. For multi-node clusters, switch to `strategy: redis` and point to a shared Redis instance.
- **Move credentials into a vault.** Use [AI Vaults](/ai-gateway/entities/ai-vault/) to source provider keys and AI Consumer credentials from HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, or the {{site.konnect_short_name}} Config Store. Replace `!secret {source: !env DECK_OPENAI_TOKEN}` style references with `{vault://backend/key}` references.
- **Cover non-Copilot OpenAI-format clients.** This recipe works for any client that speaks the OpenAI Chat Completions API and authenticates with `Authorization: Bearer`. Cursor, Continue, and similar IDE assistants can point at the same AI Model with their own AI Consumer credential.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration.

Delete the **Copilot Usage** custom dashboard. The dashboard is an org-level resource and outlives the {{site.ai_gateway}}, so remove it before tearing down Kong:

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
{: data-test-step="block" .collapsible }

Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='github-copilot-byok-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

Remove the {{site.ai_gateway_name}} entry from VS Code. Open the Chat view → model picker → **Manage Language Models...** → select **{{site.ai_gateway_name}}** → **Remove**. This deletes the entry from `chatLanguageModels.json` AND the stored secret from the OS keychain. Copilot resumes routing to GitHub's hosted models for the seat.
