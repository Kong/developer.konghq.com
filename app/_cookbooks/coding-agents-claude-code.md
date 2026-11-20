---
title: "AI Tool Integration: Claude Code"
description: Point Claude Code at {{site.ai_gateway_name}} with a managed Anthropic AI Model Provider key and a Key Auth AI Auth Strategy.
url: "/cookbooks/coding-agents-claude-code/"
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
requires_embeddings: false
providers:
  - anthropic

hint: "Requires Kong AI Gateway 2.2+, an Anthropic API key, and the Claude Code CLI."
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
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-claude-code-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-claude-code-recipe`, a local data plane connected to it, and prints `export` lines (including `AI_GATEWAY_ID`). Paste those into your shell when prompted.

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
overview: |
  Use Claude Code when you want Anthropic's Messages API through a managed org key. Claude Code speaks Anthropic wire format, so this path uses a passthrough AI Model on `/coding-agents-anthropic`. Kong holds the org Anthropic key on the AI Model Provider and authenticates the client with a Key Auth AI Auth Strategy.

  For Okta SSO, use [Claude Code SSO](/cookbooks/claude-code-sso/).
---

## The problem

Claude Code calls the Anthropic Messages API directly from each developer's machine. That works for one person with one key, but an organization that wants to give a whole team Claude Code on a shared Anthropic account runs into several problems:

* **Provider keys end up on laptops.** The simplest setup is to hand each developer an Anthropic API key and have them export it as `ANTHROPIC_API_KEY`. Claude Code sends that key as the `X-Api-Key` header straight to `api.anthropic.com`. Every machine holds a credential that bills the organization's account, a leaked key works anywhere, and offboarding one developer means finding and revoking the right key.
* **Per-developer Console keys move the problem but don't remove it.** The [Claude Console](https://code.claude.com/docs/en/iam#claude-console-authentication) can issue each developer their own Claude Code API key. Usage is attributed per key, but the key is still a provider credential stored on the developer's machine. Budgets, rate limits, and audit logging live in a separate console from the rest of your API traffic.
* **There is no central place to apply policy.** Anthropic's [LLM gateway guidance](https://code.claude.com/docs/en/llm-gateway) lists what organizations put a gateway in front of Claude Code for: keeping the provider key server-side, attributing usage by developer, enforcing budgets and rate limits, logging every request for compliance, and switching providers without touching developer machines. Without a gateway, each of those has to be solved per machine or per provider console.
* **A gateway has to stay out of Claude Code's way.** Claude Code sends Anthropic-specific request headers such as `anthropic-beta` and `anthropic-version`, and new capabilities arrive as new `anthropic-beta` values and request body fields with each release. Anthropic's [gateway compatibility guide](https://code.claude.com/docs/en/llm-gateway-protocol) asks gateways to forward these unchanged. A gateway that translates, allowlists, or rewrites the request breaks features such as extended context and per-turn effort, sometimes with `400` errors and sometimes silently.

The root issue is that the credential, the policy, and the compatibility burden all sit on the client. Teams need one server-side point that holds the organization's Anthropic key, authenticates developers with credentials it can revoke, and forwards Claude Code's requests byte-for-byte.

## The solution

This recipe puts {{site.ai_gateway}} between Claude Code and the Anthropic API:

* **Server-side provider credential.** The organization's Anthropic API key lives on {{site.ai_gateway}}. Developers never see it, and rotating it is one configuration change.
* **Revocable developer credentials.** Each developer gets an AI Consumer API key from Kong. Claude Code sends that key instead of an Anthropic key, and Kong attributes every request to the matching AI Consumer. Revoking a developer means deleting one AI Consumer credential.
* **Native Messages API forwarding.** The AI Model forwards Claude Code's Anthropic-format requests without translating them, so `anthropic-beta`, `anthropic-version`, and every request body field reach Anthropic unchanged.
* **One place for future policy.** Once traffic flows through Kong, you can add logging, rate limiting, and other AI Policies to the same AI Model without changing anything on developer machines.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant CC as Claude Code
    participant K as AI Gateway
    participant A as Anthropic API

    CC->>K: POST /coding-agents-anthropic/v1/messages (x-api-key: AI Consumer key)
    activate K
    K->>K: Key Auth AI Auth Strategy validates x-api-key (else 401)
    K->>K: AI Model strips path, AI Model Provider swaps in org Anthropic key
    K->>A: POST /v1/messages (x-api-key: org key, anthropic-* headers unchanged)
    activate A
    A-->>K: Messages API response (streamed)
    deactivate A
    K-->>CC: Response forwarded byte-for-byte
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
  - component: "Claude Code"
    responsibility: "Sends Anthropic Messages API requests to `ANTHROPIC_BASE_URL` with the AI Consumer key in the `x-api-key` header."
  - component: "Key Auth AI Auth Strategy"
    responsibility: "Validates the AI Consumer key, attaches the request to the AI Consumer, and removes the key before the request goes upstream."
  - component: "AI Consumer"
    responsibility: "Represents one developer. Its API key credential is the only secret the developer holds."
  - component: "AI Model"
    responsibility: "Exposes `/coding-agents-anthropic` and forwards Messages API traffic in passthrough format, without translation."
  - component: "AI Model Provider"
    responsibility: "Holds the organization's Anthropic API key and injects it into every upstream request."
  - component: "Anthropic API"
    responsibility: "Serves the model inference and bills the organization's account."
{% endtable %}

## How it works

When you run a prompt in Claude Code, the request goes through these steps:

1. **Claude Code sends the request to Kong.** With `ANTHROPIC_BASE_URL` set to `http://localhost:8000/coding-agents-anthropic`, Claude Code posts Messages API requests to `/coding-agents-anthropic/v1/messages`. Because `ANTHROPIC_API_KEY` holds the AI Consumer key, Claude Code sends that key in the `x-api-key` header.
1. **Kong authenticates the developer.** The AI Model lists the Key Auth AI Auth Strategy in `access.auth_strategies`. The AI Auth Strategy reads `x-api-key`, matches it against the AI Consumer credentials, and attaches the request to `coding-agents-consumer`. A missing or unknown key returns `401`.
1. **Kong removes the AI Consumer key.** With `hide_credentials` enabled, the AI Auth Strategy strips `x-api-key` from the request so the developer's Kong credential never reaches Anthropic.
1. **The AI Model forwards the request unchanged.** The AI Model uses the `passthrough` format, so Kong forwards the request and response bodies byte-for-byte. Kong strips the `/coding-agents-anthropic` prefix and sends the remaining path, `/v1/messages`, to the target's `upstream_url`.
1. **The AI Model Provider injects the organization's key.** The target references the AI Model Provider, which sets `x-api-key` to the organization's Anthropic API key. Anthropic authenticates the request against that key and bills the organization's account.
1. **The response streams back.** Anthropic streams the response back through Kong to Claude Code. Kong logs the request against the AI Consumer.

