---
title: Resource scoping
content_type: reference
layout: reference
description: Learn why some {{site.mesh_product_name}} resources must be applied to the Global Control Plane, and why certain resources on Kubernetes must live in the system namespace. A foundational guide for operators new to the mesh.
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
    url: "/mesh/scenarios/split-traffic-with-meshservice-resources/"
related_resources:
  - text: Single-zone deployment
    url: /mesh/single-zone/
  - text: Multi-zone deployment
    url: /mesh/mesh-multizone-service-deployment/
  - text: Federate a zone Control Plane
    url: /mesh/federate-zone/
---
{{site.mesh_product_name}} can be deployed in two main architectures:

### Non-federated zone (single CP)
A **non-federated zone** is a Zone CP that is not connected to a Global CP. This is common for single Kubernetes clusters or single-site Universal deployments; see [Single-zone deployment](/mesh/single-zone/) for how to set one up.
*   **The Zone CP is the only authority.**
*   **All resources** (Meshes, Policies, etc.) are applied directly to this one CP.
*   Scoping rules (Global vs Zone) do not apply because there is only one tier.
*   You can later [federate the zone](/mesh/federate-zone/) into a Global CP without redeploying.

### Federated multi-zone (production/scale)
In a **federated multi-zone deployment**, the architecture is split into two distinct tiers. See [Multi-zone deployment](/mesh/mesh-multizone-service-deployment/) for how to connect zones, and [Federate a zone Control Plane](/mesh/federate-zone/) for joining an existing zone to a Global CP.

{% mermaid %}
flowchart TD
    GCP["🌐 Global Control Plane<br/>──────────────────────<br/>Authoritative registry for all meshes<br/>Typically a standalone deployment backed by a PostgreSQL database<br/>Syncs config DOWN via KDS"]

    GCP -- "Kuma Discovery Service (KDS)" --> ZCP_EU
    GCP -- "Kuma Discovery Service (KDS)" --> ZCP_US

    ZCP_EU["Zone CP: EU<br/>─────────────<br/>Kubernetes<br/>Zone proxies"]
    ZCP_US["Zone CP: US<br/>─────────────<br/>Universal VM<br/>Zone proxies"]
{% endmermaid %}

The **Global CP** is the single source of truth. It distributes policies and infrastructure resources to all Zone CPs using the **Kuma Discovery Service (KDS)**. 

When a Zone CP is connected to a Global CP, it is technically called a **Federated Zone**. In this state, the Zone CP automatically becomes "read-only" for Global resources, as it now defers to the Global CP as the authoritative leader.

### The benefits (and responsibility) of scale

Separating the **Global** and **Zone** tiers provides massive benefits for a growing organization like Kong Air:

- **Operational Safety**: If the Global CP is offline for maintenance, your Zone CPs keep running. Your flights keep flying, even if you can't push a *new* policy at that exact moment.
- **Geographic Scale**: A Zone CP in `EU` doesn't need to talk to a Zone CP in `US` to handle local traffic. This keeps latency low and reliability high.
- **Security Scoping**: You can grant your `EU` infrastructure team access only to their local Zone CP, while the core platform team manages the Global CP.

Because of this separation, you must be specific about where you target resources. If we allowed every Zone CP to change the "Main" Mesh settings, we would quickly end up with conflicting configurations and a "split-brain" mesh.

---

## Why this matters: who "owns" each resource?

Each resource type in {{site.mesh_product_name}} has a defined **owner**: the tier that is authorized to create, modify, and delete it.

### Global CP only: mesh infrastructure

These resources define the **structure** of your mesh. Kong Air's network operations team controls them from a single point of authority.

<!-- vale off -->
{% table %}
columns:
  - title: Resource
    key: resource
  - title: Why Global Only
    key: why_global_only
rows:
  - resource: |
      `Mesh`
    why_global_only: |
      Defines a mesh and its mTLS config. Zones receive a read-only copy via KDS.
  - resource: |
      `MeshMultiZoneService`
    why_global_only: |
      Declares a service that spans multiple zones. The Global CP is the only entity with the full cross-zone topology picture.
{% endtable %}
<!-- vale on -->

{:.warning}
> Always apply `Mesh` and `MeshMultiZoneService` to the Global Control Plane. If your Global CP runs on Kubernetes, use `kubectl apply` against the Global CP kubeconfig and place the resource in the system namespace. On a Kubernetes-native Global CP you cannot use arbitrary namespaces or CRDs; only the system namespace ({{site.mesh_namespace}}) is supported. If it is Universal, use `kumactl apply` pointed at the Global CP API.

### Global or Zone CP: identity & policy resources

These resources can be created at either tier and will be synced to the other via KDS. This gives teams flexibility: a security team might manage `MeshIdentity` centrally, while application teams manage `MeshTrafficPermission` locally in their zone.

<!-- vale off -->
{% table %}
columns:
  - title: Resource
    key: resource
  - title: Where to Apply
    key: where_to_apply
  - title: Notes
    key: notes
