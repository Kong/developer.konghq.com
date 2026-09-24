---
title: "OpenID Connect authentication with {{site.ai_gateway}} 2.0"
layout: reference
content_type: reference
description: Learn how the OpenID Connect AI Auth Strategy authenticates AI Consumers in {{site.ai_gateway}} 2.0 and the OpenID Connect capabilities you can use.
breadcrumbs:
  - /ai-gateway/

works_on:
  - konnect

products:
  - ai-gateway

tools:
  - kongctl

tags:
  - ai
  - authentication
  - openid-connect

min_version:
  ai-gateway: '2.0'

schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayAuthStrategyOpenIDConnectConfig

related_resources:
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: Kong Identity principals and directories
    url: /identity/principals/
  - text: Identify AI Consumers on AI Model traffic with Kong Identity
    url: /ai-gateway/identify-ai-consumers-with-kong-identity/
  - text: OpenID Connect plugin reference
    url: /plugins/openid-connect/
---

{{site.ai_gateway}} uses [AI Auth Strategies](/ai-gateway/entities/ai-auth-strategy/) to authenticate consumers and tools with [AI Models](/ai-gateway/entities/ai-model/), [AI Agents](/ai-gateway/entities/ai-agent/), and [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/).
Depending on how they are configured, AI Auth Strategies allow you to authenticate users and tools, attribute usage to [AI Consumers](/ai-gateway/entities/ai-consumer/), and deny unauthenticated requests.

