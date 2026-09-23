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
  - on-prem
  - konnect
next_steps:
  - text: "Split traffic with MeshService resources"
    url: "/mesh/split-traffic-with-meshservice-resources/"
related_resources:
  - text: Multi-zone architecture
    url: /mesh/multi-zone-architecture/
  - text: Policy targeting and precedence
    url: /mesh/policy-targeting-and-precedence/
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
    placement: "On Kubernetes they can only be created in `{{site.mesh_namespace}}`."
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
    placement: "On Kubernetes it can only be created in `{{site.mesh_namespace}}`."
    why: "Create it globally for a dependency shared by zones, or in one zone when its endpoints and reachability are local to that zone."
  - resource: "`MeshOpenTelemetryBackend`"
    owner: "Global or zone control plane"
    placement: "On Kubernetes it can only be created in `{{site.mesh_namespace}}`."
    why: "Observability policies reference it by label, so it is shared infrastructure rather than application-owned configuration."
  - resource: "`MeshZoneAddress`"
    owner: "Zone control plane"
    placement: "Any namespace. It syncs to the global control plane and on to the other zones."
    why: "Only the zone knows the address its own zone ingress publishes for cross-zone traffic."
{% endtable %}
<!-- vale on -->

## Global resources

Create the `Mesh` through the global control plane before deploying workloads into it. Create resources such as `MeshMultiZoneService` there, then wait for their read-only copies to sync to the connected zones. On Kubernetes, a synced copy of a namespaced resource lands in `{{site.mesh_namespace}}`.

Once a zone is connected to a global control plane, it can no longer create a global resource for itself. Applying a `Mesh` with `kubectl` against that zone is rejected by the admission webhook. A standalone control plane, which has no global and zone split, is the exception: there, `kubectl apply` of a `Mesh` is the normal way to create one.

## Zone-origin resources on Kubernetes

These scenarios use zone-origin policy for the early, single-zone exercises so every command can be run against the connected Kubernetes cluster. A zone-origin resource in the system namespace carries two labels:

```yaml
metadata:
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
```

The `kuma.io/origin` line is required there. On a Kubernetes zone connected to a global control plane, every resource created in `{{site.mesh_namespace}}` must carry `kuma.io/origin: zone`, whatever its kind, and the zone control plane rejects it otherwise. A resource in an application namespace does not need it, and a standalone control plane, which has no global and zone split, does not check it at all. Setting the label is valid in all three cases, which is why the examples in these scenarios always include it on system-namespace resources.

The control plane computes the remaining ownership labels when it stores the resource. Anything you create in a zone is given `kuma.io/zone` set to that zone's name, and a policy is also given `kuma.io/policy-role`. Don't copy these out of a synced object into new YAML. A `kuma.io/origin` value you write in an application namespace stays on the Kubernetes object but has no effect, because the control plane computes its own value when it reads the resource. A `kuma.io/zone` value naming a different zone is rejected outright.

### Where a resource can live

On Kubernetes, some resource types can only be created in `{{site.mesh_namespace}}`, whichever control plane creates them:

* `MeshIdentity`
* `MeshTrust`
* `MeshExternalService`
* `MeshOpenTelemetryBackend`
* `HostnameGenerator`

Every policy, along with `MeshService`, `MeshMultiZoneService`, and `MeshZoneAddress`, can live in an application namespace instead, as long as a zone control plane owns it. A global control plane accepts no namespace other than `{{site.mesh_namespace}}`, for any kind, and rejects a resource created there with `kuma.io/origin: zone`.

Policies created in an application namespace are already local to that namespace. The control plane labels them `consumer` or `workload-owner`, and a policy with either role selects only proxies in its own namespace. Put a policy in the system namespace only when a platform operator intentionally needs mesh-wide or cross-namespace scope, which gives it the `system` role. See [Policy targeting and precedence](/mesh/policy-targeting-and-precedence/) for how the role affects which policy wins.

## Universal zones

Universal zones do not have Kubernetes namespaces. Point kongctl at the control plane that owns the resource and apply the Universal form there:

```sh
kongctl apply mesh -f mesh-traffic-permission.yaml --control-plane-name "$MESH_CP"
```

Before changing a resource, read its `kuma.io/origin` label:

```sh
kongctl get mesh meshtrafficpermissions --control-plane-name "$MESH_CP" --mesh kong-air-mesh -o yaml
```

Update a global resource through the global control plane and a zone-origin resource through the zone that owns it. For a self-managed control plane, pass `--control-plane-url` with its API address in place of `--control-plane-name`.
