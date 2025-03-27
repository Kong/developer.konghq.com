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
  - caching
  - traffic-control

related_resources:
  - text: GraphQL Rate Limiting Advanced plugin
    url: /plugins/graphql-rate-limiting-advanced/
  - text: DeGraphQL plugin
    url: /plugins/degraphql/
---

The GrapQL Proxy Cache Advanced plugin provides a reverse GraphQL proxy cache implementation for {{site.base_gateway}}. 
It caches response entities by GraphQL query or Vary headers.

## How it works

{% include_cached /plugins/caching/strategies.md name=page.name %}

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