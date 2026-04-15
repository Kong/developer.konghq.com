---
featured: true
time_estimate: "30 min"
content_type: cookbook
products:
    - ai-gateway
tools:
    - kongctl
works_on:
    - konnect
layout: reference
title: Secure Internal MCP Gateway
description: Aggregate multiple internal APIs into a single MCP server with OAuth 2.1 authentication and tool-level access control via consumer-group ACLs.
canonical: true
agent_setup_url: "/kong-cookbooks/agent-setup/?recipe=/kong-cookbooks/secure-internal-mcp-gateway/"
plugins:
    - ai-mcp-proxy
    - ai-mcp-oauth2
    - cors
requires_embeddings: false
extra_services:
    - name: Identity Provider (Okta or Keycloak)
      env_vars: [DECK_OAUTH_AUTH_SERVER, DECK_OAUTH_INTROSPECTION_URL, DECK_OAUTH_CLIENT_ID, DECK_OAUTH_CLIENT_SECRET]
hint: "Create an OAuth application for Kong (API Services / Client Credentials) and one for MCP clients (SPA / Authorization Code + PKCE). See the Identity Provider section in Prerequisites."
---

## Overview

Organizations adopting MCP (Model Context Protocol) face a common challenge: multiple API teams
each expose tools, but there is no centralized control over who can discover and call those tools.
Developers connect MCP clients directly to individual servers, credentials are scattered, and
there is no audit trail when an AI agent calls a destructive operation.

There are broadly two types of MCP servers that Kong can proxy:

- **Internal MCP servers** are hosted within your organization's trust boundary. They wrap
internal APIs (databases, ticketing systems, proprietary services) and you control both the
server and the authentication. Kong can convert REST APIs into MCP tools automatically, or
proxy fully custom MCP server implementations. This recipe covers this scenario.
- **External MCP servers** are third-party services (GitHub, Slack, Figma) that manage their
own authentication and issue their own tokens. Proxying these through Kong requires a different
approach — the auth flow is between the MCP client and the external provider, with Kong acting
as a passthrough with observability. See [Secure External MCP Gateway](/kong-cookbooks/secure-external-mcp-gateway/)
  for that pattern.

This recipe focuses on internal MCP servers, placing Kong Gateway in front of them as a single
aggregated endpoint. Each API team independently defines their tools and access policies using the
[ai-mcp-proxy](/plugins/ai-mcp-proxy/) plugin in `conversion-only` mode. A central platform team
aggregates those tools into one MCP server using `listener` mode, secures it with OAuth 2.1 via
[ai-mcp-oauth2](/plugins/ai-mcp-oauth2/), and enforces per-tool access control through
consumer-group ACLs.

The result: one MCP endpoint, federated tool ownership, centralized auth, and fine-grained access
control — all without any team giving up independence over their own APIs.

### The problem

**No centralized MCP access control.** Each internal MCP server manages its own authentication,
or worse, has none. When AI agents connect directly to these servers, there is no central policy
governing which agent can call which tools. A warehouse automation agent and a customer support
agent see the same tool catalog.

**Scattered credentials.** Each MCP server requires its own authentication setup. Developers
juggle multiple tokens, and there is no single revocation point. Offboarding a developer means
touching every MCP server they had access to.

**No federated tool governance.** API teams want to control which of their endpoints are exposed
as MCP tools and who can call them. But without a central aggregation layer, there is no
mechanism for a platform team to enforce organization-wide policies while letting individual
teams manage their own tool definitions.

**MCP auth is nascent.** The OAuth 2.0 specification for MCP is still evolving, and identity
provider support varies significantly. Some IdPs support token introspection (required by the
ai-mcp-oauth2 plugin), others do not. Most do not yet implement RFC 8707 (Resource Indicators),
which means audience validation requires workarounds.

### The solution

This recipe uses Kong Gateway as a federated MCP aggregation layer with three capabilities:

- **REST-to-MCP conversion** — Each API team applies the ai-mcp-proxy plugin in `conversion-only`
mode to their existing Kong routes. This converts selected REST endpoints into MCP tools, tagged
for discovery. Teams control their own tool definitions and ACL policies.
- **Tool aggregation** — A central route runs the ai-mcp-proxy plugin in `listener` mode, which
discovers all tagged tools and exposes them through a single MCP endpoint. MCP clients connect
to one URL and see a unified tool catalog.
- **OAuth 2.1 + ACLs** — The ai-mcp-oauth2 plugin handles the full MCP auth spec: Protected
Resource Metadata (PRM) discovery (RFC 9728), authorization code flow with PKCE, and token
introspection. In Kong Gateway 3.14+, the plugin maps token claims directly to Kong consumers
and consumer groups, enabling per-tool ACLs without a separate authentication plugin.

