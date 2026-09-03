---
title: How to proxy request to a specific upstream path when the upstream root path already exists by using `request-transformer` plugin
content_type: support
description: This article shows how to create a dynamic route path by using the `request-transformer` plugin.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: request-transformer plugin documentation
    url: /plugins/request-transformer/
tldr:
  q: How do I route a request to a specific upstream path when the Route already points to the upstream's root path?
  a: |
    Use the `request-transformer` plugin with a regex capture group on the Route path, then set `Config.Replace.Uri` to `/$(uri_captures.g1)` so Kong rewrites the request to the captured upstream path before proxying it.
---

## Overview

It is a common case that there are several routes pointing to one service. For example, assuming we are using an echo application as upstream and running it in `http://kong.example` for testing purpose. There is an existing service entity called `exampleservice` in Kong, and its URL parameter is defined as `http://kong.example`. And, we have a route entity with a path `/example`, and `strip_path: true`. This route will proxy requests to `http://kong.example` via Kong. Now, you'd like to enable a plugin only on `http://kong.example/api/v1/secret`. One method is to create another pair of service and route. But with Kong `request-transformer` plugin, you can realize it without creating a duplicated service entity of the same application.

## Steps

This article shows how to create a dynamic route path by using the `request-transformer` plugin.

1. Define the route path in regex format in the Route entity and point this route to the service `exampleservice`.

   In versions prior to 3.x:

   ```
   /example/(?<g1>api/v1/secret)
   ```

   In versions from 3.x onwards, regex paths have to be prefixed with `~`:

   ```
   ~/example/(?<g1>api/v1/secret)
   ```

2. Enable the `request-transformer` plugin for the route.

3. Set `Config.Replace.Uri` of the `request-transformer` plugin as below:

   ```
   /$(uri_captures.g1)
   ```

4. Test the settings. The request is transformed and sent to `/api/v1/secret` to your application.

   ```bash
   curl -i {kong proxy}/example/api/v1/secret
   HTTP/1.1 200 OK
   ....

   HTTP/1.1 GET /api/v1/secret. <--- request URI has been transformed to /api/v1/secret
   (echo application shows which path has been accessed as above)
   ```
