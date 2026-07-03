---
title: "{{site.base_gateway}} FAQs"
content_type: reference
description: "Answers to common questions about {{site.base_gateway}} plugins, workspaces, custom plugin caching, and DNS resolver configuration."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Gateway plugin entity reference
    url: /gateway/entities/plugin/
  - text: Gateway Vault entity reference
    url: /gateway/entities/vault/
  - text: DNS resolver configuration options
    url: /gateway/configuration/#dns-resolver-section
---

## Plugins

### Can a global plugin be applied to all workspaces?

A plugin that isn't associated with any Service, Route, or Consumer is considered global and runs on every request, but only within its own Workspace. There is no way to set up a plugin that automatically applies to all Workspaces.

### How do I retrieve a secret with {{site.base_gateway}} secret management in the Request Transformer Advanced plugin?

You can fetch a token from a [{{site.base_gateway}} Vault](/gateway/entities/vault/) and pass it to the upstream service in the `Authorization` header as `Bearer <token>`:

1. Enable `KONG_UNTRUSTED_LUA="on"` in your {{site.base_gateway}} configuration.
2. Add the following under the plugin's `config.add_headers`:

   ```lua
   Authorization:$((function() local value, err =
           kong.vault.get("{vault://env/kong-token}") if value then return "Bearer "
           .. value end end)())
   ```

Make sure you have made the required changes to the Vault reference. This configuration dynamically retrieves the token from a {{site.base_gateway}} Vault and appends it to the `Authorization` header as a Bearer token.

### What are the `hit_level` definitions for caching in custom plugins?

When you implement caching in a custom plugin, `hit_level` indicates which cache level a value was fetched from. The cache level hierarchy is:

- **L1**: Least-Recently-Used Lua VM cache using `lua-resty-lrucache`. Provides the fastest lookup if populated, and uses LRU eviction to avoid exhausting the workers' Lua VM memory.
- **L2**: `lua_shared_dict` memory zone shared by all workers. This level is only accessed if L1 was a miss, and prevents workers from requesting the L3 cache.
- **L3**: A custom function that is only run by a single worker to avoid the dog-pile effect on your database or backend (via `lua-resty-lock`). Values fetched via L3 are set to the L2 cache for other workers to retrieve.

This is also defined in the [`lua-resty-mlcache` repo](https://github.com/thibaultcha/lua-resty-mlcache) on GitHub.

## Networking

### What options can be configured with the {{site.base_gateway}} DNS resolver?

You can use the `RES_OPTIONS` environment variable to override the following DNS resolver options:

```
rotate
ndots
timeout
attempts
```
{:.no-copy-code}

For additional details on these settings, refer to the [`resolv.conf` documentation](https://man7.org/linux/man-pages/man5/resolv.conf.5.html). See also the [DNS resolver configuration](/gateway/configuration/#dns-resolver-section).
