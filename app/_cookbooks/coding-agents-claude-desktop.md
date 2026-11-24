---
title: "AI Tool Integration: Claude Desktop"
description: Connect Claude Desktop's third-party Gateway mode to {{site.ai_gateway_name}}, so users authenticate with a revocable AI Consumer key and the Anthropic API key stays in Kong.
url: "/cookbooks/coding-agents-claude-desktop/"
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
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-claude-desktop-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-claude-desktop-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: Claude Desktop
      content: |
        This tutorial uses Claude Desktop with a [third-party inference configuration](https://claude.com/docs/third-party/claude-desktop/gateway).

        1. Install [Claude Desktop](https://claude.com/download) version 1.3036.0 or later. Earlier versions don't have the **Gateway auth scheme** setting.
        1. Use a device where your organization hasn't deployed Claude Desktop, as the [single-machine setup](https://claude.com/docs/third-party/claude-desktop/installation#single-machine-setup) requires.
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
  Put {{site.ai_gateway_name}} between Claude Desktop and the Anthropic API, so that each user enters a Kong key that you can revoke instead of an Anthropic API key. You'll set up:

  * An Anthropic API key that stays in Kong and never reaches user devices
  * An AI Consumer key that Kong accepts in either of Claude Desktop's gateway auth schemes
  * A passthrough endpoint that forwards Claude Desktop's requests to Anthropic unchanged
---

## What this cookbook solves

Most teams that run Claude Desktop with a third-party inference configuration set the Anthropic API as the provider and enter the organization's Anthropic API key on each device, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Each device holds a key that bills the organization's Anthropic account. A leaked key works from anywhere, and removing one user's access means rotating the key on every other device."
    solution: "The AI Model Provider keeps the Anthropic API key in Kong and adds it to each upstream request. Users enter only an AI Consumer key as the **Gateway API key**."
  - problem: "Nothing between Claude Desktop and Anthropic identifies the user, so usage attribution, revocation, and request logging need a separate solution on each device."
    solution: "The Key Auth AI Auth Strategy maps each key to an AI Consumer and rejects unknown keys with `401` before any upstream call. Deleting the AI Consumer credential revokes one user."
  - problem: "Claude Desktop sends the gateway credential as `Authorization: Bearer` by default, or as `x-api-key`, and a gateway that reads only one of them rejects the other."
    solution: "A global Pre-Function Policy moves a Bearer token to the `apikey` header, and the Key Auth AI Auth Strategy reads `apikey` or `x-api-key`, so both schemes work."
  - problem: "Claude Desktop's [gateway requirements](https://claude.com/docs/third-party/claude-desktop/gateway) include streaming, tool use, and `cache_control` breakpoints. A gateway that strips or rewrites these fields breaks features or loses prompt caching."
    solution: "The AI Model uses the `passthrough` format, so Kong forwards the request body and the response stream to Anthropic unchanged."
{% endtable %}

## Try it out

Apply the configuration, connect Claude Desktop to Kong, then send requests with and without the AI Consumer key and send a message from Claude Desktop.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your Anthropic API key, a Key Auth AI Auth Strategy, an AI Consumer with an API key, a global Pre-Function Policy that moves a Bearer token to the `apikey` header, and a passthrough AI Model on `/coding-agents-anthropic`. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Generate the AI Consumer's API key. Claude Desktop sends this key to Kong instead of an Anthropic key. The credential's `api_key` field is write-only, so its value must come from an environment variable:

```bash
export CONSUMER_API_KEY="coding-agents-demo-$(openssl rand -hex 8)"
```

Apply the configuration. The Anthropic credentials come from the prerequisites:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: coding-agents-claude-desktop-recipe
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
    - apikey
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
        ngx.req.clear_header("Authorization")
      end
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

### Connect Claude Desktop to Kong

Claude Desktop reads its gateway settings from its third-party inference configuration, not from `ANTHROPIC_BASE_URL`. Print the AI Consumer key, which you enter as the **Gateway API key**:

```bash
echo "${CONSUMER_API_KEY}"
```

Set up Claude Desktop in its [in-app configuration window](https://claude.com/docs/third-party/claude-desktop/in-app-configuration):

1. Launch Claude Desktop and don't sign in. From the macOS menu bar, or the application menu (☰) on Windows, click **Help > Troubleshooting > Enable Developer Mode**.
1. Click **Developer > Configure Third-Party Inference**.
1. In **Connection**, set **Inference provider** to **Gateway**, then set the fields in the following table.
1. Click **Apply Changes**, then click **Save & Restart**.
1. On the sign-in screen, choose the option to start Claude Desktop with the configuration you entered.

Set the following fields in **Connection**:

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: "Credential kind"
    value: "**Static API key**"
  - field: "Gateway base URL"
    value: "`http://localhost:8000/coding-agents-anthropic`. Don't add `/v1`, because Claude Desktop adds `/v1/messages`."
  - field: "Gateway API key"
    value: "The value of `CONSUMER_API_KEY`. This is the AI Consumer key, not the organization's Anthropic API key."
  - field: "Gateway auth scheme"
    value: "**Bearer**, the default. Kong also accepts **x-api-key**."
  - field: "Model discovery"
    value: "Off. The AI Model doesn't serve `GET /v1/models`."
  - field: "Model list"
    value: "Add the full model ID `claude-haiku-4-5-20251001`. With discovery off, each entry must be a full model ID ([Models](https://claude.com/docs/third-party/claude-desktop/gateway#models))."
{% endtable %}

If Claude Desktop shows `Gateway was unreachable`, it couldn't reach the **Gateway base URL** at startup ([Desktop app](https://code.claude.com/docs/en/llm-gateway-connect#desktop-app)). Check that the data plane is running and that the URL matches the AI Model's path.

### Send a request through the AI Model

Call the Messages API through Kong with the AI Consumer key as a Bearer token, the way Claude Desktop sends it with the default auth scheme:

```bash
curl -sS -X POST "http://localhost:8000/coding-agents-anthropic/v1/messages" \
  -H "Content-Type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -H "Authorization: Bearer ${CONSUMER_API_KEY}" \
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

To test the **x-api-key** scheme, send the same request with `-H "x-api-key: ${CONSUMER_API_KEY}"` instead of the `Authorization` header.

### Send a request without the AI Consumer key

Send the same request without the `Authorization` header:

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

### Send a message from Claude Desktop

Start a new chat with `claude-haiku-4-5-20251001` selected and send `Reply with exactly: desktop-ok`. Claude Desktop replies with `desktop-ok`.

### Check the results

The requests and the Claude Desktop chat confirm the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Kong holds the Anthropic API key"
    evidence: "The request with only the AI Consumer key gets a Messages API response from Anthropic. No Anthropic key is set on the client."
  - behavior: "Bearer token authentication"
    evidence: "The request with `Authorization: Bearer` succeeds, because the Pre-Function Policy moves the token to the `apikey` header."
  - behavior: "AI Consumer authentication"
    evidence: "The request without a key returns `401`, and Anthropic never receives it."
  - behavior: "Claude Desktop works through Kong"
    evidence: "Claude Desktop replies `desktop-ok` with the **Gateway base URL** pointing at the AI Model."
{% endtable %}

To review the created entities and per-consumer usage, open the `coding-agents-claude-desktop-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Claude Desktop sends Messages API requests to Kong with the AI Consumer key as a Bearer token or in the `x-api-key` header. Kong moves a Bearer token to the `apikey` header, validates the key, removes it, adds the organization's Anthropic API key, and forwards the request and the streamed response without changing them.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant CD as Claude Desktop
    participant K as Kong AI Gateway
    participant A as Anthropic API

    CD->>K: POST /coding-agents-anthropic/v1/messages (Bearer token or x-api-key)
    activate K
    K->>K: Pre-Function Policy moves a Bearer token to apikey
    K->>K: Key Auth AI Auth Strategy validates apikey or x-api-key (else 401)
    K->>K: Remove the AI Consumer key and add the Anthropic API key
    K->>A: POST /v1/messages (body unchanged)
    activate A
    A-->>K: Streamed Messages API response
    deactivate A
    K-->>CD: Response, unchanged
    deactivate K
{% endmermaid %}
<!-- vale on -->

### Pre-Function Policy

The Key Auth AI Auth Strategy compares the whole header value, so it can't read a key from an `Authorization: Bearer` header. The [Pre-Function](/ai-gateway/policies/pre-function/) Policy runs Lua that moves the Bearer token to the `apikey` header. The policy is global, because a policy attached to an AI Model runs after authentication, while a global Pre-Function Policy runs before it ([Scopes and authentication](/ai-gateway/entities/ai-policy/#scopes-and-authentication)).

The following settings configure the Pre-Function Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`global: true`"
    purpose: "The policy applies to each request on the {{site.ai_gateway}} and runs before the Key Auth AI Auth Strategy. Requests without a Bearer token, including the **x-api-key** scheme, pass through unchanged."
  - setting: "`config.rewrite`"
    purpose: "The Lua runs in the `rewrite` phase, before authentication."
  - setting: "`ngx.req.set_header(\"apikey\", ...)`"
    purpose: "Copies the token after the `Bearer ` prefix to the `apikey` header. The prefix check ignores case."
  - setting: "`ngx.req.clear_header(\"Authorization\")`"
    purpose: "Removes the `Authorization` header, so the AI Consumer key doesn't reach Anthropic. The Key Auth AI Auth Strategy removes only the header that it reads."
{% endtable %}

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header, which the Pre-Function Policy fills, or the `x-api-key` header, and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use.

The following settings configure the Key Auth AI Auth Strategy and the AI Consumer:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`key_names: [apikey, x-api-key]`"
    purpose: "Kong reads the AI Consumer key from `apikey` for the **Bearer** scheme, or from `x-api-key` for the **x-api-key** scheme."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the header that held the key before it forwards the request. The AI Model Provider then sets its own `x-api-key`, so Anthropic only gets the organization's key."
  - setting: "`credentials[].api_key`"
    purpose: "The AI Consumer's key. The field is write-only, so it takes a `!secret` reference to `CONSUMER_API_KEY`."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### AI Model Provider and AI Model

The AI Model Provider holds the organization's Anthropic API key. The AI Model exposes `/coding-agents-anthropic`, requires the Key Auth AI Auth Strategy, and has one target that uses the AI Model Provider. The [passthrough format](/ai-gateway/passthrough/) forwards request and response bodies byte for byte, without translation or schema validation, so streaming, tool use, and `cache_control` breakpoints reach Anthropic as Claude Desktop sent them. Passthrough also forwards any path under `/coding-agents-anthropic`, so each AI Consumer can reach the whole Anthropic API with the organization's key, not only `/v1/messages`.

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
    purpose: "Claude Desktop sends `POST` requests. Requests with other methods, for example `GET /v1/models`, don't match the AI Model, so **Model discovery** must be off."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so Claude Desktop can call the local data plane at `http://localhost:8000`."
  - setting: "`targets[].config.upstream_url`"
    purpose: "The Anthropic API host with no path, so Kong adds the client's path to it. See [Upstream paths](/ai-gateway/passthrough/#upstream-paths)."
  - setting: "`targets[].config.version`"
    purpose: "The Anthropic API version, from `ANTHROPIC_VERSION`."
  - setting: "`config.max_request_body_size: 16777216`"
    purpose: "Accepts request bodies up to 16 MB, instead of the 8 MB default. Requests carry the conversation, tool definitions, and attached files."
  - setting: "`config.response_streaming: allow`"
    purpose: "Kong passes the streamed response to Claude Desktop as it arrives."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. Conversations can contain documents and source code, so set it to `false` if you only need usage metrics."
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
  - variation: "Issue one AI Consumer for each user"
    how: "Add an AI Consumer with its own credential for each Claude Desktop user, so that usage and revocation are per person. Distribute each key through your secrets tooling."
  - variation: "Use only the x-api-key scheme"
    how: "If every installation sets **Gateway auth scheme** to **x-api-key**, remove the Pre-Function Policy and `apikey` from `key_names`. The AI Model and AI Model Provider don't change."
  - variation: "Distribute the configuration to a fleet"
    how: "In the in-app configuration window, use [**Export**](https://claude.com/docs/third-party/claude-desktop/in-app-configuration#apply-locally-or-export-for-a-fleet) to create a `.mobileconfig` profile for macOS or a `.reg` file for Windows, and deploy it with your MDM ([Deploy with MDM](https://claude.com/docs/third-party/claude-desktop/mdm)). Point **Gateway base URL** at a shared data plane instead of `localhost`."
  - variation: "Restrict the exposed API"
    how: "Set `upstream_url` to a URL with a fixed path, for example `https://api.anthropic.com/v1/messages`, so that Kong sends every request to that endpoint and ignores the client's path. See [Upstream paths](/ai-gateway/passthrough/#upstream-paths)."
  - variation: "Add token budgets"
    how: "Attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to give each AI Consumer a token budget. Kong reads token counts from passthrough responses for an `anthropic` target ([Token usage and cost](/ai-gateway/passthrough/#token-usage-and-cost))."
  - variation: "Authenticate users with an identity provider"
    how: "Set **Credential kind** to **Interactive sign-in**, so that Claude Desktop sends a token from your identity provider as a Bearer credential ([single sign-on](https://claude.com/docs/third-party/claude-desktop/gateway#single-sign-on-with-your-identity-provider)). Validate it with an OpenID Connect AI Auth Strategy instead of the Key Auth AI Auth Strategy. The [Claude Code SSO cookbook](/cookbooks/claude-code-sso/) shows the AI Auth Strategy for Okta."
  - variation: "Connect Claude Code"
    how: "Claude Code uses `ANTHROPIC_BASE_URL` and `ANTHROPIC_API_KEY` instead of the Claude Desktop configuration. See the [Claude Code cookbook](/cookbooks/coding-agents-claude-code/)."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-claude-desktop-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

Remove the AI Consumer key from your shell:

```bash
unset CONSUMER_API_KEY
```

To return to standard Claude Desktop, choose the Anthropic sign-in option on the sign-in screen ([single-machine setup](https://claude.com/docs/third-party/claude-desktop/installation#single-machine-setup)). The saved Gateway configuration, which holds the AI Consumer key, stays in the local `configLibrary` directory ([where Claude Desktop reads configuration](https://claude.com/docs/third-party/claude-desktop/configuration-format#where-claude-desktop-reads-configuration-on-a-device)). If you have no other third-party configuration, quit Claude Desktop and delete the directory. On macOS, run:

```bash
rm -rf "${HOME}/Library/Application Support/Claude-3p/configLibrary"
```

On Windows, delete `%LOCALAPPDATA%\Claude-3p\configLibrary\`.

If the **Developer** menu still shows, turn off Developer mode: click **Developer > Open Developer Config File**, change `"allowDevTools": true` to `false`, save the file, then quit and reopen Claude Desktop ([in-app configuration](https://claude.com/docs/third-party/claude-desktop/in-app-configuration#open-the-configuration-window)).
