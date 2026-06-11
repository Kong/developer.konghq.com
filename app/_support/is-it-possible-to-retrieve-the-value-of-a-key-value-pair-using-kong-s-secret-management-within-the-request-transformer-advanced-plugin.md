---
title: "Retrieving a secret value with Kong Secret Management in the Request Transformer Advanced plugin"
content_type: support
description: Use the Request Transformer Advanced plugin to fetch a token from Kong's Secret Management and pass it to the upstream in the Authorization header as a Bearer token.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Is it possible to retrieve the value of a key-value pair using Kong's Secret Management within the Request Transformer Advanced plugin?"
  a: |
    Yes. Enable `KONG_UNTRUSTED_LUA="on"` in your Kong configuration, then add a header under the
    Request Transformer Advanced plugin's `config.add_headers` that uses `kong.vault.get` to fetch the
    secret. For example, `Authorization:$((function() local value, err = kong.vault.get("{vault://env/kong-token}")
    if value then return "Bearer " .. value end end)())` dynamically retrieves the token and passes it
    upstream in the `Authorization` header as a Bearer token.
related_resources: []
---

## Problem

You want to retrieve the value of a key-value pair from Kong's Secret Management within the Request Transformer Advanced plugin — specifically, fetch a token from Kong's Secret Management and pass it to the upstream service in the `Authorization` header as `Bearer <token>`.

## Solution

You can achieve this using the Request Transformer Advanced plugin with the following configuration for adding a header.

1. Make sure you enable `KONG_UNTRUSTED_LUA="on"` in your Kong configuration.
2. Add the following under `config.add_headers`:

   ```lua
   Authorization:$((function() local value, err =
           kong.vault.get("{vault://env/kong-token}") if value then return "Bearer "
           .. value end end)())
   ```

Note: Make sure you have made the required changes to the vault reference

This configuration dynamically retrieves a token from Kong's Secret Management (Vault) and appends it to the `Authorization` header as a Bearer token.
