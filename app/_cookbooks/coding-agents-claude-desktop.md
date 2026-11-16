---
title: "AI Tool Integration: Claude Desktop"
description: Point Claude Desktop third-party Gateway mode at {{site.ai_gateway_name}} with a managed Anthropic AI Model Provider key.
url: "/cookbooks/coding-agents-claude-desktop/"
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
  - anthropic

hint: "Requires Kong AI Gateway 2.2+, an Anthropic API key, a Kong AI Consumer key, and Claude Desktop with third-party inference."
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
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-claude-desktop-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-claude-desktop-recipe`, a local data plane connected to it, and prints `export` lines (including `AI_GATEWAY_ID`). Paste those into your shell when prompted.

           The data plane must run {{site.ai_gateway}} 2.2 or later, which passthrough AI Models require.
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
        Export an Anthropic API key for the AI Model Provider:

        ```bash
        export ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
        export ANTHROPIC_VERSION='2023-06-01'
        ```
    - title: AI Consumer API Key
      content: |
        Generate the API key that the demo AI Consumer sends to Kong. Client tools use this key instead of the provider key:

        ```bash
        export CONSUMER_API_KEY="coding-agents-demo-$(openssl rand -hex 8)"
        echo "$CONSUMER_API_KEY"
        ```
    - title: Claude Desktop
      content: |
        Install [Claude Desktop](https://claude.com/download) with a build that includes third-party inference (version 1.2581.0 or later).
overview: |
  Use this recipe to point Claude Desktop at the same managed Anthropic Messages path as [Claude Code](/cookbooks/coding-agents-claude-code/). Kong authenticates Claude Desktop with an AI Consumer key, then injects the org Anthropic API key from the AI Model Provider.

  Official field labels come from [Deploy Claude Desktop on 3P with an LLM gateway](https://claude.com/docs/third-party/claude-desktop/gateway) and the [configuration reference](https://claude.com/docs/third-party/claude-desktop/configuration).
---

## The problem

Claude Desktop can run against a third-party inference provider instead of a Claude.ai sign-in. An organization that wants to give a whole team Claude Desktop on a shared Anthropic account runs into several problems:

* **Provider keys end up on laptops.** Claude Desktop's [third-party configuration](https://claude.com/docs/third-party/claude-desktop/configuration) can set the inference provider to the Anthropic API and hold an Anthropic API key directly. Every machine then holds a credential that bills the organization's account, a leaked key works anywhere, and offboarding one person means rotating a key that every other machine also uses.
* **Claude Desktop doesn't share Claude Code's configuration.** Claude Desktop doesn't read `ANTHROPIC_BASE_URL`, `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, or `apiKeyHelper`. Desktop sessions with a [third-party inference configuration](https://code.claude.com/docs/en/llm-gateway-connect#desktop-app) authenticate with that configuration's credential, so a team that already routes Claude Code through environment variables needs a second, separate setup for Claude Desktop.
* **There is no central place to apply policy.** Anthropic's [LLM gateway guidance](https://code.claude.com/docs/en/llm-gateway) lists what organizations put a gateway in front of Claude for: keeping the provider key server-side, attributing usage by developer, enforcing budgets and rate limits, logging every request for compliance, and switching providers without touching developer machines. Without a gateway, each of those has to be solved per machine or per provider console.
* **A gateway has to match Claude Desktop's wire format.** Claude Desktop's [gateway mode](https://claude.com/docs/third-party/claude-desktop/gateway) requires `POST /v1/messages` from the Anthropic Messages API with streaming and tool use, and asks gateways to preserve `cache_control` so prompt caching keeps working. Claude Desktop sends its gateway credential as `Authorization: Bearer` by default, or as `x-api-key` when you change **Gateway auth scheme**, so the gateway has to accept whichever header the configuration selects.

The root issue is that the credential, the policy, and the compatibility burden all sit on the client. Teams need one server-side point that holds the organization's Anthropic key, authenticates each Claude Desktop installation with a credential it can revoke, and forwards Messages API requests unchanged.

{:.warning}
> **Do not** put Claude.ai Team seat or session tokens in the Gateway profile. Anthropic's terms prohibit intermediating Claude.ai credentials.

## The solution

This recipe puts {{site.ai_gateway}} between Claude Desktop and the Anthropic API:

* **Server-side provider credential.** The organization's Anthropic API key lives on {{site.ai_gateway}}. Claude Desktop users never see it, and rotating it is one configuration change.
* **Revocable user credentials.** Each user gets an AI Consumer API key from Kong and enters it as the **Gateway API key**. Kong attributes every request to the matching AI Consumer, and revoking access means deleting one AI Consumer credential.
* **Either Gateway auth scheme.** Kong accepts the AI Consumer key in `x-api-key` or as an `Authorization: Bearer` token, so the recipe works with Claude Desktop's default scheme or the `x-api-key` alternative.
* **Native Messages API forwarding.** The AI Model forwards Claude Desktop's Anthropic-format requests without translating them, so streaming, tool use, `cache_control` breakpoints, and `anthropic-*` headers reach Anthropic unchanged.
* **One place for future policy.** Once traffic flows through Kong, you can add logging, rate limiting, and other AI Policies without changing anything on user machines.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant CD as Claude Desktop
    participant K as AI Gateway
    participant A as Anthropic API

    CD->>K: POST /coding-agents-anthropic/v1/messages (x-api-key or Authorization: Bearer, AI Consumer key)
    activate K
    K->>K: Pre-Function Policy copies a Bearer token into apikey
    K->>K: Key Auth AI Auth Strategy validates apikey or x-api-key (else 401)
    K->>K: AI Model strips path, AI Model Provider swaps in org Anthropic key
    K->>A: POST /v1/messages (x-api-key: org key, body unchanged)
    activate A
    A-->>K: Messages API response (streamed)
    deactivate A
    K-->>CD: Response forwarded byte-for-byte
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
  - component: "Claude Desktop"
    responsibility: "Sends Anthropic Messages API requests to the **Gateway base URL** with the AI Consumer key in the header that **Gateway auth scheme** selects."
  - component: "Pre-Function Policy"
    responsibility: "Copies an `Authorization: Bearer` token into the `apikey` header so the Key Auth AI Auth Strategy can read it."
  - component: "Key Auth AI Auth Strategy"
    responsibility: "Validates the AI Consumer key from `apikey` or `x-api-key`, attaches the request to the AI Consumer, and removes the key before the request goes upstream."
  - component: "AI Consumer"
    responsibility: "Represents one user. Its API key credential is the only secret the user holds."
  - component: "AI Model"
    responsibility: "Exposes `/coding-agents-anthropic` and forwards Messages API traffic in passthrough format, without translation."
  - component: "AI Model Provider"
    responsibility: "Holds the organization's Anthropic API key and injects it into every upstream request."
  - component: "Anthropic API"
    responsibility: "Serves the model inference and bills the organization's account."
{% endtable %}

## How it works

When you send a message in Claude Desktop, the request goes through these steps:

1. **Claude Desktop sends the request to Kong.** With **Gateway base URL** set to `http://localhost:8000/coding-agents-anthropic`, Claude Desktop posts Messages API requests to `/coding-agents-anthropic/v1/messages`. It sends the **Gateway API key** as `x-api-key` or as `Authorization: Bearer <key>`, depending on **Gateway auth scheme**.
1. **Kong normalizes a Bearer token.** A global Pre-Function Policy runs in the rewrite phase, before authentication. If the request carries `Authorization: Bearer <key>`, it copies the key into the `apikey` header. Requests that use `x-api-key` pass through unchanged.
1. **Kong authenticates the user.** The AI Model lists the Key Auth AI Auth Strategy in `access.auth_strategies`. The AI Auth Strategy reads the key from `apikey` or `x-api-key`, matches it against the AI Consumer credentials, and attaches the request to `coding-agents-consumer`. A missing or unknown key returns `401`.
1. **Kong removes the AI Consumer key.** With `hide_credentials` enabled, the AI Auth Strategy strips the key header it matched so the AI Consumer credential doesn't reach Anthropic in that header.
1. **The AI Model forwards the request unchanged.** The AI Model uses the `passthrough` format, so Kong forwards the request and response bodies byte-for-byte. Kong strips the `/coding-agents-anthropic` prefix and sends the remaining path, `/v1/messages`, to the target's `upstream_url`.
1. **The AI Model Provider injects the organization's key.** The target references the AI Model Provider, which sets `x-api-key` to the organization's Anthropic API key. Anthropic authenticates the request against that key and bills the organization's account.
1. **The response streams back.** Anthropic streams the response back through Kong to Claude Desktop. Kong logs the request against the AI Consumer.

### Pre-Function Policy: Bearer token normalization

Claude Desktop's **Gateway auth scheme** defaults to Bearer, which sends the AI Consumer key as `Authorization: Bearer <key>`. Key Auth doesn't strip a `Bearer ` prefix, so it can't match that header value against an AI Consumer credential on its own. The [Pre-Function](/ai-gateway/policies/pre-function/) Policy closes that gap: it copies the token into the `apikey` header before authentication runs. The Policy is global, so it applies to every resource on this {{site.ai_gateway}}.

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

**`config.rewrite`**: An array of Lua source strings that run in the rewrite phase. The rewrite phase runs before the Key Auth AI Auth Strategy, so the `apikey` header exists by the time authentication reads it.

**`ngx.req.set_header("apikey", ...)`**: Sets the header on the incoming request so later processing, including Key Auth, sees it. The prefix check is case-insensitive, so `Bearer` and `bearer` both match.

**`global: true`**: Applies the Policy to all resources on the {{site.ai_gateway}}. Requests without a Bearer token, including Claude Desktop with the `x-api-key` scheme, pass through unchanged.

**Skipping the Policy**: If every Claude Desktop installation uses the `x-api-key` scheme, the Key Auth AI Auth Strategy reads the key directly and the Pre-Function Policy has nothing to do. Keep it if any installation might use the default Bearer scheme.

### Key Auth: AI Consumer authentication

The Key Auth AI Auth Strategy is what lets each user hold a Kong credential instead of an Anthropic key. It reads the AI Consumer key from either header the recipe supports: `apikey`, which the Pre-Function Policy fills from a Bearer token, or `x-api-key`, which Claude Desktop sends directly with the `x-api-key` scheme. Kong attributes each request to the AI Consumer that owns the key, and deleting the credential revokes access without touching the organization's Anthropic key. Authentication in {{site.ai_gateway_name}} is an AI Auth Strategy that the AI Model references, not an AI Policy.

#### Configuration details

```yaml
ai_gateway_auth_strategies:
- ref: coding-agents-key-auth
  name: coding-agents-key-auth
  type: key-auth
  config:
    key_names:
    - apikey
    - x-api-key
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

**`key_names: [apikey, x-api-key]`**: The headers Kong reads the AI Consumer key from. `apikey` covers the Bearer scheme after the Pre-Function Policy runs, and `x-api-key` covers the `x-api-key` scheme.

**`hide_credentials: true`**: Removes the matched key header from the request before Kong forwards it. With the `x-api-key` scheme, the AI Model Provider then sets its own `x-api-key` with the organization's key, so Anthropic only sees the provider credential in that header.

**`credentials[].api_key`**: The AI Consumer's key. The field is write-only, so it takes a `!secret` reference rather than a plain string.

**Scaling AI Consumers**: Add one AI Consumer per user, each with its own credential. The recipe defines one AI Consumer for demonstration.

### AI Model and AI Model Provider: Messages API passthrough with credential injection

The AI Model gives Claude Desktop an Anthropic-compatible base URL, and the AI Model Provider supplies the credential Anthropic expects. The AI Model uses the `passthrough` format, which forwards request and response bodies byte-for-byte without schema validation. That addresses the compatibility problem: streaming, tool use, `cache_control` breakpoints, and `anthropic-*` headers reach Anthropic exactly as Claude Desktop sent them. Passthrough still keeps AI Model Provider authentication, AI Consumer identity, and logging.

#### Configuration details

```yaml
ai_gateway_model_providers:
- ref: coding-agents-anthropic-provider
  name: coding-agents-anthropic-provider
  type: anthropic
  config:
    auth:
      type: basic
      headers:
      - name: x-api-key
        value: !secret {source: !env 'ANTHROPIC_TOKEN'}
ai_gateway_models:
- ref: coding-agents-anthropic
  name: coding-agents-anthropic
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
```
{:.no-copy-code}

**`config.auth.headers`** (AI Model Provider): The header Kong adds to every upstream request. Anthropic authenticates API keys through `x-api-key`, so the AI Model Provider sets that header to the organization's key.

**`formats: [{type: passthrough}]`**: Forwards bodies without translation or validation. The `passthrough` format can't be combined with other formats and requires {{site.ai_gateway}} 2.2 or later.

**`route.paths` and `strip_path: true`**: Claude Desktop appends `/v1/messages` to the **Gateway base URL**. Kong matches the `/coding-agents-anthropic` prefix, strips it, and forwards `/v1/messages` to the upstream.

**`route.methods`**: Claude Desktop sends `POST` for inference. The AI Model doesn't accept `GET`, so it doesn't serve `GET /v1/models`, and Claude Desktop's model discovery can't populate the model picker from it. Set an explicit **Model list** instead, as shown in [Configure Claude Desktop](#configure-claude-desktop).

**`targets[].config.upstream_url`**: The Anthropic API base URL. Kong appends the stripped request path to it.

**`targets[].config.version`**: The Anthropic API version, read from `ANTHROPIC_VERSION`.

**`max_request_body_size: 16777216`**: Raises the request body limit to 16 MB from the 8 MB default. Requests carry the full conversation, tool definitions, and attached file contents, and long sessions can exceed the default.

**`response_streaming: allow`**: Lets Anthropic stream Server-Sent Events back to Claude Desktop, which renders tokens as they arrive.

**`logging.payloads: true`**: Captures full request and response bodies. Claude Desktop conversations can include source code, documents, and other sensitive content, so payload logging can expose that data in your logging destination. Set it to `false` if you only need usage metrics.

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. AI Vaults support HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store.

## Apply the Kong configuration

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply command can manage it. The `coding-agents-claude-desktop-recipe` namespace scopes every resource, so teardown removes only this recipe's configuration.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

The following configuration creates the AI Model Provider with the organization's Anthropic key, the Key Auth AI Auth Strategy, the demo AI Consumer, the Pre-Function Policy that copies a Bearer token into `apikey`, and the passthrough AI Model. `AI_GATEWAY_ID`, `ANTHROPIC_TOKEN`, `ANTHROPIC_VERSION`, and `CONSUMER_API_KEY` are already exported from the prerequisites.

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
    - "local auth = kong.request.get_header(\"Authorization\")\nif auth and string.sub(string.lower(auth),\
      \ 1, 7) == \"bearer \" then\n  ngx.req.set_header(\"apikey\", string.sub(auth,\
      \ 8))\nend\n"
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

## Try it out

Point Claude Desktop at the AI Model, send a request directly to confirm the gateway path, and then send a message from Claude Desktop. You also send a request without a key to see Key Auth reject it.

### Configure Claude Desktop

Open Claude Desktop's [in-app configuration window](https://claude.com/docs/third-party/claude-desktop/in-app-configuration) and set Gateway as the inference provider:

1. Click **Help → Troubleshooting → Enable Developer Mode**, and restart Claude Desktop if it prompts you.
1. Click **Developer → Configure Third-Party Inference…**.
1. In **Connection**, set **Inference provider** to **Gateway**.
1. Set the connection fields to the values in the following table.
1. Click **Apply Changes**. Claude Desktop writes the configuration to this device and relaunches into it.

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: Credential kind
    value: Static API key
  - field: Gateway base URL
    value: "`http://localhost:8000/coding-agents-anthropic`. Don't add `/v1`, because Claude Desktop appends `/v1/messages`."
  - field: Gateway API key
    value: "The value of `CONSUMER_API_KEY`. This is the AI Consumer key, not the organization's Anthropic key and not a Claude.ai seat token."
  - field: Gateway auth scheme
    value: "`x-api-key`. The default, Bearer, also authenticates through the Pre-Function Policy."
  - field: Model discovery
    value: "Off. This AI Model doesn't serve `GET /v1/models`."
  - field: Model list
    value: "Add the full model ID `claude-haiku-4-5-20251001`."
{% endtable %}

When every **Model list** entry is a full model ID, Claude Desktop [skips model discovery](https://claude.com/docs/third-party/claude-desktop/gateway#models) automatically. Turning **Model discovery** off covers earlier Claude Desktop versions that still call `GET /v1/models`.

If Claude Desktop shows `Gateway was unreachable`, it couldn't reach the **Gateway base URL** at startup. Check that the data plane is running and that the URL matches the AI Model's path.

### Send a request through the AI Model

Call the Messages API through Kong with the AI Consumer key in `x-api-key`, the same header Claude Desktop sends with the `x-api-key` scheme:

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

Kong returns Anthropic's Messages API response unchanged. The response looks similar to this, with different IDs and token counts:

```json
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

Repeat the request without `x-api-key`:

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

Start a new chat with `claude-haiku-4-5-20251001` selected and send `Reply with exactly: desktop-ok`. Claude Desktop replies with `desktop-ok`, and the data plane logs show `POST /coding-agents-anthropic/v1/messages`.

### What happened

1. **The direct request** carried the AI Consumer key in `x-api-key`. The Key Auth AI Auth Strategy matched it to `coding-agents-consumer`, removed it, and the AI Model Provider replaced it with the organization's Anthropic key. Anthropic answered with `smoke-ok`.
1. **The request without a key** had no `Authorization` header for the Pre-Function Policy to copy and no `x-api-key`, so it failed at the Key Auth AI Auth Strategy with `401`. Kong never contacted Anthropic, so the organization's key was never used.
1. **The Claude Desktop message** followed the same path as the direct request. Claude Desktop appended `/v1/messages` to the **Gateway base URL** and sent the **Gateway API key** in the header that **Gateway auth scheme** selects. The passthrough AI Model forwarded the request body and response stream unchanged. Claude Desktop never had access to the organization's Anthropic key.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `coding-agents-claude-desktop-recipe`. The recipe created an AI Model Provider (`coding-agents-anthropic-provider`) holding the organization's Anthropic key, an AI Model (`coding-agents-anthropic`) at `/coding-agents-anthropic`, a Key Auth AI Auth Strategy (`coding-agents-key-auth`), a global Pre-Function Policy (`coding-agents-bearer-to-apikey`), and an AI Consumer (`coding-agents-consumer`) with an API key credential, all scoped to this recipe by the kongctl namespace.

For request, token, and per-AI Consumer analysis across every {{site.ai_gateway}}, open the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

* **Issue one AI Consumer per user.** Add an AI Consumer and credential for each Claude Desktop user so usage and revocation are per person. Distribute each key through your secrets tooling.
* **Distribute the configuration to a fleet.** The in-app configuration window can [export](https://claude.com/docs/third-party/claude-desktop/in-app-configuration#apply-locally-or-export-for-a-fleet) the Gateway settings as a `.mobileconfig` profile for macOS MDM or a `.reg` file for Windows MDM. See [Deploy with MDM](https://claude.com/docs/third-party/claude-desktop/mdm) for the deployment workflow. Point the **Gateway base URL** at a shared {{site.ai_gateway}} data plane instead of `localhost`.
* **Route Claude Code through the same AI Model.** The [Claude Code recipe](/cookbooks/coding-agents-claude-code/) uses the same managed Anthropic key and passthrough AI Model with Claude Code's `ANTHROPIC_BASE_URL`.
* **Replace API keys with SSO.** Claude Desktop also supports an **Interactive sign-in** credential kind that sends a token from your identity provider to the gateway as a Bearer credential, as described in [single sign-on with your identity provider](https://claude.com/docs/third-party/claude-desktop/gateway#single-sign-on-with-your-identity-provider). The [Claude Code SSO recipe](/cookbooks/claude-code-sso/) shows how to authenticate Okta users with an OpenID Connect AI Auth Strategy.
* **Move credentials into a vault.** Use [AI Vaults](/ai-gateway/entities/ai-vault/) to source the Anthropic key and AI Consumer credentials from HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, or the {{site.konnect_short_name}} Config Store.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-claude-desktop-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
