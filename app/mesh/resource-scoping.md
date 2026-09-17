---
title: Resource scoping
content_type: reference
layout: reference
description: Understand which {{site.mesh_product_name}} resources belong to the global control plane, which can be created in a zone, and where zone-origin resources live on Kubernetes.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - konnect
next_steps:
  - text: "Split traffic with MeshService resources"
    url: "/mesh/split-traffic-with-meshservice-resources/"
related_resources:
  - text: Multi-zone architecture
    url: /mesh/multi-zone-architecture/
  - text: Multi-zone deployment
    url: /mesh/mesh-multizone-service-deployment/
---

Each Kubernetes or Universal zone runs its own zone control plane and connects to the global control plane over the Kuma Discovery Service (KDS).

Where you create a resource determines who owns it:

* Create global resources through the global control plane. It distributes them to the zones that need them.
* Create zone-origin resources through the local zone control plane. On Kubernetes, the examples in these scenarios use `kubectl`.
* Workload resources, such as generated `Dataplane` and `MeshService` objects, originate in the zone where the workload runs and sync towards the global control plane when required.

## How configuration moves

{% mermaid %}
flowchart TD
    K["Global control plane<br/>global resources and central view"]
    Z1["Kubernetes zone CP<br/>zone1"]
    Z2["Universal zone CP<br/>zone2"]
    D1["Local workloads and proxies"]
    D2["Local workloads and proxies"]

    K <-->|KDS| Z1
    K <-->|KDS| Z2
    Z1 -->|xDS| D1
    Z2 -->|xDS| D2
{% endmermaid %}

KDS is bidirectional, but that does not make every resource writable everywhere. Each resource type declares whether it can originate globally, in a zone, or in either place. A resource synced into a zone is a read-only copy; update it at its point of origin.

## Resource ownership

<!-- vale off -->
{% table %}
columns:
  - title: Resource
    key: resource
  - title: Create it in
    key: owner
  - title: Kubernetes placement
    key: placement
  - title: Why
    key: why
rows:
  - resource: "`Mesh`"
    owner: "Global control plane"
    placement: "The synced Kubernetes copy is cluster-scoped; it has no namespace."
    why: "Defines the mesh boundary. Identity, mTLS, and other behavior are configured by separate resources and policies."
  - resource: "`MeshMultiZoneService`"
    owner: "Global control plane"
    placement: "Synced copies appear in the zone system namespace."
    why: "Only the global control plane has the service information needed to assemble a destination spanning multiple zones."
  - resource: "`MeshIdentity` and `MeshTrust`"
    owner: "Global or zone control plane"
    placement: "Zone-origin resources must be in `{{site.mesh_namespace}}`."
    why: "Create them globally for shared identity configuration, or in a zone when the issuer and trust are deliberately local to that zone."
  - resource: "Mesh-wide policy, for example `MeshTLS`"
    owner: "Global or zone control plane"
    placement: "Use `{{site.mesh_namespace}}` for a zone-origin policy that governs the whole mesh."
    why: "A global policy gives every zone the same baseline. A zone-origin policy is useful for a local scenario or a deliberate zone override."
  - resource: "Workload policy, for example `MeshTimeout`"
    owner: "Global or zone control plane"
    placement: "Usually the workload namespace when the policy only governs workloads in that namespace."
    why: "Namespace placement keeps application-owned policy within the application team's scope."
  - resource: "`MeshExternalService`"
    owner: "Global or zone control plane"
    placement: "A zone-origin resource must be in `{{site.mesh_namespace}}`."
    why: "Create it globally for a dependency shared by zones, or in one zone when its endpoints and reachability are local to that zone."
{% endtable %}
<!-- vale on -->

## Global resources

Create the `Mesh` through the global control plane before deploying workloads into it. Create resources such as `MeshMultiZoneService` there, then wait for their read-only copies to sync to the connected zones.

Do not apply a global resource to a Kubernetes zone with `kubectl`. A zone cannot turn a local Kubernetes object into a global resource.

## Zone-origin resources on Kubernetes

These scenarios use zone-origin policy for the early, single-zone exercises so every command can be run against the connected Kubernetes cluster. A system-namespace resource explicitly uses the zone-origin label:

```yaml
metadata:
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
```

The control plane also records which zone originated the resource. Do not copy the zone label from a synced object into new YAML; the control plane manages it.

Policies created in an application namespace are already local to that namespace. Their target selectors must stay within the authority granted to that namespace. Put a policy in the system namespace only when a platform operator intentionally needs mesh-wide or cross-namespace scope.

## Universal zones

Universal zones do not have Kubernetes namespaces. Point `kumactl` at the intended zone control plane and apply the Universal form of the resource there:

```sh
kumactl config control-planes use zone-eu-cp
kumactl apply -f mesh-traffic-permission.yaml
```

Before changing a resource, inspect its `kuma.io/origin` label with `kumactl`. Update a global resource through the global control plane and a zone-origin resource through the zone that owns it.
