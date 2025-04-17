---
title: Configure OpenID Connect with the user info auth flow
content_type: how_to

related_resources:
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authentication flows and grants
    url: /plugins/openid-connect/#authentication
  - text: User info auth workflow
    url: /plugins/openid-connect/#user-info-authentication-flow

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

## 1. Enable the OpenID Connect plugin with user info auth

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
* `auth_methods`: User info and password grant.
* `bearer_token_param_type`: We want to search for user info in headers only.

{% include_cached plugins/oidc/client-auth.md %}

## 2. Retrieve the bearer token using the user info endpoint

Check that you can recover the token by requesting the Service with the basic authentication credentials created in the [prerequisites](#prerequisites), and export it to an environment variable:

```sh
export TOKEN=$(curl --user john:doe http://localhost:8000/anything \
  | jq -r .headers.Authorization)
echo $TOKEN
```
{: data-deployment-topology="on-prem" }

```sh
export TOKEN=$(curl --user john:doe http://$KONNECT_PROXY_URL/anything \
  | jq -r .headers.Authorization)
echo $TOKEN
```
{: data-deployment-topology="konnect" }

## 3. Validate the token

At this point you have created a Gateway Service, routed traffic to the Service, enabled the OpenID Connect plugin, and retrieved the bearer token. 
Access the `example-route` Route by passing the token you retrieved through user info:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
display_headers: true
headers:
  - "Authorization: $TOKEN"
{% endvalidation %}

{% include_cached plugins/oidc/cache.md %}
