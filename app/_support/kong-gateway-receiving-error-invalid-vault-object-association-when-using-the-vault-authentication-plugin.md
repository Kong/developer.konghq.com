---
title: "Kong Gateway: Receiving error \"invalid Vault object association\" when using the Vault Authentication plugin"
content_type: support
description: "The `vault-auth` plugin logs an `invalid Vault object association` error, and the client receives \"An unexpected error occurred\", when the plugin references a Vault ID that doesn't exist or isn't configured correctly. Confirm the correct ID via the `/vault-auth` Admin API endpoint."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: What causes the "invalid Vault object association" error with the Vault Authentication plugin?
  a: |
    The `vault-auth` plugin logs `invalid Vault object association` (and returns `An unexpected error occurred` to the client) when the plugin configuration references a Vault ID that doesn't exist or is misconfigured. Confirm the correct Vault ID via the `/vault-auth` Admin API endpoint and update the plugin configuration to match.
---

## Problem

When attempting to access a route/service protected by the Vault Authentication plugin you receive the message:

`An unexpected error occurred`

A review of the Kong logs shows:

```

2023/03/24 19:24:00 [error] 2174#0: *1253 [kong] handler.lua:185 [vault-auth] failed to get from node cache: callback threw an error: .../local/share/lua/5.1/kong/plugins/vault-auth/handler.lua:47: invalid Vault object association
stack traceback:
        [C]: in function 'error'
        .../local/share/lua/5.1/kong/plugins/vault-auth/handler.lua:47: in function <.../local/share/lua/5.1/kong/plugins/vault-auth/handler.lua:41>
        [C]: in function 'xpcall'
        /usr/local/share/lua/5.1/resty/mlcache.lua:751: in function 'get'
        /usr/local/share/lua/5.1/kong/cache/init.lua:168: in function 'get'
        .../local/share/lua/5.1/kong/plugins/vault-auth/handler.lua:182: in function 'do_authentication'
        .../local/share/lua/5.1/kong/plugins/vault-auth/handler.lua:236: in function <.../local/share/lua/5.1/kong/plugins/vault-auth/handler.lua:224>, client: 172.28.0.1, server: kong
```

## Solution

This can occur when an invalid Vault is referenced. During the setup of the plugin a valid vault ID must be specified.

The vault ID is obtained from the creation of the Vault object as specified here. If a bad ID or vault configuration is used it will result in this error.

You can confirm the ID by accessing the `/vault-auth` endpoint of the Admin API.

```bash

curl https://localhost:8443/vault-auth

{
  "data": [
    {
      "port": 8200,
      "kv": "v1",
      "protocol": "http",
      "name": "kong-auth",
      "id": "2cfd63c7-81a1-4979-a794-68a21da2b6c4",
      "mount": "kong-auth",
      "created_at": 1679686578,
      "updated_at": 1679686578,
      "vault_token": "kong",
      "host": "localhost"
    }
  ],
  "next": null
}
```
