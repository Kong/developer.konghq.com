---
title: "Kong plugin produces a warning \"a client request body is buffered to a temporary file\""
content_type: support
description: "It is likely that the `client_body_buffer_size` value is too small to hold the entire payload."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does a Kong plugin log "a client request body is buffered to a temporary file"?
  a: |
    `client_body_buffer_size` is too small to hold the request body in memory, so NGINX buffers it to a temporary file and logs this warning. Increase `nginx_http_client_body_buffer_size` so the full payload fits in memory instead.
---

## Problem

A Kong plugin may not produce the desired results and you find the following error in the logs.

```
2026/07/24 02:24:15 [warn] 125#0: *335 a client request body is buffered to a temporary file /kong/servroot/client_body_temp/0000000001, client: 172.23.0.1, server: kong, request: "POST /v1/data/KPIS/query HTTP/1.1", host: "localhost:8000"
```

## Cause

It is likely that the `client_body_buffer_size` value is too small to hold the entire payload. The logs indicate that the request was buffered, which triggers this warning. Plugins may not function as expected if they cannot store the full request payload in memory.

## Solution

The recommended solution is to increase `nginx_http_client_body_buffer_size` to a value large enough to keep the entire request in memory and avoid buffering, as documented in the Kong Gateway configuration reference.
