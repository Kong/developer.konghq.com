---
title: Unable to mark Upstream targets as healthy or unhealthy via Kong manager
content_type: support
description: Kong Manager returns a 400 error when marking Upstream targets healthy or unhealthy because active health checks are not enabled on the upstream.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why do I get a 400 error when trying to mark Upstream targets healthy or unhealthy in Kong Manager?
  a: |
    Kong Manager returns a 400 `no healthchecker found` error when marking a target healthy or unhealthy because active health checks aren't enabled on the upstream — the default healthy/unhealthy check intervals are `0`, which disables health checks entirely.

    Set `Healthchecks.Active.Healthy.Interval` and `Healthchecks.Active.Unhealthy.Interval` to a non-zero interval, then you can mark targets as healthy or unhealthy.
related_resources: []
---

## Problem

Get the below error when trying to mark Upstream targets healthy/unhealthy via Kong manager (this uses a `PUT` request to the Upstream's health endpoint)

```

HTTP/1.1 400 Bad Request
{"message":"no healthchecker found for example-upstream"}
```

Note: on a hybrid-mode Data Plane, this endpoint isn't available at all and the request will 404, since Data Planes don't expose this part of the Admin API. This only applies to standalone nodes or a Control Plane.

## Cause

The reason to get 400 is that neither the active healthy check nor the active unhealthy check is enabled in your upstream. The default values of healthy or unhealthy check intervals are 0, which means the health checks are totally disabled.

## Solution

Please set up `Healthchecks.Active.Healthy.Interval` and `Healthchecks.Active.Unhealthy.Interval` to your desired time. After that, you can mark a target as unhealthy or healthy. Besides, we're working on a more user-friendly Kong Manager upstream dashboard to provide more instructions on it.
