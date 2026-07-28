---
title: "Kong Gateway: Performance impact of setting the `headers` configuration parameter to `latency_tokens`"
content_type: support
published: false
description: This value will have no impact on performance when enabled.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Is there a performance impact from setting the `headers` configuration parameter to `latency_tokens` in Kong Gateway?
  a: |
    No. The latency values are always calculated regardless of this setting — the `headers` flag only controls whether that value is actually added to the request or not.
related_resources:
  - text: Kong Gateway configuration reference - headers
    url: /gateway/configuration/#headers
---

## Kong Gateway: Is there any performance impact from setting configuration parameter `headers` to `latency_tokens`

We are looking to enable the configuration parameter `headers` to `latency_tokens` on our production servers. Is there any risk or performance impact by enabling this setting?

This value will have no impact on performance when enabled. Reason being is the values are always calculated, regardless. The `headers` flag indicates if the header is actually added to the response or not.
