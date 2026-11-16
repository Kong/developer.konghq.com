---
title: "AI Tool Integration: Codex CLI"
description: Point Codex CLI Responses API traffic at {{site.ai_gateway_name}} passthrough.
url: "/cookbooks/coding-agents-codex/"
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
  ai-gateway: '2.2'
categories:
  - agents
  - llm
  - access-control
featured: false
popular: false

plugins:
  - key-auth
  - pre-function
requires_embeddings: false
providers:
  - openai

hint: "Requires Kong AI Gateway 2.2+, an OpenAI API key, and the Codex CLI."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped {{site.ai_gateway}} and local data plane.

        1. Create a new personal access token by opening the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-codex-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-codex-recipe`, a local data plane connected to it, and prints `export` lines (including `AI_GATEWAY_ID`). Paste those into your shell when prompted.

           The data plane must run {{site.ai_gateway}} 2.2 or later, which passthrough AI Models require.
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
        Export an OpenAI API key for the AI Model Provider:

        ```bash
        export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
        ```
    - title: AI Consumer API Key
      content: |
        Generate the API key that the demo AI Consumer sends to Kong. Client tools use this key instead of the provider key:

        ```bash
        export CONSUMER_API_KEY="coding-agents-demo-$(openssl rand -hex 8)"
        echo "$CONSUMER_API_KEY"
        ```
overview: |
  Use Codex CLI when you need OpenAI's Responses API (`POST /v1/responses`). Chat Completions AI Models don't expose that endpoint, so Codex targets `/coding-agents-responses` with `wire_api = "responses"`.
---

## The problem

Codex CLI calls a model provider directly from each developer's machine. That works for one person with one key, but an organization that wants to give a whole team Codex on a shared OpenAI account runs into several problems:

* **Provider keys end up on laptops.** A [custom model provider](https://developers.openai.com/codex/config-file/config-advanced) in `~/.codex/config.toml` reads its API key from the environment variable named in `env_key`. Without a gateway, that variable holds an OpenAI API key. Every machine holds a credential that bills the organization's account, a leaked key works anywhere, and offboarding one developer means finding and revoking the right key.
* **There is no central place to apply policy.** Attribution, logging, and credential control happen per machine or in the provider's console. OpenAI's [gateway guide for Codex](https://developers.openai.com/codex/enterprise/connect-to-a-gateway) describes the gateway as the place that validates gateway credentials, controls which credential goes upstream, and records the user, model, and route for each request.
* **Codex only speaks the Responses API.** In the [Codex configuration reference](https://developers.openai.com/codex/config-file/config-reference), `responses` is the only supported `wire_api` value. OpenAI's [gateway compatibility guide](https://developers.openai.com/codex/enterprise/gateway-compatibility) states that a working Chat Completions endpoint doesn't establish Responses compatibility: for a base URL ending in `/v1`, the gateway must accept `POST /v1/responses`. A gateway that only offers OpenAI-compatible Chat Completions can't serve Codex.
* **A gateway has to stream without changing the protocol.** The same compatibility guide asks gateways to forward server-sent events incrementally rather than buffering them, and to preserve event types and payloads, including the terminal `response.completed` event. A gateway that translates or buffers Responses API traffic stalls or breaks Codex sessions.

The root issue is that the credential, the policy, and the protocol burden all sit on the client. Teams need one server-side point that holds the organization's OpenAI key, authenticates developers with credentials it can revoke, and forwards Codex's Responses API traffic unchanged.

## The solution

This recipe puts {{site.ai_gateway}} between Codex CLI and the OpenAI API:

* **Server-side provider credential.** The organization's OpenAI API key lives on {{site.ai_gateway}}. Developers never see it, and rotating it is one configuration change.
* **Revocable developer credentials.** Each developer gets an AI Consumer API key from Kong. Codex sends that key instead of an OpenAI key, and Kong attributes every request to the matching AI Consumer. Revoking a developer means deleting one AI Consumer credential.
* **Native Responses API forwarding.** The AI Model exposes the Responses API endpoint and forwards Codex's requests and streamed responses without translating them, so every request field and server-sent event reaches its destination unchanged.
* **One place for future policy.** After traffic flows through Kong, you can add logging, rate limiting, and other AI Policies without changing anything on developer machines.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant CX as Codex CLI
    participant K as AI Gateway
    participant O as OpenAI API

    CX->>K: POST /coding-agents-responses/v1/responses (Authorization: Bearer AI Consumer key)
    activate K
    K->>K: Pre-Function Policy copies Bearer token into apikey
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: AI Model strips path, AI Model Provider swaps in org OpenAI key
    K->>O: POST /v1/responses (Authorization: org key, body unchanged)
    activate O
    O-->>K: Responses API events (streamed)
    deactivate O
    K-->>CX: Response forwarded byte-for-byte
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
  - component: "Codex CLI"
    responsibility: "Sends Responses API requests to the custom model provider's `base_url` with the AI Consumer key in the `Authorization` header."
  - component: "Pre-Function Policy"
    responsibility: "Copies the token from `Authorization: Bearer <key>` into the `apikey` header that the Key Auth AI Auth Strategy reads."
  - component: "Key Auth AI Auth Strategy"
    responsibility: "Validates the AI Consumer key, attaches the request to the AI Consumer, and removes the `apikey` header before the request goes upstream."
  - component: "AI Consumer"
    responsibility: "Represents one developer. Its API key credential is the only secret the developer holds."
  - component: "AI Model"
    responsibility: "Exposes `/coding-agents-responses` and forwards Responses API traffic in passthrough format, without translation."
  - component: "AI Model Provider"
    responsibility: "Holds the organization's OpenAI API key and injects it into every upstream request."
  - component: "OpenAI API"
    responsibility: "Serves the model inference and bills the organization's account."
{% endtable %}

## How it works

When you run a prompt in Codex CLI, the request goes through these steps:

1. **Codex sends the request to Kong.** The `kong` model provider sets `base_url` to `http://localhost:8000/coding-agents-responses/v1`, so Codex posts Responses API requests to `/coding-agents-responses/v1/responses`. Codex reads the key from `CODEX_API_KEY`, the variable named in `env_key`, which holds the AI Consumer key, and sends it as `Authorization: Bearer <key>`.
1. **Kong moves the key into the header Key Auth reads.** The global Pre-Function Policy runs in the rewrite phase. It finds the `Bearer ` prefix on the `Authorization` header and copies the token into an `apikey` header.
1. **Kong authenticates the developer.** The AI Model lists the Key Auth AI Auth Strategy in `access.auth_strategies`. The AI Auth Strategy reads `apikey`, matches it against the AI Consumer credentials, and attaches the request to `coding-agents-consumer`. A missing or unknown key returns `401`.
1. **Kong removes the AI Consumer key.** With `hide_credentials` enabled, the AI Auth Strategy strips the `apikey` header from the request.
1. **The AI Model forwards the request unchanged.** The AI Model uses the `passthrough` format, so Kong forwards the request and response bodies byte-for-byte. Kong strips the `/coding-agents-responses` prefix and sends the remaining path, `/v1/responses`, to the target's `upstream_url`. The `model` field Codex sends reaches OpenAI as is.
1. **The AI Model Provider injects the organization's key.** The target references the AI Model Provider, which sets the `Authorization` header to the organization's OpenAI key, replacing the AI Consumer key Codex sent. OpenAI authenticates the request against that key and bills the organization's account.
1. **The response streams back.** OpenAI streams Responses API events back through Kong to Codex. Kong logs the request against the AI Consumer.