rows:
  - resource: |
      `MeshIdentity`
    where_to_apply: |
      Global CP **or** Zone CP
    notes: |
      Must be in the system namespace on K8s
  - resource: |
      `MeshTrust`
    where_to_apply: |
      Global CP **or** Zone CP
    notes: |
      Must be in the system namespace on K8s
  - resource: |
      `MeshTrafficPermission`
    where_to_apply: |
      Global CP **or** Zone CP
    notes: |
      Any namespace
  - resource: |
      `MeshFaultInjection`
    where_to_apply: |
      Global CP **or** Zone CP
    notes: |
      Any namespace
  - resource: |
      `MeshPassthrough`
    where_to_apply: |
      Global CP **or** Zone CP
    notes: |
      Any namespace
  - resource: |
      `MeshTLS`
    where_to_apply: |
      Global CP **or** Zone CP
    notes: |
      Any namespace
{% endtable %}
<!-- vale on -->

## The Kubernetes system namespace rule

On Kubernetes, resources like **`MeshIdentity`** and **`MeshTrust`** must be created in the **system namespace** (typically `kong-mesh-system`). 

### Why a system namespace?

`MeshIdentity` is a **cluster-wide identity authority**. It tells every Envoy proxy in the mesh which CA certificate to use when establishing its SPIFFE identity. This is not a per-application setting; it's a certificate authority configuration.

Placing it in the system namespace enforces two key properties:
1. **Access control**: The system namespace is typically restricted to platform engineers, not application developers. This prevents a developer from accidentally (or intentionally) changing the CA for all services in the mesh.
2. **Clear authority**: It signals to operators that this resource is at the "infrastructure" level, just like a `ClusterIssuer` in cert-manager belongs to the platform, not to a single app.

### Summary for Kubernetes users

<!-- vale off -->
{% table %}
columns:
  - title: Resource
    key: resource
  - title: Namespace
    key: namespace
rows:
  - resource: |
      `Mesh`
    namespace: |
      Applied to the Global CP (system namespace only)
  - resource: |
      `MeshMultiZoneService`
    namespace: |
      Applied to the Global CP, in the system namespace
  - resource: |
      `MeshIdentity`
    namespace: |
      **`kong-mesh-system`** (system namespace only)
  - resource: |
      `MeshTrust`
    namespace: |
      **`kong-mesh-system`** (system namespace only)
  - resource: |
      `MeshTrafficPermission`
    namespace: |
      Any namespace (workload or system)
  - resource: |
      `MeshFaultInjection`
    namespace: |
      Any namespace
  - resource: |
      `MeshPassthrough`
    namespace: |
      Any namespace
{% endtable %}
<!-- vale on -->

## Universal mode: simpler scoping

In Universal mode, there are no Kubernetes namespaces. Resources are identified by their `name` and `mesh` fields only. The control plane tier (Global vs Zone) is determined purely by **which CP API you point `kumactl` at**.

```bash
# Applying to the Global CP
kumactl config control-planes use global-cp
kumactl apply -f mesh.yaml

# Applying to a specific Zone CP
kumactl config control-planes use zone-eu-cp
kumactl apply -f mesh-traffic-permission.yaml
```

{:.info}
> In Universal mode, you can verify which CP you're pointing at with `kumactl get control-planes`.

## Quick reference

<!-- vale off -->
{% table %}
columns:
  - title: Resource
    key: resource
  - title: Apply To
    key: apply_to
  - title: K8s Namespace
    key: k8s_namespace
rows:
  - resource: |
      `Mesh`
    apply_to: |
      Global CP **only**
    k8s_namespace: |
      System NS on K8s
  - resource: |
      `MeshMultiZoneService`
    apply_to: |
      Global CP **only**
    k8s_namespace: |
      System NS on K8s
  - resource: |
      `MeshIdentity`
    apply_to: |
      Global or Zone
    k8s_namespace: |
      System NS only
  - resource: |
      `MeshTrust`
    apply_to: |
      Global or Zone
    k8s_namespace: |
      System NS only
  - resource: |
      `MeshTrafficPermission`
    apply_to: |
      Global or Zone
    k8s_namespace: |
      Any namespace
  - resource: |
      `MeshFaultInjection`
    apply_to: |
      Global or Zone
    k8s_namespace: |
      Any namespace
  - resource: |
      `MeshPassthrough`
    apply_to: |
      Global or Zone
    k8s_namespace: |
      Any namespace
  - resource: |
      `MeshTLS`
    apply_to: |
      Global or Zone
    k8s_namespace: |
      Any namespace
{% endtable %}
<!-- vale on -->


## How this appears in the documentation

Throughout the {{site.mesh_product_name}} scenario guides, code blocks use tabs to show both Kubernetes and Universal variations. The tab label tells you **which control plane tier** to target:

<!-- vale off -->
{% table %}
columns:
  - title: Tab Label
    key: tab_label
  - title: Meaning
    key: meaning
rows:
  - tab_label: |
      **`Kubernetes (Global CP)`**
    meaning: |
      Run `kubectl apply` against your **Global Control Plane** kubeconfig. Only relevant when your Global CP is K8s-hosted.
  - tab_label: |
      **`Universal (Global CP)`**
    meaning: |
      Run `kumactl apply` pointed at your **Global CP** API. Applies when the Global CP is a standalone Universal server.
  - tab_label: |
      **`Kubernetes`**
    meaning: |
      Run `kubectl apply` against any K8s cluster running a zone CP (or standalone). No Global CP context required.
  - tab_label: |
      **`Universal`**
    meaning: |
      Run `kumactl apply` against any Universal zone CP or standalone deployment.
{% endtable %}
<!-- vale on -->

{:.info}
> When you see the **(Global CP)** qualifier on a tab, that is your signal that only the Global CP has authority over that resource. If you attempt to apply it to a Zone CP, the API or Admission Webhook will block the request with a `Forbidden` error.
