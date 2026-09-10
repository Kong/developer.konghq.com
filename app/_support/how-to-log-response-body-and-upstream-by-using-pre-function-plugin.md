---
title: How to log response body and upstream by using pre-function plugin
content_type: support
description: Use the pre-function plugin to log the response body and the resolved upstream for a service.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: pre-function plugin
    url: /plugins/pre-function/
tldr:
  q: How do I log the response body and upstream target using the pre-function plugin?
  a: |
    Enable a `pre-function` plugin on the service with a `config.log` phase function that calls `kong.log(kong.service.response.get_raw_body())`, and a `config.access` phase function that enables request buffering and logs `ngx.ctx.balancer_data` fields. The response body and resolved upstream then appear in Kong's error log for each request. Logging the response body forces Nginx to buffer the full body, which affects proxy performance for large responses.
---

## Overview

How to log response body and upstream by using pre-function plugin

## Steps

See the pre-function plugin docs to learn how to enable a pre-function plugin.

Use the command below to enable a pre-function plugin with a Lua function to log the response body on a service:

```bash
curl -X POST http://\<kong\>:8001/services/\<service\>/plugins \
    --data "name=pre-function"  \
    --data "config.log[1]=kong.log(string.gsub(kong.service.response.get_raw_body(), '\n', ''))" \
    --data "config.access[1]=kong.service.request.enable_buffering()" \
    --data "config.access[2]=kong.log(ngx.ctx.balancer_data.scheme, '://', ngx.ctx.balancer_data.host, ':', ngx.ctx.balancer_data.port, ngx.var.upstream_uri)"
```

If you send a request to the route associated with the service that has the pre-function plugin enabled, you should be able to see the response body inside `kong error.log`:

```
2026/05/07 07:03:01 [notice] 27#0: *207173 [kong] ',..."]:1 [pre-function] https://httpbin.org:443/anything, client: 172.21.0.1, server: kong, request: "GET /ttt HTTP/1.1", host: "localhost:8000"
...
2026/05/07 07:03:02 [notice] 27#0: *207173 [kong] [string "kong.log(string.gsub(kong.service.response.ge..."]:1 [pre-function] {  "args": {},   "data": "",   "files": {},   "form": {},   "headers": {    "Accept": "*/*",     "Host": "httpbin.org",     "User-Agent": "curl/7.64.1",     "X-Amzn-Trace-Id": "Root=1-6094e626-44a735441ee0fc2b51ef72a0",     "X-Forwarded-Host": "localhost",     "X-Forwarded-Path": "/ttt",     "X-Forwarded-Prefix": "/ttt"  },   "json": null,   "method": "GET",   "origin": "172.21.0.1, 175.177.45.138",   "url": "https://localhost/anything"}19 while logging request, client: 172.21.0.1, server: kong, request: "GET /ttt HTTP/1.1", host: "localhost:8000"
```

Be aware that logging the response body requires Nginx to buffer the whole body, which affects proxy performance when the body is large.
