---
title: Configure OpenID Connect with introspection
permalink: /how-to/configure-oidc-with-introspection/
content_type: how_to

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authentication flows and grants
    url: /plugins/openid-connect/#authentication
  - text: Introspection workflow
    url: /plugins/openid-connect/#introspection-authentication-workflow
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

description: Set up OpenID Connect with introspection auth, which retrieves a bearer token from the IdP's introspection endpoint for authentication.

tldr:
  q: How do I retrieve a token using my identity provider's introspection endpoint?
  a: Using the OpenID Connect plugin, set up the [introspection auth workflow](/plugins/openid-connect/#introspection-authentication-workflow) to connect to an identity provider (IdP) to retrieve a token from the IdP's introspection endpoint, then use the token to access the upstream service.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Enable the OpenID Connect plugin with introspection

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin with introspection authentication.
We're also enabling the password grant so that you can test retrieving the auth token for introspection.

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
        - introspection
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
* `auth_methods`:  Specifies that the plugin should use introspection and the password grant for authentication.
* `bearer_token_param_type`: Restricts token lookup to the request headers only.

{% include_cached plugins/oidc/client-auth.md %}

## Retrieve the bearer token using introspection

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

```sh
export TOKEN='YOUR_BEARER_TOKEN'
```

## Validate the token

Now, validate the setup by accessing the `example-route` Route and passing the token you retrieved using introspection:

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