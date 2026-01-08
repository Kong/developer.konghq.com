---
title: "{{site.mesh_product_name}} resource sizing guidelines"
description: "Learn about control plane and sidecar container sizing guidelines for {{site.mesh_product_name}}."
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - performance

works_on:
  - on-prem

related_resources:
  - text: "{{site.mesh_product_name}} version support policy"
    url: /mesh/support-policy/
  - text: Mesh concepts
    url: /mesh/concepts/
---

## Sizing your control plane

Generally, a {{site.mesh_product_name}} control plane with 4vCPU and 2GB of memory will be able to accommodate more than 1000 data planes.

A good rule of thumb is to assign about 1MB of memory per data plane.
When it comes to CPUs, {{site.mesh_product_name}} handles parallelism extremely well since its architecture uses a lot of shared-nothing goroutines, so more CPUs usually enable quicker propagation of changes.

However, we highly recommend that you to run your own load tests prior to going to production.
There are many ways to run workloads and deploy applications, and while we test some of them, you are in the best position to build a realistic benchmark of what you do.

To see if you may need to increase your control plane's spec, there are two main metrics to pay attention to:

- Propagation time (`xds_delivery`): This is the time it takes between a change in the mesh and the data plane receiving its updated configuration. Think about it as the reactivity of your mesh.
- Configuration generation time (`xds_generation`): This is the time it takes for the configuration to be generated.

For any large mesh using a transparent proxy, we recommend using [reachable services](/mesh/performance-tuning/#reachable-services).

You can also find tuning configuration in the [performance fine-tuning](/mesh/performance-tuning/) documentation.

## Sizing your sidecar container on Kubernetes

When deploying {{site.mesh_product_name}} on Kubernetes, the sidecar is deployed as a separate container, `kuma-sidecar`, in your pods. By default it has the following resource requests and limits:

```yaml
resources:
    requests:
        cpu: 50m
        memory: 64Mi
    limits:
        cpu: 1000m
        memory: 512Mi
```

This configuration should be enough for most use cases. In some cases (for example, when you can't scale horizontally or your service handles lots of concurrent traffic), you may need to change these values. You can do this using the [`ContainerPatch` resource](/mesh/data-plane-kubernetes/#custom-container-configuration). 

For example, you can modify individual parameters under `resources`:

```yaml
apiVersion: kuma.io/v1alpha1
kind: ContainerPatch
metadata:
  name: container-patch-1
  namespace: {{site.mesh_namespace}}
spec:
  sidecarPatch:
    - op: add
      path: /resources/requests/cpu
      value: '"1"'
```

Or you can modify the entire `limits`, `request` or `resources` sections:

```yaml
apiVersion: kuma.io/v1alpha1
kind: ContainerPatch
metadata:
  name: container-patch-1
  namespace: {{site.mesh_namespace}}
spec:
  sidecarPatch:
    - op: add
      path: /resources/limits
      value: '{
        "cpu": "1",
        "memory": "1G"
      }'
```

Check the [`ContainerPatch` documentation](/mesh/data-plane-kubernetes/#workload-matching) to learn how to apply these resources to specific pods.

{:.info}
> **Note**: When changing these resources, remember that they must be described using [Kubernetes resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes).
