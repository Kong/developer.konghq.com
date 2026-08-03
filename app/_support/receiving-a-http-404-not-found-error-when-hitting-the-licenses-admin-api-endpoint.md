---
title: "Receiving an HTTP 404 \"Not Found\" error when hitting the `/licenses` Admin API endpoint"
content_type: support
description: "A 404 on the `/licenses` Admin API endpoint usually means you're running the open-source image instead of `kong/kong-gateway`, or Kong Gateway is running in DB-less mode, where the endpoint doesn't exist."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does the `/licenses` Admin API endpoint return a 404 Not Found error?
  a: |
    A 404 on `/licenses` usually has one of two causes: you're running the open-source Kong image instead of `kong/kong-gateway` (licenses only apply to Enterprise Edition images), or Kong Gateway is running in DB-less mode, where the `/licenses` endpoint doesn't exist — load the license through environment variables or the file system instead.
---

## Problem

I'm unable to send requests to the `/licenses` endpoint on the Admin API. When sending a cURL to the `/licenses` endpoint, I receive an HTTP 404 Not Found error response such as the one below:

```bash
curl --request GET \
  --url http://localhost:8001/licenses -v
Note: Unnecessary use of -X or --request, GET is already inferred.
*   Trying 127.0.0.1:8001...
* Connected to localhost (127.0.0.1) port 8001 (#0)
> GET /licenses HTTP/1.1
> Host: localhost:8001
> User-Agent: curl/7.79.1
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< Date: Mon, 20 Jun 2026 17:55:11 GMT
< Content-Type: application/json; charset=utf-8
< Connection: keep-alive
< Access-Control-Allow-Origin: *
< Content-Length: 23
< X-Kong-Admin-Latency: 0
< Server: kong/3.14.0.0
<
* Connection #0 to host localhost left intact
{"message":"Not found"}%
```

## Solution

There are at least two known reasons for an HTTP 404 response to any `/licenses` requests, and these include the following:

- Using the open-source image rather than the `kong/kong-gateway` image for the Enterprise Edition. The open source image does not allow for licenses since licenses are applicable only to the Enterprise Edition images of Kong Gateway.
- Running Kong Gateway in DB-less mode. Per the documentation, the `/licenses` endpoint does not exist in a DB-less deployment style. When running Kong Gateway in DB-less mode, an admin must use the environment variables or file system for loading the license instead of the Admin API.
