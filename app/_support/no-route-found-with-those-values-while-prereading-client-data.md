---
title: "\"no Route found with those values while prereading client data\" error when a TCP connection doesn't match any route"
content_type: support
description: "This error is the TCP equivalent of \"no Route matched with those values,\" indicating that no suitable route was found for the connection."
products:
  - gateway
  - kic
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Kong Gateway log "no Route found with those values while prereading client data" for a TCP connection?
  a: |
    This is the TCP equivalent of "no Route matched with those values" — the connection was accepted, but its source, destination, or SNI didn't match any configured route. For TLS SNI-based `TCPIngress` routing, confirm the route's expected host header (for example `example.com`) and that the `TCPIngress` resource was created successfully and is associated with the correct `IngressClass`.
---

## Problem

When consuming a TCP route on Gateway you notice the connection is terminated and the below message is logged:

```
2025/10/31 13:41:03 [error] 2135#0: *702 stream [lua] handler.lua:1249: before(): no Route found with those values while prereading client data, client: 192.168.59.1, server: 0.0.0.0:9000
```

How can this be resolved?

## Solution

This error is the TCP equivalent of "no Route matched with those values," indicating that no suitable route was found for the connection. In the same log, you should see an entry just before the error showing a connection established to confirm port connectivity to the Gateway.

```
2025/10/31 13:41:03 [info] 2135#0: *702 client 192.168.59.51:48836 connected to 0.0.0.0:9000
```

Provided the connection was established, this error occurs when the source, destination, or SNI does not match any configured route. For example, a route may require a host header like `example.com`, as with TLS SNI-based routing in `TCPIngress`.

When using `TCPIngress` on Kubernetes, ensure the `TCPIngress` resource has been successfully created and is associated with the correct `IngressClass`. Reviewing the ingress controller logs can provide additional insight.
</content>
