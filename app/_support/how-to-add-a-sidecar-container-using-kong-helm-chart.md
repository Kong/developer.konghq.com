---
title: How to add a sidecar container using Kong Helm Chart
content_type: support
published: false
description: The Kong Helm Chart can deploy additional sidecar containers along with the Kong and Ingress Controller containers.
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I add a sidecar container to a Kong pod using the Kong Helm Chart?
  a: |
    The Kong Helm Chart's `deployment.sidecarContainers` field in `values.yaml` accepts an array of container objects, which are appended as-is to the Kong deployment's `spec.template.spec.containers` array. Use it to add sidecars such as network proxies or logging agents alongside the Kong and Ingress Controller containers.
related_resources: []
---

## Overview

How can I add a sidecar container to Kong pod using the Helm Chart?

## Steps

The Kong Helm Chart can deploy additional sidecar containers along with the Kong and Ingress Controller containers. This can be useful to include network proxies or logging services along with Kong. The `deployment.sidecarContainers` field in `values.yaml` file takes an array of objects that get appended as-is to the existing `spec.template.spec.containers` array in the Kong deployment resource:

```yaml

deployment:
  kong:
    enabled: true
  sidecarContainers:
    - name: cloud-sql-proxy
      image: some-proxy:1.9.0
      command:
        - "/start_proxy"
        - "-parameter=value"
...
```
