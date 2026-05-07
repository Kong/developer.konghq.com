---
title: Workload
description: Reference for the Workload resource, which represents a logical grouping of data plane proxies with status reporting for connected and healthy instances.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - data-plane
  - status

min_version:
  mesh: '2.13'

related_resources:
  - text: MeshIdentity
    url: /mesh/policies/meshidentity/
  - text: Data plane proxy configuration
    url: /mesh/data-plane-proxy/
  - text: Data plane proxy authentication
    url: /mesh/data-plane-proxy-authentication/
---

The `Workload` resource represents a logical grouping of [data plane proxies](/mesh/data-plane-proxy/) that share the same workload identifier. {{site.mesh_product_name}} creates and manages `Workload` resources automatically when data plane proxies carry a `kuma.io/workload` label. On Kubernetes, set the label with a `kuma.io/workload` annotation on the Pod. On Universal, set the label directly on the `Dataplane` resource.

Use `Workload` resources to:

* Monitor connected and healthy data plane proxies per workload.
* Group data plane proxies by workload identifier for observability.
* Integrate with [`MeshIdentity`](/mesh/policies/meshidentity/) to assign identity based on the workload.

{:.warning}
> * {{site.mesh_product_name}} manages `Workload` resources automatically. Do not create them manually. The control plane creates a `Workload` resource when a data plane proxy with a `kuma.io/workload` label is deployed, and deletes it when no data plane proxies reference it.
> 
> * All data plane proxies that reference a `Workload` must belong to the same mesh. On Kubernetes, {{site.mesh_product_name}} enforces this at the namespace level. A single namespace cannot contain Pods in multiple meshes.
>
>   If {{site.mesh_product_name}} detects Pods in multiple meshes within the same namespace, it emits a Kubernetes warning event on the namespace and skips `Workload` generation for the affected workload. Any existing `Workload` resource remains orphaned rather than being deleted.
>
>   For details on preventing this configuration issue, see the [namespace-mesh constraint documentation](/mesh/mesh-multi-tenancy/).

## Examples

The following examples show how {{site.mesh_product_name}} creates `Workload` resources from data plane proxies, how to assign identity to a workload with `MeshIdentity`, and how to check workload status.

### Workload created automatically

When you deploy a data plane proxy, {{site.mesh_product_name}} generates the `kuma.io/workload` label and creates a `Workload` resource:

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

Define a Pod with a ServiceAccount. By default, {{site.mesh_product_name}} uses the ServiceAccount name as the workload identifier:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo-app
spec:
  serviceAccountName: demo-workload
```

{{site.mesh_product_name}} then creates the matching `Workload`:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Workload
metadata:
  name: demo-workload
  namespace: default
  labels:
    kuma.io/mesh: default
    kuma.io/managed-by: k8s-controller
spec: {}
status:
  dataplaneProxies:
    connected: 3
    healthy: 3
    total: 3
```

{% endnavtab %}
{% navtab "Universal" %}

Define a `Dataplane` with a workload label:

```yaml
type: Dataplane
mesh: default
name: demo-app
networking:
  address: 192.168.0.1
  inbound:
    - port: 8080
      tags:
        kuma.io/service: demo-service
        kuma.io/workload: demo-workload
```

{{site.mesh_product_name}} then creates the matching `Workload`:

```yaml
type: Workload
mesh: default
name: demo-workload
status:
  dataplaneProxies:
    connected: 3
    healthy: 3
    total: 3
```

{% endnavtab %}
{% endnavtabs %}

### Workload with MeshIdentity

Combine `Workload` with `MeshIdentity` to assign identity based on the workload identifier:

{% navtabs "meshidentity" %}
{% navtab "Kubernetes" %}

Define a `MeshIdentity` that selects data plane proxies by their `kuma.io/workload` label:

