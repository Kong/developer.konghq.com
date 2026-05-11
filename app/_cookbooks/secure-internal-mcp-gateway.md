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

hint: "Requires an OAuth 2.1 identity provider (Okta or Keycloak in this recipe) and Insomnia 12+ for testing."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. The [quickstart script](https://get.konghq.com/quickstart) provisions a recipe-scoped Control Plane and local Data Plane.

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped Control Plane name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='secure-internal-mcp-gateway-recipe'
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
    - title: Identity Provider
      content: |
        You need an OAuth 2.1 identity provider. This recipe shows setup steps for Okta and Keycloak, both of which expose an RFC 7662 token introspection endpoint that the AI MCP OAuth2 Plugin calls to validate tokens. Other IdPs (Microsoft Entra ID, Auth0, AWS Cognito, Google) work too. See the [AI MCP OAuth2 Plugin: Token validation methods](/plugins/ai-mcp-oauth2/#token-validation-methods) reference for the JWKS-based path. Select your IdP below and follow the setup steps.

        Set the MCP resource URL once. Both IdP tabs use the same value:

        ```bash
        export DECK_MCP_RESOURCE_URL='http://localhost:8000/ecommerce-mcp'
        ```

        {% navtabs "Identity Provider" %}
        {% tab Okta %}

        You need an Okta organization with admin access. The steps below create two Okta applications, configure a `groups` claim, create two groups, set up a test user (new or existing), and export Kong's introspection credentials.

        **Create the {{site.base_gateway}} application**

        This is a confidential client that represents Kong as the resource server. Kong uses its credentials to call Okta's token introspection endpoint.

        1. In the Okta Admin Console, go to **Applications → Create App Integration**.
        1. Select **API Services** (machine-to-machine).
        1. Name it `Kong MCP Gateway`.
        1. From the **General** tab, copy the **Client ID** and **Client Secret** under **Client Credentials**. Export these as `DECK_OAUTH_CLIENT_ID` and `DECK_OAUTH_CLIENT_SECRET` in the final step.

        **Create the MCP Client application**

        This is a public client that represents the MCP client (Insomnia, Claude Code, VS Code, or any MCP-compatible tool). Public clients use Authorization Code + PKCE without a client secret.

        1. In the Okta Admin Console, go to **Applications → Create App Integration**.
        1. Select **OIDC - OpenID Connect** and **Single-Page Application**, then click **Next**.
        1. Name it `MCP Client`.
        1. Set the sign-in redirect URI to `https://app.insomnia.rest/oauth/redirect`. This is Insomnia 12+'s built-in OAuth callback. To use a different MCP client later, register that client's redirect URI here too. The section in **Variations and next steps** covers this.
        1. On the application's **General** tab under **Client Credentials**, confirm that **Proof Key for Code Exchange (PKCE)** is checked. Okta enables it by default for SPA app types.
        1. Copy the **Client ID** for use in your MCP client. Insomnia and other MCP clients prompt for this value when they start the OAuth flow; the recipe does not export it as an environment variable.

        {:.warning}

        > Use the SPA application type, not Web. Okta SPA integrations are public clients with no client secret and use Authorization Code + PKCE by default. MCP clients perform the PKCE flow without sending a client secret, so Okta's token endpoint rejects the token exchange against a Web (confidential) integration even if PKCE is enabled on it.

        **Configure the groups claim**

        The AI MCP OAuth2 Plugin uses the `groups` claim in access tokens to map users to Kong Consumer Groups. Configure your Okta authorization server to include this claim:

        1. Go to **Security → API → Authorization Servers** and select your authorization server (for example, `default`).
        1. Go to the **Claims** tab and add a new claim:
          - **Name:** `groups`
          - **Include in token type:** Access Token
          - **Value type:** Groups
          - **Filter:** Matches regex `.*` (or restrict to specific groups)
        1. Go to the **Scopes** tab and ensure `openid` is present.

        **Set up Okta groups and a test user**

        Create two groups in Okta that match the Kong Consumer Group names, plus one user assigned to one of them:

        1. Go to **Directory → Groups** and create:
          - `warehouse-ops`
          - `customer-support`
        1. Go to **Directory → People** and either add a new person (for example, `mcp-test-user@example.com`) or pick an existing user. Make sure the user has a password set and can sign in.
        1. Open the user, go to the **Groups** tab, and assign them to `warehouse-ops`. To exercise the other persona later, move the same user to `customer-support` and reauthenticate from your MCP client. The IdP-issued `groups` claim drives Kong's ACLs, so changing the user's group is all that's needed.
        1. Open the `MCP Client` application created above, go to the **Assignments** tab, and assign the same user. Without this, Okta blocks the OAuth flow at sign-in.

        **Export Kong's Okta endpoints and credentials**

        Export the authorization server URL, the introspection endpoint, and the **{{site.base_gateway}}** application's Client ID and Secret. The MCP Client (SPA) Client ID is not exported here. It is used at flow time by the MCP client itself.

        ```bash
        export DECK_OAUTH_AUTH_SERVER='https://your-org.okta.com/oauth2/default'
        export DECK_OAUTH_INTROSPECTION_URL='https://your-org.okta.com/oauth2/default/v1/introspect'
        export DECK_OAUTH_CLIENT_ID='your-kong-gateway-client-id'
        export DECK_OAUTH_CLIENT_SECRET='your-kong-gateway-client-secret'
        ```

        {% endtab %}
        {% tab Keycloak %}

        You need a Keycloak instance with admin access. The steps below create a realm, two clients, configure a `groups` claim, create two groups, set up a test user (new or existing), and export Kong's introspection credentials.

        **Create a realm**

        In the Keycloak Admin Console, create a new realm (for example, `mcp-demo`), or use an existing one.

        **Create the {{site.base_gateway}} client**

        This is a confidential client that represents Kong as the resource server. Kong uses its credentials to call Keycloak's token introspection endpoint.

        1. Go to **Clients → Create client**.
        1. Set **Client ID** to `kong-mcp-gateway`.
        1. Set **Client authentication** to **On** (confidential client).
        1. Enable **Service accounts roles**.
        1. From the **Credentials** tab, copy the **Client Secret**. Export the Client ID (`kong-mcp-gateway`) as `DECK_OAUTH_CLIENT_ID` and this secret as `DECK_OAUTH_CLIENT_SECRET` in the final step.

        **Create the MCP Client**

        This is a public client that represents the MCP client (Insomnia, Claude Code, VS Code, or any MCP-compatible tool). Public clients use Authorization Code + PKCE without a client secret.

        1. Go to **Clients → Create client**.
        1. Set **Client ID** to `mcp-client`.
        1. Set **Client authentication** to **Off** (public client).
        1. Set **Valid redirect URIs** to `https://app.insomnia.rest/oauth/redirect`. This is Insomnia 12+'s built-in OAuth callback. To use a different MCP client later, add that client's redirect URI here too. The section in **Variations and next steps** covers this.
        1. Enable **Standard flow** (Authorization Code) and confirm PKCE is required for public clients (Keycloak enforces PKCE for public clients automatically).
        1. Note the **Client ID** (`mcp-client`) for use in your MCP client. Insomnia and other MCP clients prompt for this value when they start the OAuth flow; the recipe does not export it as an environment variable.

        **Configure the groups claim**

        By default, Keycloak does not include a `groups` claim in access tokens. Add a client scope and mapper:

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

        **Set up groups and a test user**

        Create two groups that match the Kong Consumer Group names, plus one user assigned to one of them:

        1. Go to **Groups** and create:
          - `warehouse-ops`
          - `customer-support`
        1. Go to **Users** and either add a new user (for example, `mcp-test-user`) or pick an existing one. On the **Credentials** tab, set a password and clear **Temporary** so the user can sign in directly.
        1. Open the user, go to the **Groups** tab, and join `warehouse-ops`. To exercise the other persona later, swap the user's group to `customer-support` and reauthenticate from your MCP client. The IdP-issued `groups` claim drives Kong's ACLs, so changing the user's group is all that's needed.

        **Export Kong's Keycloak endpoints and credentials**

        Export the realm URL, the introspection endpoint, and the **{{site.base_gateway}}** client's ID and Secret. The MCP Client's Client ID is not exported here. It is used at flow time by the MCP client itself.

        ```bash
        export DECK_OAUTH_AUTH_SERVER='https://your-keycloak-host/realms/mcp-demo'
        export DECK_OAUTH_INTROSPECTION_URL='https://your-keycloak-host/realms/mcp-demo/protocol/openid-connect/token/introspect'
        export DECK_OAUTH_CLIENT_ID='kong-mcp-gateway'
        export DECK_OAUTH_CLIENT_SECRET='your-kong-gateway-client-secret'
        ```

        {:.info}

        > **Keycloak groups claim.** Ensure you configured the `groups` client scope and mapper above. Without it, the access token does not contain a `groups` claim and Consumer Group mapping fails.

        {% endtab %}
        {% endnavtabs %}
    - title: Insomnia 12+
      content: |
        This recipe verifies the gateway using [Insomnia](https://insomnia.rest/), Kong's MCP-aware API client. Insomnia speaks the MCP protocol natively and handles the full OAuth 2.1 + PKCE dance, including Protected Resource Metadata (PRM) discovery.

        1. Install **Insomnia** from [insomnia.rest/download](https://insomnia.rest/download).
        1. Verify the version is 12.0 or later (Help → About on macOS, equivalent on other platforms).

        See [MCP clients in Insomnia](/insomnia/mcp-clients-in-insomnia/) for an overview of MCP server testing in Insomnia.
overview: |
  Organizations adopting MCP (Model Context Protocol) often end up with multiple API teams each exposing tools through their own MCP servers, and no centralized control over who can discover and call them. Putting {{site.base_gateway}} in front of those servers collapses them into a single aggregated MCP endpoint with one place to enforce OAuth 2.1 auth and per-tool access control.

  Broadly, there are two types of MCP servers {{site.ai_gateway_name}} can proxy, distinguished by who owns the user identity. **Internal MCP servers** live inside your organization's trust boundary. Your IdP is the MCP auth server, and your security team controls the tokens. **External MCP servers** are third-party SaaS like GitHub, Slack, and Figma.com that run their own authorization servers; that case calls for a different pattern covered in [Secure External MCP Gateway](/cookbooks/secure-external-mcp-gateway/).

  This recipe covers the internal case. Kong produces an internal MCP server in one of two ways: the [AI MCP Proxy](/plugins/ai-mcp-proxy/) Plugin can generate one directly by converting managed REST APIs into MCP tools, with no separate MCP server to run, or it can proxy a standalone custom MCP server your team already operates in passthrough mode. Either shape sits behind the [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin, which enforces OAuth 2.1 at the edge and maps token claims to per-tool ACLs. The walkthrough below demonstrates the REST-conversion path against three mock ecommerce APIs with two Consumer Groups.

---

## The problem

**No centralized MCP access control.** Each internal MCP server manages its own authentication,
or worse, has none. When AI agents connect directly to these servers, there is no central policy
governing which agent can call which tools. A warehouse automation agent and a customer support
agent see the same tool catalog.

**Scattered credentials.** Each MCP server requires its own authentication setup. Developers
juggle multiple tokens, and there is no single revocation point. Removing a developer means
touching every MCP server they had access to.

**No federated tool governance.** API teams want to control which of their endpoints are exposed
as MCP tools and who can call them. But without a central aggregation layer, there is no
mechanism for a platform team to enforce organization-wide policies while letting individual
teams manage their own tool definitions.

**MCP auth is nascent.** The OAuth 2.0 specification for MCP is still evolving, and identity
provider support varies significantly. Some IdPs implement RFC 7662 token introspection, others
only expose a JWKS endpoint for local JWT validation, and most do not yet implement RFC 8707
(Resource Indicators), which means audience validation requires workarounds.

## The solution

This recipe uses {{site.base_gateway}} as a federated MCP aggregation layer with three capabilities:

- **REST-to-MCP conversion.** Each API team applies the AI MCP Proxy Plugin in `conversion-only`
mode to their existing Kong Routes. This converts selected REST endpoints into MCP tools, tagged
for discovery. Teams control their own tool definitions and ACL policies.

{:.info}
> **Tool design tip.** Automatic REST-to-MCP conversion works well when endpoints map cleanly to user actions. For multi-step workflows, hand-build a single workflow tool (`process-return(orderId, reason)`) inside a custom MCP server and put it behind Kong in passthrough mode. The same OAuth and ACL boundary applies either way.

- **Tool aggregation.** A central Route runs the AI MCP Proxy Plugin in `listener` mode, which
discovers all tagged tools and exposes them through a single MCP endpoint. MCP clients connect
to one URL and see a unified tool catalog.
- **OAuth 2.1 + ACLs.** The AI MCP OAuth2 Plugin handles the full MCP auth spec: Protected
Resource Metadata (PRM) discovery (RFC 9728), authorization code flow with PKCE, and token
validation via either introspection (RFC 7662) or JWKS-based JWT verification. In {{site.base_gateway}} 3.14+,
the Plugin maps token claims directly to Kong Consumers and Consumer Groups, enabling per-tool
ACLs without a separate authentication Plugin.

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

{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibility
    key: responsibility
rows:
  - component: "Identity Provider (Okta / Keycloak)"
    responsibility: "OAuth 2.1 authorization server, user identity, group membership, token issuance and introspection"
  - component: "Kong [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin"
    responsibility: "MCP-native OAuth: PRM discovery, token introspection, Consumer and Consumer Group mapping (3.14+)"
  - component: "Kong [AI MCP Proxy](/plugins/ai-mcp-proxy/) Plugin (`conversion-only`)"
    responsibility: "Converts REST API endpoints into MCP tools with per-tool ACL definitions"
  - component: "Kong [AI MCP Proxy](/plugins/ai-mcp-proxy/) Plugin (`listener`)"
    responsibility: "Aggregates tagged tools into a single MCP server, enforces ACLs at call time"
  - component: "Kong [CORS](/plugins/cors/) Plugin"
    responsibility: "Enables browser-based MCP clients to connect to the Gateway"
  - component: "Backend APIs (httpbin)"
    responsibility: "Mock ecommerce services representing independent API teams"
{% endtable %}

### ACL matrix

This recipe creates two Consumer Groups with different tool access:

{% table %}
columns:
  - title: Tool
    key: tool
  - title: warehouse-ops
    key: warehouse
  - title: customer-support
    key: support
rows:
  - tool: "`list-orders`"
    warehouse: "yes"
    support: "yes"
  - tool: "`get-order`"
    warehouse: "yes"
    support: "yes"
  - tool: "`cancel-order`"
    warehouse: "no"
    support: "yes"
  - tool: "`list-inventory`"
    warehouse: "yes"
    support: "yes"
  - tool: "`check-inventory`"
    warehouse: "yes"
    support: "yes"
  - tool: "`restock-item`"
    warehouse: "yes"
    support: "no"
  - tool: "`get-customer`"
    warehouse: "no"
    support: "yes"
  - tool: "`update-customer-contact`"
    warehouse: "no"
    support: "yes"
{% endtable %}

Warehouse operations staff can view orders and manage inventory (including restocking), but
cannot access customer data or cancel orders. Customer support agents can view orders, check
inventory, manage customer records, and cancel orders, but cannot restock inventory.

## How it works

A request flows through the system in these steps:

1. The client discovers the MCP server's OAuth requirements through the identity provider.
2. The client authenticates via PKCE flow and receives an access token.
3. The client connects to the MCP endpoint through Kong with the Bearer token.
4. Kong's AI MCP Proxy Plugin converts stream-enabled HTTP to SSE for the upstream.
5. Kong's AI MCP OAuth2 Plugin validates the token via introspection and maps the user to a Consumer Group.
6. ACL rules determine which MCP tools the Consumer Group can access.
7. The upstream MCP server processes permitted tool calls and returns results through Kong.

### AI MCP Proxy: REST-to-MCP conversion, tool aggregation, and ACL enforcement

The [AI MCP Proxy](/plugins/ai-mcp-proxy/) Plugin runs in two modes on this recipe. Per-team Routes use `conversion-only` mode to declare MCP tool definitions that map to existing REST endpoints, with no MCP endpoint served on those Routes. A single central Route runs the same Plugin in `listener` mode, discovers every `conversion-only` definition tagged with `ecom-mcp`, and exposes the union as one MCP server. The listener evaluates each tool's ACL against the caller's Consumer Group at call time, rejecting unauthorized invocations with `INVALID_PARAMS (-32602)` before the request leaves Kong. This split lets API teams own their own tool definitions and ACL policies while the platform team owns aggregation and the OAuth boundary.

{:.info}
> **Tool design tip.** Automatic REST-to-MCP conversion works well when endpoints map cleanly to user actions. For multi-step workflows, hand-build a single workflow tool (`process-return(orderId, reason)`) inside a custom MCP server and put it behind Kong in passthrough mode. The same OAuth and ACL boundary applies either way. Starting with decK v1.57, the `deck file openapi2mcp` command can generate `ai-mcp-proxy` tool definitions directly from an OpenAPI specification, removing the need to write tool configs by hand.

#### Configuration details

A `conversion-only` Plugin attached to a per-team Route declares the tools and ACLs:

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

- **name** and **description**: what the tool does (visible to MCP clients and LLM agents).
- **method** and **path**: the REST endpoint this tool maps to.
- **annotations**: MCP hints like `read_only_hint` and `destructive_hint` that help agents understand the tool's behavior.
- **acl**: which Consumer Groups can call this tool. Completely overrides `default_acl` when set.
- **parameters**: OpenAPI 3.0 parameter definitions.

The `tags` field on the Plugin entity (not the config) is what the listener uses for discovery. All `conversion-only` Plugins that should be aggregated share the same tag (`ecom-mcp`).

The central Route runs the Plugin in `listener` mode:

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

The listener does not define its own tools. It inherits tool definitions **and their ACL rules** from the tagged `conversion-only` Plugins. `include_consumer_groups: true` is required on the listener for group-based ACLs to work. Without it, the listener cannot pass Consumer Group membership to the ACL evaluation logic.

ACLs use a two-tier system. The `default_acl` block defines baseline rules applied to all tools that don't declare their own ACL. A per-tool `acl` block (`acl.allow` or `acl.deny`) completely overrides the default for that tool. There is no merging between the two tiers, and `deny` always takes precedence over `allow`. In this recipe, every tool defines its own `acl.allow` list, so `default_acl` is unused. See the AI MCP Proxy [reference docs](/plugins/ai-mcp-proxy/) for the full set of supported modes (including `passthrough-listener`) and ACL semantics.

### AI MCP OAuth2: OAuth 2.1 authentication and Consumer mapping

The [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin implements the full MCP authentication specification: Protected Resource Metadata (PRM) discovery (RFC 9728), authorization code flow with PKCE, and token validation. When an MCP client connects without a token, the Plugin returns `401` with a `WWW-Authenticate` header pointing to the PRM endpoint, which advertises the authorization server and supported scopes. When a client presents a Bearer token, the Plugin validates it (introspection or JWKS, see below), maps token claims to Kong Consumer Groups, and lets the request proceed to the AI MCP Proxy listener.

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
    consumer_optional: true
    consumer_groups_claim:
      - groups
    consumer_groups_optional: false
```
{:.no-copy-code}

Field-by-field:

- **`resource`**: the canonical MCP resource URL the Plugin advertises in PRM. MCP clients use this to confirm they are talking to the right resource.
- **`authorization_servers`**: the IdP issuer URL(s). MCP clients fetch OAuth metadata from this URL to discover the authorization and token endpoints.
- **`introspection_endpoint`**, **`client_id`**, **`client_secret`**: the RFC 7662 introspection endpoint and Kong's confidential-client credentials. Kong calls this endpoint on every request to validate Bearer tokens; responses are cached by default to reduce IdP load.
- **`metadata_endpoint`**: the path Kong serves the PRM document at. MCP clients fetch this when they receive a 401 with a `WWW-Authenticate` header.
- **`consumer_claim`** and **`consumer_by`**: which token claim to look up against which Consumer field. `sub` matched against `username` or `custom_id` is the standard pattern. The recipe pairs these with `consumer_optional: true` so a matching Kong Consumer is not required at request time. The IdP is the source of truth for identity.
- **`consumer_optional: true`**: lets the request proceed even when no pre-provisioned Kong Consumer matches the `sub` claim. Identity is captured for audit via the `credential_claim`, and Consumer Groups still drive ACLs.
- **`consumer_groups_claim`**: which token claim contains the user's group membership. Kong maps the values directly to Consumer Groups, enabling per-tool ACLs without a separate authorization Plugin.
- **`consumer_groups_optional: false`**: required for ACL enforcement. If the token has no `groups` claim or none of its values match a Kong Consumer Group, the request is rejected. Setting this to `true` would let an unmapped caller bypass ACLs entirely.
- **`credential_claim`**: which claim to use as a fallback credential identifier when no matching Consumer is found, so downstream Plugins can still identify the caller.

{:.warning}
> **`insecure_relaxed_audience_validation: true`.** Most identity providers do not yet implement RFC 8707 (Resource Indicators for OAuth 2.0), so the `aud` claim in access tokens does not match the MCP resource URL. This flag relaxes audience validation until your IdP supports RFC 8707. Without it, all requests are rejected with an audience mismatch error.

The Route that hosts this Plugin includes two paths: `/ecommerce-mcp` for the MCP endpoint itself and `/.well-known/oauth-protected-resource/ecommerce-mcp` for PRM discovery. The second path ensures MCP clients that ignore the `resource_metadata` URL in the `WWW-Authenticate` header and fall back to [standard PRM locations](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization#protected-resource-metadata-discovery-requirements) can still discover the metadata.

**Choosing a token validation method.** {{site.base_gateway}} 3.14 added JWKS-based JWT validation to the AI MCP OAuth2 Plugin alongside the existing RFC 7662 introspection support. With `introspection_endpoint`, Kong calls the IdP on every request (with caching) using `client_id` + `client_secret`. This is the right default for IdPs that expose an introspection endpoint (Okta, Keycloak, Ping Identity, FusionAuth, ORY Hydra). With `jwks_endpoint`, Kong validates signed JWTs locally against the IdP's public keys with no per-request call to the IdP. Use this when your IdP does not implement RFC 7662 introspection: Microsoft Entra ID, Auth0, AWS Cognito, and Google OAuth2 all expose JWKS endpoints and issue signed JWTs that work directly with this mode. When both are configured, introspection wins. Pick whichever matches your IdP's capabilities and your latency budget. Introspection gives instant revocation at the cost of a network hop; JWKS is faster but tokens stay valid until they expire. See the Plugin's [token validation methods](/plugins/ai-mcp-oauth2/#token-validation-methods) reference for the full schema.

{:.info}
> In production, store credentials in [Kong Vaults](/gateway/latest/kong-enterprise/secrets-management/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. Kong supports HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the Konnect Config Store.

## Apply the Kong configuration

This section configures the Control Plane in two parts. First, adopt the quickstart Control Plane into a kongctl namespace so the apply command below can manage it. The recipe's `select_tags` and the `secure-internal-mcp-gateway-recipe` namespace scope every resource so teardown removes only this recipe's configuration.

```bash
kongctl adopt control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the Control Plane.

The configuration below creates four Kong Services (three ecommerce APIs plus one aggregated MCP server), eight MCP tools with per-tool ACLs, two Consumer Groups, OAuth 2.1 authentication via the AI MCP OAuth2 Plugin, and CORS support. The IdP-specific `DECK_OAUTH_*` env vars and the shared `DECK_MCP_RESOURCE_URL` are already exported during the Identity Provider prerequisite, so they do not repeat here. The configuration is identical regardless of which IdP you selected; the AI MCP OAuth2 Plugin resolves the IdP endpoints from those variables at apply time.

Apply the Kong configuration:

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
      instance_name: orders-mcp-conversion
      tags:
      - secure-internal-mcp-gateway-recipe
      - ecom-mcp
      config:
        mode: conversion-only
        consumer_identifier: username
        include_consumer_groups: true
        max_request_body_size: 1048576
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
      instance_name: inventory-mcp-conversion
      tags:
      - secure-internal-mcp-gateway-recipe
      - ecom-mcp
      config:
        mode: conversion-only
        consumer_identifier: username
        include_consumer_groups: true
        max_request_body_size: 1048576
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
      instance_name: customers-mcp-conversion
      tags:
      - secure-internal-mcp-gateway-recipe
      - ecom-mcp
      config:
        mode: conversion-only
        consumer_identifier: username
        include_consumer_groups: true
        max_request_body_size: 1048576
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
      instance_name: ecommerce-mcp-oauth2
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
        consumer_optional: true
        consumer_groups_claim:
        - groups
        consumer_groups_optional: false
        credential_claim:
        - sub
    - name: ai-mcp-proxy
      instance_name: ecommerce-mcp-listener
      tags:
      - secure-internal-mcp-gateway-recipe
      config:
        mode: listener
        consumer_identifier: username
        include_consumer_groups: true
        max_request_body_size: 1048576
        server:
          tag: ecom-mcp
          timeout: 10000
          forward_client_headers: true
        logging:
          log_payloads: true
          log_statistics: true
    - name: cors
      instance_name: ecommerce-mcp-cors
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
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

## Try it out

With the configuration applied and your IdP configured, the aggregated MCP endpoint is ready to accept authenticated connections. The verification path below uses [Insomnia](/insomnia/mcp-clients-in-insomnia/), Kong's MCP-aware API client, to exercise the full OAuth + ACL flow. Once verified, the same endpoint can be plugged into any MCP-compatible AI client.

### Verify with Insomnia

Insomnia speaks the MCP protocol natively. It auto-discovers Protected Resource Metadata (PRM) from a 401 response, runs the OAuth 2.1 + PKCE dance against the IdP, and exposes every step of the auth handshake in its **Events** panel with full request/response inspection.

To verify the Gateway:

1. **Create an MCP request.** In Insomnia, create a new request and select **MCP** as the request type. Enter the Gateway URL:

    ```text
    http://localhost:8000/ecommerce-mcp
    ```
    {:.no-copy-code}

1. **Configure OAuth on the request.** Open the **Auth** tab and select **OAuth 2.0** from the dropdown. Set **Grant Type** to **MCP Auth flow**. Enter the **Client ID** copied from the `MCP Client` SPA application in your IdP (Okta) or the `mcp-client` public client (Keycloak). Set **State** to any value (for example, `recipe-test`). Insomnia uses these values when it runs the PKCE flow in the next step.

1. **Initiate the connection.** Insomnia sends an MCP `initialize` request without credentials. Kong's [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin returns `401` with a `WWW-Authenticate: Bearer resource_metadata=...` header pointing at `/.well-known/oauth-protected-resource/ecommerce-mcp`. The **Events** tab shows the unauthenticated initialize, the 401, and Insomnia's follow-up GET against the PRM URL. The raw 401 response looks like this:

    ```text
    HTTP/1.1 401 Unauthorized
    WWW-Authenticate: Bearer resource_metadata="http://localhost:8000/.well-known/oauth-protected-resource/ecommerce-mcp"
    Content-Type: application/json

    {"error":"unauthorized","error_description":"Missing access token"}
    ```
    {:.no-copy-code}

    The `WWW-Authenticate` header is what makes the endpoint MCP-spec compliant. MCP clients read the `resource_metadata` URL, fetch the PRM document, and discover the authorization server.

1. **Complete OAuth.** Insomnia opens your browser to the IdP's authorization endpoint with a generated PKCE code challenge. Sign in as your test user (currently in `warehouse-ops`), approve the application, and Insomnia captures the redirect, exchanges the authorization code for an access token, and reconnects to the MCP endpoint with `Authorization: Bearer <token>`. The OAuth handshake appears as a sequence of `MCP Auth` entries in the **Events** tab.

1. **List tools.** With the connection authenticated, Insomnia populates its tool browser. With your user in `warehouse-ops`, you see five tools: `list-orders`, `get-order`, `list-inventory`, `check-inventory`, `restock-item`. The authenticated `tools/list` response body looks like this:

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

    The three customer-only tools (`cancel-order`, `get-customer`, `update-customer-contact`) are filtered out by Kong before the response leaves the Gateway. Kong evaluated the `consumer_groups_claim` against each tool's ACL before returning the catalog. To see the other persona, move your test user from `warehouse-ops` to `customer-support` in the IdP and rerun the OAuth flow. The catalog flips to seven tools, with `restock-item` filtered out instead.

1. **Call a permitted tool.** Select `check-inventory`, set `sku` to `WIDGET-42`, and call it. The call succeeds; the response body shows the proxied call to the inventory backend (httpbin echoes the request details in this recipe). Inspect the response headers. Kong attaches `X-Kong-Upstream-Latency` (time in ms spent waiting for the upstream MCP server) and `X-Kong-Proxy-Latency` (time in ms Kong spent on auth, ACL, and routing) on every authenticated call.

1. **Call a restricted tool.** Manually invoke `cancel-order` (the tool name can be entered directly even though it's hidden from the catalog. This simulates a misbehaving client). Kong returns an MCP error with code `INVALID_PARAMS (-32602)` and a body explaining the tool is not available for your Consumer Group. The token was valid; Kong's ACL evaluated it and denied the call before the request reached any upstream.

1. **(Optional) Verify the auth boundary.** Replace the captured access token with `not-a-real-token` and resend the initialize. Kong's introspection call rejects the token and the AI MCP OAuth2 Plugin returns the same `401 + WWW-Authenticate` response as the unauthenticated case. This confirms invalid credentials never bypass auth.

### Explore in Konnect

Open [Konnect](https://cloud.konghq.com/) and navigate to **API Gateway** → **Gateways** → **`secure-internal-mcp-gateway-recipe`**. The recipe created the following resources on this Control Plane:

- **Gateway services**: the four Services the recipe registered (`orders-api`, `inventory-api`, `customers-api`, `aggregated-mcp-server`). Open the `aggregated-mcp-server` Service. Its detail page has tabs for Configuration, Routes, Plugins, and Analytics.
  - **Routes** tab: the four Routes, including `ecommerce-mcp` with both the MCP path and the PRM well-known path.
  - **Plugins** tab: every Plugin instance: three AI MCP Proxy (`conversion-only`), one AI MCP Proxy (`listener`), one AI MCP OAuth2, and one CORS.
- **Consumer Groups**: `warehouse-ops` and `customer-support`. No Consumers are pre-provisioned. The AI MCP OAuth2 Plugin runs with `consumer_optional: true`, so Kong identifies the caller by the IdP-issued `sub` claim and resolves group membership from the `groups` claim against these Consumer Groups at request time.

The **Analytics** tab on the `aggregated-mcp-server` Service gives an at-a-glance view of recipe traffic, including request counts, error rates, and latency for both successful tool calls and ACL denials. For a deeper dive into these analytics, plus platform-wide analytics across every Control Plane, head to the **Observability** L1 menu in Konnect.

## Variations and next steps

- **Connect from an AI harness.** The same Gateway URL works in any MCP-compatible client (Claude Code, VS Code, Claude Desktop, and others). Each client handles OAuth differently, so follow the client's documentation for adding a remote MCP server. Before connecting, register that client's OAuth redirect URI on your IdP `MCP Client` application alongside Insomnia's `https://app.insomnia.rest/oauth/redirect`. Token validation, ACL evaluation, and the `groups` claim mapping are unchanged.
- **Add rate limiting per Consumer Group.** Attach the [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) Plugin to enforce per-tier token budgets, giving premium Consumer Groups higher quotas while protecting shared infrastructure.
- **Expand to multiple MCP servers.** Add additional Services and Routes for other internal MCP servers (databases, monitoring, CI/CD). Each gets its own ACL configuration while sharing the same OAuth authentication flow.
- **Add response logging for audit trails.** Enable payload logging on the AI MCP Proxy Plugin to capture tool calls and responses for compliance auditing.
- **Integrate with external identity providers.** Replace the Okta configuration with Azure AD, Auth0, or Keycloak by updating the OAuth endpoints in the deck config.

## Cleanup

The recipe's `select_tags` and kongctl namespace scoped all resources, so this teardown removes
only this recipe's configuration. Tear down the local Data Plane and delete the Control Plane
from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='secure-internal-mcp-gateway-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```
