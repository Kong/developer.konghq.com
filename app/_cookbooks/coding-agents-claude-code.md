---
title: "AI Tool Integration: Claude Code"
description: Route Claude Code through {{site.ai_gateway_name}} so developers authenticate with a revocable AI Consumer key and the Anthropic API key stays in Kong.
url: "/cookbooks/coding-agents-claude-code/"
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
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-claude-code-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-claude-code-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: Claude Code
      content: |
        This tutorial uses [Claude Code](https://code.claude.com/docs/en/setup).

        1. Install Claude Code from the [setup guide](https://code.claude.com/docs/en/setup).
        1. Verify that it's installed:

           ```bash
           claude --version
           ```
    - title: AI Credentials
      content: |
        The AI Model Provider uses your organization's Anthropic API key.

        1. [Create an Anthropic account](https://console.anthropic.com/).
        1. [Get an API key](https://console.anthropic.com/settings/keys).
        1. Export the API key and the [Messages API version](https://docs.claude.com/en/api/versioning) that Kong sends upstream on each request:

           ```bash
           export ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
           export ANTHROPIC_VERSION='2023-06-01'
           ```
overview: |
  Put {{site.ai_gateway_name}} between Claude Code and the Anthropic API, so that developers hold a Kong key that you can revoke instead of an Anthropic API key. You'll set up:

  * An Anthropic API key that stays in Kong and never reaches developer machines
  * An AI Consumer key for each developer, checked on each request
  * A passthrough endpoint that forwards Claude Code's requests to Anthropic unchanged

  This cookbook uses a static API key for each developer. To authenticate developers through Okta instead, see the [Claude Code SSO cookbook](/cookbooks/claude-code-sso/).
---

## What this cookbook solves

Most teams give each developer an Anthropic API key to export as `ANTHROPIC_API_KEY` on their machine, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Each laptop holds a key that bills the organization's Anthropic account. A leaked key works from anywhere, and removing one developer's access means finding and revoking the right key."
    solution: "The AI Model Provider keeps the Anthropic API key in Kong and adds it to each upstream request. Developers hold only an AI Consumer key."
  - problem: "Nothing between Claude Code and Anthropic identifies the developer, so usage attribution, revocation, and request logging need a separate solution on each machine or in each provider console."
    solution: "The Key Auth AI Auth Strategy maps each key to an AI Consumer and rejects unknown keys with `401` before any upstream call. Deleting the AI Consumer credential revokes one developer."
  - problem: "Claude Code adds capabilities with each release as new `anthropic-beta` values and request body fields. A gateway that translates or allowlists them breaks those features, as Anthropic's [gateway compatibility guide](https://code.claude.com/docs/en/llm-gateway-protocol) explains."
    solution: "The AI Model uses the `passthrough` format, so Kong forwards the request body, the response stream, and the `anthropic-*` headers to Anthropic unchanged."
{% endtable %}

## Try it out

Apply the configuration, connect Claude Code to Kong, then send requests with and without the AI Consumer key and run a prompt from Claude Code.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your Anthropic API key, a Key Auth AI Auth Strategy, an AI Consumer with an API key, and a passthrough AI Model on `/coding-agents-anthropic`. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Generate the AI Consumer's API key. Claude Code sends this key to Kong instead of an Anthropic key. The credential's `api_key` field is write-only, so its value must come from an environment variable:

```bash
export CONSUMER_API_KEY="coding-agents-demo-$(openssl rand -hex 8)"
```

Apply the configuration. The Anthropic credentials come from the prerequisites:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: coding-agents-claude-code-recipe
ai_gateway_model_providers:
- ref: coding-agents-anthropic-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: coding-agents-anthropic-provider
  display_name: coding-agents-anthropic
  type: anthropic
  config:
    auth:
      type: basic
      headers:
      - name: x-api-key
        value: !secret {source: !env 'ANTHROPIC_TOKEN'}
ai_gateway_auth_strategies:
- ref: coding-agents-key-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: coding-agents-key-auth
  display_name: coding-agents key auth
  type: key-auth
  config:
    key_names:
    - x-api-key
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
- ref: coding-agents-anthropic
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: coding-agents-anthropic
  display_name: coding-agents (Anthropic managed)
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
      - /coding-agents-anthropic
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: anthropic-api
    provider: coding-agents-anthropic-provider
    config:
      version: !env 'ANTHROPIC_VERSION'
      type: anthropic
      upstream_url: https://api.anthropic.com/
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

### Connect Claude Code to Kong

Claude Code reads its gateway settings from environment variables ([Connect Claude Code to an LLM gateway](https://code.claude.com/docs/en/llm-gateway-connect)). Point Claude Code at the AI Model and use the AI Consumer key as the API key:

```bash
export ANTHROPIC_BASE_URL='http://localhost:8000/coding-agents-anthropic'
export ANTHROPIC_API_KEY="${CONSUMER_API_KEY}"
unset ANTHROPIC_AUTH_TOKEN
```

These commands set the following values:

* `ANTHROPIC_BASE_URL` sends Claude Code's requests to the AI Model. Claude Code adds `/v1/messages` to it.
* `ANTHROPIC_API_KEY` holds the AI Consumer key. Claude Code sends it in the `x-api-key` header, which the Key Auth AI Auth Strategy reads.
* `unset ANTHROPIC_AUTH_TOKEN` makes sure that Claude Code sends the AI Consumer key. Claude Code uses `ANTHROPIC_AUTH_TOKEN` before `ANTHROPIC_API_KEY` when both are set ([authentication precedence](https://code.claude.com/docs/en/authentication#authentication-precedence)).

In an interactive session, Claude Code asks once whether to use the API key. Approve it. In non-interactive mode (`-p`), Claude Code always uses the key.

### Send a request through the AI Model

Call the Messages API through Kong with the AI Consumer key in the `x-api-key` header, the same header that Claude Code sends:

```bash
curl -sS -X POST "http://localhost:8000/coding-agents-anthropic/v1/messages" \
  -H "Content-Type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -H "x-api-key: ${CONSUMER_API_KEY}" \
  -d '{
    "model": "claude-haiku-4-5-20251001",
    "max_tokens": 32,
    "messages": [{"role": "user", "content": "Reply with exactly: smoke-ok"}]
  }'
```

Kong returns Anthropic's Messages API response unchanged. The response looks similar to the following, with different IDs and token counts:

```text
{
  "id": "msg_01...",
  "type": "message",
  "role": "assistant",
  "model": "claude-haiku-4-5-20251001",
  "content": [
    {
      "type": "text",
      "text": "smoke-ok"
    }
  ],
  "stop_reason": "end_turn",
  "usage": {
    "input_tokens": 14,
    "output_tokens": 6
  }
}
```
{:.no-copy-code}

### Send a request without the AI Consumer key

Send the same request without the `x-api-key` header:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' -X POST "http://localhost:8000/coding-agents-anthropic/v1/messages" \
  -H "Content-Type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{"model": "claude-haiku-4-5-20251001", "max_tokens": 32, "messages": [{"role": "user", "content": "hi"}]}'
```

Kong rejects the request before it reaches Anthropic:

```text
401
```
{:.no-copy-code}

### Send a prompt from Claude Code

Run a one-shot prompt with the environment from [Connect Claude Code to Kong](#connect-claude-code-to-kong):

```bash
claude -p "Reply with exactly: claude-ok" --output-format text --max-turns 1
```

Claude Code prints the reply:

```text
claude-ok
```
{:.no-copy-code}

### Check the results

The requests and the Claude Code prompt confirm the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Kong holds the Anthropic API key"
    evidence: "The request with only the AI Consumer key gets a Messages API response from Anthropic. No Anthropic key is set on the client."
  - behavior: "AI Consumer authentication"
    evidence: "The request without `x-api-key` returns `401`, and Anthropic never receives it."
  - behavior: "Claude Code works through Kong"
    evidence: "`claude -p` prints `claude-ok` with `ANTHROPIC_BASE_URL` pointing at the AI Model."
{% endtable %}

To review the created entities and per-consumer usage, open the `coding-agents-claude-code-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Claude Code sends Messages API requests to Kong with the AI Consumer key in the `x-api-key` header. Kong validates the key, removes it, adds the organization's Anthropic API key, and forwards the request and the streamed response without changing them.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant CC as Claude Code
    participant K as Kong AI Gateway
    participant A as Anthropic API

    CC->>K: POST /coding-agents-anthropic/v1/messages (x-api-key: AI Consumer key)
    activate K
    K->>K: Key Auth AI Auth Strategy validates x-api-key (else 401)
    K->>K: Remove the AI Consumer key and add the Anthropic API key
    K->>A: POST /v1/messages (body and anthropic-* headers unchanged)
    activate A
    A-->>K: Streamed Messages API response
    deactivate A
    K-->>CC: Response, unchanged
    deactivate K
{% endmermaid %}
<!-- vale on -->

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `x-api-key` header, which Claude Code fills from `ANTHROPIC_API_KEY`, and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use.

The following settings configure the Key Auth AI Auth Strategy and the AI Consumer:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`key_names: [x-api-key]`"
    purpose: "Kong reads the AI Consumer key from the `x-api-key` header, the header that Claude Code uses for `ANTHROPIC_API_KEY`."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes `x-api-key` before it forwards the request. The AI Model Provider then sets its own `x-api-key`, so Anthropic only gets the organization's key."
  - setting: "`credentials[].api_key`"
    purpose: "The AI Consumer's key. The field is write-only, so it takes a `!secret` reference to `CONSUMER_API_KEY`."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### AI Model Provider and AI Model

The AI Model Provider holds the organization's Anthropic API key. The AI Model exposes `/coding-agents-anthropic`, requires the Key Auth AI Auth Strategy, and has one target that uses the AI Model Provider. The [passthrough format](/ai-gateway/passthrough/) forwards request and response bodies byte for byte, without translation or schema validation, so new Claude Code features keep working without a Kong change. Passthrough also forwards any path under `/coding-agents-anthropic`, so each AI Consumer can reach the whole Anthropic API with the organization's key, not only `/v1/messages`.

The following settings configure the AI Model Provider and the AI Model:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth.headers` (AI Model Provider)"
    purpose: "Kong sets the `x-api-key` header to `ANTHROPIC_TOKEN` on each upstream request. Anthropic authenticates API keys through this header."
  - setting: "`formats: [{type: passthrough}]`"
    purpose: "Kong forwards bodies without translation. The `passthrough` format can't be combined with other formats and requires {{site.ai_gateway}} 2.2 or later. AI Policies that read or change prompt content, for example guardrails, don't work with it."
  - setting: "`config.route.paths` and `strip_path: true`"
    purpose: "Kong matches the `/coding-agents-anthropic` prefix, removes it, and forwards the rest of the path, for example `/v1/messages`."
  - setting: "`config.route.methods: [POST, OPTIONS]`"
    purpose: "Claude Code sends `POST` requests. Requests with other methods, for example `GET /v1/models`, don't match the AI Model."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so Claude Code can call the local data plane at `http://localhost:8000`."
  - setting: "`targets[].config.upstream_url`"
    purpose: "The Anthropic API host with no path, so Kong adds the client's path to it. See [Upstream paths](/ai-gateway/passthrough/#upstream-paths)."
  - setting: "`targets[].config.version`"
    purpose: "The Anthropic API version, from `ANTHROPIC_VERSION`. Claude Code also sends its own `anthropic-version` header, which Kong forwards unchanged."
  - setting: "`config.max_request_body_size: 16777216`"
    purpose: "Accepts request bodies up to 16 MB, instead of the 8 MB default. Claude Code requests carry the conversation, tool definitions, and file contents."
  - setting: "`config.response_streaming: allow`"
    purpose: "Kong passes the streamed response to Claude Code as it arrives."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. Claude Code requests contain source code and file contents, so set it to `false` if you only need usage metrics."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key and the Anthropic API key in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

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
    how: "Add an AI Consumer with its own credential for each developer, so that usage and revocation are per person. Distribute each key through your secrets tooling."
  - variation: "Distribute the settings"
    how: "Set `ANTHROPIC_BASE_URL` in a [Claude Code managed settings file](https://code.claude.com/docs/en/managed-settings), so that developers don't configure it themselves."
  - variation: "Lock Claude Code to the gateway"
    how: "Set [`allowedProviders`](https://code.claude.com/docs/en/settings-reference#allowedproviders) to `[\"customEndpoint\"]` and put `ANTHROPIC_BASE_URL` in the same managed settings file. Claude Code then refuses sessions that point anywhere else. See [Other LLM gateways](https://code.claude.com/docs/en/llm-gateway) for the required Claude Code version."
  - variation: "Restrict the exposed API"
    how: "Set `upstream_url` to a URL with a fixed path, for example `https://api.anthropic.com/v1/messages`, so that Kong sends every request to that endpoint and ignores the client's path. See [Upstream paths](/ai-gateway/passthrough/#upstream-paths). Claude Code also calls the optional `/v1/messages/count_tokens` endpoint, so test the change before you roll it out."
  - variation: "Send the key as a Bearer token"
    how: "If developers set `ANTHROPIC_AUTH_TOKEN`, Claude Code sends the key as `Authorization: Bearer`. Add a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy (`global: true`) that copies the token to a header in `key_names` and removes `Authorization`. The [Claude Desktop cookbook](/cookbooks/coding-agents-claude-desktop/) shows this pattern."
  - variation: "Add token budgets"
    how: "Attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to give each AI Consumer a token budget. Kong reads token counts from passthrough responses for an `anthropic` target ([Token usage and cost](/ai-gateway/passthrough/#token-usage-and-cost))."
  - variation: "Route to Bedrock, Azure AI Foundry, or Vertex AI"
    how: "Use `formats: [{type: anthropic}]` instead of `passthrough`. Kong then parses Claude Code's requests and forwards them to each provider's Claude endpoint, and AI Policies that read prompts work. The [Claude Code SSO cookbook](/cookbooks/claude-code-sso/) uses this format."
  - variation: "Authenticate developers with Okta"
    how: "Replace the Key Auth AI Auth Strategy with an OpenID Connect AI Auth Strategy and an `apiKeyHelper` script. See the [Claude Code SSO cookbook](/cookbooks/claude-code-sso/)."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-claude-code-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

Remove the Claude Code settings and the AI Consumer key from your shell:

```bash
unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY CONSUMER_API_KEY
```

If you unset `ANTHROPIC_AUTH_TOKEN` for this cookbook, export it again from your shell profile to return to your previous Claude Code authentication.
