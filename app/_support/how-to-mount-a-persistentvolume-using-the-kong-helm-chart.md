---
title: How to mount a PersistentVolume using the Kong Helm Chart
content_type: support
description: To mount a `PersistentVolume` using the Kong Helm chart, declare the volume under `deployment.userDefinedVolumes` and `deployment.userDefinedVolumeMounts` in `values.yaml`.
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources:
  - text: the documentation
    url: https://github.com/Kong/charts/blob/main/charts/kong/README.md#user-defined-volumes
  - text: the Kubernetes docs
    url: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims
tldr:
  q: How do I mount a PersistentVolume using the Kong Helm Chart?
  a: |
    Declare the volume under `deployment.userDefinedVolumes` and `deployment.userDefinedVolumeMounts` in your Helm `values.yaml` (for example, referencing a `PersistentVolumeClaim`) so it's mounted in all Kong containers. The PV and PVC must already exist in Kubernetes, or the pods will wait indefinitely for the claim.
---

## Overview

How do I mount a PersistentVolume using the Kong Helm Chart?

## Steps

To mount a `PersistentVolume`, you need to declare the volume in the `deployment.userDefinedVolumes` and `deployment.userDefinedVolumeMounts` sections. You can find the details in the documentation.

After declaring the `userDefinedVolumes` and `userDefinedVolumeMounts`, the volume will be mounted in all the Kong containers.

If you want to use a `PersistentVolumeClaim`, you can declare it in the same way as an `emptyDir`, but you must create the PV and PVC claim in Kubernetes, otherwise the pods will not be created, waiting for the PVC. You can find the details in the Kubernetes docs.

As an example, the `values.yaml` file will be like:

```yaml
deployment:
  # Define any volumes and mounts you want present in the Kong proxy container
  userDefinedVolumes:
  - name: "test-volume"
    persistentVolumeClaim:
      claimName: myclaim
  userDefinedVolumeMounts:
  - name: "test-volume"
    mountPath: "/tmp/kong_volumes/mount"
```

Assuming the PVC `myclaim` exists in the Kong namespace.
