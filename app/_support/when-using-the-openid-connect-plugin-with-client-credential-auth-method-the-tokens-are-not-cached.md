---
title: When using the `openid-connect` plugin with client credential auth method the tokens are not cached
content_type: support
description: Explains why the `openid-connect` plugin doesn't cache tokens when both `client_credentials` and `password` are enabled in `auth_methods` and credentials are sent via a Basic auth header.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: When using the `openid-connect` plugin with client credential auth method the tokens are not cached
  a: |
    The `openid-connect` plugin's token cache is bypassed when both `client_credentials` and `password` are listed in `auth_methods` and credentials are sent via a Basic auth header — the plugin matches the `password` grant instead, so tokens for `client_credentials` requests never get cached. Enable only the `client_credentials` auth method to fix caching.
related_resources: []
---

## Problem

We are using the `openid-connect` plugin with `client_credentials` authentication, and we have set the `cache_tokens` property of the plugin to `true` but it looks like Kong connects to the IdP with every request, and does NOT use the cache. Also, for each request we see the following type of log entry: `2023/04/13 10:33:49 [notice] 2042#0: *1072500 [lua] cache.lua:990: [openid-connect] loading tokens from the identity provide`

## Cause

The token caching will not work if BOTH `client_credentials` and `password` are specified in the `auth_methods` `openid-connect` property, and if the credentials are sent via an `Authorizartion: Basic` header. This is because both authentication methods could match in that scenario, and the plugin prioritizes the password grant which if only `client_credentials` is allowed leads to the token not getting cached.

## Solution

To resolve this caching issue, please make sure you only have the `client_credentials` method enabled.