### Pre-Function: Bearer token to apikey

Codex sends its API key in the `Authorization` header as a Bearer token, but the Key Auth AI Auth Strategy reads a key from a named header and doesn't strip a `Bearer ` prefix. The Pre-Function Policy bridges the two: it runs Lua in the rewrite phase, before authentication, and copies the token into the `apikey` header. This lets Codex keep its standard API key setup while Kong authenticates the developer with a Kong credential instead of an OpenAI key. The Policy is global, so every AI Model on this {{site.ai_gateway}} gets the same header handling.

#### Configuration details

```yaml
ai_gateway_policies:
- ref: coding-agents-bearer-to-apikey
  name: coding-agents-bearer-to-apikey
  type: pre-function
  global: true
  config:
    rewrite:
    - |
      local auth = kong.request.get_header("Authorization")
      if auth and string.sub(string.lower(auth), 1, 7) == "bearer " then
        ngx.req.set_header("apikey", string.sub(auth, 8))
      end
```
{:.no-copy-code}

**`config.rewrite`**: An array of Lua source strings that run in the rewrite phase, before the Key Auth AI Auth Strategy checks the request.

**`ngx.req.set_header("apikey", ...)`**: Sets the header on the incoming request, so the Key Auth AI Auth Strategy sees it when it runs. The Lua leaves the `Authorization` header in place; the AI Model Provider replaces it before the request goes upstream.

