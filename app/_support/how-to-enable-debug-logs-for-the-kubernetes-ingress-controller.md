---
title: How to enable debug logs for the Kubernetes Ingress Controller
content_type: support
description: "Set the Kubernetes Ingress Controller's log level to debug using the `log-level` CLI flag, the `CONTROLLER_LOG_LEVEL` environment variable, or the `log_level` key under `ingressController.env` in the Helm chart."
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I enable debug logs for the Kubernetes Ingress Controller?
  a: |
    Set the KIC log level to `debug` via the `log-level` CLI flag, the `CONTROLLER_LOG_LEVEL` environment variable, or the `log_level` key under `ingressController.env` in the Helm chart. The chart prepends `CONTROLLER_` and upper-cases the key, so it must be `log_level`, not `controller_log_level`.
---

## Overview

How do I enable debug logs for the Kubernetes Ingress Controller?

## Steps

The KIC log level can be set with the `log-level` flag, documented here: Kubernetes Ingress Controller CLI Arguments .

The flag can also be configured using an environment variable. The name of the environment variable is: `CONTROLLER_LOG_LEVEL=debug` .

When using Helm, you can add this flag in the `env` section under the `ingress` config, as part of the Ingress Controller Parameters , for example:

The chart automatically prepends `CONTROLLER_` and upper-cases every key placed under `ingressController.env`, so the key must be `log_level`, not `controller_log_level` — using `controller_log_level` produces the never-read environment variable `CONTROLLER_CONTROLLER_LOG_LEVEL` and the flag is silently ignored.

```yaml
ingressController:
  enabled: true
  installCRDs: false
  env:
    log_level: "debug"
    kong_admin_token:
      valueFrom:
        secretKeyRef:
          name: kong-enterprise-superuser-password #CHANGEME
          key: password #CHANGEME
```
