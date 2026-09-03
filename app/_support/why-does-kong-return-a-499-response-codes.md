---
title: HTTP 499 response codes from Kong when a client closes the connection early
content_type: support
description: Kong returns HTTP 499 when a client closes the connection before Kong finishes sending the response back, which indicates a client-side issue rather than a Kong or upstream problem.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does Kong return a 499 response code?
  a: |
    499 is an Nginx-specific, non-standard response code that Kong returns when the client closes the connection before Kong finishes sending the response back — often because the client's own request timeout fired. It indicates a client-side issue rather than a Kong or upstream problem. Check the Kong error log with `log_level` set to `info` for the client IP to investigate further.
related_resources: []
---

## Problem

Kong returns 499 response codes despite upstream logs showing 200 responses for the requests that hit Kong, even though the upstream responds well within the specified request timeout.

## Cause

499 is an NGINX specific non-standard response code. This error code indicates that the client that initiated the request terminated the request before the complete response could be sent back by Kong.

## Solution

If Kong is configured with a `log_level` of `info`, the Kong error log will have entries like the following indicating the client ip:

```
2026/07/05 21:57:36 [info] 5605#0: *853576 epoll_wait() reported that client prematurely closed connection, so upstream connection is closed too while sending request to upstream, client: 192.168.160.1, server: kong, request: "GET /example HTTP/1.1", upstream: "http://35.173.123.14:80/delay/2000", host: "0.0.0.0:8000"
```

In most cases the client ip will be that of a component like a Load Balancer in front of Kong but it gives an indication as to where additional log information might be available. The "client" might close a connection because its request timeout triggered.

In any case, the 499 and related "info" messages indicate that the 499 is caused by some client issue rather than something on the Kong side. Therefore, any investigation should focus on what is happening on the client side of the requests which resulted in a 499 response code.
