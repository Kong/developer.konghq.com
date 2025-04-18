---
title: Configure OpenID Connect with JWT authentication
content_type: how_to

related_resources:
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authentication flows and grants
    url: /plugins/openid-connect/#authentication
  - text: JWT auth flow
    url: /plugins/openid-connect/#jwt-access-token-authentication-flow

plugins:
  - openid-connect

entities:
  - route
  - service

products:
  - gateway

works_on:
  - on-prem
  - konnect

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

description: Set up OpenID Connect with JSON Web Token (JWT) auth, which uses a bearer token for authentication with the IdP.

tldr:
  q: How do I retrieve a JWT token and use it to authenticate with my IdP?
  a: Using the OpenID Connect plugin, set up the [JWT auth workflow](/plugins/openid-connect/#jwt-access-token-authentication-flow) to connect to an identity provider (IdP) and use the validated token to access the upstream service.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

search_aliases:
  - oidc
---

## 1. Enable the OpenID Connect plugin with JWT authentication

Stateless JWT Access Token authentication is named `bearer` in the OpenID Connect plugin.

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin with bearer authentication. 
We're also enabling the password grant so that you can test retrieving the bearer auth token.

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
        - bearer
        - password
        bearer_token_param_type:
        - query
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
* `auth_methods`: Specifies that the plugin should use bearer authentication and the password grant.
* `bearer_token_param_type`: Restricts token lookup to the query string only.

{% include_cached plugins/oidc/client-auth.md %}

## 2. Retrieve the bearer token

Check that you can recover the token by requesting the Service with the basic authentication credentials created in the [prerequisites](#prerequisites):

{% validation request-check %}
url: /anything
method: GET
status_code: 200
user: "alex:doe"
display_headers: true
{% endvalidation %}

You'll see an `Authorization` header with your access token in the response.

When passing the token in a query string, you don't need to include the `Bearer` portion of the token.
Copy the token without `Bearer`, and export the value of the header to an environment variable:

```
export TOKEN='{your-token-without-bearer-prefix}'
```

## 3. Validate the token

Now, validate the setup by accessing the `example-route` Route and passing the bearer token in the query string:

{% validation request-check %}
url: /anything?access_token=$TOKEN
method: GET
status_code: 200
display_headers: true
{% endvalidation %}

{% include_cached plugins/oidc/cache.md %}