AI Auth Strategies support both [key auth](/ai-gateway/entities/ai-auth-strategy/#api-key-authentication) and OpenID Connect authentication methods.
When you use the OpenID Connect authentication method, you accept the JWT bearer tokens or OAuth 2.0 grants your AI Consumers already get from an OIDC-compliant identity provider (IdP) instead of issuing and rotating static API keys like you would with key auth.

Use the OpenID Connect AI Auth Strategy when your AI Consumers already authenticate through an enterprise IdP and you want to accept the tokens they already have, rather than issuing separate keys.
Use key auth instead when your AI Consumers are internal tools or scripts you control and you'd rather issue and rotate static API keys directly.
An AI Model can use both at once, since a single AI Model's caller population is often mixed.
For example, attach key auth for internal automation and OpenID Connect for user-facing applications on the same AI Model.
A request is authenticated if it satisfies either strategy.

Internally, the OpenID Connect AI Auth Strategy's `config` object passes through to {{site.base_gateway}}'s [OpenID Connect plugin](/plugins/openid-connect/).
{{site.ai_gateway}} documents a subset of the plugin's fields directly, and accepts the rest of the plugin's configuration through the same `config` object for advanced use cases.

## How it works

OpenID Connect works by forming a federation with an IdP.
The IdP stores account credentials and authenticates the caller.
{{site.ai_gateway}} trusts that authentication instead of managing credentials itself.
{{site.konnect_short_name}} provides [{{site.identity}}](/identity/), a managed IdP you can use for this, or you can point the AI Auth Strategy at any OIDC-compliant provider you already run.

You create an OpenID Connect AI Auth Strategy once, then attach it by `name` or `id` to one or more AI Models, AI Agents, or AI MCP Servers through their `access.auth_strategies` array.
AI MCP Servers only accept an AI Auth Strategy in `conversion-listener`, `listener`, or `passthrough-listener` mode, the three modes that accept incoming MCP traffic directly.
See the [AI MCP Server entity](/ai-gateway/entities/ai-mcp-server/#server-modes) for the full mode reference.

Once authenticated, a token can map to an [AI Consumer](/ai-gateway/entities/ai-consumer/), a [Kong Identity principal](/identity/principals/), or both at once.
See [Identity mapping](/ai-gateway/entities/ai-auth-strategy/#identity-mapping) on the AI Auth Strategy entity for how that mapping works.

{% include /ai-gateway/auth-strategy-default-termination.md %}

The following diagram shows the three outcomes for a request against an AI Model, AI Agent, or AI MCP Server with an OpenID Connect AI Auth Strategy attached:

{% mermaid %}
sequenceDiagram
    participant Client as AI Consumer
    participant Auth as OpenID Connect AI Auth Strategy
    participant Anon as Anonymous AI Consumer<br/>(Request Termination)
    participant Entity as AI Model, AI Agent,<br/>or AI MCP Server

    Client->>Auth: Request with bearer token
    alt Valid token, maps to a known AI Consumer
        Auth->>Entity: Proxies request as that AI Consumer
        Entity-->>Client: Response
    else No token, or invalid token
        Auth->>Anon: Routes to anonymous AI Consumer
        Anon-->>Client: 401 Unauthorized
    else Valid token, no Consumer/principal match,<br/>consumer_optional or principals.error_on_miss set
        Auth->>Entity: Proxies request without an AI Consumer identity
        Entity-->>Client: Response
    end
{% endmermaid %}

### Authorization with ACLs

Authentication and authorization are separate steps.
The AI Auth Strategy only confirms who's calling.
It doesn't decide which AI Model, AI Agent, or AI MCP Server that caller may reach.
Use [`access.acls`](/ai-gateway/entities/ai-model/#access-control) on the entity itself to restrict that by AI Consumer, [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/), or Authenticated Group (a [dynamic group](/ai-gateway/entities/ai-model/#access-control) derived from an OAuth 2.0 scope or claim in the token).
This matters even when every caller shares one IdP.
If several AI Models reference the same OpenID Connect AI Auth Strategy, every caller with a valid token from that IdP passes authentication on all of them.
`access.acls` is what actually segments access to a specific AI Model, AI Agent, or AI MCP Server.

## Discovery cache

When you configure `config.issuer` in the OIDC plugin, {{site.ai_gateway}} automatically retrieves the provider’s discovery metadata. 
The OIDC plugin stores the metadata as a discovery cache object and uses the cache to avoid repeated fetches. This cache includes the discovery document endpoints, JWKS keys, and the token endpoint. 

{{site.ai_gateway}} uses the discovery cache whenever validation needs issuer metadata. The cache behaves in the following way:
- Discovery data is stored in the **{{site.ai_gateway}} database** when using DB mode, or in **worker memory** when using DB‑less mode.  
- The cache TTL (time-to-live) is managed by `config.cache_ttl`, which is set to 3600 seconds by default. You can also clear it manually using the relevant [DELETE endpoints in the Admin API](/plugins/openid-connect/api/#/operations/deleteAllDiscoveryCache/).  
- If a request requires discovery information that isn't in the cache, the plugin attempts to “rediscover” it using the value in `config.issuer`. After a rediscovery occurs, no further rediscovery attempts are made until the time period defined in `config.rediscovery_lifetime` has elapsed, which helps avoid excessive requests to the identity provider.  
- If a JWT can't be validated due to missing discovery data, and a rediscovery request returns a non‑2xx status code, the plugin falls back to using any sufficient discovery information that remains in the cache.

### Manually clear discovery cache

To manually clear discovery cache entries, you can use the Admin API DELETE endpoints for the OpenID Connect plugin. These endpoints let you:
* Delete a JWKS
* Delete all caches or a specific cache

Refer to the [OIDC API reference](/plugins/openid-connect/api/) for details.

## Supported flows and grants

Configure which flows are active with `config.auth_methods`.
{{site.ai_gateway}} enables `bearer` and `client_credentials` by default.
{{site.ai_gateway}} searches for credentials in the following order of precedence:

1. [Session authentication](#session-authentication)
2. [JWT access token authentication](#jwt-access-token-authentication-bearer) (`bearer`)
4. [Introspection authentication](#introspection-authentication)
5. [User info authentication](#user-info-authentication)
6. [Refresh token grant](#refresh-token-grant)
7. [Password grant](#password-grant)
8. [Client credentials grant](#client-credentials-grant)
9. [Authorization code flow](#authorization-code-flow)

{{site.ai_gateway}} stops at the first match in that order.
This precedence order is the same one {{site.ai_gateway}}'s OpenID Connect plugin uses, since the same plugin engine runs underneath the AI Auth Strategy, and it's fixed: it can't be reconfigured.

### Session authentication

{{site.ai_gateway}} can issue a session cookie after a caller first authenticates through one of the other flows.
The caller then presents that cookie on subsequent requests instead of re-authenticating.
For example, the [authorization code flow](#authorization-code-flow) demonstrates session authentication when it uses the redirect login action.

{% navtabs "session-auth" %}
{% navtab "Diagram" %}
<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as Gateway
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: Service with<br>session cookie
    deactivate client
    kong->>kong: load session cookie
    kong->>kong: verify session
    activate httpbin
    kong->>httpbin: request with<br>access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->
{% endnavtab %}
{% navtab "Example" %}
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: session-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Session Auth
    name: session-auth
    type: openid-connect
    config:
      issuer: https://dev-123456.okta.com
      client_id:
      - my-client-id
      client_secret:
      - !secret {source: !env 'CLIENT_SECRET'}
      auth_methods:
      - bearer
      - session
      consumer_claims:
      - - sub
      cache_tokens_salt: session-auth-cache-salt
{% endentity_examples %}
{% endnavtab %}
{% endnavtabs %}

### JWT access token authentication (`bearer`)

For legacy reasons, stateless JWT access token authentication is named `bearer` in `config.auth_methods`.
{{site.ai_gateway}} verifies the token's signature against the IdP's published keys and validates standard claims, such as `exp`.

{% navtabs "jwt-bearer-auth" %}
{% navtab "Diagram" %}
<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as Gateway
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: Service with<br>access token
    deactivate client
    kong->>kong: load access token
    kong->>kong: verify signature
    kong->>kong: verify claims
    activate httpbin
    kong->>httpbin: request with<br>access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->
{% endnavtab %}
{% navtab "Example" %}
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: bearer-token-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Bearer Token Auth
    name: bearer-token-auth
    type: openid-connect
    config:
      issuer: https://dev-123456.okta.com
      client_id:
      - my-client-id
      client_secret:
      - !secret {source: !env 'CLIENT_SECRET'}
      auth_methods:
      - bearer
      consumer_claims:
      - - sub
      cache_tokens_salt: bearer-token-auth-cache-salt
{% endentity_examples %}
{% endnavtab %}
{% endnavtabs %}

### Introspection authentication

Like `bearer`, introspection authentication relies on a token the AI Consumer already obtained.
The difference is that {{site.ai_gateway}} calls the IdP's introspection endpoint to check whether the token is valid and active, which allows the IdP to issue opaque tokens instead of JWTs.

{% navtabs "introspection-auth" %}
{% navtab "Diagram" %}
<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as Gateway
    participant idp as IdP <br>(e.g. Keycloak)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: Service with access token
    deactivate client
    kong->>kong: load access token
    activate idp
    kong->>idp: IdP/introspect with <br/>client credentials and access token
    deactivate kong
    idp->>idp: authenticate client <br/>and introspect access token
    activate kong
    idp->>kong: return introspection response
    deactivate idp
    kong->>kong: verify introspection response
    activate httpbin
    kong->>httpbin: request with <br/>access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->
{% endnavtab %}
{% navtab "Example" %}
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: introspection-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Introspection Auth
    name: introspection-auth
    type: openid-connect
    config:
      issuer: https://dev-123456.okta.com
      client_id:
      - my-client-id
      client_secret:
      - !secret {source: !env 'CLIENT_SECRET'}
      auth_methods:
      - introspection
      consumer_claims:
      - - sub
      client_auth:
      - client_secret_post
      cache_tokens_salt: introspection-auth-cache-salt
{% endentity_examples %}
{% endnavtab %}
{% endnavtabs %}

{% include_cached /md/ai-gateway/v2/oidc/client-auth.md %}

### User info authentication

User info authentication verifies the access token against the IdP's standard user info endpoint, instead of the introspection endpoint.
Use [introspection](#introspection-authentication) instead in most cases, as it's meant for validating the token itself, where user info is meant for retrieving information about the user the token was issued to.

{% navtabs "user-info-auth" %}
{% navtab "Diagram" %}
<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as Gateway
    participant idp as IdP <br>(e.g. Keycloak)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: Service with<br>access token
    deactivate client
    kong->>kong: load access token
    activate idp
    kong->>idp: IdP/userinfo<br>with access token
    deactivate kong
    idp->>idp: verify access token
    activate kong
    idp->>kong: return user info <br>response
    deactivate idp
    kong->>kong: verify response<br>status code (200)
    activate httpbin
    kong->>httpbin: request with access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->
{% endnavtab %}
{% navtab "Example" %}
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: user-info-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: User Info Auth
    name: user-info-auth
    type: openid-connect
    config:
      issuer: https://dev-123456.okta.com
      client_id:
      - my-client-id
      client_secret:
      - !secret {source: !env 'CLIENT_SECRET'}
      auth_methods:
      - userinfo
      consumer_claims:
      - - sub
      client_auth:
      - client_secret_post
      cache_tokens_salt: user-info-auth-cache-salt
{% endentity_examples %}
{% endnavtab %}
{% endnavtabs %}

{% include_cached /md/ai-gateway/v2/oidc/client-auth.md %}

### Refresh token grant

The refresh token grant can be used when the AI Consumer already has a refresh token.
IdPs generally only allow the refresh token grant to run with the same client that originally obtained the token.
A mismatch can cause it to fail.

{% navtabs "refresh-token-auth" %}
{% navtab "Diagram" %}
<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as Gateway
    participant idp as IdP <br>(e.g. Keycloak)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: Service with<br>refresh token
    deactivate client
    kong->>kong: load refresh token
    activate idp
    kong->>idp: IdP/token with<br>client credentials and<br>refresh token
    deactivate kong
    idp->>idp: authenticate client and<br>verify refresh token
    activate kong
    idp->>kong: return tokens
    deactivate idp
    kong->>kong: verify tokens
    activate httpbin
    kong->>httpbin: request with access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->
{% endnavtab %}
{% navtab "Example" %}
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: refresh-token-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Refresh Token Auth
    name: refresh-token-auth
    type: openid-connect
    config:
      issuer: https://dev-123456.okta.com
      client_id:
      - my-client-id
      client_secret:
      - !secret {source: !env 'CLIENT_SECRET'}
      auth_methods:
      - refresh_token
      consumer_claims:
      - - sub
      client_auth:
      - client_secret_post
      cache_tokens_salt: refresh-token-auth-cache-salt
{% endentity_examples %}
{% endnavtab %}
{% endnavtabs %}

{% include_cached /md/ai-gateway/v2/oidc/client-auth.md %}

### Password grant

Password grant is a legacy authentication grant.
This is a less secure way of authenticating end users than the authorization code flow, because, for example, the passwords are shared with third parties.

{% navtabs "password-auth" %}
{% navtab "Diagram" %}
<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as Gateway
    participant idp as IdP <br>(e.g. Keycloak)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: Service with<br>basic authentication
    deactivate client
    kong->>kong: load <br>basic authentication<br>credentials
    activate idp
    kong->>idp: IdP/token with<br>client credentials and<br>password grant
    deactivate kong
    idp->>idp: authenticate client and<br>verify password grant
    activate kong
    idp->>kong: return tokens
    deactivate idp
    kong->>kong: verify tokens
    activate httpbin
    kong->>httpbin: request with access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->
{% endnavtab %}
{% navtab "Example" %}
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: password-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Password Auth
    name: password-auth
    type: openid-connect
    config:
      issuer: https://dev-123456.okta.com
      client_id:
      - my-client-id
      client_secret:
      - !secret {source: !env 'CLIENT_SECRET'}
      auth_methods:
      - password
      consumer_claims:
      - - sub
      password_param_type:
      - header
      cache_tokens_salt: password-auth-cache-salt
{% endentity_examples %}
{% endnavtab %}
{% endnavtabs %}

### Client credentials grant

{{site.ai_gateway}} forwards the credentials the AI Consumer passes to the IdP's token endpoint directly, without trying to authenticate itself.

{% navtabs "client-credentials-auth" %}
{% navtab "Diagram" %}
<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as Gateway
    participant idp as IdP <br>(e.g. Keycloak)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: Service with<br>basic authentication
    deactivate client
    kong->>kong: load basic<br>authentication credentials
    activate idp
    kong->>idp: IdP/token<br>with client credentials
    deactivate kong
    idp->>idp: authenticate client
    activate kong
    idp->>kong: return tokens
    deactivate idp
    kong->>kong: verify tokens
    activate httpbin
    kong->>httpbin: request with access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->
{% endnavtab %}
{% navtab "Example" %}
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: client-credentials-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Client Credentials Auth
    name: client-credentials-auth
    type: openid-connect
    config:
      issuer: https://dev-123456.okta.com
      client_id:
      - my-client-id
      client_secret:
      - !secret {source: !env 'CLIENT_SECRET'}
      auth_methods:
      - client_credentials
      consumer_claims:
      - - sub
      client_credentials_param_type:
      - header
      client_auth:
      - client_secret_post
      cache_tokens_salt: client-credentials-auth-cache-salt
{% endentity_examples %}
{% endnavtab %}
{% endnavtabs %}

{% include_cached /md/ai-gateway/v2/oidc/client-auth.md %}

### Authorization code flow

The authorization code flow is a three-legged OAuth/OpenID Connect flow, including session cookie issuance.
The sequence diagram below describes the participants and their interactions for this usage scenario, including the use of session cookies.

{% navtabs "auth-code-auth" %}
{% navtab "Diagram" %}
<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as Gateway
    participant idp as IdP <br>(e.g. Keycloak)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: HTTP request
    kong->>client: Redirect mobile app to IDP 
    deactivate kong
    activate idp
    client->>idp: Request access and authentication<br>with client parameter
    Note left of idp: /auth<br>response_type=code,<br>scope=openid
    idp->>client: Login (ask for consent)
    client->>idp: /auth with user credentials (grant consent)
    idp->>client: Return authorization code and redirect
    Note left of idp: short-lived authcode
    activate kong
    client->>kong: HTTP redirect with authorization code
    deactivate client
    kong->>kong: Verify authorization code flow
    kong->>idp: Request ID token, access token, and refresh token
    Note left of idp: /token<br>client_id:client_secret<br>authcode
    idp->>idp: Authenticate client (Kong)<br>and validate authcode
    idp->>kong: Returns tokens
    Note left of idp: ID token, access token, and refresh token
    deactivate idp
    kong->>kong: Validate tokens
    Note right of kong: Cryptographic<br>signature validation,<br>expiry check<br>(OIDC Standard JWT validation)
    activate client
    kong->>client: Redirect with session cookie<br>having session ID (SID)
    Note left of kong: sid: cryptorandom bytes <br>(128 bits)<br>& HMAC protected
    client->>kong: Authenticated request with session cookie
    deactivate client
    kong->>kong: Verify session cookie
    Note right of kong: Retrieve encrypted tokens<br>from session store (redis)
    activate httpbin
    kong->>httpbin: Backend service request with tokens
    Note right of idp: Access token and ID token
    httpbin->>kong: Backend service response
    deactivate httpbin
    activate client
    kong->>client: HTTP response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->
{% endnavtab %}
{% navtab "Example" %}
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: auth-code-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Auth Code Auth
    name: auth-code-auth
    type: openid-connect
    config:
      issuer: https://dev-123456.okta.com
      client_id:
      - my-client-id
      client_secret:
      - !secret {source: !env 'CLIENT_SECRET'}
      client_auth:
      - client_secret_post
      auth_methods:
      - authorization_code
      - session
      response_mode: form_post
      preserve_query_args: true
      login_action: redirect
      login_tokens:
      redirect_uri:
      - https://my-app.example.com/callback
      consumer_claims:
      - - sub
      cache_tokens_salt: auth-code-auth-cache-salt
{% endentity_examples %}
{% endnavtab %}
{% endnavtabs %}

{% include_cached /md/ai-gateway/v2/oidc/client-auth.md %}

{:.info}
> If using PKCE, the IdP must include `code_challenge_methods_supported` in its `/.well-known/openid-configuration` discovery response, per [RFC 8414](https://www.rfc-editor.org/rfc/rfc8414.html).
> Otherwise, {{site.ai_gateway}} won't send the PKCE `code_challenge` parameter.

## Authorization

Beyond `access.acls` (see [How it works](#how-it-works)), the OpenID Connect AI Auth Strategy supports claims-based authorization.
Claims-based authorization uses a pair of options to manage claims verification during authorization.
The pair can be any of:

* `config.scopes_claim` and `config.scopes_required`
* `config.audience_claim` and `config.audience_required`
* `config.groups_claim` and `config.groups_required`
* `config.roles_claim` and `config.roles_required`
* `config.consumer_groups_claim`

In each parameter pair, the `*_claim` parameter points to a source, and the `*_required` parameter defines a set of claims values to check against.

Claims-based auth adheres to the following rules:
* You can validate a maximum of 4 claims at the same time
* You can traverse an array or object for the claim name
* You can validate multiple values of the same claim using `OR` and `AND` logic

Both the claim type and the required claim content take an array of string elements.

### Claim type

For the claim type (for example, `config.groups_claim`), the array is a list of JSON objects listed in nested order.
{{site.ai_gateway}} uses the order of the items in the array to look up data in a JSON payload.

The value of a claim can be:

* A space-separated string (common for scope claims)
* A JSON array of strings (common for groups claims)
* A simple value, such as a string

For example, look at the following sample payload, where `groups` is nested inside `user`:

```json
{
    "user": {
        "name": "alex",
        "groups": [
            "employee",
            "marketing"
        ]
    }
}
```

In this case, use `config.groups_claim` to traverse to the groups you need, where `groups` is the JSON object that contains the list of groups:

```yaml
config:
  groups_claim:
  - user
  - groups
```

### Claim requirements

The `config.*_required` parameters (for example, `config.groups_required`) are arrays that allow logical `AND`/`OR` types of checks:

* `AND`: Space-separated values.
  This claim has to have both `employee` AND `marketing`:

  ```yaml
  config:
    groups_required:
    - employee marketing
  ```

* `OR`: Values in separate array indices.
  This claim has to have either `employee` OR `marketing`:

  ```yaml
  config:
    groups_required:
    - employee
    - marketing
  ```

This runs independently of `access.acls`, which authorizes an already-resolved AI Consumer identity against a specific entity.

## Client authentication

`config.client_auth` selects how {{site.ai_gateway}} authenticates itself to the IdP, including through mutual TLS (mTLS) client authentication.

{% include_cached /md/ai-gateway/v2/oidc/client-auth.md %}

### Mutual TLS client authentication

The OpenID Connect auth strategy supports mutual TLS (mTLS) client authentication with the IdP. 
When mTLS authentication is enabled, {{site.ai_gateway}} establishes mTLS connections with the IdP using the configured client certificate.
You can use mTLS client authentication with the following IdP endpoints and corresponding flows:

* `token`
  * [Authorization Code Flow](#authorization-code-flow)
  * [Password Grant](#password-grant-workflow)
  * [Refresh Token Grant](#refresh-token-grant-workflow)
* `introspection`
  * [Introspection Authentication flow](#introspection-authentication-flow)
* `revocation`
  * [Session Authentication](#session-auth-workflow)

For all these endpoints and for the flows supported, the auth strategy uses mTLS client authentication as the authentication method when communicating with the IdP, for example, to fetch the token from the token endpoint.

## Advanced OpenID Connect plugin capabilities

The following capabilities exist on {{site.base_gateway}}'s OpenID Connect plugin, which the OpenID Connect AI Auth Strategy's `config` object passes through to for advanced use cases.

### Financial-grade API (FAPI)

{{site.ai_gateway}} supports various features of the FAPI standard, aimed at protecting APIs that expose high-value and sensitive data.

{% table %}
columns:
  - title: Specification
    key: spec
  - title: Description
    key: description
rows:
  - spec: "Pushed authorization requests (PAR)"
    description:
      With PAR enabled, {{site.ai_gateway}} (as the OAuth client) sends the payload of an authorization request to the IdP.
      As a result, it obtains a `request_uri` value.
      The client uses this value in a call to the authorization endpoint as a reference to obtain the authorization request payload data.
      <br><br>
      Use [`config.pushed_authorization_request_endpoint`](./#schema--config-pushed-authorization-request-endpoint) to enable PAR.
  - spec: "JWT-secured authorization requests (JAR)"
    description:
      With JAR enabled, when sending requests to the authorization endpoint, {{site.ai_gateway}} provides request parameters in a JSON Web Token (JWT) instead of using a query string.
      This allows for request data to be signed with JSON Web Signature (JWS).
      <br><br>
      Use [`config.require_signed_request_object`](./#schema--config-require-signed-request-object) to enable JAR.
  - spec: "JWT-secured authorization response mode (JARM)"
    description: |
      With JARM enabled, {{site.ai_gateway}} requests the authorization server to return the authorization response parameters encoded in a JWT, which allows the response data to be signed with JSON Web Signature (JWS).
      <br><br>
      Set [`config.response_mode`](./#schema--config-response-mode) to any of the following values: `query.jwt`, `form_post.jwt`, `fragment.jwt`, `jwt` to enable JARM.
  - spec: "Certificate-bound access tokens"
    description: |
      Certificate-bound access tokens allow binding tokens to clients.
      This guarantees the authenticity of the token by verifying whether the sender is authorized to use the token for accessing protected resources.
      <br><br>
      Set [`config.proof_of_possession_mtls`](./#schema--config-proof-of-possession-mtls) to `strict` and [`config.client_id`](./#schema--config-client-id) to a client bound to a client certificate to enable cert-bound access tokens.
  - spec: "Mutual TLS (mTLS) client authentication with certificate-bound access tokens"
    description: |
      When mTLS client authentication is enabled, {{site.ai_gateway}} establishes mTLS connections with the IdP using the configured X.509 certificate as client credentials.
      <br><br>
      If the authorization server is configured to bind the client certificate with the issued access token, {{site.ai_gateway}} can validate the access token using mTLS proof of possession.
      <br><br>
      Set [`config.client_auth`](./#schema--config-client-auth) to `tls_client_auth` and provide a certificate at [`config.tls_client_auth_cert_id`](./#schema--config-tls-client-auth-cert-id) to enable mTLS auth.
  - spec: "Demonstrating proof-of-possession (DPoP)"
    description: |
      Demonstrating Proof of Possession (DPoP) is an application-level mechanism for proving the sender's ownership of OAuth access and refresh tokens.
      With DPoP, a client can prove possession of a public/private key pair associated with a token by using a header.
      The header contains a signed JWT that includes a reference to the associated access token.
      <br><br>
      When DPoP is enabled, {{site.ai_gateway}} validates the DPoP header in the request to ensure that the sender is authorized to use the access token.
      <br><br>
      Set [`config.proof_of_possession_dpop`](./#schema--config-proof-of-possession-dpop) to `strict` to enable DPoP.
{% endtable %}

#### Certificate-bound access tokens

One of the main vulnerabilities of OAuth is bearer tokens.
With OAuth, presenting a valid bearer token is enough proof to access a resource.
This can create problems, since the client presenting the token isn't validated as the legitimate user the token was issued to.

Certificate-bound access tokens solve this problem by binding tokens to clients.
This ensures the legitimacy of the token, because it requires proof that the sender is authorized to use a particular token to access protected resources.

Certificate-bound access tokens are supported by the following auth methods:

* [JWT access token authentication](#jwt-access-token-authentication-bearer)
* [Introspection authentication](#introspection-authentication)
* [Session authentication](#session-authentication)

Session authentication is only compatible with certificate-bound access tokens when used along with one of the other supported authentication methods:

* When [`config.proof_of_possession_auth_methods_validation`](./#schema--config-proof-of-possession-auth-methods-validation) is set to `false` and other non-compatible methods are enabled, and a valid session is found, {{ site.ai_gateway }} only performs the proof of possession validation if the session was originally created using one of the compatible methods.
* If you configure multiple OpenID Connect auth strategy instances with the `session` auth method, configure a different [`config.session_secret`](./#schema--config-session-secret) value on each for additional security. This avoids sessions being shared across auth strategy instances and possibly bypassing the proof of possession validation.

To enable certificate-bound access tokens:
* Ensure that the IdP you're using is set up to generate OAuth 2.0 mutual TLS certificate-bound access tokens.
* Use [`config.proof_of_possession_mtls`](./#schema--config-proof-of-possession-mtls) to verify that the supplied access token belongs to the client, by checking its binding with the client certificate provided in the request.

The following is an example cert-bound access token config:
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: cert-bound-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Cert-Bound Access Tokens Auth
    name: cert-bound-auth
    type: openid-connect
    config:
      issuer: https://dev-123456.okta.com
      client_id:
      - my-client-id
      client_secret:
      - !secret {source: !env 'CLIENT_SECRET'}
      auth_methods:
      - bearer
      proof_of_possession_mtls: strict
      consumer_claims:
      - - sub
      cache_tokens_salt: cert-bound-auth-cache-salt
{% endentity_examples %}

#### Demonstrating Proof-of-Possession (DPoP)

Demonstrating Proof-of-Possession (DPoP) is an alternative technique to [mutual TLS client authentication with certificate-bound access tokens](#client-authentication). Unlike mTLS, which binds the token to the mTLS client certificate, DPoP binds the token to a JSON Web Key (JWK) provided by the client.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as Gateway
    participant upstream as Upstream <br>(backend service,<br> e.g. httpbin)
    participant idp as Authentication Server <br>(e.g. Keycloak)
    activate client
    client->>client: generate key pair
    client->>idp: POST /oauth2/token<br>DPoP:$PROOF
    deactivate client
    activate idp
    idp-->>client: DPoP bound access token ($AT)
    activate client
    deactivate idp
    client->>kong: GET https://example.com/resource<br>Authorization: DPoP $AT<br>DPoP: $PROOF
    activate kong
    deactivate client
    kong->>kong: validate $AT and $PROOF
    kong->>upstream: proxied request <br> GET https://example.com/resource<br>Authorization: Bearer $AT
    deactivate kong
    activate upstream
    upstream-->>kong: upstream response
    deactivate upstream
    activate kong
    kong-->>client: response
    deactivate kong
{% endmermaid %}
<!--vale on-->

You can use DPoP without mTLS, and even with plain HTTP, although HTTPS is recommended for enhanced security.

When verification of the DPoP proof is enabled, {{ site.ai_gateway }} removes the `DPoP` header and changes the token type from `dpop` to `bearer`.
This effectively downgrades the request to use a conventional bearer token, and lets an upstream without DPoP support work with the DPoP token without losing the protection of the key binding mechanism.

DPoP is compatible with the following authentication methods:

* [JWT access token authentication](#jwt-access-token-authentication-bearer)
* [Introspection authentication](#introspection-authentication)
* [Session authentication](#session-authentication)

Session authentication is only compatible with DPoP when used along with one of the other supported authentication methods. If you configure multiple OpenID Connect auth strategy instances with the `session` authentication method, configure a different [`config.session_secret`](./#schema--config-session-secret) value on each for additional security. This avoids sessions being shared across auth strategy instances and possibly bypassing the proof of possession validation.

To enable DPoP:
* Ensure that the IdP you're using has DPoP enabled.
* Use [`config.proof_of_possession_dpop`](./#schema--config-proof-of-possession-dpop) to verify that the supplied access token is bound to the client, by checking its association with the JWT provided in the request.

The following is an example DPoP config:
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: dpop-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: DPoP Auth
    name: dpop-auth
    type: openid-connect
    config:
      issuer: https://dev-123456.okta.com
      client_id:
      - my-client-id
      client_secret:
      - !secret {source: !env 'CLIENT_SECRET'}
      auth_methods:
      - bearer
      proof_of_possession_dpop: strict
      consumer_claims:
      - - sub
      cache_tokens_salt: dpop-auth-cache-salt
{% endentity_examples %}

### Multi-IdP support

If your APIs serve clients that authenticate with different identity providers, the OIDC auth strategy can validate tokens from multiple issuers at the gateway layer, so backends don't need per-IdP logic.

You can implement this in one of the following ways:

* **Trusted issuers registry**: Configure the OIDC auth strategy with a list of trusted issuers and their JWKS endpoints using [`config.issuers_allowed`](./#schema--config-issuers-allowed) and [`config.extra_jwks_uris`](./#schema--config-extra-jwks-uris).
{{ site.ai_gateway }} validates incoming tokens against the appropriate public keys and forwards them to the backend as-is.
This works best when token formats are consistent across IdPs.

* **Token exchange** {% new_in 3.14 %}: Configure the OIDC auth strategy to swap incoming tokens for a canonical token from one trusted issuer using [`config.token_exchange`](./#schema--config-token-exchange).
The backend always receives tokens from a single issuer regardless of which IdP the client used.
This works best when backends must trust one issuer, or when you need to normalize scopes and claims across IdPs.

### Protected resource metadata {% new_in 3.16 %}

Some clients, including MCP (Model Context Protocol) clients that follow the [MCP authorization specification](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization), need to know which authorization server protects an API before they can request a token.

[RFC 9728](https://www.rfc-editor.org/rfc/rfc9728) (OAuth 2.0 Protected Resource Metadata) solves this by letting a resource server advertise itself, including which authorization servers protect it and what scopes it supports, at a well-known URI that clients can discover automatically.

When you configure [`config.protected_resource_metadata`](./#schema--config-protected-resource-metadata), the OIDC auth strategy:
* Serves an RFC 9728 metadata document at a well-known URI, with no authentication required.
* Rejects a request with no bearer token with a `401 Unauthorized` response instead of `403 Forbidden`, and adds a `resource_metadata` attribute, and optionally a `scope` attribute, to its `WWW-Authenticate` header, so clients that receive a challenge can locate the metadata document.

{:.info}
> Configuring this setting only advertises protected resource metadata and adds it to unauthorized responses.
It doesn't change how the OIDC auth strategy authenticates requests, and the authorization server URLs you configure here aren't validated against `config.issuer`.

#### Well-known metadata endpoint

By default, the OIDC auth strategy derives the metadata document's path from [`config.protected_resource_metadata.resource`](./#schema--config-protected-resource-metadata-resource) by appending `/.well-known/oauth-protected-resource` to its path component. For example:

* `resource`: `https://api.example.com/mcp`
* Metadata document served at: `https://api.example.com/mcp/.well-known/oauth-protected-resource`

To serve the document at a different path, set [`config.protected_resource_metadata.metadata_endpoint`](./#schema--config-protected-resource-metadata-metadata-endpoint).

{{ site.ai_gateway }} intercepts requests to this path before any authentication logic runs:
* `GET` requests receive a `200` response with the metadata document as a JSON body (`Content-Type: application/json`, `Cache-Control: no-store`).
The document always includes `resource`, and includes `authorization_servers` and `scopes_supported` when they're configured.
* Requests using any other method receive a `405` response with an `Allow: GET` header.

For example, with `resource` set to `https://api.example.com/mcp`:

```sh
curl -s https://api.example.com/mcp/.well-known/oauth-protected-resource
```

The response is the metadata document, and doesn't require an `Authorization` header since a client fetches it before it has a token:

```json
{
  "resource": "https://api.example.com/mcp",
  "authorization_servers": ["https://idp.example.com"],
  "scopes_supported": ["openid", "profile"]
}
```
{:.no-copy-code}

{:.info}
> {{ site.ai_gateway }} doesn't handle CORS for the metadata endpoint.
If MCP or browser-based clients need to fetch the metadata document cross-origin, add the [CORS policy](/ai-gateway/policies/cors/) to the same route.

#### WWW-Authenticate header

When a request is rejected with a `401 Unauthorized` response, the OIDC auth strategy adds a `resource_metadata` attribute to the `WWW-Authenticate` header, pointing to the well-known metadata endpoint.
If [`config.protected_resource_metadata.scopes_supported`](./#schema--config-protected-resource-metadata-scopes-supported) is set, the header also includes a `scope` attribute listing the supported scopes.
This only applies to `401` responses.

For example, a request without a bearer token:

```sh
curl -s -i https://api.example.com/mcp
```

Returns a `401` response whose `WWW-Authenticate` header carries the discovery information:

```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer realm="idp.example.com", resource_metadata="https://api.example.com/mcp/.well-known/oauth-protected-resource", scope="openid profile", error="invalid_token"

{"message":"Unauthorized"}
```
{:.no-copy-code}

### Token exchange

The [OAuth 2.0 Token Exchange](https://oauth.net/2/token-exchange/) (RFC 8693) is an extension to the OAuth 2.0 framework that allows exchanging an existing security token for a new one.
The RFC defines a protocol approach to support scenarios where a client can exchange a token for a new token by interacting with the authorization server.
This is particularly useful in complex environments like microservices or cross-domain federations.

{:.info}
> **Note**: Only access tokens can be exchanged with the OIDC auth strategy.

#### Why use token exchange?

Token exchange can be used in several critical use cases:

* **Downscoping**: A service receives a powerful token but only needs a subset of those permissions to call an upstream service.
It exchanges the powerful token for one with fewer scopes to maintain the Principle of Least Privilege.
* **Internal vs. external tokens**: Converting an external opaque token or a third-party token (like a SAML assertion) into an internal JWT that the microservices understand.
* **Impersonation and delegation**: Allowing a service to act on behalf of a user.
For example, a frontend service needs to trade its token for a new token with specific scopes to call a backend service.
* **Privacy**: Removing sensitive user information from a token before passing it to an upstream service.

{:.info}
> Because token exchange allows for the creation of new tokens, trust models are vital.
The trust model must strictly define which clients are allowed to exchange tokens and which scopes they are permitted to elevate or downgrade to prevent security flaws like privilege escalations.

#### How token exchange works

In a typical OAuth flow, a token is obtained to access a resource.
However, in a token exchange, a client already has a token (the "subject token").
{{ site.ai_gateway }} decides which incoming tokens are eligible for exchange and facilitates the token exchange using its own client credentials.
The subject token is presented to the authorization server to get a different token (the "requested token") that is better suited for accessing the resource.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    participant C as Client<br>(e.g. mobile app)
    participant K as Gateway
    participant A as Authorization server<br>(e.g. Keycloak)
    participant U as Upstream<br>(backend service,<br>e.g. httpbin)

    C->>K: Request with subject token
    activate K
    note over K: Validate subject token<br>(iss, exp, nbf)
    K->>A: Token exchange request
    activate A
    A-->>K: Exchanged access token
    deactivate A
    K->>K: Validate exchanged token
    K->>U: Proxy request with exchanged token
    activate U
    U-->>K: Response
    deactivate U
    K-->>C: Response
    deactivate K
{% endmermaid %}
<!--vale on-->

Before triggering the exchange, the OIDC auth strategy performs the following checks on the incoming token:
1. Checks the incoming subject token meets the following criteria:
  * The issuer (`iss` claim) matches a configured trusted issuer (`subject_token_issuers`).
  * The token is not expired (`exp` claim).
  * The token is not used before its time (`nbf` claim).
  * {% new_in 3.15 %} If [`verify_signature`](./#schema--config-token-exchange-subject-token-issuers-verify-signature) is enabled for the issuer, {{ site.ai_gateway }} cryptographically verifies the token signature before sending the exchange request to the IdP.
1. If the `subject_token_issuer` and `target_issuer` are different, token exchange is triggered.
1. If the `subject_token_issuer` and `target_issuer` are the same, the configured conditions are evaluated to determine whether to trigger token exchange.
1. {{ site.ai_gateway }} uses its client credentials to trigger the exchange.

Afterwards, the OIDC auth strategy continues processing the exchanged token through the rest of its flow.

Depending on the use case, {{ site.ai_gateway }} can exchange the token either with the same authorization server that issued the initial subject token, or exchange tokens between different authorization servers.

##### Key terms

The token exchange flow uses the following terms:

* **Subject token**: The input token representing the identity/authorization being exchanged.
* **Subject token issuer**: The authorization server that issued the initial token (subject token).
* **Target issuer**: The authorization server protecting the resources (APIs/services).
* **Conditions**: Conditions under which to trigger token exchange.
Conditions look for the presence or absence of two claims: `scopes` and `audience`.

#### Subject token signature verification {% new_in 3.15 %}

By default, {{ site.ai_gateway }} validates the `iss`, `exp`, and `nbf` claims of an incoming subject token but doesn't verify its cryptographic signature before sending the exchange request to the IdP.
The IdP performs its own signature check, so validation happens eventually.

Enabling signature verification in {{ site.ai_gateway }} adds an earlier check that rejects tokens with invalid signatures before they reach the IdP.
This reduces unnecessary round-trips to the IdP and keeps {{ site.ai_gateway }}'s security posture consistent with other authentication flows.

You can configure this setting per issuer on each entry in [`config.token_exchange.subject_token_issuers`](./#schema--config-token-exchange-subject-token-issuers):

* [`config.token_exchange.subject_token_issuers[].verify_signature`](./#schema--config-token-exchange-subject-token-issuers-verify-signature): Set to `true` to enable signature verification for that issuer.
Defaults to `false` for backward compatibility.
We recommend enabling this for all subject token issuers to prevent tokens with invalid signatures from consuming IdP resources.
* [`config.token_exchange.subject_token_issuers[].jwks_uri`](./#schema--config-token-exchange-subject-token-issuers-jwks-uri): An optional explicit JWKS endpoint for fetching the signing keys for this issuer.
If not set, {{ site.ai_gateway }} resolves the JWKS URI from OIDC discovery using the issuer URL.
Set this when the issuer doesn't publish a discovery document or when you want to pin to a specific key endpoint.

#### Actor tokens {% new_in 3.16 %}

An actor token represents the identity of the party acting on behalf of the subject in a token exchange, as defined by [RFC 8693](https://www.rfc-editor.org/rfc/rfc8693#name-actor-token-and-actor-toke).
This is useful for delegation scenarios, such as an AI agent or backend service that needs to identify itself separately from the user (the subject) it's acting for.
Some identity providers require an actor token to be present for certain token exchange grants.

Configure [`config.token_exchange.request.actor_token`](./#schema--config-token-exchange-request-actor-token) to include an actor token in the exchange request.

Use [`config.token_exchange.request.actor_token.type`](./#schema--config-token-exchange-request-actor-token-type) to set the token type identifier sent as `actor_token_type`.
This defaults to `urn:ietf:params:oauth:token-type:access_token`.

### Using cloud authentication with Redis

{% include_cached /md/ai-gateway/v2/redis-cloud-auth.md %}

{% include_cached /md/ai-gateway/v2/redis-cloud-providers.md redis_group="oidc" %}

### Multiple clients

`config.client_id` and `config.client_secret` are array fields on the OpenID Connect AI Auth Strategy schema, and behave the same way as on the plugin.

You can configure the OIDC auth strategy ([`config.client_id`](./#schema--config-client-id)) and
client secrets ([`config.client_secret`](./#schema--config-client-secret)), where the ID and client pairs correspond based on their locations in the array.

For example:

```yaml
config:
  issuer: example-issuer-url
  client_id:
    - my-first-client
    - my-second-client
  client_secret:
    - first-client-secret
    - second-client-secret
```

When making a request, you can specify which client to target to use by including a client ID argument.
For example, after configuring the auth strategy client secrets, you can target a client by name:

```sh
curl -X GET "http://localhost:8000?client_id=my-second-client"
```

Or by its index value (starting with 1):

```sh
curl -X GET "http://localhost:8000?client_id=2"
```

{{ site.ai_gateway }} will look for the client ID in the following locations, in order of precedence:
1. If [`config.client_arg`](./#schema--config-client-arg) is set, {{ site.ai_gateway }} checks for that value in the following order: in the request header, URI argument, and body.
1. If `config.client_arg` is not set, {{ site.ai_gateway }} checks for a `client_id` in the following order: in the request header, URI argument, and body.
1. If no client is found in either of those places, {{ site.ai_gateway }} uses the first client ID and client secret pair.

{:.info}
> **Note:** Configuring multiple clients is not possible with the client credentials grant, as the auth strategy always uses the client ID passed directly from the client.

{% entity_example %}
type: auth-strategy
data:
  display_name: Multi-Client Auth
  name: multi-client-auth
  type: openid-connect
  config:
    issuer: https://dev-123456.okta.com
    client_id:
      - first-client-id
      - second-client-id
    client_secret:
      - !secret {source: !env 'CLIENT_SECRET_A'}
      - !secret {source: !env 'CLIENT_SECRET_B'}
    auth_methods:
      - client_credentials
    cache_tokens_salt: multi-client-auth-cache-salt
{% endentity_example %}

## Schema

{% entity_schema %}