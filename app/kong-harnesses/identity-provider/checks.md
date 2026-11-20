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

{{site.kong_harnesses}} refuses an identity provider value or response that doesn't meet these checks.
[`kong-harnesses profile create`](/kong-harnesses/profile/create/) checks the profile values and the discovery document, and [`kong-harnesses profile import`](/kong-harnesses/profile/import/) checks the profile values.
[`kong-harnesses login`](/kong-harnesses/login/) and [`kong-harnesses setup`](/kong-harnesses/setup/) check the discovery document again, and also the callback, the signing keys, the token response and the ID token.
A renewal checks the token response.
For the client settings, the scopes and the access token lifetime, see [Register {{site.kong_harnesses}} in your identity provider](/kong-harnesses/identity-provider/).

This page lists the checks that the settings of an identity provider or a profile can break.
{{site.kong_harnesses}} also refuses a response that breaks the encoding rules of [OAuth 2.0](https://www.rfc-editor.org/rfc/rfc6749), [OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html), [JWS](https://www.rfc-editor.org/rfc/rfc7515), [JWK](https://www.rfc-editor.org/rfc/rfc7517), [JWA](https://www.rfc-editor.org/rfc/rfc7518) or [JWT](https://www.rfc-editor.org/rfc/rfc7519), such as a value that isn't in Base64url, and a response with more than 16,384 bytes of headers or a body that it can't read completely.

## Profile values

* `--client-id`: 1 to 256 visible ASCII characters.
* `--audience`: An absolute URI of 1 to 2,048 bytes of visible ASCII characters, without user information or a fragment.
* `--scope`: 2 to 16 scopes, with `openid` and `offline_access`.
  Each scope has 1 to 128 visible ASCII characters, without `"` or `\`, and the list can't have a scope twice.
* `--gateway-origin`: A canonical `https` origin, or an `http` origin on a loopback host, such as `http://localhost:8000`.
  The origin has no path, query, fragment, user information or default port, and an `http` origin can't use an IPv4-mapped IPv6 address.
* `discovery_url` in a profile file: The issuer URL without a trailing slash, followed by `/.well-known/openid-configuration`.

## URLs

The issuer, `authorization_endpoint`, `token_endpoint`, `jwks_uri` and `revocation_endpoint` must each be a canonical `https` URL:

* At most 2,048 bytes of visible ASCII characters, without `\`.
* A host that is a lowercase DNS name, an IPv4 address, or an IPv6 address in brackets in its canonical short form, without a zone.
  Each label of a DNS name has 1 to 63 letters, digits or `-`, and doesn't start or end with `-`.
  The name has at most 253 characters, and doesn't end with `.`.
  A host of only digits and dots must be an IPv4 address in its canonical form, such as `192.0.2.1`.
* No port, or a port from 1 to 65535 without a zero at the start, other than `443`.
* No user information, fragment, or `.` or `..` path segment.
* Percent encoding with uppercase hexadecimal digits only, and no encoded letter, digit, `-`, `.`, `_`, `~`, `\` or control character.
* The same text after a URL parser reads the URL and writes it again.

The issuer can't have a query.
The query of `authorization_endpoint` can't have a parameter that {{site.kong_harnesses}} sets: `response_type`, `client_id`, `redirect_uri`, `scope`, `state`, `nonce`, `code_challenge`, `code_challenge_method`, `resource`, `audience` or `prompt`.

## Callback

While the developer signs in, {{site.kong_harnesses}} keeps waiting when a request comes to another path or without the `state` of this sign-in.
A request to the callback path with that `state` ends the wait, and it must meet these checks:

* It is a `GET` request without a body, with a `Host` header that has the host and port of the callback.
* Each of `state`, `code`, `error`, `error_description`, `error_uri`, `iss` and `session_state` occurs at most once, with a value that isn't empty.
* It has `code` or `error`, but not both.
  With `error`, the sign-in fails with the error of the identity provider.
  With `code`, it has no `error_description` or `error_uri`.
* `code` has 1 to 8,192 visible ASCII characters.
* When the request has `iss`, the value is the issuer of the profile.
  When the discovery document sets `authorization_response_iss_parameter_supported` to `true`, the request must have `iss`.

{{site.kong_harnesses}} ignores other parameters.

## HTTP responses

{{site.kong_harnesses}} reads the discovery document from the issuer URL without a trailing slash, followed by `/.well-known/openid-configuration`.
It reads the discovery document and the signing keys with one `GET` request each.
It doesn't follow redirects, and it uses TLS 1.2 or later for all requests to the identity provider.

Each response from the discovery document, the signing keys and the token endpoint must have:

* A `2xx` status.
* One `Content-Type` header with the value `application/json`, and no parameter other than `charset=utf-8`, in any case.
* No `Content-Encoding` header, or one with the value `identity`.
* A body of at most 65,536 bytes, with the same length as its `Content-Length` header when the response has one.
* One JSON object in UTF-8, with only whitespace after it.
  In a renewal response, a top-level member that {{site.kong_harnesses}} reads can't occur twice.
  In the other responses, a top-level member name can't be empty or occur twice.

The identity provider must answer within these times:

* The discovery document and the signing keys: 10 seconds each.
* The token endpoint at sign-in: 15 seconds.
* The token endpoint at renewal: 4 seconds.
  Before {{site.kong_harnesses}} sends the refresh token, it must also open a TLS connection to the token endpoint within 2 seconds.

## Discovery document

The discovery document must have `issuer`, `authorization_endpoint`, `token_endpoint` and `jwks_uri` as strings, and `issuer` must be the same as the issuer of the profile.
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

{{site.kong_harnesses}} accepts a discovery document that leaves out any of these three fields, but a missing field doesn't prove the capability.
For example, without `code_challenge_methods_supported`, check that the token endpoint refuses a code exchange without a valid `S256` code verifier.

## Signing keys

The document at `jwks_uri` must have a `keys` array of 1 to 64 keys, and at least one key must be usable.
Each key has `kty` as a string.
{{site.kong_harnesses}} skips a key that it can't use:

* A key type other than `RSA` or `EC`.
* An `alg` value other than `RS256`, `RS384`, `RS512`, `PS256`, `PS384`, `PS512`, `ES256`, `ES384` or `ES512`.
* A `use` value other than `sig`.
* A `key_ops` list without `verify`.

Some keys make the sign-in fail, even when the ID token uses another key:

* A `kid` that isn't 1 to 256 visible ASCII characters.
* Two usable keys with the same `kid`.
* An `RSA` key with a modulus of less than 2,048 or more than 8,192 bits, or a public exponent that isn't an odd number from 3 to 2,147,483,647.
* An `EC` key without a `crv` string for `P-256`, `P-384` or `P-521`.

## Token responses

At sign-in, the token response must have `access_token`, `token_type`, `id_token`, `refresh_token` and `expires_in`.
At renewal, it must have `access_token`, `token_type` and `expires_in`, and it can leave out `refresh_token`, but it can't send an empty one.
In both responses:

* `access_token` has 1 to 16,384 characters, from letters, digits, `-`, `.`, `_`, `~`, `+` and `/`, with optional `=` characters at the end.
* `refresh_token` has 1 to 16,384 visible ASCII characters.
* `token_type` is `Bearer`, in any case.
* `expires_in` is a JSON number with digits only, not a string.
* `scope` is a string with single spaces between scopes, and no space at the start or the end.
  Each scope in it has 1 to 128 visible ASCII characters, without `"` or `\`, and occurs only once.

Omit the `error` member from a successful sign-in response.
At renewal, {{site.kong_harnesses}} ignores an `id_token`.
When the identity provider refuses a renewal with `invalid_grant` and a `4xx` status other than `429`, {{site.kong_harnesses}} removes the saved sign-in.

## ID token

The ID token from the sign-in must have:

* At most 32,768 visible ASCII characters, in three parts.
* An `alg` header that is one of the supported algorithms and that the discovery document lists.
* No `crit` header, no `typ` header other than `JWT`, and no `kid` header that isn't 1 to 256 visible ASCII characters.
* A signature from exactly one usable key that matches `alg`, and `kid` when the header has one.
* `iss` that is the issuer of the profile, and a `sub` of 1 to 255 visible ASCII characters.
* `aud` that is the client ID, as a string or as an array with only the client ID.
* `azp` that is the client ID, when the token has one.
* The `nonce` of the sign-in request.
* `exp` in the future, without a tolerance for clock difference, and `iat` that isn't after `exp` or more than 1 minute in the future.
  Both are JSON numbers with digits only that fit in a signed 64-bit integer, so `1.5` and `1.7e9` fail.
* An `at_hash` that matches the access token, when the token has one.
