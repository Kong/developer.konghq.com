---
title: "AI Tool Integration: LibreChat"
description: Point LibreChat OPENAI_REVERSE_PROXY at {{site.ai_gateway_name}} Chat Completions.
url: "/cookbooks/coding-agents-librechat/"
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
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-librechat-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-librechat-recipe`, a local data plane connected to it, and prints `export` lines (including `AI_GATEWAY_ID`). Paste those into your shell when prompted.
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
  Use LibreChat when a browser chat UI should talk to the same OpenAI-compatible AI Model as the CLIs.
---

## The problem

[LibreChat](https://www.librechat.ai/docs) is a self-hosted chat UI that many teams run as a shared internal assistant. Its OpenAI endpoint reads the provider key and model list from the server's environment. That works for a single deployment with one key, but an organization that runs LibreChat next to CLIs and coding agents on the same OpenAI account runs into several problems:

* **The provider key lives in the chat server's environment.** The simplest setup puts the organization's OpenAI key in [`OPENAI_API_KEY`](https://www.librechat.ai/docs/configuration/dotenv#openai) in LibreChat's `.env` file or container environment. Anyone with access to that host, container, or deployment manifest can read a credential that bills the organization's account, and every other internal tool that calls OpenAI holds its own copy of the same key.
* **Usage from the chat UI is mixed with everything else.** OpenAI bills LibreChat traffic and CLI or agent traffic to the same account. Without a shared point of attribution, you can't tell how much of the bill came from the chat UI and how much came from other tools.
* **Model choice and policy are set per deployment.** [`OPENAI_MODELS`](https://www.librechat.ai/docs/configuration/dotenv#openai) controls which models LibreChat offers, and each deployment sets it independently. Rate limits, logging, and model restrictions have to be configured separately for each tool, or not at all.
* **A gateway has to accept LibreChat's OpenAI client as-is.** LibreChat's OpenAI endpoint sends Chat Completions requests to the base URL in `OPENAI_REVERSE_PROXY` and sends `OPENAI_API_KEY` as an `Authorization: Bearer` header. A gateway that expects its client key in a different header rejects these requests unless LibreChat can change how it sends the key.

The root issue is that the provider credential and the policy sit on each client deployment. Teams need one server-side point that holds the organization's OpenAI key, authenticates LibreChat with a credential it can revoke, and accepts LibreChat's OpenAI Chat Completions traffic without changes to LibreChat.

## The solution

This recipe puts {{site.ai_gateway}} between LibreChat and the OpenAI API:

* **Server-side provider credential.** The organization's OpenAI API key lives on {{site.ai_gateway}}. LibreChat holds only an AI Consumer key, and rotating the OpenAI key is one configuration change.
* **Revocable client credentials.** LibreChat sends an AI Consumer API key from Kong instead of an OpenAI key. Kong attributes every request to the matching AI Consumer, and revoking LibreChat's access means deleting one AI Consumer credential.
* **Bearer token compatibility.** A global Pre-Function Policy copies the `Authorization: Bearer` token into the header that Key Auth reads, so LibreChat authenticates without any change to how it sends the key.
* **One allowed model.** The AI Model accepts only requests that name the model in `CHAT_MODEL`, and the same value configures LibreChat's model list.
* **One place for future policy.** After traffic flows through Kong, you can add logging, rate limiting, and other AI Policies without changing the LibreChat deployment.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant LC as LibreChat
    participant K as AI Gateway
    participant O as OpenAI API

    LC->>K: POST /coding-agents/chat/completions (Authorization: Bearer AI Consumer key)
    activate K
    K->>K: Pre-Function Policy copies Bearer token into apikey header
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: AI Model matches model field, AI Model Provider swaps in org OpenAI key
    K->>O: POST /v1/chat/completions (Authorization: org key)
    activate O
    O-->>K: Chat Completions response (streamed)
    deactivate O
    K-->>LC: Chat Completions response
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
  - component: "LibreChat"
    responsibility: "Sends OpenAI Chat Completions requests to `OPENAI_REVERSE_PROXY` with the AI Consumer key as `Authorization: Bearer`."
  - component: "Pre-Function Policy"
    responsibility: "Copies the Bearer token from `Authorization` into the `apikey` header before authentication."
  - component: "Key Auth AI Auth Strategy"
    responsibility: "Validates the AI Consumer key in `apikey`, attaches the request to the AI Consumer, and removes the key before the request goes upstream."
  - component: "AI Consumer"
    responsibility: "Represents the LibreChat deployment. Its API key credential is the only secret LibreChat holds."
  - component: "AI Model"
    responsibility: "Exposes `/coding-agents`, accepts OpenAI-format requests whose `model` field equals `CHAT_MODEL`, and routes them to the OpenAI target."
  - component: "AI Model Provider"
    responsibility: "Holds the organization's OpenAI API key and injects it into every upstream request."
  - component: "OpenAI API"
    responsibility: "Serves the model inference and bills the organization's account."
{% endtable %}

## How it works

When you send a message in LibreChat, the request goes through these steps:

1. **LibreChat sends the request to Kong.** With `OPENAI_REVERSE_PROXY` set to `http://host.docker.internal:8000/coding-agents`, LibreChat's OpenAI endpoint posts Chat Completions requests to `/coding-agents/chat/completions`. Because `OPENAI_API_KEY` holds the AI Consumer key, LibreChat sends that key as `Authorization: Bearer <key>`. The body's `model` field is the model you selected, which comes from `OPENAI_MODELS`.
1. **Kong copies the Bearer token.** The global Pre-Function Policy runs Lua in the rewrite phase. It reads `Authorization`, and if the value starts with `Bearer `, it writes the token into the `apikey` header.
1. **Kong authenticates the request.** The AI Model lists the Key Auth AI Auth Strategy in `access.auth_strategies`. The AI Auth Strategy reads `apikey`, matches it against the AI Consumer credentials, and attaches the request to `coding-agents-consumer`. A missing or unknown key returns `401`. With `hide_credentials` enabled, the AI Auth Strategy removes `apikey` before the request goes upstream.
1. **The AI Model matches the requested model.** The AI Model's route accepts requests on `/coding-agents` whose `model` body field equals `CHAT_MODEL`. Kong strips the `/coding-agents` prefix and forwards the request through the target named `CHAT_MODEL`.
1. **The AI Model Provider injects the organization's key.** The target references the AI Model Provider, which sets `Authorization` to the organization's OpenAI API key. The client's Bearer token never reaches OpenAI.
1. **The response returns to LibreChat.** OpenAI's Chat Completions response flows back through Kong to LibreChat, streamed when LibreChat requests streaming. Kong logs the request against the AI Consumer.

