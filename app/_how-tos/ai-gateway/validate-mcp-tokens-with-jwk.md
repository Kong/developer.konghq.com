---
title: Validate MCP tokens locally with JWK verification
content_type: how_to
description: "Configure the AI MCP OAuth2 plugin to validate MCP access tokens locally using the authorization server's published JWK Set instead of token introspection"
products:
  - gateway
  - ai-gateway
works_on:
  - on-prem
  - konnect
min_version:
  gateway: '3.14'
plugins:
  - ai-mcp-oauth2
  - ai-mcp-proxy
entities:
  - service
  - route
  - plugin
permalink: /how-to/validate-mcp-tokens-with-jwk/
tags:
  - ai
  - mcp
  - authentication
tldr:
  q: "How do I validate MCP tokens locally without calling an introspection endpoint?"
  a: "Set `jwks_endpoint` in the AI MCP OAuth2 plugin config. Kong fetches the authorization server's public keys, caches them, and validates each incoming JWT locally without a per-request round-trip."
tools:
  - deck
related_resources:
  - text: AI MCP OAuth2 plugin
    url: /plugins/ai-mcp-oauth2/
  - text: AI MCP Proxy plugin
    url: /plugins/ai-mcp-proxy/
  - text: Secure MCP tools with OAuth2 and Okta (introspection)
    url: /mcp/secure-mcp-tools-with-oauth2-and-okta/
