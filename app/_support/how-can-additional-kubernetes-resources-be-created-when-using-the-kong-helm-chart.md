---
title: Creating additional Kubernetes resources when using the Kong Helm chart
content_type: support
description: The Helm charts support an array parameter, `extraObjects`, that you can use for this purpose.
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: How can additional Kubernetes resources be created when using the Kong Helm chart?
  a: |
    The Helm charts support an array parameter, `extraObjects`, that can be used for this purpose.
    Each new resource is an entry in the array, so you can define manifests (such as Kubernetes
    `Secret` objects) directly in your values file to have them created on deployment.
related_resources:
  - text: General parameters
    url: https://github.com/Kong/charts/tree/main/charts/kong#general-parameters
---

## Overview

Sometimes it is desirable to create additional Kubernetes resources upon deployment when using the Kong Helm chart. For example, creating a secret. How can this be achieved?

## Steps

The Helm charts support an array parameter, `extraObjects`, that you can use for this purpose.

Each new resource is an entry in the array. For example, the following array contains two manifests that create Kubernetes Secrets:

```yaml
image:
  repository: kong/kong-gateway

extraObjects:
  - apiVersion: v1
    data:
      kongCredType: YmFzaWMtYXV0aA==
      password: a29uZw==
      username: Z3J1YmVy
    kind: Secret
    metadata:
      name: basic-auth
  - apiVersion: v1
    data:
      password: a29uZw==
      username: bWNjbGFuZQo=
    kind: Secret
    metadata:
      name: uid-pw
```
