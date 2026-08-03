---
title: How to use a `pre-function` plugin to review incoming request details with minimal Kong processing
content_type: support
description: "Use a `pre-function` plugin with a custom Lua script to capture and return incoming request details, such as headers, query string, and raw body, with minimal additional Kong processing."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I use a `pre-function` plugin to inspect the details of an incoming request?
  a: |
    Attach a `pre-function` plugin to a route and use a Lua script such as `prefunc.lua` in its access phase. The script calls `kong.request.*` functions to collect the method, scheme, host, headers, query string, and raw body, then uses `kong.response.exit()` to return them directly in the response, without proxying the request upstream.
---

## Overview

How to use a `pre-function` plugin to reflect incoming request details with minimal Kong processing.

## Steps

Create a route:

```bash
curl 'https://localhost:8001/default/routes' \
    -H 'Content-Type: application/json;charset=UTF-8' \
    --data-raw '{"name":"test-rt","protocols":["http"],"paths":["/echo"]}'
```

Create a `prefunc.lua` file with the following content:

```lua
local kong = kong

local response_body = {}
response_body["request_method"] = kong.request.get_method()
response_body["request_scheme"] = kong.request.get_scheme()
response_body["request_host"] = kong.request.get_host()
response_body["request_port"] = kong.request.get_port()
response_body["request_http_version"] = kong.request.get_http_version()
response_body["request_path"] = kong.request.get_path()
response_body["request_query_string"] = kong.request.get_raw_query()
response_body["request_query_arguments"] = kong.request.get_query()
response_body["request_headers"] = kong.request.get_headers()
response_body["request_raw_body"] = kong.request.get_raw_body()

return kong.response.exit(200, response_body, headers)
```

Assign a `pre-function` plugin to the route to use the `prefunc.lua` file:

```bash
curl -X POST http://localhost:8001/routes/test-rt/plugins \
     -F "name=pre-function"  \
     -F "config.access=@prefunc.lua"
```

These functions are all available in the access phase.

Test the `/echo` route for a response:

```bash
curl http://localhost:8000/echo -H "Custom-Header:hello" -d "I am a body"
```

Response:

```
HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 393
Content-Type: application/json; charset=utf-8
Date: Wed, 30 Jun 2026 05:06:53 GMT
Server: kong/3.14.0.0-enterprise-edition
X-Kong-Response-Latency: 0

{
  "request_method": "POST",
  "request_http_version": 1.1,
  "request_port": 8000,
  "request_scheme": "http",
  "request_host": "localhost",
  "request_path": "/echo",
  "request_raw_body": "I am a body",
  "request_query_arguments": {},
  "request_headers": {
    "host": "localhost:8000",
    "custom-header": "hello",
    "user-agent": "curl/7.64.1",
    "accept": "*/*",
    "content-type": "application/x-www-form-urlencoded",
    "content-length": "11"
  },
  "request_query_string": ""
}
```
