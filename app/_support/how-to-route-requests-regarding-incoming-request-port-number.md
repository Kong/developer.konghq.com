---
title: How to route requests regarding incoming request port number
content_type: support
description: Kong doesn't route requests based on the incoming port natively, so this article uses the `pre-function` plugin to proxy requests to different upstreams by port number.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "Admin API route object reference"
    url: "/gateway/entities/route/"
tldr:
  q: How do I proxy requests to different upstreams based on the incoming port number in Kong?
  a: |
    Kong doesn't route requests based on the incoming port by default. Configure multiple ports with `proxy_listen`, then use a `pre-function` plugin whose Lua script checks `kong.request.get_port()` and calls `kong.service.set_target()` to send each port's traffic to a different upstream. This requires setting `untrusted_lua` to `on` or `lax` (not the default `strict`), since `set_target()` is otherwise blocked.
---

## Overview

I would like to proxy requests to different upstreams regarding different incoming ports like below

```

e.g
http://<kong>:7000/test will be proxied to upstream1(https://<upstream1>:443/xxx)
http://<kong>:8000/test will be proxied to upstream2(https://<upstream2>:443/xxx)
http://<kong>:9000/test will be proxied to upstream3(https://<upstream3>:443/xxx)
```

How to realize it?

## Steps

As Kong does not support routing requests based on ports, we have to use the `pre-function` plugin to realize it.

Please refer bellow procedure to send requests based on different ports

(Please modify Lua script/service object/route object depend on your requirements)

Prerequisite: The pre-function plugin's `kong.service.set_target()` call requires the `untrusted_lua` Kong configuration property to be set to `on` or `lax` (the default is now `strict`, which excludes this call). Set `KONG_UNTRUSTED_LUA=on` and restart Kong before proceeding, otherwise the plugin will fail with a 500 error: `attempt to call field 'set_target' (a nil value)`.

1. Enable multiple proxy ports for Kong and restart Kong.

   Modify below parameter in kong configuration

   ```
   KONG_PROXY_LISTEN/proxy_listen=0.0.0.0:7000, 0.0.0.0:8000, 0.0.0.0:9000, 0.0.0.0:8443 ssl
   ```

   Restart Kong

   ```bash
   kong restart
   ```

2. Create below service object and route object

   ```yaml
   service:
     name: test
     url: https://<upstream1>:443/xxx
   route:
     name: test
     path: /test
   ```

3. Write a Lua script like below, let's name it as `redirect.lua`

   ```lua
   local port = kong.request.get_port()
   if port == 8000  then
      kong.service.set_target("<upstream2>", 443)
      kong.service.request.set_scheme("https")
      kong.service.request.set_path("/xxx")
   elseif port == 9000 then
      kong.service.set_target("<upstream3>", 443)
      kong.service.request.set_scheme("https")
      kong.service.request.set_path("/xxx")
   end
   ```

4. Enable the `pre-function` plugin on the route object we created in step 2

   ```bash
   curl -X POST http://<kong>:8001/routes/test/plugins \
       -F "name=pre-function"  \
       -F "config.access[1]=@/path/to/redirect.lua"
   ```

5. Testing

   ```bash
   curl -i http://<kong>:7000/test
   > response from upstream1

   curl -i http://<kong>:8000/test 
   > response from upstream2

   curl -i http://<kong>:9000/test
   > response from upstream3
   ```

As we could see,

request from 7000 port has been proxied to upstream1,

request from 8000 port has been proxied to upstream2,

request from 9000 port has been proxied to upstream3.
