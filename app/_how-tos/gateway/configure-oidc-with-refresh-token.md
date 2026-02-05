---
title: Configure OpenID Connect with refresh token
permalink: /how-to/configure-oidc-with-refresh-token/
content_type: how_to

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authentication flows and grants
    url: /plugins/openid-connect/#authentication
  - text: Refresh token grant
    url: /plugins/openid-connect/#refresh-token-grant-workflow
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

description: Set up OpenID Connect with the refresh token grant, which looks for a Refresh-Token header.

tldr:
  q: How do I use a refresh token to authenticate directly with my identity provider?
  a: Using the OpenID Connect plugin, retrieve the refresh token and use it to authenticate with an identity provider (IdP) by passing the refresh token in a `Refresh-Token` header.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Enable the OpenID Connect plugin with refresh tokens

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the [OpenID Connect plugin](/plugins/openid-connect/) with the refresh token grant.

We're also enabling the password grant, as well as a refresh token header, so that we can test retrieving the token.

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
        - refresh_token
        - password
        refresh_token_param_type:
        - header
        refresh_token_param_name: refresh_token
        upstream_refresh_token_header: refresh_token
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
* `auth_methods`: Specifies that the plugin should use the refresh token auth flow and the password grant for authentication.
* `refresh_token_param_type`: Restricts refresh token lookup to request headers only.

{% include_cached plugins/oidc/client-auth.md %}

## Retrieve the refresh token

Check that you can recover the refresh token by requesting the Service with the basic authentication credentials created in the [prerequisites](#prerequisites):

<!-- vale off -->
{% validation request-check %}
url: /anything
method: GET
status_code: 200
user: "alex:doe"
display_headers: true
extract_body:
  - name: 'headers.Refresh-Token'
    variable: 'REFRESH_TOKEN'
{% endvalidation %}
<!-- vale on -->

You should see a `Refresh-Token` header in the response.

Export the token to an environment variable:

```sh
export REFRESH_TOKEN='{your-refresh-token}'
```

## Validate the refresh token grant

Now, validate the setup by accessing the `example-route` Route and passing the refresh token in a `Refresh-Token` header:

<!-- vale off -->
{% validation request-check %}
url: /anything
method: GET
status_code: 200
display_headers: true
headers:
  - "Refresh-Token: $REFRESH_TOKEN"
{% endvalidation %}
<!-- vale on -->

{% include_cached plugins/oidc/cache.md %}

Alternatively, you can use jq to pass the credentials and retrieve the most recent refresh token every time:

<!-- vale off -->
{% validation request-check %}
url: /anything
method: GET
status_code: 200
display_headers: true
headers:
  - |
    Refresh-Token:$(curl --user alex:doe http://localhost:8000/anything \
            | jq -r '.headers."Refresh-Token"')
skip: true
{% endvalidation %}
<!-- vale on -->
