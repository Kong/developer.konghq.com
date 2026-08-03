---
title: Instability when Dynatrace is enabled in Kong Gateway
content_type: support
description: "Kong Gateway can become unstable, with random restarts and crashes, when the third-party Dynatrace OneAgent is enabled; upgrading to OneAgent 1.245 or later, which added Kong Gateway support, resolves most cases."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Kong Gateway become unstable when Dynatrace is enabled?
  a: |
    Dynatrace is a third-party, unsupported integration. Some Dynatrace OneAgent versions caused Kong Gateway crashes, random restarts, and slower performance — this was more common before OneAgent 1.245, which added Kong Gateway support. Upgrade to OneAgent 1.245 or later, and contact Dynatrace support if issues persist.
---

## Problem

I want to use Dynatrace and have integrated it inside Kong Gateway however since that time I have noticed the stability of Kong Gateway has decreased with intermittent restarts and other unintentional behavior.

We see the following in the logs in the Control Plane (CP):

```
2026/12/15 13:38:48 [notice] 1#0: start worker process 437
2026/12/15 13:38:48 [notice] 1#0: signal 29 (SIGIO) received
2026/12/15 13:38:51 [notice] 1#0: signal 17 (SIGCHLD) received from 436
2026/12/15 13:38:51 [alert] 1#0: worker process 436 exited on signal 11
2026/12/15 13:38:51 [notice] 1#0: start worker process 442
```

We see the following in the logs in the Data Plane (DP):

```
2026/12/15 13:38:54 [error] 2087#0: *5819 [lua] init.lua:373: error while receiving frame from peer: failed to receive the first 2 bytes: closed, context: ngx.timer
```

## Cause

Dynatrace is a third-party software tool that typically works fine with Kong Gateway, however there have been issues seen when Dynatrace is enabled, such as random restarts/reboots and crashes, or slower performance. Kong does not officially offer support for integrating Dynatrace, as it is third-party and untested, so using Dynatrace is done at your own risk. This was a more frequent issue before the release of version 1.245 of Dynatrace's OneAgent, which added support for Kong Gateway from Dynatrace's software.

## Solution

If using Dynatrace, it is recommended to use the latest version possible, or at least a version from 1.245 and newer. If these issues are still seen after adding Dynatrace even after 1.245 of their OneAgent, then Kong recommends contacting the Dynatrace support team for further support, as Kong does not offer support for using Dynatrace within Kong products at this time.
