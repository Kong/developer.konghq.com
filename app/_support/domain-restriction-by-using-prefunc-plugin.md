---
title: Domain restriction by using the pre-function plugin
content_type: support
description: Restrict requests from specific domains by checking the `Host` header in a pre-function plugin and returning a 403 response.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I restrict requests from certain domains using the pre-function plugin?
  a: |
    Use a pre-function plugin whose access phase checks the `Host` header and calls `kong.response.exit(403, ...)` when the header matches a restricted domain. Requests with any other `Host` header pass through to the upstream normally.
related_resources:
  - text: Kong Gateway configuration reference for `proxy_listen`
    url: /gateway/configuration/#proxy-listen
---

## Steps

Below is an example that restricts the domains `aaa.com` and `bbb.com`; refer to this and replace the domain names you want to restrict.

1. Create a `test.lua` file with the below content:

   ```lua
   local host = kong.request.get_header("host")
   if host == "aaa.com" or host == "bbb.com" then
     kong.response.exit(403, "Your Domain is not allowed!")
   end
   ```

2. Add the pre-function plugin to a Route like this:

   ```bash
   curl -X POST http://{KONG}:8001/routes/{ROUTE}/plugins \
   -F "name=pre-function" \
   -F "config.access[1]=@/path/to/test.lua"
   ```

   You could also update an existing pre-function plugin like this:

   ```bash
   curl -X PATCH http://{KONG}:8001/plugins/<PLUGIN-ID> \
       -F "config.access[1]=@/path/to/test.lua"
   ```

3. Sending a request with the `Host` header set to `aaa.com` or `bbb.com` returns a 403:

   ```
   ❯ curl {KONG}:8000/{ROUTE_PATH} -i -H Host:aaa.com
   HTTP/1.1 403 Forbidden
   Date: Fri, 01 Jul 2026 06:16:47 GMT
   Connection: keep-alive
   Content-Length: 27
   X-Kong-Response-Latency: 1
   Server: kong/3.14.0.0-enterprise-edition

   Your Domain is not allowed!%
   ❯ curl {KONG}:8000/{ROUTE_PATH} -i -H Host:bbb.com
   HTTP/1.1 403 Forbidden
   Date: Fri, 01 Jul 2026 06:16:51 GMT
   Connection: keep-alive
   Content-Length: 27
   X-Kong-Response-Latency: 1
   Server: kong/3.14.0.0-enterprise-edition

   Your Domain is not allowed!
   ```

4. Sending a request with any other `Host` header passes the pre-function plugin check and returns the upstream response:

   ```
   ❯ curl {KONG}:8000/{ROUTE_PATH} -i -H Host:ccc.com
   HTTP/1.1 200 OK
   ...
   ```
