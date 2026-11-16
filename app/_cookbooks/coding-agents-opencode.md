---
title: "AI Tool Integration: OpenCode"
description: Point OpenCode at {{site.ai_gateway_name}} OpenAI-compatible Chat Completions.
url: "/cookbooks/coding-agents-opencode/"
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

hint: "Requires Kong AI Gateway 2.2+, an OpenAI API key, and OpenCode."
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
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-opencode-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-opencode-recipe`, a local data plane connected to it, and prints `export` lines (including `AI_GATEWAY_ID`). Paste those into your shell when prompted.
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
  Use OpenCode when you want an OpenAI-compatible terminal agent against `/coding-agents`. OpenCode uses `@ai-sdk/openai-compatible` and Bearer auth.
---

## The problem

[OpenCode](https://opencode.ai/docs/) is a terminal coding agent that talks to many LLM providers. Each developer configures those providers on their own machine. That works for one person with one key, but an organization that wants to give a whole team OpenCode on a shared provider account runs into several problems:

* **Provider keys end up on laptops.** OpenCode picks up provider keys from [environment variables](https://opencode.ai/docs/config/) or from the `/connect` command, which [stores them](https://opencode.ai/docs/providers/) in `~/.local/share/opencode/auth.json`. Either way, every machine holds a credential that bills the organization's account, a leaked key works anywhere, and offboarding one developer means finding and revoking the right key.
* **Usage isn't attributed to developers.** When the whole team shares one OpenAI key, the provider bill is a single line item. There is no record of which developer sent which request, which model they used, or how many tokens they spent.
* **There is no central place to apply policy.** OpenCode's [`enabled_providers` and `disabled_providers`](https://opencode.ai/docs/config/) settings control which providers a developer can pick, but they live in each developer's config files. Budgets, rate limits, and request logging have to be solved per machine or per provider console.
* **OpenAI-compatible clients send Bearer tokens.** OpenCode connects to custom endpoints through the `@ai-sdk/openai-compatible` package, whose [`apiKey` option](https://ai-sdk.dev/providers/openai-compatible-providers) sends the key as `Authorization: Bearer <apiKey>`. A gateway in front of OpenCode has to accept a credential in that shape and still replace it with the provider's own key before the request goes upstream.

The root issue is that the credential, the policy, and the accounting all sit on the client. Teams need one server-side point that holds the organization's OpenAI key, authenticates developers with credentials it can revoke, and accepts OpenCode's requests as OpenCode sends them.

## The solution

This recipe puts {{site.ai_gateway}} between OpenCode and the OpenAI API:

* **Server-side provider credential.** The organization's OpenAI API key lives on {{site.ai_gateway}}. Developers never see it, and rotating it is one configuration change.
* **Revocable developer credentials.** Each developer gets an AI Consumer API key from Kong. OpenCode sends that key instead of an OpenAI key, and Kong attributes every request to the matching AI Consumer. Revoking a developer means deleting one AI Consumer credential.
* **Bearer token support.** Kong reads the AI Consumer key from OpenCode's `Authorization: Bearer` header, so OpenCode needs only a base URL and an API key in its provider config.
* **A pinned model.** The AI Model accepts one model name, set by `CHAT_MODEL`. Requests that name any other model don't reach OpenAI.
* **One place for future policy.** After traffic flows through Kong, you can add logging, rate limiting, and other AI Policies without changing anything on developer machines.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant OC as OpenCode
    participant K as AI Gateway
    participant O as OpenAI API

    OC->>K: POST /coding-agents/chat/completions (Authorization: Bearer AI Consumer key)
    activate K
    K->>K: Pre-Function Policy copies the Bearer token into apikey
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: AI Model matches body model to CHAT_MODEL, AI Model Provider sets org OpenAI key
    K->>O: Chat Completions request (Authorization: org key)
    activate O
    O-->>K: Chat Completions response
    deactivate O
    K-->>OC: OpenAI-format response
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
  - component: "OpenCode"
    responsibility: "Sends OpenAI Chat Completions requests to the custom provider's `baseURL` with the AI Consumer key as `Authorization: Bearer`."
  - component: "Pre-Function Policy"
    responsibility: "Copies the Bearer token into the `apikey` header so the Key Auth AI Auth Strategy can read it."
  - component: "Key Auth AI Auth Strategy"
    responsibility: "Validates the AI Consumer key, attaches the request to the AI Consumer, and removes the `apikey` header before the request goes upstream."
  - component: "AI Consumer"
    responsibility: "Represents one developer. Its API key credential is the only secret the developer holds."
  - component: "AI Model"
    responsibility: "Exposes `/coding-agents`, accepts OpenAI-format requests that name `CHAT_MODEL`, and routes them to the OpenAI target."
  - component: "AI Model Provider"
    responsibility: "Holds the organization's OpenAI API key and injects it into every upstream request."
  - component: "OpenAI API"
    responsibility: "Serves the model inference and bills the organization's account."
{% endtable %}

## How it works

When you run a prompt in OpenCode, the request goes through these steps:

1. **OpenCode sends the request to Kong.** The `kong` custom provider in `opencode.json` sets `baseURL` to `http://localhost:8000/coding-agents`, so OpenCode posts Chat Completions requests to `/coding-agents/chat/completions`. The provider's `apiKey` holds the AI Consumer key, which the `@ai-sdk/openai-compatible` package sends as `Authorization: Bearer <key>`.
1. **The Pre-Function Policy moves the key into `apikey`.** The Pre-Function Policy is global, so it runs on requests to every AI Model on the {{site.ai_gateway}}. In the rewrite phase, it reads `Authorization`, and if the value starts with `Bearer `, it writes the rest of the value into the `apikey` header.
1. **Kong authenticates the developer.** The AI Model lists the Key Auth AI Auth Strategy in `access.auth_strategies`. The AI Auth Strategy reads `apikey`, matches it against the AI Consumer credentials, and attaches the request to `coding-agents-consumer`. A missing or unknown key returns `401`. With `hide_credentials` enabled, the AI Auth Strategy removes `apikey` before the request goes upstream.
1. **The AI Model checks the model name.** The AI Model uses the `openai` format and matches the body's `model` field against its model selector. Only requests that name the `CHAT_MODEL` value reach the target.
1. **The AI Model Provider injects the organization's key.** The target references the AI Model Provider, which sets `Authorization` to the organization's OpenAI key. Kong sends the request to OpenAI with the target `name` as the model.
1. **The response returns to OpenCode.** OpenAI's response flows back through Kong to OpenCode, streamed when OpenCode requests streaming. Kong logs the request against the AI Consumer.

