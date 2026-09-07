---
title: "Kong Gateway: Force HTTP/1.1 downgrade on specific routes"
content_type: support
description: While Kong does not support downgrading of the connection for specific routes it can be achieved through the use of redirects.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I force an HTTP/1.1 downgrade on specific Kong Gateway routes?
  a: |
    Kong doesn't support downgrading the protocol version directly, but you can achieve it with a redirect: a pre-function/serverless plugin checks `ngx.req.http_version()` and, if it's HTTP/2, calls `kong.response.exit(301, nil, {["Location"] = "..."})` to redirect the client to an HTTP/1.1-only listener. Note that `kong.response.set_status()` alone does not short-circuit the request — you must use `kong.response.exit()`.
related_resources: []
---

## Problem

We have a use case that requires downgrading the HTTP version from HTTP/2 to HTTP/1.1 on specific routes.

## Solution

While Kong does not support downgrading of the connection for specific routes it can be achieved through the use of redirects.

Assuming the proxy listener is setup as follows where we have 2 TLS enabled ports, one using HTTP2 and the other HTTP/1.1:

```yaml
proxy_listen: "0.0.0.0:8000, 0.0.0.0:8443 http2 ssl, 0.0.0.0:9443 ssl"
```

A pre-function/serverless plugin can be added to your route to check the HTTP version being used and force a redirect to an HTTP/1.1 listener. Note that `kong.response.set_status()` alone does **not** short-circuit the request — called on its own in the `access` phase it has no effect and the request still proceeds to the upstream, whose response then overwrites it. To actually return the redirect to the client instead of proxying, use `kong.response.exit()`:

```lua
local version = ngx.req.http_version()

if version == 2 then
  return kong.response.exit(301, nil, {["Location"] = "https://localhost:9443/echo"})
end
```

This could be further scoped to specific user agents such as browsers:

```lua
local useragent = ngx.req.get_headers()["user-agent"]
..
if version == 2 and useragent:find("mozilla") ~= nil then
...
```

> **Note:** Caution should be taken with this approach as it can introduce some overhead such as increased and re-establishing connections. Additionally some clients, non-browser based, may not properly follow redirects. This is provided as general guidance and thorough testing should be performed before implementing this in any non-test environments.
