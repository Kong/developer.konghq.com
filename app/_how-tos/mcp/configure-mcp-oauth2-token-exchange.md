---
title: Configure token exchange with the AI MCP OAuth2 plugin
permalink: /mcp/configure-mcp-oauth2-token-exchange/
content_type: how_to
description: Learn how to configure token exchange with the AI MCP OAuth2 plugin using Keycloak
breadcrumbs:
  - /mcp/

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP OAuth2 plugin
    url: /plugins/ai-mcp-oauth2/
  - text: Token exchange in the AI MCP OAuth2 plugin
    url: /plugins/ai-mcp-oauth2/#token-exchange
  - text: AI MCP Proxy plugin
    url: /plugins/ai-mcp-proxy/
  - text: OAuth 2.0 specification for MCP
    url: https://modelcontextprotocol.io/specification/draft/basic/authorization

plugins:
  - ai-mcp-oauth2
  - ai-mcp-proxy

entities:
  - service
  - route
  - plugin

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.14'

tools:
  - deck

prereqs:
  inline:
    - title: Set up Keycloak with token exchange
      include_content: prereqs/auth/mcp-oauth2/keycloak-token-exchange
      icon_url: /assets/icons/keycloak.svg
    - title: Upstream MCP server
      content: |
        This guide uses a sample MCP server that exposes marketplace tools (users and orders).

        1. Clone and start the server:

            ```sh
            git clone https://github.com/tomek-labuk/marketplace-acl.git && \
            cd marketplace-acl && \
            npm install && \
            npm run build && \
            node dist/server.js
            ```

        1. Verify the server is running at `http://localhost:3001/mcp`.
  entities:
    services:
      - mcp-token-exchange-service
    routes:
      - mcp-token-exchange

tags:
  - ai
  - mcp
  - oauth2
  - authentication

tldr:
  q: How do I configure token exchange with the AI MCP OAuth2 plugin?
  a: |
    Configure the AI MCP Proxy plugin in passthrough-listener mode to proxy MCP traffic
    to an upstream MCP server. Add the AI MCP OAuth2 plugin with token exchange enabled.
    The plugin validates the incoming token, exchanges it for a new token, and forwards
    the exchanged token to the upstream.

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

## Configure the AI MCP Proxy plugin in passthrough-listener mode

Configure the [AI MCP Proxy plugin](/plugins/ai-mcp-proxy/) in `passthrough-listener` mode. This mode proxies incoming MCP requests directly to the upstream MCP server (the marketplace service running on port 3001) while generating observability metrics for the traffic.

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-proxy
      route: mcp-token-exchange
      config:
        mode: passthrough-listener
        max_request_body_size: 1048576
{% endentity_examples %}

## Configure the AI MCP OAuth2 plugin with token exchange

Configure the [AI MCP OAuth2 plugin](/plugins/ai-mcp-oauth2/) on the same Route. The plugin validates the incoming bearer token via introspection, then exchanges it for a new token at the Keycloak token endpoint before forwarding the request to the upstream MCP server.

Token exchange requires `passthrough_credentials` set to `true` so that the exchanged token is forwarded to the upstream.

