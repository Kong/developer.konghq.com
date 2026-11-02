---
title: Secure External MCP Gateway
description: Proxy third-party MCP servers (GitHub, {{site.konnect_short_name}}) through {{site.ai_gateway_name}} with AI Consumer identification, IdP-based identity mapping, and tool-level ACLs.
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
  ai-gateway: '2.0'
categories:
  - mcp
  - access-control
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - key-auth
  - openid-connect
  - request-transformer-advanced
  - ai-mcp-server
requires_embeddings: false
extra_services:
  - name: GitHub OAuth Application
    env_vars: [GITHUB_OAUTH_CLIENT_ID]
    hint: "Create a GitHub OAuth Application with a redirect URI of https://app.insomnia.rest/oauth/redirect (Insomnia 12+'s built-in OAuth callback; use the redirect URI of whichever MCP client you'll test with). See the GitHub section in Prerequisites."
  - name: Identity Provider (Okta or Keycloak)
    env_vars: [DECK_OAUTH_AUTH_SERVER, DECK_OAUTH_INTROSPECTION_URL, DECK_OAUTH_CLIENT_ID, DECK_OAUTH_CLIENT_SECRET]
    hint: "Required for the {{site.konnect_short_name}} MCP pattern. Create an OAuth application for Kong. See the Identity Provider section in Prerequisites."

hint: "Requires a GitHub OAuth application, an identity provider (Okta or Keycloak), a {{site.konnect_short_name}} personal access token, and Insomnia 12+ for testing."

prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: Kong Konnect
      content: |
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped {{site.ai_gateway}} and local data plane.

        1. Create a new personal access token by opening the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. You reuse the same token later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Export the upstream credential for the {{site.konnect_short_name}} MCP token-swap demo, as the full header string the recipe adds to every proxied request. The {{site.konnect_short_name}} MCP server accepts either a PAT or a Service Account Token (SAT); reusing your PAT here keeps the recipe to a single {{site.konnect_short_name}} credential:

           ```bash
           export DECK_KONNECT_MCP_TOKEN="Authorization:Bearer ${KONNECT_TOKEN}"
           ```

           {:.warning}
           > This reuses your PAT as the upstream credential so the demo only needs one {{site.konnect_short_name}} token. In production, generate a **System Account Token** with least-privilege permissions in **Organization > System Accounts** and store it in an [AI Vault](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references. PATs inherit the creator's full role and are tied to an individual user, which is unsuitable for a shared, audited service-account credential.

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='secure-external-mcp-gateway-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           The script provisions an {{site.ai_gateway}} named `secure-external-mcp-gateway-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: GitHub OAuth Application
      icon_url: /assets/icons/github.svg
      content: |
        GitHub's authorization server doesn't support Dynamic Client Registration (DCR), so you must create an OAuth application manually to represent your MCP client.

        1. Go to [GitHub Settings > Developer settings > OAuth Apps](https://github.com/settings/developers).
        1. Click **New OAuth App**.
        1. Fill in the required fields:
           - **Application name:** `Kong MCP Client` (or any descriptive name)
           - **Homepage URL:** `https://localhost:8443` (required by GitHub but not used in the OAuth flow)
           - **Authorization callback URL:** `https://app.insomnia.rest/oauth/redirect`. This URL is Insomnia 12+'s built-in OAuth callback. To use a different MCP client, register a separate OAuth app with that client's callback URL.
        1. Click **Register application**.
        1. On the new application's page, click **Generate a new client secret** and copy the value immediately (GitHub only shows it once).
        1. Note both the **Client ID** and the **Client Secret**. MCP clients prompt for both values when they start the GitHub OAuth flow; the recipe doesn't export them as environment variables.

        {:.warning}
        > GitHub OAuth Apps require the Client Secret at the token-exchange step. There is no public-client or PKCE-only flow. Omitting the secret causes the OAuth dance to fail with `incorrect_client_credentials`. Treat the secret as sensitive: it grants any holder the ability to mint tokens on behalf of this OAuth App.

        {:.info}
        > GitHub OAuth apps can only have **one** callback URL. If you use multiple MCP clients with different callback URLs, create a separate OAuth app for each.
    - title: Identity Provider
      content: |
        The {{site.konnect_short_name}} MCP route authenticates callers against your organization's OAuth 2.1 identity provider using an [OpenID Connect](/ai-gateway/openid-connect/) AI Auth Strategy. This recipe shows setup steps for Okta and Keycloak, both of which expose an RFC 7662 token introspection endpoint. Other IdPs (Microsoft Entra ID, Auth0, AWS Cognito, Google) work too. They expose a JWKS endpoint instead, which an OpenID Connect AI Auth Strategy validates locally without an introspection call. Select your IdP below and follow the setup steps.

        {% navtabs "Identity Provider" %}
        {% tab Okta %}

        You need an Okta organization with admin access. The steps below create two Okta applications, set up a test user (new or existing), and export Kong's introspection credentials.

        **Create the Kong MCP Gateway application**

        This confidential client represents Kong as the resource server. Kong uses its credentials to call Okta's token introspection endpoint.

        1. In the Okta Admin Console, go to **Applications → Create App Integration**.
        1. Select **API Services** (machine-to-machine).
        1. Name it `Kong MCP Gateway`.
        1. From the **General** tab, copy the **Client ID** and **Client Secret** under **Client Credentials**. Export these as `DECK_OAUTH_CLIENT_ID` and `DECK_OAUTH_CLIENT_SECRET` in the final step.

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

        **Set up a test user**

        The {{site.konnect_short_name}} MCP route authenticates any valid IdP user and forwards upstream as a stored service account, so a single user account is enough to run the recipe. Group membership isn't required.

        1. Go to **Directory → People** and either add a new person (for example, `mcp-test-user@example.com`) or pick an existing user. Make sure the user has a password set and can sign in.
        1. Open the `MCP Client` application, click the **Assignments** tab, and assign this user. Without this assignment, Okta blocks the OAuth flow at sign-in.

        **Export Kong's Okta endpoints and credentials**

        Export the authorization server URL, the introspection endpoint, and the **Kong MCP Gateway** application's Client ID and Secret. You don't export the MCP Client (SPA) Client ID here. The MCP client itself uses it at flow time.

        ```bash
        export DECK_OAUTH_AUTH_SERVER='https://your-org.okta.com/oauth2/default'
        export DECK_OAUTH_INTROSPECTION_URL='https://your-org.okta.com/oauth2/default/v1/introspect'
        export DECK_OAUTH_CLIENT_ID='your-kong-gateway-client-id'
        export DECK_OAUTH_CLIENT_SECRET='your-kong-gateway-client-secret'
        ```

        {% endtab %}
        {% tab Keycloak %}

        You need a Keycloak instance with admin access. The steps below create a realm and two clients, set up a test user (new or existing), and export Kong's introspection credentials.

        **Create a realm**

        In the Keycloak Admin Console, create a new realm (for example, `mcp-demo`), or use an existing one.

        **Create the Kong MCP Gateway client**

        This confidential client represents Kong as the resource server. Kong uses its credentials to call Keycloak's token introspection endpoint.

        1. Go to **Clients → Create client**.
        1. Set **Client ID** to `kong-mcp-gateway`.
        1. Set **Client authentication** to **On** (confidential client).
        1. Enable **Service accounts roles**.
        1. From the **Credentials** tab, copy the **Client Secret**. Export the Client ID (`kong-mcp-gateway`) as `DECK_OAUTH_CLIENT_ID` and this secret as `DECK_OAUTH_CLIENT_SECRET` in the final step.

        **Create the MCP Client**

        This public client represents the MCP client (Insomnia, Claude Code, VS Code, or any MCP-compatible tool). Public clients use Authorization Code + PKCE without a client secret.

        1. Go to **Clients → Create client**.
        1. Set **Client ID** to `mcp-client`.
        1. Set **Client authentication** to **Off** (public client).
        1. Set **Valid redirect URIs** to `https://app.insomnia.rest/oauth/redirect`. This URL is Insomnia 12+'s built-in OAuth callback. To use a different MCP client later, add that client's redirect URI here too, as described in [Variations and next steps](#variations-and-next-steps).
        1. Enable **Standard flow** (Authorization Code). Keycloak enforces PKCE for public clients automatically.
        1. Note the **Client ID** (`mcp-client`) for use in your MCP client. Insomnia and other MCP clients prompt for this value when they start the OAuth flow; the recipe doesn't export it as an environment variable.

        **Set up a test user**

        The {{site.konnect_short_name}} MCP route authenticates any valid IdP user and forwards upstream as a stored service account, so a single user account is enough to run the recipe. Group membership isn't required.

        1. Go to **Users** and either add a new user (for example, `mcp-test-user`) or pick an existing one. On the **Credentials** tab, set a password and clear **Temporary** so the user can sign in directly.

        **Export Kong's Keycloak endpoints and credentials**

        Export the realm URL, the introspection endpoint, and the **Kong MCP Gateway** client's ID and Secret. You don't export the MCP Client's Client ID here. The MCP client itself uses it at flow time.

        ```bash
        export DECK_OAUTH_AUTH_SERVER='https://your-keycloak-host/realms/mcp-demo'
        export DECK_OAUTH_INTROSPECTION_URL='https://your-keycloak-host/realms/mcp-demo/protocol/openid-connect/token/introspect'
        export DECK_OAUTH_CLIENT_ID='kong-mcp-gateway'
        export DECK_OAUTH_CLIENT_SECRET='your-kong-gateway-client-secret'
        ```

        {% endtab %}
        {% endnavtabs %}
    - title: Konnect MCP
      content: |
        [{{site.konnect_short_name}} MCP](/konnect-platform/konnect-mcp/) is reachable at a single global endpoint:

        ```bash
        export DECK_KONNECT_MCP_HOST='https://global.mcp.konghq.com'
        ```
    - title: Insomnia 12+
      content: |
        This recipe verifies the gateway using [Insomnia](https://insomnia.rest/), Kong's MCP-aware API client. Insomnia speaks the MCP protocol natively and handles OAuth 2.1 + PKCE, including Protected Resource Metadata (PRM) discovery.

        1. Install **Insomnia** from [insomnia.rest/download](https://insomnia.rest/download).
        1. Verify the version is 12.0 or later (Help → About on macOS, equivalent on other platforms).

        {:.warning}
        > {{site.konnect_short_name}}'s MCP server rejects HTTP-originated traffic, so this recipe targets Kong's local HTTPS listener at `https://localhost:8443`, which uses a self-signed certificate. On each MCP request you create in Insomnia, click **Manage Certificates** at the top of the request pane and toggle **SSL Certificate Validation** off under **Extra Options**. Scope this per-request, not globally.

        See [MCP clients in Insomnia](/insomnia/mcp-clients-in-insomnia/) for an overview of MCP server testing in Insomnia.

overview: |
  Organizations adopting MCP (Model Context Protocol) often end up connecting AI agents to a sprawl of third-party MCP servers (GitHub, Slack, Figma, {{site.konnect_short_name}}, and so on), each with its own tokens, no central audit trail, and no way to govern which tools an agent can call. Putting {{site.ai_gateway_name}} in front of those servers gives the platform team a single boundary for ACL enforcement, observability, and credential management without changing how the upstream provider's auth works.

  Broadly, there are two types of MCP servers {{site.ai_gateway_name}} can proxy, distinguished by who owns the user identity. **Internal MCP servers** live inside your organization's trust boundary. Your IdP is the MCP auth server, and your security team controls the tokens. The [Secure Internal MCP Gateway](/cookbooks/secure-internal-mcp-gateway/) recipe covers that case. **External MCP servers** are third-party SaaS like GitHub, Slack, and Figma that run their own authorization servers and issue their own (often opaque) tokens.

  This recipe covers the external case with two AI MCP Server entities: one for GitHub MCP and one for {{site.konnect_short_name}} MCP. The **passthrough** pattern (GitHub MCP) lets the user authenticate directly with GitHub; Kong passes the token through and uses a Key Auth AI Auth Strategy for AI Consumer identity and tool-level ACLs. The **token swap** pattern ({{site.konnect_short_name}} MCP) authenticates the user against the organization's IdP, maps the user to an AI Consumer, then swaps the user token for a stored {{site.konnect_short_name}} credential (Personal Access Token for the demo, Service Account Token in production) before forwarding.
---

## The problem

**External tokens are opaque to Kong.** GitHub, Figma, and most third-party MCP servers issue
opaque access tokens, not JWTs. Kong can't extract claims from an opaque token, which means
there's no way to identify the user, map them to an AI Consumer Group, or enforce ACLs based on
the token alone.

**MCP auth discovery is inconsistent.** The MCP spec requires servers to advertise their auth
requirements through Protected Resource Metadata (PRM, RFC 9728). When a gateway proxies an
external MCP server, the PRM's `resource` field points at the upstream (for example,
`api.githubcopilot.com/mcp`), not at the gateway itself. An MCP client that follows this field
strictly tries to validate against the wrong resource unless the gateway advertises its own
PRM in front of the upstream.

**No centralized observability or access control.** Without a proxy, each developer connects
directly to external MCP servers. There is no audit trail, no way to restrict which tools an
AI agent can call, and no visibility into which tools people use across the organization.
A junior developer's AI agent has the same GitHub tool access as a senior engineer's.

**Token management is distributed.** Each developer manages their own tokens for each external
MCP server. There is no central revocation point, no token rotation policy, and no way to use
a shared service account for services that support it (like {{site.konnect_short_name}}).

## The solution

This recipe places {{site.ai_gateway_name}} in front of external MCP servers with two AI MCP Server
entities, one per pattern:

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP Client
    participant GH as GitHub
    participant K as Kong AI Gateway

    C->>GH: OAuth flow (Client ID and Secret configured directly in the MCP client)
    activate GH
    GH-->>C: GitHub Bearer token
    deactivate GH
    C->>K: MCP request (apikey and Bearer token)
    activate K
    K->>K: key-auth Auth Strategy, validate apikey, resolve Consumer (else 401)
    K->>K: AI MCP Server ACLs, evaluate tool access for the Consumer's group (else 403)
    K->>GH: Forward request with Bearer token
    activate GH
    GH-->>K: MCP response
    deactivate GH
    K-->>C: MCP response
    deactivate K
{% endmermaid %}
<!-- vale on -->

**GitHub MCP (passthrough pattern).** GitHub issues the upstream OAuth token directly to the MCP
client. Kong identifies the caller separately through a Key Auth AI Auth Strategy and enforces
tool-level ACLs before forwarding the GitHub Bearer token upstream unchanged.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP Client
    participant K as Kong AI Gateway
    participant IdP as Identity Provider
    participant KM as Konnect MCP Server

    C->>K: MCP initialize (no token)
    activate K
    K-->>C: 401 and protected resource metadata
    deactivate K
    C->>IdP: OAuth flow (browser to Okta or Keycloak, then callback)
    activate IdP
    IdP-->>C: Bearer token
    deactivate IdP
    C->>K: MCP request (Bearer token)
    activate K
    K->>IdP: openid-connect Auth Strategy, introspect token (else 401)
    activate IdP
    IdP-->>K: Claims (sub maps to Consumer, groups maps to Consumer Group)
    deactivate IdP
    K->>K: Strip user token, inject stored Konnect credential
    K->>KM: Forward request with stored Konnect credential
    activate KM
    KM-->>K: MCP response
    deactivate KM
    K-->>C: MCP response
    deactivate K
{% endmermaid %}
<!-- vale on -->

**{{site.konnect_short_name}} MCP (token swap pattern).** The user authenticates against the organization's IdP. An
OpenID Connect AI Auth Strategy validates the token, maps the caller to an AI Consumer, and serves
protected resource metadata on Kong's behalf. Kong then swaps the user's token for a stored
{{site.konnect_short_name}} credential before forwarding.

{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibility
    key: responsibility
rows:
  - component: "GitHub OAuth"
    responsibility: "Issues tokens for GitHub API access; the MCP client authenticates directly with GitHub"
  - component: "Identity Provider (Okta or Keycloak)"
    responsibility: "Issues tokens for organizational identity; used by the {{site.konnect_short_name}} MCP pattern"
  - component: "Key Auth AI Auth Strategy"
    responsibility: "Resolves an AI Consumer from the `apikey` header for GitHub MCP ACL evaluation"
  - component: "OpenID Connect AI Auth Strategy"
    responsibility: "Validates the IdP token for {{site.konnect_short_name}} MCP through introspection and maps claims to an AI Consumer and AI Consumer Group"
  - component: "AI MCP Server (GitHub MCP)"
    responsibility: "Proxies MCP traffic to GitHub in passthrough mode and enforces tool-level ACLs"
  - component: "AI MCP Server ({{site.konnect_short_name}} MCP)"
    responsibility: "Proxies MCP traffic to the {{site.konnect_short_name}} MCP server, advertises protected resource metadata, and hosts the token-swap AI Policy"
  - component: "Request Transformer Advanced Policy"
    responsibility: "Injects the stored {{site.konnect_short_name}} credential once the OpenID Connect AI Auth Strategy strips the user's token"
{% endtable %}

### ACL matrix (GitHub MCP)

The GitHub MCP server exposes 70+ tools. This recipe defines ACLs for a representative subset,
with a default deny for the developer AI Consumer Group on unlisted tools:

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
create issues, push code, create and merge pull requests, and create repositories. The default
ACL denies only the developer group, so admins can call any GitHub MCP tool not explicitly
listed in the config, while developers can't.

## How it works

{:.warning}
> **Open item: GitHub PRM discovery.** This recipe's GitHub MCP server does not advertise
> protected resource metadata (PRM) the way the {{site.konnect_short_name}} MCP server does, because that mechanism
> requires an OpenID Connect AI Auth Strategy, and GitHub itself, not Kong, validates GitHub's
> opaque tokens. If your MCP client insists on discovering GitHub's OAuth details through
> a PRM document served at your own gateway's URL, configure the client's OAuth 2.0 settings
> manually (authorization URL, token URL, Client ID, and Client Secret from GitHub's own
> documentation) instead of relying on automatic discovery through Kong. For the manual
> configuration this recipe uses with Insomnia, see
> [Verify GitHub MCP with Insomnia](#verify-github-mcp-passthrough-and-dual-auth-with-insomnia).

A request flowing through Kong takes one of two paths depending on which MCP server it targets.

**GitHub MCP (passthrough):**

1. The MCP client authenticates with GitHub directly, using the Client ID and Client Secret from
   the GitHub OAuth Application prerequisite, and obtains a GitHub Bearer token.
2. The client sends an MCP request to Kong carrying two headers: `apikey` (an AI Consumer
   credential) and `Authorization: Bearer <github-token>`.
3. The Key Auth AI Auth Strategy reads `apikey`, looks it up against a registered AI Consumer
   credential, and attaches the matching AI Consumer (and its AI Consumer Group) to the request. A
   missing or unknown key short-circuits with `401` before any upstream call.
4. The AI MCP Server evaluates the requested tool against the AI Consumer Group's ACL. Tools not
   explicitly allowed for the developer group return `403` before the request reaches GitHub.
5. On an allowed tool, Kong forwards the request to GitHub's MCP server with the Bearer token
   untouched. GitHub processes the call and Kong returns the response to the client.

**{{site.konnect_short_name}} MCP (token swap):**

1. The MCP client sends an unauthenticated `initialize` request to Kong.
2. Kong's OpenID Connect AI Auth Strategy, combined with the AI MCP Server's protected resource
   metadata configuration, returns `401` with a `WWW-Authenticate` header pointing at Kong's own
   metadata document, which advertises the organization's identity provider as the authorization
   server.
3. The client completes an OAuth 2.1 flow with the identity provider (Okta or Keycloak) and
   obtains a Bearer token.
4. The client reconnects with the Bearer token. The OpenID Connect AI Auth Strategy introspects it,
   maps the `sub` claim to an AI Consumer, maps the `groups` claim to an AI Consumer Group, and
   strips the token from the request.
5. The Request Transformer Advanced Policy injects the stored {{site.konnect_short_name}} credential into the
   now-empty `Authorization` header.
6. Kong forwards the request to the {{site.konnect_short_name}} MCP server using the stored credential and
   returns the response to the client.

### Key Auth: AI Consumer identification for GitHub MCP

External MCP servers with opaque tokens create a dual auth challenge: who is calling within your
organization, and what can that caller access on GitHub? Kong answers the first question with a
Key Auth AI Auth Strategy that resolves an AI Consumer from the `apikey` header, independent of
the GitHub Bearer token that travels alongside it in `Authorization`. Because the Key Auth AI Auth Strategy only ever
inspects `apikey`, the two headers coexist on the same request without interference, and the
AI Consumer identity it resolves is what the AI MCP Server's ACLs evaluate against.

#### Configuration details

```yaml
ai_gateway_auth_strategies:
  - ref: secure-external-mcp-gateway-github-key-auth
    type: key-auth
    display_name: "secure-external-mcp-gateway GitHub key auth"
    config:
      key_names:
        - apikey
      hide_credentials: true
```
{:.no-copy-code}

**`key_names: [apikey]`**. The header Kong checks for the AI Consumer's key. Using `apikey` instead
of `Authorization` keeps the AI Consumer credential and the GitHub Bearer token on separate
headers.

**`hide_credentials: true`**. Strips the `apikey` header before forwarding upstream. GitHub never
sees the AI Consumer credential; it only sees the `Authorization: Bearer` header the client
supplied for GitHub's own auth.

### Tool-level ACLs: governing GitHub MCP access by AI Consumer Group

After Kong resolves an AI Consumer, the [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity
evaluates every tool discovery and tool invocation request against that AI Consumer's group
memberships. A default rule covers every tool the recipe doesn't list explicitly, and per-tool
rules override the default for anything that needs a tighter policy. This combination lets a junior
developer's AI agent see a restricted tool catalog while an admin's agent sees the full one,
directly addressing the "no centralized access control" problem.

#### Configuration details

```yaml
ai_gateway_consumer_groups:
  - ref: secure-external-mcp-gateway-admin
    display_name: "secure-external-mcp-gateway admin group"
    consumers:
      - secure-external-mcp-gateway-admin-user
  - ref: secure-external-mcp-gateway-developer
    display_name: "secure-external-mcp-gateway developer group"
    consumers:
      - secure-external-mcp-gateway-dev-user

ai_gateway_mcp_servers:
  - ref: secure-external-mcp-gateway-github-mcp
    type: passthrough-listener
    access:
      auth_strategies:
        - secure-external-mcp-gateway-github-key-auth
      acl_attribute_type: consumer
      default_tool_acls:
        deny:
          - secure-external-mcp-gateway-developer
    config:
      url: https://api.githubcopilot.com/mcp
      route:
        paths:
          - /github-mcp
    tools:
      - name: search_repositories
        description: Search GitHub repositories
        access:
          acls:
            allow:
              - secure-external-mcp-gateway-admin
              - secure-external-mcp-gateway-developer
      - name: push_files
        description: Push files to a repository
        access:
          acls:
            allow:
              - secure-external-mcp-gateway-admin
```
{:.no-copy-code}

**`type: passthrough-listener`**. Kong proxies MCP traffic straight to the upstream server
without converting tools. The `tools` list names real upstream tools for ACL attachment only;
Kong doesn't own their schema.

**`access.acl_attribute_type: consumer`**. Evaluates ACL rules against the resolved AI Consumer
and its AI Consumer Group memberships (the alternative, `oauth_access_token`, evaluates a claim from
an OAuth token instead, and requires an OpenID Connect AI Auth Strategy).

**`access.default_tool_acls`**. The baseline rule for every tool without its own `access.acls`.
Because the default denies only the developer group, any AI Consumer outside that group, including
admin, can call unlisted tools.

**`tools[].access.acls`**. A per-tool ACL fully replaces the default for that tool. It doesn't
merge, so every allowed group must be listed explicitly, even ones already implied by the
default.

**`ai_gateway_consumer_groups[].consumers`**. Declares group membership from the group's side by
listing the AI Consumers that belong to it.

### OpenID Connect: authenticating {{site.konnect_short_name}} MCP through your identity provider

The {{site.konnect_short_name}} MCP route swaps opaque-token passthrough for real identity: an
[OpenID Connect](/ai-gateway/openid-connect/) AI Auth Strategy validates the caller's
token against your organization's IdP and resolves an AI Consumer and AI Consumer Group from its claims.
Pairing the strategy with `access.metadata` on the AI MCP Server also makes Kong advertise
protected resource metadata (RFC 9728) at this route automatically, so MCP clients can discover
the IdP without any custom challenge logic.

#### Configuration details

```yaml
ai_gateway_auth_strategies:
  - ref: secure-external-mcp-gateway-konnect-oauth
    type: openid-connect
    display_name: "secure-external-mcp-gateway Konnect OAuth2"
    config:
      issuer: !env DECK_OAUTH_AUTH_SERVER
      introspection_endpoint: !env DECK_OAUTH_INTROSPECTION_URL
      client_id: !env DECK_OAUTH_CLIENT_ID
      client_secret: !secret {source: !env DECK_OAUTH_CLIENT_SECRET}
      cache_introspection: true
      ssl_verify: true
      hide_credentials: true
      consumer_claims:
        - [sub]
      consumer_by:
        - username
        - custom_id
      consumer_optional: true
      consumer_groups_claim:
        - groups
      consumer_groups_optional: true
      credential_claim:
        - sub

ai_gateway_mcp_servers:
  - ref: secure-external-mcp-gateway-konnect-mcp
    type: passthrough-listener
    access:
      auth_strategies:
        - secure-external-mcp-gateway-konnect-oauth
      acl_attribute_type: consumer
      metadata:
        resource: https://localhost:8443/konnect-mcp
        authorization_servers:
          - !env DECK_OAUTH_AUTH_SERVER
        scopes_supported:
          - openid
        endpoint: /.well-known/oauth-protected-resource/konnect-mcp
    config:
      url: !env DECK_KONNECT_MCP_HOST
      route:
        paths:
          - /konnect-mcp
```
{:.no-copy-code}

**`hide_credentials: true`**. Strips the caller's IdP Bearer token from the request once
authentication succeeds, so the {{site.konnect_short_name}} MCP server never sees it. The Request Transformer
Advanced Policy fills the header back in with the stored {{site.konnect_short_name}} credential.

**`consumer_claims`**. The claim path Kong reads to resolve an AI Consumer, expressed as a list of
claim paths so nested claims are possible. `[[sub]]` reads the token's top-level `sub` claim.

**`consumer_groups_claim` / `consumer_groups_optional`**. Maps the IdP's `groups` claim to Kong
AI Consumer Groups. This recipe leaves the route without tool ACLs (see
[Variations and next steps](#variations-and-next-steps)), but the mapping is already in place for whenever you add them.

**`access.metadata`**. Declares the protected resource's canonical URL (`resource`), the IdP that
issues tokens for it (`authorization_servers`), the scopes the resource accepts
(`scopes_supported`), and the path Kong serves the metadata document at (`endpoint`). Kong adds
that path to this AI MCP Server's route automatically.

**`consumer_optional` / no tool ACLs on this route.** Kong lets any authenticated IdP user
through without a pre-registered AI Consumer, matching the goal of authenticating any
organizational user while keeping the credential swap centralized.

### Request Transformer Advanced: the {{site.konnect_short_name}} credential swap

The OpenID Connect AI Auth Strategy strips the user's Bearer token as part of a successful
authentication. The [Request Transformer Advanced](/ai-gateway/policies/request-transformer-advanced/)
Policy fills that now-empty `Authorization` header with the stored {{site.konnect_short_name}} credential right
before the request reaches the upstream. Each AI Policy owns one half of the swap, so the contract
between authentication and credential injection stays visible in configuration rather than
implicit in ordering.

#### Configuration details

```yaml
ai_gateway_policies:
  - ref: secure-external-mcp-gateway-konnect-token-swap
    type: request-transformer-advanced
    display_name: "secure-external-mcp-gateway Konnect token swap"
    config:
      add:
        headers:
          - !secret {source: !env DECK_KONNECT_MCP_TOKEN}
```
{:.no-copy-code}

**`config.add.headers`**. A list of complete `"Name:Value"` header strings to add. This recipe
sets `DECK_KONNECT_MCP_TOKEN` to the entire `Authorization:Bearer <token>` string (see
Prerequisites), since the AI Policy field takes one combined string per header rather than separate
name and value fields.

This AI Policy attaches to the {{site.konnect_short_name}} MCP server through its `policies` field and runs after ACL
checks, right before the request reaches the upstream {{site.konnect_short_name}} MCP server.

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. AI Vaults support HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store.

## Apply the Kong configuration

This configuration creates two AI MCP Server entities, GitHub MCP with passthrough auth and
tool-level ACLs, and {{site.konnect_short_name}} MCP with OAuth-based identity and a token swap, all scoped under the
`secure-external-mcp-gateway-recipe` kongctl namespace so teardown removes only this recipe's
resources. First, adopt the quickstart {{site.ai_gateway}} into that namespace:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the {{site.ai_gateway}}.

Export the demo AI Consumer API keys used by the GitHub MCP route's ACL demonstration. Both are
write-only AI Consumer credential fields and must come from env vars, even for these fixed demo
values:

```bash
export DECK_ADMIN_API_KEY='admin-api-key'
export DECK_DEV_API_KEY='dev-api-key'
```

You already exported the `DECK_OAUTH_*`, `DECK_KONNECT_MCP_HOST`, and `DECK_KONNECT_MCP_TOKEN`
env vars in the prerequisites. Apply the configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: secure-external-mcp-gateway-recipe
ai_gateway_auth_strategies:
- ref: secure-external-mcp-gateway-github-key-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: secure-external-mcp-gateway-github-key-auth
  display_name: secure-external-mcp-gateway GitHub key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
- ref: secure-external-mcp-gateway-konnect-oauth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: secure-external-mcp-gateway-konnect-oauth
  display_name: secure-external-mcp-gateway Konnect OAuth2
  type: openid-connect
  config:
    issuer: !env 'DECK_OAUTH_AUTH_SERVER'
    introspection_endpoint: !env 'DECK_OAUTH_INTROSPECTION_URL'
    client_id: !env 'DECK_OAUTH_CLIENT_ID'
    client_secret: !secret {source: !env 'DECK_OAUTH_CLIENT_SECRET'}
    cache_introspection: true
    ssl_verify: true
    hide_credentials: true
    consumer_claims:
    - [sub]
    consumer_by:
    - username
    - custom_id
    consumer_optional: true
    consumer_groups_claim:
    - groups
    consumer_groups_optional: true
    credential_claim:
    - sub
ai_gateway_consumers:
- ref: secure-external-mcp-gateway-admin-user
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: secure-external-mcp-gateway-admin-user
  display_name: secure-external-mcp-gateway admin user
  type: api-key
  credentials:
  - ref: secure-external-mcp-gateway-admin-credential
    name: secure-external-mcp-gateway-admin-credential
    display_name: secure-external-mcp-gateway admin API key
    type: api-key
    api_key: !secret {source: !env 'DECK_ADMIN_API_KEY'}
- ref: secure-external-mcp-gateway-dev-user
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: secure-external-mcp-gateway-dev-user
  display_name: secure-external-mcp-gateway developer user
  type: api-key
  credentials:
  - ref: secure-external-mcp-gateway-dev-credential
    name: secure-external-mcp-gateway-dev-credential
    display_name: secure-external-mcp-gateway developer API key
    type: api-key
    api_key: !secret {source: !env 'DECK_DEV_API_KEY'}
ai_gateway_consumer_groups:
- ref: secure-external-mcp-gateway-admin
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: secure-external-mcp-gateway-admin
  display_name: secure-external-mcp-gateway admin group
  consumers:
  - secure-external-mcp-gateway-admin-user
- ref: secure-external-mcp-gateway-developer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: secure-external-mcp-gateway-developer
  display_name: secure-external-mcp-gateway developer group
  consumers:
  - secure-external-mcp-gateway-dev-user
ai_gateway_policies:
- ref: secure-external-mcp-gateway-konnect-token-swap
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: secure-external-mcp-gateway-konnect-token-swap
  display_name: secure-external-mcp-gateway Konnect token swap
  type: request-transformer-advanced
  config:
    add:
      headers:
      - !secret {source: !env 'DECK_KONNECT_MCP_TOKEN'}
ai_gateway_mcp_servers:
- ref: secure-external-mcp-gateway-github-mcp
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: secure-external-mcp-gateway-github-mcp
  display_name: secure-external-mcp-gateway GitHub MCP
  type: passthrough-listener
  enabled: true
  access:
    auth_strategies:
    - secure-external-mcp-gateway-github-key-auth
    acl_attribute_type: consumer
    default_tool_acls:
      deny:
      - secure-external-mcp-gateway-developer
  config:
    url: https://api.githubcopilot.com/mcp
    route:
      paths:
      - /github-mcp
      protocols:
      - http
      - https
      strip_path: true
      request_buffering: false
      response_buffering: false
    logging:
      payloads: true
      audits: true
    max_request_body_size: 10485760
  tools:
  - name: search_repositories
    description: Search GitHub repositories
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
        - secure-external-mcp-gateway-developer
  - name: get_file_contents
    description: Get file contents from a repository
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
        - secure-external-mcp-gateway-developer
  - name: list_issues
    description: List issues in a repository
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
        - secure-external-mcp-gateway-developer
  - name: list_pull_requests
    description: List pull requests in a repository
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
        - secure-external-mcp-gateway-developer
  - name: search_users
    description: Search GitHub users
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
        - secure-external-mcp-gateway-developer
  - name: search_code
    description: Search code across repositories
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
        - secure-external-mcp-gateway-developer
  - name: create_issue
    description: Create an issue in a repository
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
  - name: push_files
    description: Push files to a repository
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
  - name: create_pull_request
    description: Create a pull request
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
  - name: merge_pull_request
    description: Merge a pull request
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
  - name: create_repository
    description: Create a new repository
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
- ref: secure-external-mcp-gateway-konnect-mcp
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: secure-external-mcp-gateway-konnect-mcp
  display_name: secure-external-mcp-gateway Konnect MCP
  type: passthrough-listener
  enabled: true
  access:
    auth_strategies:
    - secure-external-mcp-gateway-konnect-oauth
    acl_attribute_type: consumer
    metadata:
      resource: https://localhost:8443/konnect-mcp
      authorization_servers:
      - !env 'DECK_OAUTH_AUTH_SERVER'
      scopes_supported:
      - openid
      endpoint: /.well-known/oauth-protected-resource/konnect-mcp
  config:
    url: !env 'DECK_KONNECT_MCP_HOST'
    route:
      paths:
      - /konnect-mcp
      protocols:
      - http
      - https
      request_buffering: false
      response_buffering: false
    logging:
      payloads: true
      audits: true
    max_request_body_size: 10485760
  policies:
  - secure-external-mcp-gateway-konnect-token-swap
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

## Try it out

With the configuration applied, both external MCP endpoints are ready to accept connections. The
verification path below uses [Insomnia](/insomnia/mcp-clients-in-insomnia/), Kong's MCP-aware API
client, to exercise both patterns: GitHub MCP with passthrough auth and dual-header identity, and
{{site.konnect_short_name}} MCP with OAuth-driven token swap. Once verified, the same endpoints work with any
MCP-compatible AI client.

{:.warning}
> {{site.konnect_short_name}}'s MCP server rejects HTTP-originated traffic, so this recipe targets Kong's local HTTPS
> listener at `https://localhost:8443`, which uses a self-signed certificate. On each MCP request
> you create in Insomnia, click **Manage Certificates** at the top of the request pane and toggle
> **SSL Certificate Validation** off under **Extra Options**. Scope this per-request, not
> globally.

### Verify GitHub MCP (passthrough and dual auth) with Insomnia

The GitHub MCP route demonstrates the passthrough pattern: GitHub issues the upstream OAuth
token, Kong identifies the caller separately with the Key Auth AI Auth Strategy, and the AI MCP Server enforces
tool-level ACLs. Because the Key Auth AI Auth Strategy gates every request to this route, including
the first one, configure the `apikey` header before connecting rather than waiting for a
challenge from Kong.

1. **Create an MCP request.** In Insomnia, create a new request, select **MCP** as the request
   type, and enter the gateway URL:

    ```text
    https://localhost:8443/github-mcp
    ```
    {:.no-copy-code}

1. **Add the AI Consumer key.** Click the **Headers** tab and add `apikey: dev-api-key` (use
   `admin-api-key` to test with the admin AI Consumer Group). This header coexists with the Bearer
   token Insomnia adds during OAuth: Kong's Key Auth AI Auth Strategy reads `apikey` while GitHub
   reads `Authorization: Bearer`.

1. **Configure OAuth on the request.** Click the **Auth** tab and select **OAuth 2.0** from the
   dropdown. Set **Grant Type** to **MCP Auth flow**. Enter the **Client ID** and **Client
   Secret** from your GitHub OAuth Application. Both are required because GitHub's OAuth Apps
   treat the client as confidential. Set **Scope** to `repo read:user read:org`
   (space-separated); GitHub issues tokens with no useful permissions when the authorization
   request omits scopes, and the GitHub MCP server then rejects tool calls with
   `insufficient scopes`. Set **State** to any value (for example, `recipe-test`).

    {:.info}
    > If Insomnia's automatic discovery fails to find GitHub's OAuth endpoints (this route
    > doesn't serve rewritten protected resource metadata the way the {{site.konnect_short_name}} route does), set
    > **Authorization URL** to `https://github.com/login/oauth/authorize` and **Access Token
    > URL** to `https://github.com/login/oauth/access_token` directly instead of relying on
    > discovery.

1. **Complete GitHub OAuth and connect.** Insomnia opens your browser to GitHub's authorization
   endpoint. Sign in and approve the application. Insomnia captures the redirect, exchanges the
   authorization code for an access token, and connects to the MCP endpoint carrying both
   `apikey: dev-api-key` (for Kong) and `Authorization: Bearer ghu_...` (for GitHub).

1. **List tools.** As `dev-api-key`, Insomnia lists six read-only tools: `search_repositories`,
   `get_file_contents`, `list_issues`, `list_pull_requests`, `search_users`, `search_code`. The
   five admin-only write tools (`create_issue`, `push_files`, `create_pull_request`,
   `merge_pull_request`, `create_repository`) are filtered out, along with every other GitHub MCP
   tool. The default ACL denies the developer AI Consumer Group on anything not explicitly allowed.
   Switch `apikey` to `admin-api-key` and reconnect to see the full GitHub MCP tool catalog
   (70+).

1. **Call a permitted tool.** Invoke `search_repositories` with a query like
   `kong gateway language:go`. The call succeeds; the response body shows GitHub's search
   results, proxied through Kong using the Bearer token.

    The ACL is enforced server-side on the AI MCP Server, not by filtering the client's catalog
    alone. Kong evaluates every `tools/call` against the caller's AI Consumer Group before
    forwarding upstream, so a misbehaving client that bypasses the filtered catalog and crafts a
    raw JSON-RPC request for `push_files` as `dev-api-key` receives `403 Forbidden`, and the
    request never reaches GitHub.

### Verify {{site.konnect_short_name}} MCP (token swap) with Insomnia

The {{site.konnect_short_name}} MCP route demonstrates the token-swap pattern: the user authenticates with the
organization's IdP, Kong validates the token and maps the user to an AI Consumer, then the Request
Transformer Advanced Policy strips the user's token and injects the stored {{site.konnect_short_name}} credential
before forwarding upstream.

1. **Create a second MCP request** pointed at:

    ```text
    https://localhost:8443/konnect-mcp
    ```
    {:.no-copy-code}

1. **Configure OAuth on the request.** Click the **Auth** tab and select **OAuth 2.0** from the
   dropdown. Set **Grant Type** to **MCP Auth flow**. Enter the **Client ID** copied from the
   `MCP Client` SPA application in your IdP (Okta) or the `mcp-client` public client (Keycloak).
   Set **State** to any value (for example, `recipe-test`). Insomnia uses these values when it
   runs the PKCE flow in the next step.

1. **Initiate the connection.** Insomnia sends `initialize` without credentials. Kong returns
   `401` with `WWW-Authenticate` pointing at
   `/.well-known/oauth-protected-resource/konnect-mcp`. Insomnia fetches the protected resource
   metadata and discovers the configured IdP authorization server.

1. **Complete OAuth through your IdP.** Insomnia opens your browser to the IdP (Okta or
   Keycloak) authorization endpoint and runs the PKCE flow. Sign in and approve the application;
   Insomnia captures the redirect and obtains an access token issued by your IdP.

1. **Reconnect.** Insomnia sends the MCP `initialize` again with
   `Authorization: Bearer <idp-token>`. The OpenID Connect AI Auth Strategy introspects the token,
   maps the `sub` claim to an AI Consumer, and strips the user's `Authorization` header. The
   Request Transformer Advanced Policy then adds the stored {{site.konnect_short_name}} credential from
   `DECK_KONNECT_MCP_TOKEN` into the now-empty `Authorization` header before the request reaches
   the {{site.konnect_short_name}} MCP endpoint. The swap is invisible from the Insomnia side. It shows up
   only in the upstream {{site.konnect_short_name}} audit log and in the {{site.konnect_short_name}} MCP {{site.ai_gateway}}'s traffic analytics,
   where you can confirm Kong forwarded the request authenticated as the stored {{site.konnect_short_name}} identity,
   not the end user.

1. **List {{site.konnect_short_name}} MCP tools.** Insomnia displays the tools exposed by the {{site.konnect_short_name}} MCP server
   (control plane management, API exploration, and similar operations). Call a read-only tool
   such as the one that lists control planes; the response comes from {{site.konnect_short_name}}, served under the
   stored credential's permissions.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named
`secure-external-mcp-gateway-recipe`. The recipe created two AI MCP Servers
(`secure-external-mcp-gateway-github-mcp` and `secure-external-mcp-gateway-konnect-mcp`), two
AI Auth Strategies (a Key Auth AI Auth Strategy for GitHub, an OpenID Connect AI Auth Strategy for {{site.konnect_short_name}}), a
Request Transformer Advanced Policy for the token swap, two AI Consumers (`admin-user` and
`dev-user`) with their API key credentials, and two AI Consumer Groups (`admin` and `developer`),
all scoped to this recipe by the kongctl namespace applied above.

For platform-wide traffic analysis across every {{site.ai_gateway}}, including per-consumer attribution
for the {{site.konnect_short_name}} MCP token swap, head to the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

- **Connect from an AI harness.** Both routes work in any MCP-compatible client (Claude Code, VS
  Code, Claude Desktop, and others). Each client handles OAuth differently, so follow the
  client's documentation for adding a remote MCP server. Before connecting, register that
  client's OAuth redirect URI on the GitHub OAuth Application and on your IdP `MCP Client`
  application alongside Insomnia's `https://app.insomnia.rest/oauth/redirect`. For the GitHub
  route, the client must accept both a Client ID and a Client Secret (GitHub OAuth Apps require
  the secret at token exchange) and must also send `apikey: <admin-api-key|dev-api-key>` so Kong
  can identify the AI Consumer for ACL evaluation.
- **Add more GitHub MCP tools to the ACLs.** The recipe defines ACLs for 11 of GitHub's 70+
  tools. To restrict additional tools, add more entries to the `tools` list on the GitHub AI MCP
  Server with the appropriate `access.acls.allow` groups. Any tool not explicitly listed falls
  under `access.default_tool_acls` (denied for developers, allowed for admins).
- **Enforce tool-level ACLs on the {{site.konnect_short_name}} MCP route.** The OpenID Connect AI Auth Strategy already
  maps an IdP `groups` claim to AI Consumer Groups. To restrict which {{site.konnect_short_name}} MCP tools each
  group can call, pre-create the AI Consumer Groups and add `access.acls` rules to the {{site.konnect_short_name}}
  AI MCP Server's `tools` list, mirroring the GitHub MCP route. The
  [Secure Internal MCP Gateway](/cookbooks/secure-internal-mcp-gateway/) recipe shows the full
  IdP-claim-to-ACL pattern end-to-end.
- **Proxy other external MCP servers.** The passthrough pattern (Key Auth plus AI MCP Server
  ACLs) works for any external MCP server that uses OAuth. Point a new AI MCP Server's `config.url`
  at the provider's MCP endpoint and create an OAuth app (or equivalent) for that provider.
- **Combine with internal MCP.** Use the
  [Secure Internal MCP Gateway](/cookbooks/secure-internal-mcp-gateway/) recipe alongside this
  one to expose both internal and external MCP tools through a single {{site.ai_gateway}}. Both patterns
  can share AI Consumers and AI Consumer Groups for unified access control.

## Cleanup

The recipe's kongctl namespace scopes all resources, so the teardown removes only this recipe's
configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='secure-external-mcp-gateway-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
