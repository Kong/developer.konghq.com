---
title: "Kong Kubernetes Ingress Controller: Pods never ready in new installation of KIC/Proxy in IPV6 Kubernetes Cluster"
content_type: support
description: This was a documented KIC/IPv6 discovery defect, fixed since KIC 2.11.0, where a malformed IPv6 address in Admin API discovery kept pods from ever becoming ready.
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "Kong/kubernetes-ingress-controller PR #5139"
    url: https://github.com/Kong/kubernetes-ingress-controller/pull/5139
tldr:
  q: Why do Kong Ingress Controller pods never become ready on a fresh install in an IPv6-only Kubernetes cluster?
  a: |
    This was a KIC defect where a malformed, unbracketed IPv6 address in Admin API discovery caused connection failures and the resulting "no configuration available" readiness failure. It's fixed since KIC `2.11.0`; if you can't yet upgrade, remove `http2` from the proxy's `admin_listen` definition as a stopgap.
---

## Problem

We are attempting to fresh install a Kong Kubernetes Ingress Controller + Proxy in an IPV6 only Kubernetes cluster and our pods are never marking themselves as ready

We see the following errors:

Kubernetes Events:

```

Warning  Unhealthy  3m46s (x68 over 13m)  kubelet Readiness probe failed: HTTP probe failed with statuscode: 503
```

KIC Debug Logging:

```

time="2023-11-09T16:29:25Z" level=info msg="Retrying kong admin api client call after error" error="making HTTP request: Get \"https://2600:1f18:44f6:cf31:fcfe::1:8444/\": dial tcp [2600:1f18:44f6:cf31:fcfe::1]:8444: connect: connection refused" logger=setup retries=13/60
```

Proxy:

```

[notice] 2309#0: *343 [lua] ready.lua:118: fn(): not ready for proxying: no configuration available (empty configuration present), client: 2600:1f18:44f6:cf31:ecae:9306:34c1:8274, server: kong_status, request: "GET /status/ready HTTP/1.1", host: "[2600:1f18:44f6:cf31:fcfe::1]:8100"
```

## Cause

This was a documented defect with KIC + IPv6 discovery.

**This PR is no longer "planned" — it merged on 2023-11-10 and has shipped in every KIC release since 2.11.0** (the fix corrected KIC's Admin API discovery logic so IPv6 addresses are properly bracketed, e.g. `[2600:...::1]:8444`, instead of the malformed/unbracketed address that caused the `dial tcp` connection-refused errors and the resulting "no configuration available" readiness failure shown above). Current KIC releases (3.x, as used with Kong Gateway 3.14.0.0) already include this fix, so if you are running a current KIC version and still see this exact failure signature, the root cause is likely something else (verify your KIC version first, and check for any other IPv6-specific discovery/connectivity issue rather than assuming this same bug). This environment does not have a real IPv6-only Kubernetes cluster available, so the fixed behavior could not be re-reproduced end-to-end live — this correction is based on the merged PR/changelog and current KIC version history, not a fresh live repro; treat this section as **Unverified (external dependency: no IPv6-only cluster available)** if you need direct confirmation on your own cluster.

## Solution

If you are on an older, affected KIC version and cannot yet upgrade, the previously-documented workaround (disabling `http2` from the proxy's `admin_listen` definition) may still help as a stopgap:

Original:

```yaml

gateway.env.admin_listen: "[::]:8444 http2 ssl"
```

Updated:

```yaml

gateway.env.admin_listen: "[::]:8444 ssl"
```

This will allow proper syncing between the KIC and the proxy and the pods will mark themselves ready as expected
