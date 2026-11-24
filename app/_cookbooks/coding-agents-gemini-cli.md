---
title: "AI Tool Integration: Gemini CLI"
description: Route Gemini CLI requests through {{site.ai_gateway_name}}, so developers use revocable AI Consumer keys and the Gemini API key stays in Kong.
url: "/cookbooks/coding-agents-gemini-cli/"
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
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped {{site.ai_gateway}} and local data plane. The data plane must run {{site.ai_gateway}} 2.2 or later, because the AI Model uses the `passthrough` format.

        1. Create a new personal access token by opening the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. You reuse the same token later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-gemini-cli-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-gemini-cli-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
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
        The AI Model Provider uses your organization's Google AI Studio API key.

        1. [Get a Gemini API key](https://aistudio.google.com/app/apikey) in Google AI Studio.
        1. Export the API key:

           ```sh
           export GEMINI_TOKEN='YOUR-GEMINI-API-KEY'
           ```
    - title: Gemini CLI
      content: |
        This tutorial uses [Gemini CLI](https://github.com/google-gemini/gemini-cli).

        1. Install Gemini CLI from the [installation guide](https://github.com/google-gemini/gemini-cli/blob/main/docs/get-started/installation.mdx).
        1. Verify that it's installed:

           ```bash
           gemini --version
           ```
overview: |
  Put {{site.ai_gateway_name}} between Gemini CLI and the Gemini API, so that developers use AI Consumer keys that you can revoke and the organization's Gemini API key never leaves Kong. You'll set up:

  * A `/coding-agents-gemini` endpoint that forwards Gemini CLI's native Gemini API requests unchanged
  * An AI Consumer key for Gemini CLI instead of a Google AI Studio key on each developer machine
  * Authentication that rejects requests without a valid AI Consumer key before any call to Google

  This cookbook covers Gemini CLI with Gemini API key authentication, the mode that `GOOGLE_GEMINI_BASE_URL` applies to.
---

## What this cookbook solves

The [Gemini CLI authentication guide](https://github.com/google-gemini/gemini-cli/blob/main/docs/get-started/authentication.mdx) has each developer export a Google AI Studio key as `GEMINI_API_KEY`, and most teams share one organization key this way, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Each developer machine holds a key that bills the organization's account. A leaked key works anywhere, and removing one developer means rotating the key for everyone."
    solution: "The AI Model Provider keeps the Gemini API key in Kong. Each developer gets an AI Consumer key, and deleting that credential removes only that developer's access."
  - problem: "Google's [API key guidance](https://aistudio.google.com/docs/api-key) says to treat the key like a password and to call the API from a backend proxy instead of exposing the key in client applications."
    solution: "Kong is that backend proxy. Gemini CLI sends only the AI Consumer key, and the AI Model Provider adds the organization's key to each upstream request."
  - problem: "When several developers share one key, usage arrives as one total, with no way to see who used which model."
    solution: "The Key Auth AI Auth Strategy maps each key to an AI Consumer, so {{site.konnect_short_name}} analytics show usage for each AI Consumer."
  - problem: "Gemini CLI calls Gemini's native API, not the OpenAI format, so a gateway that translates formats can't sit in front of it."
    solution: "The AI Model uses the `passthrough` format and forwards Gemini CLI's requests and the Gemini API's responses unchanged."
{% endtable %}

## Try it out

Apply the configuration, connect Gemini CLI to Kong, then send requests with and without the AI Consumer key and a prompt from Gemini CLI.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your Gemini API key, a Key Auth AI Auth Strategy, an AI Consumer with an API key, and a passthrough AI Model at `/coding-agents-gemini`. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the AI Consumer's API key. Gemini CLI sends this key instead of a Google AI Studio key. The credential's `api_key` field is write-only, so its value must come from an environment variable:

```bash
export CONSUMER_API_KEY="coding-agents-demo-$(openssl rand -hex 8)"
```

Apply the Kong configuration. The Gemini API key comes from the prerequisites:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: coding-agents-gemini-cli-recipe
ai_gateway_model_providers:
- ref: coding-agents-gemini-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: coding-agents-gemini-provider
  display_name: coding-agents-gemini
  type: gemini
  config:
    auth:
      type: basic
      headers:
      - name: x-goog-api-key
        value: !secret {source: !env 'GEMINI_TOKEN'}
ai_gateway_auth_strategies:
- ref: coding-agents-key-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: coding-agents-key-auth
  display_name: coding-agents key auth
  type: key-auth
  config:
    key_names:
    - x-goog-api-key
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
ai_gateway_models:
- ref: coding-agents-gemini
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: coding-agents-gemini
  display_name: coding-agents (Gemini)
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
      - /coding-agents-gemini
      protocols:
      - http
      - https
      methods:
      - POST
      - GET
      - OPTIONS
      strip_path: true
  targets:
  - name: gemini-api
    provider: coding-agents-gemini-provider
    config:
      type: gemini
      upstream_url: https://generativelanguage.googleapis.com/
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

### Connect Gemini CLI to Kong

Gemini CLI reads its base URL from [`GOOGLE_GEMINI_BASE_URL`](https://github.com/google-gemini/gemini-cli/blob/main/docs/reference/configuration.md#environment-variables-and-env-files) when it uses Gemini API key authentication. The URL must use HTTPS unless it points to `localhost`, so the local data plane's HTTP port works. Set the base URL to the AI Model's path, and put the AI Consumer key in `GEMINI_API_KEY` instead of a Google AI Studio key:

```bash
export GOOGLE_GEMINI_BASE_URL='http://localhost:8000/coding-agents-gemini'
export GEMINI_API_KEY="${CONSUMER_API_KEY}"
```

In headless mode, Gemini CLI reuses a cached authentication method if one exists ([Gemini CLI authentication](https://github.com/google-gemini/gemini-cli/blob/main/docs/get-started/authentication.mdx)). If you signed in to Gemini CLI with a Google account before, run `gemini` once in the same shell and select **Use Gemini API key**.

### Send a request through the AI Model

Call the Gemini API `generateContent` endpoint through Kong with the AI Consumer key in the `x-goog-api-key` header:

```bash
curl -sS -X POST "http://localhost:8000/coding-agents-gemini/v1beta/models/gemini-2.5-flash:generateContent" \
  -H "Content-Type: application/json" \
  -H "x-goog-api-key: ${CONSUMER_API_KEY}" \
  -d '{"contents": [{"role": "user", "parts": [{"text": "Reply with exactly: smoke-ok"}]}]}'
```

Kong returns the Gemini API response unchanged. Your IDs and token counts differ:

```text
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "smoke-ok"
          }
        ],
        "role": "model"
      },
      "finishReason": "STOP",
      "index": 0
    }
  ],
  "usageMetadata": {
    "promptTokenCount": 6,
    "candidatesTokenCount": 3,
    "totalTokenCount": 9
  },
  "modelVersion": "gemini-2.5-flash",
  "responseId": "..."
}
```
{:.no-copy-code}

Repeat the request without `x-goog-api-key`:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' -X POST "http://localhost:8000/coding-agents-gemini/v1beta/models/gemini-2.5-flash:generateContent" \
  -H "Content-Type: application/json" \
  -d '{"contents": [{"role": "user", "parts": [{"text": "hi"}]}]}'
```

Kong rejects the request before it reaches the Gemini API:

```text
401
```
{:.no-copy-code}

### Send a prompt from Gemini CLI

Run a one-shot prompt in the shell where you exported the Gemini CLI variables:

```bash
gemini -p "Reply with exactly: gemini-ok" --skip-trust -m gemini-2.5-flash
```

The flags come from the [Gemini CLI reference](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/cli-reference.md). `-p` runs the prompt in non-interactive mode, `--skip-trust` trusts the current folder for this session so that the folder trust check doesn't stop the run, and `-m` selects the model. Gemini CLI prints:

```text
gemini-ok
```
{:.no-copy-code}

### Check the results

The requests confirm the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "AI Consumer authentication"
    evidence: "The request with the AI Consumer key in `x-goog-api-key` succeeds. Kong matched the key to the `coding-agents-consumer` AI Consumer."
  - behavior: "Authentication before any upstream call"
    evidence: "The request without a key gets `401`. Kong never contacted the Gemini API."
  - behavior: "Native Gemini API forwarding"
    evidence: "The response has the Gemini API's own shape (`candidates`, `usageMetadata`), and Gemini CLI works with no change other than its base URL and key."
  - behavior: "The Gemini API key stays in Kong"
    evidence: "Gemini CLI and the `curl` requests only held the AI Consumer key. The AI Model Provider added the organization's key to each upstream request."
{% endtable %}

To review the created entities, and per-consumer usage, open the `coding-agents-gemini-cli-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Gemini CLI sends native Gemini API requests to `GOOGLE_GEMINI_BASE_URL`, with the AI Consumer key in `x-goog-api-key`. Kong authenticates the AI Consumer, removes the prefix `/coding-agents-gemini` from the path, and forwards the request unchanged to the Gemini API with the organization's key.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant G as Gemini CLI
    participant K as Kong AI Gateway
    participant API as Gemini API

    G->>K: POST /coding-agents-gemini/v1beta/models/MODEL:streamGenerateContent (x-goog-api-key AI Consumer key)
    activate K
    K->>K: Key Auth AI Auth Strategy validates x-goog-api-key (else 401)
    K->>K: AI Model Provider sets x-goog-api-key to the organization's key
    K->>API: POST /v1beta/models/MODEL:streamGenerateContent (unchanged body)
    activate API
    API-->>K: Gemini API response
    deactivate API
    K-->>G: Unchanged response
    deactivate K
{% endmermaid %}
<!-- vale on -->

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Gemini API reads API keys from the `x-goog-api-key` header ([Gemini API key documentation](https://aistudio.google.com/docs/api-key)), so the Key Auth AI Auth Strategy reads the AI Consumer key from the same header. No header rewrite is needed. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use.

The following settings configure the Key Auth AI Auth Strategy and the AI Consumer:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`key_names: [x-goog-api-key]`"
    purpose: "Kong reads the AI Consumer key from the `x-goog-api-key` header."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the AI Consumer key before it forwards the request. The AI Model Provider then sets `x-goog-api-key` to the organization's key."
  - setting: "`credentials[].api_key`"
    purpose: "The AI Consumer's key. The field is write-only, so it takes a `!secret` reference to `CONSUMER_API_KEY`."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### AI Model Provider and AI Model

The AI Model Provider holds the organization's Gemini API key. The AI Model uses the [`passthrough` format](/ai-gateway/passthrough/), which forwards request and response bodies byte for byte, without format translation or schema validation. Passthrough keeps AI Model Provider authentication, AI Consumer identity, and logging. Kong forwards every path under `/coding-agents-gemini`, so an AI Consumer key can call each Gemini API endpoint that the organization's key can call, not only content generation.

The following settings configure the AI Model Provider and the AI Model:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Provider)"
    purpose: "The `x-goog-api-key` header with the organization's key, from `GEMINI_TOKEN`. Kong adds it to each upstream request."
  - setting: "`formats: [{type: passthrough}]`"
    purpose: "Forwards bodies without translation. Passthrough can't be combined with other formats and needs {{site.ai_gateway}} 2.2 or later."
  - setting: "`capabilities: [generate]`"
    purpose: "The AI Model serves content generation."
  - setting: "`access.auth_strategies`"
    purpose: "Each request must have a valid AI Consumer key."
  - setting: "`targets[].config.type: gemini`"
    purpose: "Selects Gemini's authentication behavior. With a `gemini` target, Kong also reads token counts from passthrough responses, for analytics and token-based rate limits."
  - setting: "`targets[].config.upstream_url`"
    purpose: "The Gemini API host, with the path `/`. Kong forwards the client's request path without the AI Model's base path, so the API version in the path comes from Gemini CLI."
  - setting: "`config.route.paths` and `strip_path: true`"
    purpose: "Kong matches requests under `/coding-agents-gemini` and removes the prefix before it forwards the request."
  - setting: "`config.route.methods`"
    purpose: "The AI Model accepts `POST`, `GET`, and `OPTIONS`. Content generation requests use `POST`."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so Gemini CLI can call the local data plane at `http://localhost:8000`."
  - setting: "`config.max_request_body_size: 16777216`"
    purpose: "Accepts request bodies up to 16 MB, instead of the 8 MB default. Gemini CLI requests carry the conversation, tool declarations, and file contents."
  - setting: "`config.response_streaming: allow`"
    purpose: "Kong passes streamed responses to Gemini CLI."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. Gemini CLI requests contain source code, so set it to `false` if you only need usage metrics."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key and the Gemini API key in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

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
  - variation: "Restrict the request methods"
    how: "Set `config.route.methods` to `[POST]` and re-apply, so that the AI Model doesn't forward `GET` requests to the Gemini API. Test Gemini CLI after the change, because Kong then rejects each request with another method."
  - variation: "Add per-consumer token budgets"
    how: "Attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to give each AI Consumer a token budget. See [Passthrough format](/ai-gateway/passthrough/) for the AI Policies that work with passthrough."
  - variation: "Manage Gemini CLI settings centrally"
    how: "The [Gemini CLI enterprise guide](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/enterprise.md) describes a system settings file that overrides user and project settings, and a wrapper script that enforces it."
  - variation: "Connect other tools"
    how: "The [Claude Code](/cookbooks/coding-agents-claude-code/) and [Codex](/cookbooks/coding-agents-codex/) cookbooks use passthrough AI Models for Anthropic and OpenAI. For OpenAI-format tools, see the [Cursor cookbook](/cookbooks/coding-agents-cursor/)."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration.

Remove the Gemini CLI variables from your shell, so that Gemini CLI calls the Gemini API directly again:

```bash
unset GOOGLE_GEMINI_BASE_URL GEMINI_API_KEY
```

Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-gemini-cli-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
