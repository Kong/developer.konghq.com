---
title: Expected behavior for the Rate Limiting plugin with a path identifier
content_type: support
description: Explains how the Rate Limiting plugin's `path` identifier keeps a separate counter for the configured path and a shared counter for all other paths, with an example walkthrough.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: What is the expected behaviour for the Rate Limiting plugin with path identifier?
  a: |
    With `config.identifier=path`, the Rate Limiting plugin keeps a separate counter for the exact path configured on the plugin, and a second, shared counter for every other path on the same service or route. Requests to the configured path only consume that path's limit; requests to any other path share the other counter, so total throughput across all paths can exceed the configured limit.
related_resources: []
---

## What is the expected behavior for the Rate Limiting plugin with a path identifier

When configuring the Rate Limiting or Rate Limiting Advanced plugin with a path identifier, what is the expected behavior?

When configuring the Rate Limiting plugin (or Rate Limiting Advanced) with `config.identifier=path` it means the plugin will have a counter for the path configured and another counter for the paths that don't match the configured path. For example:

- Configure a service to `httpbin.org/anything`

- Configure 3 routes for that service: `/http1` `/http2` `/http3`

- Configure the Rate Limiting plugin at the service level and set: `identifier=path, strategy=local, path=/http1, window_size=[ 60 ], limit=[ 3 ], window_type=fixed`

We are configuring 3 requests per minute. This means the plugin will have a counter for the path `/http1` and a counter for the other paths (also using fixed window for an easier understanding). Let's see an example:

- We are going to send 6 requests within the same window. We can confirm we are in the same window with the header `ratelimit-reset` (from `ratelimit-reset:52` to `ratelimit-reset:37`)

- We are going to send 4 requests to `/http1`. The first 3 will respond with a 200 OK and the forth 429 Too Many Requests (note `ratelimit-remaining:0`)

- We are going to send 2 requests more, to `/http2` and `/http3`. We still are in the same window (`ratelimit-reset:40`). We see now both requests respond with a 200 OK as they use another counter. Also, you can see they use the same counter, for `/http2` `ratelimit-remaining:2` and for `/http3` `ratelimit-remaining:1`

```bash

curl -I http://proxy.kong/http1
HTTP/1.1 200 OK
x-ratelimit-limit-minute: 3
x-ratelimit-remaining-minute: 2
ratelimit-limit: 3
ratelimit-remaining: 2
ratelimit-reset: 52

curl -I http://proxy.kong/http1
HTTP/1.1 200 OK
x-ratelimit-limit-minute: 3
x-ratelimit-remaining-minute: 1
ratelimit-limit: 3
ratelimit-remaining: 1
ratelimit-reset: 48

curl -I http://proxy.kong/http1
HTTP/1.1 200 OK
x-ratelimit-limit-minute: 3
x-ratelimit-remaining-minute: 0
ratelimit-limit: 3
ratelimit-remaining: 0
ratelimit-reset: 47

curl -I http://proxy.kong/http1
HTTP/1.1 429 Too Many Requests
x-ratelimit-limit-minute: 3
x-ratelimit-remaining-minute: 0
ratelimit-limit: 3
ratelimit-remaining: 0
ratelimit-reset: 44
retry-after: 44

curl -I http://proxy.kong/http2
HTTP/1.1 200 OK
x-ratelimit-limit-minute: 3
x-ratelimit-remaining-minute: 2
ratelimit-limit: 3
ratelimit-remaining: 2
ratelimit-reset: 40

curl -I http://proxy.kong/http3
HTTP/1.1 200 OK
x-ratelimit-limit-minute: 3
x-ratelimit-remaining-minute: 1
ratelimit-limit: 3
ratelimit-remaining: 1
ratelimit-reset: 37
```

Note if we don't configure any path, the plugin will only accept 3 requests per minute. In this case, it accepts 6 requests per minute:

- 3 for `/http1`

- 3 for either `/http2` or `/http3` (or any other path configured)
