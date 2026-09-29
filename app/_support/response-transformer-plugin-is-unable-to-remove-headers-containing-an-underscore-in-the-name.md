---
title: Response Transformer plugin is unable to remove headers containing an underscore in the name
content_type: support
description: "How to work around the Response Transformer plugin's inability to remove response headers that contain an underscore in the name, using the `nginx_http_more_clear_headers` directive."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why can't the Response Transformer plugin remove a response header that contains an underscore in its name?
  a: |
    This is a known limitation of the Response Transformer plugin. As a workaround, add `nginx_http_more_clear_headers = X_myheader` to your `kong.conf` or environment settings, where `X_myheader` is the header name to remove (multiple headers can be comma-separated).
---

## Problem

When attempting to remove a response header that contains an underscore in the name, the Response Transformer plugin is not removing the header. All other headers that do not contain the underscore are successfully removed.

## Solution

The plugin is currently unable to remove a header containing an underscore in the name. However, as a workaround, the following can be added to your `kong.conf` or environment settings:

```
nginx_http_more_clear_headers = X_myheader
```

Where `X_myheader` is the name of the header to remove. Multiple headers can be specified in a comma separated list.
