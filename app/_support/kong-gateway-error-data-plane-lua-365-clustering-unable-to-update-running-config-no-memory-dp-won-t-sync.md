---
title: "Kong Gateway: Error: \"data_plane.lua:365: [clustering] unable to update running config: no memory\" DP won't sync"
content_type: support
description: "When the dataplane fails to sync it will throw a message of \"unable to update running config: xyz\"."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why does Kong Gateway show \"unable to update running config: no memory\" when the data plane won't sync?"
  a: |
    This means there's no memory left for the `db_cache`, not system memory. Check the `/status` endpoint for the `kong_core_db_cache` values, then increase `mem_cache_size` to accommodate your config's growth.
related_resources:
  - text: "`mem_cache_size` configuration reference"
    url: /gateway/configuration/#mem-cache-size
---

## Problem

We are running into an issue where we are receiving 404s on our routes and our config.cache.json isn't being generated.

Our logs are displaying the following error:

```

data_plane.lua:365: [clustering] unable to update running config: no memory
```

However our system memory looks to be alright and nothing is maxing out. What can be done to resolve this error?

## Solution

When the dataplane fails to sync it will throw a message of "unable to update running config: `xyz`". In this case, the problem is that there is no memory left for the `db_cache`.

To validate this we can call the `/status` endpoint and verify the `db_cache` values.

In this scenario we would see something like this:

```json

"kong_core_db_cache": {
"allocated_slabs": "128.00 MiB",
"capacity": "128.00 MiB"
},
```

To resolve this, we can increase our `mem_cache_size` value.

This value will need to be increased based on your config growth and should be self monitored.
