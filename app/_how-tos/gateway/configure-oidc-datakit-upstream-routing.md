---
title: Dynamically set upstream based on the authenticated caller with Datakit
permalink: /how-to/configure-oidc-datakit-upstream-routing/
content_type: how_to

related_resources:
  - text: OpenID Connect plugin
    url: /plugins/openid-connect/
  - text: Datakit plugin
    url: /plugins/datakit/
  - text: Dynamically set host based on the authenticated caller with Datakit
    url: /how-to/configure-oidc-datakit-host-routing/
  - text: OpenID Connect tutorials
    url: /how-to/?query=openid-connect

plugins:
  - openid-connect
  - datakit

entities:
  - route
  - service
  - upstream
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
  - upstream routing

description: Learn how to validate a bearer token with the OpenID Connect plugin, extract a claim as a credential, then use the Datakit plugin to route the request to a different upstream based on that credential.

tldr:
  q: How do I route requests to different backends based on who is making the request?
  a: |
    Configure the OpenID Connect plugin with `credential_claim` to extract a token claim (for example, `client_id`) and set it as the authenticated credential.
    Then, configure the Datakit plugin to read that credential, map its value to a named Upstream entity, and override the backend for the request.

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
2. [**Datakit**](/plugins/datakit/) reads that credential and maps its value to a named Upstream entity, overriding the backend for that specific request.

All callers share one Route and one Service, and the backend is decided dynamically after authentication.

This guide uses named Upstream entities, which preserves load balancing, health checks, and retries.
If you don't need those features and prefer to route directly to a `host:port` without a pool, see [Route requests to different targets based on the authenticated caller](/how-to/configure-oidc-datakit-host-routing/).

{:.info}
> **Note:** The OpenID Connect plugin has a higher [static priority](/gateway/entities/plugin/#plugin-priority) than Datakit, so it always runs first in the `access` phase.
> No explicit plugin ordering configuration is required.

## Generate salt token

{% include how-tos/steps/deck-salt-token.md %}

## Add upstreams

Create the named Upstream entities that Datakit will route to.
Each Upstream is a pool of targets, so load balancing, health checks, and retries are preserved when Datakit overrides the backend.

In this example, two callers route to separate upstreams and all other callers fall back to a default upstream.

{:.info}
> In this example, all three upstreams point at `httpbin.konghq.com` so you can run the guide end to end.
In production, each upstream would point at a different backend host.

{% entity_examples %}
entities:
  upstreams:
    - name: upstream-a
      targets:
        - target: httpbin.konghq.com:80
    - name: upstream-b
      targets:
        - target: httpbin.konghq.com:80
    - name: upstream-default
      targets:
        - target: httpbin.konghq.com:80
{% endentity_examples %}

Update the `example-service` Service so that its `host` points to `upstream-default`.
This is the default backend; Datakit overrides it per request based on the authenticated caller.

{% entity_examples %}
entities:
  services:
    - name: example-service
      host: upstream-default
      port: 80
      protocol: http
{% endentity_examples %}

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

Configure the Datakit plugin to read the credential set by the OpenID Connect plugin and map it to an upstream name.

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
          - name: PICK_UPSTREAM
            type: jq
            input: GET_CREDENTIAL
            jq: |
              {
                "caller-a": "upstream-a",
                "caller-b": "upstream-b"
              }[.id] // "upstream-default"
          - name: SET_UPSTREAM
            type: property
            property: kong.service.upstream
            input: PICK_UPSTREAM
        debug: true
{% endentity_examples %}

In this configuration:
* `GET_CREDENTIAL`: Reads the `kong.client.credential` object that the OpenID Connect plugin populates. No input is connected because this is a read-only (get) operation.
* `PICK_UPSTREAM`: Uses a jq map to look up the credential's `.id` field and return the matching upstream name. 
   The keys `caller-a` and `caller-b` match the `client_id` values in the tokens issued by the Keycloak clients you created in the prerequisites. 
   The `// "upstream-default"` fallback handles any caller whose ID isn't in the map.
* `SET_UPSTREAM`: Writes the resolved upstream name to `kong.service.upstream`, overriding the backend for this request. 
* `debug: true`: Enables trace output for this tutorial. Remove it before using this configuration in production.

## Validate the routing

To validate that routing via Datakit is working, retrieve access tokens from Keycloak using the client credentials grant, then send them as bearer tokens to verify that each caller is routed to the correct upstream.

All three upstreams point at the same host in this tutorial, so each request returns an HTTP 200 from `httpbin.konghq.com`.
In the following requests, we're setting the `X-Datakit-Debug-Trace: true` request header so that Datakit returns a JSON trace in the response body showing each node's input and output.

1. Fetch a token as `caller-a` :

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

   In the response body, find the `complete` event for each node and check:
   * `GET_CREDENTIAL`: `value.value.id` is `caller-a`.
   * `PICK_UPSTREAM`: `value.value` is `upstream-a`.
   * `SET_UPSTREAM`: `value.value` is `upstream-a`.

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

   `PICK_UPSTREAM` should resolve to `upstream-b`.

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

   `GET_CREDENTIAL` should show `value.value.id` as `kong`, and `PICK_UPSTREAM` should be `upstream-default` because `kong` isn't in the routing map.
