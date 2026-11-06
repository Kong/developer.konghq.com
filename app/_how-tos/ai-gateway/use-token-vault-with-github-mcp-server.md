---
title: Authenticate to a GitHub MCP server with Token Vault and Okta
permalink: /ai-gateway/use-token-vault-with-github-mcp-server/
content_type: how_to
description: Let an AI agent call the GitHub MCP server on behalf of a user through Token Vault, Okta, and an AI MCP Server in {{site.ai_gateway}}.
automated_tests: false

products:
  - ai-gateway
  - identity

works_on:
  - konnect

min_version:
  ai-gateway: '2.3'

entities:
  - ai-mcp-server
  - ai-auth-strategy

tags:
  - ai
  - mcp
  - authentication
  - kong-identity

tldr:
  q: How do I let an AI agent call the GitHub MCP server on behalf of a user without the agent handling a GitHub credential?
  a: |
    Add Okta as a trusted IdP in your {{site.identity}} directory, add a GitHub provider to Token Vault, and create a Token Vault data store in {{site.ai_gateway}}. Then create an `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) for Okta and an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) for GitHub that uses it. Users sign in to Claude Code with Okta and approve GitHub's consent screen once, and {{site.ai_gateway}} then fetches their GitHub token from the vault on each call, so the agent never handles a GitHub credential.


tools:
  - {{site.konnect_product_name}}

prereqs:
  skip_product: true
  inline:
    - title: Kong Konnect
      position: before
      content: "{% include prereqs/products/konnect-auth-only.md raw=true %}"
      icon_url: /assets/icons/gateway.svg
    - title: "{{site.identity}} directory"
      position: before
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/identity.svg
    - title: "{{site.identity}} Token Vault"
      position: before
      include_content: prereqs/token-vault-directory
      icon_url: /assets/icons/identity.svg
    - title: Vault encryption key
      position: before
      include_content: prereqs/token-vault-encryption-key
      icon_url: /assets/icons/identity.svg
    - title: "{{site.ai_gateway}} running"
      position: before
      content: |
        Run the {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) to provision a control plane in {{site.konnect_product_name}} and a local data plane. The `-e` flag passes the vault private key to the data plane:

        ```bash
        curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN \
           -e TOKEN_VAULT_PRIVATE_KEY
        ```

        This sets up a {{site.ai_gateway}} control plane named `ai-quickstart`, provisions a local data plane, and prints the following environment variable exports:

        ```bash
        export AI_GATEWAY_ID=your-gateway-id
        export KONNECT_TOKEN=$KONNECT_TOKEN
        export KONNECT_CONTROL_PLANE_NAME=ai-quickstart
        export KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.com
        export KONNECT_PROXY_URL='http://localhost:8000'
        ```

        Copy and paste these into your terminal to configure your session.
      icon_url: /assets/icons/ai.svg
    - title: Okta as the user IdP
      content: |
        You need admin access to an [Okta](https://login.okta.com/) org, with a custom authorization server and a native OIDC application that the agent uses to sign users in.

        1. Create a native OIDC application with the **Authorization Code** and **Refresh Token** grant types, and the following sign-in redirect URI:

           ```
           http://localhost:61337/callback
           ```

        1. Create a custom authorization server with `http://localhost:8000/github` as its audience, and an access policy that assigns it to the application.

        1. Export the application's client ID and the authorization server's issuer URI:

           ```sh
           export OKTA_CLIENT_ID='YOUR_OKTA_CLIENT_ID'
           export OKTA_ISSUER='https://YOUR_OKTA_DOMAIN/oauth2/YOUR_AUTH_SERVER_ID'
           ```
      icon_url: /assets/icons/okta.svg
    - title: GitHub OAuth app
      content: |
        [Create an OAuth app in GitHub](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app).

        1. Set the following values for demo purposes:

           * **Homepage URL:** `https://cloud.konghq.com`
           * **Authorization callback URL:** `http://localhost:8000/_vault/callback`

        1. Export its client ID and secret:

           ```sh
           export GITHUB_CLIENT_ID='YOUR_GITHUB_CLIENT_ID'
           export GITHUB_CLIENT_SECRET='YOUR_GITHUB_CLIENT_SECRET'
           ```
      icon_url: /assets/icons/github.svg
    - title: AI agent
      include_content: prereqs/claude-code
      icon_url: /assets/icons/ai.svg

