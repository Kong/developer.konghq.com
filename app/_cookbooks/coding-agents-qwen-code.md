---
title: "AI Tool Integration: Qwen Code"
description: Point Qwen Code at {{site.ai_gateway_name}} with OpenAI-compatible flags.
url: "/cookbooks/coding-agents-qwen-code/"
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

hint: "Requires Kong AI Gateway 2.2+, an OpenAI API key, and Qwen Code."
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
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-qwen-code-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-qwen-code-recipe`, a local data plane connected to it, and prints `export` lines (including `AI_GATEWAY_ID`). Paste those into your shell when prompted.
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
  Use Qwen Code when you want Alibaba's Qwen CLI pointed at an OpenAI-compatible endpoint.
---

## The problem

[Qwen Code](https://github.com/QwenLM/qwen-code) is a terminal coding agent that talks to OpenAI-compatible, Anthropic, and Gemini APIs. Its [API key setup](https://qwenlm.github.io/qwen-code-docs/en/users/configuration/auth/) works well for one developer with one key, but an organization that wants to give a whole team Qwen Code on a shared provider account runs into several problems:

* **Provider keys end up on laptops.** For an OpenAI-compatible provider, each developer exports `OPENAI_API_KEY`, stores it in a `.qwen/.env` file, or adds it to the `env` block of `~/.qwen/settings.json`. Qwen Code's own docs note that `settings.json` may be shared or synced. Every machine holds a credential that bills the organization's account, a leaked key works anywhere, and offboarding one developer means finding and revoking the right key.
* **Every developer can pick a different backend.** The `/auth` menu offers Qwen accounts, QwenCloud, Alibaba ModelStudio, built-in third-party providers such as OpenRouter and DeepSeek, and custom endpoints. Without a shared entry point, usage spreads across provider consoles and personal accounts, and nobody can see which developer used how many tokens.
* **There is no central place to apply policy.** Budgets, rate limits, request logging, and provider changes all have to be handled per machine or per provider console. Switching the team to a different upstream model means touching every developer's environment or settings file.
* **A gateway has to accept what Qwen Code sends.** Qwen Code's OpenAI-compatible protocol uses the [official OpenAI Node.js SDK](https://github.com/QwenLM/qwen-code/blob/main/docs/users/configuration/model-providers.md), which posts Chat Completions requests to the configured base URL with the key in `Authorization: Bearer <key>`, and puts the configured model name in the body's `model` field. A gateway in front of Qwen Code has to authenticate that Bearer credential and route on that model name.

The root issue is that the credential, the provider choice, and the policy all sit on the client. Teams need one server-side point that holds the organization's provider key, authenticates developers with credentials it can revoke, and accepts Qwen Code's standard OpenAI-compatible requests.

## The solution

This recipe puts {{site.ai_gateway}} between Qwen Code and the OpenAI API:

* **Server-side provider credential.** The organization's OpenAI API key lives on {{site.ai_gateway}}. Developers never see it, and rotating it is one configuration change.
* **Revocable developer credentials.** Each developer gets an AI Consumer API key from Kong. Qwen Code sends that key instead of a provider key, and Kong attributes every request to the matching AI Consumer. Revoking a developer means deleting one AI Consumer credential.
* **Bearer token compatibility.** Kong accepts the AI Consumer key in the `Authorization: Bearer` header that Qwen Code already sends, so developers only change a base URL and a key.
* **One pinned model name.** The AI Model only accepts requests whose `model` field matches the model you choose, so every developer uses the model the organization approved.
* **One place for future policy.** Once traffic flows through Kong, you can add logging, rate limiting, and other AI Policies to the same AI Model without changing anything on developer machines.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant Q as Qwen Code
    participant K as AI Gateway
    participant O as OpenAI API

    Q->>K: POST /coding-agents/chat/completions (Authorization: Bearer AI Consumer key)
    activate K
    K->>K: Pre-Function Policy copies Bearer token into apikey header
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: AI Model matches body model to CHAT_MODEL, AI Model Provider sets org OpenAI key
    K->>O: Chat Completions request (Authorization: org key)
    activate O
    O-->>K: Chat Completions response (streamed)
    deactivate O
    K-->>Q: OpenAI-format response
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
  - component: "Qwen Code"
    responsibility: "Sends OpenAI Chat Completions requests to the configured base URL with the AI Consumer key as a Bearer token."
  - component: "Pre-Function Policy"
    responsibility: "Copies the Bearer token from the `Authorization` header into the `apikey` header that the Key Auth AI Auth Strategy reads."
  - component: "Key Auth AI Auth Strategy"
    responsibility: "Validates the AI Consumer key, attaches the request to the AI Consumer, and removes the `apikey` header before the request goes upstream."
  - component: "AI Consumer"
    responsibility: "Represents one developer. Its API key credential is the only secret the developer holds."
  - component: "AI Model"
    responsibility: "Exposes `/coding-agents`, accepts OpenAI-format requests for the model named in `CHAT_MODEL`, and forwards them to OpenAI."
  - component: "AI Model Provider"
    responsibility: "Holds the organization's OpenAI API key and injects it into every upstream request."
  - component: "OpenAI API"
    responsibility: "Serves the model inference and bills the organization's account."
{% endtable %}

## How it works

When you run a prompt in Qwen Code, the request goes through these steps:

1. **Qwen Code sends the request to Kong.** With the OpenAI base URL set to `http://localhost:8000/coding-agents`, Qwen Code posts Chat Completions requests to `/coding-agents/chat/completions`. The AI Consumer key goes in `Authorization: Bearer <key>`, and the body's `model` field holds the model name you passed to Qwen Code.
1. **Kong moves the Bearer token into `apikey`.** A global Pre-Function Policy runs in the rewrite phase, before authentication. If the `Authorization` header starts with `Bearer `, the policy copies the rest of the header into an `apikey` header.
1. **Kong authenticates the developer.** The AI Model lists the Key Auth AI Auth Strategy in `access.auth_strategies`. The AI Auth Strategy reads `apikey`, matches it against the AI Consumer credentials, and attaches the request to `coding-agents-consumer`. A missing or unknown key returns `401`. With `hide_credentials` enabled, the AI Auth Strategy removes `apikey` before the request goes upstream.
1. **The AI Model matches the model name.** The AI Model reads the body's `model` field and only accepts requests whose value equals `CHAT_MODEL`. Kong strips the `/coding-agents` prefix and sends the request to the target, whose `name` is the model Kong requests from OpenAI.
1. **The AI Model Provider injects the organization's key.** The target references the AI Model Provider, which sets the `Authorization` header to the organization's OpenAI key. OpenAI authenticates the request against that key and bills the organization's account.
1. **The response streams back.** OpenAI streams the response back through Kong to Qwen Code. Kong logs the request against the AI Consumer.

