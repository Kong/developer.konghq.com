---
title: "{{site.base_gateway}}: Retaining the browser cookie when forwarding a request through a post-function plugin"
content_type: support
description: When a request is forwarded through a Kong post-function plugin, the browser Cookie may not be retained; use pre-function and post-function plugins with kong.ctx.shared to capture and forward the Cookie header.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "{{site.base_gateway}}: How can I ensure that a request forwarded through a Kong post-function plugin retains the Cookie passed from the browser?"
  a: |
    The `Cookie` header is not retained because the request handling does not propagate it to the upstream
    service. Use a `pre-function` plugin to capture the header and store it in shared context with
    `kong.ctx.shared.cookie = kong.request.get_header("Cookie")`, then use a `post-function` plugin to set it
    on the upstream request with `kong.service.request.set_header("Cookie", kong.ctx.shared.cookie)`. Because
    `kong.ctx.shared` is specific to the current request, Cookies from concurrent requests are handled
    without interference.
related_resources: []
---

## Problem

When a request is forwarded through a Kong `post-function` plugin, the `Cookie` passed from the browser is not retained, leading to unauthorized errors due to the missing cookie information.

## Cause

This problem can arise when the request handling does not correctly propagate the `Cookie` header to the upstream service.

## Solution

You can use a combination of `pre-function` and `post-function` plugins to capture and forward the `Cookie` header correctly. To implement this solution, follow these steps:

1. Use the `pre-function` plugin to store the `Cookie` in a shared context (`kong.ctx.shared`):

   In the `pre-function` plugin, capture the `Cookie` header from the incoming request and store it in the shared context. This makes the `Cookie` available across different phases of the request processing.

   ```lua
   kong.ctx.shared.cookie = kong.request.get_header("Cookie")
   ```

   Or, use a specific cookie name rather than the entire cookie header:

   ```lua
   kong.ctx.shared.session_cookie = ngx.var.cookie_session
   ```

2. Retrieve the `Cookie` from the shared context in the `post-function` plugin and set it in the request to the upstream service:

   In the `post-function` plugin, retrieve the `Cookie` from the shared context and set it as a header in the request being forwarded to the upstream service.

   ```lua
   kong.service.request.set_header("Cookie", kong.ctx.shared.cookie)
   ```

This approach ensures that the `Cookie` passed from the browser is retained and forwarded correctly through the `post-function` plugin, allowing the request to be authenticated and authorized by the upstream service.

The shared context (`kong.ctx.shared`) is specific to the current request, which ensures that Cookies from concurrent requests are handled correctly without interference.

This code snippet is a basic example and requires review before you implement it in any environment. Do not use this code without thorough testing. Depending on your specific requirements and setup, you might need to add additional error handling or logic to suit your needs.
