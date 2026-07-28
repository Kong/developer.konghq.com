---
title: Error `cannot list resource ingressclassparameterses` when upgrading the Ingress Controller
content_type: support
description: "Why upgrading the Ingress Controller can fail with a \"cannot list resource `ingressclassparameterses`\" permissions error, and how to fix it by updating the Helm chart."
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: "Why does upgrading the Ingress Controller fail with a \"cannot list resource `ingressclassparameterses`\" error?"
  a: |
    This RBAC error occurs because your role lacks permission to list `ingressclassparameterses` at the cluster scope, which usually happens with an older Helm chart version. Newer chart versions grant this permission automatically — run `helm repo update` and upgrade to a current chart version to resolve it.
---

## Problem

When upgrading the Kubernetes Ingress Controller you find an error like the following in the logs:

```
W1102 15:28:53.061851 1 reflector.go:424] pkg/mod/k8s.io/client-go@v0.25.2/tools/cache/reflector.go:169: failed to list *v1alpha1.IngressClassParameters: ingressclassparameterses.configuration.konghq.com is forbidden: User "system:serviceaccount:kong-enterprise:kong-enterprise-ingress-kong-ingress" cannot list resource "ingressclassparameterses" in API group "configuration.konghq.com" at the cluster scope
```

The name of the service account can be different, however it is not possible to list the resource `ingressclassparameterses` at the cluster scope.

You should only get this error if your role lacks that permission, and current versions of the Helm chart add it or inform you that you're not allowed to grant it with your user when upgrading. So you probably are using an older chart version.

## Solution

To upgrade the Helm Chart, run `helm repo update`.
