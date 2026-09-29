---
title: How to implement guard logic for buffered proxying and body existence in serverless plugins
content_type: support
description: Add guard logic to a `pre-function` plugin that checks `ngx.ctx.buffered_proxying` and confirms the request or response body is non-nil before serializing it, to prevent errors from nil bodies or disabled buffering.
tldr:
  q: How do I guard against missing bodies and disabled buffering in a serverless plugin?
  a: |
    In a `pre-function` plugin, check `ngx.ctx.buffered_proxying` before reading a body, call `kong.service.request.enable_buffering()` when it is off, and verify the raw body is non-nil before serializing it.
    This prevents errors when the body is `nil` or buffering is disabled.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
---

## Overview

When working with request and response bodies, buffered proxying needs to be enabled and the body needs to exist to perform operations.

Without guard logic in place, empty request / response bodies and incorrect buffering settings can cause the serverless plugin to throw errors in the Kong logs when the body is nil or buffering is disabled.

## Steps

Guard logic can be put in place to protect any operations that expect a body to be present.

This is an example of how to configure a `pre-function` plugin to check for whether buffering is enabled, and if so serialize the request and response bodies to a log plugin output.

1. Create `access-phase.lua` and add the following contents:

   ```lua
   kong.log.warn("Access Start")
   kong.log.warn("Checking buffering")

   if ngx.ctx.buffered_proxying then
       kong.log.warn("Buffering already enabled.")
   else
       kong.log.warn("Enabling buffering...")
       kong.service.request.enable_buffering()
   end

   if not ngx.ctx.buffered_proxying then
       kong.log.warn("Buffering was not enabled.")
   else
       kong.log.warn("Buffering check passed, retrieving request body")
       local raw_body = kong.request.get_raw_body()

       if raw_body then
           kong.log.warn("Valid request body found, serialising to log")
           kong.log.set_serialize_value("request.body", raw_body)
       else
           kong.log.warn("No body to serialise")
       end
   end

   kong.log.warn("Access End")
   ```

2. Create `log-phase.lua` and add the following contents:

   ```lua
   kong.log.warn("Log Start")

   kong.log.warn("Checking buffering")

   if not ngx.ctx.buffered_proxying then
       kong.log.warn("Buffering is disabled, cannot log the response body.")
   else
       kong.log.warn("Buffering check passed, retrieving response body")
       local raw_response_body = kong.service.response.get_raw_body()

       if raw_response_body then
           kong.log.warn("Valid response body found, serialising to log")
           kong.log.set_serialize_value("response.body", raw_response_body)
       else
           kong.log.warn("No body to serialise")
       end
   end
   ```

3. Add the `pre-function` plugin to a route/service using the files as inputs:

   ```bash
   curl -X POST http://localhost:8001/routes/<route_name>/plugins \
   -F "name=pre-function"  \
   -F "config.access=@./access-phase.lua" \
   -F "config.log=@./log-phase.lua" \
   -H "Kong-Admin-Token:<RBAC Token>"
   ```

The Kong error log will show the various log messages as they are executed.
