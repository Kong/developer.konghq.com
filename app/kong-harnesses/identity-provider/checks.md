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
[`kong-harnesses login`](/kong-harnesses/login/) and [`kong-harnesses setup`](/kong-harnesses/setup/) check the discovery document again, and also the signing keys, the token response and the ID token.
A renewal checks the token response.
For the client settings, the callback, the scopes and the access token lifetime, see [Register {{site.kong_harnesses}} in your identity provider](/kong-harnesses/identity-provider/).

## Profile values

* `--client-id`: 1 to 256 visible ASCII characters.
* `--audience`: An absolute URI with a scheme, of 1 to 2,048 bytes of visible ASCII characters, without user information or a fragment.
* `--scope`: 2 to 16 scopes, with `openid` and `offline_access`.
  Each scope has 1 to 128 visible ASCII characters, without `"` or `\`, and the list can't have a scope twice.

## URLs

The issuer, `authorization_endpoint`, `token_endpoint`, `jwks_uri` and `revocation_endpoint` must each be a canonical `https` URL:

* At most 2,048 bytes of visible ASCII characters, without `\`.
* A host that is a lowercase DNS name, an IPv4 address, or an IPv6 address in brackets in its canonical short form, without a zone.
  Each label of a DNS name has 1 to 63 letters, digits or `-`, and doesn't start or end with `-`.
  The name has at most 253 characters, and doesn't end with `.`.
* No port, or a port from 1 to 65535 without a zero at the start, other than `443`.
* No user information, fragment, or `.` or `..` path segment.
* Percent encoding with uppercase hexadecimal digits only, and no encoded letter, digit, `-`, `.`, `_`, `~`, `\` or control character.
* The same text after a URL parser reads the URL and writes it again.

The issuer can't have a query.
The query of `authorization_endpoint` can't have a parameter that {{site.kong_harnesses}} sets: `response_type`, `client_id`, `redirect_uri`, `scope`, `state`, `nonce`, `code_challenge`, `code_challenge_method`, `resource`, `audience` or `prompt`.

## HTTP responses

{{site.kong_harnesses}} reads the discovery document from the issuer URL followed by `/.well-known/openid-configuration`.
It reads the discovery document and the signing keys with one `GET` request each.
It doesn't follow redirects, and it uses TLS 1.2 or later for all requests to the identity provider.

Each response from the discovery document, the signing keys and the token endpoint must have:

* A `2xx` status.
* One `Content-Type` header with the value `application/json`, and no parameter other than `charset=utf-8`.
* No `Content-Encoding` other than `identity`.
* A body of at most 65,536 bytes, with the same length as its `Content-Length` header when the response has one.
* A JSON object in UTF-8, with nothing after the object.
  In a renewal response, a member that {{site.kong_harnesses}} reads can't occur twice.
  In the other responses, no member name can be empty or occur twice.

The identity provider must answer within these times:

* The discovery document and the signing keys: 10 seconds each.
* The token endpoint at sign-in: 15 seconds.
* The token endpoint at renewal: 4 seconds.

## Discovery document

The discovery document must have `issuer`, `authorization_endpoint`, `token_endpoint` and `jwks_uri` as strings.
`issuer` must be the same as the issuer of the profile.
For the other rules of the discovery document, see [Discovery document](/kong-harnesses/identity-provider/#discovery-document).

## Signing keys

The document at `jwks_uri` must have a `keys` array of 1 to 64 keys, and at least one key must be usable.
{{site.kong_harnesses}} skips a key that it can't use:

* A key type other than `RSA` or `EC`.
* An `alg` value other than `RS256`, `RS384`, `RS512`, `PS256`, `PS384`, `PS512`, `ES256`, `ES384` or `ES512`.
* A `use` value other than `sig`.
* A `key_ops` list without `verify`.

Some keys make the sign-in fail, even when the ID token uses another key:

* A key without `kty`, or a `kid` that isn't 1 to 256 visible ASCII characters.
* Two usable keys with the same `kid`.
* An `RSA` key with a modulus of less than 2,048 or more than 8,192 bits, or a public exponent that isn't an odd number from 3 to 2,147,483,647.
* An `EC` key on a curve other than `P-256`, `P-384` or `P-521`, or with a point that isn't on the curve.

## Token responses

At sign-in, the token response must have `access_token`, `token_type`, `id_token`, `refresh_token` and `expires_in`.
At renewal, it must have `access_token`, `token_type` and `expires_in`, and it can leave out `refresh_token`.
In both responses:

* `token_type` is `Bearer`, in any case.
* `expires_in` is a JSON number with digits only, not a string.
* `access_token`, `refresh_token` and `scope` are strings.
* `scope` has single spaces between scopes, and no space at the start or the end.
* A sign-in response has no `error` member.

At renewal, {{site.kong_harnesses}} ignores an `id_token`.
When the identity provider refuses a renewal with `invalid_grant` and a `4xx` status other than `429`, {{site.kong_harnesses}} removes the saved sign-in.

## ID token

The ID token from the sign-in must have:

* At most 32,768 visible ASCII characters, in three parts.
* An `alg` header that is one of the supported algorithms and that the discovery document lists.
* No `crit` header, and no `typ` header other than `JWT`.
* A signature from exactly one usable key that matches `alg`, and `kid` when the header has one.
* `iss` that is the issuer of the profile, and a `sub` of 1 to 255 visible ASCII characters.
* `aud` that is the client ID, as a string or as an array with only the client ID.
* `azp` that is the client ID, when the token has one.
* The `nonce` of the sign-in request.
* `exp` in the future, and `iat` that isn't after `exp` or more than 1 minute in the future, both as JSON numbers.
* An `at_hash` that matches the access token, when the token has one.
