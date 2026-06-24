---
title: Authenticate Principals with the OpenID Connect plugin
permalink: /how-to/authenticate-principals-with-oidc/
content_type: how_to
breadcrumbs:
  - /identity/
related_resources:
  - text: Authentication
    url: /gateway/authentication/

description: Use the OpenID Connect plugin to allow Principals to authenticate.
products:
    - gateway
    - identity

plugins:
  - key-auth
works_on:
    - konnect

min_version:
  gateway: '3.15'
entities: 
  - plugin
  - service
  - route
  - principal

tags:
    - authentication

tools:
    - deck

tldr:
  q: How do I authenticate Principals with OpenID Connect?
  a: |
    SUMMARY HERE

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Kong Identity directory
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/identity.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Create an auth server in {{site.identity}}

Before you can configure the OpenID Connect plugin, you must first create an auth server in {{site.identity}}. We recommend creating different auth servers for different environments or subsidiaries. The auth server name is unique per each organization and each {{site.konnect_short_name}} region.

Create an auth server using the [`/v1/auth-servers` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "example-auth-server"
  description: "Example auth server"
  audience: "orders-api"
extract_body:
  - name: 'id'
    variable: AUTH_SERVER_ID
  - name: 'issuer'
    variable: ISSUER_URL
capture:
  - variable: AUTH_SERVER_ID
    jq: ".id"
  - variable: ISSUER_URL
    jq: ".issuer"
{% endkonnect_api_request %}
<!--vale on-->

## Create a Principal

{% include /how-tos/steps/principal.md %}

