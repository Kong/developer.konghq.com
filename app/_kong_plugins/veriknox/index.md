---
title: 'VeriKnox'
name: 'VeriKnox'

content_type: plugin

publisher: veriknox
description: "Cryptographically signed audit receipts for every AI interaction passing through your gateway, with dual classical and post-quantum signatures."

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

third_party: true
support_url: https://veriknox.ai

icon: veriknox.svg

min_version:
  gateway: '3.14'

tags:
  - ai
  - security

search_aliases:
  - veriknox
  - veriknox-plugin
  - ai agent receipts
  - post-quantum signatures
  - tamper-evident

related_resources:
  - text: VeriKnox documentation
    url: https://veriknox.ai
---

Use the VeriKnox plugin (`veriknox-plugin`) to attach cryptographically signed audit receipts to every AI interaction passing through {{site.base_gateway}}.
The plugin intercepts LLM inference, MCP, and A2A requests and responses, applies business policy, and forwards tamper-evident receipts to VeriKnox Hub.
This gives your organization verifiable proof of what each AI agent did, whether it was authorized to do so, when it happened, and on whose behalf.

AI agents increasingly call LLMs, MCP servers, and each other through a shared gateway, but standard access logs don't prove what payload was sent or what the model returned.
VeriKnox addresses this by embedding ED25519 and ML-DSA-65 (NIST FIPS 204, post-quantum) signatures on every receipt.
The signatures are resistant to both classical and future quantum attacks, and no private key material ever leaves the Rust signing library on the data plane.

Benefits of using the VeriKnox plugin:

- Tamper-evident proof of every AI interaction: signed receipts record what the agent sent, what the model returned, who authorized it, and when.
- Dual classical and post-quantum signatures: each receipt carries both an ED25519 signature (fast, verifiable today) and an ML-DSA-65 signature (NIST FIPS 204, resistant to quantum adversaries).
- Policy enforcement at the gateway: VeriKnox Hub evaluates each interaction against your business policy and can block non-compliant requests before they reach the upstream.
- Broad protocol coverage: supports OpenAI Chat Completions, OpenAI Responses, Anthropic Claude Messages, OpenRouter, Google Gemini, MCP tool calls, and A2A JSON-RPC operations including streaming.
- No credential exposure: the agent passphrase is resolved from a Kong Vault reference at runtime and never written to disk in plain text.

## How it works

Every {{site.base_gateway}} data plane enrolled with VeriKnox Hub holds an encrypted identity bundle on disk.
When the plugin is enabled on a Route, it decrypts this identity using the `agent_passphrase` vault reference, then acts in the Kong request-lifecycle `access` phase.

In the `access` phase, the plugin:
1. Parses the request body according to the configured `endpoint.specification` (OpenAI, Anthropic, MCP, A2A, and so on).
2. Evaluates the request against VeriKnox Hub policy. If the policy blocks it, the plugin returns an error and nothing is forwarded upstream.
3. Signs a receipt with both ED25519 and ML-DSA-65 signatures and forwards it to VeriKnox Hub.
4. Strips VeriKnox-specific agent headers (`x-veriknox-agent-id`, `x-veriknox-api-key`, `x-veriknox-agent-auth`) before proxying the request upstream.

After the upstream responds, the plugin signs and forwards a response receipt to VeriKnox Hub as well.

{% mermaid %}
sequenceDiagram
    autonumber
    participant A as AI Agent
    participant K as Kong Gateway<br/>veriknox-plugin
    participant H as VeriKnox Hub
    participant U as Upstream<br/>LLM / MCP / A2A

    A->>K: Request with agent headers
    Note over K: access phase
    K->>H: Policy check + signed request receipt
    alt Policy blocks request
        H-->>K: Deny
        K-->>A: 403 Forbidden
    else Policy allows request
        H-->>K: Allow
        K->>U: Proxied request (agent headers stripped)
        U-->>K: Response
        K->>H: Signed response receipt
        K-->>A: Response
    end
{% endmermaid %}