### Pre-Function: Bearer token to apikey

Qwen Code sends its API key as `Authorization: Bearer <key>`, and the Key Auth AI Auth Strategy doesn't strip a `Bearer ` prefix. The Pre-Function Policy bridges that gap: it runs Lua in the rewrite phase, before the Key Auth AI Auth Strategy, and copies the token into the `apikey` header. That addresses the compatibility problem without changing anything in Qwen Code. Developers keep using Qwen Code's standard OpenAI-compatible settings.

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

**`config.rewrite`**: Lua code that runs in the rewrite phase, before authentication. The check is case-insensitive, so `bearer` and `Bearer` both match. Requests without a Bearer token pass through unchanged and fail at the Key Auth AI Auth Strategy.

**`global: true`**: Applies the policy globally to all resources in the {{site.ai_gateway}}, so you don't attach it to the AI Model. Any other AI Model on the same {{site.ai_gateway}} that uses the `apikey` header for Key Auth also accepts Bearer tokens.

**The original `Authorization` header**: The policy copies the token and leaves `Authorization` in place. The AI Model Provider then sets `Authorization` to the organization's key, so OpenAI receives the provider credential rather than the AI Consumer key.

See the [Pre-Function](/ai-gateway/policies/pre-function/) Policy reference for the other phases and options.

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

**`key_names: [apikey]`**: The header Kong reads the AI Consumer key from. Qwen Code doesn't send this header itself. The Pre-Function Policy creates it from the Bearer token.

**`hide_credentials: true`**: Removes `apikey` from the request before Kong forwards it, so the AI Consumer key doesn't reach OpenAI.

