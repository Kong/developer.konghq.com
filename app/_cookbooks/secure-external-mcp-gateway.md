---
title: Secure External MCP Gateway
description: "Proxy third-party MCP servers (GitHub, Konnect) through {{site.base_gateway}} with centralized access control, observability, and tool-level ACLs."
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
    hint: "Create a GitHub OAuth Application with a redirect URI of http://localhost:8085/callback. See the GitHub section in Prerequisites."
  - name: Identity Provider (Okta or Keycloak)
    env_vars: [DECK_OAUTH_AUTH_SERVER, DECK_OAUTH_INTROSPECTION_URL, DECK_OAUTH_CLIENT_ID, DECK_OAUTH_CLIENT_SECRET]
    hint: "Required for the Konnect MCP pattern. Create an OAuth application for Kong. See the Identity Provider section in Prerequisites."

hint: "Requires a GitHub OAuth application, an identity provider (Okta or Keycloak), a Konnect service account token, and Insomnia 12+ for testing."

prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"      
      content: |
        This tutorial uses {{site.konnect_product_name}}. You will provision a recipe-scoped Control Plane and local Data Plane via the [quickstart script](https://get.konghq.com/quickstart).

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped control plane name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='secure-external-mcp-gateway-recipe'
           curl -Ls https://get.konghq.com/quickstart | bash -s -- -k $KONNECT_TOKEN --deck-output
           ```

           This provisions a Konnect Control Plane named `secure-external-mcp-gateway-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars. Paste those into your shell when prompted.
    - title: kongctl + decK
      content: |
        This tutorial uses [kongctl](/kongctl/) and [decK](/deck/) to manage Kong configuration.

        1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
        2. Install **decK** version 1.43 or later from [docs.konghq.com/deck](https://docs.konghq.com/deck/).

        Verify both are installed:

        ```bash
        kongctl version
        deck version
        ```
    - title: GitHub OAuth Application
      icon_url: /assets/icons/github.svg
      content: |
        Since GitHub's authorization server does not support Dynamic Client Registration (DCR), you
        must create an OAuth application manually to represent your MCP client.

        1. Go to [GitHub Settings > Developer settings > OAuth Apps](https://github.com/settings/developers).
        2. Click **New OAuth App**.
        3. Fill in the required fields:
           - **Application name:** `Kong MCP Client` (or any descriptive name)
           - **Homepage URL:** `http://localhost:8000` (required by GitHub but not used in the OAuth flow)
           - **Authorization callback URL:** `http://localhost:8085/callback`
        4. Click **Register application**.
        5. Note the **Client ID**. This is your `GITHUB_OAUTH_CLIENT_ID` for the demo script.

        {:.info}
        > GitHub OAuth apps can only have **one** callback URL. If you use multiple MCP clients with different callback URLs, create a separate OAuth app for each.
    - title: Identity Provider
      content: |
        The Konnect MCP pattern uses the [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin with your organization's IdP. This requires the same IdP setup as the [Secure Internal MCP Gateway](/cookbooks/secure-internal-mcp-gateway/) recipe. If you've already completed that setup, you can reuse the same IdP applications.

        {% navtabs "Identity Provider" %}
        {% tab Okta %}

        Create two Okta applications as described in the [Secure Internal MCP Gateway prerequisites](/cookbooks/secure-internal-mcp-gateway/#identity-provider):

        1. **{{site.base_gateway}} application** (API Services), for token introspection.
        2. **MCP Client application** (SPA), for the OAuth flow.

        Note your **authorization server URL** and **introspection endpoint**, then export the values:

        ```bash
        export DECK_OAUTH_AUTH_SERVER='https://your-org.okta.com/oauth2/default'
        export DECK_OAUTH_INTROSPECTION_URL='https://your-org.okta.com/oauth2/default/v1/introspect'
        export DECK_OAUTH_CLIENT_ID='your-kong-client-id'
        export DECK_OAUTH_CLIENT_SECRET='your-kong-client-secret'
        ```

        {% endtab %}
        {% tab Keycloak %}

        Create a Keycloak realm and two clients as described in the [Secure Internal MCP Gateway prerequisites](/cookbooks/secure-internal-mcp-gateway/#identity-provider):

        1. **{{site.base_gateway}} client** (Confidential), for token introspection.
        2. **MCP Client** (Public), for the OAuth flow.

        Note your **realm URL** and **introspection endpoint**, then export the values:

        ```bash
        export DECK_OAUTH_AUTH_SERVER='https://your-keycloak-host/realms/mcp-demo'
        export DECK_OAUTH_INTROSPECTION_URL='https://your-keycloak-host/realms/mcp-demo/protocol/openid-connect/token/introspect'
        export DECK_OAUTH_CLIENT_ID='kong-mcp-gateway'
        export DECK_OAUTH_CLIENT_SECRET='your-kong-client-secret'
        ```

        {% endtab %}
        {% endnavtabs %}
    - title: Konnect Service Account Token
      content: |
        The Konnect MCP pattern requires a Service Account Token (SAT) or Personal Access Token (PAT) for authenticating to the Konnect MCP server. Kong stores this token and injects it into requests after validating the user's organizational identity.

        1. In Konnect, go to **Organization > System Accounts** (for SAT) or use your existing PAT.
        2. Create a token with appropriate permissions for the Konnect MCP server.
        3. Export it alongside the recipe's local Kong proxy URLs:

        ```bash
        export DECK_KONNECT_MCP_SAT='Bearer spat_YOUR_TOKEN'
        export DECK_GATEWAY_URL='http://localhost:8000'
        export DECK_KONNECT_MCP_RESOURCE_URL='http://localhost:8000/konnect-mcp'
        ```
    - title: Insomnia 12+
      content: |
        This recipe verifies the gateway using [Insomnia](https://insomnia.rest/), Kong's MCP-aware API client. Insomnia speaks the MCP protocol natively and handles the full OAuth 2.1 + PKCE dance, including Protected Resource Metadata (PRM) discovery.

        1. Install **Insomnia** from [insomnia.rest/download](https://insomnia.rest/download).
        1. Verify the version is 12.0 or later (Help → About on macOS, equivalent on other platforms).

        See [MCP clients in Insomnia](/insomnia/mcp-clients-in-insomnia/) for an overview of MCP server testing in Insomnia.

overview: |
  This recipe is the companion to [Secure Internal MCP Gateway](/cookbooks/secure-internal-mcp-gateway/),
  which covers proxying MCP servers that your organization hosts and controls. This recipe covers
  the other side: proxying **external** (third-party) MCP servers, such as GitHub, Slack,
  or Figma that manage their own authentication and issue their own tokens.

  There are broadly two types of MCP servers you can proxy through Kong:

  - **Internal MCP servers** are hosted within your trust boundary. You control both the server
    and the auth. Kong can handle authentication centrally and map users to Consumers for ACLs.
    See [Secure Internal MCP Gateway](/cookbooks/secure-internal-mcp-gateway/).
  - **External MCP servers** are third-party services. They issue their own tokens (often opaque),
    manage their own OAuth flows, and may not support standard token introspection. Kong acts as
    a proxy with observability and access control, but the upstream auth belongs to the external
    provider.

  This recipe demonstrates two patterns for proxying external MCP servers, using GitHub MCP and
  {{site.konnect_product_name}} MCP as examples:

  | Pattern | Server | How it works |
  |---------|--------|-------------|
  | **Passthrough** | GitHub MCP | User authenticates directly with GitHub. Kong passes the token through to GitHub and uses a separate Key Auth layer for Consumer identity and ACLs. |
  | **Token swap** | Konnect MCP | User authenticates with the organization's IdP (Okta/Keycloak). Kong validates the token, maps the user to a Consumer, then swaps the token for a stored Konnect Service Account Token before forwarding. |
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
    K->>K: key-auth — resolve Kong Consumer
    K->>K: ai-mcp-proxy (passthrough-listener) — evaluate tool ACLs, log
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
    K->>IdP: ai-mcp-oauth2 — introspect token
    activate IdP
    IdP-->>K: Claims (sub → Kong Consumer)
    deactivate IdP
    K->>K: Strip user token, inject stored SAT (request-transformer-advanced)
    K->>KM: Forward request with SAT
    activate KM
    KM-->>K: MCP response
    deactivate KM
    K-->>C: MCP response (logged via ai-mcp-proxy)
    deactivate K
{% endmermaid %}
<!-- vale on -->

<!-- vale off -->
{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibility
    key: responsibility
rows:
  - component: GitHub OAuth
    responsibility: Issues tokens for GitHub API access; MCP clients authenticate directly
  - component: Identity Provider (Okta / Keycloak)
    responsibility: Issues tokens for organizational identity; used by Konnect MCP pattern
  - component: Kong [Datakit](/plugins/datakit/) Plugin
    responsibility: Checks for Authorization header; returns 401 + PRM pointer for unauthenticated requests
  - component: Kong [Key Auth](/plugins/key-auth/) Plugin
    responsibility: Resolves Kong Consumer from apikey header for GitHub MCP ACL evaluation
  - component: Kong [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin
    responsibility: MCP-native OAuth for Konnect MCP; PRM, introspection, Consumer mapping
  - component: Kong [AI MCP Proxy](/plugins/ai-mcp-proxy/) Plugin (`passthrough-listener`)
    responsibility: Proxies MCP traffic to upstream servers; enforces tool-level ACLs; provides observability
  - component: Kong [Response Transformer Advanced](/plugins/response-transformer-advanced/) Plugin
    responsibility: Rewrites GitHub's PRM resource field to point at Kong
  - component: Kong [Request Transformer Advanced](/plugins/request-transformer-advanced/) Plugin
    responsibility: Swaps user token for stored Konnect SAT
{% endtable %}
<!-- vale on -->

### ACL matrix (GitHub MCP)

The GitHub MCP server exposes 70+ tools. This recipe defines ACLs for a representative subset,
with a default deny for the `developer` group on unlisted tools:

<!-- vale off -->
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
    type: read
  - tool: "`get_file_contents`"
    admin: "yes"
    developer: "yes"
    type: read
  - tool: "`list_issues`"
    admin: "yes"
    developer: "yes"
    type: read
  - tool: "`list_pull_requests`"
    admin: "yes"
    developer: "yes"
    type: read
  - tool: "`search_users`"
    admin: "yes"
    developer: "yes"
    type: read
  - tool: "`search_code`"
    admin: "yes"
    developer: "yes"
    type: read
  - tool: "`create_issue`"
    admin: "yes"
    developer: "no"
    type: write
  - tool: "`push_files`"
    admin: "yes"
    developer: "no"
    type: write
  - tool: "`create_pull_request`"
    admin: "yes"
    developer: "no"
    type: write
  - tool: "`merge_pull_request`"
    admin: "yes"
    developer: "no"
    type: write
  - tool: "`create_repository`"
    admin: "yes"
    developer: "no"
    type: write
  - tool: "*(all other tools)*"
    admin: "yes"
    developer: "no"
    type: default deny
{% endtable %}
<!-- vale on -->

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
7. For the Konnect MCP pattern, the [Request Transformer Advanced](/plugins/request-transformer-advanced/) Plugin strips the user's token and injects a stored Service Account Token before forwarding.
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
            resource_metadata="http://localhost:8000/.well-known/oauth-protected-resource/github-mcp",
            error="invalid_token"
          BODY: '{"message": "Unauthorized"}'
      - name: UNAUTH_EXIT
        type: exit
        status: 401
        inputs:
          body: UNAUTH_RESPONSE.BODY
          headers: UNAUTH_RESPONSE
```
{:.no-copy-code}

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
        - "resource:http://localhost:8000/github-mcp"
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
  "resource": "http://localhost:8000/github-mcp",
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

### GitHub MCP: Tool-level ACLs on passthrough-listener

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

1. The [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin authenticates the user via the organization's IdP (Okta/Keycloak),
   validates the token through introspection, and maps claims to Kong Consumers
2. The [Request Transformer Advanced](/plugins/request-transformer-advanced/) Plugin strips the user's token and injects a stored Konnect SAT
3. The [AI MCP Proxy](/plugins/ai-mcp-proxy/) Plugin (passthrough-listener) provides observability

This pattern means users authenticate with their organizational identity, but the Konnect API
call uses a shared service account. The SAT is stored securely, either in a decK env var
(for development) or in a Kong vault backend (for production).

{:.info}
> In production, store credentials in [Kong Vaults](/gateway/entities/vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. Kong supports HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the Konnect Config Store.

## Apply the Kong configuration

This section configures the Control Plane in two parts. First, adopt the quickstart Control Plane into a kongctl namespace so the apply commands below can manage it. The recipe's `select_tags` and the `secure-external-mcp-gateway-recipe` namespace scope every resource so teardown removes only this recipe's configuration.

```bash
kongctl adopt control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the Control Plane.

The following configuration creates two external MCP proxy setups: GitHub MCP with passthrough auth and tool-level ACLs, and Konnect MCP with OAuth token swap. Two Consumer Groups (`admin` and `developer`) control GitHub tool access.

The `DECK_OAUTH_*`, `DECK_GATEWAY_URL`, `DECK_KONNECT_MCP_SAT`, and `DECK_KONNECT_MCP_RESOURCE_URL` environment variables were exported in the prerequisites. Apply the configuration:

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
              resource_metadata="${{ env "DECK_GATEWAY_URL" }}/.well-known/oauth-protected-resource/github-mcp",
              error="invalid_token"
            BODY: '{"message": "Unauthorized"}'
        - name: UNAUTH_EXIT
          type: exit
          status: 401
          inputs:
            body: UNAUTH_RESPONSE.BODY
            headers: UNAUTH_RESPONSE
    - name: key-auth
      tags:
      - secure-external-mcp-gateway-recipe
      config:
        key_names:
        - apikey
        hide_credentials: true
    - name: ai-mcp-proxy
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
      tags:
      - secure-external-mcp-gateway-recipe
      config:
        replace:
          json:
          - "resource:${{ env \"DECK_GATEWAY_URL\" }}/github-mcp"
          json_types:
          - string
- name: konnect-mcp-service
  host: us.mcp.konghq.com
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
      tags:
      - secure-external-mcp-gateway-recipe
      config:
        resource: ${{ env "DECK_KONNECT_MCP_RESOURCE_URL" }}
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
      tags:
      - secure-external-mcp-gateway-recipe
      config:
        mode: passthrough-listener
        logging:
          log_payloads: true
          log_statistics: true
    - name: request-transformer-advanced
      tags:
      - secure-external-mcp-gateway-recipe
      config:
        add:
          headers:
          - 'Authorization:${{ env "DECK_KONNECT_MCP_SAT" }}'
        remove:
          headers:
          - X-Forwarded-Proto
    - name: cors
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
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

## Try it out

With the configuration applied, both external MCP endpoints are ready to accept connections. The verification path below uses [Insomnia](/insomnia/mcp-clients-in-insomnia/), Kong's MCP-aware API client, to exercise both patterns: GitHub MCP with passthrough auth and dual-header identity, and Konnect MCP with OAuth-driven token swap. Once verified, the same endpoints can be plugged into any MCP-compatible AI client.

### Verify GitHub MCP (passthrough + dual auth) with Insomnia

The GitHub MCP route demonstrates the passthrough pattern: GitHub issues the upstream OAuth token, Kong identifies the caller separately via Key Auth, and the AI MCP Proxy Plugin enforces tool-level ACLs.

1. **Create an MCP request.** In Insomnia, create a new request, select **MCP** as the request type, and enter the gateway URL:

    ```text
    http://localhost:8000/github-mcp
    ```
    {:.no-copy-code}

1. **Add the Kong Consumer key.** Open the **Headers** tab and add `apikey: dev-api-key` (use `admin-api-key` to test with the admin Consumer Group). This header coexists with the Bearer token Insomnia adds during OAuth — Kong's [Key Auth](/plugins/key-auth/) Plugin reads `apikey` while the upstream reads `Authorization: Bearer`.

1. **Initiate the connection.** Insomnia sends the MCP `initialize` without a Bearer token. Kong's [Datakit](/plugins/datakit/) Plugin detects the missing `Authorization` header and returns `401` with `WWW-Authenticate: Bearer resource_metadata=...` pointing at `/.well-known/oauth-protected-resource/github-mcp`. Insomnia auto-discovers the PRM. Inspecting the **Events** tab shows Insomnia's GET against the PRM endpoint and the response body — note that the `resource` field reads `http://localhost:8000/github-mcp` (Kong's URL) rather than `api.githubcopilot.com/mcp` (GitHub's). The `authorization_servers` field still points at `https://github.com/login/oauth`. Kong's [Response Transformer Advanced](/plugins/response-transformer-advanced/) Plugin rewrote the resource field while preserving GitHub as the authorization server.

1. **Complete GitHub OAuth.** Insomnia opens your browser to GitHub's authorization endpoint. Sign in, approve the application, and Insomnia captures the redirect, exchanges the authorization code for an access token, and reconnects to the MCP endpoint. The reconnect now carries both `apikey: dev-api-key` (for Kong) and `Authorization: Bearer ghu_...` (for GitHub).

1. **List tools.** As `dev-api-key`, Insomnia lists six read-only tools: `search_repositories`, `get_file_contents`, `list_issues`, `list_pull_requests`, `search_users`, `search_code`. The five admin-only write tools (`create_issue`, `push_files`, `create_pull_request`, `merge_pull_request`, `create_repository`) are filtered out, along with every other GitHub MCP tool — the `default_acl` denies the `developer` Consumer Group on anything not explicitly allowed. Switching `apikey` to `admin-api-key` and reconnecting shows the full GitHub MCP tool catalog (70+).

1. **Call a permitted tool.** Invoke `search_repositories` with a query like `kong gateway language:go`. The call succeeds; the response body shows GitHub's search results, proxied through Kong using the Bearer token.

1. **Call a restricted tool.** Manually invoke `push_files` (the tool name is hidden from the catalog but can be entered directly to simulate a misbehaving client). Kong returns `INVALID_PARAMS (-32602)` with a body explaining the tool is not available for the `developer` Consumer Group. The request never reached GitHub — Kong's ACL evaluated and denied it locally.

### Verify Konnect MCP (token swap) with Insomnia

The Konnect MCP route demonstrates the token-swap pattern: the user authenticates with the organization's IdP, Kong validates the token and maps the user to a Consumer, then the [Request Transformer Advanced](/plugins/request-transformer-advanced/) Plugin strips the user's token and injects the stored Konnect Service Account Token before forwarding upstream.

1. **Create a second MCP request** pointed at:

    ```text
    http://localhost:8000/konnect-mcp
    ```
    {:.no-copy-code}

1. **Initiate the connection.** Insomnia sends `initialize` without credentials. Kong's [AI MCP OAuth2](/plugins/ai-mcp-oauth2/) Plugin returns `401` with `WWW-Authenticate` pointing at `/.well-known/oauth-protected-resource/konnect-mcp`. Insomnia fetches the PRM and discovers the configured IdP authorization server.

1. **Complete OAuth via your IdP.** Insomnia opens your browser to the IdP (Okta or Keycloak) authorization endpoint and runs the PKCE flow. Sign in and approve the application; Insomnia captures the redirect and obtains an access token issued by your IdP.

1. **Reconnect.** Insomnia sends the MCP `initialize` again with `Authorization: Bearer <idp-token>`. The AI MCP OAuth2 Plugin introspects the token, maps the `sub` claim to a Kong Consumer, and clears authorization for the request to proceed. The Request Transformer Advanced Plugin then **replaces** the user's `Authorization` header with the stored `Bearer spat_...` SAT before the request reaches `us.mcp.konghq.com`. The token swap is invisible from the Insomnia side — it shows up only in the upstream Konnect audit log and in the **Analytics** view on the `konnect-mcp-service` Service in Konnect, where you can confirm Kong forwarded the request authenticated as the service account, not the user.

1. **List Konnect MCP tools.** Insomnia displays the tools exposed by the Konnect MCP server (control plane management, API exploration, and similar operations). Call a read-only tool such as the one that lists control planes; the response comes from Konnect, served under the SAT's permissions.

1. **Verify the swap in Konnect Analytics.** Open the `konnect-mcp-service` Service in Konnect and filter the **Analytics** tab to recent traffic. The forwarded `Authorization` header on each upstream call carries the SAT; the Consumer recorded against the request reflects the user identified from the IdP token. Same call, two different identity contexts: end-user identity is captured for audit, while the upstream auth uses a centrally rotated service account.

### Connect a real MCP client

Both routes are usable from any MCP-compatible AI client. Each client handles OAuth differently — follow the upstream documentation for the client's configuration mechanics. The values below cover the gateway-specific bits.

<!-- vale off -->
{% table %}
columns:
  - title: Client
    key: client
  - title: Documentation
    key: documentation
  - title: GitHub MCP route
    key: github_route
  - title: Konnect MCP route
    key: konnect_route
rows:
  - client: Claude Code
    documentation: "[code.claude.com/docs/en/mcp](https://code.claude.com/docs/en/mcp)"
    github_route: '`claude mcp add --transport http github-mcp http://localhost:8000/github-mcp --header "apikey: dev-api-key"`'
    konnect_route: "`claude mcp add --transport http konnect-mcp http://localhost:8000/konnect-mcp`"
  - client: VS Code
    documentation: "[vscode-docs/copilot/reference/mcp-configuration.md](https://github.com/microsoft/vscode-docs/blob/main/docs/copilot/reference/mcp-configuration.md)"
    github_route: "Add `\"github-mcp\": {\"type\": \"http\", \"url\": \"http://localhost:8000/github-mcp\", \"headers\": {\"apikey\": \"dev-api-key\"}}` to `.vscode/mcp.json`"
    konnect_route: "Add `\"konnect-mcp\": {\"type\": \"http\", \"url\": \"http://localhost:8000/konnect-mcp\"}` to `.vscode/mcp.json`"
  - client: Claude Desktop
    documentation: "[Get started with custom connectors using remote MCP](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp)"
    github_route: "Customize → Connectors → Add custom connector. The gateway must be reachable from Anthropic's IPs, so this client only works once Kong is deployed publicly; `http://localhost:8000` is not reachable from Claude Desktop."
    konnect_route: Same, public deployment only.
{% endtable %}
<!-- vale on -->

For the GitHub route, the additional `apikey` header is what tells Kong which Consumer the call belongs to; the Bearer token continues to authenticate to GitHub upstream. Once connected, ask the agent a permitted task (`Search GitHub for repositories matching kong gateway language:go`) and a restricted one (`Push a file to test/test`). The first succeeds; the second is reported as denied because Kong filters the tool from the catalog or returns an ACL error on the call.

### Explore in Konnect

Open [Konnect](https://cloud.konghq.com/) and navigate to **API Gateway > Gateways > `secure-external-mcp-gateway-recipe`** to inspect the deployed configuration:

- **Gateway Services** lists `github-mcp-service`, `github-mcp-prm-service`, and `konnect-mcp-service`. Open each Service to see the attached Routes and Plugins.
- **Routes** shows the three Routes with their paths (`/github-mcp`, `/.well-known/oauth-protected-resource/github-mcp`, `/konnect-mcp`).
- **Plugins** lists the `datakit`, `key-auth`, `ai-mcp-proxy`, `ai-mcp-oauth2`, `request-transformer-advanced`, `response-transformer-advanced`, and `cors` Plugins, scoped per Route.
- **Consumers** shows `admin-user` and `dev-user` with their Key Auth credentials, and **Consumer Groups** lists `admin` and `developer`.
- The **Analytics** tab on `github-mcp-service` gives an at-a-glance view of GitHub MCP traffic, including request rates and latency. The same tab on `konnect-mcp-service` is where the token swap is visible — the upstream identity is the SAT, while the Consumer attributed to the request is the IdP user.
- For deeper analytics across all three Services, open the **Observability** menu in the Konnect left navigation to see traffic, error rates, and latency dashboards over time.

## Cleanup

The recipe's `select_tags` and kongctl namespace scoped all resources, so this teardown removes
only this recipe's configuration. Tear down the local data plane and delete the control plane
from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='secure-external-mcp-gateway-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```

## Variations and next steps

- **Adding more GitHub MCP tools to ACLs.** The recipe defines ACLs for 11 of GitHub's 70+
  tools. To restrict additional tools, add more entries to the `tools` list in the ai-mcp-proxy
  config with the appropriate `acl.allow` groups. Any tool not explicitly listed falls under the
  `default_acl` (denied for developers, allowed for admins).

- **Proxying other external MCP servers.** The passthrough pattern (Datakit + Key Auth +
  AI MCP Proxy) works for any external MCP server that uses OAuth. Adapt the PRM Service to
  point at the provider's PRM endpoint, update the Response Transformer Advanced Plugin to rewrite
  the resource field, and create a GitHub OAuth app (or equivalent) for the provider.

- **OIDC token validation.** For external MCP servers whose auth providers expose public JWKS
  endpoints or support introspection (e.g., services using Okta or Keycloak as their auth
  server), you can add the [OpenID Connect](/plugins/openid-connect/) Plugin to validate tokens
  at Kong before forwarding. This adds a security layer beyond simple passthrough. Kong can
  reject expired or invalid tokens without hitting the upstream.

- **Combining with internal MCP.** Use the [Secure Internal MCP Gateway](/cookbooks/secure-internal-mcp-gateway/)
  recipe alongside this one to expose both internal and external MCP tools through a single
  Kong deployment. Internal tools use `conversion-only` + `listener` mode with OAuth; external
  tools use `passthrough-listener` mode. Both patterns can share Consumers and Consumer Groups
  for unified access control.
