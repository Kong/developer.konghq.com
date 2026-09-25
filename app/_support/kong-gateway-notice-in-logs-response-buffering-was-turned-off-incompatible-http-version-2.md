---
title: "Kong Gateway: Notice in logs: \"response buffering was turned off: incompatible HTTP version (2)\""
content_type: support
description: This informational message in the logs comes from the Nginx layer.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: 'Why does Kong Gateway log "response buffering was turned off: incompatible HTTP version (2)", and does it need action?'
  a: |
    This is an informational Nginx/Kong log message, not an error. It appears when Kong Gateway turns buffered proxying back off for a request, most commonly during a connection upgrade such as a WebSocket request. On current Kong Gateway, the `"incompatible HTTP version (2)"` variant specifically should not occur, since `kong.service.request.enable_buffering()` and a plugin's `response` handler both work correctly over HTTP/2. If you're not seeing any impact and just want it out of your logs, raise the log level to `warn`, since there's no way to suppress this one notice specifically.
---

## Problem

I am using the Kong Gateway and in reviewing the logs recently I discovered this notice appearing frequently:

```

[notice] 5094#0: *6462968 [lua] init.lua:984: access(): response buffering was turned off: incompatible HTTP version (2)
```

What is the reason for this message and do I need to be concerned by it? How do we get this out of our logs?

## Cause

This informational message in the logs comes from the Nginx/Kong core layer. It is meant to inform the reviewer that Kong Gateway had activated buffered proxying (for example because a plugin implements a `response` handler, or a plugin explicitly calls `kong.service.request.enable_buffering()`) but then had to turn it back off for the current request.

## Solution

This should cause
no impact to most traffic, which is why it's only logged at "notice" level. The requests & responses are still processed as expected without buffering. On Kong Gateway 3.14.0.0, the only condition that turns buffered proxying back off is a **connection upgrade** (e.g. a WebSocket `Upgrade` request), which logs the message:

```

[notice] ...: [lua] init.lua:...: access(): response buffering was turned off: connection upgrade (websocket)
```

If you are instead seeing the `"incompatible HTTP version (2)"` variant shown above, note that on current Kong Gateway, `kong.service.request.enable_buffering()` and the automatic buffered-proxy mode a plugin's `response` handler activates both work correctly over an HTTP/2 downstream connection, so that specific message should not occur.

However there may be some cases where this can cause issues in the event that a custom plugin is relying on response buffering, which may cause a custom plugin to fail on an upgraded connection. If you are using a custom plugin which relies on response buffering, please look to improve the resiliency of the custom plugin so that it's not 100% dependent on the buffering of responses on an upgraded connection. Please note that writing code for custom plugins falls outside the scope of Kong Support, however our Professional Services team can be hired for custom plugin work.

If this is causing immediate issues and is high-impacting on a connection-upgrade scenario, the following are some possible short-term workarounds:

- Avoid relying on response buffering for traffic that uses a `Connection: Upgrade` (e.g. WebSocket) request.
- Route non-upgraded traffic separately from upgraded traffic (e.g. via a load balancer or client-side change) if the two need different buffering behavior.

If you are not having any impact but want to simply prevent this from being logged, then you will need to consider changing the log level to `warn` instead of the default `notice`. There is no way to remove this message in particular, the `log_level` property will need to be adjusted for the system.