### Pre-Function: Bearer token to apikey

LibreChat sends its key the way every OpenAI client does, as `Authorization: Bearer <key>`. The Key Auth AI Auth Strategy reads the key from a header listed in `key_names` and doesn't strip a `Bearer ` prefix, so it can't use the `Authorization` value directly. The [Pre-Function](/ai-gateway/policies/pre-function/) Policy bridges that gap: it copies the token into `apikey` before authentication runs. This lets LibreChat authenticate with an AI Consumer key without any LibreChat-side change.

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

**`config.rewrite`**: An array of Lua source strings that Kong runs in the rewrite phase, before the Key Auth AI Auth Strategy authenticates the request. Each function has access to the [Kong PDK](/gateway/pdk/reference/) and the `ngx` namespace.

**`ngx.req.set_header("apikey", ...)`**: Sets the header on the incoming request, so the Key Auth AI Auth Strategy sees it. The scheme comparison is case-insensitive, and the Lua code leaves requests without a Bearer token unchanged, so they fail authentication with `401`.

**`global: true`**: Applies the Policy globally to all resources in the {{site.ai_gateway}}. Any AI Model you add later that uses the same AI Auth Strategy also accepts Bearer tokens without its own Pre-Function Policy.

### Key Auth: AI Consumer authentication

