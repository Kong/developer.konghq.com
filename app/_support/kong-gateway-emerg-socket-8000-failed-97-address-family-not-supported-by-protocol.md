---
title: "Kong Gateway: \"[emerg] socket() [::]:8000 failed (97: Address family not supported by protocol)\" error when installing via the Kong Helm chart with IPv6 disabled"
content_type: support
description: "The official `kong/kong` Helm chart enables an IPv6 `[::]` listener by default alongside IPv4, which fails to bind if IPv6 is disabled in the Kubernetes cluster."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does Kong Gateway fail to start with "socket() [::]:8000 failed (97: Address family not supported by protocol)" when installed via Helm?
  a: |
    The official `kong/kong` Helm chart's default listen values include an IPv6 `[::]` listener alongside the IPv4 `0.0.0.0` one. If IPv6 is disabled in the Kubernetes cluster, NGINX can't bind to it and Kong fails to start. Override the listen directives via the chart's `env:` block (for example `env.proxy_listen`) to drop the `[::]` entries and bind IPv4 only.
related_resources: []
---

## Problem

I am trying to install Kong Gateway in my Kubernetes environment using Helm. When I install, I see the following error and Kong will not start:

```
nginx: [emerg] socket() [::]:8000 failed (97: Address family not supported by protocol)
nginx: configuration file /tmp/tmp.Wv0OvAzYBz/nginx.conf test failed
```

## Solution

The official `kong/kong` Helm chart's default `KONG_PROXY_LISTEN` (and `KONG_ADMIN_LISTEN`/`KONG_STATUS_LISTEN`) value includes an IPv6 `[::]` listener alongside the IPv4 `0.0.0.0` one (confirmed still the case on the current chart, e.g. `KONG_PROXY_LISTEN=0.0.0.0:8000, [::]:8000, 0.0.0.0:8443 http2 ssl, [::]:8443 http2 ssl`). This is generally okay unless IPv6 is in some way disabled in your Kubernetes cluster. If NGINX is blocked from binding to an IPv6 address you will receive the above error.

The current chart no longer exposes an `addresses:` field on the Kubernetes Service blocks (`proxy:`, `admin:`, `manager:`, etc.) at all — that field does not exist anywhere in the chart's values schema, and in any case a Kubernetes Service-level setting has no effect on which addresses the Kong/NGINX process itself binds to inside the container, which is what actually produces this error. The correct, current fix is to override the listen directives directly via the chart's `env:` block, dropping the `[::]` IPv6 entries:

```yaml
env:
  proxy_listen: "0.0.0.0:8000, 0.0.0.0:8443 http2 ssl"
  admin_listen: "127.0.0.1:8444 http2 ssl"
  status_listen: "0.0.0.0:8100"
```

Add only the listener overrides you actually need — `proxy_listen` is the one that matters for this exact error, since it targets port 8000. Confirmed via `helm template` against the current chart that setting `env.proxy_listen` correctly overrides the rendered `KONG_PROXY_LISTEN` environment variable to the IPv4-only value given.
