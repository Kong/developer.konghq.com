---
title: "\"IngressClass doesn't reference any parameters\" messages logged when creating an Ingress"
content_type: support
description: "A debug-level `doesn't reference any parameters` log message appears when an `IngressClass` has no `IngressClassParameters` configured — this is expected and not an error."
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "Kong Ingress Controller upgrade FAQ — expression router"
    url: "/kubernetes-ingress-controller/faq/upgrading-ingress-controller/#expression-router"
  - text: "Kubernetes Ingress documentation"
    url: "https://kubernetes.io/docs/concepts/services-networking/ingress/"
tldr:
  q: What does the "IngressClass doesn't reference any parameters" debug log message mean?
  a: |
    This debug-level message appears when an `IngressClass` has no `IngressClassParameters` configured. It's expected — not an error — and is used by Kong to support the Kong 2.x to 3.x migration for Ingress objects using regex paths. You can confirm this by describing your `IngressClass` and checking whether it references a parameters resource.
---

## Problem

When viewing the Ingress Controller logs the below message is repeated very frequently.

```
time="2026-11-22T13:28:29Z" level=debug msg="could not find IngressClassParameters, using defaults: IngressClass kong doesn't reference any parameters"
```

## Cause

These messages are only logged at the debug level and generally not a cause for concern. `IngressClass` Parameters are used to let you reference another resource that provides configuration related to that `IngressClass`.

Specifically, this is used by Kong to make the migration from Kong 2.x to 3.x smoother for the users that use regex paths in their Ingress. If no parameters are used, these messages are to be expected and will be logged at the frequency as defined by your `proxy-sync-seconds`.

## Solution

To confirm that no parameters are defined you can view/edit/describe your `IngressClass`, for example this `IngressClass` defines no parameters and would generate these messages:

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  annotations:
    meta.helm.sh/release-name: gruber
    meta.helm.sh/release-namespace: kongfused
spec:
  controller: ingress-controllers.konghq.com/kong
```
