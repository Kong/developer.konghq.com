---
title: We seem to have a memory leak on our kong nodes after adding a large number of regex routes
content_type: support
description: Configuring more regex routes than the default `nginx_http_lua_regex_cache_max_entries` (8192) causes Lua regex cache thrashing and rising memory usage on Kong nodes.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does memory usage increase on Kong nodes after adding a large number of regex routes?
  a: |
    Kong's Lua regex cache thrashes once you have more regex routes than the default `nginx_http_lua_regex_cache_max_entries` (8192) — each non-matching request forces the entire cache to rebuild, and Lua's garbage collector under-accounts for the large compiled regex memory behind each small cdata handle.

    Set `KONG_NGINX_HTTP_LUA_REGEX_CACHE_MAX_ENTRIES` to at least the number of regex routes you have configured (or higher, to leave headroom) to stop the thrashing.
related_resources: []
---

## Problem

After adding a large number of regex routes (more than 8192), we are seeing memory usage on our Kong nodes increase. In particular, this seems to happen when we send requests that return a 404 "no Route matched with those values" response from kong.How can we stop the memory increase?

## Cause

In OpenResty, the Lua regex cache is usually used to help with performance of the regex matching so that subsequent matches of the same regex need not be recompiled. When you have a large amount of regex routes, specifically more than the default `nginx_http_lua_regex_cache_max_entries` which is 8192, this will cause regex cache thrashing, which means that each request that does not match an existing regex requires the entire regex cache to be rebuilt. Each regex is compiled by C code and Lua code gets a cdata handle to the compiled object. That cdata handle is essentially a C pointer value which for Lua Garbage Collection (GC) is very small in size even though the actual memory allocated for JIT compiled regexes is much larger. This results in the Lua GC not reclaiming the memory, and thus the high memory utilization.

## Solution

To prevent this memory utilization increase, make sure you set the `KONG_NGINX_HTTP_LUA_REGEX_CACHE_MAX_ENTRIES` variable to a value at least as high as the number of regex routes you have configured. You can use the total number of routes that you have in your system. If you think you will add a larger number of routes, you can set this value higher, such as double the current number of routes. Only actually existing regex routes will get cached, so a higher value will lead to higher memory usage.
