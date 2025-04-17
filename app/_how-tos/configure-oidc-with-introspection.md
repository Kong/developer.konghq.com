---
title: Configure OpenID Connect with introspection
content_type: how_to

related_resources:
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authentication flows and grants
    url: /plugins/openid-connect/#authentication
  - text: Introspection workflow
    url: /plugins/openid-connect/#introspection-authentication-workflow

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

description: Set up OpenID Connect with introspection auth, which retrieves a bearer token from the IdP's introspection endpoint for authentication.

tldr:
  q: How do I retrieve a token using my identity provider's introspection endpoint?
  a: Using the OpenID Connect plugin, set up the [introspection auth workflow](/plugins/openid-connect/#password-grant-workflow) to connect to an identity provider (IdP) to retrieve a token from the IdP's introspection endpoint, then use the token to access the upstream service.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## 1. Enable the OpenID Connect plugin with introspection

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
* `auth_methods`: Introspection and password grant.
* `bearer_token_param_type`: We want to search for client credentials in headers only.

<!-- include_cached plugins/oidc/client-auth.md -->

## 2. Retrieve the bearer token using instrospection

Check that you can recover the token by requesting the Service with the basic authentication credentials created in the [prerequisites](#prerequisites), and export it to an environment variable:

```sh
export TOKEN=$(curl --user john:doe http://localhost:8000/anything \
  | jq -r .headers.Authorization)
```
{: data-deployment-topology="on-prem" }

```sh
export TOKEN=$(curl --user john:doe http://$KONNECT_PROXY_URL/anything \
  | jq -r .headers.Authorization)
```
{: data-deployment-topology="konnect" }

## 3. Validate the token

At this point you have created a Gateway Service, routed traffic to the Service, enabled the OpenID Connect plugin, and retrieved the bearer token. 
Access the `example-route` Route by passing the token you retrieved using introspection:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
display_headers: true
headers:
  - "Authorization: $TOKEN"
{% endvalidation %}

<!-- include_cached plugins/oidc/cache.md -->