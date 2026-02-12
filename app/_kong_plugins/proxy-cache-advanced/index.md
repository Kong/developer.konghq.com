---
title: 'Proxy Caching Advanced'
name: 'Proxy Caching Advanced'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Cache and serve commonly requested responses in Kong, in-memory or using Redis'


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
icon: proxy-cache-advanced.png

categories:
  - traffic-control

search_aliases:
  - proxy cache
  - proxy cache advanced
  - proxy-cache-advanced

tags:
  - traffic-control
  - caching

related_resources:
  - text: Proxy Cache plugin
    url: /plugins/proxy-cache/
  - text: GraphQL Proxy Cache Advanced plugin
    url: /plugin/graphql-proxy-cache-advanced/

faqs:
  - q: Does the Proxy Cache Advanced plugin update the cache value if the request body changes?
    a: |
      No, the plugin does not update the cache if _only_ the request body changes.
      See the [cache key](#cache-key) section for details on what the plugin uses to calculate the cache key.

      If you need to cache requests based on the request body, you can use the serverless [Pre-Function plugin](/plugins/pre-function/).
      Create a header with the MD5 hash of the body, then add this header to the [`config.vary_headers`](./reference/#schema--config-vary-headers) parameter.
  - q: Can I hide the `X-Cache-Key` header in the response when using the Proxy Cache Advanced plugin? 
    a: |
      You can remove the `X-Cache-Key` header from the response by applying a serverless [Post-Function plugin](/plugins/post-function/) in the `header_filter` phase.

notes: |
  In Serverless gateways only the <code>memory</code> config strategy is supported.

min_version:
  gateway: '1.0'
---

The Proxy Cache Advanced plugin provides a reverse proxy cache implementation for {{site.base_gateway}}. 
It caches response entities based on a configurable response code, content type, and request method.

This plugin extends the [Proxy Cache plugin](/plugins/proxy-cache/) with Redis, Redis Cluster, and Redis Sentinel support.

## How it works

{% include_cached /plugins/caching/strategies.md name=page.name %}

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

{% include plugins/redis-cloud-auth.md %}