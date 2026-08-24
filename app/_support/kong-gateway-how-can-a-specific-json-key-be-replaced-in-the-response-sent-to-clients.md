---
title: "{{site.base_gateway}}: Replace a specific JSON key in the response sent to clients"
content_type: support
published: false
description: Use the transform functions of the Response Transformer Advanced plugin to rename a specific JSON key in the response sent to clients.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I replace a specific JSON key in the response sent to clients?
  a: |
    Use the `transform` functions of the Response Transformer Advanced plugin. Supply a Lua function that copies the value of the old key to the new key and then removes the old key from the response body.
related_resources:
  - text: Response Transformer Advanced plugin examples
    url: /plugins/response-transformer-advanced/examples/
---

## Problem

We have a JSON structure returned from our upstream server, for example:

```json
{
  "name": "gruber",
  "location": "nakatomi plaza",
  "internal_id": "12fjsd9123"
}
```

We would like to replace the key name `internal_id` with `group_id` while retaining the value. How can this be done?

## Solution

You can achieve this using the transform functions of the Response Transformer Advanced plugin.

For example, this checks that `internal_id` isn't nil/missing and sets `group_id` to the value before removing it.

```lua
return function (data)
  if type(data) ~= "table" then
  return data
end

if data["internal_id"] ~= nil then
  data["group_id"] = data["internal_id"]
  data["internal_id"] = nil
end

return data
end
```
