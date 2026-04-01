---
title: Configure OpenID Connect with the user info auth flow
permalink: /how-to/configure-oidc-with-user-info-auth/
content_type: how_to

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authentication flows and grants
    url: /plugins/openid-connect/#authentication
  - text: User info auth workflow
    url: /plugins/openid-connect/#user-info-authentication-flow
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
search_aliases:
  - oidc

description: Set up OpenID Connect with the user info auth, which retrieves a bearer token from the IdP's user info endpoint for authentication.

tldr:
  q: How do I use attributes from user info to authenticate directly with my identity provider?
  a: Using the OpenID Connect plugin, retrieve a bearer token from the IdP's user info endpoint and use the token for authentication.
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## Enable the OpenID Connect plugin with user info auth

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin with the user info grant.

We're also enabling the password grant so that you can test retrieving the token.

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
        - userinfo
        - password
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
* `auth_methods`: Specifies that the plugin should use user info authentication with the password grant.
* `bearer_token_param_type`: Restricts token lookup to the request headers only.

{% include_cached plugins/oidc/client-auth.md %}

## Retrieve the bearer token using the user info endpoint

Check that you can recover the token by requesting the Service with the basic authentication credentials created in the [prerequisites](#prerequisites):

<!-- vale off -->
{% validation request-check %}
url: /anything
method: GET
status_code: 200
user: "alex:doe"
display_headers: true
extract_body:
  - name: 'headers.Authorization'
    variable: TOKEN
{% endvalidation %}
<!-- vale on -->


You'll see an `Authorization` header in the response. 

Export the value of the header to an environment variable:

```
export TOKEN='YOUR_BEARER_TOKEN'
```

## Validate the token

Now, validate the setup by accessing the `example-route` Route and passing the token you retrieved through user info:

<!-- vale off -->
{% validation request-check %}
url: /anything
method: GET
status_code: 200
display_headers: true
headers:
  - "Authorization: $TOKEN"
{% endvalidation %}
<!-- vale on -->

{% include_cached plugins/oidc/cache.md %}
