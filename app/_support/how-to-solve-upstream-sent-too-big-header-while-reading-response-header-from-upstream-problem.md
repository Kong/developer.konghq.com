---
title: "\"upstream sent too big header while reading response header from upstream\" error when response headers exceed the Nginx proxy buffer size in {{site.base_gateway}}"
content_type: support
description: These logs will be written when the headers sent by the upstream are too large for the Nginx proxy buffer size set in the Nginx layer in {{site.base_gateway}}.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does {{site.base_gateway}} log "upstream sent too big header while reading response header from upstream"?
  a: |
    This error means the upstream's response headers are larger than Kong's Nginx proxy buffer size, so the response is rejected and the request fails. Increase the buffer size by setting both `KONG_NGINX_PROXY_PROXY_BUFFER_SIZE` and `KONG_NGINX_PROXY_PROXY_BUFFERS` (both must be set together) to values larger than what your environment needs, for example `16k` and `4 16k` instead of the defaults `4k` and `8 4k`.
---

## Problem

{{site.base_gateway}} logs show the following error:

```

upstream sent too big header while reading response header from upstream
```

## Cause

These logs will be written when the headers sent by the upstream are too large for the Nginx proxy buffer size set in the Nginx layer in {{site.base_gateway}}. The response is effectively rejected and requests may error out / fail in this situation.

## Solution

To solve this problem, the following environment variables can be added to the Kong deployment configuration to increase the buffer size for the environment: `KONG_NGINX_PROXY_PROXY_BUFFER_SIZE` and `KONG_NGINX_PROXY_PROXY_BUFFERS`. Both must be set together - setting only `proxy_buffer_size` without also setting `proxy_buffers` will cause Kong to fail to start entirely. The values of these properties should be set a bit larger than what is needed in the environment. For example, setting `proxy_buffer_size` to `16k` and `proxy_buffers` to `4 16k` may be useful, compared to the defaults of `4k` and `8 4k` respectively. For details on what the `proxy_buffer_size` and `proxy_buffers` Nginx directives do specifically, they are outlined in the official Nginx HTTP Proxy module documentation. For instructions on injecting Nginx directives to the {{site.base_gateway}} nodes, please review the {{site.base_gateway}} Nginx Directives documentation.
