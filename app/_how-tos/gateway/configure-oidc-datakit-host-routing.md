---
title: Dynamically set host based on the authenticated caller with Datakit
permalink: /how-to/configure-oidc-datakit-host-routing/
content_type: how_to

related_resources:
  - text: OpenID Connect plugin
    url: /plugins/openid-connect/
  - text: Datakit plugin
    url: /plugins/datakit/
  - text: Dynamically set upstream based on the authenticated caller
    url: /how-to/configure-oidc-datakit-upstream-routing/
  - text: OpenID Connect tutorials
    url: /how-to/?query=openid-connect

plugins:
  - openid-connect
  - datakit

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
  gateway: '3.14'

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
      include_content: prereqs/auth/oidc/keycloak-oidc-routing
      icon_url: /assets/icons/keycloak.svg

tags:
  - authentication
  - openid-connect
  - routing
search_aliases:
  - oidc
  - datakit
  - target routing

description: Learn how to validate a bearer token with the OpenID Connect plugin, extract a claim as a credential, then use the Datakit plugin to route the request directly to a host and port based on that credential.

tldr:
  q: How do I route requests to different hosts based on who is making the request, without using Upstream entities?
  a: |
    Configure the OpenID Connect plugin with `credential_claim` to extract a token claim (for example, `client_id`) and set it as the authenticated credential.
    Then, configure the Datakit plugin to read that credential, map its value to a `host:port` string, and write it to `kong.service.target`, overriding the backend directly.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
automated_tests: false
---

Kong's router runs before authentication, so it can't directly route traffic based on who is making a request.
This guide shows you how to solve that using two plugins working together in the `access` phase:

1. [**OpenID Connect**](/plugins/openid-connect/) validates the bearer token and extracts a claim value (such as `client_id`) onto a virtual credential.
2. [**Datakit**](/plugins/datakit/) reads that credential and maps its value to a `host:port` string, setting it as the backend target for that specific request.

All callers share one Route and one Service, and the backend is decided dynamically after authentication.

This guide routes directly to a `host:port` backend, which bypasses Upstream entities, load balancing, health checks, and retries.
Use it when each backend is a fixed address and you don't need a pool.
If you need load balancing or health checks, use [Upstream entities instead](/how-to/configure-oidc-datakit-upstream-routing/).

