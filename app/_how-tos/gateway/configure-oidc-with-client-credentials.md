---
title: Configure OpenID Connect with client credentials
permalink: /how-to/configure-oidc-with-client-credentials/
content_type: how_to

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authentication flows and grants
    url: /plugins/openid-connect/#authentication
  - text: Client credentials grant workflow
    url: /plugins/openid-connect/#client-credentials-grant-workflow
  - text: OpenID Connect tutorials
    url: /how-to/?query=openid-connect

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
search_aliases:
  - oidc

description: Set up OpenID Connect with the client credentials grant, which uses a client ID and client secret for authentication.

tldr:
  q: How do I use a client ID and client secret to authenticate directly with my identity provider?
  a: Using the OpenID Connect plugin, set up the [client credentials grant flow](/plugins/openid-connect/#client-credentials-grant-workflow) to connect to an identity provider (IdP) by passing a client ID and client secret in a header.

faqs:
  - q: Why does the OIDC plugin not use cached tokens with the client credentials grant, and instead connects to the IdP on every request?
    a: |
      Token caching doesn't work if both `client_credentials` and `password` are set as auth methods in the `config.auth_methods` parameter, and credentials are sent using the `Authorization: Basic` header. 
      
      In this scenario, either authentication method could match, but the plugin prioritises the password grant.
      To resolve this caching issue, make sure you only have the `client_credentials` method enabled.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## Enable the OpenID Connect plugin with the client credentials grant

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin with the client credentials grant.

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
        - client_credentials
        client_credentials_param_type:
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
* `auth_methods`: Specifies that the plugin should use client credentials (client ID and secret) for authentication.
* `client_credentials_param_type`: Restricts client credential lookup to request headers only.

{% include_cached plugins/oidc/client-auth.md %}

## Validate the client credentials grant

Now, validate the setup by accessing the `example-route` Route using the credentials in `client-id:client-secret` format:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
user: "$DECK_CLIENT_ID:$DECK_CLIENT_SECRET"
display_headers: true
{% endvalidation %}

{% include_cached plugins/oidc/cache.md %}