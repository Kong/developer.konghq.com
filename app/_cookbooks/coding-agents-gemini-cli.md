---
title: "AI Tool Integration: Gemini CLI"
description: Point Gemini CLI at {{site.ai_gateway_name}} with a managed Gemini AI Model Provider key.
url: "/cookbooks/coding-agents-gemini-cli/"
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
  - gemini

hint: "Requires Kong AI Gateway 2.2+, a Google AI Studio API key, and the Gemini CLI."
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
           export KONNECT_CONTROL_PLANE_NAME='coding-agents-gemini-cli-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `coding-agents-gemini-cli-recipe`, a local data plane connected to it, and prints `export` lines (including `AI_GATEWAY_ID`). Paste those into your shell when prompted.

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
        Export a Google AI Studio API key for the AI Model Provider:

        ```bash
        export GEMINI_TOKEN='YOUR-GEMINI-API-KEY'
        ```
    - title: AI Consumer API Key
      content: |
        Generate the API key that the demo AI Consumer sends to Kong. Client tools use this key instead of the provider key:

        ```bash
        export CONSUMER_API_KEY="coding-agents-demo-$(openssl rand -hex 8)"
        echo "$CONSUMER_API_KEY"
        ```
overview: |
  Use Gemini CLI when developers already run Google's CLI and you want egress through Kong. Gemini CLI sends the client key as `x-goog-api-key`. The Key Auth AI Auth Strategy lists that header name, then the AI Model Provider replaces it with the real Gemini key.
---

## The problem

Gemini CLI calls the Gemini API directly from each developer's machine. That works for one person with one key, but an organization that wants to give a whole team Gemini CLI on a shared Google AI Studio account runs into several problems:

* **Provider keys end up on laptops.** The [Gemini CLI authentication guide](https://github.com/google-gemini/gemini-cli/blob/main/docs/get-started/authentication.mdx) has each developer create an API key in Google AI Studio and export it as `GEMINI_API_KEY`. Gemini CLI sends that key straight to the Gemini API. Every machine holds a credential that bills the organization's account, a leaked key works anywhere, and offboarding one developer means finding and revoking the right key.
* **Google's own guidance warns against client-side keys.** The [Gemini API key documentation](https://aistudio.google.com/docs/api-key) says to treat the key like a password, never check it into source control, and use a backend proxy server instead of hardcoding it in client applications. A key exported in every developer's shell profile or `.env` file is the opposite of that.
* **There is no central place to apply policy.** Without a gateway, there is no single point to attribute usage to a developer, enforce rate limits, or log every request for compliance. Each of those has to be solved per machine or in the Google Cloud console that owns the key.
* **A gateway has to speak the Gemini API.** Gemini CLI doesn't send OpenAI-format requests. It calls Gemini's native `generateContent` and `streamGenerateContent` endpoints and sends its key in the `x-goog-api-key` header. A gateway that expects a different wire format or a `Bearer` token can't sit in front of it without rewriting requests.

The root issue is that the credential, the policy, and the wire-format burden all sit on the client. Teams need one server-side point that holds the organization's Gemini API key, authenticates developers with credentials it can revoke, and forwards Gemini CLI's requests without translating them.

## The solution

This recipe puts {{site.ai_gateway}} between Gemini CLI and the Gemini API:

* **Server-side provider credential.** The organization's Google AI Studio API key lives on {{site.ai_gateway}}. Developers never see it, and rotating it is one configuration change.
* **Revocable developer credentials.** Each developer gets an AI Consumer API key from Kong. Gemini CLI sends that key in `x-goog-api-key` instead of a Google key, and Kong attributes every request to the matching AI Consumer. Revoking a developer means deleting one AI Consumer credential.
* **Native Gemini API forwarding.** The AI Model forwards Gemini CLI's requests without translating them, so every `generateContent` request body field reaches the Gemini API unchanged.
* **One place for future policy.** Once traffic flows through Kong, you can add logging, rate limiting, and other AI Policies to the same AI Model without changing anything on developer machines.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant G as Gemini CLI
    participant K as AI Gateway
    participant API as Gemini API

    G->>K: POST /coding-agents-gemini/v1beta/models/{model}:streamGenerateContent (x-goog-api-key: AI Consumer key)
    activate K
    K->>K: Key Auth AI Auth Strategy validates x-goog-api-key (else 401)
    K->>K: AI Model strips path, AI Model Provider swaps in org Gemini key
    K->>API: POST /v1beta/models/{model}:streamGenerateContent (x-goog-api-key: org key)
    activate API
    API-->>K: Gemini API response (streamed)
    deactivate API
    K-->>G: Response forwarded byte-for-byte
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
  - component: "Gemini CLI"
    responsibility: "Sends native Gemini API requests to `GOOGLE_GEMINI_BASE_URL` with the AI Consumer key in the `x-goog-api-key` header."
  - component: "Key Auth AI Auth Strategy"
    responsibility: "Validates the AI Consumer key, attaches the request to the AI Consumer, and removes the key before the request goes upstream."
  - component: "AI Consumer"
    responsibility: "Represents one developer. Its API key credential is the only secret the developer holds."
  - component: "AI Model"
    responsibility: "Exposes `/coding-agents-gemini` and forwards Gemini API traffic in passthrough format, without translation."
  - component: "AI Model Provider"
    responsibility: "Holds the organization's Google AI Studio API key and injects it into every upstream request."
  - component: "Gemini API"
    responsibility: "Serves the model inference and bills the organization's account."
{% endtable %}

## How it works

When you run a prompt in Gemini CLI, the request goes through these steps:

1. **Gemini CLI sends the request to Kong.** With `GOOGLE_GEMINI_BASE_URL` set to `http://localhost:8000/coding-agents-gemini`, Gemini CLI sends its Gemini API requests to paths under `/coding-agents-gemini`, such as `/coding-agents-gemini/v1beta/models/<model>:streamGenerateContent`. Because `GEMINI_API_KEY` holds the AI Consumer key, Gemini CLI sends that key in the `x-goog-api-key` header.
1. **Kong authenticates the developer.** The AI Model lists the Key Auth AI Auth Strategy in `access.auth_strategies`. The AI Auth Strategy reads `x-goog-api-key`, matches it against the AI Consumer credentials, and attaches the request to `coding-agents-consumer`. A missing or unknown key returns `401`.
1. **Kong removes the AI Consumer key.** With `hide_credentials` enabled, the AI Auth Strategy strips `x-goog-api-key` from the request so the developer's Kong credential never reaches Google.
1. **The AI Model forwards the request unchanged.** The AI Model uses the `passthrough` format, so Kong forwards the request and response bodies byte-for-byte. Kong strips the `/coding-agents-gemini` prefix and sends the remaining path, for example `/v1beta/models/<model>:streamGenerateContent`, to the target's `upstream_url`.
1. **The AI Model Provider injects the organization's key.** The target references the AI Model Provider, which sets `x-goog-api-key` to the organization's Google AI Studio API key. The Gemini API authenticates the request against that key and bills the organization's account.
1. **The response streams back.** The Gemini API streams the response back through Kong to Gemini CLI. Kong logs the request against the AI Consumer.

### Key Auth: AI Consumer authentication

The Key Auth AI Auth Strategy is what lets each developer hold a Kong credential instead of a Google AI Studio key. Gemini CLI sends whatever is in `GEMINI_API_KEY` as the `x-goog-api-key` header, so the AI Auth Strategy reads the AI Consumer key from that header. No header rewrite is needed, because Gemini CLI doesn't use a `Bearer` token. Kong attributes each request to the AI Consumer that owns the key, and deleting the credential revokes access without touching the organization's Gemini key. Authentication in {{site.ai_gateway_name}} is an AI Auth Strategy that the AI Model references, not an AI Policy.

#### Configuration details

```yaml
ai_gateway_auth_strategies:
- ref: coding-agents-key-auth
  name: coding-agents-key-auth
  type: key-auth
  config:
    key_names:
    - x-goog-api-key
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

**`key_names: [x-goog-api-key]`**: The header Kong reads the AI Consumer key from. Gemini CLI sends `GEMINI_API_KEY` as `x-goog-api-key`, so this is the only name the AI Auth Strategy needs.

**`hide_credentials: true`**: Removes `x-goog-api-key` from the request before Kong forwards it. The AI Model Provider then sets its own `x-goog-api-key` with the organization's key, so the Gemini API only ever sees the provider credential.

**`credentials[].api_key`**: The AI Consumer's key. The field is write-only, so it takes a `!secret` reference rather than a plain string.

**Bearer-token clients**: Key Auth doesn't strip a `Bearer` prefix. If you put an OpenAI-compatible client in front of the same pattern, it needs a [Pre-Function](/ai-gateway/policies/pre-function/) Policy that copies the token into a header listed in `key_names`. The [Codex recipe](/cookbooks/coding-agents-codex/) shows that pattern.

**Scaling AI Consumers**: Add one AI Consumer per developer, each with its own credential. The recipe defines one AI Consumer for demonstration.

### AI Model and AI Model Provider: Gemini API passthrough with credential injection

The AI Model gives Gemini CLI a Gemini-compatible base URL, and the AI Model Provider supplies the credential the Gemini API expects. The AI Model uses the `passthrough` format, which forwards request and response bodies byte-for-byte without schema validation. That addresses the wire-format problem: Gemini CLI's native `generateContent` requests, including tool declarations and generation settings, reach the Gemini API exactly as Gemini CLI sent them. Passthrough still keeps AI Model Provider authentication, AI Consumer identity, and logging.

#### Configuration details

```yaml
ai_gateway_model_providers:
- ref: coding-agents-gemini-provider
  name: coding-agents-gemini-provider
  type: gemini
  config:
    auth:
      type: basic
      headers:
      - name: x-goog-api-key
        value: !secret {source: !env 'GEMINI_TOKEN'}
ai_gateway_models:
- ref: coding-agents-gemini
  name: coding-agents-gemini
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
```
{:.no-copy-code}

**`config.auth.headers`** (AI Model Provider): The header Kong adds to every upstream request. The Gemini API [authenticates API keys](https://aistudio.google.com/docs/api-key) through `x-goog-api-key`, so the AI Model Provider sets that header to the organization's key.

**`formats: [{type: passthrough}]`**: Forwards bodies without translation or validation. The `passthrough` format can't be combined with other formats and requires {{site.ai_gateway}} 2.2 or later. To accept OpenAI-format clients instead, use `formats: [{type: openai}]` with a model selector, as the [Cursor recipe](/cookbooks/coding-agents-cursor/) does.

**`route.paths` and `strip_path: true`**: Gemini CLI appends the Gemini API path, such as `/v1beta/models/<model>:streamGenerateContent`, to `GOOGLE_GEMINI_BASE_URL`. Kong matches the `/coding-agents-gemini` prefix, strips it, and forwards the rest of the path to the upstream.

**`route.methods`**: Gemini CLI sends `POST` for inference. `GET` lets read-only Gemini API requests through the same path. `OPTIONS` allows preflight requests from browser-based clients.

**`targets[].config.upstream_url`**: The Gemini API base URL. Kong appends the stripped request path to it, so the API version in the path comes from the client.

**`max_request_body_size: 16777216`**: Raises the request body limit to 16 MB from the 8 MB default. Gemini CLI requests carry the full conversation, tool declarations, and file contents, and long sessions can exceed the default.

**`response_streaming: allow`**: Lets the Gemini API stream responses back to Gemini CLI, which renders tokens as they arrive.

**`logging.payloads: true`**: Captures full request and response bodies. Gemini CLI requests include source code and file contents, so payload logging can expose sensitive data in your logging destination. Set it to `false` if you only need usage metrics.

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. AI Vaults support HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store.

## Apply the Kong configuration

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply command can manage it. The `coding-agents-gemini-cli-recipe` namespace scopes every resource, so teardown removes only this recipe's configuration.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

The following configuration creates the AI Model Provider with the organization's Gemini API key, the Key Auth AI Auth Strategy, the demo AI Consumer, and the passthrough AI Model. `AI_GATEWAY_ID`, `GEMINI_TOKEN`, and `CONSUMER_API_KEY` are already exported from the prerequisites.

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

## Try it out

Point Gemini CLI at the AI Model, send a request directly to confirm the gateway path, and then run a prompt from Gemini CLI. You also send a request without a key to see Key Auth reject it.

### Configure Gemini CLI

Set the base URL to the AI Model's path and use the AI Consumer key as the Gemini API key:

```bash
export GOOGLE_GEMINI_BASE_URL='http://localhost:8000/coding-agents-gemini'
export GEMINI_API_KEY="$CONSUMER_API_KEY"
```

[`GOOGLE_GEMINI_BASE_URL`](https://github.com/google-gemini/gemini-cli/blob/main/docs/reference/configuration.md#environment-variables-and-env-files) overrides the default base URL for Gemini API requests. Gemini CLI requires HTTPS for this URL unless it points to `localhost`, so the local data plane's HTTP port works here. Put the AI Consumer key in `GEMINI_API_KEY`, not the Google AI Studio key.

### Send a request through the AI Model

Call the Gemini API `generateContent` endpoint through Kong with the AI Consumer key:

```bash
curl -sS -X POST "http://localhost:8000/coding-agents-gemini/v1beta/models/gemini-2.5-flash:generateContent" \
  -H "Content-Type: application/json" \
  -H "x-goog-api-key: ${CONSUMER_API_KEY}" \
  -d '{
    "contents": [{"role": "user", "parts": [{"text": "Reply with exactly: smoke-ok"}]}]
  }'