**`credentials[].api_key`**: The AI Consumer's key. The field is write-only, so it takes a `!secret` reference rather than a plain string.

**Scaling AI Consumers**: Add one AI Consumer per developer, each with its own credential. The recipe defines one AI Consumer for demonstration.

### AI Model and AI Model Provider: OpenAI Chat Completions with credential injection

The AI Model gives Qwen Code an OpenAI-compatible base URL, and the AI Model Provider supplies the credential OpenAI expects. The AI Model uses the `openai` format with a model selector on the body's `model` field, so it only accepts requests for the model named in `CHAT_MODEL`. That keeps every developer on the model the organization approved, and the upstream model is set on the gateway rather than on each laptop. The AI Model Provider holds the organization's OpenAI key, which addresses the keys-on-laptops problem.

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

**`formats: [{type: openai}]`**: Accepts OpenAI-format requests, which is what Qwen Code's OpenAI-compatible protocol sends.

**`route.model`**: Reads the model name from the request body's `model` field (`body_param: model`). `values` holds one value, `CHAT_MODEL`, so Qwen Code must send exactly that model name. To offer a second model, add a second AI Model with its own selector value.

**`targets[].name`**: The model name Kong sends to OpenAI. The recipe sets it to `CHAT_MODEL` as well, so the name Qwen Code sends and the name OpenAI receives are the same. Set it to a different value to serve a different upstream model under the name developers use.

**`route.paths` and `strip_path: true`**: Qwen Code appends `/chat/completions` to the base URL. Kong matches the `/coding-agents` prefix and strips it before forwarding.

**`route.methods`**: Qwen Code sends `POST` for inference. The route also accepts `GET` and `OPTIONS`.

**`max_request_body_size: 16777216`**: Raises the request body limit to 16 MB from the 8 MB default. Coding agent requests carry the full conversation, tool definitions, and file contents, and long sessions can exceed the default.

**`response_streaming: allow`**: Lets OpenAI stream Server-Sent Events back to Qwen Code.

**`logging.payloads: true`**: Captures full request and response bodies. Qwen Code requests include source code and file contents, so payload logging can expose sensitive data in your logging destination. Set it to `false` if you only need usage metrics.

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. AI Vaults support HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store.

## Apply the Kong configuration

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply command can manage it. The `coding-agents-qwen-code-recipe` namespace scopes every resource, so teardown removes only this recipe's configuration.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Choose the OpenAI model that Qwen Code requests. The AI Model only accepts this exact name:

```bash
export CHAT_MODEL='gpt-4o-mini'
```

The following configuration creates the AI Model Provider with the organization's OpenAI key, the Key Auth AI Auth Strategy, the demo AI Consumer, the global Pre-Function Policy, and the AI Model. `AI_GATEWAY_ID`, `OPENAI_TOKEN`, and `CONSUMER_API_KEY` are already exported from the prerequisites.

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: coding-agents-qwen-code-recipe
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

Send a request directly to confirm the gateway path, send one without a key to see Key Auth reject it, and then run a prompt from Qwen Code pointed at the AI Model.

### Configure Qwen Code