**`global: true`**: Applies the Policy to all resources on the {{site.ai_gateway}}. Other OpenAI-compatible tools that send Bearer tokens can share the same Key Auth AI Auth Strategy without their own copy of the Policy.

### Key Auth: AI Consumer authentication

The Key Auth AI Auth Strategy is what lets each developer hold a Kong credential instead of an OpenAI key. It reads the AI Consumer key from the `apikey` header that the Pre-Function Policy populates. Kong attributes each request to the AI Consumer that owns the key, and deleting the credential revokes access without touching the organization's OpenAI key. Authentication in {{site.ai_gateway_name}} is an AI Auth Strategy that the AI Model references, not an AI Policy.

#### Configuration details

```yaml
ai_gateway_auth_strategies:
- ref: coding-agents-key-auth
  name: coding-agents-key-auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: coding-agents-consumer
  name: coding-agents-consumer
  type: api-key
  credentials:
  - ref: coding-agents-credential
    name: coding-agents-credential
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
```
{:.no-copy-code}

**`key_names: [apikey]`**: The header Kong reads the AI Consumer key from. The Pre-Function Policy writes the Bearer token into this header, so it's the only name the AI Auth Strategy needs. Clients that can send a custom header can also send `apikey` directly.

**`hide_credentials: true`**: Removes the `apikey` header before Kong forwards the request, so the developer's Kong credential never reaches OpenAI.

**`credentials[].api_key`**: The AI Consumer's key. The field is write-only, so it takes a `!secret` reference rather than a plain string.

**Scaling AI Consumers**: Add one AI Consumer per developer, each with its own credential. The recipe defines one AI Consumer for demonstration.

### AI Model and AI Model Provider: Responses API passthrough with credential injection

The AI Model gives Codex a Responses API base URL, and the AI Model Provider supplies the credential OpenAI expects. AI Models in the `openai` format expose OpenAI's Chat Completions API, not the Responses endpoint that Codex requires, so this AI Model uses the `passthrough` format instead. Passthrough forwards request and response bodies byte-for-byte without schema validation, which addresses the protocol problem: Codex's request fields and streamed events reach their destination exactly as sent. Passthrough still keeps AI Model Provider authentication, AI Consumer identity, and logging.

#### Configuration details

```yaml
ai_gateway_model_providers:
- ref: coding-agents-openai-provider
  name: coding-agents-openai-provider
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'OPENAI_TOKEN'}
ai_gateway_models:
- ref: coding-agents-openai-responses
  name: coding-agents-openai-responses
  type: model
  formats:
  - type: passthrough
  capabilities:
  - generate
  access:
    auth_strategies:
    - coding-agents-key-auth
  config:
    max_request_body_size: 16777216
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /coding-agents-responses
      protocols:
      - http
      - https
      methods:
      - POST
      - GET
      - OPTIONS
      strip_path: true
  targets:
  - name: openai-responses
    provider: coding-agents-openai-provider
    config:
      type: openai
      upstream_url: https://api.openai.com/
```
{:.no-copy-code}

**`config.auth.headers`** (AI Model Provider): The header Kong adds to every upstream request. OpenAI authenticates API keys through `Authorization: Bearer <key>`, so `OPENAI_TOKEN` holds the full header value, including the `Bearer ` prefix.

**`formats: [{type: passthrough}]`**: Forwards bodies without translation or validation. The `passthrough` format can't be combined with other formats and requires {{site.ai_gateway}} 2.2 or later. Because the AI Model has no model selector, the `model` field from Codex's `config.toml` passes through to OpenAI unchanged. To serve Chat Completions clients with a fixed model instead, use `formats: [{type: openai}]` with a model selector, as the [Cursor recipe](/cookbooks/coding-agents-cursor/) does.

