---
title: Dynamically set host based on the authenticated Principal with Datakit
permalink: /how-to/configure-oidc-datakit-host-routing-with-principals-metadata/
content_type: how_to
breadcrumbs:
  - /identity/

related_resources:
  - text: "{{site.identity}}"
    url: /identity/
  - text: "{{site.identity}} principals and directories"
    url: /identity/principals/
  - text: OpenID Connect plugin
    url: /plugins/openid-connect/
  - text: Datakit plugin
    url: /plugins/datakit/
  - text: Authenticate OAuth clients with a {{site.identity}} authorization server
    url: /how-to/authenticate-oauth-clients-with-kong-identity/
  - text: Dynamically set host based on the authenticated caller
    url: /how-to/configure-oidc-datakit-host-routing/

plugins:
  - openid-connect
  - datakit

entities:
  - route
  - service
  - plugin
  - principal

products:
  - gateway
  - identity

works_on:
  - konnect

min_version:
  gateway: '3.16'

tools:
  - deck

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route
  inline:
    - title: "{{site.identity}} directory"
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/identity.svg

tags:
  - authentication
  - openid-connect
  - routing
search_aliases:
  - oidc
  - datakit
  - principals
  - target routing

description: Learn how to store a backend address as {{site.identity}} Principal metadata, hydrate the Principal with the OpenID Connect plugin, then use the Datakit plugin to route the request to that backend.

tldr:
  q: How do I route requests to different hosts based on who is making the request, without hardcoding the routing map in my plugin config?
  a: |
    Store the backend address as metadata on a {{site.identity}} Principal and link each OAuth client to its Principal with an `auth_server_client` identity.
    Configure the OpenID Connect plugin with `principals.enabled` set to `true` so it hydrates the Principal after verifying the token.
    Then configure the Datakit plugin to read `kong.client.principal`, pull the address out of the Principal's metadata, and write it to `kong.service.target`.

faqs:
  - q: Can I retrieve my client's secret again?
    a: |
      No, the secret is only shared once when the client is created. Store it securely.
  - q: What happens if a token can't be matched to a Principal?
    a: |
      By default, the OpenID Connect plugin returns a `401` when it verifies a token but can't match it to a Principal in the directory.
      Set `principals.error_on_miss` to `false` if you want the request to continue without an authenticated Principal.
      If you do that, handle a null `kong.client.principal` in your Datakit configuration.

cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
automated_tests: false
---

Kong's router runs before authentication, so it can't directly route traffic based on who is making a request.
This guide solves that using {{site.identity}} and two plugins working together in the `access` phase:

1. You store each caller's backend address as [Principal](/identity/principals/) metadata in {{site.identity}}.
1. [**OpenID Connect**](/plugins/openid-connect/) verifies the bearer token and hydrates the matching Principal, including its metadata.
1. [**Datakit**](/plugins/datakit/) reads the Principal, pulls the address out of its metadata, and sets it as the backend target for that request.

All callers share one Route and one Service, and the Datakit plugin decides dynamically which backend responds after authentication.

Because the routing map lives in {{site.identity}}, you create a new caller using the Principal API. You don't need to edit the Datakit configuration or run a decK sync.

This guide routes directly to a `host:port` backend, and bypasses Upstream entities, load balancing, health checks, and retries.
Use it when each backend is a fixed address and you don't need a pool.