Qwen Code takes its OpenAI-compatible settings from [command-line flags](https://qwenlm.github.io/qwen-code-docs/en/users/configuration/settings/), which take precedence over environment variables and settings files. This recipe passes them on the command line, so nothing persists in your shell or `~/.qwen/settings.json`:

* **`--openai-base-url`**: The AI Model path, `http://localhost:8000/coding-agents`. Qwen Code appends `/chat/completions`.
* **`--openai-api-key`**: The AI Consumer key from `CONSUMER_API_KEY`, which Qwen Code sends as a Bearer token.
* **`--auth-type openai`**: Selects the OpenAI-compatible protocol over Chat Completions.
* **`-m`**: The model name. It must equal `CHAT_MODEL`, or the AI Model doesn't match the request.

To configure Qwen Code once instead of per command, set the equivalent [environment variables](https://qwenlm.github.io/qwen-code-docs/en/users/configuration/auth/) `OPENAI_BASE_URL`, `OPENAI_API_KEY`, and `OPENAI_MODEL`, or define a `modelProviders.openai` entry with a `baseUrl` in `~/.qwen/settings.json`.

### Send a request through the AI Model

Call Chat Completions with the AI Consumer key as a Bearer token, the same way Qwen Code does:

```bash
curl -sS -X POST "http://localhost:8000/coding-agents/chat/completions" \
  -H "Authorization: Bearer ${CONSUMER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"${CHAT_MODEL}\",
    \"messages\": [{\"role\": \"user\", \"content\": \"Reply with exactly: smoke-ok\"}]
  }"
```

Kong returns an OpenAI Chat Completions response. The response looks similar to this, with different IDs, model version, and token counts:

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
    "prompt_tokens": 13,
    "completion_tokens": 3,
    "total_tokens": 16
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

### Send a prompt from Qwen Code

Run a one-shot prompt with the flags from [Configure Qwen Code](#configure-qwen-code):

```bash
qwen -p "Reply with exactly: qwen-ok" -y \
  --openai-base-url 'http://localhost:8000/coding-agents' \
  --openai-api-key "$CONSUMER_API_KEY" \
  --auth-type openai \
  -m "$CHAT_MODEL"
```

`-p` runs Qwen Code in [non-interactive mode](https://github.com/QwenLM/qwen-code/blob/main/docs/users/features/headless.md), and `-y` (`--yolo`) auto-approves tool calls so the prompt doesn't wait for input. YOLO mode doesn't enable a sandbox, so only use it for prompts you trust.

Qwen Code prints `qwen-ok`.

### What happened

1. **The direct request** carried the AI Consumer key as a Bearer token. The Pre-Function Policy copied it into `apikey`, the Key Auth AI Auth Strategy matched it to `coding-agents-consumer` and removed `apikey`, and the AI Model Provider set `Authorization` to the organization's OpenAI key. OpenAI answered with `smoke-ok`.
1. **The request without a key** had no Bearer token, so the Pre-Function Policy set no `apikey` header and the Key Auth AI Auth Strategy returned `401`. Kong never contacted OpenAI, so the organization's key was never used.
1. **The Qwen Code prompt** followed the same path as the direct request. Qwen Code appended `/chat/completions` to the base URL, sent the AI Consumer key as a Bearer token, and set `model` to `CHAT_MODEL`, which matched the AI Model's selector. Qwen Code never had access to the organization's OpenAI key.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `coding-agents-qwen-code-recipe`. The recipe created an AI Model Provider (`coding-agents-openai-provider`) holding the organization's OpenAI key, an AI Model (`coding-agents-openai`) at `/coding-agents`, a Key Auth AI Auth Strategy (`coding-agents-key-auth`), an AI Consumer (`coding-agents-consumer`) with an API key credential, and a global Pre-Function Policy (`coding-agents-bearer-to-apikey`), all scoped to this recipe by the kongctl namespace.

For request, token, and per-AI Consumer analysis across every {{site.ai_gateway}}, open the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

* **Issue one AI Consumer per developer.** Add an AI Consumer and credential for each developer so usage and revocation are per person. Distribute each key through your secrets tooling, and have developers keep it in a [`.qwen/.env` file](https://qwenlm.github.io/qwen-code-docs/en/users/configuration/auth/) rather than in a shared or synced `settings.json`.
* **Add per-developer token budgets.** Attach an [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to the AI Model to cap tokens per AI Consumer. The [GitHub Copilot BYOK recipe](/cookbooks/github-copilot-byok/) shows a per-AI Consumer token budget with the same Bearer-to-`apikey` pattern.
* **Change the upstream model without touching laptops.** Point the AI Model's target at a different model or AI Model Provider. Developers keep sending the same `model` name, and the change takes effect on the next request.
* **Connect other tools to the same pattern.** OpenAI-compatible clients such as [OpenCode](/cookbooks/coding-agents-opencode/) and [Cursor](/cookbooks/coding-agents-cursor/) use the same AI Model, Pre-Function Policy, and Key Auth AI Auth Strategy configuration.
* **Move credentials into a vault.** Use [AI Vaults](/ai-gateway/entities/ai-vault/) to source the OpenAI key and AI Consumer credentials from HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, or the {{site.konnect_short_name}} Config Store.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-qwen-code-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
