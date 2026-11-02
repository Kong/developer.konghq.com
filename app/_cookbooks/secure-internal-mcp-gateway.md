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
  ai-gateway: '2.0'
categories:
  - mcp
  - access-control
featured: false
popular: false

# Machine-readable fields for AI agent setup

plugins:
  - ai-mcp-server
  - openid-connect
  - cors
requires_embeddings: false
extra_services:
  - name: Identity Provider (Okta or Keycloak)
    env_vars: [OAUTH_AUTH_SERVER, OAUTH_INTROSPECTION_URL, OAUTH_CLIENT_ID, OAUTH_CLIENT_SECRET]
    hint: "Create an OAuth application for Kong (API Services / Client Credentials) and one for MCP clients (SPA / Authorization Code + PKCE). See the Identity Provider section in Prerequisites."

hint: "Requires an OAuth 2.1 identity provider (Okta or Keycloak in this recipe) and Insomnia 12+ for testing."
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
           export KONNECT_CONTROL_PLANE_NAME='secure-internal-mcp-gateway-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           The script provisions an {{site.ai_gateway}} named `secure-internal-mcp-gateway-recipe`, a local data plane connected to it, and prints `export` lines (including `AI_GATEWAY_ID`) for the rest of the session vars. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: Identity Provider
      content: |
        You need an OAuth 2.1 identity provider. This recipe shows setup steps for Okta and Keycloak, both of which expose an RFC 7662 token introspection endpoint that Kong calls to validate tokens. Other IdPs (Microsoft Entra ID, Auth0, AWS Cognito, Google) work too. See the [AI Auth Strategy: OIDC token authentication](/ai-gateway/entities/ai-auth-strategy/#oidc-token-authentication) reference for the JWKS-based path. Select your IdP below and follow the setup steps.

        Set the MCP resource URL once. Both IdP tabs use the same value:

        ```bash
        export MCP_RESOURCE_URL='http://localhost:8000/ecommerce-mcp'
        ```

        {% navtabs "Identity Provider" %}
        {% tab Okta %}

        You need an Okta organization with admin access. The steps below create two Okta applications, configure a `groups` claim, create two groups, set up a test user (new or existing), and export Kong's introspection credentials.

        **Create the {{site.base_gateway}} application**

        This confidential client represents Kong as the resource server. Kong uses its credentials to call Okta's token introspection endpoint.

        1. In the Okta Admin Console, go to **Applications → Create App Integration**.
        1. Select **API Services** (machine-to-machine).
        1. Name it `Kong MCP Gateway`.
        1. From the **General** tab, copy the **Client ID** and **Client Secret** under **Client Credentials**. Export these as `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET` in the final step.

        **Create the MCP Client application**

        This public client represents the MCP client (Insomnia, Claude Code, VS Code, or any MCP-compatible tool). Public clients use Authorization Code + PKCE without a client secret.

        1. In the Okta Admin Console, go to **Applications → Create App Integration**.
        1. Select **OIDC - OpenID Connect** and **Single-Page Application**, then click **Next**.
        1. Name it `MCP Client`.
        1. Set the sign-in redirect URI to `https://app.insomnia.rest/oauth/redirect`. This URL is Insomnia 12+'s built-in OAuth callback. To use a different MCP client later, register that client's redirect URI here too, as described in [Variations and next steps](#variations-and-next-steps).
        1. On the application's **General** tab under **Client Credentials**, confirm that **Proof Key for Code Exchange (PKCE)** is checked. Okta enables it by default for SPA app types.
        1. Copy the **Client ID** for use in your MCP client. Insomnia and other MCP clients prompt for this value when they start the OAuth flow; the recipe doesn't export it as an environment variable.

        {:.warning}

        > Use the SPA application type, not Web. Okta SPA integrations are public clients with no client secret and use Authorization Code + PKCE by default. MCP clients perform the PKCE flow without sending a client secret, so Okta's token endpoint rejects the token exchange against a Web (confidential) integration even if PKCE is enabled on it.

        **Configure the groups claim**

        Kong's AI Auth Strategy uses the `groups` claim in access tokens to map users to AI Consumer Groups. Configure your Okta authorization server to include this claim:

        1. Go to **Security → API → Authorization Servers** and select your authorization server (for example, `default`).
        1. Click the **Claims** tab and add a new claim:
          - **Name:** `groups`
          - **Include in token type:** Access Token
          - **Value type:** Groups
          - **Filter:** Matches regex `.*` (or restrict to specific groups)
        1. Click the **Scopes** tab and ensure `openid` is present.

        **Set up Okta groups and a test user**

        Create two groups in Okta that match the Kong AI Consumer Group names, plus one user assigned to one of them:

        1. Go to **Directory → Groups** and create:
          - `warehouse-ops`
          - `customer-support`
        1. Go to **Directory → People** and either add a new person (for example, `mcp-test-user@example.com`) or pick an existing user. Make sure the user has a password set and can sign in.
        1. Open the user, click the **Groups** tab, and assign them to `warehouse-ops`. To exercise the other persona later, move the same user to `customer-support` and reauthenticate from your MCP client. The IdP-issued `groups` claim drives Kong's ACLs, so changing the user's group is all that's needed.
        1. Open the `MCP Client` application, click the **Assignments** tab, and assign the same user. Without this assignment, Okta blocks the OAuth flow at sign-in.

        **Export Kong's Okta endpoints and credentials**

        Export the authorization server URL, the introspection endpoint, and the **{{site.base_gateway}}** application's Client ID and Secret. You don't export the MCP Client (SPA) Client ID here. The MCP client itself uses it at flow time.

        ```bash
        export OAUTH_AUTH_SERVER='https://your-org.okta.com/oauth2/default'
        export OAUTH_INTROSPECTION_URL='https://your-org.okta.com/oauth2/default/v1/introspect'
        export OAUTH_CLIENT_ID='your-kong-gateway-client-id'
        export OAUTH_CLIENT_SECRET='your-kong-gateway-client-secret'
        ```

        {% endtab %}
        {% tab Keycloak %}

        You need a Keycloak instance with admin access. The steps below create a realm and two clients, configure a `groups` claim, create two groups, set up a test user (new or existing), and export Kong's introspection credentials.

        **Create a realm**

        In the Keycloak Admin Console, create a new realm (for example, `mcp-demo`), or use an existing one.

        **Create the {{site.base_gateway}} client**

        This confidential client represents Kong as the resource server. Kong uses its credentials to call Keycloak's token introspection endpoint.

        1. Go to **Clients → Create client**.
        1. Set **Client ID** to `kong-mcp-gateway`.
        1. Set **Client authentication** to **On** (confidential client).
        1. Enable **Service accounts roles**.
        1. From the **Credentials** tab, copy the **Client Secret**. Export the Client ID (`kong-mcp-gateway`) as `OAUTH_CLIENT_ID` and this secret as `OAUTH_CLIENT_SECRET` in the final step.

        **Create the MCP Client**

        This public client represents the MCP client (Insomnia, Claude Code, VS Code, or any MCP-compatible tool). Public clients use Authorization Code + PKCE without a client secret.

        1. Go to **Clients → Create client**.
        1. Set **Client ID** to `mcp-client`.
        1. Set **Client authentication** to **Off** (public client).
        1. Set **Valid redirect URIs** to `https://app.insomnia.rest/oauth/redirect`. This URL is Insomnia 12+'s built-in OAuth callback. To use a different MCP client later, add that client's redirect URI here too, as described in [Variations and next steps](#variations-and-next-steps).
        1. Enable **Standard flow** (Authorization Code) and confirm PKCE is required for public clients (Keycloak enforces PKCE for public clients automatically).
        1. Note the **Client ID** (`mcp-client`) for use in your MCP client. Insomnia and other MCP clients prompt for this value when they start the OAuth flow; the recipe doesn't export it as an environment variable.

        **Configure the groups claim**

        By default, Keycloak doesn't include a `groups` claim in access tokens. Add a client scope and mapper:

        1. Go to **Client scopes → Create client scope**.
        1. Name it `groups` and set its type to **Default**.
        1. In the scope, go to **Mappers → Create mapper**:
          - **Mapper type:** Group Membership
          - **Name:** `groups`
          - **Token Claim Name:** `groups`
          - **Full group path:** Off
          - **Add to access token:** On
        1. Go to **Clients → kong-mcp-gateway → Client scopes** and add the `groups` scope.
        1. Repeat for the `mcp-client` client.

        **Set up groups and a test user**

        Create two groups that match the Kong AI Consumer Group names, plus one user assigned to one of them:

        1. Go to **Groups** and create:
          - `warehouse-ops`
          - `customer-support`
        1. Go to **Users** and either add a new user (for example, `mcp-test-user`) or pick an existing one. On the **Credentials** tab, set a password and clear **Temporary** so the user can sign in directly.
        1. Open the user, click the **Groups** tab, and add the user to `warehouse-ops`. To exercise the other persona later, swap the user's group to `customer-support` and reauthenticate from your MCP client. The IdP-issued `groups` claim drives Kong's ACLs, so changing the user's group is all that's needed.

        **Export Kong's Keycloak endpoints and credentials**

        Export the realm URL, the introspection endpoint, and the **{{site.base_gateway}}** client's ID and Secret. You don't export the MCP Client's Client ID here. The MCP client itself uses it at flow time.

        ```bash
        export OAUTH_AUTH_SERVER='https://your-keycloak-host/realms/mcp-demo'
        export OAUTH_INTROSPECTION_URL='https://your-keycloak-host/realms/mcp-demo/protocol/openid-connect/token/introspect'
        export OAUTH_CLIENT_ID='kong-mcp-gateway'
        export OAUTH_CLIENT_SECRET='your-kong-gateway-client-secret'
        ```

        {:.info}

        > **Keycloak groups claim.** Ensure you configured the `groups` client scope and mapper above. Without them, the access token doesn't contain a `groups` claim and AI Consumer Group mapping fails.

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

  Broadly, there are two types of MCP servers {{site.ai_gateway_name}} can proxy, distinguished by who owns the user identity. **Internal MCP servers** live inside your organization's trust boundary. Your IdP is the MCP auth server, and your security team controls the tokens. **External MCP servers** are third-party SaaS like GitHub, Slack, and Figma that run their own authorization servers; the [Secure External MCP Gateway](/cookbooks/secure-external-mcp-gateway/) recipe covers that case with a different pattern.

  This recipe covers the internal case. An [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity converts managed REST APIs into MCP tools directly, with no separate MCP server to run, or proxies a standalone custom MCP server your team already operates. Either shape authenticates through an [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/), which enforces OAuth 2.1 at the edge and maps token claims to per-tool ACLs. The walkthrough below demonstrates the REST-conversion path against three mock ecommerce APIs with two AI Consumer Groups.
---

## The problem

**No centralized MCP access control.** Each internal MCP server manages its own authentication,
or worse, has none. When AI agents connect directly to these servers, there is no central policy
governing which agent can call which tools. A warehouse automation agent and a customer support
agent see the same tool catalog.

**Scattered credentials.** Each MCP server requires its own authentication setup. Developers
juggle multiple tokens, and there is no single revocation point. Offboarding a developer means
touching every MCP server they had access to.

**No federated tool governance.** API teams want to control which of their endpoints become
MCP tools and who can call them. But without a central aggregation layer, there is no
mechanism for a platform team to enforce organization-wide policies while letting individual
teams manage their own tool definitions.

**MCP auth is nascent.** The OAuth 2.0 specification for MCP is still evolving, and identity
provider support varies significantly. Some IdPs implement RFC 7662 token introspection, others
only expose a JWKS endpoint for local JWT validation, and most don't yet implement RFC 8707
(Resource Indicators), which means audience validation requires workarounds.

## The solution

This recipe uses {{site.base_gateway}} as a federated MCP aggregation layer with three capabilities:

- **REST-to-MCP conversion.** Each API team defines an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/)
entity in `conversion-only` mode. This mode converts selected REST endpoints into MCP tools with
per-tool ACLs, but the entity accepts no incoming MCP traffic of its own. Teams control their own
tool definitions and ACL Policies.

{:.info}
> **Tool design tip.** Automatic REST-to-MCP conversion works well when endpoints map cleanly to user actions. For multi-step workflows, hand-build a single workflow tool (`process-return(orderId, reason)`) inside a custom MCP server and put it behind Kong in `passthrough-listener` mode. The same OAuth and ACL boundary applies either way.

- **Tool aggregation.** A single AI MCP Server in `listener` mode lists the per-team servers by
name in its `sources` field, aggregating every tool they define behind one MCP endpoint. MCP
clients connect to one URL and see a unified tool catalog.
- **OAuth 2.1 + ACLs.** An [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) of type
`openid-connect` validates Bearer tokens (introspection or JWKS, see [AI Auth Strategy: OAuth 2.1 authentication and AI Consumer mapping](#ai-auth-strategy-oauth-21-authentication-and-ai-consumer-mapping)) and maps token claims
to AI Consumers and AI Consumer Groups. Setting `access.metadata` on the listener alongside that
strategy makes {{site.ai_gateway_name}} generate the OAuth 2.1 resource-server behavior MCP
clients expect: Protected Resource Metadata (PRM) discovery (RFC 9728) and token audience checks.
The strategy maps token claims directly to AI Consumer Groups, enabling per-tool ACLs without a separate
authentication policy.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP Client
    participant K as Kong AI Gateway
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
    K-->>C: Initialize OK (mapped to AI Consumer + Groups)
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
backed by httpbin, two AI Consumer Groups (`warehouse-ops` and `customer-support`), and OAuth
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
  - component: "Kong [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) (`openid-connect`)"
    responsibility: "Validates Bearer tokens and maps claims to an AI Consumer and AI Consumer Groups; combined with `access.metadata`, adds MCP-native OAuth (PRM discovery, token audience checks)"
  - component: "Kong [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) (`conversion-only`)"
    responsibility: "Converts REST API endpoints into MCP tools with per-tool ACL definitions"
  - component: "Kong [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) (`listener`)"
    responsibility: "Aggregates tools from the per-team servers by name via `sources`, enforces ACLs at call time"
  - component: "Kong AI Policy (`cors`)"
    responsibility: "Enables browser-based MCP clients to connect to the gateway"
  - component: "Backend APIs (httpbin)"
    responsibility: "Mock ecommerce services representing independent API teams"
{% endtable %}

### ACL matrix

This recipe creates two AI Consumer Groups with different tool access:

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
can't access customer data or cancel orders. Customer support agents can view orders, check
inventory, manage customer records, and cancel orders, but can't restock inventory.

## How it works

A request flows through the system in these steps:

1. The client discovers the MCP server's OAuth requirements through the identity provider.
2. The client authenticates via PKCE flow and receives an access token.
3. The client connects to the aggregated MCP endpoint through Kong with the Bearer token.
4. The AI Auth Strategy validates the token via introspection and maps the caller to an AI Consumer Group.
5. ACL rules on each tool determine which AI Consumer Group can access it.
6. Kong's `listener` AI MCP Server converts the permitted tool call into a standard HTTP request against the mapped backend.
7. The backend API processes the request, and Kong wraps the response back into MCP format for the client.

### AI MCP Server: REST-to-MCP conversion, tool aggregation, and ACL enforcement

The [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity runs in two modes in this recipe. Per-team entities use `conversion-only` mode to declare MCP tool definitions that map to existing REST endpoints; a `conversion-only` entity accepts no incoming MCP traffic of its own, so it has no `access` block and no route. A single aggregating entity runs the same entity type in `listener` mode, lists every per-team entity by its immutable `name` in `sources`, and exposes the union as one MCP server on its own route. The listener evaluates each tool's ACL against the caller's AI Consumer Group at call time, rejecting unauthorized invocations with `HTTP 403 Forbidden` before the request leaves Kong. This split lets API teams own their own tool definitions and ACL Policies while the platform team owns aggregation and the OAuth boundary.

{:.info}
> **Tool design tip.** Automatic REST-to-MCP conversion works well when endpoints map cleanly to user actions. For multi-step workflows, hand-build a single workflow tool (`process-return(orderId, reason)`) inside a custom MCP server and put it behind Kong in `passthrough-listener` mode. The same OAuth and ACL boundary applies either way.

#### Configuration details

A `conversion-only` AI MCP Server declares the tools and their ACLs, with `config.url` as the base for every tool's `path`:

```yaml
ai_gateway_mcp_servers:
- ref: orders-mcp
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: orders-mcp
  display_name: Orders API MCP tools
  type: conversion-only
  config:
    url: https://httpbin.konghq.com/anything
    max_request_body_size: 1048576
    logging:
      payloads: true
  tools:
  - name: check-inventory
    description: Check stock level for a specific SKU
    method: GET
    path: /inventory/{sku}
    annotations:
      read_only_hint: true
    access:
      acls:
        allow:
        - warehouse-ops
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
- **method** and **path**: the HTTP method and path, appended onto `config.url`, that this tool maps to.
- **annotations**: MCP hints like `read_only_hint` and `destructive_hint` that help agents understand the tool's behavior.
- **access.acls**: which AI Consumer Groups can call this tool (`allow`, `deny`, or both). When set, this fully overrides any server-level default for that tool.
- **parameters**: OpenAPI 3.0 parameter definitions.

The `sources` field on the listener performs the aggregation by referencing each `conversion-only` entity's immutable `name` directly:

```yaml
- ref: ecommerce-mcp
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: ecommerce-mcp
  display_name: Aggregated Ecommerce MCP Server
  type: listener
  sources:
  - orders-mcp
  - inventory-mcp
  - customers-mcp
  config:
    route:
      paths:
      - /ecommerce-mcp
      protocols:
      - http
      - https
```
{:.no-copy-code}

The listener has no tool definitions of its own. It inherits every tool **and its ACL** from the entities named in `sources`. Because every tool in this recipe already declares its own `access.acls`, the recipe leaves the listener's own `access.default_tool_acls` (a baseline applied to any tool that doesn't set its own) unset. See the AI MCP Server [ACL tool control](/ai-gateway/entities/ai-mcp-server/#acl-tool-control) reference for the full evaluation order and the `oauth_access_token` alternative to consumer-based ACLs.

### AI Auth Strategy: OAuth 2.1 authentication and AI Consumer mapping

An [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) of type `openid-connect`, referenced in the listener's `access.auth_strategies`, authenticates every request to the aggregated MCP endpoint. Setting `access.metadata` alongside it tells {{site.ai_gateway_name}} to generate the MCP-native OAuth behavior these clients expect: Protected Resource Metadata (PRM) discovery (RFC 9728), token audience validation, and the `WWW-Authenticate` challenge on unauthenticated requests. You don't create or attach that generated configuration yourself; {{site.ai_gateway_name}} derives it from the AI Auth Strategy and `access.metadata` together.

#### Configuration details

```yaml
ai_gateway_auth_strategies:
- ref: secure-internal-mcp-gateway-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: secure-internal-mcp-gateway-auth
  display_name: secure-internal-mcp-gateway OIDC auth
  type: openid-connect
  config:
    issuer: !env 'OAUTH_AUTH_SERVER'
    introspection_endpoint: !env 'OAUTH_INTROSPECTION_URL'
    client_id:
    - !env 'OAUTH_CLIENT_ID'
    client_secret:
    - !secret {source: !env 'OAUTH_CLIENT_SECRET'}
    auth_methods:
    - introspection
    cache_introspection: true
    scopes:
    - openid
    consumer_claims:
    - - sub
    consumer_by:
    - username
    - custom_id
    consumer_optional: true
    consumer_groups_claim:
    - groups
    consumer_groups_optional: false
    credential_claim:
    - sub
    cache_tokens_salt: secure-internal-mcp-gateway-oidc-cache
    ssl_verify: true
    hide_credentials: true
```
{:.no-copy-code}

Field-by-field:

- **`issuer`**: the IdP's discovery URL. Kong fetches OIDC metadata and signing keys from here.
- **`introspection_endpoint`**, **`client_id`**, **`client_secret`**: the RFC 7662 introspection endpoint and Kong's confidential-client credentials, both arrays so you can configure multiple client ID/secret pairs side by side. Kong calls this endpoint on every request to validate Bearer tokens; `cache_introspection: true` caches responses to reduce IdP load.
- **`auth_methods: [introspection]`**: the validation method, which tells Kong to treat incoming Bearer tokens as opaque and validate them against `introspection_endpoint` on every request, rather than verifying a signed JWT locally. See "Choosing a token validation method" below for the JWKS alternative.
- **`consumer_claims`** and **`consumer_by`**: which token claim to look up against which AI Consumer field. `sub` matched against `username` or `custom_id` is the standard pattern. The recipe pairs these with `consumer_optional: true` so the request doesn't require a matching AI Consumer. The IdP is the source of truth for identity.
- **`consumer_optional: true`**: the setting that lets the request proceed even when no pre-provisioned AI Consumer matches the `sub` claim. Kong captures identity for audit through `credential_claim`, and AI Consumer Groups still drive ACLs.
- **`consumer_groups_claim`**: which token claim contains the user's group membership. Kong maps the values directly to AI Consumer Groups, enabling per-tool ACLs without a separate authorization policy.
- **`consumer_groups_optional: false`**: the setting ACL enforcement requires. If the token has no `groups` claim or none of its values match an AI Consumer Group, Kong rejects the request. Setting this to `true` would let an unmapped caller bypass ACLs entirely.
- **`credential_claim`**: which claim to use as a fallback credential identifier when Kong finds no matching AI Consumer, so audit logs can still identify the caller.
- **`cache_tokens_salt`**: a required, non-secret value used to key the introspection response cache for this strategy.

Setting `access.metadata` on the listener, alongside this strategy, advertises the resource and serves the PRM document:

```yaml
  access:
    acl_attribute_type: consumer
    auth_strategies:
    - secure-internal-mcp-gateway-auth
    metadata:
      resource: !env 'MCP_RESOURCE_URL'
      endpoint: /.well-known/oauth-protected-resource/ecommerce-mcp
```
{:.no-copy-code}

- **`resource`**: the canonical MCP resource URL {{site.ai_gateway_name}} advertises in PRM. MCP clients use this URL to confirm they're talking to the right resource.
- **`endpoint`**: the path {{site.ai_gateway_name}} serves the PRM document at. Kong adds this path to the listener's route automatically; you don't add it to `config.route.paths` yourself. The recipe leaves `authorization_servers` and `scopes_supported` unset; both fall back to the AI Auth Strategy's `issuer` and `scopes` above, so there's nothing to repeat.

Most identity providers don't yet implement RFC 8707 (Resource Indicators for OAuth 2.0), so the `aud` claim in access tokens won't match the MCP resource URL. The AI Auth Strategy's `audience_required` field lists the audiences {{site.ai_gateway_name}} should enforce, and this recipe leaves it unset entirely, which disables that check until your IdP supports RFC 8707. Set `audience_required: [http://localhost:8000/ecommerce-mcp]` (matching `MCP_RESOURCE_URL`) once it does.

**Choosing a token validation method.** With `introspection_endpoint` set, Kong calls the IdP on every request (with caching) using `client_id` + `client_secret`. Introspection is the right default for IdPs that expose an introspection endpoint (Okta, Keycloak, Ping Identity, FusionAuth, ORY Hydra). With `jwks_endpoint` instead, Kong validates signed JWTs locally against the IdP's public keys with no per-request call to the IdP. Use JWKS when your IdP doesn't implement RFC 7662 introspection: Microsoft Entra ID, Auth0, AWS Cognito, and Google OAuth2 all expose JWKS endpoints and issue signed JWTs that work directly with this mode. Pick whichever matches your IdP's capabilities and your latency budget. Introspection gives instant revocation at the cost of a network hop; JWKS is faster but tokens stay valid until they expire. See the [AI Auth Strategy schema](/ai-gateway/entities/ai-auth-strategy/#schema) for the full field list.

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. AI Vaults support HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store.

## Apply the Kong configuration

This section configures the {{site.ai_gateway}} in two parts. First, adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply command can manage it. The recipe's `secure-internal-mcp-gateway-recipe` namespace scopes every resource so teardown removes only this recipe's configuration.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the {{site.ai_gateway}}.

The following configuration creates three per-team AI MCP Servers (`conversion-only`) exposing eight MCP tools with per-tool ACLs, one aggregating AI MCP Server (`listener`), two AI Consumer Groups, an `openid-connect` AI Auth Strategy, and a CORS Policy. You already exported the IdP-specific `OAUTH_*` env vars and the shared `MCP_RESOURCE_URL` in the Identity Provider prerequisite, so you don't need to export them again. This same configuration applies regardless of which IdP you selected; the AI Auth Strategy resolves the IdP endpoints from those variables at apply time.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: secure-internal-mcp-gateway-recipe

ai_gateway_auth_strategies:
- ref: secure-internal-mcp-gateway-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: secure-internal-mcp-gateway-auth
  display_name: secure-internal-mcp-gateway OIDC auth
  type: openid-connect
  config:
    issuer: !env 'OAUTH_AUTH_SERVER'
    introspection_endpoint: !env 'OAUTH_INTROSPECTION_URL'
    client_id:
    - !env 'OAUTH_CLIENT_ID'
    client_secret:
    - !secret {source: !env 'OAUTH_CLIENT_SECRET'}
    auth_methods:
    - introspection
    cache_introspection: true
    scopes:
    - openid
    consumer_claims:
    - - sub
    consumer_by:
    - username
    - custom_id
    consumer_optional: true
    consumer_groups_claim:
    - groups
    consumer_groups_optional: false
    credential_claim:
    - sub
    cache_tokens_salt: secure-internal-mcp-gateway-oidc-cache
    ssl_verify: true
    hide_credentials: true

ai_gateway_consumer_groups:
- ref: warehouse-ops
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: warehouse-ops
  display_name: Warehouse Operations
- ref: customer-support
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: customer-support
  display_name: Customer Support

ai_gateway_mcp_servers:
- ref: orders-mcp
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: orders-mcp
  display_name: Orders API MCP tools
  type: conversion-only
  config:
    url: https://httpbin.konghq.com/anything
    max_request_body_size: 1048576
    logging:
      payloads: true
  tools:
  - name: list-orders
    description: >-
      List recent orders with optional filters for status and date.
      Returns order summaries including order ID, status, and total.
    method: GET
    path: /orders
    annotations:
      read_only_hint: true
      title: List orders
    access:
      acls:
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
    description: >-
      Get full details for a specific order including line items,
      shipping address, and payment status.
    method: GET
    path: /orders/{orderId}
    annotations:
      read_only_hint: true
      title: Get order details
    access:
      acls:
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
    description: >-
      Cancel a pending order. This action cannot be undone.
      Only customer support agents can perform cancellations.
    method: POST
    path: /orders/{orderId}/cancel
    annotations:
      destructive_hint: true
      title: Cancel order
    access:
      acls:
        allow:
        - customer-support
    parameters:
    - name: orderId
      in: path
      required: true
      description: The order ID to cancel
      schema:
        type: string

- ref: inventory-mcp
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: inventory-mcp
  display_name: Inventory API MCP tools
  type: conversion-only
  config:
    url: https://httpbin.konghq.com/anything
    max_request_body_size: 1048576
    logging:
      payloads: true
  tools:
  - name: list-inventory
    description: >-
      List inventory items with optional filters for category
      or low stock alerts.
    method: GET
    path: /inventory
    annotations:
      read_only_hint: true
      title: List inventory
    access:
      acls:
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
    description: >-
      Check current stock level, reorder threshold, and product
      details for a specific SKU.
    method: GET
    path: /inventory/{sku}
    annotations:
      read_only_hint: true
      title: Check inventory for SKU
    access:
      acls:
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
    description: >-
      Add units to a product's inventory. Only warehouse
      operations staff can perform restocking.
    method: POST
    path: /inventory/{sku}/restock
    annotations:
      destructive_hint: true
      title: Restock inventory item
    access:
      acls:
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
      description: Number of units to add to inventory
      schema:
        type: integer

- ref: customers-mcp
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: customers-mcp
  display_name: Customers API MCP tools
  type: conversion-only
  config:
    url: https://httpbin.konghq.com/anything
    max_request_body_size: 1048576
    logging:
      payloads: true
  tools:
  - name: get-customer
    description: >-
      Retrieve customer profile including name, contact info,
      and account status. Only customer support can access
      customer data.
    method: GET
    path: /customers/{customerId}
    annotations:
      read_only_hint: true
      title: Get customer details
    access:
      acls:
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
    description: >-
      Update a customer's contact information. Only customer
      support agents can modify customer records.
    method: PUT
    path: /customers/{customerId}/contact
    annotations:
      destructive_hint: true
      title: Update customer contact info
    access:
      acls:
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

- ref: ecommerce-mcp
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: ecommerce-mcp
  display_name: Aggregated Ecommerce MCP Server
  type: listener
  sources:
  - orders-mcp
  - inventory-mcp
  - customers-mcp
  access:
    acl_attribute_type: consumer
    auth_strategies:
    - secure-internal-mcp-gateway-auth
    metadata:
      resource: !env 'MCP_RESOURCE_URL'
      endpoint: /.well-known/oauth-protected-resource/ecommerce-mcp
  config:
    max_request_body_size: 1048576
    logging:
      payloads: true
      audits: true
    route:
      paths:
      - /ecommerce-mcp
      protocols:
      - http
      - https
    server:
      forward_client_headers: true
  policies:
  - secure-internal-mcp-gateway-cors

ai_gateway_policies:
- ref: secure-internal-mcp-gateway-cors
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: secure-internal-mcp-gateway-cors
  display_name: secure-internal-mcp-gateway CORS
  type: cors
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

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

## Try it out

With the configuration applied and your IdP configured, the aggregated MCP endpoint is ready to accept authenticated connections. The verification path below uses [Insomnia](/insomnia/mcp-clients-in-insomnia/), Kong's MCP-aware API client, to exercise the full OAuth + ACL flow. Once verified, you can plug the same endpoint into any MCP-compatible AI client.

### Verify with Insomnia

Insomnia speaks the MCP protocol natively. It auto-discovers Protected Resource Metadata (PRM) from a 401 response, runs the OAuth 2.1 + PKCE dance against the IdP, and exposes every step of the auth handshake in its **Events** panel with full request/response inspection.

To verify the gateway:

1. **Create an MCP request.** In Insomnia, create a new request and select **MCP** as the request type. Enter the gateway URL:

    ```text
    http://localhost:8000/ecommerce-mcp
    ```
    {:.no-copy-code}

1. **Configure OAuth on the request.** Click the **Auth** tab and select **OAuth 2.0** from the dropdown. Set **Grant Type** to **MCP Auth flow**. Enter the **Client ID** copied from the `MCP Client` SPA application in your IdP (Okta) or the `mcp-client` public client (Keycloak). Set **State** to any value (for example, `recipe-test`). Insomnia uses these values when it runs the PKCE flow in the next step.

1. **Initiate the connection.** Insomnia sends an MCP `initialize` request without credentials. Kong's aggregated AI MCP Server returns `401` with a `WWW-Authenticate: Bearer resource_metadata=...` header pointing at `/.well-known/oauth-protected-resource/ecommerce-mcp`. The **Events** tab shows the unauthenticated initialize, the 401, and Insomnia's follow-up GET against the PRM URL. The raw 401 response looks like this:

    ```text
    HTTP/1.1 401 Unauthorized
    WWW-Authenticate: Bearer resource_metadata="http://localhost:8000/.well-known/oauth-protected-resource/ecommerce-mcp"
    Content-Type: application/json

    {"error":"unauthorized","error_description":"Missing access token"}
    ```
    {:.no-copy-code}

    The `WWW-Authenticate` header makes the endpoint MCP-spec compliant. MCP clients read the `resource_metadata` URL, fetch the PRM document, and discover the authorization server.

1. **Complete OAuth.** Insomnia opens your browser to the IdP's authorization endpoint with a generated PKCE code challenge. Sign in as your test user (a member of `warehouse-ops`) and approve the application. Insomnia captures the redirect, exchanges the authorization code for an access token, and reconnects to the MCP endpoint with `Authorization: Bearer <token>`. The OAuth handshake appears as a sequence of `MCP Auth` entries in the **Events** tab.

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

    Kong filters out the three customer-only tools (`cancel-order`, `get-customer`, `update-customer-contact`) before the response leaves the gateway. Kong evaluates the caller's AI Consumer Group against each tool's ACL before returning the catalog. To see the other persona, move your test user from `warehouse-ops` to `customer-support` in the IdP and rerun the OAuth flow. The catalog flips to seven tools, with `restock-item` filtered out instead.

1. **Call a permitted tool.** Select `check-inventory`, set `sku` to `WIDGET-42`, and call it. The call succeeds; the response body shows the proxied call to the inventory backend (httpbin echoes the request details in this recipe). Inspect the response headers. Kong attaches `X-Kong-Upstream-Latency` (time in ms spent waiting for the upstream MCP server) and `X-Kong-Proxy-Latency` (time in ms Kong spent on auth, ACL, and routing) on every authenticated call.

1. **Call a restricted tool.** Manually invoke `cancel-order` (you can enter the tool name directly even though it's hidden from the catalog, which simulates a misbehaving client). Kong returns `HTTP 403 Forbidden` explaining the tool isn't available for your AI Consumer Group. The token is valid; Kong's ACL evaluates it and denies the call before the request reached any upstream.

1. **(Optional) Verify the auth boundary.** Replace the captured access token with `not-a-real-token` and resend the initialize. Kong's introspection call rejects the token and the aggregated AI MCP Server returns the same `401 + WWW-Authenticate` response as the unauthenticated case. This check confirms that invalid credentials never bypass auth.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `secure-internal-mcp-gateway-recipe`. The recipe created:

- **AI MCP Servers**: three `conversion-only` entities (`orders-mcp`, `inventory-mcp`, `customers-mcp`) and one `listener` entity (`ecommerce-mcp`) that aggregates them.
- **AI Auth Strategy**: `secure-internal-mcp-gateway-auth`, the `openid-connect` strategy that authenticates the aggregated endpoint.
- **AI Consumer Groups**: `warehouse-ops` and `customer-support`. The recipe doesn't pre-provision any AI Consumers. The AI Auth Strategy runs with `consumer_optional: true`, so Kong identifies the caller by the IdP-issued `sub` claim and resolves group membership from the `groups` claim against these groups at request time.
- **AI Policy**: `secure-internal-mcp-gateway-cors`, attached to the `ecommerce-mcp` listener.

The kongctl namespace applied above scopes all of these resources to this recipe. For platform-wide traffic analysis, including tool-call volume and ACL denial rates, across every {{site.ai_gateway}}, head to the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

- **Connect from an AI harness.** The same gateway URL works in any MCP-compatible client (Claude Code, VS Code, Claude Desktop, and others). Each client handles OAuth differently, so follow the client's documentation for adding a remote MCP server. Before connecting, register that client's OAuth redirect URI on your IdP `MCP Client` application alongside Insomnia's `https://app.insomnia.rest/oauth/redirect`. Token validation, ACL evaluation, and the `groups` claim mapping are unchanged.
- **Add rate limiting per AI Consumer Group.** Attach a [Rate Limiting Advanced](/ai-gateway/policies/rate-limiting-advanced/) Policy to the `ecommerce-mcp` listener's `policies` field to enforce per-tier request budgets, giving premium groups higher quotas while protecting shared infrastructure.
- **Expand to multiple MCP servers.** Add additional `conversion-only` (or `upstream-server`, for an existing MCP server) entities for other internal systems (databases, monitoring, CI/CD), and list their names in the listener's `sources` field. Each gets its own ACL configuration while sharing the same OAuth authentication flow.
- **Add response logging for audit trails.** Set `config.logging.audits: true` on any AI MCP Server to capture ACL decisions for compliance auditing, in addition to `config.logging.payloads` for full request and response bodies.
- **Integrate with external identity providers.** Replace the Okta configuration with Azure AD, Auth0, or Keycloak by updating the OAuth endpoints in the AI Auth Strategy config.

## Cleanup

The recipe's kongctl namespace scopes all resources, so the teardown removes only this
recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='secure-internal-mcp-gateway-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
