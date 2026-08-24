---
title: How to customize a plugin response to make it more meaningful
content_type: support
description: Use the `exit-transformer` plugin to append meaningful messages to plugin responses based on the HTTP status code returned by Kong.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I customize a plugin response to make it more meaningful?
  a: |
    Use the `exit-transformer` plugin to rewrite responses based on the HTTP status code Kong returns.
    Point its `config.functions` at a Lua function that inspects `status` and sets `body.message` (for example, a clearer message on `403`), then apply the plugin to the route or service.
related_resources:
  - text: OpenTelemetry plugin
    url: /plugins/opentelemetry/
---

## Overview

How can I customize the output/response of plugins e.g. bot detection to illustrate the reasons behind certain responses e.g. "Forbidden"

## Steps

To provide more informative responses from, for example, the bot detection plugin, you can utilize the `exit-transformer` plugin to customize the output. This approach allows you to append specific messages to the response body, based on the HTTP status codes returned by Kong, indicating the reason for the response, such as detection as a bot.

Here are the steps to set up the `exit-transformer` plugin for verbose output:

1. Create a Lua script named `transform.lua` with the following content:

   ```lua
   return function(status, body, headers)
       if status == 401 then
           body.message = "Unauthorized"
       end
       if status == 403 then
           body.message = "Forbidden, detected as bot"
       end
       if status == 429 then
           body.message = "Retry again later"
       end
       return status, body, headers
   end
   ```

2. Apply the `exit-transformer` plugin to a route or service. Use the following command as an example to set it up on a route:

   ```bash
   curl -X POST -H "Kong-Admin-Token:password" http://api.kong.lan/routes/local-httpbin/plugins \
       --form 'name="exit-transformer"' \
       --form 'config.functions=@"transform.lua"'
   ```

3. Test the setup by making a request that would trigger the plugin. For example, using a user-agent that is detected as a bot:

   ```bash
   curl http://localhost:8000/httpbin -A "Googlebot"
   ```

   The response should now include the customized message:

   ```json
   {"request_id":"61b4f06cc3719e4410464120c3a83054","message":"Forbidden, detected as bot"}
   ```

Additionally, when logging plugins like `http-log` or `file-log` are enabled, the user-agent and other relevant information are logged in the Data Plane logs, which can be useful for debugging purposes.

Additional Tips:

- For a more comprehensive view of the plugins involved in processing a request, consider using the OpenTelemetry plugin, which provides visibility into the spans captured and can help developers understand the flow of requests through the plugins.
- Remember to remove or adjust the verbose output settings when moving from the development stage to production to avoid exposing unnecessary information.
