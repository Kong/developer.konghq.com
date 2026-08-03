---
title: "Redirecting a route based on the \"User-Agent\" header"
content_type: support
description: Use the Route Transformer Advanced plugin with a Lua function to dynamically change a route's path based on the incoming User-Agent header.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "How can I redirect a route based on the \"User-Agent\" header?"
  a: |
    Use the `route-transformer-advanced` plugin with a Lua function that reads the `User-Agent` header and returns a different upstream path per browser, for example `/myapp/chrome` for Chrome and `/myapp/mozilla` for Mozilla-based browsers.
related_resources: []
---

## Overview

I have unique paths on my upstream for different browsers for example how could I route a Chrome browser to `/myapp/chrome` and a Mozilla based browser to `/myapp/mozilla`?

## Steps

This is a good use case for the Route Transformer Advanced plugin.

The plugin can be applied to a route to dynamically change the path based on a header. This is achieved using a Lua function.

```bash
curl -X POST http://{HOST}:8001/plugins/ \
    --data "name=route-transformer-advanced" \
    --data "config.path=<insert_function>"
```

Example function:

```lua
$((function()
local value = headers['User-Agent']
  if not value then
    return "not found"
  end
  if value:sub(1, 8) == "Chrome" then
    return "/myapp/chrome"   
  elseif value:sub(1, 4) == "Mozilla" then
	return "/myapp/mozilla"
  end
end)())
```

If using the Admin API to configure the plugin attach it to the curl request as a data payload/file.
