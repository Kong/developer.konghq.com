---
title: "AI Tool Integration: Cursor"
description: Route Cursor chat requests through {{site.ai_gateway_name}}, so developers use revocable AI Consumer keys and the OpenAI key stays in Kong.
url: "/cookbooks/coding-agents-cursor/"
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
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-cursor-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-cursor-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
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
    - title: Cursor
      content: |
        This tutorial uses the [Cursor](https://cursor.com/downloads) editor. Install it from the [downloads page](https://cursor.com/downloads).
    - title: ngrok
      content: |
        Cursor sends chat requests from its own servers, not from your machine, so the local data plane needs a public URL. This tutorial uses an [ngrok](https://ngrok.com/docs/share-localhost/quickstart) tunnel for that URL.

        1. [Create an ngrok account](https://dashboard.ngrok.com/signup).
        1. Install the ngrok agent from the [download page](https://ngrok.com/download).
        1. Copy your [authtoken](https://dashboard.ngrok.com/get-started/your-authtoken) and connect the agent to your account:

           ```bash
           ngrok config add-authtoken 'YOUR_NGROK_AUTHTOKEN'
           ```
overview: |
  Put {{site.ai_gateway_name}} between Cursor and OpenAI, so that developers use AI Consumer keys that you can revoke and the organization's OpenAI key never leaves Kong. You'll set up:

  * A `/coding-agents` endpoint that accepts Cursor's OpenAI-format chat requests and its `Authorization: Bearer` key
  * An AI Consumer key for Cursor instead of a provider key on each developer machine
  * A public URL for the local data plane, so that Cursor's servers can reach it

  This cookbook covers Cursor chat models. Cursor's Tab completion keeps using Cursor's built-in models and doesn't go through Kong.
---

## What this cookbook solves

Cursor can call chat models with your own OpenAI API key, and most teams then paste a shared organization key into each developer's editor, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Each developer machine holds a key that bills the organization's account. A leaked key works anywhere, and removing one developer means rotating the key for everyone."
    solution: "The AI Model Provider keeps the OpenAI key in Kong. Each developer gets an AI Consumer key, and deleting that credential removes only that developer's access."
  - problem: "The key leaves the machine with each request. [Cursor's documentation](https://cursor.com/help/models-and-usage/api-keys) says that own-key requests go through Cursor's servers for final prompt building, so the key travels to them each time."
    solution: "Cursor sends only the AI Consumer key. The AI Model Provider replaces it with the organization's key inside Kong, so the provider key never reaches Cursor."
  - problem: "When several developers share one key, the provider bill shows one line item, with no way to see who used which model."
    solution: "The Key Auth AI Auth Strategy maps each key to an AI Consumer, so {{site.konnect_short_name}} analytics show usage for each AI Consumer."
  - problem: "Developers can select any model that the key can reach, and logging, budgets, and rate limits have to be set up for each provider account."
    solution: "The AI Model accepts only the model in `CHAT_MODEL`, and AI Policies on the {{site.ai_gateway}} apply to all Cursor traffic in one place."
{% endtable %}

## Try it out

Apply the configuration, put the data plane on a public URL, connect Cursor to Kong, then send requests with and without the AI Consumer key and a prompt from Cursor.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your OpenAI key, a Key Auth AI Auth Strategy, an AI Consumer with an API key, a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy that copies the Bearer token into the `apikey` header, and an AI Model at `/coding-agents`. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the AI Consumer's API key and the model. Cursor sends this key instead of an OpenAI key. The credential's `api_key` field is write-only, so its value must come from an environment variable. `CHAT_MODEL` is the only model name that the AI Model accepts, and the upstream model that Kong sends to OpenAI:

```bash
export CONSUMER_API_KEY="coding-agents-demo-$(openssl rand -hex 8)"
export CHAT_MODEL='gpt-4o-mini'
```

Apply the Kong configuration. The OpenAI key comes from the prerequisites:

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

### Put the data plane on a public URL

Cursor's servers call the base URL that you set in Cursor, so `localhost` doesn't work. Start an ngrok tunnel to the data plane proxy on port `8000` in a separate terminal and keep it running:

```bash
ngrok http 8000
```

ngrok prints a forwarding URL on your account's dev domain, for example `https://your-assigned-name.ngrok-free.dev`. Export it in the terminal where you run the rest of this cookbook:

```bash
export KONG_PUBLIC_URL='https://your-assigned-name.ngrok-free.dev'
```

{:.warning}
> The tunnel makes every route on the data plane reachable from the internet. The Key Auth AI Auth Strategy rejects requests to `/coding-agents` without a valid AI Consumer key, but anyone who has the key can use the organization's OpenAI account through the URL. Stop the tunnel when you finish, and don't add routes without authentication to this {{site.ai_gateway}} while it runs.

### Send a request through the public URL

Call Chat Completions through the tunnel with the AI Consumer key as a Bearer token, the way Cursor sends it:

```bash
curl -sS -X POST "${KONG_PUBLIC_URL}/coding-agents/chat/completions" \
  -H "Authorization: Bearer ${CONSUMER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"${CHAT_MODEL}\", \"messages\": [{\"role\": \"user\", \"content\": \"Reply with exactly: cursor-ok\"}]}"
```

Kong returns an OpenAI Chat Completions response. Your IDs and token counts differ:

```text
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

Repeat the request without the `Authorization` header:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' -X POST "${KONG_PUBLIC_URL}/coding-agents/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"${CHAT_MODEL}\", \"messages\": [{\"role\": \"user\", \"content\": \"hi\"}]}"
```

Kong rejects the request before it reaches OpenAI:

```text
401
```
{:.no-copy-code}

### Connect Cursor to Kong

In Cursor's **Models** settings, the OpenAI provider has an **API Key** field, a **Use API Key** switch that appears after you save a key, and a switch that overrides the base URL ([Cursor release notes](https://cursor.com/docs/release-notes)). Print the two values that Cursor needs:

```bash
echo "API key:  ${CONSUMER_API_KEY}"
echo "Base URL: ${KONG_PUBLIC_URL}/coding-agents"
```

Configure Cursor:

1. Open **Cursor Settings** > **Models**.
1. Paste the API key into the OpenAI **API Key** field, and turn on **Use API Key**.
1. Turn on the OpenAI base URL override, and paste the base URL into its field. Include the `/coding-agents` path, because the AI Model matches requests on that path.
1. In the chat model picker, select a model named exactly the value of `CHAT_MODEL`. If the picker doesn't list it, add a model with that name in **Cursor Settings** > **Models**. The AI Model accepts only that name.

[Own API keys work only with chat models](https://cursor.com/help/models-and-usage/api-keys), so Tab completion keeps using Cursor's built-in models.

### Send a prompt from Cursor

Send a chat prompt from Cursor with the `CHAT_MODEL` model selected:

```text
Reply with exactly: cursor-ok
```
{:.no-copy-code}

Cursor replies with `cursor-ok`. To see the request that Cursor's servers sent, open the ngrok [web inspection interface](https://ngrok.com/docs/gateway/agent/web-inspection-interface) at `http://localhost:4040`. It lists `POST /coding-agents/chat/completions`.

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
  - behavior: "Cursor reaches Kong through the public URL"
    evidence: "Cursor answers with `cursor-ok`, and the ngrok web inspection interface shows the request from Cursor's servers."
  - behavior: "The OpenAI key stays in Kong"
    evidence: "Cursor and the `curl` requests only held the AI Consumer key. The AI Model Provider added the OpenAI key to each upstream request."
{% endtable %}

To review the created entities, and per-consumer usage, open the `coding-agents-cursor-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Cursor's servers send each chat request to the ngrok URL, and ngrok forwards it to the data plane. Kong copies the Bearer token into `apikey`, authenticates the AI Consumer, checks the model name, and sends the request to OpenAI with the organization's key.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Cursor
    participant CS as Cursor servers
    participant N as ngrok tunnel
    participant K as Kong AI Gateway
    participant O as OpenAI

    C->>CS: Chat request with the AI Consumer key
    CS->>N: POST /coding-agents/chat/completions (Authorization: Bearer key)
    N->>K: Forwarded request on port 8000
    activate K
    K->>K: Global Pre-Function Policy copies the Bearer token to apikey
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: AI Model matches the model name to CHAT_MODEL
    K->>O: Request with the organization's OpenAI key
    activate O
    O-->>K: Chat Completions response
    deactivate O
    K-->>N: Response
    deactivate K
    N-->>CS: Response
    CS-->>C: Reply in the chat
{% endmermaid %}
<!-- vale on -->

### Pre-Function Policy

Cursor sends the API key as `Authorization: Bearer <key>`. The Key Auth AI Auth Strategy compares the whole value of the header that it reads, so it can't match a key that has a `Bearer ` prefix. The Pre-Function Policy runs Lua code that copies the token into the `apikey` header. A global Pre-Function Policy runs before authentication, while one attached to an AI Model runs after it.

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

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use.

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

The AI Model Provider holds the organization's OpenAI key. The AI Model gives Cursor an OpenAI-compatible base URL at `/coding-agents`, requires the Key Auth AI Auth Strategy, and has one target that uses the AI Model Provider.

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
    purpose: "The AI Model accepts OpenAI-format requests, which is the format that Cursor sends to an overridden OpenAI base URL."
  - setting: "`capabilities: [generate]`"
    purpose: "The AI Model serves chat completions."
  - setting: "`access.auth_strategies`"
    purpose: "Each request must have a valid AI Consumer key."
  - setting: "`config.route.model`"
    purpose: "Kong reads the `model` field of the request body (`body_param: model`) and selects this AI Model only if the value equals `CHAT_MODEL`. An AI Model accepts one value."
  - setting: "`targets[].name`"
    purpose: "The upstream model that Kong sends to OpenAI, also `CHAT_MODEL`. Set it to another value to keep the name that developers select while you change the upstream model."
  - setting: "`config.route.paths` and `strip_path: true`"
    purpose: "Kong matches requests under `/coding-agents` and removes the prefix before it forwards the request."
  - setting: "`config.route.methods`"
    purpose: "The AI Model accepts `POST`, `GET`, and `OPTIONS`. Chat Completions requests use `POST`."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so the tunnel and `curl` can call the local data plane on port `8000`."
  - setting: "`config.max_request_body_size: 16777216`"
    purpose: "Accepts request bodies up to 16 MB, instead of the 8 MB default. Coding requests carry conversation history and file contents."
  - setting: "`config.response_streaming: allow`"
    purpose: "Clients can request streamed responses."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. Cursor requests contain source code, so set it to `false` if you only need usage metrics."
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
  - variation: "Issue one AI Consumer for each developer"
    how: "Add an AI Consumer and a credential for each developer, so that usage and revocation are per person. Distribute each key through your secrets tooling."
  - variation: "Change the upstream model"
    how: "Set `targets[].name` to a different model than `config.route.model.values` and re-apply. Developers keep selecting the same model name in Cursor."
  - variation: "Add per-consumer token budgets"
    how: "Attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to give each AI Consumer a token budget. The [GitHub Copilot BYOK cookbook](/cookbooks/github-copilot-byok/) shows a token budget with the same Bearer-to-`apikey` pattern."
  - variation: "Use a stable public URL"
    how: "The ngrok dev domain stays the same when you restart the agent. For production, run the data plane on a host with its own public DNS name and TLS certificate instead of a tunnel, and set the Cursor base URL to it."
  - variation: "Connect other tools"
    how: "The [OpenCode](/cookbooks/coding-agents-opencode/) and [LibreChat](/cookbooks/coding-agents-librechat/) cookbooks use the same OpenAI-format AI Model and Pre-Function Policy."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration.

Stop the ngrok tunnel with `Ctrl+C` in its terminal. In **Cursor Settings** > **Models**, turn off the OpenAI base URL override and **Use API Key**, clear the OpenAI **API Key** field, and remove the model that you added, if any.

Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-cursor-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
