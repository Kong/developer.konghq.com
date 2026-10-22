---
title: Enabling Dynatrace to monitor Kong in Kubernetes
content_type: support
description: Enable Dynatrace runtime instrumentation for Kong's NGINX proxy in a Helm-based Kubernetes deployment by setting `DT_NGINX_FORCE_RUNTIME_INSTRUMENTATION` as a quoted string under `customEnv`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Dynatrace's manual runtime instrumentation guide for NGINX
    url: https://docs.dynatrace.com/docs/technology-support/application-software/nginx/manual-runtime-instrumentation
  - text: Kong's Helm chart values.yaml
    url: https://github.com/Kong/charts/blob/main/charts/kong/values.yaml
tldr:
  q: How do I enable Dynatrace runtime instrumentation for Kong when Kong is deployed via Helm?
  a: |
    Set `DT_NGINX_FORCE_RUNTIME_INSTRUMENTATION: "on"` under `customEnv` in your Helm values file, keeping the value quoted — an unquoted `on` is parsed as the YAML boolean and renders as the string `"true"`, which silently fails to enable instrumentation.

    Runtime instrumentation also adds 10+ seconds to NGINX startup, so raise your liveness and readiness probe timeouts to accommodate the delay.
---

## Problem

We need to enable Dynatrace monitoring on our Kong deployment. We use Helm to install Kong. How can this be achieved?

## Solution

Dynatrace has released new steps to monitor Kong.

We need to add the following to our values file for a Helm install (see the `customEnv` section in Kong's Helm chart `values.yaml` — note the exact line numbers shift between chart releases, so search for `customEnv` rather than relying on a fixed line anchor):

```yaml
customEnv:
  DT_NGINX_FORCE_RUNTIME_INSTRUMENTATION: "on"
```

Note: quote the value as `"on"`. YAML treats a bare, unquoted `on` (and `off`/`yes`/`no`) as a boolean — Helm then renders it into the container as the literal string `"true"` rather than the literal string `on` that Dynatrace's agent expects (confirmed via `helm template`: an unquoted `on` produces `value: "true"` in the rendered env var, while a quoted `"on"` correctly produces `value: "on"`), so leaving it unquoted will silently fail to enable the instrumentation.

Additionally, the runtime instrumentation adds a notable startup delay (Dynatrace's own docs cite 10 seconds or more) to NGINX. You will need to adjust your timeouts on your liveness and readiness probes to accommodate this, or Kubernetes may kill the container mid-startup.