### Pre-Function: Bearer token to apikey header

The Key Auth AI Auth Strategy reads the AI Consumer key from a named header, and it doesn't strip a `Bearer ` prefix from `Authorization`. OpenCode's OpenAI-compatible provider sends its `apiKey` as `Authorization: Bearer <key>`, so the Pre-Function Policy bridges the two. It copies the token into `apikey` before authentication runs, which lets OpenCode authenticate with a standard API key setting. The policy is global, so every AI Model on the {{site.ai_gateway}} gets the same behavior.

#### Configuration details

```yaml
ai_gateway_policies:
- ref: coding-agents-bearer-to-apikey
  name: coding-agents-bearer-to-apikey
  type: pre-function
  global: true
  config:
    rewrite:
    - "local auth = kong.request.get_header(\"Authorization\")\nif auth and string.sub(string.lower(auth),\
      \ 1, 7) == \"bearer \" then\n  ngx.req.set_header(\"apikey\", string.sub(auth,\
      \ 8))\nend\n"
```
{:.no-copy-code}

The Lua in `config.rewrite` reads as follows:

```lua
local auth = kong.request.get_header("Authorization")
if auth and string.sub(string.lower(auth), 1, 7) == "bearer " then
  ngx.req.set_header("apikey", string.sub(auth, 8))
end
```
{:.no-copy-code}

