---
title: "{{site.base_gateway}}: Proxy Caching Advanced plugin always bypasses the cache and hits the API"
content_type: support
description: "The Proxy Caching Advanced plugin may always bypass the cache and hit the API if the upstream response's content type is not included in the plugin's configuration."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "{{site.base_gateway}}: Why is the Proxy Caching Advanced plugin always bypassing the cache and hitting the API?"
  a: |
    The Proxy Caching Advanced plugin bypasses the cache (shown by the `x-cache-status: bypass` response
    header) when the upstream response's content type is not included in the plugin's configuration. Check
    the upstream content type with `curl -v`, then update the plugin configuration to include that content
    type. For large responses you may also need to adjust NGINX buffer sizes (for example,
    `KONG_NGINX_HTTP_PROXY_BUFFERS="8 16k"`). Verify the fix by confirming `x-cache-status` shows `HIT` on
    repeated requests.
related_resources: []
---

## Problem

The Proxy Caching Advanced plugin always hits the API instead of caching, as indicated by the `x-cache-status: bypass` header in the response.

## Cause

The Proxy Caching Advanced plugin bypasses the cache and hits the API when the upstream response's content type is not included in the plugin's configuration.

## Solution

1. Check the upstream content type using a tool like `curl -v`.
2. Update the plugin configuration to include that content type.
3. (Optional) Adjust NGINX buffer sizes if you're dealing with large responses:

   ```bash
   KONG_NGINX_HTTP_PROXY_BUFFERS="8 16k"
   ```
4. Test the fix by checking if `x-cache-status` shows `HIT` on repeated requests.

Ensuring the plugin is configured with the correct content types is the key to enabling proper caching behavior.
