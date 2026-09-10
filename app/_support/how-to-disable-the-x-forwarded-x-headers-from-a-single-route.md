---
title: How to disable the x-forwarded-x headers from a single route
content_type: support
description: Explains how to use the `post-function` plugin to disable specific `X-Forwarded-*` headers, such as `x-forwarded-proto` or `x-forwarded-host`, on a single route.
products:
  - gateway
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I disable specific X-Forwarded-* headers on a single route?
  a: |
    Install the `post-function` plugin on the route and, in its `access` phase configuration, set the corresponding Nginx variable to `nil` (for example, `ngx.var.upstream_x_forwarded_proto=nil` to drop `x-forwarded-proto`, or `ngx.var.upstream_x_forwarded_host=nil` to drop `x-forwarded-host`) so the header isn't sent to the upstream.
related_resources: []
---

## Overview

How to disable the x-forwarded-x headers on a single route so they do not get sent to the upstream.

## Steps

The easiest way to disable these headers is with a `post-function` plugin.

If you wanted to disable the `x-forwarded-proto` header for example:

1. Install the `post-function` plugin on the route you wish the header removed from.

2. Add the following line to the access phase of the post function header field:

```lua
ngx.var.upstream_x_forwarded_proto=nil
```

If you wanted to disable the `x-forwarded-host` header for example:

1. Install the `post-function` plugin on the route you wish the header removed from.

2. Add the following line to the access phase of the post function header field:

```lua
ngx.var.upstream_x_forwarded_host=nil
```
