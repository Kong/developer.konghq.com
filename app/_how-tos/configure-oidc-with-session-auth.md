---
title: Configure OpenID Connect with session authentication
content_type: how_to

related_resources:
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authentication flows and grants
    url: /plugins/openid-connect/#authentication
  - text: Session auth workflow
    url: /plugins/openid-connect/#session-authentication-workflow

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

description: Set up OpenID Connect with session authentication, which stores credentials in a session cookie and reuses the cookie for subsequent access attempts.

tldr:
  q: How do I use a session cookie to authenticate directly with my identity provider?
  a: Using the OpenID Connect plugin, set up the [session auth flow](/plugins/openid-connect/#session-authentication-workflow) to connect to an identity provider (IdP) to retrieve, store, and use session cookies for authentication.

faqs:
  - q: How do I disable session creation?
    a: If you want to disable session creation with some grants, use the [`config.disable_session`](/plugins/openid-connect/reference/#schema--config-disable-session) configuration parameter.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## 1. Enable the OpenID Connect plugin with session auth

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin with the session auth flow.

We're also enabling the password grant so that we can test retrieving the session cookie.

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
        - session
        - password
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
* `auth_methods`: Session auth and password grant.

{% include_cached plugins/oidc/client-auth.md %}

## 2. Store the session cookie

Request the Service with the basic authentication credentials created in the [prerequisites](#prerequisites) and store the session:

<!--vale off-->
{% validation request-check %}
url: /anything
method: GET
status_code: 200
user: "john:doe"
display_headers: true
cookie_jar: example-user
{% endvalidation %}
<!--vale on-->

## 3. Validate session authentication

Make a request with the stored session cookie:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
display_headers: true
cookie: example-user
{% endvalidation %}

{% include_cached plugins/oidc/cache.md %}