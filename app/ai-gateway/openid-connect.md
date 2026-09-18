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
  path: /schemas/AIGatewayAuthStrategyOpenIDConnectResponse

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
This precedence order is the same one {{site.base_gateway}}'s OpenID Connect plugin uses, since the same plugin engine runs underneath the AI Auth Strategy, and it's fixed: it can't be reconfigured.

### Session authentication

{{site.ai_gateway}} can issue a session cookie after a caller first authenticates through one of the other flows.
The caller then presents that cookie on subsequent requests instead of re-authenticating.
For example, the [authorization code flow](#authorization-code-flow) demonstrates session authentication when it uses the redirect login action.

{% navtabs "session-auth" %}
{% navtab "Diagram" %}
{% include_cached plugins/oidc/diagrams/session.md gateway_label="AI Gateway" %}
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
{% include_cached plugins/oidc/diagrams/jwt-access-token.md gateway_label="AI Gateway" %}
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
{% include_cached plugins/oidc/diagrams/introspection.md gateway_label="AI Gateway" %}
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

{% include_cached plugins/oidc/client-auth.md %}

### User info authentication

User info authentication verifies the access token against the IdP's standard user info endpoint, instead of the introspection endpoint.
Use [introspection](#introspection-authentication) instead in most cases, as it's meant for validating the token itself, where user info is meant for retrieving information about the user the token was issued to.

{% navtabs "user-info-auth" %}
{% navtab "Diagram" %}
{% include_cached plugins/oidc/diagrams/user-info.md gateway_label="AI Gateway" %}
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

{% include_cached plugins/oidc/client-auth.md %}

### Refresh token grant

The refresh token grant can be used when the AI Consumer already has a refresh token.
IdPs generally only allow the refresh token grant to run with the same client that originally obtained the token.
A mismatch can cause it to fail.

{% navtabs "refresh-token-auth" %}
{% navtab "Diagram" %}
{% include_cached plugins/oidc/diagrams/refresh-token.md gateway_label="AI Gateway" %}
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

{% include_cached plugins/oidc/client-auth.md %}

### Password grant

Password grant is a legacy authentication grant.
This is a less secure way of authenticating end users than the authorization code flow, because, for example, the passwords are shared with third parties.

{% navtabs "password-auth" %}
{% navtab "Diagram" %}
{% include_cached plugins/oidc/diagrams/password.md gateway_label="AI Gateway" %}
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
{% include_cached plugins/oidc/diagrams/client-credentials.md gateway_label="AI Gateway" %}
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

{% include_cached plugins/oidc/client-auth.md %}

### Authorization code flow

The authorization code flow is a three-legged OAuth/OpenID Connect flow, including session cookie issuance.
The sequence diagram below describes the participants and their interactions for this usage scenario, including the use of session cookies.

{% navtabs "auth-code-auth" %}
{% navtab "Diagram" %}
{% include_cached plugins/oidc/diagrams/auth-code.md gateway_label="AI Gateway" %}
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

{% include_cached plugins/oidc/client-auth.md %}

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

{% include_cached plugins/oidc/client-auth.md schema_page="/ai-gateway/openid-connect/#schema" %}

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
      Use [`config.pushed_authorization_request_endpoint`](/plugins/openid-connect/reference/#schema--config-pushed-authorization-request-endpoint) to enable PAR.
  - spec: "JWT-secured authorization requests (JAR)"
    description:
      With JAR enabled, when sending requests to the authorization endpoint, {{site.ai_gateway}} provides request parameters in a JSON Web Token (JWT) instead of using a query string.
      This allows for request data to be signed with JSON Web Signature (JWS).
      <br><br>
      Use [`config.require_signed_request_object`](/plugins/openid-connect/reference/#schema--config-require-signed-request-object) to enable JAR.
  - spec: "JWT-secured authorization response mode (JARM)"
    description: |
      With JARM enabled, {{site.ai_gateway}} requests the authorization server to return the authorization response parameters encoded in a JWT, which allows the response data to be signed with JSON Web Signature (JWS).
      <br><br>
      Set [`config.response_mode`](/plugins/openid-connect/reference/#schema--config-response-mode) to any of the following values: `query.jwt`, `form_post.jwt`, `fragment.jwt`, `jwt` to enable JARM.
  - spec: "Certificate-bound access tokens"
    description: |
      Certificate-bound access tokens allow binding tokens to clients.
      This guarantees the authenticity of the token by verifying whether the sender is authorized to use the token for accessing protected resources.
      <br><br>
      Set [`config.proof_of_possession_mtls`](/plugins/openid-connect/reference/#schema--config-proof-of-possession-mtls) to `strict` and [`config.client_id`](/plugins/openid-connect/reference/#schema--config-client-id) to a client bound to a client certificate to enable cert-bound access tokens.
  - spec: "Mutual TLS (mTLS) client authentication with certificate-bound access tokens"
    description: |
      When mTLS client authentication is enabled, {{site.ai_gateway}} establishes mTLS connections with the IdP using the configured X.509 certificate as client credentials.
      <br><br>
      If the authorization server is configured to bind the client certificate with the issued access token, {{site.ai_gateway}} can validate the access token using mTLS proof of possession.
      <br><br>
      Set [`config.client_auth`](/plugins/openid-connect/reference/#schema--config-client-auth) to `tls_client_auth` and provide a certificate at [`config.tls_client_auth_cert_id`](/plugins/openid-connect/reference/#schema--config-tls-client-auth-cert-id) to enable mTLS auth.
  - spec: "Demonstrating proof-of-possession (DPoP)"
    description: |
      Demonstrating Proof of Possession (DPoP) is an application-level mechanism for proving the sender's ownership of OAuth access and refresh tokens.
      With DPoP, a client can prove possession of a public/private key pair associated with a token by using a header.
      The header contains a signed JWT that includes a reference to the associated access token.
      <br><br>
      When DPoP is enabled, {{site.ai_gateway}} validates the DPoP header in the request to ensure that the sender is authorized to use the access token.
      <br><br>
      Set [`config.proof_of_possession_dpop`](./#schema--config-proof-of-possession-dpop) to `strict` to enable DPoP.
  - spec: |
      mTLS Proof-of-Possession via HTTP header {% new_in 3.15 %}
    description: |
      In enterprise deployments where TLS is terminated at a WAF or load balancer before {{site.ai_gateway}},
      the downstream connection carries no client certificate.
      <br><br>
      {{site.ai_gateway}} can read the certificate from an HTTP header injected by the WAF or proxy and validate its thumbprint against the `cnf.x5t#S256` claim bound in the access token.
      <br><br>
      Set [`config.proof_of_possession_mtls`](/plugins/openid-connect/reference/#schema--config-proof-of-possession-mtls) to `strict` and configure `config.proof_of_possession_mtls_from_header` with the header name and a trusted CA certificate.
{% endtable %}

#### Certificate-bound access tokens

{% include_cached plugins/oidc/cert-bound-access-tokens.md type="auth strategy" gateway=site.ai_gateway schema_page="/ai-gateway/openid-connect/#schema" hide_examples=true jwt_flow_anchor="#jwt-access-token-authentication-bearer" introspection_flow_anchor="#introspection-authentication" session_flow_anchor="#session-authentication" %}

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

{% comment %}
DON't THINK THIS IS SUPPORTED, WILL CHECK
#### mTLS Proof-of-Possession via HTTP header {% new_in 3.15 %}

{% include_cached plugins/oidc/mtls-pop-header.md type="auth strategy" gateway=site.ai_gateway schema_page="/ai-gateway/openid-connect/#schema" hide_examples=true %}

The following is an example mTLS proof-of-possession config:
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: mtls-client-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: mTLS Client Auth
    name: mtls-client-auth
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
      proof_of_possession_auth_methods_validation: true
      proof_of_possession_mtls_from_header:
        certificate_header_name: x-client-cert
        certificate_header_format: base64_encoded
        ca_certificates:
        - $CA_CERTIFICATE_UUID
        ssl_verify: true
      consumer_claims:
      - - sub
      cache_tokens_salt: mtls-client-auth-cache-salt
{% endentity_examples %}
{% endcomment %}

#### Demonstrating Proof-of-Possession (DPoP)

{% include_cached plugins/oidc/dpop.md type="auth strategy" gateway=site.ai_gateway schema_page="/ai-gateway/openid-connect/#schema" hide_examples=true gateway_label="AI Gateway" mtls_client_auth_anchor="#client-authentication" jwt_flow_anchor="#jwt-access-token-authentication-bearer" introspection_flow_anchor="#introspection-authentication" session_flow_anchor="#session-authentication" %}

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

{% include_cached plugins/oidc/multi-idp.md type="auth strategy" gateway=site.ai_gateway schema_page="/ai-gateway/openid-connect/#schema" hide_examples=true %}

### Protected resource metadata {% new_in 3.16 %}

{% include_cached plugins/oidc/protected-resource-metadata.md type="auth strategy" gateway=site.ai_gateway schema_page="/ai-gateway/openid-connect/#schema" hide_examples=true cors="[CORS policy](/ai-gateway/policies/cors/)" %}

### Token exchange

{% include_cached plugins/oidc/token-exchange.md type="auth strategy" gateway=site.ai_gateway gateway_label="AI Gateway" schema_page="/ai-gateway/openid-connect/#schema" hide_examples=true %}

### Using cloud authentication with Redis

{% include_cached /plugins/redis/redis-cloud-auth.md %}

{% include_cached /plugins/redis/enterprise.md redis_group="oidc" %}

## Multiple clients

`config.client_id` and `config.client_secret` are array fields on the OpenID Connect AI Auth Strategy schema, and behave the same way as on the plugin.

{% include_cached plugins/oidc/multiple-clients.md type="auth strategy" gateway=site.ai_gateway schema_page="/ai-gateway/openid-connect/#schema" %}

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
