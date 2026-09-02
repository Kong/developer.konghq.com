---
title: "{{site.base_gateway}}: How to remove portion of path leaving and sending remainder to backend"
content_type: support
published: false
description: "To accomplish this we can use capture groups and then the request transformer advanced plugin to trip the \"/test/api\"."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I remove a portion of the request path in {{site.base_gateway}} and send only the remainder to the backend?
  a: |
    Use a capture group in the route's path regex to capture the segment you want to keep, for example `~/test/api/(?<validtest>v2/validtest2)`. Then set `config.replace.uri` on the Request Transformer Advanced plugin to `/$(uri_captures['validtest'])` so only the captured portion of the path is sent upstream.
---

## {{site.base_gateway}}: How to remove portion of path leaving and sending remainder to backend

We are looking to use 1 service and 2 routes. Each route will point to the same service and have different paths. However, our backend will handle each route differently.

We are currently using the following paths:

```
/test/api/validtest1
/test/api//v2/validtest2
```
We only need "validtest1" or "validtest2" sent to the backend.

How can we remove "test/api" from the request without distorting the routes?

To accomplish this we can use capture groups and then the request transformer advanced plugin to trip the "/test/api".

Example:

Route 1:

```
~/test/api/(?<validtest>/validtest1)
```
Route 2:

```
~/test/api/(?<validtest>v2/validtest2)
```
On the Request Transformer Advanced plugin we can set the following:

`config.replace.uri`:

```
/$(uri_captures['validtest'])
```
Now when you proxy requests to either of these 2 routes, the data entered into the capture group will only be sent to the upstream.
