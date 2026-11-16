---
title: "AI Tool Integration: Open WebUI"
description: Point Open WebUI at {{site.ai_gateway_name}} with explicit Model IDs.
url: "/cookbooks/coding-agents-open-webui/"
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

hint: "Requires Kong AI Gateway 2.2+, an OpenAI API key, Docker, and Docker Compose."
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
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-open-webui-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-open-webui-recipe`, a local data plane connected to it, and prints `export` lines (including `AI_GATEWAY_ID`). Paste those into your shell when prompted.
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
    - title: Docker
      content: |
        Install Docker and Docker Compose. Export `CONSUMER_API_KEY` in the shell that starts Compose.
overview: |
  Use Open WebUI when you want a browser chat UI on Chat Completions. An AI Model with the `openai` format doesn't serve `GET /models`, so Open WebUI can't discover models. Set the model IDs explicitly.
---

## The problem

[Open WebUI](https://docs.openwebui.com/) is a self-hosted browser chat UI that talks to any OpenAI-compatible API. Pointing it straight at OpenAI works for one person, but an organization that runs Open WebUI for a team on a shared OpenAI account runs into several problems:

* **The provider key lives in every Open WebUI deployment.** The direct setup sets [`OPENAI_API_KEY`](https://docs.openwebui.com/reference/env-configuration/) to an OpenAI key, or an admin pastes the key into the connection settings. Open WebUI persists that value in its own database, so each instance, its volume, and its backups hold a credential that bills the organization's account. Open WebUI's own documentation advises least-privilege keys for regular user traffic, but the key is still a provider credential sitting outside your control point.
* **Usage isn't attributed to a team or deployment.** Every request from every Open WebUI instance reaches OpenAI under the same key. The provider bill is one line item, and you can't revoke one deployment's access without rotating the key for everyone.
* **There is no central place to apply policy.** Logging, rate limits, and model restrictions have to be configured per Open WebUI instance or per provider console. Nothing sits between the chat UI and the provider where an organization can enforce them once.
* **The client's wire format constrains the gateway.** Open WebUI sends its API key as a standard Bearer token, and it expects the backend to answer `GET /models` so it can fill the model selector. Open WebUI's [connection guide](https://docs.openwebui.com/getting-started/quick-start/connect-a-provider/starting-with-openai-compatible) notes that some backends don't serve `/models`, and in that case you list the **Model IDs** yourself. A gateway in front of Open WebUI has to accept a Bearer token and work with an explicit model list.

The root issue is that the credential and the policy both sit in the chat UI deployment. Teams need one server-side point that holds the organization's OpenAI key, authenticates each Open WebUI deployment with a credential it can revoke, and accepts the requests Open WebUI already sends.

## The solution

This recipe puts {{site.ai_gateway}} between Open WebUI and the OpenAI API:

* **Server-side provider credential.** The organization's OpenAI API key lives on {{site.ai_gateway}}. Open WebUI never stores it, and rotating it is one configuration change.
* **Revocable client credentials.** Open WebUI holds an AI Consumer API key from Kong instead of an OpenAI key. Kong attributes every request to the matching AI Consumer, and revoking access means deleting one AI Consumer credential.
* **Bearer token compatibility.** A Pre-Function Policy copies the Bearer token Open WebUI sends into the header that the Key Auth AI Auth Strategy reads, so Open WebUI needs no custom headers.
* **One pinned model.** The AI Model accepts only the model named in `CHAT_MODEL`. You list that same model ID in Open WebUI, so the model selector shows exactly what Kong serves.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant W as Open WebUI
    participant K as AI Gateway
    participant O as OpenAI API

    W->>K: POST /coding-agents/chat/completions (Authorization: Bearer AI Consumer key)
    activate K
    K->>K: Pre-Function Policy copies Bearer token into apikey
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: AI Model matches model to CHAT_MODEL, AI Model Provider swaps in org OpenAI key
    K->>O: Chat Completions request (Authorization: org key)
    activate O
    O-->>K: Chat Completions response (streamed)
    deactivate O
    K-->>W: OpenAI-format response
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
  - component: "Open WebUI"
    responsibility: "Sends Chat Completions requests to the connection URL with the AI Consumer key as a Bearer token, using the model IDs you list."
  - component: "Pre-Function Policy"
    responsibility: "Copies the token from `Authorization: Bearer <key>` into the `apikey` header before authentication runs."
  - component: "Key Auth AI Auth Strategy"
    responsibility: "Validates the `apikey` header, attaches the request to the AI Consumer, and removes the key before the request goes upstream."
  - component: "AI Consumer"
    responsibility: "Represents the Open WebUI deployment. Its API key credential is the only secret Open WebUI holds."
  - component: "AI Model"
    responsibility: "Exposes `/coding-agents`, accepts OpenAI-format requests whose `model` equals `CHAT_MODEL`, and routes them to the OpenAI target."
  - component: "AI Model Provider"
    responsibility: "Holds the organization's OpenAI API key and injects it into every upstream request."
  - component: "OpenAI API"
    responsibility: "Serves the model inference and bills the organization's account."
{% endtable %}

## How it works

When you send a message in Open WebUI, the request goes through these steps:

1. **Open WebUI sends the request to Kong.** With the connection URL set to `http://host.docker.internal:8000/coding-agents`, Open WebUI posts Chat Completions requests to `/coding-agents/chat/completions`. It sends the AI Consumer key as `Authorization: Bearer <key>` and the selected model ID in the body's `model` field.
1. **Kong copies the Bearer token into `apikey`.** The global Pre-Function Policy runs in the rewrite phase, before authentication. It reads the `Authorization` header, strips the `Bearer ` prefix, and writes the remaining token into an `apikey` header.
1. **Kong authenticates the request.** The AI Model lists the Key Auth AI Auth Strategy in `access.auth_strategies`. The AI Auth Strategy reads `apikey`, matches it against the AI Consumer credentials, and attaches the request to `coding-agents-consumer`. A missing or unknown key returns `401`. With `hide_credentials` enabled, the AI Auth Strategy removes `apikey` before the request goes upstream.
1. **The AI Model checks the model name.** The AI Model uses the `openai` format with a model selector on the body's `model` field. Only a request that names exactly the `CHAT_MODEL` value matches this AI Model.
1. **The AI Model Provider injects the organization's key.** The target references the AI Model Provider, which sets `Authorization` to the organization's OpenAI API key. OpenAI authenticates the request against that key and bills the organization's account.
1. **The response streams back.** OpenAI streams the response back through Kong to Open WebUI, which renders tokens as they arrive. Kong logs the request against the AI Consumer.

