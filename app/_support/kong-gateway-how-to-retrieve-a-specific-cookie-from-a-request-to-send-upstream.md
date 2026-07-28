---
title: "Kong Gateway: How to retrieve a specific cookie from a request to send upstream"
content_type: support
published: false
description: This can be done using the Request Transformer Advanced plugin with advanced templates.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I retrieve a specific cookie from a request and send it upstream in Kong Gateway?
  a: |
    Use the Request Transformer Advanced plugin's `config.add.header` property with an advanced template that parses the `cookie` header. The template loops over the cookie's key/value pairs with `cookie:gmatch("([^;=]+)=([^;]*)")` and returns the value for the matching cookie name, which is then added as a new upstream header.
---

## Kong Gateway: How to retrieve a specific cookie from a request to send upstream

We would like to retrieve a specific cookie value from the request cookie header to proxy upstream. How can this be achieved?

This can be done using the Request Transformer Advanced plugin with advanced templates.

For example, given the request cookie

Cookie: name=gruber;location=nakatomi plaza

```bash
curl -H "cookie: name=gruber;location=nakatomi plaza" localhost:8000/replace
```

The below can be used to add the value of the cookie named `name` to the upstream header `X-Test-Header` using the `config.add.header` property. In cases where multiple cookies share the same name this will only process the first occurrence.

```lua
X-Test-Header:$((function()
local cookie = headers.cookie

for key, value in cookie:gmatch("([^;=]+)=([^;]*)") do
if key == "name" then
    return value
end
end

end)())
```

**Please keep in mind that any sample custom code provided is not intended for use in production. Please thoroughly test this on a lower environment.**