The Key Auth AI Auth Strategy is what lets LibreChat hold a Kong credential instead of an OpenAI key. It reads the AI Consumer key from the `apikey` header that the Pre-Function Policy sets, attributes each request to the AI Consumer that owns the key, and rejects anything else with `401`. Deleting the credential revokes LibreChat's access without touching the organization's OpenAI key. Authentication in {{site.ai_gateway_name}} is an AI Auth Strategy that the AI Model references, not an AI Policy.

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

**`key_names: [apikey]`**: The header Kong reads the AI Consumer key from. The Pre-Function Policy writes LibreChat's Bearer token into this header, so one name is enough.

**`hide_credentials: true`**: Removes `apikey` from the request before Kong forwards it. The AI Model Provider then sets `Authorization` with the organization's key, so OpenAI only sees the provider credential.

**`credentials[].api_key`**: The AI Consumer's key. The field is write-only, so it takes a `!secret` reference rather than a plain string.

**Scaling AI Consumers**: LibreChat sends one server-side `OPENAI_API_KEY` for all of its users, so every LibreChat user maps to the same AI Consumer. Give each LibreChat deployment, or each other tool, its own AI Consumer to separate their usage.

### AI Model and AI Model Provider: OpenAI routing with credential injection

The AI Model gives LibreChat an OpenAI-compatible base URL, and the AI Model Provider supplies the credential OpenAI expects. The AI Model uses the `openai` format with a model selector, so it accepts only requests whose `model` field equals `CHAT_MODEL`. That addresses the per-deployment model problem: LibreChat's `OPENAI_MODELS` and the AI Model read the same value, and a request for any other model doesn't reach OpenAI. The AI Model Provider keeps the OpenAI key on the gateway, where LibreChat can't read it.

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

**`formats: [{type: openai}]`**: LibreChat's OpenAI endpoint speaks the OpenAI Chat Completions API, so the AI Model accepts OpenAI-format requests.

**`route.paths` and `strip_path: true`**: LibreChat appends `/chat/completions` to `OPENAI_REVERSE_PROXY`. Kong matches the `/coding-agents` prefix, strips it, and forwards the rest of the request to OpenAI.

**`route.methods`**: LibreChat sends `POST` for Chat Completions. The route also accepts `GET`, and `OPTIONS` for preflight requests from browser-based clients.

**`route.model`**: Reads the `model` field from the request body (`body_param: model`) and matches it against `values`. The field accepts one value per AI Model, so LibreChat must send exactly the value of `CHAT_MODEL`. To offer a second model, add a second AI Model with its own selector value and list both models in `OPENAI_MODELS`.

**`targets[].name`**: The model name Kong sends upstream. It equals the selector value in this recipe, so OpenAI receives the same model name LibreChat requested. Set them independently if you want LibreChat to show a different name from the upstream model.

**`max_request_body_size: 16777216`**: Raises the request body limit to 16 MB from the 8 MB default. Each LibreChat request carries the conversation history, and long conversations with pasted content can exceed the default.

**`response_streaming: allow`**: Lets OpenAI stream Server-Sent Events back to LibreChat, which renders tokens as they arrive.

**`logging.payloads: true`**: Captures full request and response bodies. Chat conversations can include sensitive data, so payload logging can expose it in your logging destination. Set it to `false` if you only need usage metrics.

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. AI Vaults support HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store.

## Apply the Kong configuration

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply command can manage it. The `coding-agents-librechat-recipe` namespace scopes every resource, so teardown removes only this recipe's configuration.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the model that LibreChat offers and the AI Model accepts:

