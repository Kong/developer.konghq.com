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
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-qwen-code-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-qwen-code-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: Qwen Code
      content: |
        This tutorial uses [Qwen Code](https://github.com/QwenLM/qwen-code), a terminal coding agent.

        1. Install Qwen Code with npm, which requires Node.js 22 or later, or with another method from the [Qwen Code quickstart](https://qwenlm.github.io/qwen-code-docs/en/users/quickstart/):

           ```bash
           npm install -g @qwen-code/qwen-code@latest
           ```

        1. Verify it's installed:

           ```bash
           qwen --version
           ```
    - title: AI Credentials
      content: |
        Pick the provider you want to route to and export its credentials. The provider's tab in [Apply the Kong configuration](#apply-the-kong-configuration) reads these variables.

        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key:

           ```sh
           export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
        {% endnavtab %}
        {% endnavtabs %}
overview: |
  Put {{site.ai_gateway_name}} between Qwen Code and OpenAI, so that the organization's OpenAI key stays in Kong and each developer authenticates with their own key that you can revoke. You'll set up:

  * Qwen Code command-line flags that send an AI Consumer key to Kong
  * A global Pre-Function Policy that lets the Key Auth AI Auth Strategy read the key from a Bearer token
  * An AI Model that accepts one model name, so the team uses the model that the organization chose
---

## What this cookbook solves

Most teams let each developer configure Qwen Code with a shared provider API key, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Each developer keeps the key in a shell export, a `.qwen/.env` file, or `settings.json`, which [Qwen Code's docs](https://qwenlm.github.io/qwen-code-docs/en/users/configuration/auth/) say can be shared or synced. Each laptop holds a credential that bills the organization's account, and a leaked key works anywhere."
    solution: "The AI Model Provider keeps the OpenAI key in Kong. Each developer holds only an AI Consumer key, and Kong sends the OpenAI key upstream."
  - problem: "The Qwen Code `/auth` menu offers Qwen accounts, built-in third-party providers, and custom endpoints, so usage spreads across consoles and personal accounts, and nobody can see which developer used how many tokens."
    solution: "The Key Auth AI Auth Strategy authenticates each developer as an AI Consumer. Kong rejects a missing or unknown key with `401` before any upstream call, and deleting one credential removes one developer's access."
  - problem: "Qwen Code's OpenAI-compatible protocol uses the [official OpenAI Node.js SDK](https://qwenlm.github.io/qwen-code-docs/en/users/configuration/model-providers/), which sends the API key as `Authorization: Bearer <key>`, so a gateway in front of it has to accept that header."
    solution: "A global Pre-Function Policy copies the Bearer token into the `apikey` header before authentication, so developers change only a base URL and a key."
  - problem: "Switching the team to another model means changing each developer's environment or settings file."
    solution: "The AI Model accepts one model name, `CHAT_MODEL`, and its target decides the upstream model. You change the model in Kong, not on each laptop."
{% endtable %}

## Try it out

Apply the configuration, connect Qwen Code to Kong, then send requests with and without the AI Consumer key and run a prompt from Qwen Code.

### Apply the Kong configuration

The configuration creates an AI Model Provider with the organization's OpenAI key, a Key Auth AI Auth Strategy, an AI Consumer with an API key, a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy that copies the Bearer token into the `apikey` header, and an AI Model on `/coding-agents`. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Generate the AI Consumer's API key. Qwen Code sends this key to Kong instead of an OpenAI key. The credential's `api_key` field is write-only, so its value must come from an environment variable:

```bash
export CONSUMER_API_KEY="coding-agents-demo-$(openssl rand -hex 8)"
```

Select your provider. The tab exports `CHAT_MODEL`, the only model name that the AI Model accepts and the model that Kong requests from OpenAI, then applies the configuration. Provider credentials come from the prerequisites.

{% navtabs "Providers" %}
{% navtab "OpenAI" %}

Export the model env var:

```bash
export CHAT_MODEL='gpt-4o-mini'
```

Apply the Kong configuration:

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

{% endnavtab %}
{% endnavtabs %}

### Connect Qwen Code to Kong

Qwen Code takes its OpenAI-compatible settings from command-line flags, which take precedence over environment variables and settings files ([Qwen Code authentication](https://qwenlm.github.io/qwen-code-docs/en/users/configuration/auth/)). This cookbook passes the settings as flags, so nothing persists in your shell profile or `~/.qwen/settings.json`. The prompt in [Run a prompt from Qwen Code](#run-a-prompt-from-qwen-code) uses these flags:

* `--auth-type openai` selects the OpenAI-compatible protocol.
* `--openai-base-url` is the AI Model path, `http://localhost:8000/coding-agents`. Qwen Code adds `/chat/completions` to it.
* `--openai-api-key` is the AI Consumer key from `CONSUMER_API_KEY`.
* `--model` is the model name, from `CHAT_MODEL`. The AI Model accepts only that name.

To configure Qwen Code once instead of in each command, set the `OPENAI_BASE_URL`, `OPENAI_API_KEY`, and `OPENAI_MODEL` environment variables, or add a provider entry to `~/.qwen/settings.json` ([Qwen Code model providers](https://qwenlm.github.io/qwen-code-docs/en/users/configuration/model-providers/)).

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

The response is an OpenAI Chat Completions object, with different IDs and token counts:

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

### Send a request without the AI Consumer key

Send the same request without the `Authorization` header:

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

### Run a prompt from Qwen Code

Run a one-shot prompt in [headless mode](https://qwenlm.github.io/qwen-code-docs/en/users/features/headless/) with the flags from [Connect Qwen Code to Kong](#connect-qwen-code-to-kong):

```bash
qwen --prompt "Reply with exactly: qwen-ok" \
  --auth-type openai \
  --openai-base-url 'http://localhost:8000/coding-agents' \
  --openai-api-key "${CONSUMER_API_KEY}" \
  --model "${CHAT_MODEL}"
```

Qwen Code prints `qwen-ok`.

### Check the results

The requests and the Qwen Code prompt confirm the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "AI Consumer authentication with a Bearer token"
    evidence: "The request with `Authorization: Bearer` and the AI Consumer key returns a completion. The Pre-Function Policy copied the token into `apikey`, and the Key Auth AI Auth Strategy matched it to `coding-agents-consumer`."
  - behavior: "Authentication before any upstream call"
    evidence: "The request without a key gets `401`. Kong never contacted OpenAI."
  - behavior: "Qwen Code through Kong"
    evidence: "The `qwen` prompt prints `qwen-ok`. Qwen Code sent the `CHAT_MODEL` name, which the AI Model accepts."
  - behavior: "Provider credentials stay in Kong"
    evidence: "Qwen Code only held the AI Consumer key. The AI Model Provider added the OpenAI key to each upstream request."
{% endtable %}

To review the created entities, and per-consumer usage, open the `coding-agents-qwen-code-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Qwen Code sends each request to Kong with the AI Consumer key as a Bearer token. Kong copies the Bearer token into the `apikey` header, authenticates the AI Consumer, selects the AI Model that matches the model name, and forwards the request to OpenAI with the organization's key.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant Q as Qwen Code
    participant K as Kong AI Gateway
    participant O as OpenAI

    Q->>K: POST /coding-agents/chat/completions (Authorization: Bearer AI Consumer key)
    activate K
    K->>K: Global Pre-Function Policy copies the Bearer token into apikey
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: Select the AI Model whose model value matches the request
    K->>K: AI Model Provider adds the organization's OpenAI key
    K->>O: Chat Completions request
    activate O
    O-->>K: Response, streamed when requested
    deactivate O
    K-->>Q: OpenAI-format response
    deactivate K
{% endmermaid %}
<!-- vale on -->

### Pre-Function Policy

The Key Auth AI Auth Strategy reads the AI Consumer key from the `apikey` header and compares the whole header value, so it can't read a key from `Authorization: Bearer <key>`. The Pre-Function Policy runs Lua code that copies the token into `apikey` before authentication. It's global, because a policy attached to an AI Model runs only after authentication succeeds, while a global policy with a higher priority than the AI Auth Strategy runs before it ([AI Policy scopes and authentication](/ai-gateway/entities/ai-policy/#scopes-and-authentication)).

The following settings configure the Pre-Function Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`global: true`"
    purpose: "Applies the policy to all traffic on the {{site.ai_gateway}}, so it runs before the Key Auth AI Auth Strategy. Each AI Model on this {{site.ai_gateway}} that uses a Key Auth AI Auth Strategy with the `apikey` header also accepts Bearer tokens."
  - setting: "`config.rewrite`"
    purpose: "Runs the Lua code in the `rewrite` phase. The [Pre-Function Policy reference](/ai-gateway/policies/pre-function/) lists the other phases."
  - setting: "Lua code"
    purpose: "Compares the first seven characters of `Authorization` with `bearer `, without regard to case, and sets `apikey` to the rest of the value. A request without a Bearer token passes unchanged, and the Key Auth AI Auth Strategy rejects it. `kong.request.get_header` and `ngx.req.set_header` are in the strict [sandbox](/ai-gateway/sandboxing/) allowlist."
{% endtable %}

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header that the Pre-Function Policy set and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use.

The following settings configure the Key Auth AI Auth Strategy and the AI Consumer:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`key_names: [apikey]`"
    purpose: "Kong reads the key from the `apikey` header, which the Pre-Function Policy fills from the Bearer token."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the key before it forwards the request. OpenAI never sees the AI Consumer key."
  - setting: "`credentials[].api_key`"
    purpose: "The AI Consumer's key. The field is write-only, so it takes a `!secret` reference to `CONSUMER_API_KEY`."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### AI Model Provider and AI Model

The AI Model Provider holds the organization's OpenAI key. The AI Model exposes `/coding-agents`, accepts OpenAI-format requests whose `model` field equals `CHAT_MODEL`, and has one target that uses the AI Model Provider.

The following settings configure the AI Model Provider and the AI Model:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Provider)"
    purpose: "The `Authorization` header with the OpenAI key, from `OPENAI_TOKEN` with its `Bearer ` prefix. Kong adds it to each upstream request, and it takes precedence over the client's `Authorization` header."
  - setting: "`formats: [{type: openai}]`"
    purpose: "The AI Model accepts OpenAI Chat Completions requests, the format that Qwen Code's OpenAI-compatible protocol sends."
  - setting: "`capabilities: [generate]`"
    purpose: "The AI Model serves `/chat/completions` and `/completions`."
  - setting: "`config.route.model`"
    purpose: "Kong reads the `model` field of the request body (`body_param: model`) and selects this AI Model only if the value equals `CHAT_MODEL`. An AI Model accepts one value."
  - setting: "`targets[].name`"
    purpose: "The model that Kong requests from OpenAI, also `CHAT_MODEL`. Set it to another model to change what OpenAI serves without changing developer configuration."
  - setting: "`config.route.paths` and `strip_path: true`"
    purpose: "Qwen Code adds `/chat/completions` to the base URL. Kong matches `/coding-agents` and removes it before it forwards the request."
  - setting: "`config.route.methods`"
    purpose: "Qwen Code sends requests with `POST`. The AI Model also accepts `GET` and `OPTIONS` on the same path."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so Qwen Code can call the local data plane at `http://localhost:8000`."
  - setting: "`config.max_request_body_size: 16777216`"
    purpose: "Accepts request bodies up to 16 MB, instead of the 8 MB default. Coding agent requests carry the conversation, tool definitions, and file contents."
  - setting: "`config.response_streaming: allow`"
    purpose: "Kong passes streamed responses to Qwen Code."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. Qwen Code requests contain source code, so set it to `false` if you only need usage metrics. The default is `false`."
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
  - variation: "Give each developer their own key"
    how: "Add an AI Consumer and credential for each developer. Have each developer keep their key in a [`.qwen/.env` file](https://qwenlm.github.io/qwen-code-docs/en/users/configuration/auth/), not in a shared or synced `settings.json`. The AI Model and AI Model Provider don't change."
  - variation: "Change the upstream model"
    how: "Set `targets[].name` to another model, or point the target at another AI Model Provider, and re-apply. Developers keep sending the same model name."
  - variation: "Offer more models"
    how: "Add one AI Model for each model name on the same `/coding-agents` path, each with its own `config.route.model.values`. See the [Basic LLM routing cookbook](/cookbooks/basic-llm-routing/) for two AI Models on one path."
  - variation: "Add per-consumer token limits"
    how: "Attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to give each AI Consumer its own token budget. The [GitHub Copilot BYOK cookbook](/cookbooks/github-copilot-byok/) shows token budgets for each AI Consumer."
  - variation: "Connect other coding agents"
    how: "The [OpenCode](/cookbooks/coding-agents-opencode/) and [Cursor](/cookbooks/coding-agents-cursor/) cookbooks use the same kind of AI Model."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-qwen-code-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
