---
title: 'AI MCP OAuth2'
name: 'AI MCP OAuth2'

content_type: policy
publisher: kong-inc
description: 'Secure MCP server access with OAuth2 authentication'

tech_preview: true
products:
    - ai-gateway

works_on:
    - konnect

min_version:
    ai-gateway: '2.0'

tags:
  - ai
  - mcp
  - security

search_aliases:
  - ai-mcp-oauth2
  - OAuth2
  - MCP


icon: ai-mcp-oauth2.png

categories:
   - ai
related_resources:
  - text: OAuth 2.0 specification for MCP
    url: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization
  - text: AI MCP Server
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Policy
    url: /ai-gateway/entities/ai-policy/
---

The AI MCP OAuth2 Policy secures Model Context Protocol (MCP) traffic on {{site.ai_gateway}} using [OAuth 2.0 specification for MCP servers](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization). It ensures only authorized MCP clients can access protected MCP servers proxied via an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity, and acts as a crucial security layer for MCP traffic.

## Purpose and core functionality

The AI MCP OAuth2 Policy provides OAuth 2.0 authentication for MCP traffic, allowing MCP clients to safely request access. It validates that access tokens are issued specifically for the target MCP server, ensuring only authorized requests are accepted. To reduce the risk of token theft or confused deputy attacks, the Policy does not pass access tokens to upstream services.

The Policy performs three core functions:

* Validates incoming MCP requests by verifying access tokens from an external Authorization Server.
* Extracts claims from validated tokens and forwards them to upstream MCP services via headers.
* Ensures compliance with MCP authorization requirements based on OAuth 2.1.

## Authorization flow

The AI MCP OAuth2 Policy follows the following authorization flow:

* {{site.ai_gateway}} acts as the **Resource Server**, enforcing access control.
* The MCP clients send requests with a valid `Authorization: Bearer <access-token>` header.
* The Policy validates tokens, checks the intended audience, and blocks invalid or expired tokens with a `401 Unauthorized`.
* Access tokens are **not forwarded to upstream services** by default, protecting against token theft or confused deputy attacks.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP client
    participant K as AI MCP OAuth2<br/>(resource server)
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

## Policy execution

The AI MCP OAuth2 Policy is designed to secure MCP traffic as early as possible in the request lifecycle to prevent unauthorized access before any AI-specific processing occurs.

{:.warning}
> **Note:** The AI MCP OAuth2 Policy is not invoked as part of an LLM request flow.
>
> Instead, it targets API traffic (MCP traffic specifically), allowing it to capture MCP requests independently of LLM request flow.
> LLM-specific policies will not be applied to MCP traffic. Use this Policy with API-traffic policies like Rate Limiting Advanced, and other API-level policies as needed.

## Token validation methods

The Policy supports two token validation methods. When introspection is configured, it is always used. JWKS is only used when no introspection endpoint is configured.