```bash
export CHAT_MODEL='gpt-4o-mini'
```

The following configuration creates the AI Model Provider with the organization's OpenAI key, the Key Auth AI Auth Strategy, the demo AI Consumer, the global Pre-Function Policy, and the OpenAI-format AI Model. `AI_GATEWAY_ID`, `OPENAI_TOKEN`, and `CONSUMER_API_KEY` are already exported from the prerequisites.

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: coding-agents-librechat-recipe
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

Send a request directly to the AI Model to confirm the gateway path, send one without a key to see Key Auth reject it, and then start LibreChat in Docker and chat through Kong.

### Send a request through the AI Model

Call the Chat Completions API through Kong with the AI Consumer key as a Bearer token, the same way LibreChat sends it:

```bash
curl -sS -X POST "http://localhost:8000/coding-agents/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${CONSUMER_API_KEY}" \
  -d "{
    \"model\": \"${CHAT_MODEL}\",
    \"messages\": [{\"role\": \"user\", \"content\": \"Reply with exactly: smoke-ok\"}]
  }"
```

Kong returns OpenAI's Chat Completions response. The response looks similar to this, with different IDs and token counts:

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
  -d "{\"model\": \"${CHAT_MODEL}\", \"messages\": [{\"role\": \"user\", \"content\": \"hi\"}]}"
```

Kong rejects the request before it reaches OpenAI:

```text
401
```
{:.no-copy-code}

### Configure and start LibreChat

LibreChat runs in Docker with a MongoDB container. Its container reaches the data plane on your machine through `host.docker.internal`, which the [`extra_hosts`](https://docs.docker.com/reference/compose-file/services/#extra_hosts) entry maps to the host.

Generate the secrets LibreChat requires. [LibreChat's environment reference](https://www.librechat.ai/docs/configuration/dotenv) requires a 32-byte `CREDS_KEY` (64 hexadecimal characters), a 16-byte `CREDS_IV` (32 hexadecimal characters), and unique JWT secrets of at least 32 bytes:

```bash
export LIBRECHAT_JWT_SECRET="$(openssl rand -hex 32)"
export LIBRECHAT_JWT_REFRESH_SECRET="$(openssl rand -hex 32)"
export LIBRECHAT_CREDS_KEY="$(openssl rand -hex 32)"
export LIBRECHAT_CREDS_IV="$(openssl rand -hex 16)"
```

Write the Compose file. Compose fills in `CONSUMER_API_KEY`, `CHAT_MODEL`, and the secrets from your shell:

```bash
cat <<'EOF' > librechat-compose.yaml
services:
  librechat:
    image: ghcr.io/danny-avila/librechat:latest
    ports:
      - "3080:3080"
    environment:
      HOST: "0.0.0.0"
      PORT: "3080"
      ALLOW_EMAIL_LOGIN: "true"
      ALLOW_REGISTRATION: "true"
      JWT_SECRET: "${LIBRECHAT_JWT_SECRET}"
      JWT_REFRESH_SECRET: "${LIBRECHAT_JWT_REFRESH_SECRET}"
      CREDS_KEY: "${LIBRECHAT_CREDS_KEY}"
      CREDS_IV: "${LIBRECHAT_CREDS_IV}"
      MONGO_URI: "mongodb://mongo:27017/LibreChat"
      OPENAI_API_KEY: "${CONSUMER_API_KEY}"
      OPENAI_REVERSE_PROXY: "http://host.docker.internal:8000/coding-agents"
      OPENAI_MODELS: "${CHAT_MODEL}"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    depends_on:
      - mongo
  mongo:
    image: mongo:7
    volumes:
      - librechat-mongo:/data/db
volumes:
  librechat-mongo:
