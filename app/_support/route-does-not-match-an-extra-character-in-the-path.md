---
title: "Route does not match an extra `/` character in the path"
content_type: support
description: "How to configure a route so an extra slash character in the request path doesn't cause Kong to match the wrong route, using a regex `+` modifier."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Kong match the wrong route when a request path has an extra slash character?
  a: |
    Kong matches the first route whose path matches; if two routes share a root path (e.g. `/foo` and `/foo/bar`) and the request has an extra `/` (e.g. `/foo//bar`), Kong matches the shorter route. Use the regex `+` modifier on the trailing slash in the more specific route's path (e.g. `/+foo/+bar`) so it matches one or more slash characters and takes precedence.
---

## Problem

If there are two routes that have the same root for the URI path, for example:

1. `/foo`
2. `/foo/bar`

When a request is sent with extra slash in the path, "/foo//bar", then Kong matches the first route. How can the extra `/` character be ignored so the request matches the second path?

## Solution

You need to write the second route to exactly match any trailing slash for the second route to match it. The best way to do this is using the regex `+` modifier. This modifier will match one or more trailing characters, which in this case is the `/` character.

The route should be configured as below:

```
/+foo/+bar
```
