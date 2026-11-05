---
title: Authenticate to the GitHub MCP server with the {{site.identity}} Token Vault
permalink: /ai-gateway/use-token-vault-with-github-mcp-server/
content_type: how_to
description: ""

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
    <!-- TODO -->

tools:
  - konnect-api

prereqs:
  konnect:
    - name: TOKEN_VAULT_PRIVATE_KEY
  inline:
    - title: Vault encryption key
      position: before
      include_content: prereqs/token-vault-encryption-key
      icon_url: /assets/icons/identity.svg
    - title: "{{site.identity}} directory"
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/identity.svg
    - title: "{{site.identity}} Token Vault"
      include_content: prereqs/token-vault-directory
      icon_url: /assets/icons/identity.svg
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
           export OKTA_CLIENT_ID='YOUR-OKTA-CLIENT-ID'
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
           export GITHUB_CLIENT_ID='YOUR-CLIENT-ID'
           export GITHUB_CLIENT_SECRET='YOUR-CLIENT-SECRET'
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

## Register a vault key

1. Export the public key, with the newlines escaped so it fits in a JSON body:

   ```sh
   export VAULT_PUBLIC_KEY=$(awk 'NF {printf "%s\\n", $0}' vault-public.pem)
   ```

1. Register the key:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/keys
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: my-vault-key
  public_key: $VAULT_PUBLIC_KEY
capture:
  - variable: VAULT_KEY_ID
    jq: ".id"
  - variable: VAULT_KEY_KID
    jq: ".kid"
{% endkonnect_api_request %}
<!--vale on-->

## Create a Token Vault Datastore

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/datastores
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: token-vault-datastore
  display_name: Token Vault Datastore
  type: token-vault
  config:
    directory: $DIRECTORY_NAME
    current_version: $VAULT_KEY_KID
    keys:
      - version: $VAULT_KEY_KID
        key: "{vault://env/TOKEN_VAULT_PRIVATE_KEY}"
{% endkonnect_api_request %}
<!--vale on-->

## Create the GitHub provider

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

## Create an AI Auth Strategy for Okta

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

## Create the AI MCP Server

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

1. List the MCP server's tools. Before enrollment, the server returns the `authenticate` and `check_authentication_status` tools only.

1. Call `authenticate`, then open the returned URL and approve GitHub's consent screen.

1. Call `check_authentication_status`.

1. Reload the tool list with `/mcp`. The GitHub MCP server's tools now appear.

1. List the credentials stored for the GitHub provider:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers/$PROVIDER_ID/credentials
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

   The response contains one `user` credential with `status: active` for the Okta user's principal.
