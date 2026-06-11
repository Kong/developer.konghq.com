---
title: Configure OpenID Connect with multiple IdPs using a trusted issuer registry
permalink: /how-to/configure-oidc-with-multi-idp/
content_type: how_to
description: Learn how to configure the OpenID Connect plugin to validate tokens from multiple identity providers using a trusted issuer registry.

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: Multi-IdP token validation at the gateway layer
    url: /plugins/openid-connect/multi-idp/
  - text: Configure OpenID Connect with token exchange
    url: /how-to/configure-oidc-with-token-exchange/
  - text: OpenID Connect tutorials
    url: /how-to/?query=openid-connect

plugins:
  - openid-connect

entities:
  - route
  - service
  - plugin

products:
  - gateway

works_on:
  - on-prem
  - konnect

tools:
  - deck

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route
  inline:
    - title: Set up Keycloak with two realms
      include_content: prereqs/auth/oidc/keycloak-multi-idp
      icon_url: /assets/icons/keycloak.svg

tags:
  - authentication
  - openid-connect
search_aliases:
  - oidc
  - multi-idp
  - multiple identity providers

tldr:
  q: How do I configure {{site.base_gateway}} to accept tokens from multiple identity providers on the same route?
  a: |
    Configure the OpenID Connect plugin with `extra_jwks_uris` listing each IdP's JWKS endpoint and `issuers_allowed` listing each IdP's issuer URL.
    Set `verify_claims` to `false` so that the `iss` claim is checked against `issuers_allowed` rather than requiring it to match `config.issuer`.
    {{site.base_gateway}} validates incoming tokens against the matching JWKS and forwards them to the upstream without transformation.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

## Generate salt token

{% include how-tos/steps/deck-salt-token.md %}

## Enable the OpenID Connect plugin for multiple IdPs

Using the Keycloak configuration from the [prerequisites](#prerequisites), configure the OpenID Connect plugin on `example-route` to accept tokens from both realms:

{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      route: example-route
      config:
        issuer: ${realm-a-issuer}
        using_pseudo_issuer: true
        jwks_endpoint: ${realm-a-jwks}
        auth_methods:
          - bearer
        extra_jwks_uris:
          - ${realm-b-jwks}
        issuers_allowed:
          - ${realm-a-issuer}
          - ${realm-b-issuer}
        verify_signature: true
        verify_claims: false
        cache_tokens_salt: ${salt-token}
variables:
  realm-a-issuer:
    value: $REALM_A_ISSUER
  realm-a-jwks:
    value: $REALM_A_JWKS
  realm-b-jwks:
    value: $REALM_B_JWKS
  realm-b-issuer:
    value: $REALM_B_ISSUER
{% endentity_examples %}

Auth configuration:
* `issuer`: The primary IdP URL, used for discovery and as the canonical issuer reference.
* `using_pseudo_issuer`: Disables OIDC discovery from the `issuer` URL. Required here because {{site.base_gateway}} runs inside Docker and can't reach `localhost:8080` directly. The `issuer` value is still used to match the `iss` claim in tokens from `realm-a`.
* `jwks_endpoint`: Explicit JWKS endpoint that {{site.base_gateway}} uses to fetch signing keys for `realm-a`. Uses the `keycloak` container name, which is reachable from {{site.base_gateway}} over the shared Docker network.
* `extra_jwks_uris`: The JWKS endpoint for `realm-b`. The plugin checks the primary JWKS first, then falls back to this list.
* `issuers_allowed`: Explicit allowlist of accepted issuers. Tokens whose `iss` claim doesn't match one of these values are rejected.
* `verify_claims`: Set to `false` so that the `iss` claim is checked against `issuers_allowed` instead of requiring it to equal `config.issuer`. Without this, tokens from `realm-b` would fail claim verification.

## Validate the flow

### Token from realm-a

Get a client credentials token from `realm-a`:

```sh
TOKEN_A=$(curl -s -X POST \
  http://$KEYCLOAK_HOST:8080/realms/master/protocol/openid-connect/token \
  -d "grant_type=client_credentials" \
  -d "client_id=client-a" \
  -d "client_secret=$DECK_CLIENT_A_SECRET" | jq -r .access_token) && echo $TOKEN_A
```

Send the token to {{site.base_gateway}}:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
display_headers: true
headers:
  - "Authorization: Bearer $TOKEN_A"
{% endvalidation %}

You should see a `200` response.
When you decode the token in the forwarded `Authorization` header, the `iss` claim should be `http://localhost:8080/realms/master`.

### Token from realm-b

Get a client credentials token from `realm-b`:

```sh
TOKEN_B=$(curl -s -X POST \
  http://$KEYCLOAK_HOST:8080/realms/realm-b/protocol/openid-connect/token \
  -d "grant_type=client_credentials" \
  -d "client_id=client-b" \
  -d "client_secret=$DECK_CLIENT_B_SECRET" | jq -r .access_token) && echo $TOKEN_B
```

Send the token to {{site.base_gateway}}:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
display_headers: true
headers:
  - "Authorization: Bearer $TOKEN_B"
{% endvalidation %}

You should see a `200` response.
When you decode the token in the forwarded `Authorization` header, the `iss` claim should be `http://localhost:8080/realms/realm-b`, confirming that {{site.base_gateway}} accepted the token from the second IdP and forwarded it unchanged.
