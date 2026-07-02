---
title: How to get the time when {{site.base_gateway}} sends a request to upstream and receives a response
content_type: support
description: Use the Pre-Function and Post-Function plugins to log the time {{site.base_gateway}} sends a request to upstream and the time {{site.base_gateway}} receives the whole response.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I get the time when {{site.base_gateway}} sends a request to upstream and the time {{site.base_gateway}} gets the whole response from upstream?
  a: |
    Use the Post-Function plugin (end of the access phase) to log the send time, and the Pre-Function plugin (start of the log phase) to log the receive time.
    Set `untrusted_lua_sandbox_requires = socket` first so the plugins can call `socket.gettime()`.
related_resources:
  - text: Plugin execution order
    url: /gateway/entities/plugin/#dynamic-plugin-ordering
  - text: Pre-Function plugin configuration
    url: /plugins/pre-function/
  - text: Post-Function plugin configuration
    url: /plugins/post-function/
---


## Steps

Kong handles requests in phases: the access phase ends just before the request is sent to upstream, and the log phase begins just after the full response is received.

* **Send time**: Obtainable at the end of the access phase. The Post-Function plugin runs after all other plugins, so it can capture this timestamp.
* **Receive time**: Obtainable at the beginning of the log phase. The Pre-Function plugin runs before all other plugins in the log phase, so it can capture this timestamp.

To implement this:

1. Set the following parameter for {{site.base_gateway}} to use the socket package in the Pre-Function/Post-Function plugins:

   ```bash
   untrusted_lua_sandbox_requires = socket
   ```

   If you run Kong in a container, set the following env var instead:

   ```bash
   KONG_UNTRUSTED_LUA_SANDBOX_REQUIRES = socket
   ```

2. Enable the Post-Function plugin on the target Route/Service object to log the send time:

   ```yaml
   plugins:
   - name: post-function
     config:
       access:
       - |-
         local socket = require "socket"
         local s_time = socket.gettime()*1000
         kong.log('sending time(ms): ', s_time)
     enabled: true
   ```

3. Enable the Pre-Function plugin on the target Route/Service object to log receive time:

   ```yaml
   plugins:
   - name: pre-function
     config:
       log:
       - |-
         local socket = require "socket"
         local r_time = socket.gettime()*1000
         kong.log('receiving time(ms): ', r_time)
     enabled: true
   ```

4. Send a request to {{site.base_gateway}} again, and you will see the following times (ms) in the {{site.base_gateway}} error log:

* The time when {{site.base_gateway}} sends a request to upstream
* The time {{site.base_gateway}} gets the whole response from upstream
