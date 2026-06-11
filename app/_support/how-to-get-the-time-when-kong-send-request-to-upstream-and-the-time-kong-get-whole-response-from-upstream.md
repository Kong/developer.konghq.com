---
title: Getting the time when Kong sends a request to upstream and receives the whole response
content_type: support
description: Use the pre-function and post-function plugins to log the time Kong sends a request to upstream and the time Kong receives the whole response.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: plugin execution order
    url: /konnect/reference/plugins/#plugin-execution-order
  - text: pre-function plugin configuration
    url: /hub/kong-inc/pre-function/configuration/
  - text: post-function plugin configuration
    url: /hub/kong-inc/post-function/configuration/
  - text: untrusted_lua_sandbox_requires
    url: /gateway/reference/configuration/#untrusted_lua_sandbox_requires
---

## Overview

When I send a request to Kong, how can I get the following times?

(1) The time when Kong sends a request to upstream

(2) The time Kong gets the whole response from upstream

## Steps

The above is the flow of how Kong handles requests. (1) could be obtained at the end of the access phase, (2) could be obtained at the beginning of the log phase.

The `post-function` plugin runs after all the other plugins, so we could use it to get (1) in the access phase.

The `pre-function` plugin runs before all the other plugins, so we could use it to get (2) in the log phase.

We could implement it by following the steps below:

1. Set the parameter below for Kong to use the socket package in the `pre-function`/`post-function` plugins:

   ```
   untrusted_lua_sandbox_requires = socket
   ```

   If you run Kong with a container, please set the env var below instead:

   ```
   KONG_UNTRUSTED_LUA_SANDBOX_REQUIRES = socket
   ```

2. Enable the `post-function` plugin below on the target route/service object to log (1):

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

3. Enable the `pre-function` plugin below on the target route/service object to log (2):

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

4. Send a request to Kong again, then you will be able to get the times below (ms) from the Kong error log:

   (1) The time when Kong sends a request to upstream

   (2) The time Kong gets the whole response from upstream
