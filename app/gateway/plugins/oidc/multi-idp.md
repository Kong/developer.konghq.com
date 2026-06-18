---
title: Multi-IdP token validation with OpenID Connect

description: "Configure the OpenID Connect plugin to validate tokens from multiple identity providers using a trusted issuer registry or token exchange."
content_type: reference
layout: reference
permalink: /plugins/openid-connect/multi-idp/

products:
  - gateway

breadcrumbs:
  - /plugins/
  - /plugins/openid-connect/


works_on:
  - on-prem
  - konnect

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: OpenID Connect plugin reference
    url: /plugins/openid-connect/
  - text: "How-to: Configure OpenID Connect with multiple IdPs"
    url: /how-to/configure-oidc-with-multi-idp/
  - text: "How-to: Configure OpenID Connect with token exchange using Keycloak"
    url: /how-to/configure-oidc-with-token-exchange/
---

If your APIs serve clients from multiple identity providers (IdPs), the [OpenID Connect (OIDC) plugin](/plugins/openid-connect/) can act as a federated authentication broker at the gateway layer.
For example, you might have employees using Okta, B2B partners using Azure AD, and legacy systems on an in-house IdP.
In this setup, {{site.base_gateway}} centralizes auth policy and forwards only the verified identity context upstream, so backends don't need per-IdP validation logic.