### Plugin priority

{{site.base_gateway}} runs plugins in descending priority order (higher number runs first).
The VeriKnox plugin must run after authentication plugins (which sit at approximately 1001-1005), so its priority must be lower.

Where you place the VeriKnox plugin relative to AI Gateway plugins determines what gets signed:

{% table %}
columns:
  - title: Priority range
    key: range
  - title: What the plugin signs
    key: signs
rows:
  - range: "785-999"
    signs: Original client payload, before any AI plugin transformation
  - range: Below 765
    signs: AI-modified payload, what actually reached the LLM and what it returned
{% endtable %}

VeriKnox recommends a priority of approximately 700.
Use 785-999 if you need to sign the raw user intent before any model routing or prompt injection by AI plugins.

### Caller identity

The VeriKnox plugin doesn't authenticate clients itself.
It reads caller context from VeriKnox-specific request headers:

{% table %}
columns:
  - title: Header
    key: header
  - title: Purpose
    key: purpose
rows:
  - header: "`x-veriknox-agent-id`"
    purpose: Caller-provided agent identifier
  - header: "`x-veriknox-api-key`"
    purpose: Caller-provided API key
  - header: "`x-veriknox-agent-auth`"
    purpose: "Combined credentials in the form `agent_id;api_key`"
{% endtable %}

Use the `pre-function` plugin to copy these headers into shared request context and remove them before proxying upstream:

```yaml
plugins:
  - name: pre-function
    config:
      access:
        - |-
          kong.ctx.shared.veriknox_agent_auth = kong.request.get_header("x-veriknox-agent-auth")
          kong.ctx.shared.veriknox_agent_id = kong.request.get_header("x-veriknox-agent-id")
          kong.ctx.shared.veriknox_api_key = kong.request.get_header("x-veriknox-api-key")
          kong.service.request.clear_header("x-veriknox-agent-auth")
          kong.service.request.clear_header("x-veriknox-agent-id")
          kong.service.request.clear_header("x-veriknox-api-key")
```

If no agent ID is supplied, the plugin generates a traceable ID in the form `http-client:<ip-address>`.
This supports audit tracing but is not an authenticated identity.
In production, always pair the VeriKnox plugin with a Kong authentication plugin such as `key-auth` or `jwt` to provide a verified agent identity.

## Install the VeriKnox plugin

The VeriKnox plugin ships baked into a custom {{site.base_gateway}} image distributed from the VeriKnox ECR registry.
It's not available as a standalone LuaRock.

### Prerequisites

Before installing the plugin, you need:

- A VeriKnox account and a **site enrollment token** to register the data plane identity with VeriKnox Hub.
- AWS credentials with pull access to the VeriKnox ECR registry (`510978032592.dkr.ecr.us-east-1.amazonaws.com`).
- A Kong Vault to store the identity passphrase. VeriKnox recommends a {{site.konnect_short_name}} Config Store-backed vault, but any [vault backend {{site.base_gateway}} supports](/gateway/entities/vault/) works.

### Enroll the data plane identity

Before the plugin can sign receipts, each data plane must be enrolled with VeriKnox Hub.
Enrollment generates ED25519 and ML-DSA-65 keypairs, encrypts the private keys with the identity passphrase, and registers the public keys with VeriKnox Hub.

Run enrollment as a one-shot init container using the `veriknox/kong-init-identity` image:

```yaml
services:
  kong-init:
    image: 510978032592.dkr.ecr.us-east-1.amazonaws.com/veriknox/kong-init-identity:0.0.9
    restart: "no"
    environment:
      KONG_VERIKNOX_IDENTITY_ENROLLMEN_TOKEN: ${VERIKNOX_ENROLLMENT_TOKEN}
      KONG_VERIKNOX_IDENTITY_PASSPHRASE: ${VERIKNOX_IDENTITY_PASSPHRASE}
      KONG_VERIKNOX_IDENTITY_BASE_URL: https://hub.veriknox.ai
      KONG_VERIKNOX_IDENTITY_STATE_DIR: /data
    volumes:
      - kong-init-volume:/data
```

