---
title: The Retry-After header is not sent when a rate limit is hit
content_type: support
published: false
description: The `rate-limiting-advanced` plugin sends a `Retry-After` header, along with `RateLimit-*` headers, when a rate limit is hit.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: 'Does Kong send a `Retry-After` header when a client hits a rate limit?'
  a: |
    Yes — with the `rate-limiting-advanced` plugin, Kong's `429 Too Many Requests` response includes a `Retry-After` header, the classic per-period `x-ratelimit-*` headers, and the newer `RateLimit-*` headers, all together.
---

## The Retry-After header is not sent when a rate limit is hit

When using the rate-limiting-advanced plugin and a client hits the configured rate limit, Kong returns a `429 Too Many Requests` response that includes a `Retry-After` header indicating when the client can send requests again. The classic per-period `x-ratelimit-limit-minute`/`x-ratelimit-remaining-minute` headers are also present, and Kong sends Title-Case `RateLimit-*` headers (`RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset`) alongside `Retry-After`, plus its own `X-Kong-Request-Id`:

```bash
curl -v http://proxy.kong.lan/httpbin/anything
*   Trying 192.168.1.196:80...
* Connected to proxy.kong.lan (192.168.1.196) port 80 (#0)
> GET /httpbin/anything HTTP/1.1
> Host: proxy.kong.lan
> User-Agent: curl/7.74.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 429 Too Many Requests
< Date: Thu, 27 Aug 2026 07:12:13 GMT
< Content-Type: application/json; charset=utf-8
< Connection: keep-alive
< RateLimit-Remaining: 0
< X-RateLimit-Limit-minute: 5
< X-RateLimit-Remaining-minute: 0
< Retry-After: 31
< RateLimit-Limit: 5
< RateLimit-Reset: 31
< Content-Length: 37
< X-Kong-Response-Latency: 1
< Server: kong/3.14.0.0-enterprise-edition
< X-Kong-Request-Id: 1db8a37b8bea7a716112277aead4ce72
<
* Connection #0 to host proxy.kong.lan left intact
{"message":"API rate limit exceeded"}
```
