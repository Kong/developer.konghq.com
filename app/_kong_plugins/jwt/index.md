---
title: JWT plugin

name: JWT
publisher: kong-inc
content_type: plugin
description: Verify and authenticate JSON Web Tokens
tags:
    - authentication

works_on:
    - on-prem
    - konnect
---

The JWT plugin lets you verify requests containing HS256 or RS256 signed JSON Web Tokens, as specified in [RFC 7519](https://tools.ietf.org/html/rfc7519).

When you enable this plugin, it grants JWT credentials (public and secret keys) to each of your consumers, which must be used to sign their JWTs. You can then pass a token through any of the following:

* A query string parameter
* A cookie
* HTTP request headers

Kong will either proxy the request to your upstream services if the token’s signature is verified, or discard the request if not. Kong can also perform verifications on some of the registered claims of RFC 7519 (exp and nbf). If Kong finds multiple tokens that differ - even if they are valid - the request will be rejected to prevent JWT smuggling.
