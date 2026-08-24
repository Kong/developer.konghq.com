---
title: "Kong Gateway: Log the upstream/target hostname in a logging plugin"
content_type: support
published: false
description: "`balancer_data` returns the service host, not the upstream target host; use `ngx.var.upstream_host` to log the upstream/target hostname in a logging plugin."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How can I log the upstream/target hostname in a logging plugin?
  a: |
    `ngx.ctx.balancer_data.host` returns the service host configured in Kong, not the resolved upstream target.
    Use `ngx.var.upstream_host` instead to log the actual upstream/target hostname.
---

## Problem

We are looking to grab the upstream/target hostname in the logging plugin. However we are noticing that when we grab the value of `ctx.balancer_data.host` it is returning the value of the upstream resource inside Kong.

Example:

pre-function:

Log phase:

```lua
kong.log.err(ngx.ctx.balancer_data.host)
```

Returns:

```
[error] 2193#0: *5947 [kong] [string "kong.log.err(ngx.ctx.balancer_data.host)"]:1 [pre-function] SampleUpstreamName while logging request
```

How can we get the upstream/target host returned instead?

## Cause

`balancer_data` returns the host of the service that is being utilized. In this case, the service host is `SampleUpstreamName`. So this is reflected when `ngx.ctx.balancer_data.host` is utilized.

## Solution

To return the upstream/target host you can utilize the variable `ngx.var.upstream_host`

Sample output:

```
2025/08/29 18:16:12 [error] 2193#0: *6163 [kong] [string "kong.log.err(ngx.var.upstream_host)"]:1 [pre-function] mockbin.org while logging request, client: 123.34.45.567, server: kong, request: "GET /upstream HTTP/1.1", upstream: "http://123.34.45.567:80/request", host: "localhost:8000"
```
