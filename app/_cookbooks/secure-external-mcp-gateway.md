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
works_on:
  - konnect
min_version:
  ai-gateway: '2.0'
categories:
  - mcp
  - access-control
featured: false
popular: false
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
           export KONNECT_CONTROL_PLANE_NAME='secure-external-mcp-gateway-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `secure-external-mcp-gateway-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: GitHub OAuth App
      icon_url: /assets/icons/github.svg
      content: |
        The GitHub MCP server uses GitHub's OAuth. GitHub doesn't support Dynamic Client Registration, so you register an OAuth App for your MCP client ([GitHub: Creating an OAuth app](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app)).

        1. On GitHub, click your profile picture, then **Settings > Developer settings > OAuth Apps**, and click **New OAuth App**.
        1. Set **Application name** to `Kong MCP Client`.
        1. Set **Homepage URL** to `https://localhost:8443`.
        1. Set **Authorization callback URL** to `https://app.insomnia.rest/oauth/redirect`, Insomnia's default OAuth redirect URL.
        1. Click **Register application**.
        1. Click **Generate a new client secret**.
        1. Copy the **Client ID** and the client secret. You enter both in Insomnia in [Connect Insomnia to GitHub MCP](#connect-insomnia-to-github-mcp).

        GitHub requires the client secret when it exchanges the authorization code for a token, also when the client uses PKCE ([GitHub: Authorizing OAuth apps](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)). An MCP client that sends only the Client ID fails at the token exchange.
    - title: Identity Provider
      content: |
        The {{site.konnect_short_name}} MCP route authenticates users against your identity provider (IdP) with token introspection. This cookbook covers Okta and Keycloak. Each setup creates two applications: a confidential client that Kong uses to call the introspection endpoint, and a public client for the MCP client.

        {% navtabs "Identity Provider" %}
        {% navtab "Okta" %}

        You need an Okta organization with admin access.

        **Create the Kong MCP Gateway application**

        This confidential client represents Kong. Kong uses its credentials to call Okta's introspection endpoint ([Okta: Client Credentials flow](https://developer.okta.com/docs/guides/implement-grant-type/clientcreds/main/)).

        1. In the Okta Admin Console, go to **Applications and Resources > Applications**, click **Create App Integration**, and select **Classic experience**.
        1. Select **API Services**, then click **Next**.
        1. Name the application `Kong MCP Gateway` and click **Save**.
        1. On the **General** tab, in **Client Credentials**, copy the **Client ID** and the **Client secret**.

        **Create the MCP Client application**

        This public client represents Insomnia. It uses Authorization Code with PKCE and no client secret ([Okta: Authorization Code with PKCE](https://developer.okta.com/docs/guides/implement-grant-type/authcodepkce/main/)).

        1. Go to **Applications and Resources > Applications**, click **Create App Integration**, and select **Classic experience**.
        1. Select **OIDC - OpenID Connect** and **Single-Page Application**, then click **Next**.
        1. Name the application `MCP Client`.
        1. Set the sign-in redirect URI to `https://app.insomnia.rest/oauth/redirect`.
        1. Click **Save**.
        1. In **Client Credentials**, confirm that client authentication is **None**. With **None**, Okta requires PKCE.
        1. Copy the **Client ID**. You enter it in Insomnia.

        **Assign a test user**

        1. Go to **Directory > People** and add a user, for example `mcp-test-user@example.com`, or pick an existing user who can sign in.
        1. Open the `MCP Client` application, click the **Assignments** tab, and assign the user. Without this assignment, Okta blocks the sign-in.

        **Export the Okta values**

        Export the `default` authorization server's issuer URL, its introspection endpoint, and the **Kong MCP Gateway** application's credentials:

        ```bash
        export OAUTH_AUTH_SERVER='https://your-org.okta.com/oauth2/default'
        export OAUTH_INTROSPECTION_URL='https://your-org.okta.com/oauth2/default/v1/introspect'
        export OAUTH_CLIENT_ID='your-kong-mcp-gateway-client-id'
        export OAUTH_CLIENT_SECRET='your-kong-mcp-gateway-client-secret'
        ```

        {% endnavtab %}
        {% navtab "Keycloak" %}

        You need a Keycloak realm with admin access, for example a realm named `mcp-demo`.

        **Create the Kong MCP Gateway client**

        This confidential client represents Kong. Only confidential clients can call Keycloak's introspection endpoint ([Keycloak: OIDC endpoints](https://www.keycloak.org/securing-apps/oidc-layers)).

        1. In the Keycloak Admin Console, click **Clients**, then **Create client**.
        1. Set **Client ID** to `kong-mcp-gateway` and click **Next**.
        1. Turn on **Client authentication**, then click **Save**.
        1. On the **Credentials** tab, copy the **Client Secret**.

        **Create the MCP Client**

        This public client represents Insomnia.

        1. Click **Clients**, then **Create client**.
        1. Set **Client ID** to `mcp-client` and click **Next**.
        1. Keep **Client authentication** off, keep **Standard flow** on, and set **PKCE Method** to **S256**. Without a PKCE method, Keycloak accepts the client's requests without PKCE ([Keycloak: Server Administration Guide](https://www.keycloak.org/docs/latest/server_admin/index.html)).
        1. Set **Valid redirect URIs** to `https://app.insomnia.rest/oauth/redirect`, then click **Save**.

        **Add Kong to the token audience**

        Keycloak's introspection endpoint answers only a client that is in the token's `aud` claim. Add the `kong-mcp-gateway` client to the audience of the tokens issued to `mcp-client`:

        1. Open the `mcp-client` client, click the **Client scopes** tab, and click `mcp-client-dedicated`.
        1. Click **Configure a new mapper** and select **Audience**.
        1. Set **Name** to `kong-mcp-gateway-audience`, set **Included Client Audience** to `kong-mcp-gateway`, keep **Add to access token** on, and click **Save**.

        **Create a test user**

        Go to **Users** and add a user, for example `mcp-test-user`, or pick an existing one. On the **Credentials** tab, set a password and turn off **Temporary**.

        **Export the Keycloak values**

        Export the realm's issuer URL, its introspection endpoint, and the `kong-mcp-gateway` credentials:

        ```bash
        export OAUTH_AUTH_SERVER='https://your-keycloak-host/realms/mcp-demo'
        export OAUTH_INTROSPECTION_URL='https://your-keycloak-host/realms/mcp-demo/protocol/openid-connect/token/introspect'
        export OAUTH_CLIENT_ID='kong-mcp-gateway'
        export OAUTH_CLIENT_SECRET='your-kong-mcp-gateway-client-secret'
        ```

        {% endnavtab %}
        {% endnavtabs %}
    - title: "{{site.konnect_short_name}} MCP"
      content: |
        Kong calls the [{{site.konnect_short_name}} MCP server](/konnect-platform/konnect-mcp/) with a stored {{site.konnect_short_name}} credential. The server accepts a personal access token or a [system account access token](/konnect-api/#system-accounts-and-access-tokens).

        1. Export the server URL:

           ```bash
           export KONNECT_MCP_HOST='https://global.mcp.konghq.com'
           ```

        1. Export the credential as the complete header that Kong adds to each request. This cookbook reuses your personal access token:

           ```bash
           export KONNECT_MCP_TOKEN="Authorization:Bearer ${KONNECT_TOKEN}"
           ```

        A personal access token has the permissions of the user who created it. In production, use a system account access token with only the permissions the MCP tools need.
    - title: Insomnia
      content: |
        This tutorial uses [Insomnia](https://insomnia.rest/) as the MCP client. Insomnia connects to MCP servers and runs the OAuth flow that MCP servers advertise ([MCP clients in Insomnia](/insomnia/mcp-clients-in-insomnia/)).

        Install the latest version of Insomnia from [insomnia.rest/download](https://insomnia.rest/download).
overview: |
  Put {{site.ai_gateway_name}} in front of third-party MCP servers, so that you identify each caller, control which tools they can call, and keep shared upstream credentials out of client configuration. You'll set up:

  * A GitHub MCP endpoint that identifies each caller with an AI Consumer key and limits developers to read-only GitHub tools
  * A {{site.konnect_short_name}} MCP endpoint that authenticates users through Okta or Keycloak and calls {{site.konnect_short_name}} with a stored credential
  * One place for MCP access rules and MCP traffic logs

  For MCP servers that your own teams build, see the [Secure Internal MCP Gateway cookbook](/cookbooks/secure-internal-mcp-gateway/).
---

## What this cookbook solves

Most teams connect AI agents directly to third-party MCP servers, each with its own tokens and its own tool catalog, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Third-party MCP servers often issue opaque tokens. A gateway can't read a user or a group from them, so it can't apply access rules."
    solution: "A Key Auth AI Auth Strategy identifies the caller with an AI Consumer key, next to the GitHub token. The AI Consumer's group decides which tools the caller can use."
  - problem: "Each agent gets every tool that the upstream token allows. A developer's agent can merge pull requests as easily as it can search code."
    solution: "Tool ACLs on the AI MCP Server limit the developer AI Consumer Group to read-only GitHub tools. Kong removes the other tools from `tools/list` and rejects calls to them."
  - problem: "Each developer manages their own token for each MCP server, so there's no central place to revoke access or rotate a shared credential."
    solution: "For {{site.konnect_short_name}} MCP, users sign in with your IdP. An OpenID Connect AI Auth Strategy validates their token, and a Request Transformer Advanced Policy replaces it with one stored {{site.konnect_short_name}} credential."
  - problem: "Agents call MCP servers directly, so there's no record of which tools people call."
    solution: "Both AI MCP Servers log payloads and ACL decisions, and their traffic shows in {{site.konnect_short_name}} analytics."
{% endtable %}

## Try it out

Apply the configuration, connect Insomnia to both MCP endpoints, then compare the GitHub tools that a developer and an admin get and call a {{site.konnect_short_name}} MCP tool through the token swap.

### Apply the Kong configuration

The configuration creates a Key Auth AI Auth Strategy, two AI Consumers with demo API keys, two AI Consumer Groups (`secure-external-mcp-gateway-admin` and `secure-external-mcp-gateway-developer`), an OpenID Connect AI Auth Strategy for your IdP, a [Request Transformer Advanced](/ai-gateway/policies/request-transformer-advanced/) Policy, and two [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/): one for GitHub MCP and one for {{site.konnect_short_name}} MCP. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the demo API keys of the admin and developer AI Consumers. The credential's `api_key` field is write-only, so its value must come from an environment variable, even for a fixed demo key:

```bash
export ADMIN_API_KEY='admin-api-key'
export DEV_API_KEY='dev-api-key'
```

The IdP values and the {{site.konnect_short_name}} MCP values come from the prerequisites. The same configuration works with Okta and Keycloak. Apply the Kong configuration:

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
    issuer: !env 'OAUTH_AUTH_SERVER'
    introspection_endpoint: !env 'OAUTH_INTROSPECTION_URL'
    client_id:
    - !env 'OAUTH_CLIENT_ID'
    client_secret:
    - !secret {source: !env 'OAUTH_CLIENT_SECRET'}
    auth_methods:
    - introspection
    cache_introspection: true
    cache_tokens_salt: secure-external-mcp-gateway-oidc-cache
    ssl_verify: true
    hide_credentials: true
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
    api_key: !secret {source: !env 'ADMIN_API_KEY'}
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
    api_key: !secret {source: !env 'DEV_API_KEY'}
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
      - !env 'KONNECT_MCP_TOKEN'
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
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
        - secure-external-mcp-gateway-developer
  - name: get_file_contents
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
        - secure-external-mcp-gateway-developer
  - name: list_issues
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
        - secure-external-mcp-gateway-developer
  - name: list_pull_requests
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
        - secure-external-mcp-gateway-developer
  - name: search_users
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
        - secure-external-mcp-gateway-developer
  - name: search_code
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
        - secure-external-mcp-gateway-developer
  - name: issue_write
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
  - name: push_files
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
  - name: create_pull_request
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
  - name: merge_pull_request
    access:
      acls:
        allow:
        - secure-external-mcp-gateway-admin
  - name: create_repository
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
      - !env 'OAUTH_AUTH_SERVER'
      scopes_supported:
      - openid
      endpoint: /.well-known/oauth-protected-resource/konnect-mcp
  config:
    url: !env 'KONNECT_MCP_HOST'
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

### Connect Insomnia to GitHub MCP

Create an MCP client in Insomnia for the GitHub route. The client sends two credentials: the `apikey` header identifies the AI Consumer for Kong, and the GitHub token from the OAuth flow authenticates the user to GitHub.

{:.warning}
> The {{site.konnect_short_name}} MCP server rejects traffic that reaches Kong over HTTP, so this cookbook uses the data plane's HTTPS listener at `https://localhost:8443`, which has a self-signed certificate. In each Insomnia MCP client, click **Manage Certificates** and turn off **SSL Certificate Validation** under **Extra Options**. The setting applies to that MCP client only.

1. In Insomnia, click **MCP Clients** in the left pane, name the client `GitHub MCP`, and click **Create**.
1. In **MCP Server URL**, enter `https://localhost:8443/github-mcp`.
1. Click the **Headers** tab and add the header `apikey` with the value `dev-api-key`.
1. Click the **Auth** tab, select **OAuth 2.0**, and set **Grant Type** to **MCP Auth Flow**.
1. Enter the **Client ID** and **Client Secret** of your GitHub OAuth App.
1. Under **Advanced Options**, set **Scope** to `repo read:user read:org`. GitHub issues a token with no scopes when the request has none, and the GitHub MCP server then rejects tool calls.
1. Click **Connect**. Kong forwards the first request to GitHub, which answers with `401` and its protected resource metadata. Insomnia opens GitHub in your browser.
1. Sign in to GitHub and authorize the application. Insomnia stores the token and connects.

If Insomnia doesn't start the GitHub sign-in, set **Grant Type** to **Authorization Code**, set **Authorization URL** to `https://github.com/login/oauth/authorize` and **Access Token URL** to `https://github.com/login/oauth/access_token`, and keep the same Client ID, Client Secret, and Scope. This cookbook hasn't confirmed the discovery through Kong against a live {{site.ai_gateway}}.

### Compare developer and admin tools

The left pane lists the tools that Kong returns for the `dev-api-key` AI Consumer. The developer AI Consumer Group gets six read-only tools: `search_repositories`, `get_file_contents`, `list_issues`, `list_pull_requests`, `search_users`, and `search_code`.

1. Call `search_repositories` with the query `kong language:go`. The response contains GitHub's search results.
1. Click the **Headers** tab, change the `apikey` value to `admin-api-key`, and reconnect.

The admin AI Consumer Group gets each tool that the GitHub MCP server offers, including the write tools `issue_write`, `push_files`, `create_pull_request`, `merge_pull_request`, and `create_repository`.

If a client calls a tool that its AI Consumer Group can't use, Kong rejects the `tools/call` request with `403 Forbidden` before it reaches GitHub ([ACL evaluation logic](/ai-gateway/entities/ai-mcp-server/#acl-evaluation-logic)).

### Call {{site.konnect_short_name}} MCP through the token swap

Create a second MCP client for the {{site.konnect_short_name}} route. This route needs no `apikey` header. Kong identifies the user from the IdP token.

1. Click **MCP Clients**, name the client `Konnect MCP`, and click **Create**.
1. In **MCP Server URL**, enter `https://localhost:8443/konnect-mcp`, and turn off **SSL Certificate Validation** in **Manage Certificates**.
1. Click the **Auth** tab, select **OAuth 2.0**, set **Grant Type** to **MCP Auth Flow**, and enter the Client ID of the `MCP Client` application (Okta) or `mcp-client` (Keycloak). Leave **Client Secret** empty.
1. Click **Connect**. Kong answers with `401` and a link to its own protected resource metadata, which names your IdP as the authorization server. Insomnia opens your IdP in the browser.
1. Sign in as your test user. Insomnia connects with the IdP token.
1. Call a read-only tool from the list, for example one that lists your control planes.

Kong validates the IdP token, removes it, and adds the stored {{site.konnect_short_name}} credential, so the response comes from {{site.konnect_short_name}} with the permissions of `KONNECT_MCP_TOKEN`. This cookbook hasn't confirmed the token swap against a live {{site.ai_gateway}}.

### Check the results

The Insomnia sessions confirm the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "AI Consumer identification next to the GitHub token"
    evidence: "The GitHub MCP client connects only with a valid `apikey` header and a GitHub token."
  - behavior: "Tool ACLs for each AI Consumer Group"
    evidence: "With `dev-api-key`, the tool list has six read-only tools. With `admin-api-key`, it also has the write tools."
  - behavior: "IdP sign-in through protected resource metadata"
    evidence: "The {{site.konnect_short_name}} MCP client gets a `401` from Kong, then opens your IdP's sign-in page."
  - behavior: "Token swap"
    evidence: "{{site.konnect_short_name}} MCP tools return data for the stored credential, although Insomnia only holds an IdP token."
{% endtable %}

To review the created entities and the MCP traffic, open the `secure-external-mcp-gateway-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Each route has its own AI MCP Server in `passthrough-listener` mode, which forwards MCP traffic to the upstream MCP server without converting tools. The GitHub route authenticates the AI Consumer with an API key and leaves the GitHub token in place. The {{site.konnect_short_name}} route authenticates the user with your IdP and replaces the user's token with a stored credential.

The following diagram shows the GitHub route:

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP Client
    participant K as Kong AI Gateway
    participant GH as GitHub

    C->>K: MCP request with apikey, no GitHub token
    activate K
    K->>K: Key Auth AI Auth Strategy (else 401)
    K->>GH: Forwarded request
    activate GH
    GH-->>K: 401 and GitHub protected resource metadata
    deactivate GH
    K-->>C: 401 from GitHub
    deactivate K
    C->>GH: OAuth sign-in with Client ID and Client Secret
    activate GH
    GH-->>C: GitHub token
    deactivate GH
    C->>K: MCP request with apikey and GitHub token
    activate K
    K->>K: Key Auth AI Auth Strategy (else 401)
    K->>K: Tool ACL for the AI Consumer Group (else 403)
    K->>GH: Request with the GitHub token
    activate GH
    GH-->>K: MCP response
    deactivate GH
    K-->>C: MCP response
    deactivate K
{% endmermaid %}
<!-- vale on -->

The following diagram shows the {{site.konnect_short_name}} route:

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP Client
    participant K as Kong AI Gateway
    participant I as Identity Provider
    participant KM as Konnect MCP

    C->>K: MCP request, no token
    activate K
    K-->>C: 401 and Kong protected resource metadata
    deactivate K
    C->>I: Authorization Code with PKCE
    activate I
    I-->>C: Access token
    deactivate I
    C->>K: MCP request with the IdP token
    activate K
    K->>I: Introspect the token (else 401)
    activate I
    I-->>K: Token claims
    deactivate I
    K->>K: Remove the IdP token, add the stored Konnect credential
    K->>KM: Request with the stored credential
    activate KM
    KM-->>K: MCP response
    deactivate KM
    K-->>C: MCP response
    deactivate K
{% endmermaid %}
<!-- vale on -->

### Key Auth AI Auth Strategy and AI Consumers

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header and maps the key to an AI Consumer. The AI Consumer's group is the identity that the tool ACLs use. The GitHub token travels in the `Authorization` header, which Key Auth doesn't read.

The following settings configure the Key Auth AI Auth Strategy, the AI Consumers, and the AI Consumer Groups:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`key_names: [apikey]`"
    purpose: "Kong reads the AI Consumer key from the `apikey` header, so it doesn't conflict with the GitHub token in `Authorization`."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the `apikey` header before it forwards the request, so GitHub never sees the AI Consumer key."
  - setting: "`credentials[].api_key`"
    purpose: "The demo keys, from `ADMIN_API_KEY` and `DEV_API_KEY`. The field is write-only."
  - setting: "`ai_gateway_consumer_groups[].consumers`"
    purpose: "Puts each AI Consumer in its group: the admin AI Consumer in `secure-external-mcp-gateway-admin`, the developer AI Consumer in `secure-external-mcp-gateway-developer`."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. MCP traffic for each AI Consumer appears in {{site.konnect_short_name}} analytics.

### GitHub AI MCP Server and tool ACLs

The GitHub AI MCP Server forwards MCP traffic to `https://api.githubcopilot.com/mcp`. Its `tools` list names GitHub MCP tools only to attach ACLs to them. Kong doesn't own their schema. A per-tool ACL replaces the default ACL for that tool, so each tool lists every group it allows.

The following settings configure the GitHub AI MCP Server:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`type: passthrough-listener`"
    purpose: "Kong proxies MCP traffic to the upstream server and applies the tool ACLs to `tools/list` and `tools/call`."
  - setting: "`access.auth_strategies`"
    purpose: "Each request needs a valid AI Consumer key."
  - setting: "`access.acl_attribute_type: consumer`"
    purpose: "Kong evaluates the ACLs against the AI Consumer and its AI Consumer Groups."
  - setting: "`access.default_tool_acls.deny`"
    purpose: "Denies the developer AI Consumer Group each tool that has no ACL of its own. Other AI Consumers, including the admin, can call those tools."
  - setting: "`tools[].access.acls.allow`"
    purpose: "The AI Consumer Groups that can call the tool. Read-only tools allow both groups. Write tools allow only the admin group."
  - setting: "`config.url`"
    purpose: "GitHub's remote MCP server."
  - setting: "`config.route.paths: [/github-mcp]` and `strip_path: true`"
    purpose: "Clients call `/github-mcp`, and Kong removes the path before it adds the upstream path `/mcp`."
  - setting: "`config.route.request_buffering` and `response_buffering: false`"
    purpose: "Kong streams requests and responses instead of buffering them, so MCP streams aren't delayed."
  - setting: "`config.logging.payloads` and `audits: true`"
    purpose: "Kong logs MCP payloads and an audit entry for each ACL decision."
  - setting: "`config.max_request_body_size: 10485760`"
    purpose: "Accepts request bodies up to 10 MB, instead of the 8 MB default, for tool calls with file contents."
{% endtable %}

The tools that the cookbook lists have the following access:

{% table %}
columns:
  - title: Tool
    key: tool
  - title: Admin
    key: admin
  - title: Developer
    key: developer
rows:
  - tool: "`search_repositories`, `get_file_contents`, `list_issues`, `list_pull_requests`, `search_users`, `search_code`"
    admin: "Allowed"
    developer: "Allowed"
  - tool: "`issue_write`, `push_files`, `create_pull_request`, `merge_pull_request`, `create_repository`"
    admin: "Allowed"
    developer: "Denied"
  - tool: "Each other GitHub MCP tool"
    admin: "Allowed"
    developer: "Denied"
{% endtable %}

### OpenID Connect AI Auth Strategy

The OpenID Connect AI Auth Strategy validates the IdP token on the {{site.konnect_short_name}} route by calling your IdP's introspection endpoint. Because the AI MCP Server also sets `access.metadata`, {{site.ai_gateway}} adds the OAuth resource server behavior that MCP clients expect: it serves protected resource metadata and challenges requests that have no token ([Protected resource metadata](/ai-gateway/entities/ai-mcp-server/#protected-resource-metadata)).

The following settings configure the OpenID Connect AI Auth Strategy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`issuer`"
    purpose: "Your IdP's authorization server, from `OAUTH_AUTH_SERVER`."
  - setting: "`auth_methods: [introspection]`"
    purpose: "Kong validates the token with the introspection endpoint, so the IdP can issue opaque tokens."
  - setting: "`introspection_endpoint`, `client_id`, and `client_secret`"
    purpose: "The introspection endpoint and the Kong MCP Gateway client's credentials. `client_id` and `client_secret` are lists."
  - setting: "`cache_introspection: true`"
    purpose: "Kong caches introspection results, so it doesn't call the IdP for each request."
  - setting: "`cache_tokens_salt`"
    purpose: "A stable, non-secret value for the token cache keys."
  - setting: "`consumer_optional: true`"
    purpose: "Any authenticated IdP user can call the route without an AI Consumer. The AI Auth Strategy sets `consumer_groups_claim` and no `consumer_claims`: Konnect accepts only one of the two."
  - setting: "`consumer_groups_claim: [groups]` and `consumer_groups_optional: true`"
    purpose: "Kong maps a `groups` claim to AI Consumer Groups when the token has one, and doesn't reject tokens without it."
  - setting: "`credential_claim: [sub]`"
    purpose: "Kong identifies a caller without an AI Consumer by the `sub` claim."
  - setting: "`ssl_verify: true`"
    purpose: "Kong verifies the IdP's TLS certificate."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the IdP token before it forwards the request, so the token never reaches {{site.konnect_short_name}}."
{% endtable %}

### Konnect AI MCP Server and token swap

The {{site.konnect_short_name}} AI MCP Server forwards MCP traffic to `KONNECT_MCP_HOST` and advertises your IdP in its protected resource metadata. Its Request Transformer Advanced Policy runs after the OpenID Connect AI Auth Strategy and adds the stored {{site.konnect_short_name}} credential to the request.

The following settings configure the {{site.konnect_short_name}} AI MCP Server and the Request Transformer Advanced Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`access.metadata.resource`"
    purpose: "The URL that MCP clients use for this route, `https://localhost:8443/konnect-mcp`."
  - setting: "`access.metadata.authorization_servers` and `scopes_supported`"
    purpose: "Your IdP and the `openid` scope, which MCP clients read from the metadata to start the sign-in."
  - setting: "`access.metadata.endpoint`"
    purpose: "The path of the metadata document. {{site.ai_gateway}} adds it to the route."
  - setting: "`config.url`"
    purpose: "The {{site.konnect_short_name}} MCP server, from `KONNECT_MCP_HOST`."
  - setting: "`policies`"
    purpose: "Attaches the Request Transformer Advanced Policy to this AI MCP Server only."
  - setting: "`config.add.headers` (Request Transformer Advanced Policy)"
    purpose: "Adds the header in `KONNECT_MCP_TOKEN`. A kongctl `!env` tag replaces the whole value, so the variable holds the complete `Authorization:Bearer <token>` string."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer keys, the IdP client secret, and the {{site.konnect_short_name}} credential in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

## Variations and next steps

You can change or extend this configuration in the following ways:

{% table %}
columns:
  - title: Variation
    key: variation
  - title: How
    key: how
rows:
  - variation: "Add ACLs for more GitHub tools"
    how: "Add entries to the GitHub AI MCP Server's `tools` list with the AI Consumer Groups that can call each tool. Tools without an entry follow `access.default_tool_acls`."
  - variation: "Use a system account access token"
    how: "Create a [system account access token](/konnect-api/#system-accounts-and-access-tokens) with only the permissions the {{site.konnect_short_name}} MCP tools need, set `KONNECT_MCP_TOKEN` to `Authorization:Bearer <token>`, and apply again."
  - variation: "Restrict {{site.konnect_short_name}} MCP tools by group"
    how: "Add a `groups` claim in your IdP, create AI Consumer Groups with the same names, and add `tools[].access.acls` to the {{site.konnect_short_name}} AI MCP Server. The [Secure Internal MCP Gateway cookbook](/cookbooks/secure-internal-mcp-gateway/) shows the pattern."
  - variation: "Limit MCP calls"
    how: "Set `rate_limiting` on a `passthrough-listener` AI MCP Server to cap requests for an MCP method or a tool. See [Rate limiting](/ai-gateway/entities/ai-mcp-server/#rate-limiting)."
  - variation: "Connect another MCP client"
    how: "Add the client's OAuth redirect URL to the GitHub OAuth App and to your IdP's MCP client application. For GitHub, the client must accept a Client ID and a Client Secret and send the `apikey` header."
  - variation: "Proxy another external MCP server"
    how: "Add a `passthrough-listener` AI MCP Server with the provider's MCP URL in `config.url` and reference the same Key Auth AI Auth Strategy. The AI Consumers and AI Consumer Groups don't change."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='secure-external-mcp-gateway-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

In Insomnia, delete the `GitHub MCP` and `Konnect MCP` MCP clients. On GitHub, delete the `Kong MCP Client` OAuth App, and in your IdP, delete the two applications that you created.
