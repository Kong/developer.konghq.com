---
title: "Kong Gateway: Observing 404 response codes during auto-scaling in Kubernetes platform"
content_type: support
description: Kong Gateway briefly returns 404 responses during Kubernetes auto-scaling because the readiness probe reports healthy before routing configuration finishes loading; the current Kong Helm chart's default `readinessProbe` already fixes this by targeting `/status/ready`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Configure liveness, readiness, and startup probes
    url: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes
tldr:
  q: Why does Kong Gateway return brief 404 responses when new pods are created during Kubernetes auto-scaling?
  a: |
    Kubernetes sends traffic to the new pod before Kong Gateway has finished loading its routing configuration, usually because the readiness probe is a generic process-up check that reports healthy before the router has built from the first config sync.

    The current Kong Helm chart's default `readinessProbe` already targets `/status/ready` on the status port (default `8100`), which stays `503` until routing is ready, so this is fixed out of the box on a current chart. On an older chart or a custom deployment, point the readiness probe at `/status/ready` instead of a generic check.
---

## Problem

We are using auto-scaling in Kubernetes for Kong Gateway, and during the creation of new pods we are seeing 404 responses to traffic for a brief period of time (usually just a few seconds). We want to understand why this is happening and how to prevent it in our systems.

## Cause

This behavior is usually seen because the Kubernetes platform is sending traffic to Kong Gateway before the full config has loaded in the Gateway. This is often the case when the readiness probes are set to a generic process-up check (for example a plain TCP check, or the default `/readyz` or `/healthz` endpoint) that returns healthy before Kong Gateway has actually finished loading its routing configuration.

## Solution

**Update:** the current Kong Helm chart's default `readinessProbe` for the proxy container already addresses this out of the box — it targets `/status/ready` on the `status` port (default `8100`), a dedicated Kong Gateway status endpoint that returns `503` until the router has finished building from the first config sync, and only returns `200` once Kong Gateway is actually ready to serve routed traffic. If you are deploying via the current Kong Helm chart with its default readiness probe, you should not need any of the additional workarounds below at all. This is the fix this article previously said would arrive "in a future release" — it has since landed.

If you are on an older chart/manifest version, have overridden the default readiness probe, or are not using the Helm chart at all, the following workarounds still apply:

1. **Recommended:** Point the readiness probe at `/status/ready` on Kong Gateway's status port (default `8100`) instead of a generic process-up check. This endpoint requires no additional plugin/route setup.
2. Add a delay (`initialDelaySeconds`) to the readiness probe configuration.
3. Create a dedicated Route in the Kong Gateway to respond to the readiness probes. On the Route, add a scoped Request Termination plugin to respond with a 200 HTTP response. Lastly, configure the readiness probes to check the newly created Route.