prereqs:
  inline:
    - title: WeatherAPI
      icon_url: /assets/icons/gateway.svg
      content: |
        1. Go to [WeatherAPI](https://www.weatherapi.com/).
        1. Sign up for a free account.
        1. Navigate to [your dashboard](https://www.weatherapi.com/my/) and copy your API key.
        1. Export your API key:

            ```sh
            export DECK_WEATHERAPI_API_KEY='your-weatherapi-api-key'
            ```
    - title: Set up Keycloak
      icon_url: /assets/icons/gateway.svg
      content: |
        This guide uses [Keycloak](http://www.keycloak.org/) as the authorization server. Keycloak publishes a JWKS endpoint that Kong uses to validate tokens locally.

        #### Install and run Keycloak

        Run the Keycloak Docker image on the same network as Kong Gateway:

        ```sh
        docker run -p 127.0.0.1:8080:8080 \
          --name keycloak \
          --network kong-quickstart-net \
          -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
          -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
          -e KC_HOSTNAME=http://localhost:8080 \
          quay.io/keycloak/keycloak start-dev
        ```

        Export the Keycloak endpoints. `DECK_KEYCLOAK_ISSUER` uses `localhost` (reachable from your machine). `DECK_KEYCLOAK_JWKS_ENDPOINT` uses the container name `keycloak` (reachable from Kong Gateway over the shared Docker network):

        ```sh
        export DECK_KEYCLOAK_ISSUER='http://localhost:8080/realms/master'
        export DECK_KEYCLOAK_JWKS_ENDPOINT='http://keycloak:8080/realms/master/protocol/openid-connect/certs'
        export KEYCLOAK_HOST='localhost'
        ```

        #### Create the MCP client

        1. Open the Keycloak admin console at `http://localhost:8080/admin/master/console/`.
        1. In the sidebar, open **Clients**, then click **Create client**.
        1. **General settings**: Client type: **OpenID Connect**, Client ID: `mcp-gateway`.
        1. **Capability config**: Toggle **Client authentication** to **on**. Check **Service accounts roles** (this enables the `client_credentials` grant).
        1. **Login settings**: Set **Valid redirect URIs** to `http://localhost:8000/*`.
        1. Click **Save**.
        1. Open the **Credentials** tab, copy the **Client Secret**, and export it:

            ```sh
            export DECK_MCP_CLIENT_ID='mcp-gateway'
            export DECK_MCP_CLIENT_SECRET='YOUR-CLIENT-SECRET'
            ```

        #### Configure the audience claim

        Keycloak does not include a custom audience in tokens by default. Add a client scope mapper so that tokens issued by `mcp-gateway` include the MCP resource URL in the `aud` claim. This lets Kong validate the audience without relaxing validation.

        1. In the sidebar, open **Client scopes**, then click **Create client scope**.
        1. Name: `mcp-audience`. Click **Save**.
        1. Open the **Mappers** tab, click **Configure a new mapper**, and select **Audience**.
        1. Name: `mcp-resource-audience`.
        1. **Included Custom Audience**: `http://localhost:8000/weather/mcp`
        1. Toggle **Add to access token** to **on**.
        1. Click **Save**.
        1. In the sidebar, open **Clients**, click `mcp-gateway`, then click the **Client scopes** tab.
        1. Click **Add client scope**, check `mcp-audience`, click **Add** and set the scope as **Default**.
  entities:
    services:
      - weather-jwk-service
    routes:
      - weather-jwk-route
      - weather-jwk
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
faqs:
  - q: When should I use JWK validation instead of token introspection?
    a: |
      Use JWK validation when your authorization server publishes a JWKS endpoint and issues JWTs. JWK validation avoids per-request round-trips to the authorization server, since Kong validates tokens locally after fetching and caching the public keys.

      Use token introspection when the authorization server issues opaque tokens (not JWTs), or when you need real-time token revocation checks on every request. Introspection requires `client_id`, `client_secret`, and `introspection_endpoint`.
  - q: What happens when the authorization server rotates its keys?
    a: |
      Kong caches the JWK Set for the duration specified in `jwks_cache_ttl` (in seconds). If an incoming token's `kid` (key ID) does not match any key in the cache, the plugin automatically invalidates the cache, re-fetches the JWKS, and retries validation once. If the key is still not found after the refresh, Kong returns `401`. This means routine key rotations are handled transparently without waiting for the TTL to expire.
  - q: Do I still need client_id and client_secret in the plugin config with JWK validation?
    a: |
      No. The `client_id` and `client_secret` fields in the AI MCP OAuth2 plugin config are used for token introspection, where Kong calls the authorization server's introspection endpoint as a confidential client. With JWK validation, Kong validates tokens locally and does not need these credentials.
  - q: What claims does Kong validate with JWK verification?
    a: |
      Kong validates the token signature against the cached public keys, checks the `exp` and `nbf` claims to confirm the token is not expired and not used before its valid time, and verifies the issuer (`iss`) against the configured `authorization_servers`. If `insecure_relaxed_audience_validation` is `false` (the default), Kong also validates the audience (`aud`) claim against the `resource` value. You can use `jwt_claims_leeway` to allow a small tolerance (in seconds) for clock skew between Kong and the authorization server.
  - q: What happens if Kong can't reach the JWKS endpoint?
    a: |
      If Kong cannot fetch the JWKS (network failure, authorization server outage), it returns `503`. As long as the cached keys have not expired, Kong continues to validate tokens using the cached JWKS without contacting the authorization server.
---

## Configure the AI MCP Proxy tools

Configure the [AI MCP Proxy plugin](/plugins/ai-mcp-proxy/) in `conversion-only` mode on the `weather-jwk-route` Route. This instance converts the WeatherAPI REST endpoints into MCP tool definitions. The `weather-tools` tag lets the listener instance discover and aggregate these tools.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: weather-jwk-route
      tags:
        - weather-tools
      config:
        mode: conversion-only
        tools:
          - annotations:
              title: Realtime API
            description: Returns current weather data as a JSON object for a given location.
            method: GET
            path: current.json
            query:
              key:
                - ${weatherapi_key}
            parameters:
              - name: q
                in: query
                description: Pass US Zipcode, UK Postcode, Canada Postalcode, IP address, Latitude/Longitude (decimal degree) or city name.
                required: true
                type: string
variables:
  weatherapi_key:
    value: $WEATHERAPI_API_KEY
{% endentity_examples %}

## Configure the AI MCP Proxy listener

Configure a second [AI MCP Proxy plugin](/plugins/ai-mcp-proxy/) instance in `listener` mode on the `weather-jwk` Route. This instance aggregates tools tagged `weather-tools` and serves them over the MCP protocol to connected clients.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: weather-jwk
      config:
        mode: listener
        server:
          tag: weather-tools
          timeout: 45000
        logging:
          log_statistics: true
          log_payloads: false
        max_request_body_size: 32768
{% endentity_examples %}

## Configure the AI MCP OAuth2 plugin with JWK validation

Configure the [AI MCP OAuth2 plugin](/plugins/ai-mcp-oauth2/) on the `weather-jwk` Route with `jwks_endpoint` pointing at Keycloak's certificate endpoint. Kong fetches the public keys, caches them for the duration set in `jwks_cache_ttl`, and validates each incoming JWT locally.

The `resource` field identifies this MCP server. Because we configured a [client scope mapper](#configure-the-audience-claim) in Keycloak to include this URL in the `aud` claim, Kong can validate the audience with `insecure_relaxed_audience_validation` set to `false` (the default).

The `metadata_endpoint` path must match one of the paths on the `weather-jwk` Route so the plugin can serve the OAuth Protected Resource Metadata that MCP clients need to discover the authorization server.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-oauth2
      route: weather-jwk
      config:
        authorization_servers:
          - ${keycloak_issuer}
        jwks_endpoint: ${keycloak_jwks_endpoint}
        jwks_cache_ttl: 3600
        resource: http://localhost:8000/weather/mcp
        metadata_endpoint: "/.well-known/oauth-protected-resource/weather/mcp"
variables:
  keycloak_issuer:
    value: $KEYCLOAK_ISSUER
  keycloak_jwks_endpoint:
    value: $KEYCLOAK_JWKS_ENDPOINT
{% endentity_examples %}

Notice what's absent compared to the [introspection-based config](/mcp/secure-mcp-tools-with-oauth2-and-okta/): no `client_id`, no `client_secret`, no `introspection_endpoint`, and no `insecure_relaxed_audience_validation`. Kong validates tokens locally using the public keys from the JWKS endpoint, and audience validation works because Keycloak includes the resource URL in the `aud` claim.

`jwks_cache_ttl` controls how long Kong caches the fetched keys, in seconds. The default is `3600` (one hour). If an incoming token's `kid` does not match any cached key (for example, after a key rotation), the plugin re-fetches the JWKS and retries once before returning `401`.

{:.info}
> If you omit `jwks_endpoint`, the plugin attempts to discover the JWKS URL from the authorization server's metadata (for example, from `/.well-known/openid-configuration`). Set `jwks_endpoint` explicitly when the authorization server is reachable at a different hostname from Kong's perspective, as is the case with Docker networking in this guide.

## Validate

### Get a token from Keycloak

Obtain a JWT from Keycloak using the `client_credentials` grant:

```sh
MCP_TOKEN=$(curl -s -X POST \
  http://$KEYCLOAK_HOST:8080/realms/master/protocol/openid-connect/token \
  -d "grant_type=client_credentials" \
  -d "client_id=$DECK_MCP_CLIENT_ID" \
  -d "client_secret=$DECK_MCP_CLIENT_SECRET" | jq -r .access_token) && echo $MCP_TOKEN
```

You can decode the token to confirm the claims. The `aud` claim should include `http://localhost:8000/weather/mcp` (from the scope mapper) and the `iss` claim should match `DECK_KEYCLOAK_ISSUER`:

```sh
echo $MCP_TOKEN | cut -d. -f2 | base64 -d 2>/dev/null | jq .
```

```json
{
  "iss": "http://localhost:8080/realms/master",
  "aud": "http://localhost:8000/weather/mcp",
  "azp": "mcp-gateway",
  "exp": 1775253107,
  "iat": 1775253047
}
```
{:.no-copy-code}

### Confirm unauthenticated requests are rejected

Send a request without a token:

```sh
curl -i --no-progress-meter --fail-with-body http://localhost:8000/weather/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

The response returns a `401` status, confirming the plugin is enforcing authentication.

### Confirm valid tokens are accepted

Send a request with the JWT:

```sh
curl --no-progress-meter --fail-with-body http://localhost:8000/weather/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $MCP_TOKEN" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

A successful response returns the list of available MCP tools, confirming that Kong validated the token's signature against the cached JWK Set and verified the `iss`, `exp`, and `aud` claims.

### Confirm tampered tokens are rejected

Modify one character in the token and send the request again:

```sh
curl -i --no-progress-meter --fail-with-body http://localhost:8000/weather/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${MCP_TOKEN}x" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

The response returns `401`, confirming that Kong rejects tokens with invalid signatures.

<!--vale on-->