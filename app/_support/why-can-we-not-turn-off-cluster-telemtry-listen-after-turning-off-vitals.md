---
title: Cannot turn off `cluster_telemetry_listen` after disabling Vitals
content_type: support
published: false
description: "The `cluster_telemetry_listen_endpoint` is used by the data planes to send both vitals data and license report counter data."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why can we not turn off `cluster_telemetry_listen` after turning off vitals?
  a: |
    Even when Vitals is disabled, data planes still use the endpoint configured by `cluster_telemetry_listen` to send license report counter data back to the control plane, so `cluster_telemetry_listen` cannot be set to `off`. Attempting to do so causes the control plane to fail to start with `cluster_telemetry_listen must be specified when role = "control_plane"`.
related_resources: []
---

## Problem

We have deployed Kong in hybrid mode, and have decided to not use Kong Vitals so have set the `vitals` property or `KONG_VITALS` variable on both the control plane, and data plane components to `off`.

After doing so, we tried to also turn off the `cluster_telemetry_listen` property on the control plane but this results in the following error preventing the control plane from starting:

```
Error: cluster_telemetry_listen must be specified when role = "control_plane"
```

## Solution

The `cluster_telemetry_listen_endpoint` is used by the data planes to send both vitals data and license report counter data. Therefore, even when Vitals is disabled, the data planes still need to send license report counter data back to the control plane over `cluster_telemetry_listen_endpoint`, so `cluster_telemetry_listen` cannot be set to `off`.
