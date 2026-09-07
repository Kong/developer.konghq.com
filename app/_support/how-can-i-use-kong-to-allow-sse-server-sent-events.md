---
title: Configuring Kong Gateway to support SSE (Server-Sent Events)
content_type: support
description: SSE connections through Kong Gateway need enough `read_timeout` headroom and disabled response buffering (via `X-Accel-Buffering: no`) to avoid premature connection termination or delayed delivery.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Service object reference
    url: /gateway/entities/service/
tldr:
  q: How can I use Kong to allow SSE (Server-Sent Events)?
  a: |
    SSE just needs a normal Service/Route through Kong Gateway, but two settings matter: raise the Service's `read_timeout` so Kong doesn't close long-lived SSE connections early, and have your upstream send `X-Accel-Buffering: no` so Kong doesn't buffer (and delay) the event stream — don't disable proxy buffering globally.
---

## Overview

Server-Sent Events (SSE) is a standard that allows browser clients to receive a stream of updates from a server over an HTTP connection. To support SSE with Kong Gateway, configure a Service and Route to handle HTTP requests passing through Kong Gateway.

When proxying SSE connections, ensure the request does not exceed the configured proxy read timeout; otherwise, Kong Gateway will terminate the upstream connection. You can adjust this setting with the Service entity's `read_timeout` property (there is no field literally named `upstream_read_timeout`). For more details, see the Service object reference documentation.

Buffering can cause issues with SSE. To prevent this, do not disable proxy buffering globally using Nginx directives. Instead, have your upstream service send the `X-Accel-Buffering: no` response header for SSE connections. This explicitly disables buffering for those responses when proxied through Kong Gateway.
