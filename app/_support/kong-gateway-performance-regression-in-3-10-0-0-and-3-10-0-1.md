---
title: "Kong Gateway: Performance regression in 3.10.0.0 and 3.10.0.1"
content_type: support
description: A bug in the OpenResty `lua-nginx-module` used by Kong Gateway 3.10.0.0 and 3.10.0.1 can misidentify or fail to reuse pooled upstream connections for hostnames longer than 32 characters, reducing throughput; upgrading to Kong Gateway 3.10.0.2 or later resolves it.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "#12288"
    url: https://github.com/Kong/kong-ee/issues/12288
tldr:
  q: Why did Kong Gateway 3.10.0.0 and 3.10.0.1 introduce a performance regression?
  a: |
    A bug in the underlying OpenResty `lua-nginx-module` truncated hostnames longer than 32 characters when matching pooled keepalive upstream connections, which could misidentify or fail to reuse pooled connections and reduce throughput. Upgrade to Kong Gateway `3.10.0.2` or later to pick up the upstream OpenResty fix.
---

## Problem

Since upgrading to Kong Gateway 3.10.0.0 or 3.10.0.1, I am seeing degraded performance by way of lower throughput.

## Cause

Starting with Kong Gateway version 3.10.0.0, a bug originating from the underlying OpenResty platform (`lua-nginx-module`'s balancer keepalive-pool handling) affects upstream connection pooling when the pooled connection's identifying hostname is longer than 32 characters — a stack-truncated buffer was used instead of the real hostname when storing/matching a pooled keepalive connection, which can misidentify or fail to reuse pooled connections for such upstreams. This issue negatively impacts performance, resulting in reduced request rates and increased latencies, and is most likely to be noticed against upstreams with long hostnames (for example, hostnames that are long enough on their own, or become long once combined with connection-pool-key data such as SNI/cert-related information for HTTPS upstreams). Versions 3.10.0.0 and 3.10.0.1 are both affected.

## Solution

To resolve this regression, please upgrade to Kong Gateway 3.10.0.2 or later. This fix is documented in the Kong Gateway 3.10.0.2 changelog verbatim as: "Applied a patch from upstream OpenResty to fix an issue where upstream connection pooling failed when pool names exceeded 32 characters." (#12288, KAG-6951)

This patch (an upstream OpenResty fix, `openresty/lua-nginx-module` commit `18ce5fbd58`) restores correct connection-pool identification and expected performance levels. If you are experiencing performance issues in versions 3.10.0.0 or 3.10.0.1, upgrading to 3.10.0.2 or later is strongly recommended.

**Note on Kong Gateway 3.14.0.0:** this fix has been included in every Kong Gateway release since 3.10.0.2 — 3.14.0.0 already contains it (confirmed via `kong-ee` source history: the fixing commit is an ancestor of the 3.14.0.0 tag). This regression is not something you would encounter on current Kong Gateway 3.14.0.0; this article remains relevant only to anyone still running the affected 3.10.0.0/3.10.0.1 releases specifically.
