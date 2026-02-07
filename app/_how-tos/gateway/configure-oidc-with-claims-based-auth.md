---
title: Configure OpenID Connect with claims-based authorization
permalink: /how-to/configure-oidc-with-claims-based-auth/
content_type: how_to

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authorization options
    url: /plugins/openid-connect/#authorization
  - text: Claims-based authorization in OIDC
    url: /plugins/openid-connect/#claims-based-authorization
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
  - authorization
  - openid-connect
search_aliases:
  - oidc

description: Configure the OpenID Connect plugin for claims-based authorization.

tldr:
  q: How do I use claims-based authorization with OpenID Connect?
  a: |
    Use the OpenID Connect plugin to look for specific claims in a token payload, and only allow users with the right claims access to a given resources. 
  
    Set up any type of authentication (the password grant, in this guide) and enable claims-based authorization by pointing to claims to look for in the authorization request.

faqs:
  - q: How do I check the scopes being passed in the token payload?
    a: |

      For troubleshooting or debugging purposes, you may want to check the scopes being passed in the payload. 
      The signed JWT access token you receive in the response is composed of three parts, each separated with a dot (`.`) character: `$HEADER.$PAYLOAD.$SIGNATURE`. 
      The payload portion contains the scopes information, encoded in base64 format.
      
      Decode the payload in any tool you prefer. For example, you can use base64 and jq:

      ```sh
      jq -n --arg p "$PAYLOAD" '$p | @base64d | fromjson'
      ```
      The response will contain data about the user, including the scope:

      ```json
      "scope": "openid profile email",
      "email_verified": false,
      "preferred_username": "alex"
      ```
      {:.no-copy-code}
  - q: How can I check that I'm able to connect to my IdP?
    a: |
      If you're running a self-managed {{site.base_gateway}} instance, you can check that the OpenID connect plugin is able to access the issuer URL with the `/openid-connect/issuers/` endpoint:
      
      ```
      curl http://localhost:8001/openid-connect/issuers
      ```

      The results should contain the Keycloak OpenID Connect discovery document and keys. If the results only show the issuer URL and ID, then the connection was unsuccessful.
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## Enable the OpenID Connect plugin with claims-based authorization

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin. In this example, we're using the simple password grant with the `scopes_claim` and `scopes_required` claims pair.

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
        - bearer
        scopes_claim:
        - scope
        scopes_required:
        - openid
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
* `auth_methods`: Password grant, for easy testing, and the bearer grant so that we can authenticate using the JWT that we retrieve.
* `scopes_claim` and `scopes_required`: Looks for a claim named `scope` in the payload, and checks that the scope contains `openid`.

{% include_cached plugins/oidc/client-auth.md %}

## Retrieve the bearer token

Check that you can recover the token by requesting the Service with the basic authentication credentials created in the [prerequisites](#prerequisites):

<!-- vale off -->
{% validation request-check %}
url: /anything
method: GET
status_code: 200
user: "alex:doe"
display_headers: true
extract_body:
  - name: 'headers.Authorization'
    variable: TOKEN
{% endvalidation %}
<!-- vale on -->

You'll see an `Authorization` header in the response. 

Export the value of the header to an environment variable:

```sh
export TOKEN=YOUR_BEARER_TOKEN
```

## Validate the token

Now, validate the setup by accessing the `example-route` Route and passing the token from the previous step:

<!-- vale off -->
{% validation request-check %}
url: /anything
method: GET
status_code: 200
display_headers: true
headers:
  - "Authorization: $TOKEN"
{% endvalidation %}
<!-- vale on -->

{% include_cached plugins/oidc/cache.md %}