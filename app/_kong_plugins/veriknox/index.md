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

The [VeriKnox](https://veriknox.ai) plugin (`veriknox-plugin`) lets you attach cryptographically signed audit receipts to every AI interaction passing through {{site.base_gateway}}.
The plugin intercepts LLM inference, MCP, and A2A requests and responses, applies business policy, and forwards tamper-evident receipts to VeriKnox Hub.
This gives your organization verifiable proof of what each AI agent did, whether it was authorized to do so, when it happened, and on whose behalf.

AI agents increasingly call LLMs, MCP servers, and each other through a shared gateway, but standard access logs don't prove what payload was sent or what the model returned.
VeriKnox addresses this by embedding ED25519 and ML-DSA-65 (NIST FIPS 204, post-quantum) signatures on every receipt.
The signatures are resistant to both classical and future quantum attacks, and no private key material ever leaves the Rust signing library on the data plane.

Benefits of using the VeriKnox plugin:

* **Tamper-evident proof of every AI interaction:** Signed receipts record what the agent sent, what the model returned, who authorized it, and when.
* **Dual classical and post-quantum signatures:** Each receipt carries both an ED25519 signature (fast, verifiable today) and an ML-DSA-65 signature (NIST FIPS 204, resistant to quantum adversaries).
* **Policy enforcement at the gateway:** VeriKnox Hub evaluates each interaction against your business policy and can block non-compliant requests before they reach the upstream.
* **Broad protocol coverage:** Supports OpenAI Chat Completions, OpenAI Responses, Anthropic Claude Messages, OpenRouter, Google Gemini, MCP tool calls, and A2A JSON-RPC operations including streaming.
* **No credential exposure:** The agent passphrase is resolved from a [Kong Vault](/gateway/entities/vault/) reference at runtime and never written to disk in plain text.

## How it works

Every {{site.base_gateway}} data plane enrolled with VeriKnox Hub holds an encrypted identity bundle on disk.
When the VeriKnox plugin is enabled on a Route, it decrypts this identity using the `agent_passphrase` Vault reference, then acts in the {{site.base_gateway}} request lifecycle `access` phase.

In the `access` phase, the plugin:
1. Parses the request body according to the configured `endpoint.specification` (OpenAI, Anthropic, MCP, A2A, and so on).
1. Evaluates the request against VeriKnox Hub policy.
  * If the policy blocks it, the plugin returns an error and nothing is forwarded upstream.
  * If the policy allows it, the plugin signs a receipt with both ED25519 and ML-DSA-65 signatures and forwards it to VeriKnox Hub.
1. Strips VeriKnox-specific agent headers (`x-veriknox-agent-id`, `x-veriknox-api-key`, `x-veriknox-agent-auth`) before proxying the request upstream.

After the upstream responds, the plugin signs and forwards a response receipt to VeriKnox Hub as well.

{% mermaid %}
sequenceDiagram
    autonumber
    participant A as AI Agent
    participant K as {{site.base_gateway}}<br/>VeriKnox plugin
    participant H as VeriKnox Hub
    participant U as Upstream<br/>LLM / MCP / A2A

    A->>K: Request with agent headers
    Note over K: access phase
    K->>H: Policy check + signed request receipt
    alt If the policy blocks the request
        H-->>K: Deny
        K-->>A: 403 Forbidden
    else If the policy allows the request
        H-->>K: Allow
        K->>U: Proxied request (agent headers stripped)
        U-->>K: Response
        K->>H: Signed response receipt
        K-->>A: Response
    end
{% endmermaid %}

### Supported endpoint specifications

The [`endpoint.specification`](/plugins/veriknox/reference/#schema--config-endpoint-specification) field tells the plugin which protocol and API format to expect.
Set it to one of the following values:

{% table %}
columns:
  - title: Specification value
    key: spec
  - title: Protocol
    key: protocol
rows:
  - spec: "`Inference:OpenAI/Chat_Completions`"
    protocol: "OpenAI `/v1/chat/completions`"
  - spec: "`Inference:OpenAI/Responses`"
    protocol: "OpenAI `/v1/responses`"
  - spec: "`Inference:Claude/Messages`"
    protocol: "Anthropic Claude `/v1/messages`"
  - spec: "`Inference:OpenRouter/Chat_Completions`"
    protocol: "OpenRouter `api/v1/chat/completions`"
  - spec: "`Inference:Google/Gemini_Generate_Content`"
    protocol: "Google Gemini `/v1beta/models/{model}:generateContent` (and `:streamGenerateContent`)"
  - spec: "`MCP`"
    protocol: "Model Context Protocol tool-call requests (JSON-RPC v2)"
  - spec: "`A2A`"
    protocol: "Agent2Agent JSON-RPC operations, including streaming (`text/event-stream`)"
{% endtable %}

### Plugin priority

{{site.base_gateway}} runs plugins in descending [priority order](/gateway/entities/plugin/#plugin-priority) (higher number runs first).
The VeriKnox plugin must run after authentication plugins (which sit at approximately 1001-1005), so its priority must be lower.
You can control this using [dynamic plugin ordering](/gateway/entities/plugin/#dynamic-plugin-ordering).

Where you place the VeriKnox plugin relative to {{site.ai_gateway_name}} plugins determines what gets signed:

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

The VeriKnox plugin doesn't authenticate clients to {{site.base_gateway}}.
If you want receipts to identify the calling agent, configure an authentication plugin or another gateway mechanism separately, then pass the caller context to the VeriKnox plugin through VeriKnox-specific request headers:

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

Use the [Pre-Function](/plugins/pre-function/) plugin to copy these headers into shared request context and remove them before proxying upstream:

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

If no agent ID is supplied through `x-veriknox-agent-id` or `x-veriknox-agent-auth`, the plugin generates a traceable ID in the form `http-client:<ip-address>`.
It uses the forwarded client IP when {{site.base_gateway}} trusts the proxy, otherwise it uses the direct client IP.
This fallback supports audit tracing, but it is not an authenticated identity.

In production, each AI agent (HTTP client) must authenticate with {{site.base_gateway}} before sending traffic.
{{site.base_gateway}} supports this through [authentication plugins](/plugins/?category=authentication) such as [Key Auth](/plugins/key-auth/) or [JWT](/plugins/jwt/).
The VeriKnox plugin should not handle authentication itself.

Without a paired authentication plugin, {{site.base_gateway}} may accept LLM inference, MCP, and A2A traffic without authentication: it allows each HTTP request through, and the VeriKnox plugin may then block it based on policy.
That downstream step is authorization without prior authentication.
Run a separate {{site.base_gateway}} authentication plugin or dedicated service for AI agents alongside the VeriKnox plugin to provide `x-veriknox-agent-id`.

### Logging

Log verbosity is controlled by {{site.base_gateway}}'s `KONG_LOG_LEVEL` environment variable.

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Output per request
    key: output
rows:
  - setting: "`KONG_LOG_LEVEL=info` (default)"
    output: "One `veriknox` log line per request (or `policy_block` / `error` on failure)"
  - setting: "`KONG_LOG_LEVEL=debug`"
    output: "That summary plus 1-2 plugin lifecycle debug lines"
  - setting: "`KONG_VERIKNOX_LOG_PRINT_ALL=on` (with `debug`)"
    output: "Additional Hub client/server debug lines"
{% endtable %}

Set `KONG_VERIKNOX_LOG_PRINT_ALL` in `KONG_NGINX_MAIN_ENV` alongside the other VeriKnox environment variables so Nginx workers can read it:

```bash
KONG_NGINX_MAIN_ENV="KONG_VERIKNOX_LOG_PRINT_ALL; env KONG_VERIKNOX_IDENTITY_STATE_DIR; env KONG_VERIKNOX_HUB_BASE_URL"
```

## Install the VeriKnox plugin

The VeriKnox plugin ships as part of a custom {{site.base_gateway}} image distributed from the VeriKnox ECR registry.
It's not available as a standalone LuaRock.

{:.info}
> **Note**: If you want to try the plugin without installing it against your own data planes, see the [Quickstart](#quickstart) for a self-contained Docker Compose environment with sample data planes and upstream services.

### Prerequisites

Before installing the plugin, you need:

* A VeriKnox account and a site enrollment token to register the data plane identity with VeriKnox Hub.
* AWS credentials with pull access to the VeriKnox ECR registry (`510978032592.dkr.ecr.us-east-1.amazonaws.com`).
* A [Kong Vault](/gateway/entities/vault/) to store the identity passphrase. VeriKnox recommends using a [{{site.konnect_short_name}} Config Store-backed vault](/gateway/entities/vault/konnect-config-store/).

### Enroll the data plane identity

Before the plugin can sign receipts, each data plane must be enrolled with VeriKnox Hub.
Enrollment generates ED25519 and ML-DSA-65 key pairs, encrypts the private keys with the identity passphrase, and registers the public keys with VeriKnox Hub.

Run enrollment as an init container using the `510978032592.dkr.ecr.us-east-1.amazonaws.com/veriknox/kong-init-identity` image.
The container exits after enrollment completes and doesn't need to run alongside {{site.base_gateway}}:

```yaml
services:
  kong-init:
    image: 510978032592.dkr.ecr.us-east-1.amazonaws.com/veriknox/kong-init-identity:0.0.9
    restart: "no"
    environment:
      KONG_VERIKNOX_IDENTITY_ENROLLMENT_TOKEN: ${VERIKNOX_ENROLLMENT_TOKEN}
      KONG_VERIKNOX_IDENTITY_PASSPHRASE: ${VERIKNOX_IDENTITY_PASSPHRASE}
      KONG_VERIKNOX_IDENTITY_BASE_URL: https://hub.veriknox.ai
      KONG_VERIKNOX_IDENTITY_STATE_DIR: /data
    volumes:
      - kong-init-volume:/data
```

The `KONG_VERIKNOX_IDENTITY_STATE_DIR` and `KONG_VERIKNOX_HUB_BASE_URL` environment variables must be exposed to Nginx workers via `KONG_NGINX_MAIN_ENV` so the plugin can read them at runtime.
You will use them during installation.

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

When the control plane is {{site.konnect_short_name}}, provision the control plane and vault secrets first, enroll the data plane identity second, then start the data planes.

1. Obtain the `schema.lua` file from your VeriKnox Technical Account Manager.

{% include_cached plugins/third-party-konnect-plugin.md %}

1. Create a {{site.konnect_short_name}} Vault backed by a Config Store to hold the identity passphrase.
   Use the {{site.konnect_short_name}} API to create a [config store](/gateway/entities/vault/konnect-config-store/), then write the passphrase secret.
   The plugin resolves `{vault://veriknox/VERIKNOX_IDENTITY_PASSPHRASE}` at runtime and never reads the passphrase from disk.

   {:.info}
   > **Note**: You can instead point {{site.base_gateway}} at another vault backend it supports, for example AWS Secrets Manager, GCP Secret Manager, HashiCorp Vault, or an env-based vault.
   > The plugin configuration follows the same format (`agent_passphrase: "{vault://...}"`).
   > Only the vault backend and how you seed the secret change.

1. Sync your gateway configuration (Services, Routes, and the `veriknox-plugin` config) to {{site.konnect_short_name}}:

   ```bash
   deck gateway sync konnect.yml
   ```

   You can also apply the same Services, Routes, and plugins manually in the {{site.konnect_short_name}} UI or API.

1. Enroll the data plane identity with VeriKnox Hub.
   See [Enroll the data plane identity](#enroll-the-data-plane-identity).
   Complete this step before starting the data planes, since they can't sign receipts without a registered identity.

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

   At runtime, the data plane mounts the identity storage, completes the mTLS handshake to the control plane, and pulls the synced gateway configuration.
   The plugin then resolves `agent_passphrase` from the vault to sign receipts.

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

## Quickstart

VeriKnox provides a Docker Compose quickstart environment that runs the full stack locally: a {{site.konnect_short_name}}-connected data plane with the VeriKnox plugin, a sample MCP math server, a sample A2A math-agent server, and a test client.
Contact your VeriKnox Technical Account Manager to obtain the quickstart files.

### Prerequisites

* Docker with the Compose plugin
* The [`just`](https://github.com/casey/just) command runner
* decK (`deck`)
* AWS credentials with pull access to the VeriKnox ECR registry
* Python 3 with `python-dotenv`, `jinja2`, and requests (`pip install -r requirements.txt`)
* A VeriKnox site enrollment token
* A {{site.konnect_short_name}} personal access token (PAT)
* An OpenAI API key (required for the OpenAI inference and A2A examples)

### Example data planes and upstream services

Traffic through the data plane is inspected by the `veriknox-plugin` before it reaches the upstream service.
For each request, the plugin both forwards traffic to the upstream service and posts a signed receipt to VeriKnox Hub, which acts as the policy engine (allow or block) and records the receipt.

{% mermaid %}
flowchart LR
    A[Client / AI Agent] --> B
    subgraph DP["kong-dp-0"]
        B[VeriKnox plugin]
    end
    B --> C["Upstream service<br/>(data plane traffic)"]
    B --> D["VeriKnox Hub<br/>(policy engine)"]
{% endmermaid %}

After `just up`, the stack includes the following components.

{% table %}
columns:
  - title: Component
    key: component
  - title: Role
    key: role
rows:
  - component: "`kong-dp-0`, `kong-dp-N`"
    role: "{{site.base_gateway}} data planes ({{site.konnect_short_name}} hybrid mode) with `veriknox-plugin` baked in. HTTP on `http://localhost:8080`."
  - component: "`kong-init` / `kong-deinit`"
    role: "One-shot identity enroll and unenroll against VeriKnox Hub."
  - component: "`kong-gs-mcp-math`"
    role: "MCP math tool server (JSON-RPC), reached through {{site.base_gateway}} as `/mcp/math`."
  - component: "`math-agent-server`"
    role: "Sample A2A agent that calls OpenAI and MCP through {{site.base_gateway}} (`/openai`, `/mcp/math`, `/agent`)."
  - component: "`veriknox-agent-test`"
    role: "Optional test client (`just shell-agent`, Compose profile `test`)."
{% endtable %}

Routes synced from `konnect.yml` send LLM, MCP, and A2A traffic through the data planes so the plugin can sign receipts to VeriKnox Hub.

### What the quickstart does

The `./setup_quickstart` script performs the following steps in one run:

1. Creates a VeriKnox site and obtains a site enrollment token, used by `kong-init` to register the data plane identity with VeriKnox Hub.
1. Creates a {{site.konnect_short_name}} control plane (or selects an existing one) and collects the control plane connection details: the endpoints and mTLS material the data planes use to join hybrid mode.
1. Configures the control plane:
   * Uploads the `veriknox-plugin` schema.
   * Creates vault secrets, including the identity passphrase.
   * Syncs the gateway configuration with `deck gateway sync konnect.yml`, or applies the same Services, Routes, and plugins manually in {{site.konnect_short_name}}.
1. Prepares the local runtime: writes `.env` and renders `docker-compose.yml` so Compose can run identity enrollment (`kong-init`), start the data planes, and bring up the sample backends (the MCP math server and the A2A math-agent server).

The script prompts for the enrollment token, {{site.konnect_short_name}} PAT, and OpenAI API key, then provisions {{site.konnect_short_name}} and writes the local files.
After it finishes, start the stack with `just up`.

### Run the quickstart

1. Authenticate to the VeriKnox ECR registry:

   ```bash
   aws ecr get-login-password --region us-east-1 \
     | docker login --username AWS --password-stdin \
       510978032592.dkr.ecr.us-east-1.amazonaws.com
   ```
1. Run the setup script.
   When prompted, enter your VeriKnox enrollment token, {{site.konnect_short_name}} PAT, and OpenAI API key.
   The script provisions the {{site.konnect_short_name}} control plane and writes the local configuration files:

   ```bash
   ./setup_quickstart
   ```

1. Start the stack:

   ```bash
   just up
   ```

   The gateway is reachable at `http://localhost:8080` after identity enrollment completes.

To configure the plugin on your Routes, see the [LLM inference](/plugins/veriknox/examples/llm-inference/) and [MCP tool call](/plugins/veriknox/examples/mcp-tool-call/) examples.

### Manage data planes and upstream services

```bash
just up        # Start (pulls ECR images, runs docker-compose.yml)
just down      # Stop, keep containers
just logs      # Follow logs
just shell-dp 0  # Open a shell in kong-dp-0
just shell-agent # Open a shell in the agent test client
just delete    # Unenroll, then stop and remove containers and volumes
```

### Uninstall

To unenroll the data plane identity and tear down the stack:

```bash
just delete
./setup_quickstart --deinit
```
