---
title: How to solve OIDC error unable to verify digest
content_type: support
description: The `unable to RSA SHA256 verify digest` error appears when Kong cannot verify the signature of an access token, typically when using MS Azure AD (directly, or as a federated store behind Okta).
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: OpenID Connect plugin
    url: /plugins/openid-connect/
tldr:
  q: Why do I get an `unable to RSA SHA256 verify digest` error when logging in to Kong Manager with OIDC?
  a: |
    This happens when the access token is signed with a key whose public key Microsoft doesn't publish — common with Azure AD (directly, or as a federated store behind Okta) — so Kong can't verify the signature. Where possible, follow the OpenID Connect with Azure AD instructions to force Azure AD to issue v2.0 tokens. If that isn't possible, set `config.ignore_signature=authorization_code` on the OpenID Connect plugin to skip verification for just that flow, rather than disabling verification entirely with `config.verify_signature=false`.
---

## Problem

A user can't log in to Kong Manager using OIDC authentication, and the Kong error log shows an `unable to RSA SHA256 verify digest` error:

```
2026/02/10 11:44:21 [notice] 24#0: *1328563 [lua] handler.lua:686: [openid-connect] unable to RSA SHA256 verify digest, client: 192.168.50.21, server: kong_admin, request: "GET /auth?code=Q5QUvq-DU58EAnngeSdp&state=9TQNEoa4OJwtbt1rpNXLKnn2 HTTP/1.1", host: "10.73.146.151:8001", referrer: "http://10.73.146.151:8002/?code=Q5QUvq-DU58EAnngeSdp&state=9TQNEoa4OJwtbt1rpNXLKnn2"
```

## Cause

The `unable to RSA SHA256 verify digest` error shows up when Kong is unable to verify the signature of the access token, typically when using MS Azure AD (or Okta with Azure AD as the federated user store).

This is caused when access tokens are issued that are signed with a key that does not have the public key published. MS does not release the public key for Azure AD, thus Kong is not able to verify the tokens.

## Solution

If possible, please follow the OpenID Connect with Azure AD instructions, in particular, force Azure AD to use v2.0 tokens, and include a `YOUR_CLIENT_ID/.default` scope in your plugin configuration.

If changing the configuration isn't possible or does not resolve the error, you can set the `config.verify_signature=false` parameter to disable all verification, which, while it will solve the problem, is not ideal and should only be used in a test or dev environment.

The better solution is to use the `config.ignore_signature` parameter, which will just disable the token verification for that specific flow. For example: `config.ignore_signature=authorization_code`.

For more information about the parameter above, check the OpenID Connect plugin documentation.
