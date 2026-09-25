---
title: "\"Unauthorized\" error when using Open ID Connect Authentication Plugin"
content_type: support
description: "A large OIDC session cookie returned by the identity provider can exceed the browser's 4096-byte cookie limit and get silently rejected, causing an \"Unauthorized\" error after login."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Kong Manager or Kong Portal show an "Unauthorized" error after a successful Open ID Connect login?
  a: |
    The identity provider's session cookie can exceed the browser's 4096-byte cookie size limit and get silently dropped, so the session is never established even though the IDP login succeeded.

    On Kong Gateway 3.14.0.0, session data is compressed automatically by the bundled `lua-resty-session` library, so the older `session_compressor` field is a deprecated no-op. If the cookie is still too large, set `config.session_storage` to `redis` or `memcached` instead of the default `cookie`, so only a small session ID is stored in the browser and the actual session data lives server-side.
---

## Problem

When integrating the Open ID Connect Authentication Plugin for Kong Manager or Kong Portal, the user is authenticated correctly in the external IDP (eg. Azure AD) but the session cookie is not correctly set in the browser. After the external IDP redirects to Kong Manager or Kong Portal, you see an "Unauthorized" error on the UI because the session cookie isn't set correctly.

## Cause

When looking into the HAR file, you find there is an `authorization` cookie that expired, but not the cookie you defined in the session configuration:

`set-cookie authorization=; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Max-Age=0; Path=/; Secure`

This issue can be caused because some IDPs like Azure AD return a session cookie larger than 4096 bytes. You can check it in the `Content-Length` header, eg: `Content-Length: 5362`. If this is the case, some web browsers like Google Chrome will reject the cookie as it can store a maximum cookie size of 4096 bytes.

## Solution

**On Kong Gateway 3.14.0.0, the `session_compressor` field described below no longer exists** — it's a deprecated, fully no-op field (confirmed by creating an `openid-connect` plugin with `config.session_compressor` set: the plugin is created successfully but the field is silently dropped and never appears in the echoed configuration). This is because compression is now automatic and unconditional: the bundled session library (`lua-resty-session` 4.1.5) deflates session data by default once it exceeds a 1 KB threshold, with no plugin configuration needed. If you're on Kong Gateway 3.14.0.0 (or another current version) and still hitting an oversized cookie despite this automatic compression — for example, because the IDP's claims are large enough that even compressed data exceeds 4096 bytes — the fix is to move session data out of the cookie entirely by setting `config.session_storage` to `redis` or `memcached` instead of the default `cookie`. With non-cookie storage, only a small session ID is stored in the browser cookie, and the actual session data (compressed or not) lives server-side.

If you're on an older Kong Gateway version where `session_compressor` was still a working field, adding it to the OIDC Authentication Plugin configuration remains the applicable fix for that version:

```json

{
   "session_compressor": "zlib",
   "leeway": 1000,
   "logout_redirect_uri": [
       "https://kongportal.yourompany.com/"
    ],
    "scopes": [
        "openid",
        "profile",
        "email",
        "offline_access"
    ],
    "login_action": "redirect",
    "verify_parameters": false,
    "consumer_claim": [
        "email"
    ],
    ...
}
```

Note also that `consumer_claim` (singular, shown above) is a deprecated shorthand for `consumer_claims` (plural) — on Kong Gateway 3.14.0.0 it still works via an automatic mapping, but the value's shape changes: `consumer_claim: ["email"]` is normalized internally to `consumer_claims: [["email"]]` (an array of arrays). New configurations should use `consumer_claims` directly in that shape.