* **Introspection**: Set [`config.introspection_endpoint`](./reference/#schema--config-introspection-endpoint) to have the Policy call the authorization server to validate opaque tokens. Requires `config.client_id` when `config.client_auth` is `client_secret_basic` or `client_secret_post`.
* **JWKS**: Set [`config.jwks_endpoint`](./reference/#schema--config-jwks-endpoint) to validate signed JWTs locally using the authorization server's public keys. If not set, the Policy attempts to discover the JWKS URI from the authorization server metadata.

## Claim forwarding

The Policy can extract claims from a validated token and forward them to the upstream MCP server as HTTP headers. Two approaches are available, and they are mutually exclusive.

### Top-level claims

Use [`config.claim_to_header`](./reference/#schema--config-claim-to-header) to map top-level token claims to upstream headers. Each entry requires a `claim` name and a `header` name:

{% entity_example %}
type: policy
data:
  name: oauth2-map-user-claims
  display_name: OAuth2 Map User Claims
  type: ai-mcp-oauth2
  config:
    resource: https://api.example.com/mcp
    authorization_servers:
      - https://auth.example.com
    claim_to_header:
      - claim: sub
        header: X-User-Id
      - claim: email
        header: X-User-Email
formats:
  - konnect-api
{% endentity_example %}

### Nested claims

Use [`config.upstream_headers`](./reference/#schema--config-upstream-headers) to map claims at any depth in the token payload using a path array. This field is mutually exclusive with `claim_to_header`:

{% entity_example %}
type: policy
data:
  name: oauth2-map-nested-claims
  display_name: OAuth2 Map Nested Claims
  type: ai-mcp-oauth2
  config:
    resource: https://api.example.com/mcp
    authorization_servers:
      - https://auth.example.com
    upstream_headers:
      - header: X-Org-Id
        path:
          - org
          - id
      - header: X-User-Role
        path:
          - realm_access
          - roles
formats:
  - konnect-api
{% endentity_example %}

## AI Consumer and AI Consumer Group mapping

The Policy can map token claims to [AI Consumers](/ai-gateway/entities/ai-consumer/) and [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/), enabling consumer-based rate limiting, ACL, and other consumer-aware policies to function with MCP traffic.

### AI Consumer

You can map individual users from your authorization server to AI Consumers for per-user rate limiting, usage tracking, and access control. For example, map the user's unique identifier (like `sub` or email) from the token to an AI Consumer, then apply policies such as rate limiting to individual users.

Configure AI Consumer lookup:

* Set [`config.consumer_claim`](./reference/#schema--config-consumer-claim) to the path of the claim identifying the AI Consumer. For example, `["sub"]` for top-level claims or `["realm_access", "user_id"]` for nested claims.
* Use [`config.consumer_by`](./reference/#schema--config-consumer-by) to specify which AI Consumer fields to check. Accepted values: `id`, `username`, `custom_id`. Defaults to `["username", "custom_id"]`.
* Set [`config.consumer_optional`](./reference/#schema--config-consumer-optional) to `true` to allow requests to proceed if no matching AI Consumer is found.

{% entity_example %}
type: policy
data:
  name: oauth2-with-consumer
  display_name: OAuth2 with Consumer Mapping
  type: ai-mcp-oauth2
  config:
    resource: https://api.example.com/mcp
    authorization_servers:
      - https://auth.example.com
    consumer_claim:
      - sub
    consumer_by:
      - username
      - custom_id
    consumer_optional: false
formats:
  - konnect-api
{% endentity_example %}

### AI Consumer Groups

You can also map token claims to AI Consumer Groups to enforce team or organization-level rate limiting and access policies. For example, map users from your authorization server's `teams` or `organizations` claims to AI Consumer Groups, then apply policies at the group level across multiple MCP clients.

Configure AI Consumer Group lookup:

* Set [`config.consumer_groups_claim`](./reference/#schema--config-consumer-groups-claim) to the path of the claim containing the AI Consumer Group names. Supports nested paths with multiple strings.
* Set [`config.consumer_groups_optional`](./reference/#schema--config-consumer-groups-optional) to `true` to allow requests to proceed if no matching AI Consumer Group is found.

{% entity_example %}
type: policy
data:
  name: oauth2-with-teams
  display_name: OAuth2 with Team Mapping
  type: ai-mcp-oauth2
  config:
    resource: https://api.example.com/mcp
    authorization_servers:
      - https://auth.example.com
    consumer_groups_claim:
      - groups
    consumer_groups_optional: true
formats:
  - konnect-api
{% endentity_example %}

### Virtual credentials

When consumer mapping is not used, set [`config.credential_claim`](./reference/#schema--config-credential-claim) to derive a virtual credential from the token. This credential is used by other policies to track usage. Defaults to `["sub"]`.

## Token exchange

Token exchange lets the Policy swap the client's access token for a different token before forwarding the request to the upstream MCP server. This is useful when the upstream MCP server requires a token from a different authorization server or with different scopes.

{:.info}
> Token exchange requires [`config.passthrough_credentials`](./reference/#schema--config-passthrough-credentials) to be set to `true`.

When `config.token_exchange.enabled` is `true`, the Policy performs the following after validating the incoming token:

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP client
    participant K as AI MCP OAuth2<br/>(resource server)
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

Configure token exchange:

* Set [`config.token_exchange.enabled`](./reference/#schema--config-token-exchange) to `true` to activate token exchange.
* Use [`client_auth`](./reference/#schema--config-token-exchange-client-auth) to control authentication with the token exchange endpoint. Accepted values: `client_secret_basic`, `client_secret_post`, `none`, `inherit`. Use `inherit` to reuse credentials from the introspection endpoint.
* Set [`config.token_exchange.request.actor_token_source`](./reference/#schema--config-token-exchange-request) to `header` to extract the actor token from a request header, or `config` to use a static token value.
* Exchanged tokens are cached by default. Set [`config.token_exchange.cache.enabled`](./reference/#schema--config-token-exchange-cache) to `false` to disable caching. TTL defaults to `3600` seconds.

The following example creates an AI MCP Oauth2 Policy that validates client tokens with one authorization server and exchanges them for tokens from a different server before forwarding to the upstream MCP server:

{% entity_example %}
type: policy
data:
  name: mcp-oauth2-token-exchange
  display_name: MCP OAuth2 Token Exchange
  type: ai-mcp-oauth2
  config:
    passthrough_credentials: true
    authorization_servers:
      - https://auth.example.com
    consumer_claim:
      - sub
    consumer_by:
      - username
      - custom_id
    consumer_optional: false
    token_exchange:
      enabled: true
      endpoint: https://auth.example.com/oauth/token
      client_auth: client_secret_basic
      request:
        actor_token_source: header
      cache:
        enabled: true
        ttl: 3600
formats:
  - konnect-api
{% endentity_example %}

## Token passthrough

By default, the Policy strips the incoming access token before forwarding the request to the upstream MCP server, preventing token theft and confused deputy attacks. Set [`config.passthrough_credentials`](./reference/#schema--config-passthrough-credentials) to `true` to keep the original token in the request.

{:.warning}
> Only enable token passthrough when the upstream MCP server explicitly requires the original access token, or when token exchange is configured.
