---
title: Get started with the {{site.identity}} Token Vault
permalink: /how-to/get-started-with-token-vault/
content_type: how_to
breadcrumbs:
  - /identity/
products:
  - identity
works_on:
  - konnect
tags:
  - authentication
  - kong-identity
description: Learn how to enable the {{site.identity}} Token Vault, register a vault key, trust a corporate IdP, and add a GitHub provider.
automated_tests: false

tldr:
  q: How do I get started with the {{site.identity}} Token Vault?
  a: |
    Enable the Token Vault on your {{site.identity}} directory with `vault_enabled`, register a public vault key, add your corporate IdP as the directory's trusted IdP, and add a provider for the third-party service, such as GitHub, using a provider template.

prereqs:
  inline:
    - title: "{{site.identity}} directory"
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/identity.svg
    - title: Corporate IdP
      content: |
        You need admin access to an IdP that issues signed JWTs, such as Okta, and its issuer URL. Export them as follows:

        ```sh
        export ISSUER_URL='https://YOUR_OKTA_DOMAIN/oauth2/default'
        export JWKS_URI='https://YOUR_OKTA_DOMAIN/oauth2/default/v1/keys'
        ```
      
      icon_url: /assets/icons/identity.svg
    - title: GitHub OAuth app
      content: |
        [Create an OAuth app in GitHub](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app).
        
        1. Set the following values for demo purposes:
        
        * **Homepage URL:** `https://cloud.konghq.com`
        * **Redirect URI:** `http://localhost:8000/_vault/callback`
        
        1. Export its client ID and secret:

        ```sh
        export GITHUB_CLIENT_ID='YOUR-CLIENT-ID'
        export GITHUB_CLIENT_SECRET='YOUR-CLIENT-SECRET'
        ```

        
      icon_url: /assets/icons/github.svg

related_resources:
  - text: "{{site.identity}} Token Vault"
    url: /identity/token-vault/
  - text: Principals and directories
    url: /identity/principals/
  - text: "{{site.identity}} authorization servers, claims, scopes, and clients"
    url: /identity/auth-servers/
---

This guide walks you through the Token Vault configuration workflow to use third-party services, such as GitHub, as upstream authentication providers for {{site.ai_gateway}}. You enable the Token Vault on a directory, register a vault key, trust your corporate IdP, add a provider, and validate that the provider is available.

## Enable the Token Vault on a directory

Send a `PATCH` request to the `/v2/directories/{directoryId}` endpoint with `vault_enabled` set to `true`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID
status_code: 200
method: PATCH
body:
  vault_enabled: true
{% endkonnect_api_request %}
<!--vale on-->

`PATCH` is a partial update, so any field you omit keeps its current value. You only need to send `vault_enabled`.

Confirm the vault is enabled by sending a `GET` request to the same endpoint and capturing the `vault_enabled` field:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID
status_code: 200
method: GET
capture:
  - variable: VAULT_ENABLED
    jq: ".vault_enabled"
{% endkonnect_api_request %}
<!--vale on-->

Print the captured value. It returns `true` when the Token Vault is active on the directory:

```sh
echo $VAULT_ENABLED
```

## Add a trusted IdP

Send a `POST` request to the `/v2/directories/{directoryId}/trusted-idps` endpoint. The `issuer_url` must be unique within the directory, so a `POST` reusing an existing issuer returns a `409`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/trusted-idps
status_code: 201
method: POST
body:
  issuer_url: $ISSUER_URL
  jwks_uri: $JWKS_URI
  display_name: Okta
  vault_access_enabled: true
{% endkonnect_api_request %}
<!--vale on-->

The `issuer_url` must match the `iss` claim of your IdP's tokens exactly. If you omit `jwks_uri`, {{site.identity}} discovers it from the issuer's `/.well-known/openid-configuration` document. 

For all the available parameters, see [Trusted IdP](/identity/token-vault/#trusted-idp).

Verify the configuration by sending a `GET` request to the same endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/trusted-idps
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

## Add a provider

Send a `POST` request to the `/v2/directories/{directoryId}/vault/providers` endpoint to create a provider from the `github` template:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers
status_code: 201
method: POST
body:
  template_name: github
  name: github-prod
  client_id: $GITHUB_CLIENT_ID
  client_secret: $GITHUB_CLIENT_SECRET
  scopes:
    - repo
    - read:user
capture:
  - variable: PROVIDER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Validate the setup

Confirm that the Token Vault contains the provider:

List the providers registered for the directory. The response includes `github-prod`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

Check that the provider is enabled by sending a `GET` request to the provider endpoint, using the `PROVIDER_ID` captured when you added it. 
The response contains `"enabled": true`, `"template_name": "github"`, and `"credential_type": "user"`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers/$PROVIDER_ID
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->


## Register a vault key


Before users can enroll to an AI service like MCP servers, you need to upload an encryption key to the Token Vault.

The Token Vault encrypts every credential it stores with a public key that you register on the directory. {{site.identity}} keeps only the public key, and the matching private key stays on the {{site.ai_gateway_name}}, so {{site.identity}} can't decrypt your credentials. {{site.identity}} rejects a request to store a static secret until the directory has a vault key.

1. Generate an RSA key pair. The key must be at least 2048 bits (RSA) or 256 bits (EC):

   ```sh
   openssl genrsa -out vault-private.pem 2048
   openssl rsa -in vault-private.pem -pubout -out vault-public.pem
   ```

   Keep `vault-private.pem` safe. Don't share it or commit it to source control.

1. Export the public key as a single line, with the newlines escaped so it fits in a JSON body:

   ```sh
   export VAULT_PUBLIC_KEY=$(awk 'NF {printf "%s\\n", $0}' vault-public.pem)
   ```

1. Send a `POST` request to the `/v2/directories/{directoryId}/vault/keys` endpoint:

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

A directory can hold up to 5 vault keys, which lets you rotate keys over time.

## Next steps

Users now enroll their GitHub credential the first time an agent calls GitHub through {{site.ai_gateway_name}}. For details, see [Credential enrollment](/identity/token-vault/#credential-enrollment).
After uploading the encryption key, you can see your GitHub provider as an option for authenticating {{site.ai_gateway_name}} services, like MCP servers. For the full configuration, see [AI MCP Server upstream authentication with Token Vault](/ai-gateway/entities/ai-mcp-server/#token-vault).
To disable the provider without deleting it, for example as a kill switch, send a `PATCH` request to `/v2/directories/{directoryId}/vault/providers/{providerId}` with `enabled: false`.
