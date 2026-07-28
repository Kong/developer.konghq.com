---
title: Using the `exit-transformer` to modify the 404 message when a route cannot be matched
content_type: support
description: The `exit-transformer` plugin can be applied globally to modify Kong responses, including changing the router 404 `no Route matched with those values` message to a custom message.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can I use the `exit-transformer` to modify the 404 message when a route cannot be matched?
  a: |
    The `exit-transformer` plugin can be applied globally to rewrite Kong's default responses, including the router's 404 `no Route matched with those values` message. Map the default message to a custom one in a Lua script, then install the plugin globally with `config.functions` pointing at that script so it replaces the message for any unmatched route.
related_resources:
  - text: "`exit-transformer` example Lua functions"
    url: /plugins/exit-transformer/#example-lua-functions
---

## Overview

How can I use the `exit-transformer` to modify the 404 message when a route cannot be matched?

## Steps

The `exit-transformer` plugin can be used to modify responses from Kong for specific routes and services, but it can also be applied globally to:

a) Cover a multitude of responses from many routes and services

b) Use less code and apply the same rules across an entire workspace

c) Cover responses that aren't generated from any specific route or service

There are examples about how to use it in many situations in the plugin documentation.

The 404 message given by Kong's router when a request cannot be matched:

```json
{
    "message": "no Route matched with those values"
}
```

In this example we will be changing this message to read `Kong doesn't live here`.

1. Create a Lua script called `custom-messages.lua` with the mapping and message you want to replace:

   ```lua
   local error_map = {
       -- Default
       [0] = function (status, body, headers) return {
         message = body.message,
         _type = "KONG_ERROR",
       } end,
       ["no Route matched with those values"] = {
         message = "Kong doesn't live here",
         status = 404,
       },
     }
     
     
     return function (status, body, headers)
       -- maybe try to get a better way if response comes from kong or not
       if not body or not body.message then
         return status, body, headers
       end
     
       -- Direct error match or default error
       local error = error_map[body.message] or error_map[0](status, body, headers)
     
       body = {
         message = error.message
       }
     
       status = error.status or status
       headers = error.headers or headers
     
       return status, body, headers
     end
   ```

2. Install the plugin globally in the default workspace:

   ```bash
   http -f :8001/plugins name=exit-transformer \
   config.handle_unknown=true \
   config.handle_unexpected=true \
   config.functions=@./custom-messages.lua \
   kong-admin-token:admin
   ```

3. Confirm the custom message is returned:

   ```bash
   http :8000/not_exist
   HTTP/1.1 404 Not Found
   Connection: keep-alive
   Content-Length: 36
   Content-Type: application/json; charset=utf-8
   Date: Fri, 10 Mar 2025 06:12:57 GMT
   X-Kong-Response-Latency: 0
   
   {
       "message": "Kong doesn't live here"
   }
   ```
