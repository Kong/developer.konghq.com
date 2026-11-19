---
title: "AI Tool Integration: LibreChat"
description: Connect LibreChat to {{site.ai_gateway_name}} through a custom endpoint, so the chat server holds a revocable AI Consumer key and the OpenAI key stays in Kong.
url: "/cookbooks/coding-agents-librechat/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
works_on:
  - konnect
min_version:
  ai-gateway: '2.0'
categories:
  - agents
  - llm
  - access-control
featured: false
popular: false
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped {{site.ai_gateway}} and local data plane.

        1. Create a new personal access token by opening the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. You reuse the same token later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-librechat-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-librechat-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
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
        The AI Model Provider uses your organization's OpenAI API key.

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key:

           ```sh
           export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
    - title: Docker
      content: |
        This tutorial runs LibreChat and its MongoDB database with Docker Compose.

        1. Install [Docker](https://docs.docker.com/get-started/get-docker/) with the [Docker Compose](https://docs.docker.com/compose/install/) plugin.
        1. Verify that both are installed:

           ```bash
           docker --version
           docker compose version
           ```
overview: |
  Put {{site.ai_gateway_name}} between LibreChat and OpenAI, so that the chat server holds an AI Consumer key that you can revoke and the organization's OpenAI key never leaves Kong. You'll set up:

  * A `/coding-agents` endpoint that accepts OpenAI-format chat requests with an `Authorization: Bearer` key
  * A LibreChat custom endpoint that sends its requests to Kong
  * One model that both LibreChat and the AI Model allow
---

## What this cookbook solves

[LibreChat](https://www.librechat.ai/docs) is a self-hosted chat UI, and most teams give it the organization's OpenAI key in the chat server's environment, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Anyone with access to the chat server's host, container, or deployment manifest can read a key that bills the organization's account, and each other internal tool holds its own copy of the same key."
    solution: "The AI Model Provider keeps the OpenAI key in Kong. LibreChat holds only an AI Consumer key, and deleting that credential removes LibreChat's access."
  - problem: "OpenAI bills chat UI traffic and traffic from other tools to the same account, with no way to tell them apart."
    solution: "The Key Auth AI Auth Strategy maps each key to an AI Consumer, so {{site.konnect_short_name}} analytics show usage for LibreChat separately from other tools."
  - problem: "Each deployment chooses its own models, and rate limits and logging have to be configured for each tool."
    solution: "The AI Model accepts only the model in `CHAT_MODEL`, and AI Policies on the {{site.ai_gateway}} apply to every tool that uses it."
  - problem: "LibreChat's OpenAI-compatible client sends its key as `Authorization: Bearer`, while the gateway reads its client keys from another header."
    solution: "A global Pre-Function Policy copies the Bearer token into the `apikey` header that the Key Auth AI Auth Strategy reads."
{% endtable %}

## Try it out

Apply the configuration, send requests with and without the AI Consumer key, then connect LibreChat to Kong and chat through it.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your OpenAI key, a Key Auth AI Auth Strategy, an AI Consumer with an API key, a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy that copies the Bearer token into the `apikey` header, and an AI Model at `/coding-agents`. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the AI Consumer's API key and the model. LibreChat sends this key instead of an OpenAI key. The credential's `api_key` field is write-only, so its value must come from an environment variable. `CHAT_MODEL` is the only model name that the AI Model accepts, and the upstream model that Kong sends to OpenAI:

```bash
export CONSUMER_API_KEY="coding-agents-demo-$(openssl rand -hex 8)"
export CHAT_MODEL='gpt-4o-mini'
```

Apply the Kong configuration. The OpenAI key comes from the prerequisites:

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
    - |
      local auth = kong.request.get_header("Authorization")
      if auth and string.sub(string.lower(auth), 1, 7) == "bearer " then
        ngx.req.set_header("apikey", string.sub(auth, 8))
      end
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

### Send a request through the AI Model

Call Chat Completions through Kong with the AI Consumer key as a Bearer token, the way LibreChat sends it:

```bash
curl -sS -X POST "http://localhost:8000/coding-agents/chat/completions" \
  -H "Authorization: Bearer ${CONSUMER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"${CHAT_MODEL}\", \"messages\": [{\"role\": \"user\", \"content\": \"Reply with exactly: smoke-ok\"}]}"
```

Kong returns OpenAI's Chat Completions response. Your IDs and token counts differ:

```text
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

### Connect LibreChat to Kong

