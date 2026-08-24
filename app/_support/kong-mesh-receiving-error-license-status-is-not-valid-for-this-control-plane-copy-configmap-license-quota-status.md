---
title: "Kong Mesh: Receiving error \"license status is not valid for this control plane. Copy ConfigMap license-quota-status\""
content_type: support
description: A {{site.mesh_product_name}} Zone Control Plane can lose license validity when the `license-quota-status` ConfigMap is out of sync with the Global CP; deleting the ConfigMap and letting it rebuild resolves the error.
products:
  - mesh
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Reference
    url: /mesh/control-plane-configuration/#memory
tldr:
  q: "Why does deploying a Data Plane fail with \"license status is not valid for this control plane\" in a multi-zone Kong Mesh setup?"
  a: |
    This happens when the `license-quota-status` ConfigMap on the Zone Control Plane is out of sync with the Global CP. Delete the ConfigMap on the Zone CP and redeploy (for example, via `helm upgrade`) so it rebuilds and picks up a valid license. On Universal mode, back the Zone CP with a database instead of Memory storage, since Memory storage doesn't persist the license state.
---

## Problem

We have a multi-zone mesh setup and when deploying a Data Plane we received the following error message on the Zone Control Plane:

```
Warning FailedToGenerateKumaDataplane pod/redis-m30k3nks3-93kd3 Failed to generate Kuma Dataplane: admission webhook "validator.kuma-admission.kuma.io" denied the request: license status is not valid for this control plane. Copy ConfigMap license-quota-status from Global to Zone to restore functionality of the system.
```

This is preventing us from deploying and utilizing our data plane.

## Solution

To correct this you can have the Zone CP rebuild this configmap. You will need to first delete the original configmap using the following command on the Zone CP:

```bash
kubectl delete configmap <configmapname> -n <namespace>
```

Afterwards, redeploy the Zone CP and the configmap will be rebuilt. For example, if helm was used to deploy:

```bash
helm upgrade -n kong-mesh-system --values values.yaml kong-mesh kong-mesh/kong-mesh
```

We recommend validating that the license itself is correct on both the Global CP and the Zone CP after the deployment. To validate that you can run the following command:

```bash
kubectl get configmap license-quota-status -o yaml -n <namespace>
```

The output should be identical when run on the Global and Zone CP. Once the configmap is rebuilt the issue should be resolved.

If this occurs on Universal, please verify if you are running on Memory or backed by a database.

If this occurs while running on Memory please deploy out a database to resolve this issue. Memory data storage is intended for demo purposes.

Each Zone CP is intended to be backed by a database in universal.
