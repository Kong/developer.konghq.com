---
title: "{{site.base_gateway}}: Connections intended for websocket route are routing to HTTP routes"
content_type: support
published: false
description: To force the request to use the websocket route we need to add some differentiator to the route.
tldr:
  q: Why do connections intended for my websocket route get routed to an equivalent HTTP route instead?
  a: |
    When two routes are otherwise identical, Kong's route priority matching can send the request to the HTTP route.
    Add a differentiator such as the `Upgrade: websocket` header to the websocket route so it is prioritized.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: priority matching
    url: /gateway/entities/route/#priority-matching
---

## Problem

We have 2 identical routes configured. The only difference is one uses WSS and the other uses HTTP. When we are calling out the websocket route we have noticed that the equivalent HTTP route is being called in its place. If I reach out to the websocket endpoint directly the request is processed properly through the WSS protocol. How can we resolve this and force the connection to go to the websocket route.

## Solution

To force the request to use the websocket route we need to add some differentiator to the route.

One option is to add the header `Upgrade: websocket` to the route.

When curling the 2 routes now it will prioritize the request that contains the header `upgrade: websocket` to the WSS route. This behavior is governed by Kong's route priority matching.
