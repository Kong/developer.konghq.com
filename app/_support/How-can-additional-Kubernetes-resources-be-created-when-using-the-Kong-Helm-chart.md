---
title: Creating additional Kubernetes resources when using the Kong Helm chart
content_type: support
description: The helm charts support an array parameter, extraObjects, that can be used for this purpose.
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: How can additional Kubernetes resources be created when using the Kong Helm chart?
related_resources:
  - text: General parameters
    url: https://github.com/Kong/charts/tree/main/charts/kong#general-parameters
---

## Overview

Sometimes it is desirable to create additional Kubernetes resources upon deployment when using the Kong Helm chart. For example, creating a secret. How can this be achieved?

## Steps

The helm charts support an array parameter, `extraObjects`, that can be used for this purpose.

Each new resource should be an entry in the Array. For example, the below contains two manifests to create Kubernetes Secrets:

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
