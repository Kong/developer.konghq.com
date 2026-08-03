---
title: How to redirect a failed request with exit transformer plugin and `Location` header
content_type: support
description: How to use the Exit Transformer plugin to add a `Location` header and redirect clients to another route after a failed authentication request.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Exit Transformer plugin
    url: /plugins/exit-transformer/
tldr:
  q: How do I redirect a client to a different route after a failed authentication request?
  a: |
    Use the Exit Transformer plugin to rewrite the response Kong sends when `kong.exit()` is called — for example, on a failed key-auth check. The plugin's Lua function can add a `Location` header and a `302` status to the response, so the client follows the redirect to another route.
---

## Overview

Currently we have set the key-auth plugin on our service. How can we redirect the request to a certain route in Kong if the key-auth authentication failed?

## Steps

You can customize authentication error responses with the Exit Transformer plugin. The Exit Transformer plugin lets you transform Kong's response when `kong.exit()` is called, which in this case happens when authentication fails.

In this use case, we will use the plugin to add a `Location` header to the exit response.

After receiving the response, the client will follow the header to the designated route.

Demonstration:

1. Create a Service and two Routes with path `/test` and `/http` in Kong. Enable the key-auth plugin on the `/test` route

   ```bash
   http :8001/services name=example host=mockbin.org
   http -f :8001/services/example/routes name=example_route paths=/test
   http -f :8001/services/example/routes name=redirect_route paths=/hello
   http :f :8001/routes/example_route/plugins name=key-auth
   ```

2. Create a file named `redirect.lua` with the transformation code. The following example adds a `Location` header, adds an error, and adds a status field on the response.

   ```lua
   return function(status, body, headers)
     if not body then
       body = { message = "redirect to kong" }
     else
       body.message = "redirect to Kong"
     end

     if not headers then
       headers = { Location = "/hello" }
     else
       headers["Location"] ={ "/hello" }
     end

     return 302, body, headers
   end
   ```

3. Send a request to the `/test` route without the `api-key` header to trigger failed authentication. You will see the request fails and redirects to the `/http` route:

   ```bash
   curl localhost:8000/test -L -v
   *   Trying ::1:8000...
   * Connected to localhost (::1) port 8000 (#0)
   > GET /test HTTP/1.1
   > Host: localhost:8000
   > User-Agent: curl/7.71.1
   > Accept: */*
   >
   * Mark bundle as not supporting multiuse
   < HTTP/1.1 302 Moved Temporarily
   < Date: Mon, 17 Aug 2026 03:53:42 GMT
   < Content-Type: application/json; charset=utf-8
   < Connection: keep-alive
   < WWW-Authenticate: Key realm="kong"
   < Location: /hello --> `Location` header created by the exit transformer plugin
   < Content-Length: 30
   < Server: kong/3.14.0.0-enterprise-edition
   <
   * Ignoring the response-body
   * Connection #0 to host localhost left intact
   * Issue another request to this URL: 'http://localhost:8000/http'
   * Found bundle for host localhost: 0x563de38385c0 [serially]
   * Can not multiplex, even if we wanted to!
   * Re-using existing connection! (#0) with host localhost
   * Connected to localhost (::1) port 8000 (#0)
   > GET /hello HTTP/1.1
   > Host: localhost:8000
   > User-Agent: curl/7.71.1
   > Accept: */*
   >
   * Mark bundle as not supporting multiuse
   < HTTP/1.1 200 OK
   < Content-Type: application/json
   < Content-Length: 338
   < Connection: keep-alive
   < Server: gunicorn/19.9.0
   < Date: Mon, 17 Aug 2026 03:53:42 GMT
   < Access-Control-Allow-Origin: *
   < Access-Control-Allow-Credentials: true
   < Via: kong/3.14.0.0-enterprise-edition
   <
   ```
