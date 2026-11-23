---
title: "Identity provider checks in {{site.kong_harnesses}}"
description: "The checks that {{site.kong_harnesses}} makes on the URLs, discovery document, signing keys, token responses and ID tokens of an OpenID Connect identity provider."
content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

min_version:
  ai-gateway: '2.4'

tags:
  - cli
  - openid-connect

breadcrumbs:
  - /kong-harnesses/
  - /kong-harnesses/identity-provider/

related_resources:
  - text: Register kong-harnesses in your identity provider
    url: /kong-harnesses/identity-provider/
  - text: Identity provider settings for kong-harnesses
    url: /kong-harnesses/identity-provider/providers/
---

Use these checks to find why {{site.kong_harnesses}} refuses a value or a response of your identity provider at profile creation, at sign-in or at renewal.
{{site.kong_harnesses}} refuses an identity provider value or response that doesn't meet these checks.
[`kong-harnesses profile create`](/kong-harnesses/profile/create/) checks the profile values and the discovery document, and [`kong-harnesses profile import`](/kong-harnesses/profile/import/) checks the profile values.
[`kong-harnesses login`](/kong-harnesses/login/) and [`kong-harnesses setup`](/kong-harnesses/setup/) check the discovery document again, and also the callback, the signing keys, the token response and the ID token.
A renewal checks the token response.
For the client settings, the scopes and the access token lifetime, see [Register {{site.kong_harnesses}} in your identity provider](/kong-harnesses/identity-provider/).

