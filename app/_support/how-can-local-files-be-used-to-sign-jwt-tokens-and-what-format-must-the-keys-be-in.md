---
title: Using local files to sign JWT tokens and the required key format
content_type: support
description: The `jwt-plugin`'s keyset parameters only support loading keys from an http(s) endpoint, so local key files must be served through a custom nginx endpoint instead.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can local files be used to sign JWT tokens and what format must the keys be in?
  a: |
    The `jwt-signer` plugin's `*_keyset` parameters only load keys from an http(s) endpoint, not directly from the local filesystem. To serve local key files, add a custom nginx server block (loaded via `nginx_http_include` in `kong.conf`) that exposes them over `http://127.0.0.1:<port>/...` with a `Content-Type: application/jwk-set+json` header, then point the plugin's keyset parameter at that local endpoint. Keys must be in JWK format; PEM keys need to be converted first.
related_resources:
  - text: "`jwt-signer` plugin: managing key signing"
    url: /plugins/jwt-signer/#manage-key-signing
  - text: The JWK format (RFC 7517)
    url: https://tools.ietf.org/html/rfc7517
  - text: CLI tool lokey
    url: https://github.com/jpf/lokey
  - text: Online JS conversion
    url: https://irrte.ch/jwt-js-decode/pem2jwk.html
  - text: A CLI tool for creating JWK's
    url: https://smallstep.com/docs/cli/crypto/jwk/create/
---

## Overview

When using the `jwt-signer` plugin, how can custom keys be used to sign the tokens? The documentation mentions that the `*_keyset` parameters can be used but there is no detail on how to use this to pass key files from the local filesystem to the plugin, nor the required format for the keys.

## Steps

The `jwt-plugin` does not support loading keys from a local filesystem. The keyset parameters can support an http(s) endpoint to load your own keys, or any other value will cause Kong to auto-generate keys.

It is however possible to set up a custom nginx server block to serve keys from the local filesystem. The keys need to be provided from an endpoint that provides a JWK format key with a content-type of `application/jwk-set+json`. The JWK format is described here.

Assuming that the keys are stored in the local filesystem in the `/opt/key` directory, you can configure a new nginx server block to return the right content-type for files ending in `.key`. Firstly, create a file `/etc/kong/jwk-keys.conf` with contents like this:

```nginx
server {
    listen 127.0.0.1:4444;
    root /opt/keys/;
    location / {
      types {
          application/jwk-set+json  key;
      }
    }
}
```

Next, add the below parameter to the `kong.conf` file to load the `jwk-keys.conf` as an nginx include file:

```bash
nginx_http_include=/etc/kong/jwk-keys.conf
```

Note, after restarting Kong, the jwt keys will be available via the localhost interface, i.e. the keys will not be available publicly.

```bash
curl -v http://127.0.0.1:4444/jwks.key
* About to connect() to 127.0.0.1 port 4444 (#0)
*   Trying 127.0.0.1...
* Connected to 127.0.0.1 (127.0.0.1) port 4444 (#0)
> GET /jwks.key HTTP/1.1
> User-Agent: curl/7.29.0
> Host: 127.0.0.1:4444
> Accept: */*
>
< HTTP/1.1 200 OK
< Date: Thu, 14 May 2026 14:08:03 GMT
< Content-Type: application/jwk-set+json
< Content-Length: 705
< Last-Modified: Thu, 14 May 2026 11:05:31 GMT
< Connection: keep-alive
< ETag: "5ebd25fb-2c1"
< Accept-Ranges: bytes
<
{
      "kid": "74bd86fc61e4c6cb450126ff4e38b069b8f8f35c",
      "e": "AQAB",
      "alg": "RS256",
      "use": "sig",
      "n": "q9WQ8_ucw5sLCKMZpWj1WhZXW1C83G6aE7NST1D3cUNnKIN3RhI04EOtJrbfF5wJwmdMurqwIJuhXBC44pyhBkaxJ0-lyrvgLHVhQhxH6K9b-UV0whE0eqiOOl1snKk-N0BRfT5dmCghr7rxcHUJqSFuDpZo2ZJzMiuF2DmeQHaTtusLnU-7xnP4B4eHG_h4nisK1zx8-l-rBYyaGHRf6ZqelTpRDHDVQMGuunbGqVXRgc1OjwPci6ZDzdSFRGST3gCZFirRfOoXMqF2474TD3KjYPdmwfETiPAfOVCA9I2mVj4IhbELDTVVYdh0DBs3mks1j2TBIUniUiDs5c-_ow",
      "kty": "RSA"
    },
    {
      "e": "AQAB",
      "alg": "RS256",
      "use": "sig",
      "n": "xHKHysGHfZby92stAyC4Xkp7t2Ib6TEha1G11UwGgmrv7pgpjKBJkO1XtvvT2L3pEylhcKhLgO8fx5R-rKceezZ_YpTyuT1vHHsWYJxeocV5m0V70_Nvgfysl6lS_gdvfT68dMNk1EL8bIk9uiCMIotVpcq4FIeID75Dendq_oTuXOZVeCi1r8q0qeMWN7nFZEJCnxzayNOTE7-eC8FRMRiu-e3tOtkruga3Cz62nkkrGtQyAaQtUntrDTQxjE2TNhBvWBWDVOfvG-uCe2JkhfDC7CZlE6tpBo-VkyIGGZjR5qBlYTKx6ZJjWeQC13lpwd7WB1vKtBSKGH2vKuBbrQ",
      "kty": "RSA",
      "kid": "c1771814ba6a70693fb9412da3c6e90c2bf5b927"
    }
```

You can then configure the `jwt-signer` plugin to use the local http address to load the custom keys:

```bash
config.access_token_keyset=http://127.0.0.1:4444/jwks.key
```

To convert a PEM key to JWK format, there are a few 3rd party utilities. For example, see the below links (these are not validated by Kong so please ensure that you perform your own validation as to the suitability of these or any other tools you choose to use for JWK creation).

```bash
step crypto jwk create -kty=RSA -alg=RS256 pub.json priv.json
```
