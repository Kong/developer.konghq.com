---
title: Response buffering in Kong and how it's controlled
content_type: support
description: Explains why {{site.base_gateway}} sometimes buffers upstream responses to a temporary file and how to control this behavior with `proxy_max_temp_file_size`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: What is response buffering in Kong and how is it controlled?
  a: |
    Kong buffers upstream responses to a temporary file when a client can't consume the response data as fast as the upstream application produces it, freeing the upstream to serve other requests sooner. Set `proxy_max_temp_file_size` to `0` (injected via the `kong.conf` file) to disable this buffering, though this is rarely recommended.
related_resources: []
---

## Problem

Occasionally, the proxy error logs show a message like:

```
an upstream response is buffered to a temporary file
```

It's not clear why responses are sometimes buffered to disk or how this behavior is controlled.

## Cause

A client usually has a much slower connection and can not consume the response data as fast as it is produced by an upstream application. Kong tries to buffer the whole response to release the upstream application as soon as possible.

This ensures the upstream application is free to serve other requests and a slow client can still consume the response. Disk buffering does not always happen for every response, if the client can consume the whole response in a timely manner no buffering occurs.

## Solution

It is possible to set `proxy_max_temp_file_size` to 0 to remove response buffering, though there are not many scenarios where this would be desirable so use with caution.

To set this it is required to inject the value into the Nginx config at run time, this can be configured by injecting Nginx directives using the `kong.conf` file.

```
nginx_proxy_proxy_max_temp_file_size=0
```
