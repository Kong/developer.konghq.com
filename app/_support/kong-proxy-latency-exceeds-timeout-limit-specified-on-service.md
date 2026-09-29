---
title: "`x-kong-proxy-latency` header exceeds the timeout limit specified on the service"
content_type: support
description: Kong's `x-kong-proxy-latency` header keeps climbing beyond the configured timeout because Kong retries a slow upstream according to the service's `retries` setting, adding each retry's latency to the total.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does the `x-kong-proxy-latency` header exceed the timeout configured on my service?
  a: |
    Kong retries a slow upstream according to the service's `retries` setting when the initial attempt exceeds the configured timeout, and each retry adds to the total latency reported in `x-kong-proxy-latency`. This is expected behavior — review your `retries` and timeout settings to match your use case.
---

## Problem

Our services upstream is set to 60000ms (60 seconds). If our service delays for 70 seconds, we notice that Kong returns a 504 after about 5 minutes from 1 request. What is causing this behavior and how do we get Kong to time out after 60 seconds like it is specified?

Example Configuration:

`x-kong-proxy-latency` records about 5 minutes worth of delays.

```
x-kong-proxy-latency: 300007
```

## Cause

If Kong can't access the upstream in the allotted time frame (in this case 60000ms), it will retry the request based on the `retries` configuration on the service.

If `retries` is set to 5, then it will attempt to access the upstream 5 more times, causing the header value for `x-kong-proxy-latency` to increase on each retry.

For example, if `retries` is set to 1, you'll get the following:

```
x-kong-proxy-latency: 60006
```

## Solution

This is expected behavior. To tune your settings, discuss internally to determine if your timeout and `retries` are set correctly for your use case.