{:.info}
> **Note:** The OpenID Connect plugin has a higher [static priority](/gateway/entities/plugin/#plugin-priority) than Datakit, so it always runs first in the `access` phase.
> No explicit plugin ordering configuration is required.

## Create an authorization server in {{site.identity}}

An authorization server in {{site.identity}} issues the OAuth tokens that callers present to authenticate to your service.
It's recommended that you create different authorization servers for different environments. The authorization server name is unique per each organization and each {{site.konnect_short_name}} region.

Create an authorization server using the [`/v1/auth-servers` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "datakit-routing"
  description: "Authorization server for Datakit host routing"
  audience: "http://myhttpbin.dev"
capture:
  - variable: AUTH_SERVER_ID
    jq: ".id"
  - variable: ISSUER_URL
    jq: ".issuer"
{% endkonnect_api_request %}
<!--vale on-->

## Create the clients

Create one client per caller. Each client is the machine-to-machine credential that a caller uses to fetch a token.
{{site.konnect_short_name}} autogenerates the client ID and secret.

Create the `orders-caller` client using the [`/v1/auth-servers/$AUTH_SERVER_ID/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "orders-caller"
  allow_all_scopes: true
  allow_scopes: []
  access_token_duration: 3600
  grant_types:
    - client_credentials
  response_types:
    - token
  redirect_uris: []
  login_uri: ""
capture:
  - variable: CLIENT_A_ID
    jq: ".id"
  - variable: CLIENT_A_SECRET
    jq: ".client_secret"
{% endkonnect_api_request %}
<!--vale on-->

Create the `reports-caller` client:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "reports-caller"
  allow_all_scopes: true
  allow_scopes: []
  access_token_duration: 3600
  grant_types:
    - client_credentials
  response_types:
    - token
  redirect_uris: []
  login_uri: ""
capture:
  - variable: CLIENT_B_ID
    jq: ".id"
  - variable: CLIENT_B_SECRET
    jq: ".client_secret"
{% endkonnect_api_request %}
<!--vale on-->

Create the `legacy-caller` client. This caller's Principal won't carry any routing metadata, so you can use it to confirm the default backend:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "legacy-caller"
  allow_all_scopes: true
  allow_scopes: []
  access_token_duration: 3600
  grant_types:
    - client_credentials
  response_types:
    - token
  redirect_uris: []
  login_uri: ""
capture:
  - variable: CLIENT_C_ID
    jq: ".id"
  - variable: CLIENT_C_SECRET
    jq: ".client_secret"
{% endkonnect_api_request %}
<!--vale on-->

## Create the Principals

Create one Principal per caller in the directory you created in the prerequisites.
The `metadata` object is where the routing decision lives: `backend_target` holds the `host:port` address, and `backend_scheme` holds the protocol {{site.base_gateway}} uses to reach it.

{:.info}
> **Note:** Metadata is inherited hierarchically. A Principal inherits its directory's metadata and can override it, and a credential inherits the Principal's metadata and can override it.
> You can set a `backend_target` on the directory to give every Principal a shared default.

Create the `orders-caller` Principal, routed to `httpbin.konghq.com` over HTTP:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: "orders-caller"
  description: "Caller routed to the orders backend"
  metadata:
    backend_target: "httpbin.konghq.com:80"
    backend_scheme: "http"
capture:
  - variable: PRINCIPAL_A_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Create the `reports-caller` Principal, routed to `httpbun.com` over HTTPS:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: "reports-caller"
  description: "Caller routed to the reports backend"
  metadata:
    backend_target: "httpbun.com:443"
    backend_scheme: "https"
capture:
  - variable: PRINCIPAL_B_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Create the `legacy-caller` Principal with no routing metadata:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: "legacy-caller"
  description: "Caller with no routing metadata, falls back to the default backend"
capture:
  - variable: PRINCIPAL_C_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Link each client to its Principal

Your {{site.identity}} authorization server issues the tokens. Add an `auth_server_client` identity to each Principal so {{site.identity}} can map the tokens it issues back to the right Principal.

Link `orders-caller` using the [`/v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/identities` endpoint](/api/konnect/kong-identity-principals/v2/#/operations/createIdentity):

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_A_ID/identities
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  type: auth_server_client
  auth_server_id: $AUTH_SERVER_ID
  client_id: $CLIENT_A_ID
{% endkonnect_api_request %}
<!--vale on-->

Link `reports-caller`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_B_ID/identities
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  type: auth_server_client
  auth_server_id: $AUTH_SERVER_ID
  client_id: $CLIENT_B_ID
{% endkonnect_api_request %}
<!--vale on-->

Link `legacy-caller`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_C_ID/identities
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  type: auth_server_client
  auth_server_id: $AUTH_SERVER_ID
  client_id: $CLIENT_C_ID
{% endkonnect_api_request %}
<!--vale on-->

## Get the directory name

To configure the OpenID Connect plugin, you need the name of the directory you created. Store it as `DECK_DIRECTORY_NAME` so decK can read it during sync:

{% include /how-tos/steps/get-directory-name.md %}

## Generate a salt token

{% include how-tos/steps/deck-salt-token.md %}

## Enable the OpenID Connect plugin

Export the issuer URL to decK:

```sh
export DECK_ISSUER_URL=$ISSUER_URL
```

Configure the OpenID Connect plugin to verify bearer tokens issued by {{site.identity}} and hydrate the matching Principal:

{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      service: example-service
      config:
        issuer: ${issuer}
        auth_methods:
          - bearer
        audience:
          - http://myhttpbin.dev
        principals:
          enabled: true
          directory: ${directory_name}
        cache_tokens_salt: ${salt-token}
variables:
  issuer:
    value: $ISSUER_URL
  directory_name:
    value: $DIRECTORY_NAME
  salt-token:
    value: $TOKEN_SALT
formats:
  - deck
{% endentity_examples %}

In this configuration:
* `issuer`: The {{site.identity}} authorization server issuer URL. The plugin discovers the JWKS endpoint from this URL and uses it to verify token signatures.
* `auth_methods: [bearer]`: The plugin only accepts tokens in the `Authorization: Bearer` header.
* `audience`: Must match the `audience` you set on the authorization server, so the plugin accepts the `aud` claim in the token.
* `principals.enabled: true`: After verifying the token, the plugin looks up the matching Principal in the named directory and makes it available to later plugins through `kong.client.principal`.
* `principals.directory`: The name of the {{site.identity}} directory holding your Principals.

## Enable the Datakit plugin

Configure the Datakit plugin to read the Principal that the OpenID Connect plugin hydrated and use its metadata as the backend target:

{% entity_examples %}
entities:
  plugins:
    - name: datakit
      service: example-service
      config:
        nodes:
          - name: GET_PRINCIPAL
            type: property
            property: kong.client.principal
          - name: PICK_TARGET
            type: jq
            input: GET_PRINCIPAL
            jq: |
              {
                "target": (.metadata.backend_target // "httpbin.konghq.com:80"),
                "scheme": (.metadata.backend_scheme // "http")
              }
          - name: EXTRACT_TARGET
            type: jq
            input: PICK_TARGET
            jq: .target
          - name: SET_TARGET
            type: property
            property: kong.service.target
            input: EXTRACT_TARGET
          - name: EXTRACT_SCHEME
            type: jq
            input: PICK_TARGET
            jq: .scheme
          - name: SET_SCHEME
            type: property
            property: kong.service.request.scheme
            input: EXTRACT_SCHEME
        debug: true
formats:
  - deck
{% endentity_examples %}

In this configuration:
* `GET_PRINCIPAL`: Reads the `kong.client.principal` object that the OpenID Connect plugin populates. No input is connected because this is a read-only (get) operation.
* `PICK_TARGET`: Reads `backend_target` and `backend_scheme` out of the Principal's metadata and returns both in one object. Returning both values from one node avoids reading the Principal twice. The `//` operator supplies a default backend for Principals that carry no routing metadata.
* `EXTRACT_TARGET`: Extracts the `.target` field from the `PICK_TARGET` output.
* `SET_TARGET`: Writes the `host:port` string to `kong.service.target`, overriding the backend for this request. This bypasses load balancing, health checks, and retries.
* `EXTRACT_SCHEME`: Extracts the `.scheme` field from the `PICK_TARGET` output.
* `SET_SCHEME`: Writes the scheme to `kong.service.request.scheme`. This is required when backends use different protocols, so {{site.base_gateway}} uses the correct scheme when connecting.
* `debug: true`: Enables trace output for this tutorial. Remove it before using this configuration in production.

## Validate the routing

To validate that routing via Datakit is working, fetch an access token for each client from the {{site.identity}} authorization server, then send it as a bearer token and verify that each caller reaches the correct backend.

In the following requests, you set the `X-Datakit-Debug-Trace: true` request header so that Datakit returns a JSON trace in the response body showing each node's input and output.

1. Fetch a token as `orders-caller`:

   <!--vale off-->
   ```sh
   export TOKEN_A=$(curl -s -X POST "$ISSUER_URL/oauth/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=client_credentials" \
     -d "client_id=$CLIENT_A_ID" \
     -d "client_secret=$CLIENT_A_SECRET" | jq -r .access_token)
   ```
   <!--vale on-->

   Send a request as `orders-caller`:
   ```sh
   curl -si http://localhost:8000/anything \
     -H "Authorization: Bearer $TOKEN_A" \
     -H "X-Datakit-Debug-Trace: true"
   ```

   The response comes from `httpbin.konghq.com`.
   In the response body, find the `complete` event for each node and check:
   * `GET_PRINCIPAL`: `value.value.display_name` is `orders-caller`.
   * `PICK_TARGET`: `value.value` is `{"target":"httpbin.konghq.com:80","scheme":"http"}`.
   * `EXTRACT_TARGET`: `value.value` is `httpbin.konghq.com:80`.
   * `SET_TARGET`: `value.value` is `httpbin.konghq.com:80`.
   * `EXTRACT_SCHEME`: `value.value` is `http`.
   * `SET_SCHEME`: `value.value` is `http`.

1. Fetch a token as `reports-caller`:

   <!--vale off-->
   ```sh
   export TOKEN_B=$(curl -s -X POST "$ISSUER_URL/oauth/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=client_credentials" \
     -d "client_id=$CLIENT_B_ID" \
     -d "client_secret=$CLIENT_B_SECRET" | jq -r .access_token)
   ```
   <!--vale on-->

   Send a request as `reports-caller`:
   ```sh
   curl -si http://localhost:8000/anything \
     -H "Authorization: Bearer $TOKEN_B" \
     -H "X-Datakit-Debug-Trace: true"
   ```

   The response comes from `httpbun.com`, confirming the request was routed to a different backend.
   `EXTRACT_TARGET` and `SET_TARGET` should show `httpbun.com:443`, and `EXTRACT_SCHEME` and `SET_SCHEME` should show `https`.

1. Fetch a token as `legacy-caller` to confirm the fallback:

   <!--vale off-->
   ```sh
   export TOKEN_C=$(curl -s -X POST "$ISSUER_URL/oauth/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=client_credentials" \
     -d "client_id=$CLIENT_C_ID" \
     -d "client_secret=$CLIENT_C_SECRET" | jq -r .access_token)
   ```
   <!--vale on-->

   Send a request as `legacy-caller`:
   ```sh
   curl -si http://localhost:8000/anything \
     -H "Authorization: Bearer $TOKEN_C" \
     -H "X-Datakit-Debug-Trace: true"
   ```

   `GET_PRINCIPAL` should show `value.value.display_name` as `legacy-caller` with an empty `metadata` object, and `EXTRACT_TARGET` and `SET_TARGET` should resolve to `httpbin.konghq.com:80` because the Principal carries no `backend_target`.

1. Send a request with no token. The OpenID Connect plugin rejects it before Datakit runs:

   {% validation unauthorized-check %}
   url: /anything
   {% endvalidation %}

## Change a caller's backend without a decK sync

Because the routing map lives in {{site.identity}}, you can move a caller to a different backend by updating its Principal metadata.

Move `orders-caller` to `httpbun.com`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_A_ID
status_code: 200
method: PATCH
headers:
  - 'Content-Type: application/json'
body:
  metadata:
    backend_target: "httpbun.com:443"
    backend_scheme: "https"
{% endkonnect_api_request %}
<!--vale on-->

Send a request as `orders-caller` again. Once the OpenID Connect plugin's token cache expires, the response comes from `httpbun.com` with no change to your gateway configuration:

```sh
curl -si http://localhost:8000/anything \
  -H "Authorization: Bearer $TOKEN_A" \
  -H "X-Datakit-Debug-Trace: true"
```
