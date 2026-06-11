---
title: "{{site.base_gateway}}: Fixing the 'Invalid Nginx Configuration' error when enabling `nginx_proxy_brotli` in kong.conf"
content_type: support
description: "When configuring `nginx_proxy_brotli` in your `kong.conf`, you might encounter an error that prevents successful deployment, stating that the nginx configuration is invalid."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why do I get an "Invalid Nginx Configuration" error when enabling `nginx_proxy_brotli` in kong.conf?
  a: |
    This error is typically caused by incorrectly quoting the MIME type values in the
    `nginx_proxy_brotli_types` directive. To resolve it, remove the quotes around the MIME type values so
    the types are listed unquoted, for example
    `nginx_proxy_brotli_types = text/plain text/css application/json ...`.
related_resources: []
---

## Problem

When configuring `nginx_proxy_brotli` in `kong.conf`, you might encounter an error that prevents successful deployment, stating that the nginx configuration is invalid.

## Cause

This issue is typically related to how the `nginx_proxy_brotli_types` directive is formatted in the configuration file. Incorrectly quoting the MIME type values can lead to nginx configuration errors.

## Solution

To resolve this issue, adjust the `nginx_proxy_brotli_types` directive in your `kong.conf` file by removing the quotes around the MIME type values.

Here is an example of how to correctly format the `nginx_proxy_brotli_types` directive in your `kong.conf`:

```bash
nginx_proxy_brotli = on
nginx_proxy_brotli_comp_level = 5
nginx_proxy_brotli_types = text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript text/x-js
```

Notice that the MIME types are not enclosed in quotes. This format should prevent the nginx configuration error.
