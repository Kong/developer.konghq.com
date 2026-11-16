---
title: "AI Tool Integration: Cursor"
description: Point Cursor Override OpenAI Base URL at {{site.ai_gateway_name}} Chat Completions.
url: "/cookbooks/coding-agents-cursor/"
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

hint: "Requires Kong AI Gateway 2.2+, an OpenAI API key, Cursor, and a Base URL reachable from Cursor cloud (not localhost via /etc/hosts)."
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
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-cursor-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-cursor-recipe`, a local data plane connected to it, and prints `export` lines (including `AI_GATEWAY_ID`). Paste those into your shell when prompted.
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
    - title: Public URL for Cursor
      content: |
        Cursor sends chat requests from its cloud backend, not from your machine, so the data plane proxy (port `8000`) must be reachable at a public hostname. A hostname mapped to `127.0.0.1` in `/etc/hosts` doesn't work, because Cursor's servers use public DNS.

        Export the public base URL of your data plane:

        ```bash
        export KONG_PUBLIC_URL='https://YOUR_PUBLIC_HOST'
        ```
overview: |
  Use Cursor when the editor should call OpenAI Chat Completions through Kong. Cursor sends `Authorization: Bearer <key>`. A global Pre-Function Policy copies that value into `apikey`.
---

## The problem

Cursor can call chat models with your own provider API key instead of Cursor's included usage. That works for one person with one key, but an organization that wants to give a whole team Cursor on a shared OpenAI account runs into several problems:

* **Provider keys end up on every developer's machine.** With [Cursor's own-key setup](https://cursor.com/help/models-and-usage/api-keys), each developer pastes a provider key into **Cursor Settings** > **Models**. Every machine holds a credential that bills the organization's account, a leaked key works anywhere, and offboarding one developer means rotating a key that everyone else shares or tracking down which key that developer used.
* **The key leaves the machine with every request.** Cursor's documentation states that own-key requests are still "routed through Cursor's servers for final prompt building." The key isn't stored on Cursor's servers, but it travels to them with each request, in addition to sitting in the editor's settings.
* **The provider bill has no developer attribution.** OpenAI bills the organization directly for own-key requests. When several developers share one key, usage arrives as a single line item, with no way to see who used how many tokens or which model.
* **There is no central place to apply policy.** Cursor's [Zero Data Retention policy doesn't apply](https://cursor.com/help/models-and-usage/api-keys) to own-key requests, and data handling follows the provider's policy. Logging, budgets, and rate limits have to be set up per provider account, not in one place you control.
* **Cursor's request path constrains where a gateway can run.** Because Cursor's servers make the upstream call, a gateway in front of Cursor must be reachable from the public internet, not just from the developer's laptop. Cursor also sends the key as `Authorization: Bearer <key>` in OpenAI Chat Completions format, so the gateway has to accept Bearer credentials.

The root issue is that the organization's credential and policy sit with each developer and each provider account. Teams need one publicly reachable, server-side point that holds the organization's OpenAI key, authenticates developers with credentials it can revoke, and accepts Cursor's OpenAI-format requests as they are.

## The solution

This recipe puts {{site.ai_gateway}} between Cursor and the OpenAI API:

* **Server-side provider credential.** The organization's OpenAI API key lives on {{site.ai_gateway}}. Developers never see it, and rotating it is one configuration change.
* **Revocable developer credentials.** Each developer pastes an AI Consumer API key from Kong into Cursor instead of an OpenAI key. Kong attributes every request to the matching AI Consumer, and revoking a developer means deleting one AI Consumer credential.
* **Bearer-token compatibility.** Kong accepts the key in the `Authorization: Bearer` header that Cursor sends, so developers don't change anything beyond the key and base URL.
* **One pinned model.** The AI Model only accepts requests that name the model you choose, so every developer uses the same upstream model regardless of what else they configure in Cursor.
* **One place for future policy.** Once traffic flows through Kong, you can add logging, rate limiting, and other AI Policies without changing anything on developer machines.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Cursor editor
    participant CB as Cursor servers
    participant K as AI Gateway
    participant O as OpenAI API

    C->>CB: Chat request (AI Consumer key, custom model)
    CB->>K: POST /coding-agents/chat/completions (Authorization: Bearer AI Consumer key)
    activate K
    K->>K: Pre-Function Policy copies Bearer token to apikey
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: AI Model matches model to CHAT_MODEL, AI Model Provider swaps in org OpenAI key
    K->>O: POST /v1/chat/completions (Authorization: org key)
    activate O
    O-->>K: Chat Completions response (streamed)
    deactivate O
    K-->>CB: Response
    deactivate K
    CB-->>C: Reply rendered in chat
{% endmermaid %}
<!-- vale on -->

{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibility
    key: responsibility
rows:
  - component: "Cursor"
    responsibility: "Sends chat requests through Cursor's servers to the overridden OpenAI base URL, with the AI Consumer key as `Authorization: Bearer <key>`."
  - component: "Pre-Function Policy"
    responsibility: "Copies the Bearer token into the `apikey` header that the Key Auth AI Auth Strategy reads."
  - component: "Key Auth AI Auth Strategy"
    responsibility: "Validates the AI Consumer key, attaches the request to the AI Consumer, and removes the `apikey` header before the request goes upstream."
  - component: "AI Consumer"
    responsibility: "Represents one developer. Its API key credential is the only secret the developer holds."
  - component: "AI Model"
    responsibility: "Exposes `/coding-agents`, accepts OpenAI Chat Completions requests, and only routes requests whose `model` matches `CHAT_MODEL`."
  - component: "AI Model Provider"
    responsibility: "Holds the organization's OpenAI API key and injects it into every upstream request."
  - component: "OpenAI API"
    responsibility: "Serves the model inference and bills the organization's account."
{% endtable %}

## How it works

When you send a chat message in Cursor with the custom model selected, the request goes through these steps:

1. **Cursor's servers send the request to Kong.** With **Override OpenAI Base URL** set to `${KONG_PUBLIC_URL}/coding-agents`, Cursor's servers post Chat Completions requests to `/coding-agents/chat/completions` on your public hostname. The AI Consumer key from **OpenAI API Key** arrives as `Authorization: Bearer <key>`.
1. **The Pre-Function Policy normalizes the credential.** The global Pre-Function Policy reads the `Authorization` header, strips the `Bearer ` prefix, and writes the bare key into an `apikey` header.
1. **Kong authenticates the developer.** The AI Model lists the Key Auth AI Auth Strategy in `access.auth_strategies`. The AI Auth Strategy reads `apikey`, matches it against the AI Consumer credentials, and attaches the request to `coding-agents-consumer`. A missing or unknown key returns `401`. With `hide_credentials` enabled, it removes `apikey` before the request goes upstream.
1. **The AI Model checks the model name.** The AI Model uses the `openai` format with a model selector on the body's `model` field. Only a request whose `model` equals `CHAT_MODEL` reaches this AI Model.
1. **The AI Model Provider injects the organization's key.** The target references the AI Model Provider, which sets `Authorization` to the organization's OpenAI key, replacing the AI Consumer key Cursor sent. Kong sends the target's `name` upstream as the model, and OpenAI bills the organization's account.
1. **The response streams back.** OpenAI streams the response back through Kong and Cursor's servers to the editor. Kong logs the request against the AI Consumer.

### Pre-Function: Bearer token to `apikey`

Cursor sends the **OpenAI API Key** value as a Bearer token in the `Authorization` header. The Key Auth AI Auth Strategy reads the key from a named header but doesn't strip a `Bearer ` prefix, so a Bearer token on its own never matches an AI Consumer credential. The [Pre-Function](/ai-gateway/policies/pre-function/) Policy closes that gap: it copies the token into the `apikey` header before authentication runs. The Policy is global, so it applies to every resource on the recipe's {{site.ai_gateway}}.

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

**`global: true`**: Applies the Policy globally to all resources on the {{site.ai_gateway}}, so it doesn't need to be attached to the AI Model. Any other AI Model you add to the same {{site.ai_gateway}} gets the same rewrite.

**`config.rewrite`**: Runs the Lua in the `rewrite` phase, ahead of the Key Auth AI Auth Strategy check, so the new `apikey` header exists when authentication reads it.

**`string.lower(auth)` check**: Matches the `Bearer ` prefix case-insensitively and leaves requests without a Bearer token untouched. Those requests have no `apikey` header and fail authentication with `401`.

**`ngx.req.set_header`**: Sets the header on the incoming request, so later processing in Kong, including the AI Auth Strategy, sees it.

### Key Auth: AI Consumer authentication

The Key Auth AI Auth Strategy is what lets each developer hold a Kong credential instead of an OpenAI key. After the Pre-Function Policy runs, the AI Consumer key is in the `apikey` header, so the AI Auth Strategy reads it from there. Kong attributes each request to the AI Consumer that owns the key, and deleting the credential revokes access without touching the organization's OpenAI key. Authentication in {{site.ai_gateway_name}} is an AI Auth Strategy that the AI Model references, not an AI Policy.

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

**`key_names: [apikey]`**: The header Kong reads the AI Consumer key from. The Pre-Function Policy writes Cursor's Bearer token into this header, so it's the only name the AI Auth Strategy needs.

**`hide_credentials: true`**: Removes `apikey` from the request before Kong forwards it. The AI Model Provider also overwrites `Authorization` with the organization's key, so OpenAI never sees the AI Consumer key.

**`credentials[].api_key`**: The AI Consumer's key. The field is write-only, so it takes a `!secret` reference rather than a plain string.

**Scaling AI Consumers**: Add one AI Consumer per developer, each with its own credential. The recipe defines one AI Consumer for demonstration.

### AI Model and AI Model Provider: OpenAI Chat Completions with a pinned model

The AI Model gives Cursor an OpenAI-compatible base URL, and the AI Model Provider supplies the credential OpenAI expects. The AI Model uses the `openai` format with a model selector, so it only accepts requests whose `model` field equals `CHAT_MODEL`. That is why the custom model you add in Cursor must match `CHAT_MODEL` exactly. The target sends its own `name` upstream as the model, and the AI Model Provider replaces the developer's credential with the organization's key.

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

**`config.auth.headers`** (AI Model Provider): The header Kong adds to every upstream request. OpenAI authenticates with `Authorization`, which is why `OPENAI_TOKEN` includes the `Bearer ` prefix.

**`formats: [{type: openai}]`**: Accepts OpenAI-format requests such as Chat Completions. To forward a tool's native wire format unchanged instead, use the `passthrough` format, as the [Claude Code recipe](/cookbooks/coding-agents-claude-code/) does for Anthropic's Messages API.

**`route.model`**: Matches the request body's `model` field (`body_param: model`) against `values`, which holds exactly one value. A request naming any other model doesn't reach this AI Model, so Cursor's custom model name must equal `CHAT_MODEL`.

**`targets[].name`**: The model name Kong sends to OpenAI. The recipe sets it to `CHAT_MODEL` as well, so the name Cursor sends and the name OpenAI receives match. Set it to a different value to keep the name developers use stable while you change the upstream model.

**`route.paths` and `strip_path: true`**: Cursor appends `/chat/completions` to the base URL. Kong matches the `/coding-agents` prefix and strips it before routing to the target.

**`route.methods`**: `POST` carries Chat Completions requests. The route also accepts `GET` and `OPTIONS`.

**`max_request_body_size: 16777216`**: Raises the request body limit to 16 MB from the 8 MB default. Coding requests carry conversation history and file contents, and long sessions can exceed the default.

**`response_streaming: allow`**: Lets OpenAI stream responses back so Cursor can render tokens as they arrive.

**`logging.payloads: true`**: Captures full request and response bodies. Cursor requests include source code and file contents, so payload logging can expose sensitive data in your logging destination. Set it to `false` if you only need usage metrics.

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. AI Vaults support HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store.

## Apply the Kong configuration

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply command can manage it. The `coding-agents-cursor-recipe` namespace scopes every resource, so teardown removes only this recipe's configuration.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Choose the model that Cursor's custom model name and the AI Model's selector both use:

```bash
export CHAT_MODEL='gpt-4o-mini'
```

The following configuration creates the AI Model Provider with the organization's OpenAI key, the Key Auth AI Auth Strategy, the demo AI Consumer, the global Pre-Function Policy, and the AI Model. `AI_GATEWAY_ID`, `OPENAI_TOKEN`, and `CONSUMER_API_KEY` are already exported from the prerequisites.

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: coding-agents-cursor-recipe
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

Point Cursor at the AI Model through your public URL, send a request directly to confirm the gateway path, and then send a prompt from Cursor. You also send a request without a key to see Key Auth reject it.

### Configure Cursor

Cursor's [API keys page](https://cursor.com/help/models-and-usage/api-keys) covers adding your own key under **Cursor Settings** > **Models**. The OpenAI base URL override and custom model settings are in the same place.

1. Open **Cursor Settings** > **Models**.
1. Paste `CONSUMER_API_KEY` into **OpenAI API Key** and turn **Use OpenAI API Key** on.
1. Turn **Override OpenAI Base URL** on, and set **Base URL** to your public URL plus the AI Model path:

   ```bash
   echo "${KONG_PUBLIC_URL}/coding-agents"
   ```

   Cursor appends `/chat/completions`. Include the `/coding-agents` path, because a bare host doesn't match the AI Model route.
1. Click **+ Add Custom Model** and add exactly `gpt-4o-mini` (or your `CHAT_MODEL`). Select that custom model in chat, not a model from Cursor's built-in catalog.

To use Cursor's built-in models again, turn **Override OpenAI Base URL** off. Own API keys only work with chat models. [Tab completion keeps using Cursor's built-in models](https://cursor.com/help/models-and-usage/api-keys) and doesn't go through Kong.

{:.warning}
> Cursor's servers, not your machine, call the **Base URL**. Cursor rejects private destinations (`localhost`, `127.0.0.1`, and RFC 1918 addresses) with HTTP `403` and `Access to private networks is forbidden`, and a hostname mapped to `127.0.0.1` in `/etc/hosts` doesn't resolve from Cursor's servers. Set **Base URL** to a public hostname that reaches the data plane proxy on port `8000`.

### Send a request through the AI Model

Call Chat Completions with the AI Consumer key as a Bearer token, the same way Cursor does. If you set `CHAT_MODEL` to a different model, replace `gpt-4o-mini` in the request body:

```bash
curl -sS -X POST "http://localhost:8000/coding-agents/chat/completions" \
  -H "Authorization: Bearer ${CONSUMER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Reply with exactly: cursor-ok"}]}'
