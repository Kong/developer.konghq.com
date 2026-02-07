---
title: Configure OpenID Connect with ACL authorization
permalink: /how-to/configure-oidc-with-acl-auth/
content_type: how_to

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authorization options
    url: /plugins/openid-connect/#authorization
  - text: ACL authorization in OIDC
    url: /plugins/openid-connect/#acl-plugin-authorization
  - text: OpenID Connect tutorials
    url: /how-to/?query=openid-connect

plugins:
  - openid-connect
  - acl

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
  - authorization
  - openid-connect
search_aliases:
  - oidc

description: Configure the OpenID Connect and ACL plugins together to apply auth flows to ACL allow or deny lists.

tldr:
  q: How do I integrate my IdP with ACL allow or deny lists?
  a: Using the OpenID Connect and ACL plugins, set up any type of authentication (the password grant, in this guide) and enable authorization through ACL groups.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Enable the OpenID Connect plugin

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin. In this example, we're using the simple password grant with authenticated groups.

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
        - password
        authenticated_groups_claim:
        - scope
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
* `auth_methods`: Specifies that the plugin should use the password grant, for easy testing.
* `authenticated_groups_claim`: Looks for a groups claim in an ACL.

{% include_cached plugins/oidc/client-auth.md %}

## Validate the OpenID Connect plugin configuration

Request the Service with the basic authentication credentials created in the [prerequisites](#prerequisites):

{% validation request-check %}
url: /anything
method: GET
status_code: 200
user: "alex:doe"
display_headers: true
{% endvalidation %}

You should get an HTTP `200` response with an `X-Authenticated-Groups` header:

```
"X-Authenticated-Groups": "openid, email, profile"
```
{:.no-copy-code}

## Enable the ACL plugin and verify

Let's try denying access to the `openid` group first:

{% entity_examples %}
entities:
  plugins:
    - name: acl
      service: example-service
      config:
        deny:
        - openid
{% endentity_examples %}

Try to access the `/anything` Route:

{% validation request-check %}
url: /anything
method: GET
status_code: 403
user: "alex:doe"
display_headers: true
{% endvalidation %}

You should get a `403 Forbidden` error code with the message `You cannot consume this service`.

Now let's allow access to the `openid` group:

{% entity_examples %}
entities:
  plugins:
    - name: acl
      service: example-service
      config:
        allow:
        - openid
{% endentity_examples %}

And try accessing the `/anything` Route again:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
user: "alex:doe"
display_headers: true
{% endvalidation %}

This time, you should get a `200` response.
