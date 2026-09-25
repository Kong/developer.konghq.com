---
title: "Kong Gateway: How to log response headers via pre-function plugin"
content_type: support
description: "Log response headers from the pre-function plugin using `kong.log.inspect()` for a full table dump or by looping over `kong.response.get_headers()` for one line per header."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I log response headers using the pre-function plugin?
  a: |
    Use `kong.log.inspect(kong.response.get_headers())` for a pretty-printed table dump, or loop over `kong.response.get_headers()` with `kong.log.info()` to log one header per line. `kong.log.inspect()` is the PDK-native equivalent of `require("inspect")` and works without loosening the `untrusted_lua` sandbox setting.
related_resources: []
---

## Logging response headers with the pre-function plugin

We have a use case where we would like to log response headers when utilizing the pre-function plugin. Is this possible?

It is possible to log the response headers. Depending how you'd like the logs to be visualized, we have 2 different options:

`config.log`:

```lua
kong.log.inspect(kong.response.get_headers())
```

Note: `require("inspect")` is blocked by Kong Gateway's Lua sandbox (`untrusted_lua`) at both the default `strict` tier and the more permissive `lax` tier — it only works if `untrusted_lua` is set fully open (`on`), which is not recommended. `kong.log.inspect()` is the PDK-native equivalent: it performs the same pretty-printed table dump and is not gated by the sandbox at any tier, so no `untrusted_lua` configuration change is needed.

Sample output:

```
[notice] 2914#0: [kong] <source>:func:1 [pre-function]------------------------------------------------------------------------------------+
|{                                                                                                                       |
|  ["access-control-allow-credentials"] = "true",                                                                        |
|  ["access-control-allow-origin"] = "*",                                                                                |
|  connection = "close",                                                                                                 |
|  ["content-length"] = "387",                                                                                           |
|  ["content-type"] = "application/json",                                                                                |
|  date = "Thu, 27 Aug 2026 07:26:10 GMT",                                                                               |
|  server = "gunicorn/19.9.0",                                                                                           |
|  via = "1.1 kong/3.14.0.0-enterprise-edition",                                                                         |
|  ["x-kong-proxy-latency"] = "7",                                                                                       |
|  ["x-kong-request-id"] = "d23fb44f401660746e13e1522c0c3e5e",                                                           |
|  ["x-kong-upstream-latency"] = "2",                                                                                    |
|  <metatable> = {                                                                                                       |
|    __index = <function 1>                                                                                             |
|  }                                                                                                                     |
|} nil                                                                                                                   |
+------------------------------------------------------------------------------------------------------------------------+
```

or if you wanted 1 header per log line:

`config.log`

```lua
for name, value in pairs(kong.response.get_headers()) do
  if type(value) =="table" then
    for i, v in ipairs(value) do
      kong.log.info(name .. ":" .. v)
    end
  else
    kong.log.info(name .. ":" .. value)
  end
end
```

Sample output:

```
2026/08/27 07:27:15 [info] 2914#0: *3221 [kong] <source>:7 [pre-function] date:Thu, 27 Aug 2026 07:27:15 GMT while logging request, client: 172.66.147.243, server: kong, request: "GET /test/get HTTP/1.1", upstream: "http://172.18.0.6:80/get", host: "localhost:19000", request_id: "2ca915648910030237ff8045c9214d16"
2026/08/27 07:27:15 [info] 2914#0: *3221 [kong] <source>:7 [pre-function] content-length:387 while logging request, client: 172.66.147.243, server: kong, request: "GET /test/get HTTP/1.1", upstream: "http://172.18.0.6:80/get", host: "localhost:19000", request_id: "2ca915648910030237ff8045c9214d16"
2026/08/27 07:27:15 [info] 2914#0: *3221 [kong] <source>:7 [pre-function] x-kong-request-id:2ca915648910030237ff8045c9214d16 while logging request, client: 172.66.147.243, server: kong, request: "GET /test/get HTTP/1.1", upstream: "http://172.18.0.6:80/get", host: "localhost:19000", request_id: "2ca915648910030237ff8045c9214d16"
2026/08/27 07:27:15 [info] 2914#0: *3221 [kong] <source>:7 [pre-function] server:gunicorn/19.9.0 while logging request, client: 172.66.147.243, server: kong, request: "GET /test/get HTTP/1.1", upstream: "http://172.18.0.6:80/get", host: "localhost:19000", request_id: "2ca915648910030237ff8045c9214d16"
2026/08/27 07:27:15 [info] 2914#0: *3221 [kong] <source>:7 [pre-function] access-control-allow-origin:* while logging request, client: 172.66.147.243, server: kong, request: "GET /test/get HTTP/1.1", upstream: "http://172.18.0.6:80/get", host: "localhost:19000", request_id: "2ca915648910030237ff8045c9214d16"
2026/08/27 07:27:15 [info] 2914#0: *3221 [kong] <source>:7 [pre-function] access-control-allow-credentials:true while logging request, client: 172.66.147.243, server: kong, request: "GET /test/get HTTP/1.1", upstream: "http://172.18.0.6:80/get", host: "localhost:19000", request_id: "2ca915648910030237ff8045c9214d16"
2026/08/27 07:27:15 [info] 2914#0: *3221 [kong] <source>:7 [pre-function] via:1.1 kong/3.14.0.0-enterprise-edition while logging request, client: 172.66.147.243, server: kong, request: "GET /test/get HTTP/1.1", upstream: "http://172.18.0.6:80/get", host: "localhost:19000", request_id: "2ca915648910030237ff8045c9214d16"
```
