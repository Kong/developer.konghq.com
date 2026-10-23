---
title: Resource scoping
content_type: reference
layout: reference
description: Learn which control plane owns each {{site.mesh_product_name}} resource in the Kong Air scenarios, where you create it, and where zone resources live on Kubernetes.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
min_version:
  mesh: '3.0'
next_steps:
  - text: "How-to: Split traffic with MeshService resources"
    url: "/mesh/split-traffic-with-meshservice-resources/"
related_resources:
  - text: Multi-zone architecture
    url: /mesh/multi-zone-architecture/
  - text: Policy targeting
    url: /mesh/policy-targeting/
---

A multi-zone {{site.mesh_product_name}} deployment has one global control plane and one zone control plane in each zone.
Each zone control plane connects to the global control plane over the Kuma Discovery Service (KDS), a two-way synchronization channel.
The control plane where a resource is first stored owns that resource.
You change the resource only on that control plane.

Resources reach the mesh in three ways:

* **Global resources**: You create them on the global control plane. The global control plane sends a copy to each zone.
* **Zone resources**: You create them on a zone control plane. In the Kubernetes zones of these scenarios, you create them with `kubectl`.
* **Workload resources**: The zone control plane creates a `Dataplane` for each proxy and a `MeshService` for each service in its zone. The zone control plane sends them to the global control plane, and the global control plane sends each `MeshService` to the other zones.

## How configuration moves between control planes

The global control plane and the zone control planes exchange resources over KDS.
Each zone control plane then sends proxy configuration to its local proxies over xDS, the Envoy configuration protocol.

{% mermaid %}
flowchart TD
    K["Global control plane<br/>global resources and central view"]
    Z1["Kubernetes zone control plane<br/>zone1"]
    Z2["Universal zone control plane<br/>zone2"]
    D1["Local workloads and proxies"]
    D2["Local workloads and proxies"]

    K <-->|KDS| Z1
    K <-->|KDS| Z2
    Z1 -->|xDS| D1
    Z2 -->|xDS| D2
{% endmermaid %}

KDS works in both directions, but each resource type syncs only in the directions that {{site.mesh_product_name}} allows for it.
A copy that a control plane receives over KDS is read-only.
To change the resource, update it on the control plane that owns it.

## Resource ownership in the Kong Air scenarios

The following table shows where you create each resource that the scenarios use, and where it lives on Kubernetes:

<!-- vale off -->
{% table %}
columns:
  - title: Resource
    key: resource
  - title: Who creates it
    key: owner
  - title: Location on Kubernetes
    key: placement
  - title: Why
    key: why
rows:
  - resource: "`Mesh`"
    owner: "You, on the global control plane."
    placement: "The zone copy is cluster-scoped and has no namespace."
    why: "The `Mesh` defines the mesh boundary for every zone. Identity, mTLS, and traffic behavior come from separate resources and policies."
  - resource: "`MeshMultiZoneService`"
    owner: "You, on the global control plane."
    placement: "The zone copy is in `{{site.mesh_namespace}}`."
    why: "Only the global control plane has the services of every zone, which it needs to combine them into one destination."
  - resource: "`MeshIdentity` and `MeshTrust`"
    owner: "You, on the global control plane or on a zone control plane."
    placement: "Only in `{{site.mesh_namespace}}`."
    why: "Create them on the global control plane to share one identity configuration. Create them on a zone control plane when the issuer and trust belong to that zone only."
  - resource: "Mesh-wide policy, for example `MeshTLS`"
    owner: "You, on the global control plane or on a zone control plane."
    placement: "On a zone, `{{site.mesh_namespace}}`."
    why: "A policy on the global control plane gives every zone the same baseline. A policy in the zone system namespace applies to the whole zone."
  - resource: "Workload policy, for example `MeshTimeout`"
    owner: "You, on the zone control plane where the workloads run."
    placement: "Usually the namespace of the workloads that the policy governs."
    why: "A policy in an application namespace stays within the scope of the application team that owns that namespace."
  - resource: "`MeshExternalService`"
    owner: "You, on the global control plane or on a zone control plane."
    placement: "Only in `{{site.mesh_namespace}}`."
    why: "Create it on the global control plane for a dependency that every zone uses. Create it on a zone control plane when only that zone can reach the endpoints."
  - resource: "`MeshOpenTelemetryBackend`"
    owner: "You, on the global control plane or on a zone control plane."
    placement: "Only in `{{site.mesh_namespace}}`."
    why: "Observability policies select the backend by its labels, so it's shared infrastructure for every team."
  - resource: "`MeshZoneAddress`"
    owner: "On Kubernetes, the zone control plane creates it from the zone ingress Service. On Universal, you create it on the zone control plane."
    placement: "`{{site.mesh_namespace}}`."
    why: "Only the zone knows the address where other zones reach its zone ingress. The zone control plane sends it to the global control plane, which sends it to the other zones."
{% endtable %}
<!-- vale on -->

