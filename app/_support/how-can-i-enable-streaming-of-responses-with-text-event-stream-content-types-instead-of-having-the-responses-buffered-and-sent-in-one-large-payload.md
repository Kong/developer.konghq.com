---
title: "Enabling streaming of responses with `text/event-stream` content-types instead of buffering them into one large payload"
content_type: support
description: To stream responses with the `text/event-stream` content type instead of having them buffered, disable response body buffering on the specific route by setting `response_buffering` to `false`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "How can I enable streaming of responses with `text/event-stream` content-types, instead of having the responses buffered and sent in one large payload?"
  a: |
    Disable response body buffering on the affected route by setting `response_buffering` to `false` (via a `PATCH` to the Admin API, or in Kong Manager on 3.x+). Kong buffers responses by default because Nginx `proxy_buffering` is on, so turning it off lets `text/event-stream` responses stream from the upstream as they arrive.
related_resources: []
---

## Overview

How can I enable streaming of responses with `text/event-stream` content-types, instead of having the responses buffered and sent in one large payload?

## Steps

To address the issue of responses being buffered and sent in one large payload through Kong (for example, Azure OpenAI endpoint payloads), especially when the content type of the response is `text/event-stream`, you can disable response body buffering for the specific route in question.

Nginx has a feature called `proxy_buffering` which enables the buffering of responses, and is set to `true` by default.

Here are the steps to disable response buffering on a route:

1. Identify the route for which you want to disable response buffering. You can do this by accessing your Kong Admin API or Kong Manager UI and listing all routes associated with the service that communicates with the streaming server.

2. Once you have identified the route and its ID, you need to update its configuration to disable response buffering. This can be done by making a `PATCH` request to the Kong Admin API with the `response_buffering` property set to `false`.

Here is an example of how to disable response buffering using a curl command:

```bash
curl 'https://kong.admin.api:8444/default/routes/<route-id>' \
  -X 'PATCH' \
  -H 'Content-Type: application/json' \
  -H "kong-admin-token:<RBAC TOKEN>" \
  --data-raw '{"response_buffering": false}'
```

There is also an option in Kong Gateway Manager to disable `response_buffering` if using Kong 3.x+.

After applying this change, Kong will no longer buffer the responses for the specified route, allowing the responses to be streamed from the upstream server endpoints.

By following these steps, you should be able to configure your service to stream responses directly, avoiding the delay caused by buffering large responses.
