---
title: "How to retain the browser Cookie header when forwarding requests through the Post-Function plugin"
content_type: support
description: When a request is forwarded through a Post-Function plugin, the browser Cookie header may not be retained. Use Pre-Function and Post-Function plugins with kong.ctx.shared to capture and forward the Cookie header.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "How can I ensure that a request forwarded through a {{site.base_gateway}} Post-Function plugin retains the cookie passed from the browser?"
  a: |
    The `Cookie` header isn't propagated to the upstream service automatically.
    Use a Pre-Function plugin to capture it into `kong.ctx.shared`, then a Post-Function plugin to set it on the upstream request.
related_resources:
  - text: Pre-Function plugin
    url: /plugins/pre-function/
  - text: Post-Function plugin
    url: /plugins/post-function/
---

## Problem

When a request is forwarded through a `post-function` plugin, the `Cookie` header passed from the browser is not retained, causing authorization errors on the upstream service.

## Cause

The request handling does not propagate the `Cookie` header to the upstream service.

## Solution

Use a Pre-Function plugin and a Post-Function plugin together to capture and forward the `Cookie` header.

1. Use the Pre-Function plugin to store the `Cookie` in a shared context (`kong.ctx.shared`).

   Capture the `Cookie` header from the incoming request and store it in the shared context.
   This makes the `Cookie` available across different phases of request processing.

   ```lua
   kong.ctx.shared.cookie = kong.request.get_header("Cookie")
   ```

   Or, to capture a specific cookie by name instead of the entire header:

   ```lua
   kong.ctx.shared.session_cookie = ngx.var.cookie_session
   ```

2. Retrieve the `Cookie` from the shared context in the Post-Function plugin and set it as a header on the upstream request.

   In the Post-Function plugin, retrieve the `Cookie` from the shared context and set it as a header in the request being forwarded to the upstream service.

   ```lua
   kong.service.request.set_header("Cookie", kong.ctx.shared.cookie)
   ```

This approach ensures that the `Cookie` passed from the browser is retained and forwarded correctly through the Post-Function plugin, allowing the upstream service to authenticate and authorize the request.

Because `kong.ctx.shared` is scoped to the current request, cookies from concurrent requests are handled without interference.

{:.warning}
> **Warning**: This code snippet is a basic example and requires review before you implement it in any environment. Do not use this code as-is; review and test this code thoroughly before using it in any environment.
> Depending on your requirements, you may need to add error handling or additional logic.