{:.info}
> This example sets `insecure_relaxed_audience_validation` to `true` because most authorization servers do not yet include the resource URL in the `aud` claim as defined in [RFC 8707](https://datatracker.ietf.org/doc/html/rfc8707).

{% entity_examples %}
entities:
  plugins:
    - name: ai-mcp-oauth2
      route: mcp-token-exchange
      config:
        resource: http://localhost:8000/mcp
        metadata_endpoint: /.well-known/oauth-protected-resource/mcp
        authorization_servers:
          - ${keycloak_issuer}
        introspection_endpoint: ${keycloak_introspection_url}
        client_id: ${mcp_gateway_client_id}
        client_secret: ${mcp_gateway_client_secret}
        client_auth: client_secret_post
        insecure_relaxed_audience_validation: true
        passthrough_credentials: true
        claim_to_header:
          - claim: sub
            header: X-User-Id
        token_exchange:
          enabled: true
          token_endpoint: ${keycloak_token_url}
          client_auth: inherit
variables:
  keycloak_issuer:
    value: $KEYCLOAK_ISSUER
  keycloak_introspection_url:
    value: $KEYCLOAK_INTROSPECTION_URL
  keycloak_token_url:
    value: $KEYCLOAK_TOKEN_URL
  mcp_gateway_client_id:
    value: $MCP_GATEWAY_CLIENT_ID
  mcp_gateway_client_secret:
    value: $MCP_GATEWAY_CLIENT_SECRET
{% endentity_examples %}

Configuration breakdown:
* `resource`: The identifier for the protected MCP server. Matches the URL that MCP clients use to access it.
* `metadata_endpoint`: The path where the plugin serves OAuth Protected Resource Metadata. Must match one of the paths on the Route so MCP clients can discover the authorization server.
* `authorization_servers` and `introspection_endpoint`: Connect the plugin to Keycloak for token validation.
* `client_id`, `client_secret`, and `client_auth`: Credentials that {{site.base_gateway}} uses to authenticate with the introspection and token exchange endpoints.
* `passthrough_credentials`: Required for token exchange. Forwards the exchanged token to the upstream MCP server.
* `claim_to_header`: Maps the `sub` claim from the validated token to the `X-User-Id` upstream header.
* `token_exchange.enabled`: Activates token exchange after successful token validation.
* `token_exchange.token_endpoint`: The Keycloak token endpoint where the exchange request is sent.
* `token_exchange.client_auth: inherit`: Reuses the `client_id` and `client_secret` configured for introspection.

{:.info}
> The `token_exchange.request` block also supports `audience` and `scopes` fields for IdPs that honor them (for example, Okta or Azure AD). Keycloak 26 does not support custom audience targets in standard token exchange, so these fields are omitted here.

## Validate

### Verify unauthenticated requests are rejected

Send a request without a token:

```sh
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/mcp \
  --json '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

The response returns `401`, confirming the [AI MCP OAuth2 plugin](/plugins/ai-mcp-oauth2/) is enforcing authentication.

### Verify authenticated MCP requests succeed

Obtain a token from Keycloak as the `mcp-client` and list the available MCP tools. Run both commands together because Keycloak access tokens expire in 60 seconds:

```sh
export TOKEN=$(curl -s -X POST \
  http://localhost:8080/realms/master/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=$DECK_MCP_CLIENT_ID" \
  -d "client_secret=$DECK_MCP_CLIENT_SECRET" \
  -d "username=alex" \
  -d "password=doe" \
  -d "scope=openid" | jq -r '.access_token') && \
curl --no-progress-meter --fail-with-body http://localhost:8000/mcp \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

A successful response returns the tools exposed by the upstream MCP server:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [
      {"name": "list_users", "description": "List all users (id, fullName)."},
      {"name": "get_user", "description": "Get a single user by id."},
      {"name": "list_orders", "description": "List all orders."},
      {"name": "list_orders_for_user", "description": "List orders by userId."},
      {"name": "search_orders", "description": "Search orders by name (case-insensitive substring)."}
    ]
  }
}
```
{:.no-copy-code}

Call a tool to verify the full request chain, including token exchange:

```sh
export TOKEN=$(curl -s -X POST \
  http://localhost:8080/realms/master/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=$DECK_MCP_CLIENT_ID" \
  -d "client_secret=$DECK_MCP_CLIENT_SECRET" \
  -d "username=alex" \
  -d "password=doe" \
  -d "scope=openid" | jq -r '.access_token') && \
curl --no-progress-meter --fail-with-body http://localhost:8000/mcp \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"list_users","arguments":{}},"id":2}'
```

A successful response with marketplace data confirms that {{site.base_gateway}} validated the original `mcp-client` token, exchanged it at the Keycloak token endpoint, and forwarded the exchanged token to the upstream MCP server.
