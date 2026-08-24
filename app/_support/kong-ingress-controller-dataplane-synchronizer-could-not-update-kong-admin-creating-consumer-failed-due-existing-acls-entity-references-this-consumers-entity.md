---
title: "\"dataplane-synchronizer Could not update kong admin - creating consumer failed due existing 'acls' entity references this 'consumers' entity\" error when deploying the same consumer across multiple workspaces with Kong Ingress Controller"
content_type: support
description: "Explains why deploying the same consumer with ACL groups across multiple Kong Ingress Controller workspaces fails with a `creating consumer failed due existing 'acls' entity references this 'consumers' entity` error, caused by the `FillIDs` feature gate, and how to disable it."
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Kong Ingress Controller Feature Gates
    url: /kubernetes-ingress-controller/reference/feature-gates/
  - text: Kubernetes Ingress Controller CHANGELOG
    url: https://github.com/Kong/kubernetes-ingress-controller/blob/main/CHANGELOG.md#300
tldr:
  q: Why does creating a consumer with ACL groups in a second Kong Ingress Controller workspace fail with `creating consumer failed due existing 'acls' entity references this 'consumers' entity`?
  a: |
    KIC's `FillIDs` feature gate (enabled by default since KIC 3.0.0) generates UUIDs for entities from their attribute values, so identical consumers in different workspaces get the same UUID and collide when added to ACL groups. Disable both `FillIDs` and `KongCustomEntity` together via the `feature_gates` / `CONTROLLER_FEATURE_GATES` environment variable — `KongCustomEntity` depends on `FillIDs`, so disabling only one causes KIC to crash-loop.
---

## Problem

When deploying the same consumer with ACL groups in multiple workspaces with Kong Ingress Controller (KIC), creating the consumer fails with the error `dataplane-synchronizer Could not update kong admin - creating consumer failed due existing 'acls' entity references this 'consumers' entity`.

## Cause

The issue you are encountering is due to a feature gate parameter `FillIDs` that was enabled by default starting in KIC 3.0.0. This feature causes KIC to generate UUIDs for entities based on their attribute values. When you attempt to create identical consumers across different workspaces, the same UUID is generated, leading to a conflict when adding the consumer to ACL groups in the second workspace as the UUID is already associated with an ACL group from the first workspace.

## Solution

To resolve this issue, you need to disable the `FillIDs` feature by adding an environment variable to your KIC configurations. Note that `FillIDs` must be disabled together with the `KongCustomEntity` feature gate — disabling `FillIDs` alone causes KIC to crash-loop with an explicit dependency error, since `KongCustomEntity` depends on `FillIDs` being enabled. Here are the steps to do so:

1. Modify your KIC deployment configuration to include the `feature_gates` environment variable with both `FillIDs` and `KongCustomEntity` set to `false`.

2. Apply the updated configuration to your Kubernetes cluster.

Here is an example of how to set the environment variable in your KIC configuration:

```yaml

env:
  - name: CONTROLLER_FEATURE_GATES
    value: "FillIDs=false,KongCustomEntity=false"
```

After making this change, redeploy your KIC and test the deployment of your consumers across the workspaces again. You should find that KIC now starts and syncs cleanly, and is able to create the consumers and their ACL grouping without encountering the previous error.

For your reference, more information about feature gates is available in the Kong Ingress Controller documentation.

Additionally, the change log that introduced this feature is available in the GitHub repository for the Kong Kubernetes Ingress Controller.