### Pre-Function: Bearer token to apikey

Open WebUI sends its API key as a Bearer token, but the Key Auth AI Auth Strategy reads the key as-is from the headers in `key_names` and doesn't strip a `Bearer ` prefix. The [Pre-Function](/ai-gateway/policies/pre-function/) Policy bridges that gap: it runs a few lines of Lua before authentication and copies the token into an `apikey` header. That lets Open WebUI keep its standard connection settings while Kong authenticates the request against an AI Consumer credential. The policy is global, so it applies to every AI Model on the {{site.ai_gateway}}.

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

**`config.rewrite`**: An array of Lua source strings that run in the rewrite phase, ahead of authentication. Each function has access to the [Kong PDK](/gateway/pdk/reference/) and the `ngx` namespace.

**The `bearer ` check**: The comparison lowercases the first seven characters, so `Bearer` and `bearer` both match. Requests without a Bearer token pass through unchanged. If they also lack an `apikey` header, the Key Auth AI Auth Strategy returns `401`.

**`ngx.req.set_header("apikey", ...)`**: Sets the header on the incoming request, so the Key Auth AI Auth Strategy sees it in the same request.

**`global: true`**: Applies the policy to all resources on the {{site.ai_gateway}}. If another AI Model on the same {{site.ai_gateway}} should not accept Bearer tokens this way, attach the policy to specific resources instead.

### Key Auth: AI Consumer authentication

The Key Auth AI Auth Strategy is what lets Open WebUI hold a Kong credential instead of an OpenAI key. It reads the AI Consumer key from the `apikey` header that the Pre-Function Policy sets. Kong attributes each request to the AI Consumer that owns the key, and deleting the credential revokes access without touching the organization's OpenAI key. Authentication in {{site.ai_gateway_name}} is an AI Auth Strategy that the AI Model references, not an AI Policy.

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

**`hide_credentials: true`**: Removes `apikey` from the request before Kong forwards it, so the AI Consumer key never reaches OpenAI.

**`credentials[].api_key`**: The AI Consumer's key. The field is write-only, so it takes a `!secret` reference rather than a plain string.

**Scaling AI Consumers**: Add one AI Consumer per Open WebUI deployment or team, each with its own credential. The recipe defines one AI Consumer for demonstration.

