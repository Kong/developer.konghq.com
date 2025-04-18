---
title: Configure OpenID Connect with Kong Oauth2 token authentication
content_type: how_to

related_resources:
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authentication flows and grants
    url: /plugins/openid-connect/#authentication
  - text: Kong OAuth2 token authentication workflow
    url: /plugins/openid-connect/#kong-oauth-token-auth-flow

plugins:
  - openid-connect
  - oauth2

entities:
  - route
  - service

products:
  - gateway

works_on:
  - on-prem

min_version:
  gateway: '3.4'

tools:
  - deck

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route
  inline:
    - title: Set up Keycloak
      include_content: prereqs/auth/oidc/keycloak-password
      icon_url: /assets/icons/keycloak.svg

tags:
  - authentication
  - openid-connect

description: Set up OpenID Connect to verify tokens issued by Kong OAuth 2.0 plugin against an IdP.

tldr:
  q: How do I use OpenID Connect to verify the tokens issued by the Kong OAauth2 plugin?
  a: Using the OpenID Connect plugin, set up the [OAuth2 authentication workflow](/plugins/openid-connect/#introspection-authentication-workflow) with the OAuth2 plugin to retrieve and verify tokens from {{site.base_gateway}}, then use them with an IdP.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## 1. Create a Consumer with OAuth2 credentials

First, create a Consumer and assign OAuth2 credentials to them. 
We'll use these credentials to generate access tokens.

{% entity_examples %}
entities:
  consumers:
    - username: alex
      oauth2_credentials:
        - client_secret: secret
          hash_secret: true
          name: oauth2-app
{% endentity_examples %}

## 2. Enable the OAuth2 plugin

The [OAuth2 plugin](/plugins/oauth2/) adds an OAuth 2.0 authentication layer in {{site.base_gateway}} and lets you generate access tokens for Consumers.

Apply the OAuth2 plugin to the `example-route` Route you created in the [prerequisites](#prerequisites):

{% entity_examples %}
entities:
  plugins:
    - name: oauth2
      route: example-route
      config:
        global_credentials: true
        enable_client_credentials: true
        provision_key: 
{% endentity_examples %}

## 3. Enable the OpenID Connect plugin with Kong OAuth token authentication

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin with Kong OAuth token authentication.

Enable the OpenID Connect plugin on the `example-service` Service:

{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      service: example-service
      config:
        issuer: ${issuer}
        client_id:
        - ${client-id}
        client_secret:
        - ${client-secret}
        client_auth:
        - client_secret_post
        auth_methods:
        - kong_oauth2
        bearer_token_param_type:
        - header
variables:
  issuer:
    value: $ISSUER
  client-id:
    value: $CLIENT_ID
  client-secret:
    value: $CLIENT_SECRET
{% endentity_examples %}

In this example:
* `issuer`, `client ID`, `client secret`, and `client auth`: Settings that connect the plugin to your IdP (in this case, the sample Keycloak app).
* `auth_methods`: Kong OAuth2 token.
* `bearer_token_param_type`: We want to search for the token in headers only.

{% include_cached plugins/oidc/client-auth.md %}

## 4. Validate the token

Retreive the token from the OAuth token endpoint:

```sh
curl -i -X POST --insecure https://localhost:8443/anything/oauth2/token \
  --data "client_id=client" \
  --data "client_secret=secret" \
  --data "grant_type=client_credentials"
```

You should get an HTTP 200 response with the token in the `access_token` field. Export the access token to an environment varible:

```
export TOKEN=hAilsJRB8et8WBZyNBg2MrC9ZUqT1rO2
```

At this point you have created a Gateway Service, routed traffic to the Service, enabled the OpenID Connect plugin, and retrieved the bearer token. 
Access the `example-route` Route by passing the token you retrieved from the Kong OAuth plugin:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
display_headers: true
headers:
  - "Authorization: Bearer $TOKEN"
{% endvalidation %}

{% include_cached plugins/oidc/cache.md %}