{:.info}
> **Note:** The OpenID Connect plugin has a higher [static priority](/gateway/entities/plugin/#plugin-priority) than Datakit, so it always runs first in the `access` phase.
> No explicit plugin ordering configuration is required.

## Generate salt token

{% include how-tos/steps/deck-salt-token.md %}

## Enable the OpenID Connect plugin

Configure the OpenID Connect plugin to validate bearer tokens and extract the `client_id` claim as a virtual credential.
The `credential_claim` field sets `credential.id` to the value of the named claim without requiring a Kong Consumer entity.

{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      service: example-service
      config:
        issuer: ${issuer}
        using_pseudo_issuer: true
        jwks_endpoint: ${jwks-endpoint}
        client_id:
          - ${client-id}
        client_secret:
          - ${client-secret}
        client_auth:
          - client_secret_post
        auth_methods:
          - bearer
        credential_claim:
          - client_id
        consumer_optional: true
        cache_tokens_salt: ${salt-token}
variables:
  issuer:
    value: $ISSUER
  jwks-endpoint:
    value: $JWKS_ENDPOINT
  client-id:
    value: $CLIENT_ID
  client-secret:
    value: $CLIENT_SECRET
  salt-token:
    value: $TOKEN_SALT
{% endentity_examples %}

In this configuration:
* `issuer`: The issuer URL used to validate the `iss` claim in incoming tokens. This must match the `iss` value Keycloak stamps into its tokens (`localhost:8080`).
* `using_pseudo_issuer: true`: Disables OIDC discovery from the `issuer` URL. This is required here because {{site.base_gateway}} runs inside Docker and can't reach `localhost:8080` directly. The `issuer` value is still used to validate the `iss` claim in incoming tokens.
* `jwks_endpoint`: The explicit URL {{site.base_gateway}} uses to fetch Keycloak's signing keys. This uses the `keycloak` container name, which is reachable from {{site.base_gateway}} over the shared Docker network.
* `auth_methods: bearer`: The plugin only accepts tokens in the `Authorization: Bearer` header.
* `credential_claim: [client_id]`: Extracts the `client_id` claim from the validated token and places its value on `credential.id`.
* `consumer_optional: true`: Prevents a `401` when no Consumer entity matches the credential. The plugin still validates the token, but it doesn't require a Consumer to exist.

## Enable the Datakit plugin

Configure the Datakit plugin to read the credential set by the OpenID Connect plugin and map it to a `host:port` backend.

{% entity_examples %}
entities:
  plugins:
    - name: datakit
      service: example-service
      config:
        nodes:
          - name: GET_CREDENTIAL
            type: property
            property: kong.client.credential
          - name: PICK_TARGET
            type: jq
            input: GET_CREDENTIAL
            jq: |
              {
                "caller-a": {"target": "httpbin.konghq.com:80", "scheme": "http"},
                "caller-b": {"target": "httpbun.com:443", "scheme": "https"}
              }[.id] // {"target": "httpbin.konghq.com:80", "scheme": "http"}
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
{% endentity_examples %}

In this configuration:
* `GET_CREDENTIAL`: Reads the `kong.client.credential` object that the OpenID Connect plugin populates. No input is connected because this is a read-only (get) operation.
* `PICK_TARGET`: Uses a jq map to look up the credential's `.id` field and return an object containing both the `host:port` address and the scheme. Returning both values from one node avoids reading the credential twice. Unknown callers fall through to a default backend.
* `EXTRACT_TARGET`: Extracts the `.target` field from the `PICK_TARGET` output.
* `SET_TARGET`: Writes the extracted `host:port` string to `kong.service.target`, overriding the backend for this request. This bypasses load balancing, health checks, and retries.
* `EXTRACT_SCHEME`: Extracts the `.scheme` field from the `PICK_TARGET` output.
* `SET_SCHEME`: Writes the extracted scheme to `kong.service.request.scheme`. This is required when backends use different protocols, so Kong uses the correct scheme when connecting.
* `debug: true`: Enables trace output for this tutorial. Remove it before using this configuration in production.

## Validate the routing

To validate that routing via Datakit is working, retrieve access tokens from Keycloak using the client credentials grant, then send them as bearer tokens to verify that each caller is routed to the correct backend.

In the following requests, we're setting the `X-Datakit-Debug-Trace: true` request header so that Datakit returns a JSON trace in the response body showing each node's input and output.

1. Fetch a token as `caller-a`:

   ```sh
   export TOKEN_A=$(curl -s -X POST http://$KEYCLOAK_HOST:8080/realms/master/protocol/openid-connect/token \
     -d "client_id=caller-a" \
     -d "client_secret=$CALLER_A_SECRET" \
     -d "grant_type=client_credentials" | jq -r .access_token)
   ```

   Send a request as `caller-a`:
   ```sh
   curl -si http://localhost:8000/anything \
     -H "Authorization: Bearer $TOKEN_A" \
     -H "X-Datakit-Debug-Trace: true"
   ```

   The response comes from `httpbin.konghq.com`.
   In the response body, find the `complete` event for each node and check:
   * `GET_CREDENTIAL`: `value.value.id` is `caller-a`.
   * `PICK_TARGET`: `value.value` is `{"target":"httpbin.konghq.com:80","scheme":"http"}`.
   * `EXTRACT_TARGET`: `value.value` is `httpbin.konghq.com:80`.
   * `SET_TARGET`: `value.value` is `httpbin.konghq.com:80`.
   * `EXTRACT_SCHEME`: `value.value` is `http`.
   * `SET_SCHEME`: `value.value` is `http`.

1. Fetch a token as `caller-b` and send a request:

   ```sh
   export TOKEN_B=$(curl -s -X POST http://$KEYCLOAK_HOST:8080/realms/master/protocol/openid-connect/token \
     -d "client_id=caller-b" \
     -d "client_secret=$CALLER_B_SECRET" \
     -d "grant_type=client_credentials" | jq -r .access_token)
   ```

   Send a request as `caller-b`:
   ```sh
   curl -si http://localhost:8000/anything \
     -H "Authorization: Bearer $TOKEN_B" \
     -H "X-Datakit-Debug-Trace: true"
   ```

   The response comes from `httpbun.com`, confirming the request was routed to a different backend.
   `EXTRACT_TARGET` and `SET_TARGET` should show `httpbun.com:443`, and `EXTRACT_SCHEME` and `SET_SCHEME` should show `https`.

1. Fetch a token as the `kong` client to confirm the fallback:

   ```sh
   export TOKEN_FALLBACK=$(curl -s -X POST http://$KEYCLOAK_HOST:8080/realms/master/protocol/openid-connect/token \
     -d "client_id=$DECK_CLIENT_ID" \
     -d "client_secret=$DECK_CLIENT_SECRET" \
     -d "grant_type=client_credentials" | jq -r .access_token)
   ```

   Send a request as the fallback client:
   ```sh
   curl -si http://localhost:8000/anything \
     -H "Authorization: Bearer $TOKEN_FALLBACK" \
     -H "X-Datakit-Debug-Trace: true"
   ```

   `GET_CREDENTIAL` should show `value.value.id` as `kong`, and `EXTRACT_TARGET` and `SET_TARGET` should resolve to `httpbin.konghq.com:80` because `kong` isn't in the routing map.
