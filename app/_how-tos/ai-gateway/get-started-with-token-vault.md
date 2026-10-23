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
description: Learn how to enable the {{site.identity}} Token Vault, trust a corporate IdP, and add a GitHub provider.
automated_tests: false

tldr:
  q: How do I get started with the {{site.identity}} Token Vault?
  a: |
    Enable the Token Vault on your {{site.identity}} directory with `vault_enabled`, add your corporate IdP as the directory's trusted IdP, and add a provider for the third-party service, such as GitHub, using a provider template.

prereqs:
  inline:
    - title: "{{site.identity}} directory"
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/identity.svg
    - title: Corporate IdP
      content: |
        You need an IdP that issues signed JWTs, such as Okta, and its issuer URL.
      icon_url: /assets/icons/identity.svg
    - title: GitHub OAuth app
      content: |
        [Create an OAuth app in GitHub](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app) and export its client ID and secret:

        ```sh
        export GITHUB_CLIENT_ID='YOUR-CLIENT-ID'
        export GITHUB_CLIENT_SECRET='YOUR-CLIENT-SECRET'
        ```

        You register the Token Vault callback URL in this app in a later step.
      icon_url: /assets/icons/github.svg

related_resources:
  - text: "{{site.identity}} Token Vault"
    url: /identity/token-vault/
  - text: Principals and directories
    url: /identity/principals/
  - text: "{{site.identity}} authorization servers, claims, scopes, and clients"
    url: /identity/auth-servers/
---

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

Send a `POST` request to the `/v2/directories/{directoryId}/trusted-idps` endpoint. Each directory supports one trusted IdP, so a second `POST` returns a `409`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/trusted-idps
status_code: 201
method: POST
body:
  issuer_url: https://acme.okta.com/oauth2/default
  jwks_uri: https://acme.okta.com/oauth2/default/v1/keys
  display_name: Okta
  vault_access_enabled: true
{% endkonnect_api_request %}
<!--vale on-->

Replace the `issuer_url` and `jwks_uri` with the values for your IdP. If you omit `jwks_uri`, {{site.identity}} discovers it from the issuer's `/.well-known/openid-configuration` document. For all the available parameters, see [Trusted IdP](/identity/token-vault/#trusted-idp).

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
{% endkonnect_api_request %}
<!--vale on-->

For OAuth providers, register the Token Vault callback URL (`https://vault.<konnect-host>/v2/callback`) in the GitHub OAuth app that issued the client ID and secret.

Verify the provider by listing the providers registered for the directory:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

## Next steps

Users now enroll their GitHub credential the first time an agent calls GitHub through {{site.ai_gateway_name}}. For details, see [Credential enrollment](/identity/token-vault/#credential-enrollment).

To disable the provider without deleting it, for example as a kill switch, send a `PATCH` request to `/v2/directories/{directoryId}/vault/providers/{providerId}` with `enabled: false`.