EOF
```

The LibreChat settings that connect it to Kong:

* **`OPENAI_API_KEY`**: The AI Consumer key. LibreChat sends it as `Authorization: Bearer`, and the Pre-Function Policy copies it into `apikey`.
* **`OPENAI_REVERSE_PROXY`**: The AI Model's base URL. LibreChat appends `/chat/completions`.
* **`OPENAI_MODELS`**: The comma-separated list of models LibreChat offers, where the first is the default. It's set to `CHAT_MODEL` so LibreChat only offers the model the AI Model accepts.

Start LibreChat:

```bash
docker compose -f librechat-compose.yaml up -d
```

### Send a prompt from LibreChat

Open `http://localhost:3080`, register an account, and sign in. Select the OpenAI endpoint and the `CHAT_MODEL` model, then send a short prompt. LibreChat shows the model's reply, and the data plane logs show `POST /coding-agents/chat/completions` from the `langchainjs-openai` user agent.

### What happened

1. **The direct request** carried the AI Consumer key as `Authorization: Bearer`. The Pre-Function Policy copied it into `apikey`, the Key Auth AI Auth Strategy matched it to `coding-agents-consumer` and removed it, and the AI Model Provider replaced `Authorization` with the organization's OpenAI key. OpenAI answered with `smoke-ok`.
1. **The request without a key** had no Bearer token for the Pre-Function Policy to copy, so it failed at the Key Auth AI Auth Strategy with `401`. Kong never contacted OpenAI, so the organization's key was never used.
1. **The LibreChat prompt** followed the same path as the direct request. LibreChat appended `/chat/completions` to `OPENAI_REVERSE_PROXY`, sent the AI Consumer key as a Bearer token, and named `CHAT_MODEL` in the `model` field, which matched the AI Model's selector. LibreChat never had access to the organization's OpenAI key.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `coding-agents-librechat-recipe`. The recipe created an AI Model Provider (`coding-agents-openai-provider`) holding the organization's OpenAI key, an AI Model (`coding-agents-openai`) at `/coding-agents`, a Key Auth AI Auth Strategy (`coding-agents-key-auth`), an AI Consumer (`coding-agents-consumer`) with an API key credential, and a global Pre-Function Policy (`coding-agents-bearer-to-apikey`), all scoped to this recipe by the kongctl namespace.

For request, token, and per-AI Consumer analysis across every {{site.ai_gateway}}, open the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

* **Connect more tools to the same AI Model.** The `/coding-agents` AI Model accepts any OpenAI Chat Completions client that sends a Bearer token. The [Open WebUI recipe](/cookbooks/coding-agents-open-webui/) connects another browser chat UI the same way. For terminal coding agents on the same AI Model configuration, see the [OpenCode](/cookbooks/coding-agents-opencode/) and [Qwen Code](/cookbooks/coding-agents-qwen-code/) recipes.
* **Let each LibreChat user enter their own AI Consumer key.** Set `OPENAI_API_KEY` to `user_provided` so [each user supplies their own key](https://www.librechat.ai/docs/configuration/dotenv#openai) in the LibreChat UI. Issue one AI Consumer per user, and Kong attributes usage and revocation per person instead of per deployment.
* **Move to a LibreChat custom endpoint.** LibreChat marks `OPENAI_REVERSE_PROXY` as deprecated and recommends a [custom endpoint](https://www.librechat.ai/docs/configuration/librechat_yaml/object_structure/custom_endpoint) in `librechat.yaml`. Set its `baseURL` to `http://host.docker.internal:8000/coding-agents`, `apiKey` to the AI Consumer key, and `models.default` to `CHAT_MODEL`.
* **Move credentials into a vault.** Use [AI Vaults](/ai-gateway/entities/ai-vault/) to source the OpenAI key and AI Consumer credentials from HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, or the {{site.konnect_short_name}} Config Store.

## Cleanup

Stop LibreChat and MongoDB, remove their data volume, and delete the Compose file:

```bash
docker compose -f librechat-compose.yaml down -v
```

```bash
rm -f librechat-compose.yaml
```

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-librechat-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