```

Kong returns the Gemini API response unchanged. The response looks similar to this, abbreviated, with different IDs and token counts:

```json
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

### Send a request without the AI Consumer key

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

Run a one-shot prompt with the environment from [Configure Gemini CLI](#configure-gemini-cli):

```bash
gemini -p "Reply with exactly: gemini-ok" --skip-trust -y -m gemini-2.5-flash
```

`-p` runs Gemini CLI in non-interactive mode, `--skip-trust` trusts the current folder for this session so the folder trust check doesn't stop a headless run, `-y` auto-approves tool calls, and `-m` selects the model. See the [Gemini CLI reference](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/cli-reference.md) for these flags.

Gemini CLI prints `gemini-ok`.

### What happened

1. **The direct request** carried the AI Consumer key in `x-goog-api-key`. The Key Auth AI Auth Strategy matched it to `coding-agents-consumer`, removed it, and the AI Model Provider replaced it with the organization's Gemini API key. The Gemini API answered with `smoke-ok`.
1. **The request without a key** failed at the Key Auth AI Auth Strategy with `401`. Kong never contacted the Gemini API, so the organization's key was never used.
1. **The Gemini CLI prompt** followed the same path as the direct request. Gemini CLI appended the Gemini API path to `GOOGLE_GEMINI_BASE_URL` and sent `GEMINI_API_KEY` as `x-goog-api-key`, and the passthrough AI Model forwarded the request body unchanged. Gemini CLI never had access to the organization's Gemini API key.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `coding-agents-gemini-cli-recipe`. The recipe created an AI Model Provider (`coding-agents-gemini-provider`) holding the organization's Gemini API key, an AI Model (`coding-agents-gemini`) at `/coding-agents-gemini`, a Key Auth AI Auth Strategy (`coding-agents-key-auth`), and an AI Consumer (`coding-agents-consumer`) with an API key credential, all scoped to this recipe by the kongctl namespace.

For request, token, and per-AI Consumer analysis across every {{site.ai_gateway}}, open the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

* **Issue one AI Consumer per developer.** Add an AI Consumer and credential for each developer so usage and revocation are per person. Distribute each key through your secrets tooling. Gemini CLI also [loads environment variables from `.env` files](https://github.com/google-gemini/gemini-cli/blob/main/docs/reference/configuration.md#environment-variables-and-env-files), so `GOOGLE_GEMINI_BASE_URL` and `GEMINI_API_KEY` can live in a `.gemini/.env` file instead of each shell profile.
* **Manage Gemini CLI centrally.** The [Gemini CLI enterprise guide](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/enterprise.md) describes a system settings file that overrides user and project settings, and a wrapper script that enforces it. Use it to standardize Gemini CLI configuration across developer machines.
* **Connect other tools to the same pattern.** The [Claude Code](/cookbooks/coding-agents-claude-code/) and [Codex CLI](/cookbooks/coding-agents-codex/) recipes apply the same managed-key pattern with passthrough AI Models for Anthropic and OpenAI. For OpenAI-compatible tools that use an `openai` format AI Model, see the [Cursor recipe](/cookbooks/coding-agents-cursor/).
* **Move credentials into a vault.** Use [AI Vaults](/ai-gateway/entities/ai-vault/) to source the Gemini API key and AI Consumer credentials from HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, or the {{site.konnect_short_name}} Config Store.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='coding-agents-gemini-cli-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
