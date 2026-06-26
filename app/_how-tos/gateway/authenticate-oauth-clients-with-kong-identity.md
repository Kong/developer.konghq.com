---
title: Authenticate OAuth clients with a Kong Identity authorization server
permalink: /how-to/authenticate-oauth-clients-with-kong-identity/
content_type: how_to
breadcrumbs:
  - /identity/
related_resources:
  - text: Authentication
    url: /gateway/authentication/
  - text: "{{site.identity}}"
    url: /identity/
  - text: "{{site.identity}} principals and directories"
    url: /identity/principals/

description: Use the OpenID Connect plugin to map authenticated OAuth clients to Kong Identity principals.
products:
    - gateway
    - identity

plugins:
  - openid-connect
works_on:
    - konnect
    - on-prem
    

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
  q: How do I map OAuth clients to principals with OpenID Connect?
  a: |
    Create a {{site.identity}} authorization server and OAuth client, create a principal, and link the client to the principal with an `auth_server_client` identity. Configure the OpenID Connect plugin with `principals.enabled` set to `true` to use {{site.identity}} as your IdP, then send a request with the client credentials in an `Authorization: Basic` header to a protected Gateway Service.

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

## Create an authorization server in {{site.identity}}

An authorization server in {{site.identity}} issues the OAuth tokens that clients present to authenticate to your service.

Create an authorization server using the [`/v1/auth-servers` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer):

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

## Create a client

The client is the credential that the OpenID Connect plugin uses to authenticate. {{site.identity}} autogenerates the client ID and secret.

Create a client using the [`/v1/auth-servers/$AUTH_SERVER_ID/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $KONNECT_TOKEN'
body:
  name: "example-client"
  allow_all_scopes: true
  allow_scopes: []
  access_token_duration: 300
  grant_types:
    - client_credentials
  response_types:
    - token
  redirect_uris: []
  login_uri: ""
extract_body:
  - name: 'client_secret'
    variable: CLIENT_SECRET
  - name: 'id'
    variable: CLIENT_ID
capture:
  - variable: CLIENT_ID
    jq: ".id"
  - variable: CLIENT_SECRET
    jq: ".client_secret"
{% endkonnect_api_request %}
<!--vale on-->

## Create a principal

{% include /how-tos/steps/principal.md %}

## Link the client to the principal

Link the {{site.identity}} authorization server client to the principal so that {{site.identity}} can map the OAuth tokens it issues to this principal. Because {{site.identity}} issues the tokens, you reference the authorization server and client you created earlier instead of an external issuer and claim.

Add the identity using the `/v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/identities` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/identities
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $KONNECT_TOKEN'
body:
  type: auth_server_client
  auth_server_id: $AUTH_SERVER_ID
  client_id: $CLIENT_ID
{% endkonnect_api_request %}
<!--vale on-->

## Get the directory name

To configure the OpenID Connect plugin, you need the name of the directory you created. Store it as `DECK_DIRECTORY_NAME` so decK can read it during sync:

{% include /how-tos/steps/get-directory-name.md %}

## Generate a salt token

{% include how-tos/steps/deck-salt-token.md %}

## Configure the OpenID Connect plugin

Export the variables to decK:

```bash
export DECK_ISSUER_URL=$ISSUER_URL
export DECK_CLIENT_ID=$CLIENT_ID
export DECK_CLIENT_SECRET=$CLIENT_SECRET
```

Configure the [OpenID Connect plugin](/plugins/openid-connect/) to use {{site.identity}} as the identity provider and map the client credentials. Setting `principals.enabled` to `true` maps the authenticated token to a directory. This example applies the plugin to the `example-service` you created in the prerequisites.

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
        principals:
          enabled: true
          directory: ${directory_name}
        cache_tokens_salt: ${salt-token}
variables:
  issuer:
    value: $ISSUER_URL
  client-id:
    value: $CLIENT_ID
  client-secret:
    value: $CLIENT_SECRET
  directory_name:
    value: $DIRECTORY_NAME
  salt-token:
    value: $TOKEN_SALT
formats:
  - deck
{% endentity_examples %}

## Validate

Base64-encode the client ID and secret for the `Authorization` header:

<!--vale off-->
```bash
export CLIENT_CREDENTIALS=$(printf '%s' "$CLIENT_ID:$CLIENT_SECRET" | base64)
```
<!--vale on-->

Send a request to the protected Gateway Service with the client credentials. The OpenID Connect plugin exchanges them for a token with {{site.identity}}, validates it, and maps it to your principal. The request should succeed with a `200` status code:

{% validation request-check %}
url: '/anything'
display_headers: true
status_code: 200
headers:
  - 'Authorization: Basic $CLIENT_CREDENTIALS'
{% endvalidation %}

Send a request without credentials. {{site.identity}} rejects it because the request can't be mapped to a principal:

{% validation unauthorized-check %}
url: /anything
{% endvalidation %}