```
MCP Client                    Kong Gateway                          Backend APIs
──────────                   ─────────────                         ────────────

                             ┌─ /ecommerce-mcp ──────────────────────────────────┐
  │                          │   ai-mcp-oauth2                                   │
  ├── MCP initialize ──────► │     • PRM discovery (RFC 9728)                    │
  │   (no token)             │     • 401 + WWW-Authenticate                      │
  │                          │                                                   │
  ├── OAuth flow ──────────► │   (browser → IdP → callback → token)              │
  │                          │                                                   │
  ├── MCP initialize ──────► │   ai-mcp-oauth2                                  │
  │   (Bearer token)         │     • Token introspection                         │
  │                          │     • consumer_claim → Kong consumer              │
  │                          │     • consumer_groups_claim → consumer groups     │
  │                          │                                                   │
  │                          │   ai-mcp-proxy (listener)                         │
  │                          │     • Aggregates tools from tagged plugins        │
  ├── tools/list ──────────► │     • Returns tool catalog                        │
  │                          │                                                   │
  ├── tools/call ──────────► │     • Evaluates per-tool ACLs          Orders API │
  │   (check-inventory)      │     • Routes to correct backend ─────► (httpbin)  │
  │                          │                                                   │
  ├── tools/call ──────────► │     • ACL DENIED                                  │
  │   (cancel-order)         │     • Consumer group not in allow list            │
  │                          └───────────────────────────────────────────────────┘
```

{:.no-copy-code}

This recipe demonstrates the pattern with three mock ecommerce APIs (Orders, Inventory, Customers)
backed by httpbin, two consumer groups (`warehouse-ops` and `customer-support`), and OAuth
authentication via Okta or Keycloak.


| Component                                                         | Responsibility                                                                                    |
| ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Identity Provider (Okta / Keycloak)                               | OAuth 2.1 authorization server, user identity, group membership, token issuance and introspection |
| Kong — [ai-mcp-oauth2](/plugins/ai-mcp-oauth2/)                   | MCP-native OAuth: PRM discovery, token introspection, consumer and consumer group mapping (3.14+) |
| Kong — [ai-mcp-proxy](/plugins/ai-mcp-proxy/) (`conversion-only`) | Converts REST API endpoints into MCP tools with per-tool ACL definitions                          |
| Kong — [ai-mcp-proxy](/plugins/ai-mcp-proxy/) (`listener`)        | Aggregates tagged tools into a single MCP server, enforces ACLs at call time                      |
| Kong — [cors](/plugins/cors/)                                     | Enables browser-based MCP clients to connect to the gateway                                       |
| Backend APIs (httpbin)                                            | Mock ecommerce services representing independent API teams                                        |


### ACL matrix

This recipe creates two consumer groups with different tool access:


| Tool                      | warehouse-ops | customer-support |
| ------------------------- | ------------- | ---------------- |
| `list-orders`             | yes           | yes              |
| `get-order`               | yes           | yes              |
| `cancel-order`            | —             | yes              |
| `list-inventory`          | yes           | yes              |
| `check-inventory`         | yes           | yes              |
| `restock-item`            | yes           | —                |
| `get-customer`            | —             | yes              |
| `update-customer-contact` | —             | yes              |


Warehouse operations staff can view orders and manage inventory (including restocking), but
cannot access customer data or cancel orders. Customer support agents can view orders, check
inventory, manage customer records, and cancel orders, but cannot restock inventory.

## Prerequisites

### Kong Konnect

This is a Konnect tutorial and requires a Konnect personal access token.

1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
2. Export your token to an environment variable:
  ```bash
    export KONNECT_TOKEN='YOUR_KONNECT_PAT'
  ```
