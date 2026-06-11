---
title: "Kong Gateway: hit_level definitions for caching in custom plugins"
content_type: support
description: The hit_level value indicates which cache level (L1, L2, or L3) a value was fetched from when implementing caching in a custom plugin.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Kong Gateway: What are the hit_level definitions for caching in custom plugins?"
related_resources: []
---

## hit_level definitions for caching in custom plugins

When writing a custom plugin and implementing caching as part of it, the `hit_level` applies to which level the value was fetched from. The cache level hierarchy is:

- L1: Least-Recently-Used Lua VM cache using `lua-resty-lrucache`. Provides the fastest lookup if populated, and uses LRU eviction to avoid exhausting the workers' Lua VM memory.
- L2: `lua_shared_dict` memory zone shared by all workers. This level is only accessed if L1 was a miss, and prevents workers from requesting the L3 cache.
- L3: a custom function that will only be run by a single worker to avoid the dog-pile effect on your database/backend (via `lua-resty-lock`). Values fetched via L3 will be set to the L2 cache for other workers to retrieve.

This is also defined in the `lua-resty-mlcache` repo in GitHub.
