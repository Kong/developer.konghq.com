---
title: Configure OpenID Connect with Kong Oauth2 token authentication
permalink: /how-to/configure-oidc-with-kong-oauth2/
content_type: how_to

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authentication flows and grants
    url: /plugins/openid-connect/#authentication
  - text: Kong OAuth2 token authentication workflow
    url: /plugins/openid-connect/#kong-oauth-token-authentication-flow
  - text: OpenID Connect tutorials
    url: /how-to/?query=openid-connect

plugins:
  - openid-connect
  - oauth2

entities:
  - route
  - service
  - plugin

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
search_aliases:
  - oidc

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

## Create a Consumer with OAuth2 credentials

First, create a [Consumer](/gateway/entities/consumer/) and assign OAuth2 credentials to them. 
We'll use these credentials to generate access tokens.

{% entity_examples %}
entities:
  consumers:
    - username: alex
      oauth2_credentials:
        - client_secret: secret
          client_id: client
          hash_secret: true
          name: oauth2-app
{% endentity_examples %}

## Enable the OAuth2 plugin

The [OAuth2 plugin](/plugins/oauth2/) adds an OAuth 2.0 authentication layer to {{site.base_gateway}} and lets you generate access tokens for Consumers.

First, you'll need a key to provision the plugin. Generate a UUID and export it to an environment variable:

{% env_variables %}
DECK_PROVISION_KEY: $(uuidgen)
{% endenv_variables %}


Apply the OAuth2 plugin to the `example-route` Route you created in the [prerequisites](#prerequisites):

{% entity_examples %}
entities:
  plugins:
    - name: oauth2
      route: example-route
      config:
        global_credentials: true
        enable_client_credentials: true
        provision_key: ${key}
variables:
  key:
    value: $PROVISION_KEY
{% endentity_examples %}

## Enable the OpenID Connect plugin with Kong OAuth token authentication

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
* `auth_methods`: Specifies that the plugin should use Kong's OAuth2 token for authentication.
* `bearer_token_param_type`: Restricts token lookup to the request headers only.

{% include_cached plugins/oidc/client-auth.md %}

## Retrieve the access token

Retrieve the token from the OAuth token endpoint:

<!-- vale off -->
{% validation request-check %}
insecure: true
method: POST
url: /anything/oauth2/token
on_prem_url: https://localhost:8443
headers:
  - "Content-Type: application/json"
body:
  client_id: client
  client_secret: secret
  grant_type: client_credentials
extract_body:
  - name: 'access_token'
    variable: ACCESS_TOKEN
status_code: 200
{% endvalidation%}
<!-- vale on -->


You should see an `access-token` in the response.

Export the token to an environment variable:

```
export ACCESS_TOKEN='YOUR_ACCESS_TOKEN'
```

## Validate the access token flow

Now, validate the setup by accessing the `example-route` Route and passing the bearer token you received from the Kong OAuth plugin:

<!-- vale off -->
{% validation request-check %}
url: /anything
method: GET
status_code: 200
display_headers: true
headers:
  - "Authorization: Bearer $ACCESS_TOKEN"
{% endvalidation %}
<!-- vale on -->


{% include_cached plugins/oidc/cache.md %}