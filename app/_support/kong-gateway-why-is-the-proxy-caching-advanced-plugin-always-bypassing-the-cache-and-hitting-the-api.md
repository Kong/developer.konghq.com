---
title: "Why the Proxy Caching Advanced plugin always bypasses the cache"
content_type: support
description: "The Proxy Caching Advanced plugin may always bypass the cache and hit the API if the upstream response's content type is not included in the plugin's configuration."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why is the Proxy Caching Advanced plugin always bypassing the cache and hitting the API?"
  a: |
    The upstream response's content type isn't included in the plugin's configuration.
    Check the content type with `curl -v`, then add it to the plugin config.
related_resources: []
---

## Problem

The Proxy Caching Advanced plugin always hits the API instead of caching, as indicated by the `x-cache-status: bypass` header in the response.

## Cause

The Proxy Caching Advanced plugin bypasses the cache and hits the API when the upstream response's content type is not included in the plugin's configuration.

## Solution

1. Check the upstream content type with `curl -v`.
2. Update the plugin configuration to include that content type.
3. (Optional) Adjust NGINX buffer sizes if you're dealing with large responses:

   ```bash
   KONG_NGINX_HTTP_PROXY_BUFFERS="8 16k"
   ```
4. Verify the fix by confirming `x-cache-status` shows `HIT` on repeated requests.

Ensuring the plugin is configured with the correct content types is the key to enabling proper caching behavior.
