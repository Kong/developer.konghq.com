---
title: 'Proxy Cache'
name: 'Proxy Cache'

content_type: plugin

publisher: kong-inc
description: 'Cache and serve commonly requested responses in Kong'

products:
    - gateway

works_on:
    - on-prem
    - konnect


topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: proxy-cache.png

categories:
  - traffic-control

search_aliases:
  - proxy caching
  - proxy-cache

tags:
  - traffic-control
  - caching

related_resources:
  - text: Proxy Cache Advanced plugin
    url: /plugins/proxy-cache-advanced/
  - text: GraphQL Proxy Cache Advanced plugin
    url: /plugin/graphql-proxy-cache-advanced/

min_version:
  gateway: '1.2'
---

The Proxy Cache plugin provides a reverse proxy cache implementation for {{site.base_gateway}}. 
It caches response entities based on a configurable response code, content type, and request method.

The advanced version of this plugin, [Proxy Cache Advanced](/plugins/proxy-cache-advanced/), 
extends the Proxy Cache plugin with Redis, Redis Cluster, and Redis Sentinel support.

## How it works

The Proxy Cache plugin stores cache data in memory, which is a shared dictionary defined in [`config.memory.dictionary_name`](./reference/#schema--config-memory-dictionary-name).

The default dictionary, `kong_db_cache`, is also used by other plugins and functions of {{site.base_gateway}} to store unrelated database cache entities.
Using the `kong_db_cache` dictionary is an easy way to bootstrap and test the plugin, but we don't recommend using it for large-scale installations as significant usage will put pressure on other facets of {{site.base_gateway}}'s database caching operations. 
In production, we recommend defining a custom `lua_shared_dict` via a custom Nginx template.

Cache entities are stored for a [configurable period of time](./reference/#schema--config-cache-ttl), after which subsequent requests to the same resource will fetch and store the resource again. 

In [Traditional mode](/gateway/traditional-mode/), cache entities can also be [forcefully purged via the Admin API](#managing-cache-entities) prior to their expiration time.

### Cache key

{% include_cached /plugins/caching/cache-key.md name=page.name slug=page.slug %}

### Cache control

{% include_cached /plugins/caching/cache-control.md %}

### Cache status

{% include_cached /plugins/caching/cache-header.md %}

## Storage TTL

{% include_cached /plugins/caching/storage-ttl.md %}

## Upstream outages

{% include_cached /plugins/caching/upstream-outages.md %}

## Managing cache entities

{% include_cached /plugins/caching/api.md name=page.name slug=page.slug %}