**`type: pre-function`**: The [Pre-Function](/ai-gateway/policies/pre-function/) Policy runs custom Lua code during request processing.

**`config.rewrite`**: Runs the Lua in the rewrite phase, so the `apikey` header exists by the time the Key Auth AI Auth Strategy checks the request.

**`global: true`**: Applies the policy globally to all resources on the {{site.ai_gateway}}, without listing it on the AI Model.

**The Lua code**: Compares the first seven characters of `Authorization` to `bearer ` without regard to case, then copies everything after the prefix into `apikey`. Requests without a Bearer token pass through unchanged, and the Key Auth AI Auth Strategy rejects them.

**Sending `apikey` directly**: OpenCode's custom provider also accepts an [`options.headers`](https://opencode.ai/docs/providers/) object. Setting an `apikey` header there sends the AI Consumer key in the header Key Auth reads, without the Pre-Function Policy. The recipe keeps the policy because other OpenAI-compatible clients can only send Bearer tokens.

### Key Auth: AI Consumer authentication

The Key Auth AI Auth Strategy is what lets each developer hold a Kong credential instead of an OpenAI key. It reads the AI Consumer key from `apikey`, where the Pre-Function Policy placed it, and attributes each request to the AI Consumer that owns the key. Deleting the credential revokes access without touching the organization's OpenAI key. Authentication in {{site.ai_gateway_name}} is an AI Auth Strategy that the AI Model references, not an AI Policy.

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

**`key_names: [apikey]`**: The header Kong reads the AI Consumer key from. The Pre-Function Policy writes the Bearer token into this header.

**`hide_credentials: true`**: Removes `apikey` from the request before Kong forwards it, so the developer's Kong credential never reaches OpenAI.

**`credentials[].api_key`**: The AI Consumer's key. The field is write-only, so it takes a `!secret` reference rather than a plain string.

**Scaling AI Consumers**: Add one AI Consumer per developer, each with its own credential. The recipe defines one AI Consumer for demonstration.

### AI Model and AI Model Provider: OpenAI Chat Completions with credential injection

The AI Model gives OpenCode an OpenAI-compatible base URL, and the AI Model Provider supplies the credential OpenAI expects. The AI Model uses the `openai` format with a model selector, so it accepts Chat Completions requests only when the body's `model` field equals `CHAT_MODEL`. That pins the team to one model on the organization's account, whatever a developer types into `opencode.json`. The AI Model Provider replaces the client's credential with the organization's OpenAI key on every request.

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
- ref: coding-agents-openai
  name: coding-agents-openai
  type: model
  formats:
  - type: openai
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
      - /coding-agents
      protocols:
      - http
      - https
      methods:
      - POST
      - GET
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'CHAT_MODEL'
  targets:
  - name: !env 'CHAT_MODEL'
    provider: coding-agents-openai-provider
    config:
      type: openai
