---
title: Secure External MCP Gateway
description: Proxy third-party MCP servers (GitHub, Konnect) through {{site.base_gateway}} with centralized access control, observability, and tool-level ACLs.
url: "/cookbooks/secure-external-mcp-gateway/"
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
  - datakit
  - key-auth
  - response-transformer-advanced
  - request-transformer-advanced
  - cors
requires_embeddings: false
extra_services:
  - name: GitHub OAuth Application
    env_vars: [GITHUB_OAUTH_CLIENT_ID]
    hint: "Create a GitHub OAuth Application with a redirect URI of https://app.insomnia.rest/oauth/redirect (Insomnia 12+'s built-in OAuth callback; use the redirect URI of whichever MCP client you'll test with). See the GitHub section in Prerequisites."
  - name: Identity Provider (Okta or Keycloak)
    env_vars: [DECK_OAUTH_AUTH_SERVER, DECK_OAUTH_INTROSPECTION_URL, DECK_OAUTH_CLIENT_ID, DECK_OAUTH_CLIENT_SECRET]
    hint: "Required for the Konnect MCP pattern. Create an OAuth application for Kong. See the Identity Provider section in Prerequisites."

hint: "Requires a GitHub OAuth application, an identity provider (Okta or Keycloak), a Konnect personal access token, and Insomnia 12+ for testing."

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

        1. Export the upstream credential for the Konnect MCP token-swap demo. The Konnect MCP server accepts either a PAT or a Service Account Token (SAT); reusing your PAT here keeps the recipe to a single Konnect credential:

           ```bash
           export DECK_KONNECT_MCP_TOKEN="${KONNECT_TOKEN}"
           ```

           {:.warning}
           > This reuses your PAT as the upstream credential so the demo only needs one Konnect token. In production, generate a **System Account Token** with least-privilege permissions in **Organization > System Accounts** and store it in a [Kong Vault](/gateway/latest/kong-enterprise/secrets-management/) using {%raw%}`{vault://backend/key}`{%endraw%} references. PATs inherit the creator's full role and are tied to an individual user, which is unsuitable for a shared, audited service-account credential.

        1. Set the recipe-scoped Control Plane name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='secure-external-mcp-gateway-recipe'
           curl -Ls https://get.konghq.com/quickstart | bash -s -- -k $KONNECT_TOKEN --deck-output
           ```

           This provisions a Konnect Control Plane named `secure-external-mcp-gateway-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars. Paste those into your shell when prompted.
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
    - title: GitHub OAuth Application
      icon_url: /assets/icons/github.svg
      content: |
        GitHub's authorization server does not support Dynamic Client Registration (DCR), so you must create an OAuth application manually to represent your MCP client.

        1. Go to [GitHub Settings > Developer settings > OAuth Apps](https://github.com/settings/developers).
        1. Click **New OAuth App**.
        1. Fill in the required fields:
           - **Application name:** `Kong MCP Client` (or any descriptive name)
           - **Homepage URL:** `https://localhost:8443` (required by GitHub but not used in the OAuth flow)
           - **Authorization callback URL:** `https://app.insomnia.rest/oauth/redirect`. This is Insomnia 12+'s built-in OAuth callback. To use a different MCP client, register a separate OAuth app with that client's callback URL.
        1. Click **Register application**.
        1. On the new application's page, click **Generate a new client secret** and copy the value immediately (GitHub only shows it once).
        1. Note both the **Client ID** and the **Client Secret**. MCP clients prompt for both values when they start the GitHub OAuth flow; the recipe does not export them as environment variables.

        {:.warning}
        > GitHub OAuth Apps require the Client Secret at the token-exchange step. There is no public-client or PKCE-only flow. Omitting the secret causes the OAuth dance to fail with `incorrect_client_credentials`. Treat the secret as sensitive: it grants any holder the ability to mint tokens on behalf of this OAuth App.

        {:.info}
        > GitHub OAuth apps can only have **one** callback URL. If you use multiple MCP clients with different callback URLs, create a separate OAuth app for each.
    - title: Identity Provider
      content: |
        The Konnect MCP Route uses the [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin to authenticate users against your organization's OAuth 2.1 IdP. This recipe shows setup steps for Okta and Keycloak, both of which expose an RFC 7662 token introspection endpoint. Other IdPs (Microsoft Entra ID, Auth0, AWS Cognito, Google) work too. They expose a JWKS endpoint instead, which the AI MCP OAuth2 Plugin validates locally without an introspection call. Select your IdP below and follow the setup steps.

        {% navtabs "Identity Provider" %}
        {% tab Okta %}

        You need an Okta organization with admin access. The steps below create two Okta applications, set up a test user (new or existing), and export Kong's introspection credentials.

        **Create the Kong MCP Gateway application**

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

        **Set up a test user**

        The Konnect MCP route authenticates any valid IdP user and forwards upstream as a stored service account, so a single user account is enough to run the recipe. Group membership is not required.

        1. Go to **Directory → People** and either add a new person (for example, `mcp-test-user@example.com`) or pick an existing user. Make sure the user has a password set and can sign in.
        1. Open the `MCP Client` application created above, go to the **Assignments** tab, and assign this user. Without this assignment, Okta blocks the OAuth flow at sign-in.

        **Export Kong's Okta endpoints and credentials**

        Export the authorization server URL, the introspection endpoint, and the **Kong MCP Gateway** application's Client ID and Secret. The MCP Client (SPA) Client ID is not exported here. It is used at flow time by the MCP client itself.

        ```bash
        export DECK_OAUTH_AUTH_SERVER='https://your-org.okta.com/oauth2/default'
        export DECK_OAUTH_INTROSPECTION_URL='https://your-org.okta.com/oauth2/default/v1/introspect'
        export DECK_OAUTH_CLIENT_ID='your-kong-gateway-client-id'
        export DECK_OAUTH_CLIENT_SECRET='your-kong-gateway-client-secret'
        ```

        {% endtab %}
        {% tab Keycloak %}

        You need a Keycloak instance with admin access. The steps below create a realm, two clients, set up a test user (new or existing), and export Kong's introspection credentials.

        **Create a realm**

        In the Keycloak Admin Console, create a new realm (for example, `mcp-demo`), or use an existing one.

        **Create the Kong MCP Gateway client**

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
        1. Enable **Standard flow** (Authorization Code). Keycloak enforces PKCE for public clients automatically.
        1. Note the **Client ID** (`mcp-client`) for use in your MCP client. Insomnia and other MCP clients prompt for this value when they start the OAuth flow; the recipe does not export it as an environment variable.

        **Set up a test user**

        The Konnect MCP route authenticates any valid IdP user and forwards upstream as a stored service account, so a single user account is enough to run the recipe. Group membership is not required.

        1. Go to **Users** and either add a new user (for example, `mcp-test-user`) or pick an existing one. On the **Credentials** tab, set a password and clear **Temporary** so the user can sign in directly.

        **Export Kong's Keycloak endpoints and credentials**

        Export the realm URL, the introspection endpoint, and the **Kong MCP Gateway** client's ID and Secret. The MCP Client's Client ID is not exported here. It is used at flow time by the MCP client itself.

        ```bash
        export DECK_OAUTH_AUTH_SERVER='https://your-keycloak-host/realms/mcp-demo'
        export DECK_OAUTH_INTROSPECTION_URL='https://your-keycloak-host/realms/mcp-demo/protocol/openid-connect/token/introspect'
        export DECK_OAUTH_CLIENT_ID='kong-mcp-gateway'
        export DECK_OAUTH_CLIENT_SECRET='your-kong-gateway-client-secret'
        ```

        {% endtab %}
        {% endnavtabs %}
    - title: Konnect MCP region
      content: |
        The [Konnect MCP server](/konnect-platform/konnect-mcp/#regional-server-endpoints) has region-scoped endpoints; resources don't cross regions. Set this to the host matching the Konnect region your organization runs in:

        ```bash
        # Pick one: us.mcp.konghq.com, eu.mcp.konghq.com, or au.mcp.konghq.com
        export DECK_KONNECT_MCP_HOST='us.mcp.konghq.com'
        ```
    - title: Insomnia 12+
      content: |
        This recipe verifies the gateway using [Insomnia](https://insomnia.rest/), Kong's MCP-aware API client. Insomnia speaks the MCP protocol natively and handles the full OAuth 2.1 + PKCE dance, including Protected Resource Metadata (PRM) discovery.

        1. Install **Insomnia** from [insomnia.rest/download](https://insomnia.rest/download).
        1. Verify the version is 12.0 or later (Help → About on macOS, equivalent on other platforms).

        {:.warning}
        > Konnect's MCP server rejects HTTP-originated traffic, so this recipe targets Kong's local HTTPS listener at `https://localhost:8443`, which uses a self-signed certificate. On each MCP request you create in Insomnia, click **Manage Certificates** at the top of the request pane and toggle **SSL Certificate Validation** off under **Extra Options**. Scope this per-request, not globally.

        See [MCP clients in Insomnia](/insomnia/mcp-clients-in-insomnia/) for an overview of MCP server testing in Insomnia.

overview: |
  Organizations adopting MCP (Model Context Protocol) often end up connecting AI agents to a sprawl of third-party MCP servers (GitHub, Slack, Figma, Konnect, etc.), each with its own tokens, no central audit trail, and no way to govern which tools an agent can call. Putting {{site.base_gateway}} in front of those servers gives the platform team a single boundary for ACL enforcement, observability, and credential management without changing how the upstream provider's auth works.

  Broadly, there are two types of MCP servers {{site.ai_gateway_name}} can proxy, distinguished by who owns the user identity. **Internal MCP servers** live inside your organization's trust boundary. Your IdP is the MCP auth server, and your security team controls the tokens. That case is covered in [Secure Internal MCP Gateway](/cookbooks/secure-internal-mcp-gateway/). **External MCP servers** are third-party SaaS like GitHub, Slack, and Figma that run their own authorization servers and issue their own (often opaque) tokens.

  This recipe covers the external case. Kong applies one of two patterns depending on what the upstream supports, demonstrated below with GitHub MCP and Konnect MCP. The **Passthrough** pattern (GitHub MCP) lets the user authenticate directly with GitHub; Kong passes the token through and uses a separate Key Auth layer for Consumer identity and ACLs. The **Token swap** pattern (Konnect MCP) authenticates the user against the organization's IdP, maps the user to a Consumer, then swaps the user token for a stored Konnect credential (Personal Access Token for the demo, Service Account Token in production) before forwarding.
---

## The problem

**External tokens are opaque to Kong.** GitHub, Figma, and most third-party MCP servers issue
opaque access tokens, not JWTs. Kong cannot extract claims from an opaque token, which means
there is no way to identify the user, map them to a Consumer Group, or enforce ACLs based on
the token alone.

**MCP auth discovery is inconsistent.** The MCP spec requires servers to advertise their auth
requirements via Protected Resource Metadata (PRM, RFC 9728). When Kong proxies an external MCP
server, the PRM's `resource` field points at the upstream (e.g., `api.githubcopilot.com/mcp`),
not at Kong. MCP clients that follow this field would try to validate against the wrong resource.
Kong must rewrite the PRM to point at itself while preserving the authorization server
information.

**No centralized observability or access control.** Without a proxy, each developer connects
directly to external MCP servers. There is no audit trail, no way to restrict which tools an
AI agent can call, and no visibility into what tools are being used across the organization.
A junior developer's AI agent has the same GitHub tool access as a senior engineer's.

**Token management is distributed.** Each developer manages their own tokens for each external
MCP server. There is no central revocation point, no token rotation policy, and no way to use
a shared service account for services that support it (like Konnect).

## The solution

This recipe places {{site.base_gateway}} in front of external MCP servers with two distinct patterns:

**GitHub MCP (passthrough pattern):**

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP Client
    participant K as {{site.base_gateway}}
    participant GH as GitHub

    C->>K: MCP initialize (no token)
    activate K
    K-->>C: 401 + PRM pointer (datakit)
    deactivate K

    C->>K: GET /.well-known/oauth-protected-resource/github-mcp
    activate K
    K-->>C: PRM (resource rewritten to Kong URL)
    deactivate K

    C->>GH: OAuth flow (browser → GitHub OAuth → callback)
    activate GH
    GH-->>C: GitHub Bearer token
    deactivate GH

    C->>K: MCP request (apikey + Bearer)
    activate K
    K->>K: key-auth (resolve Kong Consumer)
    K->>K: ai-mcp-proxy passthrough-listener (evaluate tool ACLs, log)
    K->>GH: Forward request with Bearer to GitHub MCP Server
    activate GH
    GH-->>K: MCP response
    deactivate GH
    K-->>C: MCP response
    deactivate K
{% endmermaid %}
<!-- vale on -->

**Konnect MCP (token swap pattern):**

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP Client
    participant K as {{site.base_gateway}}
    participant IdP as Identity Provider
    participant KM as Konnect MCP Server

    C->>K: MCP initialize (no token)
    activate K
    K-->>C: 401 + PRM (ai-mcp-oauth2)
    deactivate K

    C->>IdP: OAuth flow (browser → Okta/Keycloak → callback)
    activate IdP
    IdP-->>C: Bearer token
    deactivate IdP

    C->>K: MCP request (Bearer token)
    activate K
    K->>IdP: ai-mcp-oauth2 (introspect token)
    activate IdP
    IdP-->>K: Claims (sub → Kong Consumer)
    deactivate IdP
    K->>K: Strip user token, inject stored Konnect token (request-transformer-advanced)
    K->>KM: Forward request with stored Konnect token
    activate KM
    KM-->>K: MCP response
    deactivate KM
    K-->>C: MCP response (logged via ai-mcp-proxy)
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
  - component: "GitHub OAuth"
    responsibility: "Issues tokens for GitHub API access; MCP clients authenticate directly"
  - component: "Identity Provider (Okta / Keycloak)"
    responsibility: "Issues tokens for organizational identity; used by Konnect MCP pattern"
  - component: "Kong [Datakit](/plugins/datakit/) Plugin"
    responsibility: "Checks for Authorization header; returns 401 + PRM pointer for unauthenticated requests"
  - component: "Kong [Key Auth](/plugins/key-auth/) Plugin"
    responsibility: "Resolves Kong Consumer from `apikey` header for GitHub MCP ACL evaluation"
  - component: "Kong [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin"
    responsibility: "MCP-native OAuth for Konnect MCP: PRM, introspection, Consumer mapping"
  - component: "Kong [AI MCP Proxy](/plugins/ai-mcp-proxy/) Plugin (`passthrough-listener`)"
    responsibility: "Proxies MCP traffic to upstream servers; enforces tool-level ACLs; provides observability"
  - component: "Kong [Response Transformer Advanced](/plugins/response-transformer-advanced/) Plugin"
    responsibility: "Rewrites GitHub's PRM resource field to point at Kong"
  - component: "Kong [Request Transformer Advanced](/plugins/request-transformer-advanced/) Plugin"
    responsibility: "Swaps user token for stored Konnect credential (PAT or SAT)"
{% endtable %}

### ACL matrix (GitHub MCP)

The GitHub MCP server exposes 70+ tools. This recipe defines ACLs for a representative subset,
with a default deny for the `developer` group on unlisted tools:

{% table %}
columns:
  - title: Tool
    key: tool
  - title: admin
    key: admin
  - title: developer
    key: developer
  - title: Type
    key: type
rows:
  - tool: "`search_repositories`"
    admin: "yes"
    developer: "yes"
    type: "read"
  - tool: "`get_file_contents`"
    admin: "yes"
    developer: "yes"
    type: "read"
  - tool: "`list_issues`"
    admin: "yes"
    developer: "yes"
    type: "read"
  - tool: "`list_pull_requests`"
    admin: "yes"
    developer: "yes"
    type: "read"
  - tool: "`search_users`"
    admin: "yes"
    developer: "yes"
    type: "read"
  - tool: "`search_code`"
    admin: "yes"
    developer: "yes"
    type: "read"
  - tool: "`create_issue`"
    admin: "yes"
    developer: "no"
    type: "write"
  - tool: "`push_files`"
    admin: "yes"
    developer: "no"
    type: "write"
  - tool: "`create_pull_request`"
    admin: "yes"
    developer: "no"
    type: "write"
  - tool: "`merge_pull_request`"
    admin: "yes"
    developer: "no"
    type: "write"
  - tool: "`create_repository`"
    admin: "yes"
    developer: "no"
    type: "write"
  - tool: "*(all other tools)*"
    admin: "yes"
    developer: "no"
    type: "default deny"
{% endtable %}

Developers can search and read repositories, issues, pull requests, and code. Admins can also
create issues, push code, create and merge pull requests, and create repositories. Any GitHub
MCP tool not explicitly listed in the config is denied for developers but allowed for admins
via the `default_acl`.

## How it works

When a request arrives at Kong for an external MCP server, the following sequence occurs:

1. The MCP client sends an unauthenticated request to discover the MCP server's Protected Resource Metadata (PRM) through Kong.
2. For the GitHub MCP pattern, Kong's [Datakit](/plugins/datakit/) Plugin detects the missing Authorization header and returns a 401 with a `WWW-Authenticate` header pointing to the PRM endpoint. For the Konnect MCP pattern, the [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin handles this natively.
3. The client fetches the PRM document from Kong. Kong proxies the upstream PRM and rewrites the `resource` field to point at Kong's proxy URL instead of the upstream server.
4. The client completes the OAuth flow with the appropriate authorization server (GitHub for passthrough, the organization's IdP for token swap).
5. The client connects to the MCP endpoint through Kong with the obtained access token. For GitHub MCP, the client also sends an `apikey` header for Kong Consumer identity.
6. Kong authenticates and authorizes the request. For GitHub MCP, the [Key Auth](/plugins/key-auth/) Plugin resolves the Kong Consumer and the [AI MCP Proxy](/plugins/ai-mcp-proxy/) Plugin enforces tool-level ACLs. For Konnect MCP, the AI MCP OAuth2 Plugin introspects the token and maps claims to a Consumer.
7. For the Konnect MCP pattern, the [Request Transformer Advanced](/plugins/request-transformer-advanced/) Plugin strips the user's token and injects a stored Konnect credential (PAT or SAT) before forwarding.
8. The upstream MCP server processes the request and returns results through Kong to the client.

The following sections explain each Plugin's configuration in detail.

### GitHub MCP: PRM discovery with Datakit

When an MCP client connects without a token, Kong needs to return a `401` with a
`WWW-Authenticate` header pointing to the Protected Resource Metadata endpoint. For external
MCP servers, this is handled by the [Datakit](/plugins/datakit/) Plugin rather than
the [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin, because the auth flow goes to the external provider (GitHub), not to Kong's IdP.

#### Configuration details

```yaml
- name: datakit
  ordering:
    before:
      access:
        - ai-mcp-proxy
        - key-auth
  config:
    nodes:
      - name: CHECK_AUTH
        type: jq
        inputs:
          headers: request.headers
        jq: >-
          .headers.Authorization? != null or
          .headers.authorization? != null
      - name: AUTH_BRANCH
        type: branch
        input: CHECK_AUTH
        else:
          - UNAUTH_RESPONSE
          - UNAUTH_EXIT
      - name: UNAUTH_RESPONSE
        type: static
        values:
          content-type: application/json
          www-authenticate: >-
            Bearer
            resource_metadata="https://localhost:8443/.well-known/oauth-protected-resource/github-mcp",
            error="invalid_token"
          BODY: '{"message": "Unauthorized"}'
      - name: UNAUTH_EXIT
        type: exit
        status: 401
        inputs:
          body: UNAUTH_RESPONSE.BODY
          headers: UNAUTH_RESPONSE
```
{: .no-copy-code .collapsible }

The [Datakit](/plugins/datakit/) Plugin uses four nodes:

1. **CHECK_AUTH** (jq): Reads request headers and checks if an `Authorization` header is present
   (case-insensitive). Returns `true` or `false`.
2. **AUTH_BRANCH** (branch): If `true`, the request passes through to the next Plugin (Key Auth).
   If `false`, executes the `else` branch to return a 401.
3. **UNAUTH_RESPONSE** (static): Defines the response headers including `WWW-Authenticate`
   with the PRM endpoint URL and a JSON body.
4. **UNAUTH_EXIT** (exit): Returns status 401 with the static headers and body, short-circuiting
   the request so it never reaches the upstream.

The `ordering.before.access` ensures Datakit runs before both Key Auth and AI MCP Proxy.

### GitHub MCP: PRM rewriting with Response Transformer Advanced

The MCP client fetches the PRM from Kong at `/.well-known/oauth-protected-resource/github-mcp`.
Kong proxies this request to GitHub's actual PRM endpoint and rewrites the `resource` field
to point at Kong instead of GitHub.

#### Configuration details

```yaml
- name: response-transformer-advanced
  config:
    replace:
      json:
        - "resource:https://localhost:8443/github-mcp"
      json_types:
        - string
```
{:.no-copy-code}

The upstream PRM from GitHub looks like:

```json
{
  "resource": "https://api.githubcopilot.com/mcp",
  "authorization_servers": ["https://github.com/login/oauth"],
  "scopes_supported": ["repo", "gist", "notifications", ...]
}
```
{:.no-copy-code}

After rewriting, the MCP client sees:

```json
{
  "resource": "https://localhost:8443/github-mcp",
  "authorization_servers": ["https://github.com/login/oauth"],
  "scopes_supported": ["repo", "gist", "notifications", ...]
}
```
{:.no-copy-code}

The `resource` field now points at Kong (the proxy). The `authorization_servers` field still
points at GitHub. This is correct because the MCP client authenticates directly with GitHub's
OAuth server, not with Kong.

### GitHub MCP: Dual auth model

External MCP servers with opaque tokens create a dual auth challenge:

- **Who are you in this organization?** Needed for ACLs, audit, and access control.
- **What can you access on GitHub?** Needed by the upstream MCP server.

Kong solves this with two coexisting auth mechanisms:

- **`apikey` header**: [Key Auth](/plugins/key-auth/) resolves the Kong Consumer for ACL
  evaluation. The key identifies the user within the organization.
- **`Authorization: Bearer` header**: Passed through to GitHub's MCP server for upstream
  authentication.

These coexist because Key Auth defaults to the `apikey` header, not `Authorization`. Both
headers travel on the same request without interference.

#### Configuration details

```yaml
- name: key-auth
  config:
    key_names:
      - apikey
```
{:.no-copy-code}

### AI MCP Proxy: Tool-level ACLs on passthrough-listener

The [AI MCP Proxy](/plugins/ai-mcp-proxy/) Plugin in `passthrough-listener` mode proxies MCP traffic to the upstream
server while enforcing tool-level ACLs. In passthrough mode, the Plugin does not define tools
from scratch. Instead, it defines tool **names** that match the remote server's tools, with ACL rules
attached.

#### Configuration details

```yaml
- name: ai-mcp-proxy
  config:
    mode: passthrough-listener
    consumer_identifier: username
    include_consumer_groups: true
    default_acl:
      - deny:
          - developer
        scope: tools
    tools:
      - name: search_repositories
        acl:
          allow: [admin, developer]
      - name: push_files
        acl:
          allow: [admin]
```
{:.no-copy-code}

**`default_acl`** with `deny: [developer]` ensures that any GitHub MCP tool NOT explicitly
listed is blocked for the developer Consumer Group. Admin users are not denied by default, so they can
access all 70+ GitHub MCP tools. Per-tool **`acl`** definitions completely override the default
for that specific tool. The **`mode`** field is set to `passthrough-listener`, which means Kong proxies
MCP traffic to the upstream server rather than serving tools locally. The **`consumer_identifier`**
field tells the Plugin to use the Consumer's `username` field for ACL evaluation, and
**`include_consumer_groups`** enables Consumer Group-based ACL rules.

### Konnect MCP: Token swap pattern

The Konnect MCP server supports PAT/SAT authentication. Instead of passing the user's token
through, Kong implements a token swap:

1. The [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin authenticates the user via the organization's IdP (Okta/Keycloak), validates the token through introspection, maps claims to Kong Consumers, and strips the user's `Authorization` header before the request continues (`passthrough_credentials: false`)
2. The [Request Transformer Advanced](/plugins/request-transformer-advanced/) Plugin injects the stored Konnect credential into the now-empty `Authorization` header
3. The [AI MCP Proxy](/plugins/ai-mcp-proxy/) Plugin (passthrough-listener) provides observability

Each plugin owns one step of the swap: AI MCP OAuth2 removes the inbound credential as part of successful authentication; Request Transformer Advanced adds the outbound credential. The chain works because `add.headers` injects the header only when one is not already present, and the auth plugin has guaranteed that by the time the transformer runs. `passthrough_credentials` is set explicitly so the contract between the two plugins is visible in the configuration.

This pattern means users authenticate with their organizational identity, but the Konnect API
call uses a centrally managed credential. This recipe reuses your Konnect PAT for the demo
through the `DECK_KONNECT_MCP_TOKEN` env var. In production, replace the PAT with a
least-privilege Service Account Token stored in a Kong Vault backend.

The recipe authenticates users on this route but doesn't enforce tool-level ACL. The [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin already maps an IdP `groups` claim to Kong Consumer Groups (`consumer_groups_claim: [groups]`), so layering on per-tool ACL is a matter of pre-creating the Consumer Groups and adding ACL rules to the [AI MCP Proxy](/plugins/ai-mcp-proxy/) Plugin, the same way the GitHub MCP route does. The [Secure Internal MCP Gateway](/cookbooks/secure-internal-mcp-gateway/) recipe shows the full IdP-claim-to-ACL pattern end-to-end.

{:.info}
> In production, store credentials in [Kong Vaults](/gateway/latest/kong-enterprise/secrets-management/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. Kong supports HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the Konnect Config Store.

## Apply the Kong configuration

This section configures the Control Plane in two parts. First, adopt the quickstart Control Plane into a kongctl namespace so the apply command below can manage it. The recipe's `select_tags` and the `secure-external-mcp-gateway-recipe` namespace scope every resource so teardown removes only this recipe's configuration.

```bash
kongctl adopt control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the Control Plane.

The configuration below creates two external MCP proxy setups: GitHub MCP with passthrough auth and tool-level ACLs, and Konnect MCP with OAuth token swap. Two Consumer Groups (`admin` and `developer`) control GitHub tool access. The `DECK_OAUTH_*`, `DECK_KONNECT_MCP_TOKEN`, and `DECK_KONNECT_MCP_HOST` env vars are already exported during the prereqs. Apply the configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - secure-external-mcp-gateway-recipe
consumer_groups:
- name: admin
- name: developer
consumers:
- username: admin-user
  keyauth_credentials:
  - key: admin-api-key
  groups:
  - name: admin
- username: dev-user
  keyauth_credentials:
  - key: dev-api-key
  groups:
  - name: developer
services:
- name: github-mcp-service
  host: api.githubcopilot.com
  port: 443
  protocol: https
  path: /mcp
  routes:
  - name: github-mcp
    paths:
    - /github-mcp
    protocols:
    - http
    - https
    strip_path: true
    request_buffering: false
    response_buffering: false
    plugins:
    - name: datakit
      instance_name: github-mcp-prm-challenge
      tags:
      - secure-external-mcp-gateway-recipe
      ordering:
        before:
          access:
          - ai-mcp-proxy
          - key-auth
      config:
        nodes:
        - name: CHECK_AUTH
          type: jq
          inputs:
            headers: request.headers
          jq: .headers.Authorization? != null or .headers.authorization? != null
        - name: AUTH_BRANCH
          type: branch
          input: CHECK_AUTH
          else:
          - UNAUTH_RESPONSE
          - UNAUTH_EXIT
        - name: UNAUTH_RESPONSE
          type: static
          values:
            content-type: application/json
            www-authenticate: >-
              Bearer
              resource_metadata="https://localhost:8443/.well-known/oauth-protected-resource/github-mcp",
              error="invalid_token"
            BODY: '{"message": "Unauthorized"}'
        - name: UNAUTH_EXIT
          type: exit
          status: 401
          inputs:
            body: UNAUTH_RESPONSE.BODY
            headers: UNAUTH_RESPONSE
    - name: key-auth
      instance_name: github-mcp-key-auth
      tags:
      - secure-external-mcp-gateway-recipe
      config:
        key_names:
        - apikey
        hide_credentials: true
    - name: ai-mcp-proxy
      instance_name: github-mcp-listener
      tags:
      - secure-external-mcp-gateway-recipe
      config:
        mode: passthrough-listener
        consumer_identifier: username
        include_consumer_groups: true
        default_acl:
        - deny:
          - developer
          scope: tools
        logging:
          log_payloads: true
          log_statistics: true
        tools:
        - name: search_repositories
          description: Search GitHub repositories
          acl:
            allow: [admin, developer]
        - name: get_file_contents
          description: Get file contents from a repository
          acl:
            allow: [admin, developer]
        - name: list_issues
          description: List issues in a repository
          acl:
            allow: [admin, developer]
        - name: list_pull_requests
          description: List pull requests in a repository
          acl:
            allow: [admin, developer]
        - name: search_users
          description: Search GitHub users
          acl:
            allow: [admin, developer]
        - name: search_code
          description: Search code across repositories
          acl:
            allow: [admin, developer]
        - name: create_issue
          description: Create an issue in a repository
          acl:
            allow: [admin]
        - name: push_files
          description: Push files to a repository
          acl:
            allow: [admin]
        - name: create_pull_request
          description: Create a pull request
          acl:
            allow: [admin]
        - name: merge_pull_request
          description: Merge a pull request
          acl:
            allow: [admin]
        - name: create_repository
          description: Create a new repository
          acl:
            allow: [admin]
    - name: cors
      instance_name: github-mcp-cors
      tags:
      - secure-external-mcp-gateway-recipe
      config:
        origins: ['*']
        methods: [GET, HEAD, PUT, PATCH, POST, DELETE, OPTIONS]
        credentials: false
        preflight_continue: false
- name: github-mcp-prm-service
  host: api.githubcopilot.com
  port: 443
  protocol: https
  path: /.well-known/oauth-protected-resource/mcp
  routes:
  - name: github-mcp-prm
    paths:
    - /.well-known/oauth-protected-resource/github-mcp
    protocols:
    - http
    - https
    methods: [GET, POST]
    strip_path: true
    preserve_host: false
    plugins:
    - name: response-transformer-advanced
      instance_name: github-mcp-prm-rewrite
      tags:
      - secure-external-mcp-gateway-recipe
      config:
        replace:
          json:
          - 'resource:https://localhost:8443/github-mcp'
          json_types:
          - string
- name: konnect-mcp-service
  host: ${{ env "DECK_KONNECT_MCP_HOST" }}
  port: 443
  protocol: https
  routes:
  - name: konnect-mcp
    paths:
    - /konnect-mcp
    - /.well-known/oauth-protected-resource/konnect-mcp
    protocols:
    - http
    - https
    request_buffering: false
    response_buffering: false
    plugins:
    - name: ai-mcp-oauth2
      instance_name: konnect-mcp-oauth2
      tags:
      - secure-external-mcp-gateway-recipe
      config:
        resource: https://localhost:8443/konnect-mcp
        authorization_servers:
        - ${{ env "DECK_OAUTH_AUTH_SERVER" }}
        introspection_endpoint: ${{ env "DECK_OAUTH_INTROSPECTION_URL" }}
        client_id: ${{ env "DECK_OAUTH_CLIENT_ID" }}
        client_secret: ${{ env "DECK_OAUTH_CLIENT_SECRET" }}
        metadata_endpoint: /.well-known/oauth-protected-resource/konnect-mcp
        scopes_supported:
        - openid
        insecure_relaxed_audience_validation: true
        ssl_verify: true
        cache_introspection: true
        passthrough_credentials: false
        consumer_claim:
        - sub
        consumer_by:
        - username
        - custom_id
        consumer_optional: true
        consumer_groups_claim:
        - groups
        consumer_groups_optional: true
        credential_claim:
        - sub
    - name: ai-mcp-proxy
      instance_name: konnect-mcp-listener
      tags:
      - secure-external-mcp-gateway-recipe
      config:
        mode: passthrough-listener
        logging:
          log_payloads: true
          log_statistics: true
    - name: request-transformer-advanced
      instance_name: konnect-mcp-token-swap
      tags:
      - secure-external-mcp-gateway-recipe
      config:
        add:
          headers:
          - 'Authorization:Bearer ${{ env "DECK_KONNECT_MCP_TOKEN" }}'
    - name: cors
      instance_name: konnect-mcp-cors
      tags:
      - secure-external-mcp-gateway-recipe
      config:
        origins: ['*']
        methods: [GET, HEAD, PUT, PATCH, POST, DELETE, OPTIONS]
        credentials: false
        preflight_continue: false
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: secure-external-mcp-gateway-recipe
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

With the configuration applied, both external MCP endpoints are ready to accept connections. The verification path below uses [Insomnia](/insomnia/mcp-clients-in-insomnia/), Kong's MCP-aware API client, to exercise both patterns: GitHub MCP with passthrough auth and dual-header identity, and Konnect MCP with OAuth-driven token swap. Once verified, the same endpoints can be plugged into any MCP-compatible AI client.

{:.warning}
> Konnect's MCP server rejects HTTP-originated traffic, so this recipe targets Kong's local HTTPS listener at `https://localhost:8443`, which uses a self-signed certificate. On each MCP request you create in Insomnia, click **Manage Certificates** at the top of the request pane and toggle **SSL Certificate Validation** off under **Extra Options**. Scope this per-request, not globally.

### Verify GitHub MCP (passthrough + dual auth) with Insomnia

The GitHub MCP route demonstrates the passthrough pattern: GitHub issues the upstream OAuth token, Kong identifies the caller separately via Key Auth, and the AI MCP Proxy Plugin enforces tool-level ACLs.

1. **Create an MCP request.** In Insomnia, create a new request, select **MCP** as the request type, and enter the gateway URL:

    ```text
    https://localhost:8443/github-mcp
    ```
    {:.no-copy-code}

1. **Add the Kong Consumer key.** Open the **Headers** tab and add `apikey: dev-api-key` (use `admin-api-key` to test with the `admin` Consumer Group). This header coexists with the Bearer token Insomnia adds during OAuth: Kong's [Key Auth](/plugins/key-auth/) Plugin reads `apikey` while the upstream reads `Authorization: Bearer`.

1. **Configure OAuth on the request.** Open the **Auth** tab and select **OAuth 2.0** from the dropdown. Set **Grant Type** to **MCP Auth flow**. Enter the **Client ID** and **Client Secret** from your GitHub OAuth Application. Both are required because GitHub's OAuth Apps treat the client as confidential. Set **Scope** to `repo read:user read:org` (space-separated); GitHub issues tokens with no useful permissions when the authorization request omits scopes, and the GitHub MCP server then rejects tool calls with `insufficient scopes`. Set **State** to any value (for example, `recipe-test`). Insomnia uses these values when it runs the GitHub OAuth flow in the next step.

1. **Initiate the connection.** Insomnia sends the MCP `initialize` without a Bearer token. Kong's [Datakit](/plugins/datakit/) Plugin detects the missing `Authorization` header and returns `401` with `WWW-Authenticate: Bearer resource_metadata=...` pointing at `/.well-known/oauth-protected-resource/github-mcp`. Insomnia auto-discovers the PRM. The **Events** tab shows Insomnia's GET against the PRM endpoint and the rewritten response body:

    ```json
    {
      "resource": "https://localhost:8443/github-mcp",
      "authorization_servers": ["https://github.com/login/oauth"],
      "scopes_supported": ["repo", "gist", "notifications"]
    }
    ```
    {:.no-copy-code}

    The `resource` field reads `https://localhost:8443/github-mcp` (Kong's URL) rather than `api.githubcopilot.com/mcp` (GitHub's). The `authorization_servers` field still points at `https://github.com/login/oauth`. Kong's [Response Transformer Advanced](/plugins/response-transformer-advanced/) Plugin rewrote the resource field while preserving GitHub as the authorization server.

1. **Complete GitHub OAuth.** Insomnia opens your browser to GitHub's authorization endpoint. Sign in, approve the application, and Insomnia captures the redirect, exchanges the authorization code for an access token, and reconnects to the MCP endpoint. The reconnect now carries both `apikey: dev-api-key` (for Kong) and `Authorization: Bearer ghu_...` (for GitHub).

1. **List tools.** As `dev-api-key`, Insomnia lists six read-only tools: `search_repositories`, `get_file_contents`, `list_issues`, `list_pull_requests`, `search_users`, `search_code`. The five admin-only write tools (`create_issue`, `push_files`, `create_pull_request`, `merge_pull_request`, `create_repository`) are filtered out, along with every other GitHub MCP tool. The `default_acl` denies the `developer` Consumer Group on anything not explicitly allowed. Switching `apikey` to `admin-api-key` and reconnecting shows the full GitHub MCP tool catalog (70+).

1. **Call a permitted tool.** Invoke `search_repositories` with a query like `kong gateway language:go`. The call succeeds; the response body shows GitHub's search results, proxied through Kong using the Bearer token.

    The ACL is enforced server-side in the AI MCP Proxy Plugin, not by filtering the client's catalog alone. Kong evaluates every `tools/call` against the caller's Consumer Group before forwarding upstream, so a misbehaving client that bypasses the filtered catalog and crafts a raw JSON-RPC request for `push_files` (or any other denied tool) as `dev-api-key` would receive `INVALID_PARAMS (-32602)` with a `Tool 'push_files' is not available for consumer group 'developer'` message, and the request would never reach GitHub.

### Verify Konnect MCP (token swap) with Insomnia

The Konnect MCP route demonstrates the token-swap pattern: the user authenticates with the organization's IdP, Kong validates the token and maps the user to a Consumer, then the [Request Transformer Advanced](/plugins/request-transformer-advanced/) Plugin strips the user's token and injects the stored Konnect credential before forwarding upstream.

1. **Create a second MCP request** pointed at:

    ```text
    https://localhost:8443/konnect-mcp
    ```
    {:.no-copy-code}

1. **Configure OAuth on the request.** Open the **Auth** tab and select **OAuth 2.0** from the dropdown. Set **Grant Type** to **MCP Auth flow**. Enter the **Client ID** copied from the `MCP Client` SPA application in your IdP (Okta) or the `mcp-client` public client (Keycloak). Set **State** to any value (for example, `recipe-test`). Insomnia uses these values when it runs the PKCE flow in the next step.

1. **Initiate the connection.** Insomnia sends `initialize` without credentials. Kong's [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin returns `401` with `WWW-Authenticate` pointing at `/.well-known/oauth-protected-resource/konnect-mcp`. Insomnia fetches the PRM and discovers the configured IdP authorization server.

1. **Complete OAuth via your IdP.** Insomnia opens your browser to the IdP (Okta or Keycloak) authorization endpoint and runs the PKCE flow. Sign in and approve the application; Insomnia captures the redirect and obtains an access token issued by your IdP.

1. **Reconnect.** Insomnia sends the MCP `initialize` again with `Authorization: Bearer <idp-token>`. The AI MCP OAuth2 Plugin introspects the token, maps the `sub` claim to a Kong Consumer, and **strips** the user's `Authorization` header (`passthrough_credentials: false`). The Request Transformer Advanced Plugin then **adds** the stored Konnect credential from `DECK_KONNECT_MCP_TOKEN` into the now-empty `Authorization` header before the request reaches the regional Konnect MCP endpoint. The token swap is invisible from the Insomnia side. It shows up only in the upstream Konnect audit log and in the **Analytics** view on the `konnect-mcp-service` Service in Konnect, where you can confirm Kong forwarded the request authenticated as the stored Konnect identity, not the end user.

1. **List Konnect MCP tools.** Insomnia displays the tools exposed by the Konnect MCP server (Control Plane management, API exploration, and similar operations). Call a read-only tool such as the one that lists Control Planes; the response comes from Konnect, served under the stored credential's permissions.

1. **Verify the swap in Konnect Analytics.** Open the `konnect-mcp-service` Service in Konnect and filter the **Analytics** tab to recent traffic. The forwarded `Authorization` header on each upstream call carries the stored Konnect credential; the Consumer recorded against the request reflects the user identified from the IdP token. Same call, two different identity contexts: end-user identity is captured for audit, while the upstream auth uses a centrally rotated credential.

### Explore in Konnect

Open [Konnect](https://cloud.konghq.com/) and navigate to **API Gateway** → **Gateways** → **`secure-external-mcp-gateway-recipe`**. The recipe created the following resources on this Control Plane:

- **Gateway services**: `github-mcp-service`, `github-mcp-prm-service`, and `konnect-mcp-service`. Open each Service to see the attached Routes and Plugins.
  - **Routes** tab: the three Routes with their paths (`/github-mcp`, `/.well-known/oauth-protected-resource/github-mcp`, `/konnect-mcp`).
  - **Plugins** tab: Datakit, Key Auth, AI MCP Proxy, AI MCP OAuth2, Request Transformer Advanced, Response Transformer Advanced, and CORS, scoped per Route.
- **Consumers**: `admin-user` and `dev-user` with their Key Auth credentials. The **Consumer Groups** sub-page lists `admin` and `developer`.

The **Analytics** tab on `github-mcp-service` gives an at-a-glance view of GitHub MCP traffic, including request rates and latency. The same tab on `konnect-mcp-service` is where the token swap is visible: the upstream identity is the stored Konnect credential, while the Consumer attributed to the request is the IdP user. For a deeper dive into these analytics, plus platform-wide analytics across every Control Plane, head to the **Observability** L1 menu in Konnect.

## Variations and next steps

- **Connect from an AI harness.** Both routes work in any MCP-compatible client (Claude Code, VS Code, Claude Desktop, and others). Each client handles OAuth differently, so follow the client's documentation for adding a remote MCP server. Before connecting, register that client's OAuth redirect URI on the GitHub OAuth Application and on your IdP `MCP Client` application alongside Insomnia's `https://app.insomnia.rest/oauth/redirect`. For the GitHub route, the client must accept both a **Client ID** and a **Client Secret** (GitHub OAuth Apps require the secret at token exchange) and must also send `apikey: <admin-api-key|dev-api-key>` so Kong can identify the Consumer for ACL evaluation.
- **Add more GitHub MCP tools to the ACLs.** The recipe defines ACLs for 11 of GitHub's 70+
  tools. To restrict additional tools, add more entries to the `tools` list in the AI MCP Proxy
  Plugin config with the appropriate `acl.allow` groups. Any tool not explicitly listed falls
  under the `default_acl` (denied for developers, allowed for admins).

- **Enforce tool-level ACL on the Konnect MCP route.** The token-swap chain already maps an
  IdP `groups` claim to Kong Consumer Groups via the AI MCP OAuth2 Plugin
  (`consumer_groups_claim: [groups]`). To restrict which Konnect MCP tools each group can call,
  pre-create the Consumer Groups and add `acl.allow` rules under the AI MCP Proxy Plugin on the
  `konnect-mcp` route, mirroring the GitHub MCP route. The
  [Secure Internal MCP Gateway](/cookbooks/secure-internal-mcp-gateway/) recipe shows the full
  IdP-claim-to-ACL pattern, including the Okta and Keycloak setup for issuing the `groups` claim.

- **Proxy other external MCP servers.** The passthrough pattern (Datakit + Key Auth + AI MCP
  Proxy) works for any external MCP server that uses OAuth. Adapt the PRM Service to point at
  the provider's PRM endpoint, update the Response Transformer Advanced Plugin to rewrite the
  resource field, and create a GitHub OAuth app (or equivalent) for the provider.

- **Add OIDC token validation in front of passthrough.** For external MCP servers whose auth
  providers expose public JWKS endpoints or support introspection (for example, services using
  Okta or Keycloak as their auth server), attach the [OpenID Connect](/plugins/openid-connect/)
  Plugin to validate tokens at Kong before forwarding. This adds a security layer beyond simple
  passthrough; Kong can reject expired or invalid tokens without hitting the upstream.

- **Combine with internal MCP.** Use the [Secure Internal MCP Gateway](/cookbooks/secure-internal-mcp-gateway/)
  recipe alongside this one to expose both internal and external MCP tools through a single
  Kong deployment. Internal tools use `conversion-only` + `listener` mode with OAuth; external
  tools use `passthrough-listener` mode. Both patterns can share Consumers and Consumer Groups
  for unified access control.

## Cleanup

The recipe's `select_tags` and kongctl namespace scoped all resources, so this teardown removes
only this recipe's configuration. Tear down the local Data Plane and delete the Control Plane
from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='secure-external-mcp-gateway-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```
