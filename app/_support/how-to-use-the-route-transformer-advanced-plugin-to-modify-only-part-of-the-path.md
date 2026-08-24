---
title: How to use the route-transformer-advanced plugin to modify only part of the path
content_type: support
description: The `route-transformer-advanced` plugin allows you to use any of the current request headers, query parameters, and captured URI groups as templates to populate supported config fields.
tldr:
  q: How do I use the route-transformer-advanced plugin to modify only part of the request path?
  a: |
    Use a captured URI group in the plugin's `path` template to rewrite only a portion of the path — for example capture `~/old_path/(?<path>\S+)` and set `path: /anything/new_path/$(uri_captures['path'])`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: request-transformer-advanced template as value
    url: /plugins/request-transformer-advanced/#templates
---

## Overview

How to use the route-transformer-advanced plugin to modify only some part of the request path?

## Steps

The `route-transformer-advanced` plugin allows you to use any of the current request headers, query parameters, and captured URI groups as templates to populate supported config fields.

These templates are described in the `request-transformer-advanced` plugin.

This deck example modifies the requests' original route from `/old_path/<something>` to `/anything/new_path/<something>`

```yaml
_format_version: "3.0"
services:
- host: httpbin.org
  name: httpbin.org
  port: 443
  protocol: https
  routes:
  - name: old_path
    paths:
    -  ~/old_path/(?<path>\S+)
    plugins:
    - config:
        path: /anything/new_path/$(uri_captures['path'])
      name: route-transformer-advanced
```

```bash
curl http://localhost:8000/old_path/asdf/qwerty?myparam=value1
{
  "args": {
    "myparam": "value1"
  }, 
  "data": "", 
  "files": {}, 
  "form": {}, 
  "headers": {
    "Accept": "*/*", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.68.0", 
    "X-Amzn-Trace-Id": "Root=1-64365e22-2b5844ec206841dc09909874", 
    "X-Forwarded-Host": "localhost", 
    "X-Forwarded-Path": "/old_path/asdf/qwerty", 
    "X-Forwarded-Prefix": "/old_path/asdf/qwerty"
  }, 
  "json": null, 
  "method": "GET", 
  "origin": "192.168.16.1, 213.195.110.197", 
  "url": "https://localhost/anything/new_path/asdf/qwerty?myparam=value1"
}
```
