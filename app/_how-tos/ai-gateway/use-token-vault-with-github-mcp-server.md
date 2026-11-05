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
  inline:
    - title: "{{site.identity}} directory"
      include_content: prereqs/kong-identity-directory
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
      include_content: md/identity/delete_directory
---

## Enable the Token Vault on the directory

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID
status_code: 200
method: PATCH
body:
  vault_enabled: true
{% endkonnect_api_request %}
<!--vale on-->

## Register a vault key

1. Generate a key pair:

   ```sh
   openssl genrsa -out vault-private.pem 2048
   openssl rsa -in vault-private.pem -pubout -out vault-public.pem
   ```

1. Export the public key:

   ```sh
   export VAULT_PUBLIC_KEY=$(awk 'NF {printf "%s\\n", $0}' vault-public.pem)
   export VAULT_PRIVATE_KEY=$(cat vault-private.pem)
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
{% endkonnect_api_request %}
<!--vale on-->

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

## Expose the private key to the data plane

{% env_variables %}
KONG_VAULT_ENC_KEY: $VAULT_PRIVATE_KEY
{% endenv_variables %}

## Create an AI Vault for the private key

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/vaults
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: token-vault-env
  type: env
  config:
    prefix: KONG_
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
    directory: kong-identity-directory
    current_version: v1
    keys:
      - version: v1
        key: "{vault://token-vault-env/vault_enc_key}"
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

1. Sign in with Okta: run `/mcp` in a Claude Code session, or run the following command from your shell:

   ```sh
   claude mcp login github-vault-demo
   ```

## Validate the setup

1. List the MCP server's tools. Before enrollment, the server returns the `authenticate` and `check_authentication_status` tools only.

1. Call `authenticate`, then open the returned URL and approve GitHub's consent screen.

1. Call `check_authentication_status`.

1. Reload the tool list with `/mcp`. The GitHub MCP server's tools now appear.
