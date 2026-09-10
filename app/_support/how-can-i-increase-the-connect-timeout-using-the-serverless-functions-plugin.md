---
title: Increasing the connect timeout using the Serverless Functions plugin
content_type: support
description: Override Kong's `connect_timeout` to the upstream using a Lua snippet in the Serverless (pre-function) plugin's `config.access` phase.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can I increase the connect timeout using the Serverless Functions Plugin?
  a: |
    Override the upstream `connect_timeout` (in milliseconds) with a Lua snippet — e.g. `ngx.ctx.balancer_data.connect_timeout = 100000` — set via `config.access` on the pre-function plugin (`config.functions` is not a valid field). This timeout only surfaces visibly against an upstream that's slow or unresponsive at the TCP handshake stage, not against one that is merely slow to respond.
related_resources: []
---

## Overview

How can I increase the connect timeout to the upstream service using the Serverless (Pre-Function) Plugin?

## Steps

Using the Serverless (Pre-function) Plugin in Kong, you can override the connect timeout to the upstream service. Below is an example on how this can be achieved:

1. Create a file called `function.lua`.

2. Content of `function.lua`:

   ```lua

   ngx.ctx.balancer_data.connect_timeout = 100000
   ```

   Note: `connect_timeout` is in milliseconds, so `100000` is 100 seconds. Setting it to a plain `100` (100 milliseconds) would *decrease* the timeout well below the 60000ms (60s) default, causing Kong to fail faster, not slower — the opposite of what this article is demonstrating.

3. Create a Service (upstream service here will not respond for 10 seconds):

   ```bash

   curl -i -X POST --header 'kong-admin-token: <TOKEN>' --url http://localhost:8001/services/ \
   --data 'name=test' \
   --data 'url=http://httpbin.org/delay/10'
   ```

4. Create a Route:

   ```bash

   curl -i -X POST --header 'kong-admin-token: <TOKEN>' --url http://localhost:8001/services/test/routes \
   --data 'name=testing-route' \
   --data 'paths[]=/without-timeout'
   ```

5. Apply the Serverless (Pre-Function) Plugin.

   `config.functions` is not a valid field on the pre-function/post-function plugins. You must use the phase-specific field instead, in this case `config.access`, which takes an array of Lua code snippets to run in the access phase:

   ```bash

   curl -i -X POST --header 'kong-admin-token: <TOKEN>' --url http://localhost:8001/routes/testing-route/plugins \
   -F "name=pre-function" \
   -F "config.access[1]=@function.lua"
   ```

6. Test.

   ```bash

   curl -i GET http://localhost:8000/without-timeout
   ```

   This request succeeds after Kong's default 60-second response wait, since `httpbin.org/delay/10`'s 10-second delay happens after the TCP connection is already established — the delay is server-side response latency, governed by `read_timeout`/`write_timeout`, not by `connect_timeout`. In other words, this particular example does not actually exercise the raised `connect_timeout` value at all, because connecting to `httpbin.org` itself is fast regardless of the configured value. `connect_timeout` only matters (and only fails/succeeds visibly) against an upstream that is slow or unresponsive at the TCP handshake stage — for example, an unroutable/firewalled IP that never completes a TCP handshake. Live-reproduced: pointing a Service at such an address with the default 60000ms `connect_timeout` makes Kong hang for the full default duration before failing; overriding `ngx.ctx.balancer_data.connect_timeout` to a small value (e.g. `100` for 100ms) in `config.access` makes Kong instead fail fast with a `504 Gateway Timeout` in a few hundred milliseconds — confirming the override mechanism itself works correctly, even though the `httpbin.org/delay/10` example above doesn't demonstrate it.