LibreChat connects to OpenAI-compatible APIs through a [custom endpoint](https://www.librechat.ai/docs/quick_start/custom_endpoints) in `librechat.yaml`. LibreChat recommends a custom endpoint over the `OPENAI_REVERSE_PROXY` variable, which its [environment reference](https://www.librechat.ai/docs/configuration/dotenv) marks as deprecated.

Create the LibreChat configuration. The `models.default` value must equal `CHAT_MODEL`. If you exported another model, change it:

```bash
cat <<'EOF' > librechat.yaml
version: 1.3.19
endpoints:
  custom:
    - name: 'Kong'
      apiKey: '${CONSUMER_API_KEY}'
      baseURL: 'http://host.docker.internal:8000/coding-agents'
      models:
        default: ['gpt-4o-mini']
        fetch: false
EOF
```

Create the Compose file. It runs LibreChat and MongoDB, mounts `librechat.yaml` into the LibreChat container, and passes `CONSUMER_API_KEY` from your shell to LibreChat:

```bash
cat <<'EOF' > librechat-compose.yaml
services:
  librechat:
    image: registry.librechat.ai/librechat-ai/librechat-dev:latest
    ports:
      - "3080:3080"
    environment:
      HOST: "0.0.0.0"
      PORT: "3080"
      MONGO_URI: "mongodb://mongo:27017/LibreChat"
      ALLOW_EMAIL_LOGIN: "true"
      ALLOW_REGISTRATION: "true"
      CONSUMER_API_KEY: "${CONSUMER_API_KEY}"
    volumes:
      - ./librechat.yaml:/app/librechat.yaml
    extra_hosts:
      - "host.docker.internal:host-gateway"
    depends_on:
      - mongo
  mongo:
    image: mongo:8.0.20
    volumes:
      - librechat-mongo:/data/db
volumes:
  librechat-mongo:
EOF
```

Start LibreChat in the shell where you exported `CONSUMER_API_KEY`:

```bash
docker compose -f librechat-compose.yaml up -d
```

LibreChat generates its encryption and session secrets (`CREDS_KEY`, `CREDS_IV`, `JWT_SECRET`, and `JWT_REFRESH_SECRET`) when they're blank ([LibreChat environment reference](https://www.librechat.ai/docs/configuration/dotenv)). In production, set fixed values.

### Send a prompt from LibreChat

Open `http://localhost:3080`, register an account, and sign in. Select the **Kong** endpoint and the `gpt-4o-mini` model, then send:

```text
Reply with exactly: librechat-ok
```
{:.no-copy-code}

LibreChat shows the reply `librechat-ok`.

### Check the results

The requests confirm the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "AI Consumer authentication with a Bearer token"
    evidence: "The request with `Authorization: Bearer` and the AI Consumer key succeeds. The Pre-Function Policy copied the key into `apikey`, where the Key Auth AI Auth Strategy reads it."
  - behavior: "Authentication before any upstream call"
    evidence: "The request without a key gets `401`. Kong never contacted OpenAI."
  - behavior: "LibreChat chats through Kong"
    evidence: "LibreChat answers through the **Kong** endpoint. The container has no OpenAI key, only `CONSUMER_API_KEY`."
  - behavior: "The OpenAI key stays in Kong"
    evidence: "The AI Model Provider added the OpenAI key to each upstream request."
{% endtable %}

To review the created entities, and per-consumer usage, open the `coding-agents-librechat-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

The LibreChat server sends each chat request to the custom endpoint's base URL on the data plane. Kong copies the Bearer token into `apikey`, authenticates the AI Consumer, checks the model name, and sends the request to OpenAI with the organization's key.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant U as Browser
    participant LC as LibreChat server
    participant K as Kong AI Gateway
    participant O as OpenAI

    U->>LC: Chat message
    LC->>K: POST /coding-agents/chat/completions (Authorization: Bearer key)
    activate K
    K->>K: Global Pre-Function Policy copies the Bearer token to apikey
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: AI Model matches the model name to CHAT_MODEL
    K->>O: Request with the organization's OpenAI key
    activate O
    O-->>K: Chat Completions response
    deactivate O
    K-->>LC: Response
    deactivate K
    LC-->>U: Reply in the chat
{% endmermaid %}
<!-- vale on -->

### LibreChat custom endpoint

LibreChat sends chat requests from its server container, not from the browser. The custom endpoint points it at Kong and gives it the AI Consumer key.

The following settings connect LibreChat to Kong:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`apiKey: '${CONSUMER_API_KEY}'`"
    purpose: "LibreChat reads the AI Consumer key from the container's environment and sends it as an `Authorization: Bearer` header."
  - setting: "`baseURL`"
    purpose: "The AI Model's base URL. LibreChat appends `/chat/completions` to it."
  - setting: "`models.default`"
    purpose: "The models that LibreChat offers for the endpoint. It lists only `CHAT_MODEL`, the one model that the AI Model accepts."
  - setting: "`models.fetch: false`"
    purpose: "LibreChat uses the `default` list and doesn't request a model list from the API."
  - setting: "`extra_hosts` (Compose)"
    purpose: "Maps `host.docker.internal` to your machine, so the LibreChat container reaches the data plane on port `8000`."
{% endtable %}

### Pre-Function Policy

The Key Auth AI Auth Strategy compares the whole value of the header that it reads, so it can't match a key that has a `Bearer ` prefix. The Pre-Function Policy runs Lua code that copies the token into the `apikey` header. A global Pre-Function Policy runs before authentication, while one attached to an AI Model runs after it.

The following settings configure the Pre-Function Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`global: true`"
    purpose: "Applies the policy to every request on the {{site.ai_gateway}}, before the Key Auth AI Auth Strategy runs. Each AI Model that you add to this {{site.ai_gateway}} also accepts Bearer tokens."
  - setting: "`config.rewrite`"
    purpose: "Runs the Lua code in the rewrite phase. The code reads `Authorization`, checks for a `Bearer ` prefix in any letter case, and sets `apikey` to the rest of the value. Requests without a Bearer token stay unchanged and fail authentication with `401`."
{% endtable %}

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use. LibreChat sends one key for all of its users, so each LibreChat user maps to the same AI Consumer.

The following settings configure the Key Auth AI Auth Strategy and the AI Consumer:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`key_names: [apikey]`"
    purpose: "Kong reads the key from the `apikey` header, which the Pre-Function Policy sets."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the key before it forwards the request. The AI Model Provider also replaces `Authorization`, so OpenAI never sees the AI Consumer key."
  - setting: "`credentials[].api_key`"
    purpose: "The AI Consumer's key. The field is write-only, so it takes a `!secret` reference to `CONSUMER_API_KEY`."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### AI Model Provider and AI Model

The AI Model Provider holds the organization's OpenAI key. The AI Model gives LibreChat an OpenAI-compatible base URL at `/coding-agents`, requires the Key Auth AI Auth Strategy, and has one target that uses the AI Model Provider.

The following settings configure the AI Model Provider and the AI Model:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Provider)"
    purpose: "The `Authorization` header with the organization's OpenAI key, from `OPENAI_TOKEN`. Kong adds it to each upstream request, so `OPENAI_TOKEN` includes the `Bearer ` prefix."
  - setting: "`formats: [{type: openai}]`"
    purpose: "The AI Model accepts OpenAI-format requests, which LibreChat's custom endpoint sends."
  - setting: "`capabilities: [generate]`"
    purpose: "The AI Model serves chat completions."
  - setting: "`access.auth_strategies`"
    purpose: "Each request must have a valid AI Consumer key."
  - setting: "`config.route.model`"
    purpose: "Kong reads the `model` field of the request body (`body_param: model`) and selects this AI Model only if the value equals `CHAT_MODEL`. An AI Model accepts one value, so a second model needs a second AI Model."
  - setting: "`targets[].name`"
    purpose: "The upstream model that Kong sends to OpenAI, also `CHAT_MODEL`. Set it to another value to show a different name in LibreChat than the upstream model."
  - setting: "`config.route.paths` and `strip_path: true`"
    purpose: "Kong matches requests under `/coding-agents` and removes the prefix before it forwards the request."
  - setting: "`config.route.methods`"
    purpose: "The AI Model accepts `POST`, `GET`, and `OPTIONS`. Chat Completions requests use `POST`."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so LibreChat and `curl` can call the local data plane on port `8000`."
  - setting: "`config.max_request_body_size: 16777216`"
    purpose: "Accepts request bodies up to 16 MB, instead of the 8 MB default. Each request carries the conversation history."
  - setting: "`config.response_streaming: allow`"
    purpose: "Clients can request streamed responses."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. Conversations can contain sensitive data, so set it to `false` if you only need usage metrics."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key and the OpenAI key in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

## Variations and next steps

You can change or extend this configuration in the following ways:

{% table %}
columns:
  - title: Variation
    key: variation
  - title: How
    key: how
rows:
  - variation: "Let each user enter their own AI Consumer key"
    how: "Set `apiKey` to `user_provided` in `librechat.yaml`, so that [each user enters a key](https://www.librechat.ai/docs/quick_start/custom_endpoints) in the LibreChat UI. Issue one AI Consumer for each user, and Kong attributes usage and revocation to each person instead of the whole deployment."
  - variation: "Offer a second model"
    how: "Add a second AI Model with its own `config.route.model.values` and target, and list both models in `models.default`. The AI Model Provider and AI Auth Strategy don't change."
  - variation: "Add per-consumer token budgets"
    how: "Attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to give each AI Consumer a token budget."
  - variation: "Connect other tools"
    how: "The [Open WebUI](/cookbooks/coding-agents-open-webui/), [OpenCode](/cookbooks/coding-agents-opencode/), and [Qwen Code](/cookbooks/coding-agents-qwen-code/) cookbooks use the same OpenAI-format AI Model and Pre-Function Policy."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration.

Stop LibreChat and MongoDB, remove their data volume, and delete the configuration files:

```bash
docker compose -f librechat-compose.yaml down -v
rm -f librechat-compose.yaml librechat.yaml
```

Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-librechat-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
