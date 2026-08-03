---
title: Underscores in response headers are converted to hyphens
content_type: support
published: false
description: Kong converts underscores in response header names to hyphens by default; set `lua_transform_underscores_in_response_headers` to `off` to preserve them.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why are underscores in response headers converted to hyphens by Kong?
  a: |
    Kong runs on OpenResty/Nginx, which by default converts underscores in response header names to hyphens via the `lua_transform_underscores_in_response_headers` directive. Set `KONG_NGINX_PROXY_LUA_TRANSFORM_UNDERSCORES_IN_RESPONSE_HEADERS` to `off` to keep the underscores in response header names.
related_resources:
  - text: OpenResty `ngx.header` API reference
    url: https://openresty-reference.readthedocs.io/en/latest/Lua_Nginx_API/#ngxheaderheader
---

## Underscores in response headers are converted to hyphens

When calling an upstream endpoint, some of the response headers have underscore characters in their names. When calling the upstream via Kong, the underscores are converted to hyphens. For example:

1. Calling the Upstream directly. The response headers have an underscore in the name which is kept in the response payload:

   ```bash
   curl -i 'https://httpbin.org/response-headers?INTERNAL_ID=123&RESPONSE_CODE=0'
   HTTP/2 200
   date: Wed, 07 Sep 2026 09:17:39 GMT
   content-type: application/json
   content-length: 119
   server: gunicorn/19.9.0
   internal_id: 123
   response_code: 0
   access-control-allow-origin: *
   access-control-allow-credentials: true
   {
   "Content-Length": "119",
   "Content-Type": "application/json",
   "INTERNAL_ID": "123",
   "RESPONSE_CODE": "0"
   }
   ```

2. Calling the Upstream via Kong. The response headers with an underscore in the name have the underscore replaced by a hyphen:

   ```bash
   curl -ki "https://proxy.kong.lan/httpbin/response-headers?INTERNAL_ID=123&RESPONSE_CODE=0"
   HTTP/2 200
   content-type: application/json
   x-cache-key: c9c41f4f7c690a7ce96305e5f1ff9a4e
   internal-id: 123
   x-cache-status: Hit
   access-control-allow-origin: *
   server: gunicorn/19.9.0
   age: 16
   date: Wed, 07 Sep 2026 09:18:18 GMT
   response-code: 0
   access-control-allow-credentials: true
   content-length: 119
   x-kong-upstream-latency: 0
   x-kong-proxy-latency: 2
   via: kong/3.14.0.0-enterprise-edition
   x-server: kongpose_kong-dp_1
   {
   "Content-Length": "119",
   "Content-Type": "application/json",
   "INTERNAL_ID": "123",
   "RESPONSE_CODE": "0"
   }
   ```

There is a lua property to control this name conversion behavior: `lua_transform_underscores_in_response_headers`.

See the OpenResty documentation for details.

For example, setting this parameter in a docker-compose as below:

```yaml
KONG_NGINX_PROXY_LUA_TRANSFORM_UNDERSCORES_IN_RESPONSE_HEADERS: "off"
```

Will keep the underscores in the response headers:

```bash
curl -ki "https://proxy.kong.lan/httpbin/response-headers?INTERNAL_ID=123&RESPONSE_CODE=0"
HTTP/2 200
content-type: application/json
x-cache-key: c9c41f4f7c690a7ce96305e5f1ff9a4e
internal_id: 123
response_code: 0
date: Wed, 07 Sep 2026 09:18:18 GMT
access-control-allow-credentials: true
age: 171
access-control-allow-origin: *
server: gunicorn/19.9.0
x-cache-status: Hit
content-length: 119
x-kong-upstream-latency: 0
x-kong-proxy-latency: 36
via: kong/3.14.0.0-enterprise-edition
x-server: kongpose_kong-dp_1

{
  "Content-Length": "119",
  "Content-Type": "application/json",
  "INTERNAL_ID": "123",
  "RESPONSE_CODE": "0"
}
```
