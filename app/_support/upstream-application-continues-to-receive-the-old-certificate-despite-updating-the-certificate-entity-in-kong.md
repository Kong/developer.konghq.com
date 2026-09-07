---
title: Upstream application continues to receive the old certificate despite updating the certificate entity in Kong
content_type: support
description: Kong reuses existing upstream keepalive connections, so an updated certificate only takes effect once those connections close and trigger a new TLS handshake.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does an upstream continue to receive the old certificate after I update the certificate entity in Kong?
  a: |
    Kong reuses existing upstream keepalive connections, so an updated certificate doesn't take effect until those connections close and a new TLS handshake occurs — by default that's after 60 seconds idle or `upstream_keepalive_max_requests` (10000 requests). To force the new certificate immediately, restart the Kong proxy node (or roll the pods on Kubernetes with `kubectl rollout restart`).
related_resources:
  - text: "`upstream_keepalive_idle_timeout` configuration reference"
    url: "/gateway/configuration/#upstream-keepalive-idle-timeout"
  - text: "`upstream_keepalive_max_requests` configuration reference"
    url: "/gateway/configuration/#upstream-keepalive-max-requests"
---

## Problem

The upstream application continues to receive the old certificate even after the certificate and key pair have been updated in the Kong certificate entity.

## Cause

By default, Kong has an upstream keepalive pool enabled. This means that even if you update the certificate and key of an existing certificate, the changes might not take effect immediately. This is because if there are available keepalive connections to the upstream, they will be reused, and no TLS handshake will occur on these reused connections. Consequently, the old certificate will still be used. However, these keepalive connections will eventually close, either after an idle timeout or after processing the maximum number of requests (`upstream_keepalive_idle_timeout` defaults to 60 seconds, and `upstream_keepalive_max_requests` defaults to 10000, confirmed current on Kong Gateway 3.14.0.0). The time it takes for the certificate update to become effective can vary based on the traffic sent to the upstream. For more details, see the Kong configuration reference for `upstream_keepalive_idle_timeout` and `upstream_keepalive_max_requests`.

## Solution

If you need to immediately force Kong to use the new certificate, a workaround is to restart the Kong proxy node. For Kubernetes deployments, you can achieve this by restarting the Kubernetes pods using a `kubectl rollout restart`. Remember, while deleting the old certificate and creating a new one with the latest Cert and Key pair works, it changes the certificate ID, which might not be ideal due to the need to update references in the upstream service.
