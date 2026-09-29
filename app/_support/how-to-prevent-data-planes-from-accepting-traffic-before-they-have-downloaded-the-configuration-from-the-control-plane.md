---
title: How to prevent data planes from accepting traffic before they have downloaded the configuration from the control plane
content_type: support
description: An easy way to address this issue is to change the default readiness probe to use a health check route.
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I prevent Kong data planes from accepting traffic before they've downloaded their configuration from the control plane?
  a: |
    Kong ships a native `/status/ready` endpoint on the status port that returns 503 until the data plane has received and applied its configuration from the control plane, then returns 200. It's the default `readinessProbe` shipped in the Kong Helm chart, so most deployments don't need any custom configuration. Point your Kubernetes readiness probe at `/status/ready` instead of relying on a custom `/health` route workaround.
---

## Overview

We are using Kong helm charts with a hybrid mode setup, and noticed that when new data planes come up while the control plane is unavailable that the data planes are marked as ready, and receive traffic even though they don't have the configuration yet. This results in 404 errors. How can we avoid Kong data plane pods being marked as ready before they have received the configuration from the control plane?

## Steps

Kong now ships a native `/status/ready` endpoint on the status port that already gates readiness on config-sync status: it returns a 503 until the data plane has received and applied its configuration from the control plane, then returns 200. This is the recommended solution, and it's the default `readinessProbe` shipped in the Kong Helm chart (`Kong/charts`) — most deployments won't need any custom configuration.

With a helm chart deployment, the `readinessProbe` for data-planes should look like this in `values.yaml`:

```yaml

readinessProbe:
  httpGet:
    path: "/status/ready"
    port: "status"
    scheme: HTTP
  initialDelaySeconds: 5
  timeoutSeconds: 5
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3
```

Previously, before `/status/ready` was available, a workaround was to create a custom `/health` route with a request-termination plugin returning 200, and point the readiness probe at that route on the proxy port instead. That approach still works, but it has a real downside compared to `/status/ready`: every readiness check is a proxy request and counts towards your overall request quota. Since `/status/ready` runs on the status port and is purpose-built for this check, the custom `/health` workaround is very likely unnecessary on current {{site.base_gateway}} versions.
