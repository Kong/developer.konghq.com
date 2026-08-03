---
title: OpenID Connect plugin continuing to process revoked tokens
content_type: support
description: It is possible to force Kong to recognize the access token is revoked.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "OpenID Connect plugin parameters reference (`config.introspect_jwt_tokens`)"
    url: "/plugins/openid-connect/#parameters"
tldr:
  q: How do I force Kong to recognize that an access token has been revoked with the OpenID Connect plugin?
  a: |
    By default, Kong keeps accepting a cached token until it expires, even after the token is revoked at the OIDC provider. Enable `Introspect JWT Tokens` and disable `Config.Cache Introspection` in the OpenID Connect plugin so Kong introspects the token on every request, at the cost of an extra network call to the OIDC provider per request.
---

## Problem

We generated an access token (JWT) directly from the OIDC endpoint and successfully configured the OpenID Connect plugin to utilize the access tokens inside Kong. However, after using the access token inside Kong and then revoking the token directly from the OpenID Connect endpoint, it continues to process the request successfully until the token is expired. Is there any way to force Kong to recognize the access token is revoked?

## Solution

It is possible to force Kong to recognize the access token is revoked. To do so, you will need to enforce Introspect on JWT and disable Cache Introspection.

Steps to do so inside the OpenID Connect plugin:

1. Disable `Config.Cache Introspection`.
2. Enable `Introspect JWT Tokens` - "Specifies whether to introspect the JWT access tokens (can be used to check for revocations)."

For more information, see the OpenID Connect plugin parameters reference for `config.introspect_jwt_tokens`.

From here you can retest to confirm revocation is working as expected.

NOTE: This will result in additional network calls to the OIDC provider as each request will need to verify the token.
