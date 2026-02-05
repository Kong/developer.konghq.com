---
title: Enable Proxy Caching
description: Use the `KongPlugin` CRD to configure proxy caching for a route or service.
content_type: how_to
permalink: /operator/get-started/konnect-crds/proxy-caching/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: operator-get-started-konnect-crds
  position: 5 

tldr:
  q: How do I enable response caching with {{site.konnect_short_name}} CRDs?
  a: |
    Apply the `proxy-cache` plugin using the `KongPlugin` CRD.

products:
  - operator

tools:
  - operator

works_on:
  - konnect

tags:
  - caching

---

## Set up the `proxy-cache` plugin

Use the `KongPlugin` CRD to enable proxy caching on a `KongService`. The following example:

* Caches `200 OK` responses
* Applies to `GET` and `HEAD` requests
* Targets responses with `application/json` content type
* Stores cached data in memory
* Sets the cache TTL to 300 seconds (5 minutes)

{% entity_example %}
type: plugin
cluster_plugin: false
data:
  name: proxy-cache-all-endpoints
  plugin: proxy-cache
  config:
    response_code:
    - 200
    request_method:
    - GET
    - HEAD
    content_type:
    - application/json
    cache_ttl: 300
    strategy: memory

  kongservice: service
  other_plugins: rate-limiting
{% endentity_example %}

## Validation

Send six requests to the same endpoint and inspect the cache status. The first request will miss, but subsequent ones will hit because they are served from the cache.

{% validation rate-limit-check %}
iterations: 6
url: '/anything'
headers:
  - 'apikey:example-key'
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
grep: "(Status|< HTTP)"
message: null
output:
  explanation: |
    The first request results in `X-Cache-Status: Miss`. This means that the request is sent to the upstream service. The next four responses return `X-Cache-Status: Hit` which indicates that the request was served from a cache. If you receive an `HTTP 429` from the first request, wait 60 seconds for the rate limit timer to reset.
  expected:
    - value:
      - "< HTTP/1.1 200 OK"
      - "< X-Cache-Status: Miss"
    - value:
      - "< HTTP/1.1 200 OK"
      - "< X-Cache-Status: Hit"
    - value:
      - "< HTTP/1.1 200 OK"
      - "< X-Cache-Status: Hit"
    - value:
      - "< HTTP/1.1 200 OK"
      - "< X-Cache-Status: Hit"
    - value:
      - "< HTTP/1.1 200 OK"
      - "< X-Cache-Status: Hit"
    - value:
      - "< HTTP/1.1 429 Too Many Requests"
{% endvalidation %}