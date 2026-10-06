---
title: How the `proxy-cache-advanced` plugin calculates the cache key
content_type: support
description: The `x-cache-key` response header (a SHA-256 hash of the route/consumer, method, URI, and any varied query params or headers) is the reliable source of truth for how the `proxy-cache-advanced` plugin calculates its cache key.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How does the `proxy-cache-advanced` plugin calculate the cache key?
  a: |
    The cache key is a SHA-256 hash of the route/consumer prefix, method, URI, and (if configured) `config.vary_query_params`/`config.vary_headers`, exposed as the `x-cache-key` response header. The exact internal encoding isn't officially documented, so treat the `X-Cache-Key` response header as the source of truth rather than hand-reconstructing it.
related_resources:
  - text: the plugin documentation
    url: /plugins/proxy-cache-advanced/
---

## Problem

The "Proxy Cache Advanced" plugin calculates a cache key that can be used to identify responses that are cached and the key can be used to view/delete the cache content. It's not always clear exactly how that cache key is calculated.

## Solution

The plugin documentation shows a high level overview of how the cache key is created.

At a high level, the cache key is calculated from these components;

```
hash(prefix_digest|method|uri|params_digest|headers_digest)
```

where `prefix_digest` identifies the Route (or the Consumer, for an authenticated request), and `params_digest`/`headers_digest` are only populated when `config.vary_query_params`/`config.vary_headers` are configured.

`proxy-cache-advanced` uses **SHA-256** to compute the cache key, producing a 64-character hex `x-cache-key` header value — reproduced below. The exact internal ordering/encoding of the digest components is an internal implementation detail that isn't officially documented at the byte level and may change without notice, so a manually hand-built reconstruction (e.g. via `echo ... | sha256sum`) is unlikely to match the actual output. The reliable way to obtain the cache key is to read the `X-Cache-Key` response header directly (or query it via the plugin's own Admin API), not to hand-reconstruct it.

For example, using a simple request as below;

```bash
curl -sv -H "kong-debug: 1" http://proxy.kong.lan/httpbin/anything
*   Trying 192.168.1.196:8000...
* Connected to proxy.kong.lan (192.168.1.196) port 8000 (#0)
> GET /httpbin/anything HTTP/1.1
> Host: proxy.kong.lan
> User-Agent: curl/8.7.1
> Accept: */*
> kong-debug: 1
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< content-type: application/json
< content-length: 479
< kong-route-id: ddfd3aa1-7f33-410c-af30-7b2d0d628c10
< kong-route-name: local-httpbin
< kong-service-id: c902e93d-236e-463a-9e62-96f545edc603
< kong-service-name: local-httpbin
< x-cache-key: 3cbf803727b0489d32e4bc5a91882e6006289a8849452286c53072a8c0798848
< x-cache-status: Miss
< server: gunicorn/19.9.0
< date: Thu, 27 Aug 2026 07:19:00 GMT
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-kong-upstream-latency: 6
< x-kong-proxy-latency: 2
< via: 1.1 kong/3.14.0.0-enterprise-edition
< x-kong-request-id: 9c9cc9062ad65542c00af6205e22a61d
<
{ [479 bytes data]
* Connection #0 to host proxy.kong.lan left intact
```

Note the 64-character `x-cache-key` above, reflecting the plugin's SHA-256-based hash.

Repeating the same request unchanged returns the identical `x-cache-key` with `x-cache-status: Hit`, confirming the key is stable for a given route/method/URI/vary-config combination. Changing `config.vary_query_params`/`config.vary_headers`, or the value of a varied query parameter/header, changes the key: adding `config.vary_query_params=["query_one"]` and requesting `?query_one=abc` versus `?query_one=xyz` produced two different `x-cache-key` values, each stable/repeatable for its own request shape:

```bash
curl -s http://proxy.kong.lan/httpbin/anything?query_one=abc -D - -o /dev/null | grep -i x-cache-key
x-cache-key: d0d93addf5b85d9a0ed6ebaa8274683954f2d55c2f58d44fa8a8543705cfcd5d

curl -s http://proxy.kong.lan/httpbin/anything?query_one=xyz -D - -o /dev/null | grep -i x-cache-key
x-cache-key: de2339d1176314d7c34477eebfdd0398d390e14c463fbc5c19de6c9659947843
```

Treat the `X-Cache-Key` response header as the source of truth for the cache key rather than hand-computing it.
