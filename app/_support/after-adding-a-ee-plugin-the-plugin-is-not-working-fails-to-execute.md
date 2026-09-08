---
title: "After adding an EE plugin, the plugin is not working/fails to execute"
content_type: support
description: Kong Enterprise plugins such as `mtls-auth` or `rate-limiting-advanced` silently no-op on the Data Plane when it lacks a valid Enterprise license.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does an Enterprise plugin (for example `mtls-auth` or `rate-limiting-advanced`) silently no-op instead of running?
  a: |
    Kong Enterprise plugins require a valid license on the Data Plane; without one, EE plugins are skipped ("nop'd") and a debug log line reports it. In a Hybrid deployment, license the Control Plane via the Admin API `/licenses` endpoint so it distributes the license to Data Planes automatically. If you instead set the license via `license_data` or `license_path`, you must configure it explicitly on every Data Plane.
related_resources:
  - text: documentation for deploying the license
    url: /gateway/licenses/deploy/
---

## Problem

After adding an EE plugin, for example `mtls-auth`, the plugin is not working/fails to execute. For this example, the client application can call the endpoint without passing a client certificate and the request succeeds.

As another example, adding a `rate-limiting-advanced` plugin, the requests are not rate limited.

In the logs, there are debug level messages for the plugins that say the plugin is "nop'ing" (no operation). For example;

```

kong-data-plane | 2024/07/04 10:13:25 [debug] 2435#0: *3273 [kong] certificate.lua:26 [mtls-auth] enabled, will request certificate from client
kong-data-plane | 2024/07/04 10:13:25 [debug] 2435#0: *3272 [lua] init.lua:310: calling patched method 'mtls-auth:access'
kong-data-plane | 2024/07/04 10:13:25 [debug] 2435#0: *3272 [lua] init.lua:312: nop'ing 'mtls-auth:access, ee_plugins[READ]=false
kong-data-plane | 2024/07/04 10:13:25 [debug] 2435#0: *3272 [lua] init.lua:310: calling patched method 'rate-limiting-advanced:access'
kong-data-plane | 2024/07/04 10:13:25 [debug] 2435#0: *3272 [lua] init.lua:312: nop'ing 'rate-limiting-advanced:access, ee_plugins[READ]=false
```

## Cause

When using a Kong Enterprise plugin, the Data planes require a valid license. If no license is present for the Data plane, then EE plugins will not be run and the "no operation" message will be written to the logs.

## Solution

In a Hybrid deployment topology, it is recommended to use the Admin API `/licenses` endpoint to license a Kong installation. This ensures that the Control plane will send the license to the Data planes.

If the license is configured using either `license_data` or `license_path`, then the Control plane will not send the license to the Data planes. This means that it is necessary to configure the license explicitly on all Data planes.

Further details for deploying the license can be found in the documentation.
