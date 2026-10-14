---
title: How the Entity Datastore Cache works
content_type: support
description: "Explains how Kong's two-layer (L1/L2) entity datastore cache works, including cache sizing via `mem_cache_size` and LRU eviction."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How does the Entity Datastore Cache work?
  a: |
    The Datastore Cache is two individual caches, `kong_core_db_cache` and `kong_db_cache`, holding the entities (services, routes, plugins, upstreams, certificates, etc.) that Kong needs to be performant. Their combined size is set by `mem_cache_size` (default 128m), and they evict least-recently-used entities (LRU) once full. On a request, a worker checks its per-worker L1 cache first, then the shared L2 cache, then falls back to a database call that populates both caches.
related_resources:
  - text: "`mem_cache_size` configuration property"
    url: /gateway/configuration/#mem_cache_size
  - text: the caches' behavior and capabilities
    url: https://github.com/thibaultcha/lua-resty-mlcache
---

## Problem

How does the Entity Datastore Cache work?

## Solution

What is it?

The Datastore Cache is actually the collective term for 2 individual caches: `kong_core_db_cache` & `kong_db_cache`.

These two caches hold the entities (services, routes, plugins, upstreams, certificates etc) that Kong uses to be so performant.

The size of these 2 caches is set by the `mem_cache_size` configuration property (default 128m; confirmed live via the Admin API root response's `configuration.mem_cache_size` field).

The capacity and allocation (usage) of those two caches can be seen using the `/status` endpoint.

The cache is a LRU cache, so the least recently used entities will be evicted if the cache size is not big enough to hold all entities.

How it works?

When a worker has to process a request, it will first look inside the L1 cache that is dedicated to that worker.

If the entities it needs to process the request cannot be found in the L1 cache, it will then search the L2 cache for the entities to use.

If the L2 cache does not contain those entities, then a database call is made to retrieve the entities, cache them in the L2 cache, then use them.