```
{:.no-copy-code}

**`config.auth.headers`** (AI Model Provider): The header Kong adds to every upstream request. OpenAI authenticates API keys through `Authorization`, so `OPENAI_TOKEN` holds the full header value, including the `Bearer ` prefix.

**`formats: [{type: openai}]`**: Accepts OpenAI Chat Completions requests, which is the format OpenCode's `@ai-sdk/openai-compatible` package sends. To forward bodies without schema validation instead, use the `passthrough` format, as the [Claude Code recipe](/cookbooks/coding-agents-claude-code/) does. The `passthrough` format can't be combined with other formats and requires {{site.ai_gateway}} 2.2 or later.

**`route.model`**: Matches the body's `model` field (`body_param: model`) against `values`. The list takes one value, so OpenCode must send exactly the `CHAT_MODEL` value as the model name. In `opencode.json`, that means the key under `models` must equal `CHAT_MODEL`.

**`targets[].name`**: The model name Kong sends to OpenAI. The recipe sets it to `CHAT_MODEL`, so the name OpenCode sends and the name OpenAI receives are the same. Set it to a different model to change what OpenAI serves without changing developer configs.

**`route.paths` and `strip_path: true`**: OpenCode appends `/chat/completions` to the `baseURL`. Kong matches the `/coding-agents` prefix and strips it before forwarding.

**`route.methods`**: OpenCode sends `POST` for inference. `GET` allows read requests from OpenAI-compatible clients that send them, and `OPTIONS` allows preflight requests from browser-based clients.

**`max_request_body_size: 16777216`**: Raises the request body limit to 16 MB from the 8 MB default. Coding agent requests carry the full conversation, tool definitions, and file contents, and long sessions can exceed the default.

**`response_streaming: allow`**: Lets OpenAI stream Server-Sent Events back to OpenCode, which renders tokens as they arrive.

**`logging.payloads: true`**: Captures full request and response bodies. OpenCode requests include source code and file contents, so payload logging can expose sensitive data in your logging destination. Set it to `false` if you only need usage metrics.

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. AI Vaults support HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store.

## Apply the Kong configuration

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply command can manage it. The `coding-agents-opencode-recipe` namespace scopes every resource, so teardown removes only this recipe's configuration.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Set the model the AI Model accepts and sends to OpenAI:

```bash
export CHAT_MODEL='gpt-4o-mini'
```

The following configuration creates the AI Model Provider with the organization's OpenAI key, the Key Auth AI Auth Strategy, the demo AI Consumer, the global Pre-Function Policy, and the AI Model. `AI_GATEWAY_ID`, `OPENAI_TOKEN`, and `CONSUMER_API_KEY` are already exported from the prerequisites, and `CHAT_MODEL` from the previous command.

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: coding-agents-opencode-recipe
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
- ref: coding-agents-openai
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: coding-agents-openai
  display_name: coding-agents (OpenAI-compatible)
  type: model
  formats:
  - type: openai
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
      - /coding-agents
      protocols:
      - http
      - https
      methods:
      - POST
      - GET
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'CHAT_MODEL'
  targets:
  - name: !env 'CHAT_MODEL'
    provider: coding-agents-openai-provider
    config:
      type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

## Try it out

Point OpenCode at the AI Model, send a request directly to confirm the gateway path, and then run a prompt from OpenCode. You also send a request without a key to see Key Auth reject it.

### Configure OpenCode

Create `opencode.json` in your working directory with a custom provider that uses the [`@ai-sdk/openai-compatible`](https://opencode.ai/docs/providers/) package:

```bash
cat <<'EOF' > opencode.json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "kong": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Kong AI Gateway",
      "options": {
        "baseURL": "http://localhost:8000/coding-agents",
        "apiKey": "{env:CONSUMER_API_KEY}"
      },
      "models": {
        "gpt-4o-mini": {
          "name": "gpt-4o-mini",
          "limit": { "context": 128000, "output": 16384 }
        }
      }
    }
  }
}
EOF
```

**`options.baseURL`**: The AI Model's path. OpenCode appends `/chat/completions` to it.

**`options.apiKey`**: The AI Consumer key. OpenCode replaces [`{env:CONSUMER_API_KEY}`](https://opencode.ai/docs/config/) with the value of the environment variable, so the key stays out of the file.

**`models`**: The key must equal `CHAT_MODEL`, because the AI Model accepts only that name. If you set a different `CHAT_MODEL`, change the key and `name` to match.

**`limit`**: Tells OpenCode how many input tokens the model accepts (`context`) and how many it can generate (`output`). Keep `limit.output` within the upstream model maximum.

A project `opencode.json` takes precedence over your global config, and OpenCode merges the two, so your other providers stay available.

### Send a request through the AI Model

Call Chat Completions with the AI Consumer key as a Bearer token, the same way OpenCode does:

```bash
curl -sS -X POST "http://localhost:8000/coding-agents/chat/completions" \
  -H "Authorization: Bearer ${CONSUMER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [{"role": "user", "content": "Reply with exactly: smoke-ok"}]
  }'
