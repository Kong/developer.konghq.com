---
title: Configure OpenID Connect with the client credentials grant
content_type: how_to

related_resources:
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authentication flows and grants
    url: /plugins/openid-connect/#authentication

plugins:
  - openid-connect

entities:
  - route
  - service

products:
  - gateway

works_on:
  - on-prem

min_version:
  gateway: '3.4'

tier: enterprise

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
      include_content: prereqs/auth/oidc/keycloak-jwks
      icon_url: /assets/icons/keycloak.svg

tags:
  - authentication
  - openid-connect

tldr:
  q: How do I use client credentials to authenticate with my identity provider?
  a: Using the OpenID Connect plugin, set up the client credentials grant flow to connect to an identity provider (IdP) by passing a client ID and secret in a header.

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## 1. Enable the OpenID Connect plugin with client credentials

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin with the client credentials grant.

For the client credentials grant, we need to configure the following:
* Issuer, client ID, and client auth: settings that connect the plugin to your IdP (in this case, the sample Keycloak app).
* Auth method: client credentials grant.
* We want to search for client credentials in headers only.

Using these settings, let’s test out the client credentials grant with Keycloak. 
Enable the OpenID Connect plugin on the `example-service` service:

{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      service: example-service
      config:
        issuer: $ISSUER
        client_id:
        - $CLIENT_ID
        client_auth:
        - private_key_jwt
        auth_methods:
        - client_credentials
        client_credentials_param_type:
        - header
{% endentity_examples %}

## 2. Check OpenID Connect discovery cache

Check that the OpenID Connect plugin is able to connect to your IdP:

{% control_plane_request %}
url: /openid-connect/issuers
status_code: 200
method: GET
{% endcontrol_plane_request %}

The response should contain Keycloak OpenID Connect discovery document and the keys. 
If there are no keys returned by the issuer, check your IdP configuration.

## 3. Validate the client credentials grant

At this point you have created a Gateway Service, routed traffic to the Service, and enabled the OpenID Connect plugin.
You can now test the client credentials grant.

Access the `example-route` Route using the client credentials created in the Keycloak configuration step:

{% validation request-check %}
url: /example-route
method: GET
status_code: 200
user: "$CLIENT_ID:$CLIENT_SECRET"
{% endvalidation %}

If {{site.base_gateway}} successfully authenticates with Keycloak, you'll see a `200` response with your bearer token in the Authorization header.

If you make another request using the same credentials, you'll see that {{site.base_gateway}} adds less latency to the request because it has cached the token endpoint call to Keycloak:

```
X-Kong-Proxy-Latency: 25
```
{:.no-copy-code}