### AI Model and AI Model Provider: Chat Completions with credential injection

The AI Model gives Open WebUI an OpenAI-compatible base URL, and the AI Model Provider supplies the credential OpenAI expects. The AI Model uses the `openai` format with a model selector, so it accepts Chat Completions requests only when the body's `model` field equals `CHAT_MODEL`. This AI Model doesn't serve a model list for Open WebUI to discover, which is why you list the model ID explicitly in Open WebUI's connection settings. The organization's key stays on the AI Model Provider, and Open WebUI only ever holds the AI Consumer key.

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

**`config.auth.headers`** (AI Model Provider): The header Kong adds to every upstream request. OpenAI authenticates through `Authorization`, so `OPENAI_TOKEN` holds the full header value, including the `Bearer ` prefix.

**`formats: [{type: openai}]`**: Accepts OpenAI Chat Completions requests, the format Open WebUI sends. To forward request bodies byte-for-byte without schema validation instead, use the `passthrough` format, which requires {{site.ai_gateway}} 2.2 or later and can't be combined with other formats.

**`route.model`**: The model selector. Kong reads the `model` field from the request body (`body_param: model`) and matches it against `values`, which holds one value: `CHAT_MODEL`. Open WebUI must send exactly that model ID, so the **Model IDs** list in Open WebUI uses the same value.

**`targets[].name`**: The model name Kong sends upstream. It's also `CHAT_MODEL` here, so the model the user selects in Open WebUI is the model OpenAI serves.

**`route.paths` and `strip_path: true`**: Open WebUI appends `/chat/completions` to the connection URL. Kong matches the `/coding-agents` prefix and strips it before forwarding.

**`route.methods`**: Open WebUI sends `POST` for chat completions. The route also accepts `GET` and `OPTIONS` on the same path.

**`max_request_body_size: 16777216`**: Raises the request body limit to 16 MB from the 8 MB default. Long chats resend the full conversation with each request.

**`response_streaming: allow`**: Lets OpenAI stream Server-Sent Events back to Open WebUI.

**`logging.payloads: true`**: Captures full request and response bodies. Chat messages can contain sensitive data, so payload logging can expose it in your logging destination. Set it to `false` if you only need usage metrics.

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. AI Vaults support HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store.

## Apply the Kong configuration

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply command can manage it. The `coding-agents-open-webui-recipe` namespace scopes every resource, so teardown removes only this recipe's configuration.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Set the model that the AI Model accepts and sends to OpenAI:

```bash
export CHAT_MODEL='gpt-4o-mini'
```

The following configuration creates the AI Model Provider with the organization's OpenAI key, the Key Auth AI Auth Strategy, the demo AI Consumer, the global Pre-Function Policy, and the AI Model. `AI_GATEWAY_ID`, `OPENAI_TOKEN`, and `CONSUMER_API_KEY` are already exported from the prerequisites.

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: coding-agents-open-webui-recipe
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

Start Open WebUI with a connection to the AI Model, send a request directly to confirm the gateway path, and then chat from the browser. You also send a request without a key to see Key Auth reject it.

### Configure Open WebUI