### Key Auth: AI Consumer authentication

The Key Auth AI Auth Strategy is what lets each developer hold a Kong credential instead of an Anthropic key. Claude Code sends whatever is in `ANTHROPIC_API_KEY` as the `x-api-key` header, so the AI Auth Strategy reads the AI Consumer key from that header. Kong attributes each request to the AI Consumer that owns the key, and deleting the credential revokes access without touching the organization's Anthropic key. Authentication in {{site.ai_gateway_name}} is an AI Auth Strategy that the AI Model references, not an AI Policy.

#### Configuration details

```yaml
ai_gateway_auth_strategies:
- ref: coding-agents-key-auth
  name: coding-agents-key-auth
  type: key-auth
  config:
    key_names:
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

**`key_names: [x-api-key]`**: The header Kong reads the AI Consumer key from. Claude Code sends `ANTHROPIC_API_KEY` as `x-api-key`, so this is the only name the AI Auth Strategy needs.

**`hide_credentials: true`**: Removes `x-api-key` from the request before Kong forwards it. The AI Model Provider then sets its own `x-api-key` with the organization's key, so Anthropic only ever sees the provider credential.

**`credentials[].api_key`**: The AI Consumer's key. The field is write-only, so it takes a `!secret` reference rather than a plain string.

**Bearer tokens instead of `x-api-key`**: If you set `ANTHROPIC_AUTH_TOKEN` instead of `ANTHROPIC_API_KEY`, Claude Code sends the key as `Authorization: Bearer <key>`. Key Auth doesn't strip a `Bearer` prefix, so that setup also needs a [Pre-Function](/ai-gateway/policies/pre-function/) Policy that copies the token into a header listed in `key_names`. The [Claude Desktop recipe](/cookbooks/coding-agents-claude-desktop/) shows that pattern.

**Scaling AI Consumers**: Add one AI Consumer per developer, each with its own credential. The recipe defines one AI Consumer for demonstration.

### AI Model and AI Model Provider: Messages API passthrough with credential injection

The AI Model gives Claude Code an Anthropic-compatible base URL, and the AI Model Provider supplies the credential Anthropic expects. The AI Model uses the `passthrough` format, which forwards request and response bodies byte-for-byte without schema validation. That addresses the compatibility problem: Claude Code's `anthropic-beta` values, `anthropic-version` header, and new body fields reach Anthropic exactly as Claude Code sent them, so features keep working as Claude Code releases add them. Passthrough still keeps AI Model Provider authentication, AI Consumer identity, and logging.

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

**`formats: [{type: passthrough}]`**: Forwards bodies without translation or validation. The `passthrough` format can't be combined with other formats and requires {{site.ai_gateway}} 2.2 or later. To accept OpenAI-format clients and translate them to Anthropic instead, use `formats: [{type: openai}]` with a model selector, as the [Cursor recipe](/cookbooks/coding-agents-cursor/) does.

**`route.paths` and `strip_path: true`**: Claude Code appends `/v1/messages` to `ANTHROPIC_BASE_URL`. Kong matches the `/coding-agents-anthropic` prefix, strips it, and forwards `/v1/messages` to the upstream.

**`route.methods`**: Claude Code sends `POST` for inference. `OPTIONS` allows preflight requests from browser-based clients.

**`targets[].config.upstream_url`**: The Anthropic API base URL. Kong appends the stripped request path to it.

**`targets[].config.version`**: The Anthropic API version, read from `ANTHROPIC_VERSION`. Claude Code also sends its own `anthropic-version` header, which passthrough forwards unchanged.

**`max_request_body_size: 16777216`**: Raises the request body limit to 16 MB from the 8 MB default. Claude Code requests carry the full conversation, tool definitions, and file contents, and long sessions can exceed the default.

**`response_streaming: allow`**: Lets Anthropic stream Server-Sent Events back to Claude Code, which renders tokens as they arrive.

**`logging.payloads: true`**: Captures full request and response bodies. Claude Code requests include source code and file contents, so payload logging can expose sensitive data in your logging destination. Set it to `false` if you only need usage metrics.

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. AI Vaults support HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store.

## Apply the Kong configuration

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply command can manage it. The `coding-agents-claude-code-recipe` namespace scopes every resource, so teardown removes only this recipe's configuration.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

The following configuration creates the AI Model Provider with the organization's Anthropic key, the Key Auth AI Auth Strategy, the demo AI Consumer, and the passthrough AI Model. `AI_GATEWAY_ID`, `ANTHROPIC_TOKEN`, `ANTHROPIC_VERSION`, and `CONSUMER_API_KEY` are already exported from the prerequisites.

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

## Try it out

Point Claude Code at the AI Model, send a request directly to confirm the gateway path, and then run a prompt from Claude Code. You also send a request without a key to see Key Auth reject it.

### Configure Claude Code

Set the base URL to the AI Model's path and use the AI Consumer key as the API key:

```bash
export ANTHROPIC_BASE_URL='http://localhost:8000/coding-agents-anthropic'
export ANTHROPIC_API_KEY="$CONSUMER_API_KEY"
unset ANTHROPIC_AUTH_TOKEN
```

Claude Code uses `ANTHROPIC_AUTH_TOKEN` before `ANTHROPIC_API_KEY` when both are set, so unset it to make sure Claude Code sends the AI Consumer key. Claude Code always uses `ANTHROPIC_API_KEY` in non-interactive mode (`-p`). In an interactive session, Claude Code asks once whether to use the key. Approve it.

### Send a request through the AI Model

Call the Messages API through Kong with the AI Consumer key:

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

### Send a prompt from Claude Code

Run a one-shot prompt with the environment from [Configure Claude Code](#configure-claude-code):

```bash
claude -p "Reply with exactly: claude-ok" --output-format text --max-turns 1
```

Claude Code prints the reply:

```text
claude-ok
```
{:.no-copy-code}

### What happened

1. **The direct request** carried the AI Consumer key in `x-api-key`. The Key Auth AI Auth Strategy matched it to `coding-agents-consumer`, removed it, and the AI Model Provider replaced it with the organization's Anthropic key. Anthropic answered with `smoke-ok`.
1. **The request without a key** failed at the Key Auth AI Auth Strategy with `401`. Kong never contacted Anthropic, so the organization's key was never used.
1. **The Claude Code prompt** followed the same path as the direct request. Claude Code appended `/v1/messages` to `ANTHROPIC_BASE_URL` and sent its own `anthropic-beta` and `anthropic-version` headers, which the passthrough AI Model forwarded unchanged. Claude Code never had access to the organization's Anthropic key.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `coding-agents-claude-code-recipe`. The recipe created an AI Model Provider (`coding-agents-anthropic-provider`) holding the organization's Anthropic key, an AI Model (`coding-agents-anthropic`) at `/coding-agents-anthropic`, a Key Auth AI Auth Strategy (`coding-agents-key-auth`), and an AI Consumer (`coding-agents-consumer`) with an API key credential, all scoped to this recipe by the kongctl namespace.

For request, token, and per-AI Consumer analysis across every {{site.ai_gateway}}, open the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

* **Issue one AI Consumer per developer.** Add an AI Consumer and credential for each developer so usage and revocation are per person. Distribute each key through your secrets tooling, and set `ANTHROPIC_BASE_URL` in a [Claude Code managed settings file](https://code.claude.com/docs/en/managed-settings) so developers don't configure it themselves.
* **Lock Claude Code to the gateway.** Set [`allowedProviders`](https://code.claude.com/docs/en/settings-reference#allowedproviders) to `["customEndpoint"]` in managed settings and pin `ANTHROPIC_BASE_URL` in the same file. Claude Code then refuses sessions pointed anywhere except your {{site.ai_gateway}}.
* **Connect Claude Desktop to the same pattern.** The [Claude Desktop recipe](/cookbooks/coding-agents-claude-desktop/) uses the same managed Anthropic key with Claude Desktop's third-party inference mode.
* **Replace API keys with SSO.** The [Claude Code SSO recipe](/cookbooks/claude-code-sso/) authenticates developers through Okta with an OpenID Connect AI Auth Strategy and routes them to model tiers by AI Consumer Group.
* **Move credentials into a vault.** Use [AI Vaults](/ai-gateway/entities/ai-vault/) to source the Anthropic key and AI Consumer credentials from HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, or the {{site.konnect_short_name}} Config Store.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-claude-code-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