3. Run the [quickstart script](https://get.konghq.com/quickstart) to provision a Control Plane and Data Plane:
  ```bash
    export KONNECT_CONTROL_PLANE_NAME='secure-internal-mcp-gateway-recipe'
    curl -Ls https://get.konghq.com/quickstart | bash -s -- -k $KONNECT_TOKEN --deck-output
  ```
    Copy and paste the environment variable exports it prints into your terminal.
4. Adopt the control plane so kongctl can manage it:
  ```bash
    export KONGCTL_DEFAULT_KONNECT_PAT=$KONNECT_TOKEN
    kongctl adopt control-plane ${KONNECT_CONTROL_PLANE_NAME} --namespace ${KONNECT_CONTROL_PLANE_NAME} -o json
  ```

### kongctl + decK

This tutorial uses [kongctl](/kongctl/) and [decK](/deck/) to manage Kong configuration.

1. Install **kongctl** from [developer.konghq.com/kongctl](https://developer.konghq.com/kongctl/).
2. Install **decK** version 1.43 or later from [docs.konghq.com/deck](https://docs.konghq.com/deck/).

You can verify both are installed:

```bash
kongctl version
deck version
```

### Identity provider

You need an OAuth 2.1 identity provider that supports **token introspection** (RFC 7662).
Select your IdP below and follow the setup steps.

{% navtabs "Identity Provider" %}
{% tab Okta %}

You need an Okta organization with admin access. You will create two applications:

**1. Kong Gateway application (API Services)**

This represents Kong as the resource server. Kong uses it to validate tokens via introspection.

1. In the Okta Admin Console, go to **Applications → Create App Integration**.
2. Select **API Services** (machine-to-machine).
3. Name it `Kong MCP Gateway`.
4. Note the **Client ID** and **Client Secret** — these are your `DECK_OAUTH_CLIENT_ID` and
  `DECK_OAUTH_CLIENT_SECRET`.

**2. MCP Client application (SPA)**

This represents the MCP client (the demo script, or any MCP-compatible tool).

1. In the Okta Admin Console, go to **Applications → Create App Integration**.
2. Select **OIDC — OpenID Connect** and **Single-Page Application**.
3. Name it `MCP Client`.
4. Set the sign-in redirect URI to `http://localhost:8085/callback`.
5. Enable **Authorization Code + PKCE** as the grant type.
6. Assign the application to your users.
7. Note the **Client ID** — this is your `OAUTH_CLIENT_ID` for the demo script.

{:.important}

> You must create an **SPA** application, not a **Web** application. Even if you enable PKCE on
> a Web application, the OAuth flow will not complete correctly with MCP clients that do not send
> a client secret.

**3. Configure groups claim**

The ai-mcp-oauth2 plugin uses the `groups` claim in access tokens to map users to Kong consumer
groups. Configure your Okta authorization server to include this claim:

1. Go to **Security → API → Authorization Servers** and select your authorization server
  (e.g., `default`).
2. Go to the **Claims** tab and add a new claim:
  - **Name:** `groups`
  - **Include in token type:** Access Token
  - **Value type:** Groups
  - **Filter:** Matches regex `.`* (or restrict to specific groups)
3. Go to the **Scopes** tab and ensure `openid` is present.

**4. Create Okta groups**

Create two groups in Okta that match the Kong consumer group names:

1. Go to **Directory → Groups** and create:
  - `warehouse-ops`
  - `customer-support`
2. Assign your test users to the appropriate group(s).

**5. Note your endpoints**

You will need:

- **Authorization server URL:** `https://your-org.okta.com/oauth2/default`
- **Introspection endpoint:** `https://your-org.okta.com/oauth2/default/v1/introspect`

{% endtab %}
{% tab Keycloak %}

You need a Keycloak instance with admin access. You will create a realm, two clients, and
configure group mappings.

**1. Create a realm** (or use an existing one)

1. In the Keycloak Admin Console, create a new realm (e.g., `mcp-demo`).

**2. Kong Gateway client (Confidential)**

This client represents Kong as the resource server for token introspection.

1. Go to **Clients → Create client**.
2. Set **Client ID** to `kong-mcp-gateway`.
3. Set **Client authentication** to **On** (confidential client).
4. Enable **Service accounts roles**.
5. Note the **Client ID** and **Client Secret** from the **Credentials** tab — these are your
  `DECK_OAUTH_CLIENT_ID` and `DECK_OAUTH_CLIENT_SECRET`.

**3. MCP Client (Public)**

This client represents the MCP client application.

1. Go to **Clients → Create client**.
2. Set **Client ID** to `mcp-client`.
3. Set **Client authentication** to **Off** (public client).
4. Set **Valid redirect URIs** to `http://localhost:8085/callback`.
5. Enable **Standard flow** (Authorization Code).
6. Note the **Client ID** — this is your `OAUTH_CLIENT_ID` for the demo script.

**4. Configure groups claim**

By default, Keycloak does not include a `groups` claim in access tokens. Add a client scope
and mapper:

1. Go to **Client scopes → Create client scope**.
2. Name it `groups`, set type to **Default**.
3. In the scope, go to **Mappers → Create mapper**:
  - **Mapper type:** Group Membership
  - **Name:** `groups`
  - **Token Claim Name:** `groups`
  - **Full group path:** Off
  - **Add to access token:** On
4. Go to **Clients → kong-mcp-gateway → Client scopes** and add the `groups` scope.
5. Repeat for the `mcp-client` client.

**5. Create groups and users**

1. Go to **Groups** and create:
  - `warehouse-ops`
  - `customer-support`
2. Create test users and assign them to the appropriate group(s).

**6. Note your endpoints**

You will need:

- **Authorization server URL:** `https://your-keycloak-host/realms/mcp-demo`
- **Introspection endpoint:** `https://your-keycloak-host/realms/mcp-demo/protocol/openid-connect/token/introspect`

{% endtab %}
{% endnavtabs %}

### Python environment

The demo scripts require Python 3.11 or later:

```bash
pip install httpx mcp openai
```

## How it works

### Step 1: Convert REST APIs to MCP tools

Each API team applies the ai-mcp-proxy plugin in `conversion-only` mode to their Kong route.
This mode defines MCP tools that map to REST endpoints but does **not** serve them as a
standalone MCP server. Instead, it makes the tools available for aggregation via tags.

```yaml
plugins:
  - name: ai-mcp-proxy
    tags:
      - ecom-mcp                  # Discovery tag for the listener
    config:
      mode: conversion-only       # Define tools only — no MCP endpoint here
      consumer_identifier: username
      include_consumer_groups: true
      tools:
        - name: check-inventory
          description: Check stock level for a specific SKU
          method: GET
          path: /inventory/{sku}
          annotations:
            read_only_hint: true
          acl:
            allow:
              - warehouse-ops     # Only warehouse staff can see this tool
              - customer-support
          parameters:
            - name: sku
              in: path
              required: true
              schema:
                type: string
```

{:.no-copy-code}

Each tool definition includes:

- **name** and **description** — what the tool does (visible to MCP clients and LLM agents)
- **method** and **path** — the REST endpoint this tool maps to
- **annotations** — MCP hints like `read_only_hint` and `destructive_hint` that help agents
understand the tool's behavior
- **acl** — which consumer groups can call this tool (completely overrides `default_acl` when set)
- **parameters** — OpenAPI 3.0 parameter definitions

The `tags` field on the plugin entity (not the config) is what the listener uses for discovery.
All conversion-only plugins that should be aggregated share the same tag (`ecom-mcp`).

This pattern maps naturally to Kong's federated API management model: each API team manages
their own service and route in their own control plane or namespace, and they decide which
endpoints to expose as tools and who can call them. The central platform team doesn't need
to touch individual team configurations.

{:.note}

> **Automatic conversion from OpenAPI specs.** Starting with decK v1.57, the
> `deck file openapi2mcp` command can generate ai-mcp-proxy tool definitions directly from
> an OpenAPI specification, removing the need to write tool configs by hand. This is especially
> useful for APIs that already have well-documented OpenAPI specs.

{:.important}

> **Tool design for production.** Automatic REST-to-MCP conversion — whether from plugin config
> or OpenAPI specs — is a great way to get started and works well for simpler APIs where each
> endpoint maps cleanly to a user action. For more complex workflows, however, consider designing
> higher-level tools that encapsulate complete user goals. A single `process-return(orderId, reason)` tool that handles lookup, validation, and cancellation internally tends to be more
> reliable for LLM agents than three separate endpoint-mapped tools the agent must orchestrate.
> LLMs are stateless — they rediscover tools every conversation and cannot reuse prior
> orchestration logic. The right balance depends on your APIs: use automatic conversion where
> endpoints are self-contained, and build workflow tools where operations span multiple steps.

### Step 2: Aggregate tools into one MCP server

The platform team creates a single route with the ai-mcp-proxy plugin in `listener` mode.
The listener discovers all `conversion-only` plugins matching the configured tag and exposes
their combined tool catalog as one MCP server.

```yaml
- name: ai-mcp-proxy
  config:
    mode: listener                # Aggregate tools from tagged plugins
    consumer_identifier: username
    include_consumer_groups: true  # Required for group-based ACL evaluation
    server:
      tag: ecom-mcp              # Match conversion-only plugins with this tag
      timeout: 10000
```

{:.no-copy-code}

The listener does not define its own tools. It inherits tool definitions **and their ACL rules**
from the tagged conversion-only plugins. When a tool is called, the listener evaluates the
caller's consumer group against the tool's ACL before routing the request to the backend service.

`include_consumer_groups: true` is **required** on the listener for group-based ACLs to work.
Without it, the listener cannot pass consumer group membership to the ACL evaluation logic.

### Step 3: Authenticate with OAuth 2.1

The ai-mcp-oauth2 plugin implements the full MCP authentication specification:

1. **PRM discovery (RFC 9728)** — When an MCP client connects without a token, the plugin
  returns `401` with a `WWW-Authenticate` header pointing to the Protected Resource Metadata
   endpoint. The metadata advertises which authorization server to use and what scopes to request.
2. **Token introspection (RFC 7662)** — When a client presents a Bearer token, the plugin
  validates it by calling the IdP's introspection endpoint using the configured client
   credentials. Introspection responses are cached by default to reduce load on the IdP.
3. **Consumer mapping (3.14+)** — The plugin maps token claims directly to Kong consumers and
  consumer groups:
  - `consumer_claim: [sub]` — looks up a Kong consumer whose `username` or `custom_id` matches
  the token's `sub` claim
  - `consumer_groups_claim: [groups]` — maps the token's `groups` claim to Kong consumer groups
  - If no consumer is found, `credential_claim: [sub]` sets a credential identifier so
  downstream plugins can still identify the caller

```yaml
- name: ai-mcp-oauth2
  config:
    resource: http://localhost:8000/ecommerce-mcp
    authorization_servers:
      - https://your-org.okta.com/oauth2/default
    introspection_endpoint: https://your-org.okta.com/oauth2/default/v1/introspect
    client_id: <kong-client-id>
    client_secret: <kong-client-secret>
    metadata_endpoint: /.well-known/oauth-protected-resource/ecommerce-mcp
    scopes_supported:
      - openid
    insecure_relaxed_audience_validation: true
    consumer_claim:
      - sub
    consumer_by:
      - username
      - custom_id
    consumer_groups_claim:
      - groups
```

{:.no-copy-code}

{:.important}

> `**insecure_relaxed_audience_validation: true**` — Most identity providers do not yet
> implement RFC 8707 (Resource Indicators for OAuth 2.0), so the `aud` claim in access tokens
> will not match the MCP resource URL. This flag relaxes audience validation until your IdP
> supports RFC 8707. Without it, all requests will be rejected with an audience mismatch error.

The route that hosts this plugin includes two paths:

- `/ecommerce-mcp` — the MCP endpoint itself
- `/.well-known/oauth-protected-resource/ecommerce-mcp` — the PRM discovery path

The second path ensures that MCP clients which ignore the `resource_metadata` URL in the
`WWW-Authenticate` header and fall back to
[standard PRM locations](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization#protected-resource-metadata-discovery-requirements)
can still discover the metadata.

### Step 4: Enforce tool-level ACLs

ACLs in ai-mcp-proxy use a two-tier system:

- `**default_acl**` — Baseline rules applied to all tools that don't define their own ACL.
- **Per-tool `acl`** — When a tool defines `acl.allow` or `acl.deny`, it **completely overrides**
the default. There is no merging or inheritance between the two tiers.

In this recipe, every tool defines its own `acl.allow` list specifying which consumer groups can
call it. Deny takes precedence over allow — if a consumer appears in both lists, they are denied.

When the listener receives a `tools/call` request:

1. It resolves the caller's consumer group from the authenticated consumer (mapped by
  ai-mcp-oauth2's `consumer_groups_claim`)
2. It evaluates the tool's ACL against the caller's groups
3. If the caller is not in the allow list, the request is rejected with
  `INVALID_PARAMS (-32602)`

### IdP compatibility

The ai-mcp-oauth2 plugin requires token introspection (RFC 7662). Not all identity providers
support this. The table below summarizes compatibility:


| Identity Provider      | Introspection | Compatible | Notes                                                                                                                                         |
| ---------------------- | ------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Okta**               | Yes           | Yes        | Full RFC 7662 support. Endpoint: `https://{domain}/oauth2/{authServerId}/v1/introspect`                                                       |
| **Keycloak**           | Yes           | Yes        | Full RFC 7662 support. Endpoint: `/realms/{realm}/protocol/openid-connect/token/introspect`                                                   |
| **Ping Identity**      | Yes           | Yes        | Supports token introspection per RFC 7662                                                                                                     |
| **FusionAuth**         | Yes           | Yes        | Supports RFC 7662 token introspection                                                                                                         |
| **ORY Hydra**          | Yes           | Yes        | Open source OAuth2 server with full RFC 7662 support                                                                                          |
| **Microsoft Entra ID** | No            | No         | Does not provide an introspection endpoint. Use JWKS-based JWT validation with the [openid-connect](/plugins/openid-connect/) plugin instead. |
| **Auth0**              | No            | No         | Does not support RFC 7662 introspection. Use JWKS-based JWT validation instead.                                                               |
| **AWS Cognito**        | No            | No         | Does not provide an introspection endpoint. Use JWKS-based JWT validation instead.                                                            |
| **Google OAuth2**      | Partial       | No         | Has a tokeninfo endpoint but it is not RFC 7662 compliant.                                                                                    |


For IdPs that do not support introspection, you can achieve similar functionality using the
[openid-connect](/plugins/openid-connect/) plugin with JWKS-based JWT validation and the
`consumer_claim` parameter. This requires additional configuration (a pre-function or datakit
plugin to serve the PRM endpoint and return the `WWW-Authenticate` header). A future recipe
will cover this pattern in detail.

## Apply the Kong configuration

The following configuration creates four Kong Gateway services (three ecommerce APIs + one
aggregated MCP server), eight MCP tools with per-tool ACLs, two consumer groups, OAuth 2.1
authentication via ai-mcp-oauth2, and CORS support. All resources are scoped using `select_tags`
and a kongctl `namespace` for clean teardown.

### Set your environment variables

Export the common variables:

```bash
export KONNECT_CONTROL_PLANE_NAME='secure-internal-mcp-gateway-recipe'
export DECK_MCP_RESOURCE_URL='http://localhost:8000/ecommerce-mcp'
```

Then export the IdP-specific variables for your identity provider:

{% navtabs "Identity Provider" %}
{% tab Okta %}

```bash
export DECK_OAUTH_AUTH_SERVER='https://your-org.okta.com/oauth2/default'
export DECK_OAUTH_INTROSPECTION_URL='https://your-org.okta.com/oauth2/default/v1/introspect'
export DECK_OAUTH_CLIENT_ID='your-kong-client-id'
export DECK_OAUTH_CLIENT_SECRET='your-kong-client-secret'
```

{% endtab %}
{% tab Keycloak %}

```bash
export DECK_OAUTH_AUTH_SERVER='https://your-keycloak-host/realms/mcp-demo'
export DECK_OAUTH_INTROSPECTION_URL='https://your-keycloak-host/realms/mcp-demo/protocol/openid-connect/token/introspect'
export DECK_OAUTH_CLIENT_ID='kong-mcp-gateway'
export DECK_OAUTH_CLIENT_SECRET='your-kong-client-secret'
```

{:.note}

> **Keycloak groups claim.** Ensure you configured the `groups` client scope and mapper as
> described in Prerequisites. Without it, the access token will not contain a `groups` claim
> and consumer group mapping will fail.

{% endtab %}
{% endnavtabs %}

### Apply the configuration

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - secure-internal-mcp-gateway-recipe
consumer_groups:
- name: warehouse-ops
- name: customer-support
consumers:
- username: warehouse-user
  groups:
  - name: warehouse-ops
- username: support-user
  groups:
  - name: customer-support
services:
- name: orders-api
  host: httpbin.konghq.com
  port: 443
  protocol: https
  path: /anything
  routes:
  - name: orders-mcp
    paths:
    - /orders-mcp
    plugins:
    - name: ai-mcp-proxy
      tags:
      - secure-internal-mcp-gateway-recipe
      - ecom-mcp
      config:
        mode: conversion-only
        consumer_identifier: username
        include_consumer_groups: true
        logging:
          log_payloads: true
          log_statistics: true
        tools:
        - name: list-orders
          description: List recent orders with optional filters for status and date.
          method: GET
          path: /orders
          annotations:
            read_only_hint: true
            title: List orders
          acl:
            allow:
            - warehouse-ops
            - customer-support
          parameters:
          - name: status
            in: query
            required: false
            description: Filter by order status (pending, shipped, delivered, cancelled)
            schema:
              type: string
          - name: date
            in: query
            required: false
            description: Filter by order date (YYYY-MM-DD)
            schema:
              type: string
        - name: get-order
          description: Get full details for a specific order including line items and shipping.
          method: GET
          path: /orders/{orderId}
          annotations:
            read_only_hint: true
            title: Get order details
          acl:
            allow:
            - warehouse-ops
            - customer-support
          parameters:
          - name: orderId
            in: path
            required: true
            description: The order ID
            schema:
              type: string
        - name: cancel-order
          description: Cancel a pending order. This action cannot be undone.
          method: POST
          path: /orders/{orderId}/cancel
          annotations:
            destructive_hint: true
            title: Cancel order
          acl:
            allow:
            - customer-support
          parameters:
          - name: orderId
            in: path
            required: true
            description: The order ID to cancel
            schema:
              type: string
- name: inventory-api
  host: httpbin.konghq.com
  port: 443
  protocol: https
  path: /anything
  routes:
  - name: inventory-mcp
    paths:
    - /inventory-mcp
    plugins:
    - name: ai-mcp-proxy
      tags:
      - secure-internal-mcp-gateway-recipe
      - ecom-mcp
      config:
        mode: conversion-only
        consumer_identifier: username
        include_consumer_groups: true
        logging:
          log_payloads: true
          log_statistics: true
        tools:
        - name: list-inventory
          description: List inventory items with optional filters for category or low stock.
          method: GET
          path: /inventory
          annotations:
            read_only_hint: true
            title: List inventory
          acl:
            allow:
            - warehouse-ops
            - customer-support
          parameters:
          - name: category
            in: query
            required: false
            description: Filter by product category
            schema:
              type: string
          - name: low_stock
            in: query
            required: false
            description: Set to true to show only items below restock threshold
            schema:
              type: string
        - name: check-inventory
          description: Check current stock level and details for a specific SKU.
          method: GET
          path: /inventory/{sku}
          annotations:
            read_only_hint: true
            title: Check inventory for SKU
          acl:
            allow:
            - warehouse-ops
            - customer-support
          parameters:
          - name: sku
            in: path
            required: true
            description: The product SKU
            schema:
              type: string
        - name: restock-item
          description: Add units to a product's inventory.
          method: POST
          path: /inventory/{sku}/restock
          annotations:
            destructive_hint: true
            title: Restock inventory item
          acl:
            allow:
            - warehouse-ops
          parameters:
          - name: sku
            in: path
            required: true
            description: The product SKU to restock
            schema:
              type: string
          - name: quantity
            in: query
            required: true
            description: Number of units to add
            schema:
              type: integer
- name: customers-api
  host: httpbin.konghq.com
  port: 443
  protocol: https
  path: /anything
  routes:
  - name: customers-mcp
    paths:
    - /customers-mcp
    plugins:
    - name: ai-mcp-proxy
      tags:
      - secure-internal-mcp-gateway-recipe
      - ecom-mcp
      config:
        mode: conversion-only
        consumer_identifier: username
        include_consumer_groups: true
        logging:
          log_payloads: true
          log_statistics: true
        tools:
        - name: get-customer
          description: Retrieve customer profile and contact information.
          method: GET
          path: /customers/{customerId}
          annotations:
            read_only_hint: true
            title: Get customer details
          acl:
            allow:
            - customer-support
          parameters:
          - name: customerId
            in: path
            required: true
            description: The customer ID
            schema:
              type: string
        - name: update-customer-contact
          description: Update a customer's contact information.
          method: PUT
          path: /customers/{customerId}/contact
          annotations:
            destructive_hint: true
            title: Update customer contact info
          acl:
            allow:
            - customer-support
          parameters:
          - name: customerId
            in: path
            required: true
            description: The customer ID to update
            schema:
              type: string
          - name: email
            in: query
            required: false
            description: New email address
            schema:
              type: string
          - name: phone
            in: query
            required: false
            description: New phone number
            schema:
              type: string
- name: aggregated-mcp-server
  host: httpbin.konghq.com
  port: 443
  protocol: https
  path: /anything
  routes:
  - name: ecommerce-mcp
    paths:
    - /ecommerce-mcp
    - /.well-known/oauth-protected-resource/ecommerce-mcp
    plugins:
    - name: ai-mcp-oauth2
      tags:
      - secure-internal-mcp-gateway-recipe
      config:
        resource: ${{ env "DECK_MCP_RESOURCE_URL" }}
        authorization_servers:
        - ${{ env "DECK_OAUTH_AUTH_SERVER" }}
        introspection_endpoint: ${{ env "DECK_OAUTH_INTROSPECTION_URL" }}
        client_id: ${{ env "DECK_OAUTH_CLIENT_ID" }}
        client_secret: ${{ env "DECK_OAUTH_CLIENT_SECRET" }}
        metadata_endpoint: /.well-known/oauth-protected-resource/ecommerce-mcp
        scopes_supported:
        - openid
        insecure_relaxed_audience_validation: true
        cache_introspection: true
        consumer_claim:
        - sub
        consumer_by:
        - username
        - custom_id
        consumer_optional: false
        consumer_groups_claim:
        - groups
        consumer_groups_optional: false
        credential_claim:
        - sub
    - name: ai-mcp-proxy
      tags:
      - secure-internal-mcp-gateway-recipe
      config:
        mode: listener
        consumer_identifier: username
        include_consumer_groups: true
        server:
          tag: ecom-mcp
          timeout: 10000
          forward_client_headers: true
        logging:
          log_payloads: true
          log_statistics: true
    - name: cors
      tags:
      - secure-internal-mcp-gateway-recipe
      config:
        origins:
        - '*'
        methods:
        - GET
        - HEAD
        - PUT
        - PATCH
        - POST
        - DELETE
        - OPTIONS
        credentials: false
        preflight_continue: false
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: secure-internal-mcp-gateway-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve

rm -f kong-recipe.yaml
```

The configuration is the same regardless of which identity provider you use — the only
difference is the environment variable values you exported above. The ai-mcp-oauth2 plugin
resolves the IdP endpoints from those variables at apply time.

## Try it out

With the configuration applied and your IdP configured, the aggregated MCP endpoint is ready
to accept authenticated connections.

### Basic demo: MCP client with OAuth flow

The `demo.py` script walks through the complete MCP authentication specification step by step.
It starts by sending an unauthenticated request to trigger Protected Resource Metadata (PRM)
discovery, then completes the OAuth 2.1 authorization code flow with PKCE via your browser,
and finally connects an MCP client to demonstrate tool listing and ACL enforcement.

Set the MCP client's OAuth client ID (the SPA/public client you created in Prerequisites):

```bash
export OAUTH_CLIENT_ID='your-mcp-client-id'
python demo.py
```

The script opens your browser for IdP authentication. After you log in, it captures the
callback automatically and continues in the terminal.

#### Expected output

```
=== Step 1: Discover Protected Resource Metadata ===
[401] WWW-Authenticate: Bearer resource_metadata="http://localhost:8000/.well-known/oauth-protec...
[PRM] Fetching: http://localhost:8000/.well-known/oauth-protected-resource/ecommerce-mcp
[PRM] Resource: http://localhost:8000/ecommerce-mcp
[PRM] Authorization server: https://your-org.okta.com/oauth2/default
[PRM] Scopes: openid

=== Step 2: Discover OIDC Configuration ===
[OIDC] Fetching: https://your-org.okta.com/oauth2/default/.well-known/openid-configuration
[OIDC] Authorization endpoint: https://your-org.okta.com/oauth2/default/v1/authorize
[OIDC] Token endpoint: https://your-org.okta.com/oauth2/default/v1/token

=== Step 3: OAuth 2.1 Authorization Code + PKCE ===
[AUTH] Opening browser for authentication...
[AUTH] Callback listening on http://localhost:8085/callback
[AUTH] Waiting for authorization callback (120 s timeout)...
[AUTH] Authorization code received — exchanging for token...
[AUTH] Access token obtained (expires in 3600s)

=== Step 4: Connect to MCP Server ===
[MCP] Connected — server: kong
[MCP] Protocol version: 2025-06-18

=== Step 5: List Available Tools ===
[TOOLS] 5 tool(s) available for your consumer group:

  list-orders                  List recent orders with optional filters...  (read-only)
  get-order                    Get full details for a specific order...  (read-only)
  list-inventory               List inventory items with optional filters...  (read-only)
  check-inventory              Check current stock level and details...  (read-only)
  restock-item                 Add units to a product's inventory...  (destructive)

=== Step 6: Call a Permitted Tool ===
[CALL] check-inventory(sku="WIDGET-42")
[RESULT] {"url": "https://httpbin.konghq.com/anything/inventory/WIDGET-42", ...}

=== Step 7: Attempt a Restricted Tool ===
[CALL] cancel-order(orderId="ORD-001")
[NOTE] cancel-order requires the customer-support group

[ACL DENIED] Tool 'cancel-order' is not available for your consumer group

=== Demo complete ===
```

{:.no-copy-code}

#### What happened

1. **PRM discovery (Step 1)** — The script sent an unauthenticated MCP `initialize` request to
  `/ecommerce-mcp`. The ai-mcp-oauth2 plugin returned `401` with a `WWW-Authenticate` header
   containing the PRM endpoint URL. The script fetched the PRM to learn which authorization
   server to use and what scopes to request.
2. **OIDC discovery (Step 2)** — The script fetched the authorization server's
  `.well-known/openid-configuration` to discover the authorization and token endpoints.
3. **OAuth flow (Step 3)** — The script generated a PKCE code verifier and challenge, opened
  your browser to the authorization endpoint, and waited for the callback. After you
   authenticated, it exchanged the authorization code for an access token.
4. **MCP connection (Step 4)** — The script connected to the aggregated MCP endpoint with
  the Bearer token. The ai-mcp-oauth2 plugin introspected the token, mapped the `sub` claim
   to a Kong consumer, and mapped the `groups` claim to consumer groups.
5. **Tool listing (Step 5)** — The `warehouse-ops` user sees 5 tools. The `cancel-order`,
  `get-customer`, and `update-customer-contact` tools are not shown because they require the
   `customer-support` group. If you log in as a `customer-support` user, you would see 7 tools
   (everything except `restock-item`).
6. **Permitted tool call (Step 6)** — `check-inventory` succeeded because `warehouse-ops` is
  in its ACL allow list. The response comes from httpbin echoing the request details.
7. **ACL denial (Step 7)** — `cancel-order` was denied because `warehouse-ops` is not in its
  ACL allow list (only `customer-support` is). The ai-mcp-proxy plugin returned an
   `INVALID_PARAMS (-32602)` error.

If you already have an access token (from a previous run or another tool), you can skip the
browser flow entirely:

```bash
export MCP_ACCESS_TOKEN='your-token'
python demo.py
```

### Agent demo: LLM-powered tool use with ACL constraints (optional)

The `demo_agent.py` script connects an LLM agent to the aggregated MCP server and gives it a
task that requires tools from multiple domains. The agent discovers tools, attempts to complete
each step, and encounters ACL boundaries — demonstrating how Kong constrains AI agent
capabilities at the gateway level without the agent or the LLM having any awareness of the
access control policies.

This demo requires an MCP access token (from the basic demo above) and access to any LLM
provider with an OpenAI-compatible API. The script uses the OpenAI Python SDK, which works
with any provider that supports the same chat completions format.

Set your MCP access token and select your LLM provider:

```bash
export MCP_ACCESS_TOKEN='your-token'
```

{% navtabs "LLM Provider" %}
{% tab OpenAI %}

```bash
export OPENAI_API_KEY='your-openai-key'
export LLM_MODEL='gpt-4o'
python demo_agent.py
```

{% endtab %}
{% tab Anthropic %}

```bash
export OPENAI_API_KEY='your-anthropic-key'
export LLM_BASE_URL='https://api.anthropic.com/v1/'
export LLM_MODEL='claude-sonnet-4-6'
python demo_agent.py
```

{% endtab %}
{% tab AWS Bedrock %}

```bash
export OPENAI_API_KEY='your-aws-access-key'
export LLM_BASE_URL='https://bedrock-runtime.us-east-1.amazonaws.com'
export LLM_MODEL='anthropic.claude-sonnet-4-6-20250929-v1:0'
python demo_agent.py
```

{% endtab %}
{% tab Azure %}

```bash
export OPENAI_API_KEY='your-azure-api-key'
export LLM_BASE_URL='https://your-instance.openai.azure.com/openai/deployments/your-deployment'
export LLM_MODEL='your-deployment-name'
python demo_agent.py
```

{% endtab %}
{% tab Google Gemini %}

```bash
export OPENAI_API_KEY='your-gcp-api-key'
export LLM_BASE_URL='https://generativelanguage.googleapis.com/v1beta/openai/'
export LLM_MODEL='gemini-2.0-flash'
python demo_agent.py
```

{% endtab %}
{% tab Mistral %}

```bash
export OPENAI_API_KEY='your-mistral-key'
export LLM_BASE_URL='https://api.mistral.ai/v1'
export LLM_MODEL='mistral-large-latest'
python demo_agent.py
```

{% endtab %}
{% endnavtabs %}

The agent is given a multi-step task that intentionally crosses ACL boundaries:

1. Check if SKU `WIDGET-42` is in stock
2. Look up order `ORD-1001` to see its status
3. Cancel order `ORD-1001` if it's still pending
4. Get customer `C-500`'s contact info

#### Expected output (warehouse-ops user)

```
=== Connecting to MCP Server ===
[MCP] 5 tool(s) available
  - list-orders
  - get-order
  - list-inventory
  - check-inventory
  - restock-item

=== Agent Task ===
I need you to help me with a few things:
1. Check if SKU 'WIDGET-42' is in stock
2. Look up order ORD-1001 to see its status
3. Cancel order ORD-1001 if it's still pending
4. Get customer C-500's contact info
Please try each step and report what happened.

=== Agent Execution ===

[ROUND 1] Calling: check-inventory({"sku": "WIDGET-42"})
  [SUCCESS] {"url": "https://httpbin.konghq.com/anything/inventory/WIDGET-42", ...}

[ROUND 1] Calling: get-order({"orderId": "ORD-1001"})
  [SUCCESS] {"url": "https://httpbin.konghq.com/anything/orders/ORD-1001", ...}

[ROUND 2] Calling: cancel-order({"orderId": "ORD-1001"})
  [ACL DENIED] Tool 'cancel-order' not available for your consumer group

[ROUND 3] Calling: get-customer({"customerId": "C-500"})
  [ACL DENIED] Tool 'get-customer' not available for your consumer group

=== Agent Summary ===
Here's what happened with each step:

1. **Check inventory for WIDGET-42**: Successfully retrieved inventory data. The SKU exists
   in the system.
2. **Look up order ORD-1001**: Successfully retrieved order details.
3. **Cancel order ORD-1001**: Access denied. My account does not have permission to cancel
   orders — this action requires the customer-support role.
4. **Get customer C-500's contact info**: Access denied. My account does not have permission
   to access customer data — this also requires the customer-support role.

=== Agent demo complete ===
```

{:.no-copy-code}

The agent was able to check inventory and look up orders (both allowed for `warehouse-ops`),
but was blocked from cancelling orders and accessing customer data (both restricted to
`customer-support`). The agent reported the access boundaries clearly without any confusion —
Kong enforced the policies transparently at the gateway level.

## Cleanup

The recipe's `select_tags` and kongctl namespace scoped all resources, so this teardown removes
only this recipe's configuration. Tear down the local data plane and delete the control plane
from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='secure-internal-mcp-gateway-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```