```

Kong returns an OpenAI Chat Completions response. The response looks similar to this, with different IDs and token counts:

```json
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "model": "gpt-4o-mini-2024-07-18",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "smoke-ok"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 14,
    "completion_tokens": 3,
    "total_tokens": 17
  }
}
```
{:.no-copy-code}

### Send a request without the AI Consumer key

Repeat the request without the `Authorization` header:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' -X POST "http://localhost:8000/coding-agents/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4o-mini", "messages": [{"role": "user", "content": "hi"}]}'
```

Kong rejects the request before it reaches OpenAI:

```text
401
```
{:.no-copy-code}

### Send a prompt from OpenCode

Run a one-shot prompt with the `kong` provider from [Configure OpenCode](#configure-opencode):

```bash
OPENCODE_CONFIG=./opencode.json opencode run --pure -m kong/gpt-4o-mini "Reply with exactly: opencode-ok"
```

OpenCode prints `opencode-ok`.

### What happened

1. **The direct request** carried the AI Consumer key as `Authorization: Bearer`. The Pre-Function Policy copied the token into `apikey`, the Key Auth AI Auth Strategy matched it to `coding-agents-consumer`, and the AI Model Provider set `Authorization` to the organization's OpenAI key. OpenAI answered with `smoke-ok`.
1. **The request without a key** had no Bearer token for the Pre-Function Policy to copy, so it failed at the Key Auth AI Auth Strategy with `401`. Kong never contacted OpenAI, so the organization's key was never used.
1. **The OpenCode prompt** followed the same path as the direct request. OpenCode resolved `kong/gpt-4o-mini` to the custom provider, appended `/chat/completions` to its `baseURL`, and sent the AI Consumer key as a Bearer token. OpenCode never had access to the organization's OpenAI key.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `coding-agents-opencode-recipe`. The recipe created an AI Model Provider (`coding-agents-openai-provider`) holding the organization's OpenAI key, an AI Model (`coding-agents-openai`) at `/coding-agents`, a Key Auth AI Auth Strategy (`coding-agents-key-auth`), a global Pre-Function Policy (`coding-agents-bearer-to-apikey`), and an AI Consumer (`coding-agents-consumer`) with an API key credential, all scoped to this recipe by the kongctl namespace.

For request, token, and per-AI Consumer analysis across every {{site.ai_gateway}}, open the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

* **Issue one AI Consumer per developer.** Add an AI Consumer and credential for each developer so usage and revocation are per person. Distribute each key through your secrets tooling, and have developers export it as `CONSUMER_API_KEY` so `opencode.json` stays the same for everyone.
* **Limit OpenCode to the gateway.** Set [`enabled_providers`](https://opencode.ai/docs/config/) to `["kong"]` in the shared `opencode.json`. OpenCode then enables only the `kong` provider and ignores all others.
* **Connect other Chat Completions tools to the same AI Model.** Cursor, Open WebUI, LibreChat, and Qwen Code can use `/coding-agents` with the same Pre-Function Policy and Key Auth AI Auth Strategy. See the [Cursor recipe](/cookbooks/coding-agents-cursor/). Codex needs the Responses API path instead; see the [Codex CLI recipe](/cookbooks/coding-agents-codex/).
* **Move credentials into a vault.** Use [AI Vaults](/ai-gateway/entities/ai-vault/) to source the OpenAI key and AI Consumer credentials from HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, or the {{site.konnect_short_name}} Config Store.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-opencode-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
