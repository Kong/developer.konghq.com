---
title: Retrieving capture group values with the serverless function plugins
content_type: support
description: "Use the PDK function `kong.request.get_uri_captures()` in a serverless function plugin to retrieve a route's named capture group values and set them as upstream headers."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How can the serverless function plugins be used to retrieve capture group values?
  a: |
    Call `kong.request.get_uri_captures().named.<name>` in a serverless function plugin's access phase to get a named capture group's value from the route, then pass it to `kong.service.request.set_header()` to add it as an upstream header.
---

## Overview

We are using a route with a capture group and would like to set an upstream header with the value using the serverless function plugins. How can this be achieved?

This can be accomplished using the PDK function `kong.request.get_uri_captures()`. The function returns a table and can be referenced by the key name.

## Steps

1. Define a route with a capture group, for example:

   ```
   ~/version/(?<version>\d+)
   ```

2. Consume the service over a URL that matches the pattern, for example `http://localhost:8000/version/123`.

3. In a serverless plugin, obtain the value of the named `version` capture group:

   ```lua
   local captures = kong.request.get_uri_captures().named.version
   ```

4. Set the request header using the captured value:

   ```lua
   kong.service.request.set_header("X-gruber-version", captures)
   ```
