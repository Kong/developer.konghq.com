---
title: "AI Tool Integration: Codex CLI"
description: Route Codex CLI's Responses API traffic through a passthrough AI Model in {{site.ai_gateway_name}}, so developers authenticate with a revocable AI Consumer key and the OpenAI API key stays in Kong.
url: "/cookbooks/coding-agents-codex/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
works_on:
  - konnect
min_version:
  ai-gateway: '2.2'
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
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-codex-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-codex-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: Codex CLI
      content: |
        This tutorial uses [Codex CLI](https://learn.chatgpt.com/docs/cli) 0.134.0 or later, which reads [profile files](https://learn.chatgpt.com/docs/config-file/config-advanced#profiles).

        1. Install Codex CLI from the [Codex CLI documentation](https://learn.chatgpt.com/docs/cli).
        1. Verify that it's installed:

           ```bash
           codex --version
           ```
    - title: AI Credentials
      content: |
        The AI Model Provider uses your organization's OpenAI API key.

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key with the `Bearer` prefix, because Kong sends the whole value as the `Authorization` header:

           ```bash
           export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
overview: |
  Put {{site.ai_gateway_name}} between Codex CLI and the OpenAI API, so that developers hold a Kong key that you can revoke instead of an OpenAI API key. You'll set up:

  * An OpenAI API key that stays in Kong and never reaches developer machines
  * An AI Consumer key for each developer, checked on each request
  * A passthrough endpoint for the Responses API, which Codex requires
---

## What this cookbook solves

Most teams give each developer an OpenAI API key for Codex, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Each laptop holds a key that bills the organization's OpenAI account. A leaked key works from anywhere, and removing one developer's access means finding and revoking the right key."
    solution: "The AI Model Provider keeps the OpenAI API key in Kong and adds it to each upstream request. Developers hold only an AI Consumer key."
  - problem: "Nothing between Codex and OpenAI identifies the developer, so usage attribution, revocation, and request logging need a separate solution on each machine or in the provider console."
    solution: "The Key Auth AI Auth Strategy maps each key to an AI Consumer and rejects unknown keys with `401` before any upstream call. Deleting the AI Consumer credential revokes one developer."
  - problem: "Codex speaks only the Responses API. OpenAI's [gateway compatibility requirements](https://learn.chatgpt.com/docs/enterprise/gateway-compatibility) say that a working Chat Completions endpoint doesn't establish Responses compatibility, and that the gateway must stream events without buffering or changing them."
    solution: "The AI Model uses the `passthrough` format, so Kong forwards `POST /v1/responses` and the streamed events to OpenAI and back unchanged."
  - problem: "Codex sends its API key as `Authorization: Bearer`, but a key-based gateway reads the key from a named header."
    solution: "A global Pre-Function Policy moves the Bearer token to the `apikey` header that the Key Auth AI Auth Strategy reads."
{% endtable %}

## Try it out

Apply the configuration, connect Codex CLI to Kong, then send requests with and without the AI Consumer key and run a prompt from Codex.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your OpenAI API key, a Key Auth AI Auth Strategy, an AI Consumer with an API key, a global Pre-Function Policy that moves a Bearer token to the `apikey` header, and a passthrough AI Model on `/coding-agents-responses`. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Generate the AI Consumer's API key. Codex sends this key to Kong instead of an OpenAI key. The credential's `api_key` field is write-only, so its value must come from an environment variable:

```bash
export CONSUMER_API_KEY="coding-agents-demo-$(openssl rand -hex 8)"
```

Apply the configuration. The OpenAI credentials come from the prerequisites:

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
    - |
      local auth = kong.request.get_header("Authorization")
      if auth and string.sub(string.lower(auth), 1, 7) == "bearer " then
        ngx.req.set_header("apikey", string.sub(auth, 8))
      end
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

### Connect Codex CLI to Kong

Codex reaches a gateway through a [custom model provider](https://learn.chatgpt.com/docs/config-file/config-advanced). Put the provider in a profile file, so that your default Codex configuration doesn't change. Codex reads `model_provider` and `model_providers` only from user-level files, not from a project's `.codex/config.toml`.

Create the profile file:

```bash
mkdir -p ~/.codex
cat <<'EOF' > ~/.codex/kong.config.toml
model = "gpt-4o-mini"
model_provider = "kong"

[model_providers.kong]
name = "Kong AI Gateway"
base_url = "http://localhost:8000/coding-agents-responses/v1"
env_key = "CODEX_API_KEY"
wire_api = "responses"
EOF
```

The profile sets the following values:

* `model` is the model that Codex requests. Kong passes it to OpenAI unchanged, so use a model that your OpenAI account can access.
* `base_url` includes the `/v1` API path, as OpenAI's [gateway guide](https://learn.chatgpt.com/docs/enterprise/connect-to-a-gateway) shows. Codex adds `/responses` to it.
* `env_key` names the environment variable that holds the API key. Codex sends its value in the `Authorization` header as a Bearer token.
* `wire_api = "responses"` selects the Responses API, the only value that Codex supports.

Export the AI Consumer key under the name in `env_key`:

```bash
export CODEX_API_KEY="${CONSUMER_API_KEY}"
```

### Send a request through the AI Model

Call the Responses API through Kong with the AI Consumer key as a Bearer token, the way Codex sends it:

```bash
curl -sS -X POST "http://localhost:8000/coding-agents-responses/v1/responses" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${CONSUMER_API_KEY}" \
  -d '{
    "model": "gpt-4o-mini",
    "input": "Reply with exactly: smoke-ok"
  }'
```

Kong returns OpenAI's Responses API response unchanged. The response looks similar to the following shortened example, with different IDs and token counts:

```text
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

Send the same request without the `Authorization` header:

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

Run a one-shot prompt with the `kong` profile from [Connect Codex CLI to Kong](#connect-codex-cli-to-kong). The `--skip-git-repo-check` flag lets Codex run outside a Git repository:

```bash
codex exec --profile kong --skip-git-repo-check "Reply with exactly: codex-ok"
```

Codex prints `codex-ok` as the final response. Codex can also warn that it has no model metadata for `gpt-4o-mini` and uses fallback metadata. The request still goes through Kong.

### Check the results

The requests and the Codex prompt confirm the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Kong holds the OpenAI API key"
    evidence: "The request with only the AI Consumer key gets a Responses API response from OpenAI. No OpenAI key is set on the client."
  - behavior: "Bearer token authentication"
    evidence: "The request with `Authorization: Bearer` succeeds, because the Pre-Function Policy moves the token to the `apikey` header."
  - behavior: "AI Consumer authentication"
    evidence: "The request without a key returns `401`, and OpenAI never receives it."
  - behavior: "Codex works through Kong"
    evidence: "`codex exec --profile kong` prints `codex-ok` through the Responses API endpoint on the AI Model."
{% endtable %}

To review the created entities and per-consumer usage, open the `coding-agents-codex-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Codex sends Responses API requests to Kong with the AI Consumer key as a Bearer token. Kong moves the token to the `apikey` header, validates the key, replaces the `Authorization` header with the organization's OpenAI API key, and forwards the request and the streamed events without changing them.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant CX as Codex CLI
    participant K as Kong AI Gateway
    participant O as OpenAI API

    CX->>K: POST /coding-agents-responses/v1/responses (Authorization: Bearer AI Consumer key)
    activate K
    K->>K: Pre-Function Policy copies the Bearer token to apikey
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: Remove apikey and set Authorization to the OpenAI API key
    K->>O: POST /v1/responses (body unchanged)
    activate O
    O-->>K: Streamed Responses API events
    deactivate O
    K-->>CX: Events, unchanged
    deactivate K
{% endmermaid %}
<!-- vale on -->

### Pre-Function Policy

The Key Auth AI Auth Strategy compares the whole header value, so it can't read a key from an `Authorization: Bearer` header. The [Pre-Function](/ai-gateway/policies/pre-function/) Policy runs Lua that copies the Bearer token to the `apikey` header. The policy is global, because a policy attached to an AI Model runs after authentication, while a global Pre-Function Policy runs before it ([Scopes and authentication](/ai-gateway/entities/ai-policy/#scopes-and-authentication)).

The following settings configure the Pre-Function Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`global: true`"
    purpose: "The policy applies to each request on the {{site.ai_gateway}} and runs before the Key Auth AI Auth Strategy."
  - setting: "`config.rewrite`"
    purpose: "The Lua runs in the `rewrite` phase, before authentication."
  - setting: "`ngx.req.set_header(\"apikey\", ...)`"
    purpose: "Copies the token after the `Bearer ` prefix to the `apikey` header. The prefix check ignores case. The Lua leaves `Authorization` in place, and the AI Model Provider replaces it before the request goes upstream."
{% endtable %}

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header that the Pre-Function Policy fills and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use.

The following settings configure the Key Auth AI Auth Strategy and the AI Consumer:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`key_names: [apikey]`"
    purpose: "Kong reads the AI Consumer key from the `apikey` header. Clients that can send a custom header can send `apikey` directly."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the `apikey` header before it forwards the request."
  - setting: "`credentials[].api_key`"
    purpose: "The AI Consumer's key. The field is write-only, so it takes a `!secret` reference to `CONSUMER_API_KEY`."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### AI Model Provider and AI Model

The AI Model Provider holds the organization's OpenAI API key. The AI Model exposes `/coding-agents-responses`, requires the Key Auth AI Auth Strategy, and has one target that uses the AI Model Provider. An AI Model in the `openai` format serves Chat Completions, not the Responses API that Codex requires, so this AI Model uses the [passthrough format](/ai-gateway/passthrough/), which forwards request and response bodies byte for byte. Passthrough also forwards any path under `/coding-agents-responses`, so each AI Consumer can reach the whole OpenAI API with the organization's key, not only `/v1/responses`.

The following settings configure the AI Model Provider and the AI Model:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth.headers` (AI Model Provider)"
    purpose: "Kong sets the `Authorization` header to `OPENAI_TOKEN` on each upstream request, which replaces the AI Consumer key that Codex sent."
  - setting: "`formats: [{type: passthrough}]`"
    purpose: "Kong forwards bodies without translation. The `passthrough` format can't be combined with other formats and requires {{site.ai_gateway}} 2.2 or later. The AI Model has no model selector, so the `model` that Codex sends reaches OpenAI unchanged. AI Policies that read or change prompt content, for example guardrails, don't work with it."
  - setting: "`config.route.paths` and `strip_path: true`"
    purpose: "Kong matches the `/coding-agents-responses` prefix, removes it, and forwards the rest of the path, for example `/v1/responses`."
  - setting: "`config.route.methods: [POST, GET, OPTIONS]`"
    purpose: "Codex sends `POST` for inference. `GET` lets clients call read endpoints under the same path, for example `GET /v1/models`."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so Codex can call the local data plane at `http://localhost:8000`."
  - setting: "`targets[].config.upstream_url`"
    purpose: "The OpenAI API host with no path, so Kong adds the client's path to it. See [Upstream paths](/ai-gateway/passthrough/#upstream-paths)."
  - setting: "`config.max_request_body_size: 16777216`"
    purpose: "Accepts request bodies up to 16 MB, instead of the 8 MB default. Codex requests carry the conversation, tool definitions, and file contents."
  - setting: "`config.response_streaming: allow`"
    purpose: "Kong passes the streamed events to Codex as they arrive."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. Codex requests contain source code and file contents, so set it to `false` if you only need usage metrics."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key and the OpenAI API key in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

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
    how: "Add an AI Consumer with its own credential for each developer, so that usage and revocation are per person. Distribute each key through your secrets tooling. OpenAI's [Roll out a gateway](https://learn.chatgpt.com/docs/enterprise/roll-out-a-gateway) guide covers distributing the Codex configuration."
  - variation: "Send the key in the apikey header"
    how: "Replace `env_key` with `env_http_headers = { \"apikey\" = \"CODEX_API_KEY\" }` in the profile ([custom authentication header](https://learn.chatgpt.com/docs/enterprise/connect-to-a-gateway)). Codex then sends the key in the header that the Key Auth AI Auth Strategy reads, and you can remove the Pre-Function Policy."
  - variation: "Restrict the exposed API"
    how: "Remove `GET` from `config.route.methods`, or set `upstream_url` to `https://api.openai.com/v1/responses` so that Kong sends every request to that endpoint and ignores the client's path. See [Upstream paths](/ai-gateway/passthrough/#upstream-paths)."
  - variation: "Connect Chat Completions tools"
    how: "For tools that speak Chat Completions, use an AI Model with `formats: [{type: openai}]`, which can route to any provider. The [Cursor cookbook](/cookbooks/coding-agents-cursor/) shows this setup."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-codex-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

Remove the Codex profile and the AI Consumer key:

```bash
rm -f ~/.codex/kong.config.toml
unset CODEX_API_KEY CONSUMER_API_KEY
```