related_resources:
  - text: "{{site.identity}} Token Vault"
    url: /identity/token-vault/
  - text: Get started with the {{site.identity}} Token Vault
    url: /how-to/get-started-with-token-vault/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: OpenID Connect authentication with {{site.ai_gateway}} 2.0
    url: /ai-gateway/openid-connect/
  - text: "{{site.identity}} directories"
    url: /identity/directories/

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
    - title: Clean up {{site.identity}} resources
      content: |
        Delete the GitHub provider, the trusted IdP, and the vault key from your directory:

        ```sh
        curl -X DELETE "https://us.api.konghq.com/v2/directories/$DIRECTORY_ID/vault/providers/$PROVIDER_ID" \
          -H "Authorization: Bearer $KONNECT_TOKEN"
        curl -X DELETE "https://us.api.konghq.com/v2/directories/$DIRECTORY_ID/trusted-idps/$TRUSTED_IDP_ID" \
          -H "Authorization: Bearer $KONNECT_TOKEN"
        curl -X DELETE "https://us.api.konghq.com/v2/directories/$DIRECTORY_ID/vault/keys/$VAULT_KEY_ID" \
          -H "Authorization: Bearer $KONNECT_TOKEN"
        rm vault-private.pem vault-public.pem
        ```
        {: data-test-cleanup="block" }

faqs:
  - q: Why does `claude mcp login` send me to `http://localhost:8000/authorize` and return `no Route matched`?
    a: |
      The `claude mcp login` command doesn't use the authorization server that the AI MCP Server advertises in its protected resource metadata. It sends you to `http://localhost:8000/authorize`, which the data plane doesn't serve.

      Sign in from a Claude Code session instead. Run `/mcp` and select the server, and Claude Code redirects you to Okta.
---

## Trust Okta as the identity provider

Tell your {{site.identity}} directory to trust tokens that your Okta authorization server issues. For this, send a `POST` request to the directory's [`trusted-idps` endpoint](/api/konnect/kong-identity-principals/v2/#/operations/createTrustedIdp) with the issuer URL of your Okta authorization server:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/trusted-idps
status_code: 201
method: POST
body:
  issuer_url: $OKTA_ISSUER
  display_name: Okta
  vault_access_enabled: true
  jit_provisioning_enabled: true
capture:
  - variable: TRUSTED_IDP_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

* `vault_access_enabled` lets users who sign in through Okta use the Token Vault.
* `jit_provisioning_enabled` creates a user in the directory the first time someone signs in.

## Create the GitHub provider

Create a GitHub provider in the directory's Token Vault by sending a `POST` request to the [`vault/providers` endpoint](/api/konnect/kong-identity-principals/v2/#/operations/createVaultProvider) with the `github` provider template and your GitHub OAuth app's client ID and secret.

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers
status_code: 201
method: POST
body:
  template_name: github
  name: github
  client_id: $GITHUB_CLIENT_ID
  client_secret: $GITHUB_CLIENT_SECRET
  scopes:
    - repo
    - read:user
  credential_type: user
capture:
  - variable: PROVIDER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a Token Vault data store

Create a data store that tells {{site.ai_gateway}} how to connect to Token Vault. The gateway needs it to retrieve the GitHub tokens that you store in Token Vault:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/datastores
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: token-vault-datastore
  display_name: Token Vault data store
  type: token-vault
  config:
    directory: $DIRECTORY_NAME
    current_version: $VAULT_KEY_KID
    keys:
      - version: $VAULT_KEY_KID
        key: "{vault://env/TOKEN_VAULT_PRIVATE_KEY}"
{% endkonnect_api_request %}
<!--vale on-->

