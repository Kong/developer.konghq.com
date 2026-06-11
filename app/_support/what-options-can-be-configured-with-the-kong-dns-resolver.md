---
title: Configurable options for the Kong DNS resolver
content_type: support
description: "The Kong DNS resolver supports the rotate, ndots, timeout, and attempts options, which can be overridden using the RES_OPTIONS environment variable."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: What options can be configured with the Kong DNS resolver?
  a: |
    The `RES_OPTIONS` environment variable can be used to override the following DNS resolver options:

    ```
    rotate
    ndots
    timeout
    attempts
    ```

    For additional details on these settings, refer to the documentation for `resolv.conf`.
related_resources:
  - text: DNS resolver section
    url: /reference/configuration/#dns-resolver-section
  - text: resolv.conf documentation
    url: https://man7.org/linux/man-pages/man5/resolv.conf.5.html
---

## Problem

I see in the Kong documentation that the `RES_OPTIONS` environment variable can be used to override certain options. What options are currently supported?

## Solution

The below options can be set:

```
rotate
ndots
timeout
attempts
```

For additional details on these settings please refer to the documentation for resolv.conf.