For more about each workload resource, see [MeshService](/mesh/meshservice/) and [Mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/).

## Global resources

Create the `Mesh` on the global control plane before you deploy workloads into it.
Also create global resources such as `MeshMultiZoneService` there.
The global control plane then sends a read-only copy to each connected zone.
On Kubernetes, a zone stores the copy of a namespaced resource in `{{site.mesh_namespace}}`.

A zone control plane that's connected to a global control plane can't create a global resource.
For example, if you apply a `Mesh` with `kubectl` on that zone, the admission webhook rejects it.
A zone control plane that isn't connected to a global control plane accepts a `Mesh`, because it has no global control plane to receive one from.

## Zone resources on Kubernetes

The early Kong Air scenarios use a single zone, so you create most resources on that zone with `kubectl`.
A zone resource in the system namespace needs the `kuma.io/mesh` label, because the scenarios use `kong-air-mesh` instead of the `default` mesh:

```yaml
metadata:
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
```
{:.no-copy-code}

The zone control plane adds the other ownership labels when it stores the resource:

* `kuma.io/origin: zone`, because you created the resource on a zone control plane
* `kuma.io/zone`, set to the name of the zone
* `kuma.io/policy-role`, on a policy, which decides which proxies the policy can reach

Don't copy these labels from a synced resource into new YAML.
If you set one of these labels to a value that differs from the value the control plane computes, the control plane rejects the resource.

### Namespaces that each resource type accepts

On Kubernetes, you can create the following resource types only in `{{site.mesh_namespace}}`:

* `MeshIdentity`
* `MeshTrust`
* `MeshExternalService`
* `MeshOpenTelemetryBackend`
* `HostnameGenerator`

You can create policies, `MeshService`, `MeshMultiZoneService`, and `MeshZoneAddress` resources in an application namespace on a zone control plane.

A policy in an application namespace reaches only proxies in that namespace, unless it's a producer policy for a service in that namespace.
Put a policy in `{{site.mesh_namespace}}` only when a platform operator needs it to reach the whole zone.
For the full rules, see [Policy scope](/mesh/policy-targeting/#policy-scope).

## Universal zones

Universal zones don't have namespaces, so every policy that you create there reaches the whole zone.
To create a resource, run `kongctl` against the control plane that owns it:

```sh
kongctl apply mesh -f mesh-traffic-permission.yaml --control-plane-name "$MESH_CP"
```

Before you change a resource, read its `kuma.io/origin` label to find the control plane that owns it:

```sh
kongctl get mesh meshtrafficpermissions --control-plane-name "$MESH_CP" --mesh kong-air-mesh -o yaml
```

Update a resource with `kuma.io/origin: global` on the global control plane, and a resource with `kuma.io/origin: zone` on the zone that owns it.
For a self-managed control plane, replace `--control-plane-name` with `--control-plane-url` and the address of its API.
For more `kongctl` options, see [{{site.mesh_product_name}} CLI](/mesh/cli/).