```

Kong returns HTTP `200` with an OpenAI Chat Completions response. The response looks similar to this abbreviated example, with different IDs and token counts:

```json
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "cursor-ok"
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
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hi"}]}'
```

Kong rejects the request before it reaches OpenAI:

```text
401
```
{:.no-copy-code}

### Send a prompt from Cursor

Select the custom model in Cursor chat and send `Reply with exactly: cursor-ok`. Cursor replies with `cursor-ok`.

If the request fails:

* `403 Access to private networks is forbidden` means Cursor's servers can't reach the **Base URL**. Use a public hostname.
* `User API Key Rate limit exceeded` often wraps an upstream failure or an API key mismatch. Check that the data plane logs show `POST /coding-agents/chat/completions`.

### What happened

1. **The direct request** carried the AI Consumer key as `Authorization: Bearer <key>`. The Pre-Function Policy copied the key into `apikey`, the Key Auth AI Auth Strategy matched it to `coding-agents-consumer`, and the AI Model accepted the request because `model` matched `CHAT_MODEL`. The AI Model Provider replaced the credential with the organization's OpenAI key, and OpenAI answered with `cursor-ok`.
1. **The request without a key** had no Bearer token, so the Pre-Function Policy set no `apikey` header and the Key Auth AI Auth Strategy returned `401`. Kong never contacted OpenAI, so the organization's key was never used.
1. **The Cursor prompt** followed the same path as the direct request, except that Cursor's servers sent it to your public URL. Cursor appended `/chat/completions` to the **Base URL** and sent the custom model name as `model`. Cursor never had access to the organization's OpenAI key.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `coding-agents-cursor-recipe`. The recipe created an AI Model Provider (`coding-agents-openai-provider`) holding the organization's OpenAI key, an AI Model (`coding-agents-openai`) at `/coding-agents`, a Key Auth AI Auth Strategy (`coding-agents-key-auth`), a global Pre-Function Policy (`coding-agents-bearer-to-apikey`), and an AI Consumer (`coding-agents-consumer`) with an API key credential, all scoped to this recipe by the kongctl namespace.

For request, token, and per-AI Consumer analysis across every {{site.ai_gateway}}, open the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

* **Issue one AI Consumer per developer.** Add an AI Consumer and credential for each developer so usage and revocation are per person. Distribute each key through your secrets tooling instead of sharing the demo key.
* **Connect other tools to the same pattern.** The [OpenCode](/cookbooks/coding-agents-opencode/) and [LibreChat](/cookbooks/coding-agents-librechat/) recipes use the same OpenAI-compatible AI Model and Bearer normalization.
* **Enforce per-developer token budgets.** Add an [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy that counts tokens per AI Consumer. The [GitHub Copilot BYOK recipe](/cookbooks/github-copilot-byok/) shows a per-AI Consumer token budget on the same Bearer-to-`apikey` pattern.
* **Move credentials into a vault.** Use [AI Vaults](/ai-gateway/entities/ai-vault/) to source the OpenAI key and AI Consumer credentials from HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, or the {{site.konnect_short_name}} Config Store.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-cursor-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
