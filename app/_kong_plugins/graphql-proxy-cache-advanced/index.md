---
title: 'GraphQL Proxy Caching Advanced'
name: 'GraphQL Proxy Caching Advanced'

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
icon: graphql-proxy-cache-advanced.png

categories:
  - traffic-control

search_aliases:
  - proxy cache
  - graphql proxy cache
  - graphql proxy cache advanced
  - graphql-proxy-cache-advanced

tags:
  - graphql
  - traffic-control

related_resources:
  - text: GraphQL endpoints in the Kong Admin API # @todo make sure these endpoints get generated
    url: /api/gateway/admin-ee/
  - text: GraphQL Rate Limiting Advanced plugin
    url: /plugins/graphql-rate-limiting-advanced/
  - text: DeGraphQL plugin
    url: /plugins/degraphql/
---

The GrapQL Proxy Cache Advanced plugin provides a reverse GraphQL proxy cache implementation for {{site.base_gateway}}. 
It caches response entities by GraphQL query or Vary headers.

## How it works

The GraphQL Proxy Caching Advanced plugin stores cache data in one of two ways, defined via the [`config.strategy`](/plugins/graphql-proxy-cache-advanced/reference/#schema--config-strategy) parameter:

* `redis`: A Redis database.
* `memory`: A shared dictionary defined in [`config.memory.dictionary_name`](/plugins/graphql-proxy-cache-advanced/reference/#schema--config-memory-dictionary-name).

  The default dictionary, `kong_db_cache`, is also used by other plugins and elements of {{site.base_gateway}} to store unrelated database cache entities.
  Using this dictionary is an easy way to bootstrap and test the plugin, but we don't recommend using it for large-scale installations as significant usage will put pressure on other facets of {{site.base_gateway}}'s database caching operations. 
  In production, we recommend defining a custom `lua_shared_dict` via a custom Nginx template.

Cache entities are stored for a [configurable period of time](/plugins/graphql-proxy-cache-advanced/reference/#schema--config-cache-ttl), after which subsequent requests to the same resource will fetch and store the resource again. 

In traditional mode, cache entities can also be [forcefully purged via the Admin API](#managing-cache-entities) prior to their expiration time.

### Cache key

{{site.base_gateway}} assigns a key to each cache element based on the GraphQL query sent in the HTTP request body.
It returns the cache key associated with a given request in the `X-Cache-Key` response header.

Internally, cache keys are represented as a hexadecimal-encoded MD5 sum of the concatenation of the constituent parts:

```
key = md5(UUID | headers | body)
```

`headers` contains the headers defined in [`config.vary_headers`](/plugins/graphql-proxy-cache-advanced/reference/#schema--config-vary-headers), which defaults to `none`.

### Cache status

{% include_cached /plugins/caching/cache-header.md %}

## Managing cache entities

{% include_cached /plugins/caching/api.md name=page.name slug=page.slug %}