## Create an AI Auth Strategy for Okta

Create an `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) so the gateway can validate the Okta access tokens that users present when they call the GitHub MCP server:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/auth-strategies
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: okta-oidc
  display_name: Okta OIDC
  type: openid-connect
  config:
    issuer: $OKTA_ISSUER
    client_id:
      - $OKTA_CLIENT_ID
    auth_methods:
      - bearer
    scopes:
      - openid
      - offline_access
    cache_tokens_salt: okta-oidc-cache-salt
{% endkonnect_api_request %}
<!--vale on-->

* `issuer` and `client_id` point to your Okta authorization server and the native application that signs users in.
* `auth_methods` accepts the Okta access token as a bearer token.
* `cache_tokens_salt` is required for `openid-connect` AI Auth Strategies. Set it to any unique string, which the gateway uses to build the cache key for token endpoint requests.

## Create the AI MCP Server

Create an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) in `passthrough-listener` mode, which proxies MCP traffic to the GitHub MCP server without converting its tools. The server uses:

* The Okta AI Auth Strategy to authenticate users.
* The Token Vault data store and GitHub provider to get each user's GitHub token.

Send the following request to create the AI MCP Server:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/mcp-servers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: github
  display_name: GitHub
  type: passthrough-listener
  enabled: true
  config:
    url: https://api.githubcopilot.com/mcp/
    route:
      paths:
        - /github
  datastores:
    - name: token-vault-datastore
  token_vault:
    provider: github
  access:
    acl_attribute_type: oauth_access_token
    access_token_claim_field: .sub
    auth_strategies:
      - okta-oidc
    metadata:
      resource: http://localhost:8000/github
      authorization_servers:
        - $OKTA_ISSUER
      scopes_supported:
        - openid
        - offline_access
{% endkonnect_api_request %}
<!--vale on-->

* `config.url` and `config.route.paths` set the upstream GitHub MCP server and the `/github` path that the gateway exposes it on.
* `datastores` and `token_vault.provider` tell the gateway which data store and provider to use when it looks up the user's GitHub token in the Token Vault.
* `access.auth_strategies` references the `okta-oidc` AI Auth Strategy.
* `access.acl_attribute_type` and `access.access_token_claim_field` identify the caller by the `sub` claim of their Okta access token.
* `access.metadata` advertises Okta as the authorization server, so that Claude Code knows where to send users to sign in.

## Connect Claude Code to the AI MCP Server

1. Add the MCP server:

   ```sh
   claude mcp add --transport http \
     --client-id "$OKTA_CLIENT_ID" \
     --callback-port 61337 \
     github-vault-demo "http://localhost:8000/github"
   ```

1. Start a Claude Code session, run `/mcp`, and select `github-vault-demo` to sign in with Okta.

## Validate the setup

1. In your Claude Code session, run `/mcp` and select `github-vault-demo` to list the server's tools. Before enrollment, the server returns only the `authenticate` and `check_authentication_status` tools.

1. Ask Claude Code to call `authenticate`, then open the returned URL and approve GitHub's consent screen.

1. Ask Claude Code to call `check_authentication_status`.

1. Run `/mcp` again to reload the tool list. The GitHub MCP server's tools now appear.

1. [List the credentials](/api/konnect/kong-identity-principals/v2/#/operations/listVaultProviderCredentials) stored for the GitHub provider:

   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/directories/$DIRECTORY_ID/vault/providers/$PROVIDER_ID/credentials
   status_code: 200
   method: GET
   {% endkonnect_api_request %}
   <!--vale on-->

   The response contains one `user` credential with `status: active` for the Okta user's principal.
