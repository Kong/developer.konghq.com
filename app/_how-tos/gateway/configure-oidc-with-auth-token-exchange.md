---
title: Configure OpenID Connect with token exchange
permalink: /how-to/configure-oidc-with-token-exchange/
content_type: how_to
description: Learn how to configure OpenID Connect with token exchange in Keycloak.

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: Token exchange in OIDC
    url: /plugins/openid-connect/#token-exchange
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

min_version:
  gateway: '3.14'

tools:
  - deck

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route
  inline:
    - title: Set up Keycloak with token exchange
      include_content: prereqs/auth/oidc/keycloak-token-exchange
      icon_url: /assets/icons/keycloak.svg

tags:
  - authentication
  - openid-connect
search_aliases:
  - oidc

tldr:
  q: How do I configure {{site.base_gateway}} to automatically exchange an incoming bearer token for one scoped to a different client?
  a: |
    Configure the OpenID Connect plugin with `token_exchange` settings, using `subject_token_issuers` to define which incoming tokens are eligible for exchange. {{site.base_gateway}} will perform an [OAuth 2.0 token exchange (RFC 8693)](https://curity.io/resources/learn/token-exchange-flow/) with your IdP, replacing the incoming token with a new one issued to a different client before forwarding it upstream.

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

## Enable the OpenID Connect plugin with token exchange

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), configure the OpenID Connect plugin on `example-route` to act as `client-2` and narrow the token scopes:

{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      route: example-route
      config:
        issuer: ${issuer}
        client_id:
          - client-2
        client_secret:
          - ${client-secret-2}
        auth_methods:
          - bearer
        token_exchange:
          subject_token_issuers:
            - issuer: ${issuer}
              conditions:
                has_audience:
                  - client-2
          request:
            scopes:
            - profile
variables:
  issuer:
    value: $ISSUER
  client-secret-2:
    value: $CLIENT_SECRET_2
{% endentity_examples %}

Auth configuration:
* `issuer`, `client ID`, and `client secret`: Settings that connect the plugin to your IdP (in this case, the sample Keycloak app).
* `auth_methods`: Specifies that the plugin should use bearer auth.

In this example, we are also using the following `token_exchange` settings:
* `subject_token_issuers`: Defines which incoming tokens are eligible for exchange. The `issuer` field restricts exchange to tokens from the same IdP, and `conditions.has_audience` further limits it to tokens that carry `client-2` in their `aud` claim, which is the audience we explicitly added via the scope mapper in the [Keycloak setup](#set-up-keycloak-with-token-exchange).
* `request.scopes`: The scopes that the exchanged token should be restricted to, narrowing the original broad-scoped token down to `profile` only.

This tells {{site.base_gateway}} to trigger a token exchange whenever an incoming bearer token was issued by the same IdP and has `client-2` in its `aud` claim, which is the audience we explicitly added via the scope mapper. The exchange requests a new token scoped only to `client-2`.

## Validate the flow

Obtain a token from Keycloak as a `client-1` user, including the `add-client-2-as-audience` optional scope so that `client-2` is added to the audience:

```sh
TOKEN=$(curl -s -X POST \
  http://$KEYCLOAK_HOST:8080/realms/master/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=client-1" \
  -d "client_secret=$DECK_CLIENT_SECRET_1" \
  -d "username=alex" \
  -d "password=doe" \
  -d "scope=openid profile add-client-2-as-audience" | jq -r .access_token) && echo $TOKEN
```

If you decode the token, the resulting access token will have an `aud` claim containing `client-2`, and an `azp` claim with `client-1`:

```sh
{
  "azp": "client-1",
  "aud": ["client-2", "account"],
  "scope": "openid profile email",
  "iss": "http://host.docker.internal:8080/realms/master",
  "exp": 1775253107, "iat": 1775253047
}
```
{:.no_copy_code}

Send the token to {{site.base_gateway}}:

{% validation request-check %}
url: /anything
method: GET
status_code: 302
display_headers: true
headers:
  - "Authorization: Bearer $TOKEN"
{% endvalidation %}

The response shows the Authorization header that {{site.base_gateway}} forwarded to the upstream service. When decoded, the token should look something like this:

```sh
{
  "azp": "client-2",
  "aud": "account",
  "scope": "profile email",
  "iss": "http://host.docker.internal:8080/realms/master",
  "exp": 1775253114, "iat": 1775253054
}
```
{:.no-copy-code}

The token should be a different one, with `azp` set to `client-2`, no `client-1` in `aud`, and scope narrowed to `profile`, confirming the token exchange and scope narrowing took effect.