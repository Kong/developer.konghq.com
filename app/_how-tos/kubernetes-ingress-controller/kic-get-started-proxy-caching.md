---
title: Proxy Caching
description: |
  Cache all GET and HEAD responses across all Services using Proxy Cache and the KongClusterPlugin resource
content_type: how_to

permalink: /kubernetes-ingress-controller/get-started/proxy-caching/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Get Started

series:
  id: kic-get-started
  position: 4

tldr:
  q: How do I cache upstream responses using {{ site.kic_product_name }}?
  a: |
    Use the `proxy-cache` plugin by creating a `KongPlugin` resource while specifying `config.response_code`, `config.request_method` and `config.cache_ttl`.

products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect

prereqs:
  skip_product: true

tags:
  - caching
---

## About the Proxy Cache plugin

One of the ways {{site.base_gateway}} delivers performance is through caching. The [Proxy Cache plugin](/plugins/proxy-cache/) accelerates performance by caching responses based on configurable response codes, content types, and request methods. When caching is enabled, upstream services are not impacted by repetitive requests, because {{site.base_gateway}} responds on their behalf with cached results. Caching can be enabled on specific Routes or for all requests globally.

## Proxy Cache headers
The `proxy-cache` plugin returns a `X-Cache-Status` header that can contain the following cache results:

{% include_cached /plugins/caching/cache-header.md %}

## Create a proxy-cache KongClusterPlugin

In the previous section you created a `KongPlugin` that was applied to a specific service or route. You can also use a `KongClusterPlugin` which is a global plugin that applies to all services.

This configuration caches all `HTTP 200` responses to `GET` and `HEAD` requests for 300 seconds:

{% entity_example %}
type: plugin
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
    - text/plain; charset=utf-8
    cache_ttl: 300
    strategy: memory
{% endentity_example %}

## Test the proxy-cache plugin

To test the proxy-cache plugin, send another six requests to `$PROXY_IP/echo`:

{% validation rate-limit-check %}
iterations: 6
url: '/echo'
headers:
  - 'apikey:example-key'
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
grep: "(Status|< HTTP)"
message: null
output:
  explanation: |
    The first request results in `X-Cache-Status: Miss`. This means that the request is sent to the upstream service. The next four responses return `X-Cache-Status: Hit` which indicates that the request was served from a cache. If you receive a `HTTP 429` from the first request, wait 60 seconds for the rate limit timer to reset.
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

The final thing to note is that when a `HTTP 429` request is returned by the rate-limit plugin, you don't see a `X-Cache-Status` header. This is because `rate-limiting` executes before `proxy-cache`. For more information, see [plugin priority](/gateway/entities/plugin/#plugin-priority).
