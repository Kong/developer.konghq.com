---
title: HTTP 499 error responses when Kong is behind a CDN and using SSE
content_type: support
description: HTTP error 499 means that the client closed the connection in the middle of processing the request through the server or before the server answered the request.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does Kong return HTTP 499 error responses when it's behind a CDN and using SSE?
  a: |
    Kong Gateway responds with HTTP 200, but the CDN's response to the client is HTTP 499, because the request sent through Kong needs to be shorter than the proxy read timeout or Kong terminates the upstream connection. Disable buffering on the route with `request_buffering = false` and `response_buffering = false`, or use the `X-Accel-Buffering: no` header for SSE connections to disable buffering explicitly.
related_resources:
  - text: "X-Accel-Buffering: no header"
    url: https://www.nginx.com/resources/wiki/start/topics/examples/x-accel/
---

## Problem

When Kong is behind a CDN and using SSE (Server Sent Events), clients receive HTTP 499 error responses even though Kong itself returns HTTP 200.

## Cause

HTTP error 499 means that the client closed the connection in the middle of processing the request through the server or before the server answered the request. This is a common situation when allowing SSE (Server Sent Events) and Kong is behind a CDN: Kong Gateway responds with HTTP 200, but the CDN responds with HTTP 499. In this scenario, the request sent through Kong needs to be shorter than the proxy read timeout or Kong will terminate the upstream connection.

## Solution

To prevent this issue, you can disable buffering in the route setting:

```
request_buffering = false
response_buffering = false
```

Kong also supports the `X-Accel-Buffering: no` header for SSE connections to disable buffering explicitly. You can find more information in the article: How can I use Kong to allow SSE (Server Sent Events)?
