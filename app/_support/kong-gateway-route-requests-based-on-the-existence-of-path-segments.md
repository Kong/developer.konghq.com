---
title: "Kong Gateway: Route requests based on the existence of path segments"
content_type: support
description: Use a `Template` value on the Route Transformer Advanced plugin to route requests to different upstream hosts based on the presence of a path segment.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I route a request to a different host based on the presence of a path segment?
  a: |
    Configure a Route with a regex capture group (for example `~/(v1/api/.*)`) and use the Route Transformer Advanced plugin's `host` field with a `Template` value.
    The template inspects `uri_captures` and returns a different upstream host depending on whether the segment is present.
---

## Problem

We would like to be able to route a request to different hosts using the Route Transformer Advanced plugin. However, the route path will change based on the presence of a particular URL segment. For example:

- a path of `/v1/api/<anything>` should route to `httpbin.org`
- a path of `/v1/api/xml` should route to `mockbin.org`

How can this be accomplished?

## Solution

The Route Transformer Advanced plugin supports `Template` as a value, which allows custom code for this use case.

To properly handle this type of situation you will need to have a route configured with a RegEx capture group, in this example our route will be as follows:

```
~/(v1/api/.*)
```

This will allow us to capture all traffic to `/v1/api/*` and place it in an unnamed capture group.

We can then replace the host field of the Route Transformed Advanced plugin with the following template:

```lua
$((function()
  local uri = uri_captures[1]
  if uri:match("xml") then
     return "mockbin.org"
  else
    return "httpbin.org"
   end
end)())
```

To avoid false positives of "xml" appearing anywhere in the URL, i.e.: `/thisisxml/`

you could alternatively match against just the segment

```lua
$((function()
  local uri = uri_captures[1]
  if uri:match("/xml/") then
     return "mockbin.org"
  else
    return "httpbin.org"
   end
end)())
```

NOTE: This code is provided solely as a guide and is not considered to be production ready without further testing in your environment. As always, this should be validated in lower environments before promoting.
