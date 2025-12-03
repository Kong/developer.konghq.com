---
title: 'JWT Signer'
name: 'JWT Signer'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Verify and sign one or two tokens in a request'

products:
    - gateway

works_on:
    - on-prem
    - konnect


topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional

icon: jwt-signer.png

categories:
  - authentication

tags:
  - authentication
  - jwt

search_aliases:
  - json web tokens
  - jwt-signer

min_version:
  gateway: '1.0'
---

The {{site.base_gateway}} JWT Signer plugin allows you to verify, sign, or re-sign
one or two tokens in a request. With a two-token request, one token
is allocated to an end user and the other token to the client application,
for example.

The plugin refers to tokens as an _access token_
and _channel token_. Tokens can be any valid verifiable tokens. The plugin
supports both opaque tokens through introspection,
and signed JWT tokens through signature verification. There are many
configuration parameters available to accommodate your requirements.

## Configuration notes

Most of the plugin's configuration parameters are optional, but you need to 
specify some options to actually make the plugin work:

* Signature verification requires
[`config.access_token_jwks_uri`](/plugins/jwt-signer/reference/#schema--config-access-token-jwks-uri) and/or [`config.channel_token_jwks_uri`](/plugins/jwt-signer/reference/#schema--config-channel-token-jwks-uri).

* Introspection requires introspection endpoints
[`config.access_token_introspection_endpoint`](/plugins/jwt-signer/reference/#schema--config-access-token-introspection-endpoint) and/or [`config.channel_token_introspection_endpoint`](/plugins/jwt-signer/reference/#schema--config-channel-token-introspection-endpoint).

## Manage key signing

If you specify [`config.access_token_keyset`](/plugins/jwt-signer/reference/#schema--config-access-token-keyset) or [`config.channel_token_keyset`](/plugins/jwt-signer/reference/#schema--config-channel-token-keyset) with either an
`http://` or `https://` prefix, it means that token signing keys are externally managed by you.
In that case, the plugin loads the keys just like it does for [`config.access_token_jwks_uri`](/plugins/jwt-signer/reference/#schema--config-access-token-jwks-uri)
and [`config.channel_token_jwks_uri`](/plugins/jwt-signer/reference/#schema--config-channel-token-jwks-uri). If the prefix is not `http://` or `https://`
(such as `"my-company"` or `"kong"`), {{site.base_gateway}} autogenerates JWKS for supported algorithms.

External JWKS specified with [`config.access_token_keyset`](/plugins/jwt-signer/reference/#schema--config-access-token-keyset) or
[`config.channel_token_keyset`](/plugins/jwt-signer/reference/#schema--config-channel-token-keyset) should also contain private keys with supported `alg`,
either `"RS256"` or `"RS512"` for now. External URLs that contain private keys should
be protected so that only {{site.base_gateway}} can access them. Currently, {{site.base_gateway}} doesn't add any authentication
headers when it loads the keys from an external endpoint, so you have to do it with network
level restrictions. If you commonly need to manage private keys externally
instead of allowing {{site.base_gateway}} to autogenerate them, you can add another parameter
for adding an authentication header (possibly similar to
[`config.channel_token_introspection_authorization`](/plugins/jwt-signer/reference/#schema--config-channel-token-introspection-authorization)).

The key size (the modulo) for RSA keys is currently hard-coded to 2048 bits.

## Manage token signing {% new_in 3.12 %}

You can turn channel and access token signing or re-signing off and on as needed with `config.channel_token_signing` and `config.access_token_signing`.

Use the following use cases to help you determine if you should enable or disable token signing and re-signing:
* [**Enable signing or re-signing**](/plugins/jwt-signer/examples/enable-signing-tokens/): If you don't fully trust the upstream identity provider or want to enforce a local trust boundary, set `config.channel_token_signing` or `config.access_token_signing` to `true`. This ensures that downstream services only need to trust {{site.base_gateway}}'s signing key.
* [**Disable signing or re-signing**](/plugins/jwt-signer/examples/disable-signing-tokens/): If the token already comes from an identity provider and your downstream services already validate that provider's keys, set `config.channel_token_signing` or `config.access_token_signing` to `false`.

## Consumer mapping

The following parameters let you map [Consumers](/gateway/entities/consumer/):

- [`config.access_token_consumer_claim`](/plugins/jwt-signer/reference/#schema--config-access-token-consumer-claim)
- [`config.access_token_introspection_consumer_claim`](/plugins/jwt-signer/reference/#schema--config-access-token-introspection-consumer-claim)
- [`config.channel_token_consumer_claim`](/plugins/jwt-signer/reference/#schema--config-channel-token-consumer-claim)
- [`config.channel_token_introspection_consumer_claim`](/plugins/jwt-signer/reference/#schema--config-channel-token-introspection-consumer-claim)

The plugin only maps Consumers once. 

It applies mappings in the following order, depending on whether the input is opaque or JWT:

1. Access token introspection results
2. Access token JWT payload
3. Channel token introspection results
4. Channel token JWT payload

When mapping is done, no other mappings are used.
The plugin won't try to remap or override Consumers once they've been found and mapped. 
For example, if an access token already maps to a {{site.base_gateway}} Consumer, the plugin doesn't try 
to map a channel token to that Consumer anymore, and won't throw any errors.

A general rule is to map either the access token or the channel token, not both.

## Cached JWKS

The plugin caches JWKS specified with [`config.access_token_jwks_uri`](/plugins/jwt-signer/reference/#schema--config-access-token-jwks-uri) and
[`config.channel_token_jwks_uri`](/plugins/jwt-signer/reference/#schema--config-channel-token-jwks-uri) to the {{site.base_gateway}} database for quicker access to them. The plugin
further caches JWKS in {{site.base_gateway}} nodes' shared memory, and on a per-process level in memory for
even quicker access. When the plugin is responsible for signing the tokens, it
also stores its own keys in the database.

Admin API endpoints never reveal private keys, but do reveal public keys.
Private keys that the plugin autogenerates can only be accessed from the database
directly. Private parts in JWKS include
properties such as `d`, `p`, `q`, `dp`, `dq`, `qi`, and `oth`. 

For public keys using a symmetric algorithm (such as `HS256`) that include the `k` parameter,
the parameter isn't hidden from the Admin API because it is used both to verify and
to sign. This makes it a bit problematic to use, and we strongly suggest using
asymmetric (or public key) algorithms. Doing so also makes rotating the keys
easier because the public keys can be shared between parties
and published without revealing their secrets.

## Allow your upstream service to verify {{site.base_gateway}}-issued tokens

You can give your upstream service the [`/jwt-signer/jwks/kong`](/plugins/jwt-signer/api/#/paths/jwt-signer-jwks-JwtSignerJwks/get) URL for it to verify {{site.base_gateway}}-issued tokens. The response is a standard
JWKS endpoint response. 

The `kong` suffix in the URI is a default value. You can change it
with [`config.access_token_issuer`](/plugins/jwt-signer/reference/#schema--config-access-token-issuer) or [`config.channel_token_issuer`](/plugins/jwt-signer/reference/#schema--config-channel-token-issuer).

You can also make a loopback to this endpoint by routing the {{site.base_gateway}} proxy to this URL.
Then, you can use an [authentication plugin](/plugins/?category=authentication) to protect access to this endpoint,
if needed.

The JWT Signer plugin automatically reloads or regenerates missing JWKS if it can't
find cached ones. The plugin also tries to reload JWKS if it can't verify
the signature of the original access token or channel token, such as when
the original issuer has rotated its keys and signed with the new one that is not
found in {{site.base_gateway}} cache.

## Rotate signing token Keys

Sometimes you might want to rotate the Keys {{site.base_gateway}} uses for signing tokens specified in
[`config.access_token_keyset`](/plugins/jwt-signer/reference/#schema--config-access-token-keyset) and [`config.channel_token_keyset`](/plugins/jwt-signer/reference/#schema--config-channel-token-keyset), or
reload tokens specified in [`config.access_token_jwks_uri`](/plugins/jwt-signer/reference/#schema--config-access-token-jwks-uri) and
[`config.channel_token_jwks_uri`](/plugins/jwt-signer/reference/#schema--config-channel-token-jwks-uri). 

{{site.base_gateway}} stores and uses at most two set of Keys:
**current** and **previous**. If you want {{site.base_gateway}} to forget the previous Keys, you need to
rotate Keys **twice**, as it effectively replaces both current and previous Key Sets
with newly generated tokens or reloaded tokens if the Keys were loaded from
an external URI.

## Claim validation {% new_in 3.12 %}

In {{site.base_gateway}} 3.12 or later, you can perform additional claim validation by specifying the types of token claims as well as which tokens are required and which are optional. 

You can validate the following types of access and channel token claims:
* [Issuer](/plugins/jwt-signer/examples/validate-channel-token-issuers/) (`iss`)
* [Not before](/plugins/jwt-signer/examples/validate-access-token-issuers/) (`nbf`)
* [Subject](/plugins/jwt-signer/examples/validate-channel-token-subjects/) (`sub`)
* Audience (`aud`)

You can also specify optional and required claims with the following:
* `config.access_token_optional_claims`
* `config.channel_token_optional_claims`
* `config.access_token_introspection_optional_claims`
* `config.channel_token_introspection_optional_claims`
* `config.access_token_required_claims`
* `config.channel_token_required_claims`
* `config.access_token_introspection_required_claims`
* `config.channel_token_introspection_required_claims`



