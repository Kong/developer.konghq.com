---
title: "Kong Gateway: Receiving error \"body must be a string\" with GRPC-web request"
content_type: support
description: This issue occurs when the body buffer size is not large enough to handle the entire grpc-web request. To resolve it, increase the value of `nginx_http_client_body_buffer_size`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does the grpc-web plugin fail with "body must be a string"?
  a: |
    The grpc-web request body is larger than `nginx_http_client_body_buffer_size` (default `8k`), so it gets buffered to a temporary file and the plugin receives no in-memory string.
    Increase `nginx_http_client_body_buffer_size` to fit the largest expected request body.
---

## Problem

When using the grpc-web plugin, requests occasionally fail to complete and the plugin returns a "body must be a string" error.

The warning received is the following:

```
2025/12/04 00:15:20 [warn] 20708#0: *406875 a client request body is buffered to a temporary file /usr/local/kong/client_body_temp/0000000056
```

After the warn we get the following error message:

```
2025/12/04 00:15:21 [error] 20708#0: *406875 [kong] init.lua:365 [grpc-web] ...sr/local/share/lua/5.1/kong/plugins/grpc-web/handler.lua:73: body must be a string
```

## Cause

This issue is occurring due to the body buffer size not being large enough to handle the entire grpc-web request.

## Solution

To resolve this we can increase the value of `nginx_http_client_body_buffer_size`. By default this is configured to `8k`. If your request is larger than this the grpc-web plugin will fail with "body must be a string". To verify what size buffers you need you can check the size of the body being returned by reaching out to the endpoint directly and verifying the `Content-Length`. From here you can adjust the buffer size to best fit your environment. As always, we recommend testing this out thoroughly on a lower environment before moving to production.
