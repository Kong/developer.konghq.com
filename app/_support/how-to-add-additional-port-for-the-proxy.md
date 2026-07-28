---
title: How to add an additional port for the Kong proxy
content_type: support
description: "Add an additional port for the Kong proxy by setting `proxy_listen` in `kong.conf` or the `KONG_PROXY_LISTEN` environment variable."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can I add an additional proxy port for Kong to listen to?
  a: |
    Add another entry to `proxy_listen` in `kong.conf` (or the `KONG_PROXY_LISTEN` environment variable) with the desired host and port, then restart Kong. For example, adding `0.0.0.0:9000 reuseport backlog=16384` alongside the existing listeners makes Kong also listen on port 9000.
related_resources:
  - text: Kong Gateway configuration reference (`proxy_listen`)
    url: /gateway/configuration/#proxy-listen
---

## Overview

How can I add an additional proxy port for Kong to listen to?

## Steps

You can add an additional proxy port by adding the port to `proxy_listen` in `kong.conf`, or by using the environment variable `KONG_PROXY_LISTEN`.

For more details, see the configuration reference.

Example:

If you want to add an additional http proxy port that listens on 9000, you would set `proxy_listen` as below and restart kong afterward.

```bash
proxy_listen=0.0.0.0:8000 reuseport backlog=16384, 0.0.0.0:8443 http2 ssl reuseport backlog=16384 , 0.0.0.0:9000 reuseport backlog=16384
```

Kong now will listen to 8000 and 9000 and you should be able to send an http request to these ports now.

```
[~] http http://localhost:8000                       
HTTP/1.1 404 Not Found
Connection: keep-alive
Content-Length: 48
Content-Type: application/json; charset=utf-8
Date: Fri, 21 May 2026 06:20:57 GMT
Server: kong/3.14.0.0-enterprise-edition
X-Kong-Response-Latency: 0

{
    "message": "no Route matched with those values"
}

[~] http http://localhost:9000                                                                                                                                                                       
HTTP/1.1 404 Not Found
Connection: keep-alive
Content-Length: 48
Content-Type: application/json; charset=utf-8
Date: Fri, 21 May 2026 06:21:01 GMT
Server: kong/3.14.0.0-enterprise-edition
X-Kong-Response-Latency: 1

{
    "message": "no Route matched with those values"
}
```

Additional Note:

For https, you could just copy the existing configuration in `proxy_listen` and change the port.

Example:

Config below will add 9443 as an https port:

```bash
proxy_listen=0.0.0.0:8000 reuseport backlog=16384, 0.0.0.0:8443 http2 ssl reuseport backlog=16384 , 0.0.0.0:9443 http2 ssl reuseport backlog=16384
```
