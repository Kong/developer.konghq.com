---
title: JWT

name: JWT
publisher: kong-inc
content_type: plugin
description: Verify and authenticate JSON Web Tokens
tags:
    - authentication
    - jwt

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
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: jwt.png

categories:
  - authentication

search_aliases:
  - json web tokens

min_version:
  gateway: '1.0'

---

The JWT plugin lets you verify requests containing HS256 or RS256 signed JSON Web Tokens, as specified in [RFC 7519](https://tools.ietf.org/html/rfc7519).

When you enable this plugin, it grants JWT credentials (public and secret keys) to each of your Consumers, which must be used to sign their JWTs. You can then pass a token through any of the following:

* A query string parameter
* A cookie
* HTTP request headers

{{site.base_gateway}} will either proxy the request to your upstream services if the token’s signature is verified, or discard the request if not. {{site.base_gateway}} can also perform verifications on some of the registered claims of RFC 7519 (exp and nbf). If {{site.base_gateway}} finds multiple tokens that differ - even if they are valid - the request will be rejected to prevent JWT smuggling.

## Using the plugin

To use the plugin, you need to do the following:
1. Create a [Consumer](/gateway/entities/consumer/) and associate one or more JWT credentials (holding the public and private keys used to verify the token) to it. The Consumer represents a developer using the final upstream service.
1. Create a JWT credential for the Consumer, either with the [`/consumers/{consumer}/jwt`](/plugins/jwt/api/) endpoint or by specifying `jwt_secrets:` for the Consumer in a declarative config file.
   
   {:.warning}
   > **Note for decK and {{site.kic_product_name}} users:** The declarative configuration used in decK and the {{site.kic_product_name}} imposes some additional validation requirements that differ from the requirements listed above. Because they cannot rely on defaults and do not implement their own algorithm-specific requirements, all fields other than `rsa_public_key` fields are required.
   > <br/><br/>
   > You should always fill out `key`, `algorithm`, and `secret`. If you use any `RS`, `ES`, or `PS` algorithm, use a dummy value for `secret`. In {{site.base_gateway}} 3.6 or earlier, you use the `RS256` or `ES256` algorithm instead.
1. Sign your JWT following [RFC 7519](https://tools.ietf.org/html/rfc7519) standards.
1. Enable the JWT plugin; see the [plugin configuration examples](/plugins/jwt/examples/).
1. The JWT can now be included in a request to {{site.base_gateway}}. {{site.base_gateway}} *only* proxies requests that include a valid signature, provided they don't include an invalid verified claim (optionally configured with [`config.claims_to_verify`](/plugins/jwt/reference/#schema--config-claims-to-verify)).

For more detail, see:
* End-to-end tutorial for [Authenticating Consumers with JWT](/how-to/authenticate-consumers-jwt/)
* All [JWT plugin configuration examples](/plugins/jwt/examples/)

## Craft a JWT with public/private keys (RS256 or ES256)

If you want to use RS256 or ES256 to verify your JWTs, then when creating a JWT credential,
select `RS256` or `ES256` as the `algorithm`, and explicitly upload the public key
in the `rsa_public_key` field (including for ES256 signed tokens). For example, `rsa_public_key=@/path/to/public_key.pem`.

When creating the signature, make sure that the header is:

```json
{
    "typ": "JWT",
    "alg": "RS256"
}
```

Secondly, the claims **must** contain the secret's `key` field (this **isn't** your private key used to generate
the token, but just an identifier for this credential) in the configured claim (from [`config.key_claim_name`](/plugins/jwt/reference/#schema--config-key-claim-name)).
That claim is `iss` (issuer field) by default. Set its value to our previously created credential's `key`.
The claims may contain other values. The claim is searched in both the JWT payload and header,
in that order.

```json
{
    "iss": "a36c3049b36249a3c9f8891cb127243c"
}
```

Then, create the signature using your private keys. Using the JWT debugger at
[jwt.io](https://jwt.io), set the right header (RS256), the claims (`iss`, etc.), and the
associated public key. Then, append the resulting value in the `Authorization` header, for example:

```bash
curl http://localhost:8000/{routePath} \
  -H 'Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIxM2Q1ODE0NTcyZTc0YTIyYjFhOWEwMDJmMmQxN2MzNyJ9.uNPTnDZXVShFYUSiii78Q-IAfhnc2ExjarZr_WVhGrHHBLweOBJxGJlAKZQEKE4rVd7D6hCtWSkvAAOu7BU34OnlxtQqB8ArGX58xhpIqHtFUkj882JQ9QD6_v2S2Ad-EmEx5402ge71VWEJ0-jyH2WvfxZ_pD90n5AG5rAbYNAIlm2Ew78q4w4GVSivpletUhcv31-U3GROsa7dl8rYMqx6gyo9oIIDcGoMh3bu8su5kQc5SQBFp1CcA5H8sHGfYs-Et5rCU2A6yKbyXtpHrd1Y9oMrZpEfQdgpLae0AfWRf6JutA9SPhst9-5rn4o3cdUmto_TBGqHsFmVyob8VQ'
```

## Upstream headers
{% include_cached /plugins/upstream-headers.md %}