The OIDC plugin supports two approaches for multi-IdP authentication, both using [JWT access token (bearer) auth](/plugins/openid-connect/#jwt-access-token-authentication-flow).
Clients authenticate against their respective IdPs and present the resulting bearer token to {{site.base_gateway}}:

{% table %}
columns:
  - title: ""
    key: label
  - title: "[Trusted issuers registry](#option-1-trusted-issuers-registry)"
    key: option1
  - title: "[Token exchange](#option-2-token-exchange)"
    key: option2
rows:
  - label: "How it works"
    option1: "Validates tokens from multiple issuers against their JWKS endpoints. Backends receive the original, unmodified token."
    option2: "Exchanges incoming tokens for a canonical token from one trusted target issuer. Backends only ever see tokens from that issuer."
  - label: "When to use"
    option1: "Token formats are consistent across IdPs. Backends can accept tokens from different issuers."
    option2: "Backends must trust a single issuer. Token formats differ across IdPs. You need downscoping, normalization, or cross-domain federation."
  - label: "IdP requirements"
    option1: "No special grant needed."
    option2: "IdPs must support [RFC 8693](https://www.rfc-editor.org/rfc/rfc8693) token exchange."
  - label: "Min version"
    option1: "Any"
    option2: "3.14"
  - label: "Key config parameters"
    option1: |
      * `config.issuers_allowed`
      * `config.extra_jwks_uris`
    option2: |
      * `config.token_exchange.subject_token_issuers`
      * `config.token_exchange.subject_token_issuers[].verify_signature` {% new_in 3.15 %}
      * `config.token_exchange.subject_token_issuers[].jwks_uri` {% new_in 3.15 %}
{% endtable %}

## Option 1: Trusted issuers registry

In this approach, {{site.base_gateway}} acts as a federated authentication broker maintaining a registry of trusted issuers and their public key endpoints.
The plugin inspects the `iss` claim of an incoming bearer token, looks up the matching JWKS endpoint from the configured list, validates the token signature and standard claims, then forwards the verified request upstream.
No token transformation occurs.

{% include_cached /plugins/oidc/diagrams/multi-idp-trusted-issuers.md %}

Configure the following OIDC plugin settings:

* [`config.issuers_allowed`](/plugins/openid-connect/reference/#schema--config-issuers-allowed): Allowlist of issuer URLs the plugin will accept.
Add every IdP's issuer URL here, exactly as it appears in the `iss` claim of their tokens.
* [`config.extra_jwks_uris`](/plugins/openid-connect/reference/#schema--config-extra-jwks-uris): Additional JWKS endpoints for each IdP beyond the primary `config.issuer`.
The plugin checks the primary discovery JWKS first, then falls back to these.

This approach works best when tokens issued by each IdP follow the same claim naming conventions.

{:.info}
> **Note**: The plugin uses `config.issuer` for discovery and to identify the primary issuer.
> Tokens from other IdPs will fail `iss` claim verification unless you set [`config.verify_claims`](/plugins/openid-connect/reference/#schema--config-verify-claims) to `false` and control allowed issuers via `config.issuers_allowed` instead.

If you update `config.extra_jwks_uris` after the plugin is already configured, [clear the discovery cache](/plugins/openid-connect/api/#/operations/deleteDiscoveryCache) for the change to take effect.

### Configuration example

The following example configures the OIDC plugin to accept tokens from two identity providers.
The first IdP is the primary `config.issuer`, while the second is added via `config.extra_jwks_uris`:

```yaml
config:
  issuer: https://idp-a.example.com
  auth_methods:
    - bearer
  extra_jwks_uris:
    - https://idp-b.example.com/oauth2/v1/keys
  issuers_allowed:
    - https://idp-a.example.com
    - https://idp-b.example.com
  verify_signature: true
  verify_claims: false
```

In this example, a client authenticated with `idp-a` presents a bearer token.
{{site.base_gateway}} validates it against `idp-a`'s JWKS and checks the issuer against `config.issuers_allowed`.
The same flow applies to a client from `idp-b`.
Both reach the upstream service without any token transformation.

For more detail and a complete walkthrough:
* [Plugin example: Token validation for multiple IdPs](/plugins/openid-connect/examples/extra-jwks/)
* [How-to: Configure OpenID Connect with multiple IdPs](/how-to/configure-oidc-with-multi-idp/)

## Option 2: Token exchange {% new_in 3.14 %}

Token exchange is a standard, protocol-driven way to swap an incoming security token for a new one.
Using JWT access token authentication, the plugin validates the incoming bearer token (the "subject token"), then uses its own client credentials to exchange it with the target issuer per [RFC 8693](https://www.rfc-editor.org/rfc/rfc8693).
The upstream service receives the exchanged token from the target issuer, regardless of which IdP the client originally authenticated with.

{% include_cached /plugins/oidc/diagrams/token-exchange.md %}

This approach also unlocks use cases beyond multi-IdP:

* Downscoping: Exchange a high-privilege token for one with fewer scopes before forwarding to a less-trusted upstream.
* Cross-domain federation: Exchange tokens when clients use one IdP but your APIs are protected by another.
* Token translation: Convert tokens with different claim structures into a consistent internal format that your microservices understand.
* On-behalf flows: Set up delegation and impersonation, where one client acts on behalf of another.

Key configuration parameters:

* [`config.token_exchange.subject_token_issuers`](/plugins/openid-connect/reference/#schema--config-token-exchange-subject-token-issuers): Explicit list of trusted input issuers.
The plugin only exchanges tokens whose `iss` claim matches an entry here.
* [`config.token_exchange.subject_token_issuers[].verify_signature`](/plugins/openid-connect/reference/#schema--config-token-exchange-subject-token-issuers-verify-signature) {% new_in 3.15 %}: Set to `true` to cryptographically verify the subject token's signature at the gateway before sending the exchange request to the IdP.
Defaults to `false` for backward compatibility.
We recommend enabling this for all subject token issuers because it prevents tokens with invalid signatures from consuming IdP resources.
* [`config.token_exchange.subject_token_issuers[].jwks_uri`](/plugins/openid-connect/reference/#schema--config-token-exchange-subject-token-issuers-jwks-uri) {% new_in 3.15 %}: An optional explicit JWKS endpoint for the issuer.
If not set, {{site.base_gateway}} resolves the JWKS URI from OIDC discovery.
Only used when `verify_signature` is `true`.
* [`config.token_exchange.conditions`](/plugins/openid-connect/reference/#schema--config-token-exchange-conditions): Optional per-issuer rules that control when to trigger the exchange.
If the subject token issuer and the target issuer (the one configured in `config.issuer`) are different, exchange always triggers.
If they match, conditions determine whether to exchange.
* [`config.token_exchange.request`](/plugins/openid-connect/reference/#schema--config-token-exchange-request): The scopes and audience to request in the exchanged token.

With token exchange, trust is strictly enforced on both sides.
{{site.base_gateway}} only exchanges tokens whose issuer is explicitly listed in `subject_token_issuers`.
Each IdP in the list must also authorize {{site.base_gateway}} as a trusted client eligible for the token exchange grant.

### Configuration example

The following example configures {{site.base_gateway}} to act as `kong-client` at the target issuer (`idp-a`) and exchange tokens issued by `idp-b`:

```yaml
config:
  issuer: https://idp-a.example.com
  client_id:
    - kong-client
  client_secret:
    - ${kong-client-secret}
  client_auth:
    - client_secret_post
  auth_methods:
    - bearer
  token_exchange:
    subject_token_issuers:
      - issuer: https://idp-b.example.com
        verify_signature: true
```

When a client from `idp-b` presents a bearer token, {{site.base_gateway}} verifies its signature, then exchanges it with `idp-a` to produce a token the upstream service trusts.
Tokens already issued by `idp-a` are validated as-is unless conditions require an exchange.

For more detail, see:
* [Plugin example: Token exchange for cross-domain security](/plugins/openid-connect/examples/token-exchange-cross-domain/)
* [Plugin example: Token transformation](/plugins/openid-connect/examples/token-exchange-transformation/)
* [How-to: Configure OpenID Connect with token exchange using Keycloak](/how-to/configure-oidc-with-token-exchange/)
* [Token exchange reference](/plugins/openid-connect/#token-exchange)

## Troubleshooting

The following errors can appear in the {{site.base_gateway}} error log whether you're using one issuer or multiple.
The fix differs depending on which approach you're using.
For general debugging steps, see [Debugging the OIDC plugin](/plugins/openid-connect/#debugging-the-oidc-plugin).

{% table %}
columns:
  - title: Error
    key: error
  - title: Log message
    key: log
  - title: Likely cause
    key: cause
rows:
  - error: Expired token
    log: "`invalid exp claim (<timestamp>) was specified for access token`"
    cause: |
      The token's `exp` claim is in the past. Get a new token from the IdP.
  - error: Signature verification failure
    log: "`invalid signature (pkey:verify: ...)`"
    cause: |
      The signing key for the token's issuer isn't available to the plugin.
      * If using a trusted issuer registry, check that the issuer's JWKS endpoint is listed in `config.extra_jwks_uris` and that the [discovery cache has been cleared](/plugins/openid-connect/api/#/operations/deleteDiscoveryCache) after any config change.
      * If using token exchange without `verify_signature`, confirm that `config.token_exchange.subject_token_issuers` includes the token's `iss` value.
      * If using token exchange with `verify_signature: true`, confirm that the JWKS endpoint is reachable from {{site.base_gateway}}. If you set `jwks_uri` explicitly, verify that URI is correct. If not set, check that OIDC discovery succeeds for the issuer URL.
{% endtable %}
