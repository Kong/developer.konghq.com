---

title: Secure Internal MCP Gateway
description: Aggregate multiple internal APIs into a single MCP server with OAuth 2.1 authentication and tool-level access control via consumer-group ACLs.
url: "/cookbooks/secure-internal-mcp-gateway/"
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
categories:
  - mcp
  - access-control
featured: false
popular: false

# Machine-readable fields for AI agent setup

plugins:
  - ai-mcp-proxy
  - ai-mcp-oauth2
  - cors
requires_embeddings: false
extra_services:
  - name: Identity Provider (Okta or Keycloak)
    env_vars: [DECK_OAUTH_AUTH_SERVER, DECK_OAUTH_INTROSPECTION_URL, DECK_OAUTH_CLIENT_ID, DECK_OAUTH_CLIENT_SECRET]
    hint: "Create an OAuth application for Kong (API Services / Client Credentials) and one for MCP clients (SPA / Authorization Code + PKCE). See the Identity Provider section in Prerequisites."

hint: "Requires an identity provider (Okta or Keycloak) with token introspection support and Insomnia 12+ for testing."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"      
      content: |
        This tutorial uses {{site.konnect_product_name}}. You will provision a recipe-scoped Control Plane and local Data Plane via the [quickstart script](https://get.konghq.com/quickstart).

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token and the recipe-scoped Control Plane name:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           export KONNECT_CONTROL_PLANE_NAME='secure-internal-mcp-gateway-recipe'
           ```

        1. Run the quickstart script:

           ```bash
           curl -Ls https://get.konghq.com/quickstart | bash -s -- -k $KONNECT_TOKEN --deck-output
           ```

           This provisions a Konnect Control Plane named `secure-internal-mcp-gateway-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars. Paste those into your shell when prompted.
    - title: kongctl + decK
      content: |
        This tutorial uses [kongctl](/kongctl/) and [decK](/deck/) to manage Kong configuration.

        1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
        1. Install **decK** version 1.43 or later from [docs.konghq.com/deck](https://docs.konghq.com/deck/).
        1. Verify both are installed:

           ```bash
           kongctl version
           deck version
           ```
    - title: Identity Provider (Okta or Keycloak)
      content: |
        You need an OAuth 2.1 identity provider that supports **token introspection** (RFC 7662).
        Select your IdP below and follow the setup steps.

        Set the MCP resource URL once. Both IdP tabs use the same value:

        ```bash
        export DECK_MCP_RESOURCE_URL='http://localhost:8000/ecommerce-mcp'
        ```

        {% navtabs "Identity Provider" %}
        {% tab Okta %}

        You need an Okta organization with admin access. You will create two applications.

        **1. {{site.base_gateway}} application (API Services)**

        This represents Kong as the resource server. Kong uses it to validate tokens via introspection.

        1. In the Okta Admin Console, go to **Applications → Create App Integration**.
        1. Select **API Services** (machine-to-machine).
        1. Name it `Kong MCP Gateway`.
        1. Note the **Client ID** and **Client Secret**. These are your `DECK_OAUTH_CLIENT_ID` and
          `DECK_OAUTH_CLIENT_SECRET`.

        **2. MCP Client application (SPA)**

        This represents the MCP client (the demo script, or any MCP-compatible tool).

        1. In the Okta Admin Console, go to **Applications → Create App Integration**.
        1. Select **OIDC - OpenID Connect** and **Single-Page Application**.
        1. Name it `MCP Client`.
        1. Set the sign-in redirect URI to `http://localhost:8085/callback`.
        1. Enable **Authorization Code + PKCE** as the grant type.
        1. Assign the application to your users.
        1. Note the **Client ID**. This is your `OAUTH_CLIENT_ID` for the demo script.

        {:.warning}

        > You must create an **SPA** application, not a **Web** application. Even if you enable PKCE on
        > a Web application, the OAuth flow will not complete correctly with MCP clients that do not send
        > a client secret.

        **3. Configure groups claim**

        The AI MCP OAuth2 Plugin uses the `groups` claim in access tokens to map users to Kong
        Consumer Groups. Configure your Okta authorization server to include this claim:

        1. Go to **Security → API → Authorization Servers** and select your authorization server
          (for example, `default`).
        1. Go to the **Claims** tab and add a new claim:
          - **Name:** `groups`
          - **Include in token type:** Access Token
          - **Value type:** Groups
          - **Filter:** Matches regex `.*` (or restrict to specific groups)
        1. Go to the **Scopes** tab and ensure `openid` is present.

        **4. Create Okta groups**

        Create two groups in Okta that match the Kong Consumer Group names:

        1. Go to **Directory → Groups** and create:
          - `warehouse-ops`
          - `customer-support`
        1. Assign your test users to the appropriate groups.

        **5. Export the Okta endpoints and credentials**

        ```bash
        export DECK_OAUTH_AUTH_SERVER='https://your-org.okta.com/oauth2/default'
        export DECK_OAUTH_INTROSPECTION_URL='https://your-org.okta.com/oauth2/default/v1/introspect'
        export DECK_OAUTH_CLIENT_ID='your-kong-client-id'
        export DECK_OAUTH_CLIENT_SECRET='your-kong-client-secret'
        ```

        {% endtab %}
        {% tab Keycloak %}

        You need a Keycloak instance with admin access. You will create a realm, two clients, and
        configure group mappings.

        **1. Create a realm** (or use an existing one)

        1. In the Keycloak Admin Console, create a new realm (for example, `mcp-demo`).

        **2. {{site.base_gateway}} client (Confidential)**

        This client represents Kong as the resource server for token introspection.

        1. Go to **Clients → Create client**.
        1. Set **Client ID** to `kong-mcp-gateway`.
        1. Set **Client authentication** to **On** (confidential client).
        1. Enable **Service accounts roles**.
        1. Note the **Client ID** and **Client Secret** from the **Credentials** tab. These are your
          `DECK_OAUTH_CLIENT_ID` and `DECK_OAUTH_CLIENT_SECRET`.

        **3. MCP Client (Public)**

        This client represents the MCP client application.

        1. Go to **Clients → Create client**.
        1. Set **Client ID** to `mcp-client`.
        1. Set **Client authentication** to **Off** (public client).
        1. Set **Valid redirect URIs** to `http://localhost:8085/callback`.
        1. Enable **Standard flow** (Authorization Code).
        1. Note the **Client ID**. This is your `OAUTH_CLIENT_ID` for the demo script.

        **4. Configure groups claim**

        By default, Keycloak does not include a `groups` claim in access tokens. Add a client scope
        and mapper:

        1. Go to **Client scopes → Create client scope**.
        1. Name it `groups`, set type to **Default**.
        1. In the scope, go to **Mappers → Create mapper**:
          - **Mapper type:** Group Membership
          - **Name:** `groups`
          - **Token Claim Name:** `groups`
          - **Full group path:** Off
          - **Add to access token:** On
        1. Go to **Clients → kong-mcp-gateway → Client scopes** and add the `groups` scope.
        1. Repeat for the `mcp-client` client.

        **5. Create groups and users**

        1. Go to **Groups** and create:
          - `warehouse-ops`
          - `customer-support`
        1. Create test users and assign them to the appropriate groups.

        **6. Export the Keycloak endpoints and credentials**

        ```bash
        export DECK_OAUTH_AUTH_SERVER='https://your-keycloak-host/realms/mcp-demo'
        export DECK_OAUTH_INTROSPECTION_URL='https://your-keycloak-host/realms/mcp-demo/protocol/openid-connect/token/introspect'
        export DECK_OAUTH_CLIENT_ID='kong-mcp-gateway'
        export DECK_OAUTH_CLIENT_SECRET='your-kong-client-secret'
        ```

        {:.info}

        > **Keycloak groups claim.** Ensure you configured the `groups` client scope and mapper above. Without it, the access token will not contain a `groups` claim and Consumer Group mapping will fail.

        {% endtab %}
        {% endnavtabs %}
    - title: Insomnia 12+
      content: |
        This recipe verifies the gateway using [Insomnia](https://insomnia.rest/), Kong's MCP-aware API client. Insomnia speaks the MCP protocol natively and handles the full OAuth 2.1 + PKCE dance, including Protected Resource Metadata (PRM) discovery.

        1. Install **Insomnia** from [insomnia.rest/download](https://insomnia.rest/download).
        1. Verify the version is 12.0 or later (Help → About on macOS, equivalent on other platforms).

        See [MCP clients in Insomnia](/insomnia/mcp-clients-in-insomnia/) for an overview of MCP server testing in Insomnia.
overview: |
  Organizations adopting MCP (Model Context Protocol) face a common challenge when multiple API teams each expose tools but there is no centralized control over who can discover and call those tools. This recipe places {{site.base_gateway}} in front of internal MCP servers as a single aggregated endpoint. Each API team independently defines their tools and access policies using the [AI MCP Proxy](/plugins/ai-mcp-proxy/) Plugin in `conversion-only` mode, while a central platform team aggregates those tools into one MCP server using `listener` mode, secures it with OAuth 2.1 via the [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin, and enforces per-tool access control through Consumer Group ACLs.

  There are broadly two types of MCP servers that Kong can proxy. Internal MCP servers are hosted within your organization's trust boundary, wrapping internal APIs such as databases, ticketing systems, and proprietary services where you control both the server and the authentication. External MCP servers are third-party services like GitHub, Slack, and Figma that manage their own authentication and issue their own tokens. Proxying external servers through Kong requires a different approach. See [Secure External MCP Gateway](/cookbooks/secure-external-mcp-gateway/) for that pattern.

---

## The problem

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
AI MCP OAuth2 Plugin), others do not. Most do not yet implement RFC 8707 (Resource Indicators),
which means audience validation requires workarounds.

## The solution

This recipe uses {{site.base_gateway}} as a federated MCP aggregation layer with three capabilities:

- **REST-to-MCP conversion.** Each API team applies the AI MCP Proxy Plugin in `conversion-only`
mode to their existing Kong Routes. This converts selected REST endpoints into MCP tools, tagged
for discovery. Teams control their own tool definitions and ACL policies.
- **Tool aggregation.** A central Route runs the AI MCP Proxy Plugin in `listener` mode, which
discovers all tagged tools and exposes them through a single MCP endpoint. MCP clients connect
to one URL and see a unified tool catalog.
- **OAuth 2.1 + ACLs.** The AI MCP OAuth2 Plugin handles the full MCP auth spec: Protected
Resource Metadata (PRM) discovery (RFC 9728), authorization code flow with PKCE, and token
introspection. In {{site.base_gateway}} 3.14+, the Plugin maps token claims directly to Kong Consumers
and Consumer Groups, enabling per-tool ACLs without a separate authentication Plugin.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP Client
    participant K as {{site.base_gateway}}
    participant IdP as Identity Provider
    participant B as Backend APIs

    C->>K: MCP initialize (no token)
    activate K
    K-->>C: 401 + WWW-Authenticate (PRM discovery, RFC 9728)
    deactivate K

    C->>IdP: OAuth 2.1 authorization code + PKCE
    activate IdP
    IdP-->>C: Bearer token
    deactivate IdP

    C->>K: MCP initialize (Bearer token)
    activate K
    K->>IdP: Token introspection
    activate IdP
    IdP-->>K: Claims (sub, groups)
    deactivate IdP
    K-->>C: Initialize OK (mapped to Consumer + Groups)
    deactivate K

    C->>K: tools/list
    activate K
    K-->>C: Aggregated tool catalog
    deactivate K

    C->>K: tools/call
    activate K
    alt ACL allowed (e.g. check-inventory)
        K->>B: Route to backend API
        activate B
        B-->>K: Response
        deactivate B
        K-->>C: Tool result
    else ACL denied (e.g. cancel-order)
        K-->>C: 403 (group not in allow list)
    end
    deactivate K
{% endmermaid %}
<!-- vale on -->

This recipe demonstrates the pattern with three mock ecommerce APIs (Orders, Inventory, Customers)
backed by httpbin, two Consumer Groups (`warehouse-ops` and `customer-support`), and OAuth
authentication via Okta or Keycloak.


| Component                                                         | Responsibility                                                                                    |
| ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Identity Provider (Okta / Keycloak)                               | OAuth 2.1 authorization server, user identity, group membership, token issuance and introspection |
| Kong - [AI MCP OAuth2](/plugins/ai-mcp-oauth2/)                   | MCP-native OAuth: PRM discovery, token introspection, Consumer and Consumer Group mapping (3.14+) |
| Kong - [AI MCP Proxy](/plugins/ai-mcp-proxy/) (`conversion-only`) | Converts REST API endpoints into MCP tools with per-tool ACL definitions                          |
| Kong - [AI MCP Proxy](/plugins/ai-mcp-proxy/) (`listener`)        | Aggregates tagged tools into a single MCP server, enforces ACLs at call time                      |
| Kong - [CORS](/plugins/cors/)                                     | Enables browser-based MCP clients to connect to the gateway                                       |
| Backend APIs (httpbin)                                            | Mock ecommerce services representing independent API teams                                        |


### ACL matrix

This recipe creates two Consumer Groups with different tool access:


| Tool                      | warehouse-ops | customer-support |
| ------------------------- | ------------- | ---------------- |
| `list-orders`             | yes           | yes              |
| `get-order`               | yes           | yes              |
| `cancel-order`            | no            | yes              |
| `list-inventory`          | yes           | yes              |
| `check-inventory`         | yes           | yes              |
| `restock-item`            | yes           | no               |
| `get-customer`            | no            | yes              |
| `update-customer-contact` | no            | yes              |


Warehouse operations staff can view orders and manage inventory (including restocking), but
cannot access customer data or cancel orders. Customer support agents can view orders, check
inventory, manage customer records, and cancel orders, but cannot restock inventory.

## How it works

A request flows through the system in these steps:

1. The client discovers the MCP server's OAuth requirements through the identity provider.
2. The client authenticates via PKCE flow and receives an access token.
3. The client connects to the MCP endpoint through Kong with the Bearer token.
4. Kong's AI MCP Proxy Plugin converts streamable HTTP to SSE for the upstream.
5. Kong's AI MCP OAuth2 Plugin validates the token via introspection and maps the user to a Consumer Group.
6. ACL rules determine which MCP tools the Consumer Group can access.
7. The upstream MCP server processes permitted tool calls and returns results through Kong.

### Step 1: Convert REST APIs to MCP tools

Each API team applies the AI MCP Proxy Plugin in `conversion-only` mode to their Kong Route.
This mode defines MCP tools that map to REST endpoints but does **not** serve them as a
standalone MCP server. Instead, it makes the tools available for aggregation via tags.

#### Configuration details

```yaml
plugins:
  - name: ai-mcp-proxy
    tags:
      - ecom-mcp                  # Discovery tag for the listener
    config:
      mode: conversion-only       # Define tools only, no MCP endpoint here
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

- **name** and **description** - what the tool does (visible to MCP clients and LLM agents)
- **method** and **path** - the REST endpoint this tool maps to
- **annotations** - MCP hints like `read_only_hint` and `destructive_hint` that help agents
understand the tool's behavior
- **acl** - which Consumer Groups can call this tool. Completely overrides `default_acl` when set.
- **parameters** - OpenAPI 3.0 parameter definitions

The `tags` field on the Plugin entity (not the config) is what the listener uses for discovery.
All conversion-only Plugins that should be aggregated share the same tag (`ecom-mcp`).

This pattern maps naturally to Kong's federated API management model: each API team manages
their own Service and Route in their own control plane or namespace, and they decide which
endpoints to expose as tools and who can call them. The central platform team doesn't need
to touch individual team configurations.

{:.info}

> **Automatic conversion from OpenAPI specs.** Starting with decK v1.57, the
> `deck file openapi2mcp` command can generate ai-mcp-proxy tool definitions directly from
> an OpenAPI specification, removing the need to write tool configs by hand. This is especially
> useful for APIs that already have well-documented OpenAPI specs.

{:.info}

> **Tool design for production.** Automatic REST-to-MCP conversion, whether from Plugin config
> or OpenAPI specs, is a great way to get started and works well for simpler APIs where each
> endpoint maps cleanly to a user action. For more complex workflows, consider designing
> higher-level tools that encapsulate complete user goals. A single `process-return(orderId, reason)` tool that handles lookup, validation, and cancellation internally tends to be more
> reliable for LLM agents than three separate endpoint-mapped tools the agent must orchestrate.
> LLMs are stateless. They rediscover tools every conversation and cannot reuse prior
> orchestration logic. The right balance depends on your APIs: use automatic conversion where
> endpoints are self-contained, and build workflow tools where operations span multiple steps.

### Step 2: Aggregate tools into one MCP server

The platform team creates a single Route with the AI MCP Proxy Plugin in `listener` mode.
The listener discovers all `conversion-only` Plugins matching the configured tag and exposes
their combined tool catalog as one MCP server.

#### Configuration details

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
from the tagged conversion-only Plugins. When a tool is called, the listener evaluates the
caller's Consumer Group against the tool's ACL before routing the request to the backend Service.

`include_consumer_groups: true` is **required** on the listener for group-based ACLs to work.
Without it, the listener cannot pass Consumer Group membership to the ACL evaluation logic.

### Step 3: Authenticate with OAuth 2.1

The AI MCP OAuth2 Plugin implements the full MCP authentication specification:

1. **PRM discovery (RFC 9728).** When an MCP client connects without a token, the Plugin
  returns `401` with a `WWW-Authenticate` header pointing to the Protected Resource Metadata
   endpoint. The metadata advertises which authorization server to use and what scopes to request.
1. **Token introspection (RFC 7662).** When a client presents a Bearer token, the Plugin
  validates it by calling the IdP's introspection endpoint using the configured client
   credentials. Introspection responses are cached by default to reduce load on the IdP.
1. **Consumer mapping (3.14+).** The Plugin maps token claims directly to Kong Consumers and
  Consumer Groups:
  - `consumer_claim: [sub]` looks up a Kong Consumer whose `username` or `custom_id` matches
  the token's `sub` claim.
  - `consumer_groups_claim: [groups]` maps the token's `groups` claim to Kong Consumer Groups.
  - If no Consumer is found, `credential_claim: [sub]` sets a credential identifier so
  downstream Plugins can still identify the caller.

#### Configuration details

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

{:.warning}

> **`insecure_relaxed_audience_validation: true`**. Most identity providers do not yet
> implement RFC 8707 (Resource Indicators for OAuth 2.0), so the `aud` claim in access tokens
> will not match the MCP resource URL. This flag relaxes audience validation until your IdP
> supports RFC 8707. Without it, all requests will be rejected with an audience mismatch error.

The Route that hosts this Plugin includes two paths:

- `/ecommerce-mcp` - the MCP endpoint itself
- `/.well-known/oauth-protected-resource/ecommerce-mcp` - the PRM discovery path

The second path ensures that MCP clients which ignore the `resource_metadata` URL in the
`WWW-Authenticate` header and fall back to
[standard PRM locations](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization#protected-resource-metadata-discovery-requirements)
can still discover the metadata.

### Step 4: Enforce tool-level ACLs

ACLs in ai-mcp-proxy use a two-tier system:

- **`default_acl`**. Baseline rules applied to all tools that don't define their own ACL.
- **Per-tool `acl`**. When a tool defines `acl.allow` or `acl.deny`, it **completely overrides**
the default. There is no merging or inheritance between the two tiers.

In this recipe, every tool defines its own `acl.allow` list specifying which Consumer Groups can
call it. Deny takes precedence over allow. If a Consumer appears in both lists, they are denied.

When the listener receives a `tools/call` request:

1. It resolves the caller's Consumer Group from the authenticated Consumer (mapped by
  ai-mcp-oauth2's `consumer_groups_claim`)
2. It evaluates the tool's ACL against the caller's groups
3. If the caller is not in the allow list, the request is rejected with
  `INVALID_PARAMS (-32602)`

{:.info}
> In production, store credentials in [Kong Vaults](/gateway/entities/vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. Kong supports HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the Konnect Config Store.

### IdP compatibility

The AI MCP OAuth2 Plugin requires token introspection (RFC 7662). Not all identity providers
support this. The table below summarizes compatibility:


| Identity Provider      | Introspection | Compatible | Notes                                                                                                                                         |
| ---------------------- | ------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Okta**               | Yes           | Yes        | Full RFC 7662 support. Endpoint: `https://{domain}/oauth2/{authServerId}/v1/introspect`                                                       |
| **Keycloak**           | Yes           | Yes        | Full RFC 7662 support. Endpoint: `/realms/{realm}/protocol/openid-connect/token/introspect`                                                   |
| **Ping Identity**      | Yes           | Yes        | Supports token introspection per RFC 7662                                                                                                     |
| **FusionAuth**         | Yes           | Yes        | Supports RFC 7662 token introspection                                                                                                         |
| **ORY Hydra**          | Yes           | Yes        | Open source OAuth2 server with full RFC 7662 support                                                                                          |
| **Microsoft Entra ID** | No            | No         | Does not provide an introspection endpoint. Use JWKS-based JWT validation with the [OpenID Connect](/plugins/openid-connect/) Plugin instead. |
| **Auth0**              | No            | No         | Does not support RFC 7662 introspection. Use JWKS-based JWT validation instead.                                                               |
| **AWS Cognito**        | No            | No         | Does not provide an introspection endpoint. Use JWKS-based JWT validation instead.                                                            |
| **Google OAuth2**      | Partial       | No         | Has a tokeninfo endpoint but it is not RFC 7662 compliant.                                                                                    |


For IdPs that do not support introspection, you can achieve similar functionality using the
[OpenID Connect](/plugins/openid-connect/) Plugin with JWKS-based JWT validation and the
`consumer_claim` parameter. This requires additional configuration: a pre-function or datakit
Plugin to serve the PRM endpoint and return the `WWW-Authenticate` header. A future recipe
will cover this pattern in detail.

### Example responses

The unique value Kong adds at this Route is the OAuth-aware MCP boundary. The two responses
below show what an unauthenticated request and an authenticated `tools/list` call look like
in this recipe.

A `POST /ecommerce-mcp` with no Bearer token returns:

```text
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer resource_metadata="http://localhost:8000/.well-known/oauth-protected-resource/ecommerce-mcp"
Content-Type: application/json

{"error":"unauthorized","error_description":"Missing access token"}
```
{:.no-copy-code}

The `WWW-Authenticate` header is what makes the endpoint MCP-spec compliant. MCP clients read
the `resource_metadata` URL, fetch the PRM document, and discover the authorization server.

After the OAuth flow completes, an authenticated `tools/list` from a `warehouse-ops` user
returns only the five tools that group is allowed to see:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "tools": [
      { "name": "list-orders",     "annotations": { "readOnlyHint": true } },
      { "name": "get-order",       "annotations": { "readOnlyHint": true } },
      { "name": "list-inventory",  "annotations": { "readOnlyHint": true } },
      { "name": "check-inventory", "annotations": { "readOnlyHint": true } },
      { "name": "restock-item",    "annotations": { "destructiveHint": true } }
    ]
  }
}
```
{:.no-copy-code}

The three customer-only tools (`cancel-order`, `get-customer`, `update-customer-contact`) are
filtered out by Kong before the response leaves the Gateway, so the agent never sees them in
its tool catalog. Kong attaches the standard latency headers below on every authenticated call.

| Header                    | Description                                                      |
| ------------------------- | ---------------------------------------------------------------- |
| `X-Kong-Upstream-Latency` | Time (ms) Kong spent waiting for the upstream MCP server         |
| `X-Kong-Proxy-Latency`    | Time (ms) Kong spent processing the request (auth, ACL, routing) |

## Apply the Kong configuration

The following configuration creates four {{site.base_gateway}} Services (three ecommerce APIs plus one
aggregated MCP server), eight MCP tools with per-tool ACLs, two Consumer Groups, OAuth 2.1
authentication via the AI MCP OAuth2 Plugin, and CORS support. All resources are scoped using
`select_tags` and a kongctl `namespace` for clean teardown.

The IdP-specific environment variables (`DECK_OAUTH_*`) and the shared `DECK_MCP_RESOURCE_URL`
are already exported during the Identity Provider prereq, so they do not need to be re-exported
here. The configuration below is identical regardless of which IdP you selected. The AI MCP OAuth2
Plugin resolves the IdP endpoints from those variables at apply time.

First, adopt the Control Plane into a kongctl namespace so subsequent `kongctl sync` calls can
manage it. The `--pat` flag authenticates kongctl with the same Konnect PAT exported during the
{{site.konnect_product_name}} prereq, so you do not need to run `kongctl login konnect` interactively.

```bash
kongctl adopt control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the Control Plane. Without it, kongctl treats
the quickstart-created Control Plane as foreign and refuses to mutate it.

Then apply the Kong configuration:

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
    protocols:
    - http
    - https
    plugins:
    - name: ai-mcp-proxy
      tags:
      - secure-internal-mcp-gateway-recipe
      - ecom-mcp
      config:
        mode: conversion-only
        consumer_identifier: username
        include_consumer_groups: true
        max_request_body_size: 1048576
        ssl_verify: true
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
    protocols:
    - http
    - https
    plugins:
    - name: ai-mcp-proxy
      tags:
      - secure-internal-mcp-gateway-recipe
      - ecom-mcp
      config:
        mode: conversion-only
        consumer_identifier: username
        include_consumer_groups: true
        max_request_body_size: 1048576
        ssl_verify: true
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
    protocols:
    - http
    - https
    plugins:
    - name: ai-mcp-proxy
      tags:
      - secure-internal-mcp-gateway-recipe
      - ecom-mcp
      config:
        mode: conversion-only
        consumer_identifier: username
        include_consumer_groups: true
        max_request_body_size: 1048576
        ssl_verify: true
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
    protocols:
    - http
    - https
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
        ssl_verify: true
        max_request_body_size: 1048576
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
        max_request_body_size: 1048576
        ssl_verify: true
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
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

## Try it out

With the configuration applied and your IdP configured, the aggregated MCP endpoint is ready to accept authenticated connections. The verification path below uses [Insomnia](/insomnia/mcp-clients-in-insomnia/), Kong's MCP-aware API client, to exercise the full OAuth + ACL flow. Once verified, the same endpoint can be plugged into any MCP-compatible AI client.

### Verify with Insomnia

Insomnia speaks the MCP protocol natively. It auto-discovers Protected Resource Metadata (PRM) from a 401 response, runs the OAuth 2.1 + PKCE dance against the IdP, and exposes every step of the auth handshake in its **Events** panel with full request/response inspection.

To verify the gateway:

1. **Create an MCP request.** In Insomnia, create a new request and select **MCP** as the request type. Enter the gateway URL:

    ```text
    http://localhost:8000/ecommerce-mcp
    ```
    {:.no-copy-code}

1. **Initiate the connection.** Insomnia sends an MCP `initialize` request without credentials. Kong's [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin returns `401` with a `WWW-Authenticate: Bearer resource_metadata=...` header pointing at `/.well-known/oauth-protected-resource/ecommerce-mcp`. The **Events** tab shows the unauthenticated initialize, the 401, and Insomnia's follow-up GET against the PRM URL. Selecting any entry exposes the raw JSON request and response.

1. **Complete OAuth.** Insomnia opens your browser to the IdP's authorization endpoint with a generated PKCE code challenge. Sign in as a `warehouse-ops` user, approve the application, and Insomnia captures the redirect, exchanges the authorization code for an access token, and reconnects to the MCP endpoint with `Authorization: Bearer <token>`. The OAuth handshake appears as a sequence of `MCP Auth` entries in the **Events** tab.

1. **List tools.** With the connection authenticated, Insomnia populates its tool browser. As `warehouse-ops`, you'll see five tools: `list-orders`, `get-order`, `list-inventory`, `check-inventory`, `restock-item`. The three customer-only tools (`cancel-order`, `get-customer`, `update-customer-contact`) are filtered out — Kong evaluated the `consumer_groups_claim` against each tool's ACL before returning the catalog. Reauthenticating as a `customer-support` user produces seven tools instead, with `restock-item` filtered out.

1. **Call a permitted tool.** Select `check-inventory`, set `sku` to `WIDGET-42`, and call it. The call succeeds; the response body shows the proxied call to the inventory backend (httpbin echoes the request details in this recipe). Inspect the response headers — Kong attaches `X-Kong-Upstream-Latency` (time waiting for the upstream) and `X-Kong-Proxy-Latency` (time spent in Kong on auth, ACL, and routing).

1. **Call a restricted tool.** Manually invoke `cancel-order` (the tool name can be entered directly even though it's hidden from the catalog — this simulates a misbehaving client). Kong returns an MCP error with code `INVALID_PARAMS (-32602)` and a body explaining the tool is not available for your Consumer Group. The token was valid; Kong's ACL evaluated it and denied the call before the request reached any upstream.

1. **(Optional) Verify the auth boundary.** Replace the captured access token with `not-a-real-token` and resend the initialize. Kong's introspection call rejects the token and the AI MCP OAuth2 Plugin returns the same `401 + WWW-Authenticate` response as the unauthenticated case. This confirms invalid credentials never bypass auth.

### Connect a real MCP client

The same gateway URL works in any MCP-compatible AI client. Each client handles OAuth differently — follow the upstream documentation for the client's configuration mechanics. The values below cover the gateway-specific bits.

| Client | Documentation | Configuration |
|--------|---------------|---------------|
| Claude Code | [code.claude.com/docs/en/mcp](https://code.claude.com/docs/en/mcp) | `claude mcp add --transport http ecommerce-mcp http://localhost:8000/ecommerce-mcp` (Claude Code completes the OAuth flow automatically on first use). |
| VS Code | [vscode-docs/copilot/reference/mcp-configuration.md](https://github.com/microsoft/vscode-docs/blob/main/docs/copilot/reference/mcp-configuration.md) | Add to `.vscode/mcp.json`: `{"servers": {"ecommerce-mcp": {"type": "http", "url": "http://localhost:8000/ecommerce-mcp"}}}`. Requires VS Code 1.101+. |
| Claude Desktop | [Get started with custom connectors using remote MCP](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp) | Customize → Connectors → Add custom connector. The gateway must be reachable from Anthropic's IPs, so this client only works once Kong is deployed publicly — `http://localhost:8000` is not reachable from Claude Desktop. |

Once connected, ask the agent two questions: a permitted one (`Check stock for SKU WIDGET-42`) and a restricted one (`Cancel order ORD-1001`). The first succeeds and returns inventory data; the second is reported as denied because Kong filters the tool from the catalog or returns an ACL error on the call. The same enforcement applies regardless of which MCP client connects — the gateway is the policy boundary.

### Explore in Konnect

Open [Konnect](https://cloud.konghq.com/) and inspect the resources Kong created:

- **API Gateway → Gateways → `secure-internal-mcp-gateway-recipe`** shows the recipe-scoped Control Plane.
- The **Gateway Services** tab lists the four Services: `orders-api`, `inventory-api`, `customers-api`, and `aggregated-mcp-server`.
- The **Routes** tab shows the four Routes, including `ecommerce-mcp` with both the MCP path and the PRM well-known path.
- The **Plugins** tab lists every Plugin instance: three `ai-mcp-proxy` (conversion-only), one `ai-mcp-proxy` (listener), one `ai-mcp-oauth2`, and one `cors`.
- The **Consumers** tab shows `warehouse-user` and `support-user`, and the **Consumer Groups** tab shows `warehouse-ops` and `customer-support` with their memberships.
- The **Analytics** tab on the `aggregated-mcp-server` Service gives an at-a-glance view of recipe traffic, including request counts and latency for both successful tool calls and ACL denials.
- The **Observability** L1 menu in Konnect surfaces deeper request and consumer breakdowns across all Services in the Control Plane.

## Variations and next steps

- **Add rate limiting per Consumer Group.** Attach the [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) Plugin to enforce per-tier token budgets, giving premium Consumer Groups higher quotas while protecting shared infrastructure.
- **Expand to multiple MCP servers.** Add additional Services and Routes for other internal MCP servers (databases, monitoring, CI/CD). Each gets its own ACL configuration while sharing the same OAuth authentication flow.
- **Add response logging for audit trails.** Enable payload logging on the AI MCP Proxy Plugin to capture tool calls and responses for compliance auditing.
- **Integrate with external identity providers.** Replace the Okta configuration with Azure AD, Auth0, or Keycloak by updating the OAuth endpoints in the deck config.

## Cleanup

The recipe's `select_tags` and kongctl namespace scoped all resources, so this teardown removes
only this recipe's configuration. Tear down the local data plane and delete the control plane
from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='secure-internal-mcp-gateway-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```
