---
title: "Kong Gateway OIDC plugin logs \"unknown error (not a table) was expected\" when the token's `iss` claim doesn't match the configured issuer"
content_type: support
description: This error is caused by a mismatch between the token's `iss` claim and the OIDC plugin's configured issuer, not by a truncated or modified access token.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does the OIDC plugin log `"unknown error (not a table) was expected"` when validating an access token?
  a: |
    This message is a fallback string produced when the token's `iss` claim doesn't match the plugin's configured `issuer` (or `config.issuers_allowed`). It's normally an issuer configuration mismatch rather than a truncated or modified token — compare the token's `iss` claim against your plugin's issuer configuration to resolve it.
---

## Problem

We are using the OIDC plugin with JWTs. When attempting to utilize an Access token - We are running into the following error:

```

2023/10/02 14:46:35 [notice] 1381056#0: *1726 [lua] responses.lua:24: [openid-connect] invalid issuer (https://localhost/test) was specified for access token, unknown error (not a table) was expected, client: 123.12.13.21, server: kong, request: "GET /testing HTTP/1.1", host: "localhost"
```

How can we resolve this issue?

## Cause

This message is produced by the openid-connect plugin's issuer-validation code (`kong/openid-connect/token.lua`) when the token's `iss` claim doesn't match the plugin's configured issuer (or any of `config.issuers_allowed`). The `"unknown error (not a table)"` fragment is a fallback string that gets substituted in place of the expected-issuer list when that value can't be formatted as a list of URLs; in Kong Gateway 3.14.0.0 the code building that part of the message is guarded (`if issuers and type(issuers) == "table" and next(issuers) then ...`) so this specific fallback text should no longer be reachable for a normal issuer mismatch. If you do see it, treat it as a cosmetic detail of the message rather than a signal about what actually went wrong — the real problem is still the issuer mismatch itself.

The most common cause of an `iss` mismatch is a plugin/issuer configuration problem — for example `config.issuer` pointing at a different environment or tenant than the one that actually issued the token — rather than a corrupted/truncated token. A modified or truncated JWT will usually fail signature verification or JSON parsing first, before issuer validation is ever reached, so it's worth broadening the troubleshooting beyond "check for a truncated token."

## Solution

1. Decode the token (for example via a JWT decoding utility such as jwt.io) and compare its `iss` claim against the plugin's configured `issuer` and `issuers_allowed`.
2. Confirm the entirety of the token is being sent/consumed by the client — a truncated token can still trigger this specific message if what remains happens to parse as valid JSON with an unexpected `iss`, but the confirmed direct cause of this message is a mismatched issuer value, not truncation by itself.
