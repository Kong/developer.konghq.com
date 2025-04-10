---
title: Configure OpenID Connect with the password grant
content_type: how_to

related_resources:
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authentication flows and grants
    url: /plugins/openid-connect/#authentication
  - text: Password grant workflow
    url: /plugins/openid-connect/#password-grant-workflow

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

tldr:
  q: How do I use a username and password to authenticate directly with my identity provider?
  a: Using the OpenID Connect plugin, set up the [password grant flow](/plugins/openid-connect/#password-grant-workflow) to connect to an identity provider (IdP) by passing a username and password in a header.

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## 1. Enable the OpenID Connect plugin with the password grant

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin with the password grant.

Enable the OpenID Connect plugin on the `example-service` service:

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
* `auth_methods`: Password grant.
* `client_credentials_param_type`: We want to search for client credentials in headers only.

## 2. Validate the password grant

At this point you have created a Gateway Service, routed traffic to the Service, and enabled the OpenID Connect plugin.
You can now test the password grant.

Access the `example-route` Route by passing the user credentials in `username:password` format.
The following user has the username `john` and the password `doe`:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
user: "john:doe"
display_headers: true
{% endvalidation %}

If {{site.base_gateway}} successfully authenticates with Keycloak, you'll see a `200` response with your bearer token in the Authorization header.

If you make another request using the same credentials, you'll see that {{site.base_gateway}} adds less latency to the request because it has cached the token endpoint call to Keycloak:

```
X-Kong-Proxy-Latency: 25
```
{:.no-copy-code}