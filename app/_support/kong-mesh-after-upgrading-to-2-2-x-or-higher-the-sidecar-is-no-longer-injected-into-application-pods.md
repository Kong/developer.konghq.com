---
title: "Kong Mesh: After upgrading to 2.2.x or higher, the sidecar is no longer injected into application pods"
content_type: support
description: Sidecar injection stops working after upgrading Kong Mesh past 2.2.x because annotation-based injection was removed in favor of Kubernetes labels.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Reference
    url: /mesh/reference/kubernetes-annotations/#labels
tldr:
  q: Why does Kong Mesh stop injecting sidecars into application pods after upgrading to 2.2.x or higher?
  a: |
    Kong Mesh removed annotation-based sidecar injection starting in 2.2, moving fully to Kubernetes labels (deprecated since Mesh 1.5). Update the namespace or pod manifest to use `kuma.io/sidecar-injection` as a label instead of an annotation to restore injection.
---

## Problem

After upgrading Kong Mesh to version 2.2.x or higher from 2.0.x and rolling the pods, the sidecar containers are no longer injected into application pods.

## Cause

Prior to 2.2.x it was acceptable to use annotations for the sidecar injection. Starting in Mesh 1.5, this was moved to Kubernetes labels and annotations were deprecated. As of version 2.2 this option has been completely removed in favor of using labels. If you have not transitioned to using labels prior to the upgrade, the result will be a lack of sidecar injection.

## Solution

To address this you will need to move from

```yaml
apiVersion: v1
kind: Namespace
metadata:
 name: default
 annotations:
   kuma.io/sidecar-injection: enabled
[...]
```

to

```yaml
apiVersion: v1
kind: Namespace
metadata:
 name: default
 labels:
   kuma.io/sidecar-injection: enabled
[...]
```