After enrollment, the encrypted identity bundle is written to `KONG_VERIKNOX_IDENTITY_STATE_DIR` (default: `/data`):

```
/data/
└── identity/
    ├── identity.kdf.json
    ├── identity.keys.enc
    └── identity.meta.json
```
{:.no-copy-code}

### Installation steps

{% navtabs 'install' %}
{% navtab "Docker Compose" %}

1. Authenticate to the VeriKnox ECR registry:

   ```bash
   aws ecr get-login-password --region us-east-1 \
     | docker login --username AWS --password-stdin \
       510978032592.dkr.ecr.us-east-1.amazonaws.com
   ```

1. Configure your Compose file to run `kong-init` before starting the data plane.
   Mount the same volume at `KONG_VERIKNOX_IDENTITY_STATE_DIR` so the data plane loads the enrolled identity:

   ```yaml
   services:
     kong-dp-0:
       image: 510978032592.dkr.ecr.us-east-1.amazonaws.com/veriknox/kong-gateway:3.14-0.0.9
       environment:
         KONG_VERIKNOX_IDENTITY_STATE_DIR: /data
         KONG_VERIKNOX_HUB_BASE_URL: https://hub.veriknox.ai
         KONG_NGINX_MAIN_ENV: "KONG_VERIKNOX_LOG_PRINT_ALL; env KONG_VERIKNOX_IDENTITY_STATE_DIR; env KONG_VERIKNOX_HUB_BASE_URL"
       depends_on:
         kong-init:
           condition: service_completed_successfully
       volumes:
         - kong-init-volume:/data
   ```

1. Store the identity passphrase in a Kong Vault and reference it as `{vault://...}` in the plugin configuration.
   The passphrase must never be written to disk in plain text.

{% endnavtab %}
{% navtab "{{site.konnect_short_name}}" %}

1. Obtain the `schema.lua` file from your VeriKnox Technical Account Manager.

1. Upload the `veriknox-plugin` schema to your {{site.konnect_short_name}} control plane:
   1. In the {{site.konnect_short_name}} menu, navigate to **Plugins**.
   1. Click **Custom Plugins**.
   1. Upload `schema.lua`.
   1. Click **Save**.

1. Create a {{site.konnect_short_name}} Vault backed by a Config Store to hold the identity passphrase.
   Use the {{site.konnect_short_name}} API to create a [config store](/gateway/vault/konnect-config-store/), then write the passphrase secret.
   The plugin resolves `{vault://veriknox/VERIKNOX_IDENTITY_PASSPHRASE}` at runtime.

1. Start your data plane nodes using the VeriKnox gateway image, with the enrolled identity volume mounted:

   ```yaml
   image: 510978032592.dkr.ecr.us-east-1.amazonaws.com/veriknox/kong-gateway:3.14-0.0.9
   ```

   Set the following environment variables on each data plane node:

   ```bash
   KONG_VERIKNOX_IDENTITY_STATE_DIR=/data
   KONG_VERIKNOX_HUB_BASE_URL=https://hub.veriknox.ai
   KONG_NGINX_MAIN_ENV="env KONG_VERIKNOX_IDENTITY_STATE_DIR; env KONG_VERIKNOX_HUB_BASE_URL"
   ```

{:.info}
> **Note**: The data plane must complete enrollment (via `kong-init`) before it can sign receipts.
> Use `depends_on` with `condition: service_completed_successfully` in Docker Compose, or an init container in Kubernetes, to enforce this ordering.

{% endnavtab %}
{% endnavtabs %}

## Enable the plugin

After installing the plugin, enable it on the Routes you want to audit.
See the following examples:

- [LLM inference](/plugins/veriknox/examples/llm-inference/): Sign receipts for OpenAI-compatible LLM inference traffic.
- [MCP tool call](/plugins/veriknox/examples/mcp-tool-call/): Sign receipts for Model Context Protocol tool-call requests.