**`route.paths` and `strip_path: true`**: Codex sends Responses API requests to `/coding-agents-responses/v1/responses`. Kong matches the `/coding-agents-responses` prefix, strips it, and forwards `/v1/responses` to the upstream.

**`route.methods`**: Codex sends `POST` for inference. `GET` lets clients reach read endpoints under the same path, and `OPTIONS` allows preflight requests from browser-based clients.

**`targets[].config.upstream_url`**: The OpenAI API base URL. Kong appends the stripped request path to it.

**`max_request_body_size: 16777216`**: Raises the request body limit to 16 MB from the 8 MB default. Codex requests carry the conversation, tool definitions, and file contents, and long sessions can exceed the default.

**`response_streaming: allow`**: Lets OpenAI stream server-sent events back to Codex, which renders output as it arrives.

**`logging.payloads: true`**: Captures full request and response bodies. Codex requests include source code and file contents, so payload logging can expose sensitive data in your logging destination. Set it to `false` if you only need usage metrics.

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. AI Vaults support HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store.

## Apply the Kong configuration

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply command can manage it. The `coding-agents-codex-recipe` namespace scopes every resource, so teardown removes only this recipe's configuration.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

The following configuration creates the AI Model Provider with the organization's OpenAI key, the Key Auth AI Auth Strategy, the demo AI Consumer, the global Pre-Function Policy, and the passthrough AI Model. `AI_GATEWAY_ID`, `OPENAI_TOKEN`, and `CONSUMER_API_KEY` are already exported from the prerequisites.

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: coding-agents-codex-recipe
ai_gateway_model_providers:
- ref: coding-agents-openai-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: coding-agents-openai-provider
  display_name: coding-agents-openai
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'OPENAI_TOKEN'}
ai_gateway_auth_strategies:
- ref: coding-agents-key-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: coding-agents-key-auth
  display_name: coding-agents key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: coding-agents-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: coding-agents-consumer
  display_name: coding-agents demo consumer
  type: api-key
  credentials:
  - ref: coding-agents-credential
    name: coding-agents-credential
    display_name: coding-agents demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_policies:
- ref: coding-agents-bearer-to-apikey
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: coding-agents-bearer-to-apikey
  display_name: coding-agents Bearer to apikey
  type: pre-function
  global: true
  config:
    rewrite:
    - "local auth = kong.request.get_header(\"Authorization\")\nif auth and string.sub(string.lower(auth),\
      \ 1, 7) == \"bearer \" then\n  ngx.req.set_header(\"apikey\", string.sub(auth,\
      \ 8))\nend\n"
ai_gateway_models:
- ref: coding-agents-openai-responses
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: coding-agents-openai-responses
  display_name: coding-agents (OpenAI Responses)
  type: model
  formats:
  - type: passthrough
  capabilities:
  - generate
  access:
    auth_strategies:
    - coding-agents-key-auth
  config:
    max_request_body_size: 16777216
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /coding-agents-responses
      protocols:
      - http
      - https
      methods:
      - POST
      - GET
      - OPTIONS
      strip_path: true
  targets:
  - name: openai-responses
    provider: coding-agents-openai-provider
    config:
      type: openai
      upstream_url: https://api.openai.com/
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

## Try it out

Point Codex CLI at the AI Model, send a request directly to confirm the gateway path, and then run a prompt from Codex. You also send a request without a key to see Key Auth reject it.

### Configure Codex CLI

