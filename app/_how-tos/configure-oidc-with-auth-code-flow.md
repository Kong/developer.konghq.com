---
title: Configure OpenID Connect with the authorization code flow
content_type: how_to

related_resources:
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authentication flows and grants
    url: /plugins/openid-connect/#authentications
  - text: Authorization code workflow
    url: /plugins/openid-connect/#authorization-code-flow

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
  q: How do I use an authorization code to open a session with my identity provider, letting users log in through a browser?
  a: Using the OpenID Connect plugin, set up the [auth code flow](/plugins/openid-connect/#authorization-code-flow) to connect to an identity provider (IdP) through a browser, and use session authentication to store open sessions.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## 1. Enable the OpenID Connect plugin with the auth code flow

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin with the auth code flow and session authentication.
These two 

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
        - authorization_code
        - session
        response_mode: form_post
        preserve_query_args: true
        login_action: redirect
        login_tokens: null
        authorization_endpoint: http://localhost:8080
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
* `auth_methods`: Specifies that the plugin should use session auth and the authorization code flow.
* `response_mode`: Set to `form_post` so that authorization codes won’t get logged to access logs.
* `preserve_query_args`: Preserves the original request query arguments through the authorization code flow redirection.
* `login_action`: Redirects the client to original request URL after the authorization code flow so that the POST request is turned into a GET request, and the browser address bar is updated with the original request query arguments.
* `login_tokens`: We don’t want to include any tokens in the browser address bar.
* `authorization_endpoint`: Sets a custom endpoint for authorization, overriding the endpoint returned by discovery through the IdP. 
We need this setting because we're running the example through Docker, otherwise the discovery endpoint will try to access an internal Docker host.

## 2. Validate authorization code login

Access the Route you configured in the [prerequisites](#prerequisites) with some query arguments. 
The following command opens a new tab in your default browser:

```sh
open http://localhost:8000/anything?hello=world
```

The browser should be redirected to the Keycloak login page. 

Let's check what happens if you access the same URL using cURL:

{% validation request-check %}
url: /anything?hello=world
method: GET
status_code: 302
display_headers: true
{% endvalidation %}

You should see a `302` response with the session access token in the response, and a `Location` header that shows where the request is being redirected to.