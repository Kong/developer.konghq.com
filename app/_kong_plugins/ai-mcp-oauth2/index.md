---
title: 'AI MCP OAuth2'
name: 'AI MCP OAuth2'

content_type: plugin
tier: ai_gateway_enterprise
publisher: kong-inc
description: 'Secure MCP server access with OAuth2 authentication'

tech_preview: true
products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.12'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

tags:
  - ai
  - mcp

search_aliases:
  - ai-mcp-oauth2
  - OAuth2
  - MCP


icon: ai-mcp-oauth2.png

categories:
   - ai
related_resources:
  - text: OAuth 2.0 specification for MCP
    url: https://modelcontextprotocol.io/specification/draft/basic/authorization
  - text: MCP Traffic Gateway
    url: /mcp/
---

The AI MCP OAuth2 plugin secures Model Context Protocol (MCP) traffic on {{site.ai_gateway}} using [OAuth 2.0 specification for MCP servers](https://modelcontextprotocol.io/specification/draft/basic/authorization). It ensures only authorized MCP clients can access protected MCP servers, and acts as a crucial security layer for MCP servers.


{:.warning}
> **Breaking change**
>
> {% new_in 3.13 %}The MCP OAuth2 plugin now treats all incoming traffic as MCP requests to address a potential authentication bypass vulnerability.
>
> Do not use this plugin with the [AI MCP Proxy](/plugins/ai-mcp-proxy) plugin in [`conversion-listener` mode](/plugins/ai-mcp-proxy/#configuration-modes) on the same route. Non-MCP requests will fail.
>
> Use MCP OAuth2 with MCP Proxy in `listener` or `passthrough-listener` modes. For REST API exposure, configure MCP Proxy in `conversion-only` mode on a separate route.

## Purpose and core functionality

The plugin provides OAuth 2.0 authentication for MCP traffic, allowing MCP clients to safely request access. It validates that access tokens are issued specifically for the target MCP server, ensuring only authorized requests are accepted. To reduce the risk of token theft or confused deputy attacks, the plugin does not pass access tokens to upstream services.

The plugin performs three core functions:

* Validates incoming MCP requests by verifying access tokens from an external Authorization Server.
* Extracts claims from validated tokens and forwards them to upstream MCP services via headers.
* Ensures compliance with MCP authorization requirements based on OAuth 2.1.

## Authorization flow

The plugin follows the following authorization flow:

* {{site.ai_gateway}} acts as the **Resource Server**, enforcing access control.
* The MCP clients send requests with a valid `Authorization: Bearer <access-token>` header.
* The plugin validates tokens, checks the intended audience, and blocks invalid or expired tokens with a `401 Unauthorized`.
* Access tokens are **never passed to upstream services**, protecting against token theft or confused deputy attacks.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP client
    participant K as AI MCP OAuth2 plugin
    participant AS as Authorization server
    participant U as Upstream MCP server

    C->>K: Discover protected resource metadata
    activate K
    K-->>C: Protected resource metadata (includes auth server address)
    deactivate K

    C->>AS: Request access token
    activate AS
    AS-->>C: Access token
    deactivate AS

    C->>K: MCP auth request
    activate K
    K->>AS: Introspect token
    activate AS
    AS-->>K: Valid / invalid
    deactivate AS

    alt If token valid
        K->>U: Forward request with claims as headers
        activate U
        U-->>K: MCP server response
        deactivate U
        K-->>C: MCP response
    else If token invalid
        K-->>C: 401 Unauthorized
    end
    deactivate K

{% endmermaid %}
<!-- vale on -->

## Plugin execution

The AI MCP OAuth2 plugin is designed to secure MCP traffic as early as possible in the request lifecycle to prevent unauthorized access before any AI-specific processing occurs.

{:.warning}
> **Note:** Like, the AI MCP Proxy plugin, the AI MCP OAuth2 plugin is not invoked as part of an LLM request flow.
>
> Instead, it is registered and executed as a regular plugin, allowing it to capture MCP traffic independently of LLM request flow.
> The AI MCP OAuth2 plugin can be used on its own for upstream MCP proxying or in combination with the AI MCP Proxy plugin when request/response conversion is needed.

## Token validation methods {% new_in 3.14 %}

The plugin supports multiple token validation methods simultaneously. You can configure an introspection endpoint, a JWKS endpoint, or both. When both are configured, the plugin tries each method in turn.

* **Introspection**: Set [`config.introspection_endpoint`](./reference/#schema--config-introspection-endpoint) to have the plugin call the authorization server to validate opaque tokens. Requires `config.client_id` when `config.client_auth` is `client_secret_basic` or `client_secret_post`.
* **JWKS**: Set [`config.jwks_endpoint`](./reference/#schema--config-jwks-endpoint) to validate signed JWTs locally using the authorization server's public keys. If not set, the plugin attempts to discover the JWKS URI from the authorization server metadata.

## Claim forwarding

The plugin can extract claims from a validated token and forward them to the upstream MCP server as HTTP headers. Two approaches are available, and they are mutually exclusive.

### Top-level claims

Use [`config.claim_to_header`](./reference/#schema--config-claim-to-header) to map top-level token claims to upstream headers. Each entry requires a `claim` name and a `header` name:

```yaml
claim_to_header:
  - claim: sub
    header: X-User-Id
  - claim: email
    header: X-User-Email
```

### Nested claims {% new_in 3.14 %}

Use [`config.upstream_headers`](./reference/#schema--config-upstream-headers) to map claims at any depth in the token payload using a path array. This field is mutually exclusive with `claim_to_header`:

```yaml
upstream_headers:
  - header: X-Org-Id
    path:
      - org
      - id
  - header: X-Role
    path:
      - realm_access
      - roles
      - 0
```

## Consumer mapping {% new_in 3.14 %}

The plugin can map token claims to Kong consumers and consumer groups, enabling consumer-based rate limiting, ACL, and other consumer-aware plugins to function with MCP traffic.

### Consumer

Set [`config.consumer_claim`](./reference/#schema--config-consumer-claim) to the path of the claim to use for consumer lookup. If multiple strings are provided, the plugin treats them as a nested path in the token payload.

```yaml
consumer_claim:
  - sub
```

Use [`config.consumer_by`](./reference/#schema--config-consumer-by) to control which consumer fields are checked during lookup. Accepted values are `id`, `username`, and `custom_id`. Defaults to `["username", "custom_id"]`.

Set [`config.consumer_optional`](./reference/#schema--config-consumer-optional) to `true` if you want the plugin to continue without failing when no matching consumer is found.

### Consumer groups

Set [`config.consumer_groups_claim`](./reference/#schema--config-consumer-groups-claim) to the path of the claim containing the consumer group names. If multiple strings are provided, the plugin treats them as a nested path.

```yaml
consumer_groups_claim:
  - groups
```

Set [`config.consumer_groups_optional`](./reference/#schema--config-consumer-groups-optional) to `true` to allow the request to proceed even if no matching consumer group is found.

### Virtual credentials

When consumer mapping is not used, set [`config.credential_claim`](./reference/#schema--config-credential-claim) to derive a virtual credential from the token. This credential is used by plugins like rate-limiting to track usage. Defaults to `["sub"]`.

## Token exchange {% new_in 3.14 %}

Token exchange lets the plugin swap the client's access token for a different token before forwarding the request to the upstream MCP server. This is useful when the upstream requires a token from a different authorization server or with different scopes.

{:.info}
> Token exchange requires [`config.passthrough_credentials`](./reference/#schema--config-passthrough-credentials) to be set to `true`.

When `config.token_exchange.enabled` is `true`, the plugin performs the following after validating the incoming token:

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP client
    participant K as AI MCP OAuth2 plugin
    participant AS as Authorization server
    participant TE as Token exchange endpoint
    participant U as Upstream MCP server

    C->>K: MCP request with Bearer token
    activate K
    K->>AS: Validate token (introspect / JWKS)
    activate AS
    AS-->>K: Token valid
    deactivate AS
    K->>TE: Token exchange request (subject_token = original token)
    activate TE
    TE-->>K: Exchanged access token
    deactivate TE
    K->>U: Forward request with exchanged token
    activate U
    U-->>K: MCP server response
    deactivate U
    K-->>C: MCP response
    deactivate K
{% endmermaid %}
<!-- vale on -->

The `client_auth` field controls how the plugin authenticates with the token exchange endpoint. Accepted values are `client_secret_basic`, `client_secret_post`, `none`, and `inherit`. When `inherit` is used, the plugin reuses the `client_id` and `client_secret` configured for the introspection endpoint.

When `config.token_exchange.request.actor_token_source` is set to `header`, provide the name of the header carrying the actor token in `actor_token_header`. When set to `config`, provide the static actor token value in `actor_token`.

Exchanged tokens are cached by default. Set `config.token_exchange.cache.enabled` to `false` to disable caching. The TTL defaults to `3600` seconds and is used when the token exchange endpoint does not return an `expires_in` value.

## Token passthrough {% new_in 3.14 %}

By default, the plugin strips the incoming access token before forwarding the request to the upstream MCP server, preventing token theft and confused deputy attacks. Set [`config.passthrough_credentials`](./reference/#schema--config-passthrough-credentials) to `true` to keep the original token in the request.

{:.warning}
> Only enable token passthrough when the upstream MCP server explicitly requires the original access token, or when token exchange is configured.