{{site.kong_harnesses}} also refuses a response that breaks the encoding rules of [OAuth 2.0](https://www.rfc-editor.org/rfc/rfc6749), [OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html), [JWS](https://www.rfc-editor.org/rfc/rfc7515), [JWK](https://www.rfc-editor.org/rfc/rfc7517), [JWA](https://www.rfc-editor.org/rfc/rfc7518) or [JWT](https://www.rfc-editor.org/rfc/rfc7519), such as a value that isn't in Base64url.
It also refuses a response with more than 16,384 bytes of headers, or a body that it can't read completely.

## Profile values

For the rules of the identity provider values in a profile, such as `--client-id`, `--audience`, `--scope` and `discovery_url`, see [Sign-in fields](/kong-harnesses/profile-file/#sign-in-fields).
For `--redirect-uri`, see [Callback](/kong-harnesses/identity-provider/#callback).

## URLs

The issuer, `discovery_url`, `authorization_endpoint`, `token_endpoint`, `jwks_uri` and `revocation_endpoint` must each be a canonical `https` URL:

* At most 2,048 bytes of visible ASCII characters, without `\`.
* A host without percent encoding that is a lowercase DNS name, an IPv4 address in canonical dotted decimal form, such as `192.0.2.1`, or an IPv6 address in brackets in its canonical short form, without a zone.
  Each label of a DNS name has 1 to 63 letters, digits or `-`, and doesn't start or end with `-`.
  The name has at most 253 characters, and doesn't end with `.`.
  A host of only digits and dots must be an IPv4 address in that form, so `192.0.02.1` and `3221225985` fail.
* No port, or a port from 1 to 65535 other than `443`, without a zero at the start.
* No user information, fragment, or `.` or `..` path segment.
* Percent encoding with uppercase hexadecimal digits only, and without an encoded letter, digit, `-`, `.`, `_`, `~`, `\` or control character.
* The same text after a URL parser reads the URL and writes it again.

The issuer can't have a query.
The query of `authorization_endpoint` can't have a parameter that {{site.kong_harnesses}} sets: `response_type`, `client_id`, `redirect_uri`, `scope`, `state`, `nonce`, `code_challenge`, `code_challenge_method`, `resource`, `audience` or `prompt`.

## Callback

During a sign-in, {{site.kong_harnesses}} accepts one request on the callback: a request to the callback path with the `state` of that sign-in.
It ignores other requests and keeps waiting.
The accepted request must meet these checks:

* It is a `GET` request without a body, with a `Host` header that has the exact host and port of the callback in the profile, such as `localhost:9876`.
* Its path is the callback path, without percent encoding.
* Each of `state`, `code`, `error`, `error_description`, `error_uri`, `iss` and `session_state` occurs at most once, with a value that isn't empty.
* It has `code` or `error`, but not both.
  When it has `error`, the sign-in fails with a fixed message for the `error` code, and {{site.kong_harnesses}} doesn't show the text of the identity provider.
  When it has `code`, it doesn't have `error_description` or `error_uri`.
* `code` has 1 to 8,192 visible ASCII characters.
* When the request has `iss`, the value is the issuer of the profile.
  When the discovery document sets `authorization_response_iss_parameter_supported` to `true`, the request must have `iss`.

{{site.kong_harnesses}} ignores other parameters.

## HTTP responses

{{site.kong_harnesses}} reads the discovery document from `discovery_url` and the signing keys from `jwks_uri`, with one `GET` request each.
It doesn't follow redirects, and it uses TLS 1.2 or later for all requests to the identity provider.
The TLS certificate of the identity provider must chain to the system trust store of each developer computer, because the gateway CA bundle of a profile doesn't apply to the identity provider.
If the identity provider uses a certificate from a private CA, add the CA to that trust store.

A response with a status other than `2xx` fails the request.
At renewal, when the token endpoint answers with a `4xx` status other than `429` and a complete JSON body of at most 65,536 bytes with an `error` member of `invalid_grant`, {{site.kong_harnesses}} also tries to remove the saved sign-in.
For other error responses, the renewal fails and the saved sign-in stays.

A `2xx` response from the discovery document, the signing keys and the token endpoint must have:

* One `Content-Type` header with the value `application/json`, and without a parameter other than `charset=utf-8`, in any case.
* No `Content-Encoding` header, or one with the value `identity`.
* A body of at most 65,536 bytes, with the same length as its `Content-Length` header when the response has one.
* One JSON object in UTF-8, with only whitespace after it.
  In a renewal response, a top-level member that {{site.kong_harnesses}} reads can't occur twice.
  In the other responses, a top-level member name can't be empty or occur twice.

The identity provider must answer within these times:

* The discovery document and the signing keys: 10 seconds each.
* The token endpoint at sign-in: 15 seconds.
* The token endpoint at renewal: 4 seconds.
  When no proxy applies to the token endpoint, {{site.kong_harnesses}} must also open a TLS connection to it within 2 seconds, before it sends the refresh token.

## Discovery document

The discovery document must have `issuer`, `authorization_endpoint`, `token_endpoint` and `jwks_uri` as strings, and `issuer` must match the issuer of the profile character by character, including a trailing slash.
Each of these URLs, and `revocation_endpoint` when the document lists it, must meet the rules in [URLs](#urls).

* The document has `response_types_supported` and `id_token_signing_alg_values_supported`, and each is a nonempty JSON array of unique strings.
  `grant_types_supported`, `token_endpoint_auth_methods_supported` and `code_challenge_methods_supported` follow the same rule when the document lists them.
* `response_types_supported` lists the `code` response type.
* `id_token_signing_alg_values_supported` lists at least one of `RS256`, `RS384`, `RS512`, `PS256`, `PS384`, `PS512`, `ES256`, `ES384` or `ES512`.
  Configure the client to sign ID tokens with one of these algorithms that the discovery document also lists.
* When the document lists `authorization_response_iss_parameter_supported`, it is `true` or `false`.
* When the document lists one of these fields, the field has the value that {{site.kong_harnesses}} needs:
  * `code_challenge_methods_supported` lists the `S256` PKCE method.
  * `grant_types_supported` lists the `authorization_code` and `refresh_token` grant types.
  * `token_endpoint_auth_methods_supported` lists the `none` method, for a public client.
    `--public-client-evidence deployment` skips this check.

At each sign-in, {{site.kong_harnesses}} reads the discovery document again and runs these checks again.
`authorization_endpoint`, `token_endpoint` and `jwks_uri` must also be the same as the values that `profile create` saved in the profile, and so must `revocation_endpoint` when the profile has one.
When one of them changes, sign-in fails until you create the profile again and give the new profile to developers.

{{site.kong_harnesses}} accepts a discovery document that leaves out `code_challenge_methods_supported`, `grant_types_supported` or `token_endpoint_auth_methods_supported`, but a missing field doesn't prove the capability.
For example, without `code_challenge_methods_supported`, check that the token endpoint refuses a code exchange without a valid `S256` code verifier.

## Signing keys

The document at `jwks_uri` must have a `keys` array of 1 to 64 keys, and at least one key must be usable.
A key can leave out `alg`, `use` and `key_ops`.
Each key must meet these rules, or the sign-in fails, even when another key in the document can verify the ID token:

* `kty` is a string.
* `kid`, when the key has one, has 1 to 256 visible ASCII characters.

Then {{site.kong_harnesses}} reads the other members of the key in this order, and stops at the first one that makes it skip the key:

1. When the key has `alg` with a value that isn't a string, or that isn't `RS256`, `RS384`, `RS512`, `PS256`, `PS384`, `PS512`, `ES256`, `ES384` or `ES512`, it skips the key.
2. When the key has `use` with a value that isn't a string, the sign-in fails.
   When `use` is a string other than `sig`, it skips the key.
3. When the key has `key_ops` with a value that isn't a nonempty array of unique strings, the sign-in fails.
   When `key_ops` doesn't have `verify`, it skips the key.
4. When `kty` is other than `RSA` or `EC`, it skips the key.
5. When an `RSA` key doesn't have a modulus of 2,048 to 8,192 bits and a public exponent that is an odd number from 3 to 2,147,483,647, the sign-in fails.
   When an `EC` key doesn't have a `crv` string of `P-256`, `P-384` or `P-521`, with `x` and `y` values that are a point on that curve, the sign-in fails.

Two usable keys can't have the same nonempty `kid`.

## Token responses

At sign-in, the token response must have `access_token`, `token_type`, `id_token`, `refresh_token` and `expires_in`.
At renewal, it must have `access_token`, `token_type` and `expires_in`, and it can leave out `refresh_token`, but it can't send an empty one.
In both responses:

* `access_token` has 1 to 16,384 characters, from letters, digits, `-`, `.`, `_`, `~`, `+` and `/`, with optional `=` characters at the end.
* `refresh_token` has 1 to 16,384 visible ASCII characters.
* `token_type` is `Bearer`, in any case.
* `expires_in` is a JSON number with digits only.
* `scope`, when present, is a nonempty string with single spaces between scopes, without a space at the start or the end.
  Each scope in it has 1 to 128 visible ASCII characters, without `"` or `\`, occurs only once, and must match a different allowed scope.

At sign-in, the allowed scopes are the requested scopes.
At renewal, they are the last accepted list.
A response with `scope` sets the accepted list to its matched scopes, and a response without `scope` keeps the allowed list.

{{site.kong_harnesses}} matches each returned scope against the allowed scopes in order:

1. Match an equal allowed scope.
2. Match an allowed scope equal to the percent-decoded value.
3. Match when exactly one allowed scope is a URI with a scheme and a host whose last path segment equals the returned scope, such as `api://API_ID/access_as_user` for `access_as_user`.

When `scope` is present, it must keep every scope that the profile requests other than `openid`, `profile`, `email`, `address`, `phone`, `offline_access`, `groups` or `device_sso`.

A successful sign-in response can't have an `error` member.
At renewal, {{site.kong_harnesses}} ignores an `id_token`.

## ID token

The ID token from the sign-in must meet these rules:

* It has at most 32,768 visible ASCII characters, in three parts separated by `.`.
* Its `alg` header is one of the supported algorithms, and the discovery document lists it.
* It doesn't have a `crit` header.
  A `typ` header, when the token has one, is `JWT`, and a `kid` header, when the token has one, has 1 to 256 visible ASCII characters.
* Exactly one usable key matches the `alg` of the token, and its `kid` when the header has one.
  An `RS` or `PS` algorithm needs an `RSA` key, and `ES256`, `ES384` and `ES512` need an `EC` key on `P-256`, `P-384` and `P-521`.
  So two usable keys for the same algorithm without a `kid` in the header fail the sign-in, even when one of them can verify the token.
* The signature passes verification with that key.
* `iss` is the issuer of the profile, and `sub` has 1 to 255 visible ASCII characters.
* `aud` is the client ID, as a string or as an array with only the client ID.
* `azp`, when the token has one, is the client ID.
* `nonce` is the nonce of the sign-in request.
* `exp` is in the future, without a tolerance for clock difference, and `iat` isn't after `exp` or more than 1 minute in the future.
  Both are JSON numbers with digits only that fit in a signed 64-bit integer, so `1.5` and `1.7e9` fail.
* `at_hash`, when the token has one, matches the access token.
