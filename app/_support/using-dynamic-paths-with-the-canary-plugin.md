---
title: Using dynamic paths with the Canary plugin
content_type: support
description: The Canary plugin only supports a static path; use the Request Transformer or Route Transformer plugin with capture groups to forward a dynamic upstream path from the route.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Can the Canary plugin route to a dynamic path built from the incoming request?
  a: |
    No. The Canary plugin only supports a static path. Leave the Canary plugin's path blank and use the Request Transformer or Route Transformer plugin with capture groups (for example route path `"/(?<path>\\w{3})"`, route transformer path `/v2/$(uri_captures['path'])`) to forward the route's original unstripped path before it reaches the Canary plugin.
---

## Problem

Can a dynamic path be used with the Canary plugin? For example, we would like to configure a route with a path of /updates that routes to hosta.com. The Canary plugin will be added with a host of hostb.com and a path of /v2. The goal is to pass along the unstripped path from the route, /updates, and have it appended to the canary path resulting in a path of hostb.com/v2/updates.

## Solution

The Canary plugin can only use a static path, so as long as you do not specify a path in the plugin it will not touch the path and normal Kong behavior will continue. However, once a path is added, it is static, meaning the original unstripped path will not be passed to the plugin. A viable workaround would be to manipulate the request path and leave the path of the Canary plugin as blank. The request or route transformer plugins can be used with capture groups to dynamically change it before reaching the Canary plugin, for example: route path `"/(?<path>\\w{3})"`, route transformer path: `/v2/$(uri_captures['path'])`
