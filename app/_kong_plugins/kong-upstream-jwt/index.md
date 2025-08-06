---
title: 'Kong Upstream JWT'
name: 'Kong Upstream JWT'

content_type: plugin

publisher: optum
description: "Add a signed JWT into the header of proxied requests"

products:
    - gateway

works_on:
    - on-prem

third_party: true

support_url: https://github.com/Optum/kong-upstream-jwt/issues

source_code_url: https://github.com/Optum/kong-upstream-jwt/

license_type: Apache-2.0

icon: optum.png

search_aliases:
  - optum

min_version:
  gateway: '3.0'
---

The Kong Upstream JWT plugin adds a signed JWT into the HTTP Header `JWT` of requests proxied through {{site.base_gateway}}. 
This provides a means of authentication, authorization, and non-repudiation to upstream services.

## How it works

Upstream services need a means of cryptographically validating that requests they receive were proxied by {{site.base_gateway}} and not tampered with during transmission. 
JWT validation accomplishes both as follows:

1. **Authentication** & **Authorization**: Provided by means of JWT signature validation. 
The JWT token is generated using {{site.base_gateway}}'s RSA x509 private key.
Upstream services will then validate the signature of the generated JWT token using {{site.base_gateway}}'s public key. 
This public key can be maintained in a keystore, or sent with the token, provided that upstream services validate the signature chain against their truststore.

2. **Non-Repudiation**: SHA256 is used to hash the body of the HTTP request body, and the resulting digest is included in the `payloadhash` element of the JWT body. 
Upstream services will take the SHA256 hash of the HTTP request body and compare the digest to that found in the JWT. 
If the digests are identical, they can be certain that the request remained intact during transmission.

## Set public and private keys

The plugin requires {{site.base_gateway}}'s private key is accessible in order to sign the JWT. 
We also include the x509 cert in the `x5c` JWT Header for use by API providers to [validate the JWT](https://tools.ietf.org/html/rfc7515#section-4.1.6). 

We access these via {{site.base_gateway}}'s overriding environment variables `KONG_SSL_CERT_KEY` for the private key as well as `KONG_SSL_CERT_DER` for the public key. 
The first contains the path to your `.key` file, the second specifies the path to your public key in DER format `.cer` file:

```bash
export KONG_SSL_CERT_KEY="/path/to/kong/ssl/privatekey.key"
export KONG_SSL_CERT_DER="/path/to/kong/ssl/kongpublickey.cer"
```

Make the environment variables accessible by a Nginx worker by adding these lines to your `nginx.conf`:

```
env KONG_SSL_CERT_KEY;
env KONG_SSL_CERT_DER;
```

## Install the Kong Upstream JWT plugin

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="kong-upstream-jwt" %}