{% raw %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: workload-identity
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplane:
      matchLabels:
        kuma.io/workload: demo-workload
  spiffeID:
    trustDomain: example.com
    path: "/workload/{{ .Workload }}"
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Enabled
      insecureAllowSelfSigned: true
      autogenerate:
        enabled: true
```

{% endraw %}

With this configuration, data plane proxies labeled `kuma.io/workload: demo-workload` receive the SPIFFE ID `spiffe://example.com/workload/demo-workload`.

{% endnavtab %}
{% navtab "Universal" %}

Define a `MeshIdentity` that selects data plane proxies by their `kuma.io/workload` label:

{% raw %}

```yaml
type: MeshIdentity
mesh: default
name: workload-identity
spec:
  selector:
    dataplane:
      matchLabels:
        kuma.io/workload: demo-workload
  spiffeID:
    trustDomain: example.com
    path: "/workload/{{ .Workload }}"
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Enabled
      insecureAllowSelfSigned: true
      autogenerate:
        enabled: true
```

{% endraw %}

With this configuration, data plane proxies labeled `kuma.io/workload: demo-workload` receive the SPIFFE ID `spiffe://example.com/workload/demo-workload`.

{% endnavtab %}
{% endnavtabs %}

### Checking workload status

List workloads and inspect their status to monitor connected and healthy data plane proxies:

{% navtabs "status" %}
{% navtab "Kubernetes" %}

List the workloads in the namespace:

```sh
kubectl get workloads -n default
```

The output shows each registered workload and its mesh:

```text
NAME            MESH      AGE
demo-workload   default   5m
```
{:.no-copy-code}

Inspect the detailed status of a specific workload:

```sh
kubectl get workload demo-workload -n default -o yaml
```

{% endnavtab %}
{% navtab "Universal" %}

List the workloads in the mesh:

```sh
kumactl get workloads --mesh default
```

The output shows each registered workload and its mesh:

```text
NAME            MESH      AGE
demo-workload   default   5m
```
{:.no-copy-code}

Inspect the detailed status of a specific workload:

```sh
kumactl get workload demo-workload --mesh default -o yaml
```

{% endnavtab %}
{% endnavtabs %}

## Workload label management

The `kuma.io/workload` label determines which `Workload` resource a data plane proxy belongs to.

### Kubernetes

On Kubernetes, {{site.mesh_product_name}} generates the `kuma.io/workload` label for each Pod using the following logic:

1. Automatic from Pod labels: If `runtime.kubernetes.workloadLabels` is configured in the control plane, {{site.mesh_product_name}} checks each Pod label in the configured priority order and uses the first non-empty value.
1. Fallback to ServiceAccount: If no configured labels exist or all are empty, {{site.mesh_product_name}} uses the Pod's ServiceAccount name.
1. Default behavior: By default, `workloadLabels` is empty, so {{site.mesh_product_name}} uses the ServiceAccount name.

You cannot set `kuma.io/workload` manually as a Pod label. {{site.mesh_product_name}} rejects Pod creates and updates that include it.

### Universal

On Universal, set the `kuma.io/workload` label directly in the `Dataplane` resource's inbound tags.

{:.warning}
> The `kuma.io/workload` label on a data plane proxy must match the `Workload` resource name exactly. All data plane proxies that reference a `Workload` must belong to the same mesh.

## Limitations

* Single mesh: All data plane proxies that reference a workload must belong to the same mesh. On Kubernetes, {{site.mesh_product_name}} enforces this at the namespace level. A single namespace can't contain Pods in multiple meshes. When a namespace violates the constraint, {{site.mesh_product_name}} skips the `Workload` generation and emits a warning event.
* Automatic lifecycle: You can't create or modify a `Workload` manually. The control plane fully manages the resource.
* Runtime enforcement: To prevent multi-mesh namespaces proactively, enable the [`runtime.kubernetes.disallowMultipleMeshesPerNamespace`](/mesh/reference/kuma-cp/) flag. With the flag enabled, the admission webhook rejects Pod creation and Pod updates when the namespace already contains `Dataplane` resources in a different mesh.

## Troubleshooting

### Detecting multi-mesh namespace issues

If {{site.mesh_product_name}} is not creating `Workload` resources as expected, check for multi-mesh namespace warnings:
```sh
kubectl get events -n <namespace> --field-selector type=Warning
```

Look for events with the message: `Skipping Workload generation: namespace has pods in multiple meshes for workload. This configuration is not supported.`

Identify Pods and their meshes:

```sh
kubectl get pods -n <namespace> -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.kuma\.io/mesh}{"\n"}{end}'
```

### Resolving multi-mesh namespace issues

To resolve a multi-mesh namespace conflict:

1. Identify affected Pods: Use the command above to list all Pods and their mesh assignments in the namespace.
1. Reorganize workloads: Move Pods that belong to different meshes into separate namespaces.
1. (Optional) Enable proactive prevention: Set `runtime.kubernetes.disallowMultipleMeshesPerNamespace=true` in the control plane configuration to prevent the issue from recurring.

## Schema

{% json_schema kuma.io_workloads type=crd %}
