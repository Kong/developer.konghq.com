---
title: "Kong Gateway: Routing to different endpoint based on existence of query parameter"
content_type: support
description: Use the Route Transformer Advanced plugin to route the same path to different upstream endpoints depending on whether a query parameter is present.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I route the same path to different endpoints based on whether a query parameter is present?
  a: |
    Use the Route Transformer Advanced plugin and set the `host` (and `port`) fields to a `Template` value that reads `query_params` and returns a different upstream depending on whether the query parameter is set.
---

## Problem

We would like to have 2 routes using the same path but 1 with a query string that proxies to 2 different endpoints. How can we achieve this?

Example:

- `http://localhost:8000/test`
- `http://localhost:8000/test?sendnow=test`

## Solution

One way to accomplish this is by using the Route Transformer Advanced plugin. We'd check for the query parameter and if it exists, route to endpoint A. If it doesn't exist, route to endpoint B.

Route Transformer Advanced plugin:

```yaml
    plugins:
    - config:
        host: $((function()     local value = query_params.sendnow     if value ==
          "true" then       return "mockbin.org"     else     return "google.com"   end    end)())
        path: null
        port: $((function()     local value = query_params.sendnow     if value ==
          "true" then       return "443"     else     return "443"   end    end)())
```

Attached below is a sample config for the Route Transformer Advanced and a sample route/service demonstrating the requirement.

```yaml
_format_version: "3.0"
_info:
  defaults: {}
  select_tags:
  - routebyquery
_workspace: default
services:
- connect_timeout: 60000
  host: mockbin.org
  name: mockservice
  port: 443
  protocol: https
  read_timeout: 60000
  retries: 5
  routes:
  - https_redirect_status_code: 426
    name: routebyquery
    path_handling: v0
    paths:
    - /routebyquery
    plugins:
    - config:
        host: $((function()     local value = query_params.sendnow     if value ==
          "true" then       return "mockbin.org"     else     return "google.com"   end    end)())
        path: null
        port: $((function()     local value = query_params.sendnow     if value ==
          "true" then       return "443"     else     return "443"   end    end)())
      enabled: true
      name: route-transformer-advanced
      protocols:
      - grpc
      - grpcs
      - http
      - https
    preserve_host: false
    protocols:
    - http
    - https
    regex_priority: 0
    request_buffering: true
    response_buffering: true
    strip_path: true
  tags:
  - route-by-header
  - routebyquery
  write_timeout: 60000
```

Example commands to test with query parameter:

```bash
curl 'http://localhost:58000/routebyquery?sendnow=true'
```

Example Commands to test without query parameter:

```bash
curl http://localhost:58000/routebyquery
```