Run Open WebUI in Docker with an OpenAI-compatible connection to the AI Model. The environment variables follow the [Open WebUI environment variable reference](https://docs.openwebui.com/reference/env-configuration/):

* `OPENAI_API_BASE_URLS` and `OPENAI_API_KEYS` set the connection URL and the AI Consumer key. `host.docker.internal` lets the container reach the data plane on your host's port `8000`.
* `OPENAI_API_CONFIGS` sets per-connection options keyed by the connection's index. `model_ids` lists the model IDs for the connection, because the AI Model doesn't serve a model list.
* `ENABLE_OLLAMA_API: "False"` turns off the default Ollama connection.
* `WEBUI_AUTH: "False"` turns off Open WebUI login for this local demo. Open WebUI only allows this on a fresh installation without existing users.
* `DEFAULT_MODELS` pre-selects the model on a new chat.

Create the Compose file in an empty directory. `model_ids` and `DEFAULT_MODELS` must match `CHAT_MODEL`:

```bash
cat <<'EOF' > compose.yaml
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    ports:
      - "3081:8080"
    environment:
      ENABLE_OLLAMA_API: "False"
      ENABLE_OPENAI_API: "True"
      OPENAI_API_BASE_URLS: "http://host.docker.internal:8000/coding-agents"
      OPENAI_API_KEYS: "${CONSUMER_API_KEY}"
      OPENAI_API_CONFIGS: '{"0":{"enable":true,"model_ids":["gpt-4o-mini"]}}'
      WEBUI_AUTH: "False"
      ENABLE_SIGNUP: "False"
      DEFAULT_MODELS: "gpt-4o-mini"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - open-webui:/app/backend/data
volumes:
  open-webui:
EOF
```

Start Open WebUI from the same directory, in the shell where `CONSUMER_API_KEY` is exported:

```bash
docker compose up -d
```

Open WebUI stores these connection values in its database on first launch and ignores the environment variables on later restarts. To apply changed values, remove the volume with `docker compose down -v` and start again. You can also edit the connection under **Settings > Admin > Connections** and add model IDs to its **Model IDs** list. The **Verify Connection** button in that dialog calls `/models`, which this AI Model doesn't serve, so a verification failure there doesn't mean chat is broken.

### Send a request through the AI Model

Call Chat Completions with the AI Consumer key as a Bearer token, the same way Open WebUI does:

```bash
curl -sS -X POST "http://localhost:8000/coding-agents/chat/completions" \
  -H "Authorization: Bearer ${CONSUMER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Reply with exactly: open-webui-ok"}]}'
```

The response is an OpenAI Chat Completions object. It looks similar to this, with different IDs and token counts:

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
        "content": "open-webui-ok"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 15,
    "completion_tokens": 5,
    "total_tokens": 20
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

### Send a prompt from Open WebUI

Open `http://localhost:3081`, select `gpt-4o-mini`, and send `Reply with exactly: open-webui-ok`. Open WebUI replies with `open-webui-ok`.

### What happened

1. **The direct request** carried the AI Consumer key as a Bearer token. The Pre-Function Policy copied it into `apikey`, the Key Auth AI Auth Strategy matched it to `coding-agents-consumer` and removed it, and the AI Model matched `gpt-4o-mini` against `CHAT_MODEL`. The AI Model Provider replaced the `Authorization` header with the organization's OpenAI key, and OpenAI answered with `open-webui-ok`.
1. **The request without a key** had no Bearer token for the Pre-Function Policy to copy, so the Key Auth AI Auth Strategy found no `apikey` and returned `401`. Kong never contacted OpenAI, so the organization's key was never used.
1. **The Open WebUI prompt** followed the same path as the direct request. Open WebUI appended `/chat/completions` to the connection URL, sent the AI Consumer key from `OPENAI_API_KEYS` as a Bearer token, and used the model ID from `model_ids`. Open WebUI never had access to the organization's OpenAI key.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `coding-agents-open-webui-recipe`. The recipe created an AI Model Provider (`coding-agents-openai-provider`) holding the organization's OpenAI key, an AI Model (`coding-agents-openai`) at `/coding-agents`, a Key Auth AI Auth Strategy (`coding-agents-key-auth`), a global Pre-Function Policy (`coding-agents-bearer-to-apikey`), and an AI Consumer (`coding-agents-consumer`) with an API key credential, all scoped to this recipe by the kongctl namespace.

For request, token, and per-AI Consumer analysis across every {{site.ai_gateway}}, open the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

* **Issue one AI Consumer per deployment or team.** Add an AI Consumer and credential for each Open WebUI deployment so usage and revocation are per deployment. Set each deployment's `OPENAI_API_KEYS` to its own key.
* **Keep environment variables authoritative.** Set [`ENABLE_PERSISTENT_CONFIG`](https://docs.openwebui.com/reference/env-configuration/) to `False` so Open WebUI reads the connection from environment variables on every start instead of its database. Open WebUI then doesn't save connection changes made in the admin UI.
* **Connect LibreChat to the same pattern.** The [LibreChat recipe](/cookbooks/coding-agents-librechat/) points another browser chat UI at the same OpenAI-compatible AI Model.
* **Add token budgets.** Attach an [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to cap tokens per AI Consumer, so one deployment can't exhaust the organization's quota.
* **Move credentials into a vault.** Use [AI Vaults](/ai-gateway/entities/ai-vault/) to source the OpenAI key and AI Consumer credentials from HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, or the {{site.konnect_short_name}} Config Store.

## Cleanup

Stop Open WebUI and remove its volume from the directory that holds `compose.yaml`:

```bash
docker compose down -v
```

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-open-webui-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