Add a custom model provider to your user-level `~/.codex/config.toml`. Codex ignores `model_provider` and `model_providers` in a project-level `.codex/config.toml`, so this has to go in the [user-level file](https://developers.openai.com/codex/config-file/config-advanced):

```toml
model = "gpt-4o-mini"
model_provider = "kong"

[model_providers.kong]
name = "Kong AI Gateway"
base_url = "http://localhost:8000/coding-agents-responses/v1"
env_key = "CODEX_API_KEY"
wire_api = "responses"
```

**`base_url`**: Includes the `/v1` API path, as OpenAI's [gateway guide](https://developers.openai.com/codex/enterprise/connect-to-a-gateway) recommends. Codex adds `/responses`, and Kong strips `/coding-agents-responses` before forwarding `/v1/responses` to OpenAI.

**`env_key`**: The environment variable Codex reads the API key from. It holds the AI Consumer key, not an OpenAI key.

**`wire_api = "responses"`**: Selects the Responses API, the only protocol Codex supports.

**`model`**: Passed through to OpenAI unchanged. Use any model your OpenAI account can access.

Export the AI Consumer key under the name in `env_key`:

```bash
export CODEX_API_KEY="$CONSUMER_API_KEY"
```

### Send a request through the AI Model

Call the Responses API through Kong with the AI Consumer key as a Bearer token, the same way Codex sends it:

```bash
curl -sS -X POST "http://localhost:8000/coding-agents-responses/v1/responses" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${CONSUMER_API_KEY}" \
  -d '{
    "model": "gpt-4o-mini",
    "input": "Reply with exactly: smoke-ok"
  }'
```

Kong returns OpenAI's Responses API response unchanged. The response looks similar to this abbreviated example, with different IDs and token counts:

```json
{
  "id": "resp_...",
  "object": "response",
  "status": "completed",
  "model": "gpt-4o-mini-2024-07-18",
  "output": [
    {
      "type": "message",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "smoke-ok"
        }
      ]
    }
  ],
  "usage": {
    "input_tokens": 13,
    "output_tokens": 4,
    "total_tokens": 17
  }
}
```
{:.no-copy-code}

### Send a request without the AI Consumer key

Repeat the request without the `Authorization` header:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' -X POST "http://localhost:8000/coding-agents-responses/v1/responses" \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4o-mini", "input": "hi"}'
```

Kong rejects the request before it reaches OpenAI:

```text
401
```
{:.no-copy-code}

### Send a prompt from Codex CLI

Run a one-shot prompt with the configuration from [Configure Codex CLI](#configure-codex-cli):

```bash
codex exec --skip-git-repo-check "Reply with exactly: codex-ok"
```

Codex prints `codex-ok` as the final response.

### What happened

1. **The direct request** carried the AI Consumer key as a Bearer token. The Pre-Function Policy copied it into `apikey`, the Key Auth AI Auth Strategy matched it to `coding-agents-consumer` and removed it, and the AI Model Provider replaced the `Authorization` header with the organization's OpenAI key. OpenAI answered with `smoke-ok`.
1. **The request without a key** had no `Authorization` header, so the Pre-Function Policy set nothing and the Key Auth AI Auth Strategy returned `401`. Kong never contacted OpenAI, so the organization's key was never used.
1. **The Codex prompt** followed the same path as the direct request. Codex appended `/responses` to the `kong` provider's `base_url`, sent `CODEX_API_KEY` as a Bearer token, and streamed the Responses API events back through the passthrough AI Model. Codex never had access to the organization's OpenAI key.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `coding-agents-codex-recipe`. The recipe created an AI Model Provider (`coding-agents-openai-provider`) holding the organization's OpenAI key, an AI Model (`coding-agents-openai-responses`) at `/coding-agents-responses`, a Key Auth AI Auth Strategy (`coding-agents-key-auth`), a global Pre-Function Policy (`coding-agents-bearer-to-apikey`), and an AI Consumer (`coding-agents-consumer`) with an API key credential, all scoped to this recipe by the kongctl namespace.

For request, token, and per-AI Consumer analysis across every {{site.ai_gateway}}, open the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

* **Issue one AI Consumer per developer.** Add an AI Consumer and credential for each developer so usage and revocation are per person. Distribute each key through your secrets tooling. OpenAI's [Roll out a gateway](https://developers.openai.com/codex/enterprise/roll-out-a-gateway) guide covers deploying a Codex gateway configuration across an organization.
* **Connect Chat Completions tools to the same pattern.** The [Cursor recipe](/cookbooks/coding-agents-cursor/) uses an `openai`-format AI Model with a model selector for tools that speak Chat Completions.
* **Move credentials into a vault.** Use [AI Vaults](/ai-gateway/entities/ai-vault/) to source the OpenAI key and AI Consumer credentials from HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, or the {{site.konnect_short_name}} Config Store.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-codex-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
