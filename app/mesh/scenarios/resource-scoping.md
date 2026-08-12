---
title: Resource scoping
content_type: reference
layout: reference
description: Learn why some {{site.mesh_product_name}} resources must be applied to the global control plane, and why certain resources on Kubernetes must live in the system namespace. A foundational guide for operators new to the mesh.
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
  - text: Federate a zone control plane
    url: /mesh/federate-zone/
---
{{site.mesh_product_name}} splits configuration authority between two types of control planes: a global control plane and a zone control plane. This page covers which type owns a given resource, and where that resource must live on Kubernetes.

## Deployment architectures

Whether scoping rules apply at all depends on which of these two architectures you're running:

### Non-federated zone

A non-federated zone is a zone control plane that isn't connected to a global CP. This is common for single Kubernetes clusters or single-site Universal deployments. For more information, see [Single-zone deployment](/mesh/single-zone/). In a single zone deployment:

* The zone CP is the only authority. There's no global CP to defer to.
* All resources (meshes, policies, and so on) are applied directly to the zone CP.
* Scoping rules (global vs. zone) don't apply, because there's only one type of control plane.
* You can later [federate the zone](/mesh/federate/) into a global CP without redeploying.

### Federated multi-zone

In a federated multi-zone deployment, the architecture splits into two distinct parts. The following diagram shows the architecture of a multi-zone deployment. For more information, see [Multi-zone deployment](/mesh/mesh-multizone-service-deployment/).

{% mermaid %}
flowchart TD
    GCP["Global control plane<br/>Authoritative registry for all meshes<br/>Syncs config down via KDS"]

    GCP -- "Kuma Discovery Service (KDS)" --> ZCP_EU
    GCP -- "Kuma Discovery Service (KDS)" --> ZCP_US

    ZCP_EU["Zone CP: EU<br/>Kubernetes<br/>zone proxies"]
    ZCP_US["Zone CP: US<br/>Universal VM<br/>zone proxies"]
{% endmermaid %}

The global CP is the single source of truth. It distributes policies and infrastructure resources to every zone CP over the Kuma Discovery Service (KDS). Once a zone CP connects to a global CP, it's called a federated zone: it becomes read-only for global resources and defers to the global CP as the authoritative leader.

This is useful as an organization like Kong Air grows:

* **Operational safety**: if the global CP is offline for maintenance, zone CPs keep running.
* **Geographic scale**: a zone CP in `EU` doesn't need to talk to a zone CP in `US` to handle local traffic, which keeps latency low and reliability high.
* **Security scoping**: you can grant the `EU` infrastructure team access to only their local zone CP, while the core platform team manages the global CP.

That separation is why targeting is important: if any zone CP could change global `Mesh` settings, you'd quickly end up with conflicting configuration.

## Resource ownership

Each resource type has a defined owner: the control plane type that can create, modify, and delete it. On Kubernetes, some resources are further restricted to the system namespace (`{{site.mesh_namespace}}`).

<!-- vale off -->
{% table %}
columns:
  - title: Resource
    key: resource
  - title: Scope
    key: scope
  - title: K8s namespace
    key: k8s_namespace
  - title: Why
    key: why
rows:
  - resource: |
      `Mesh`
    scope: |
      Global CP only
    k8s_namespace: |
      System namespace
    why: |
      Defines a mesh and its mTLS config. Zones receive a read-only copy via KDS.
  - resource: |
      `MeshMultiZoneService`
    scope: |
      Global CP only
    k8s_namespace: |
      System namespace
    why: |
      Declares a service that spans multiple zones. Only the global CP has the full cross-zone topology.
  - resource: |
      `MeshIdentity`
    scope: |
      Global or zone CP
    k8s_namespace: |
      System namespace
    why: |
      A cluster-wide identity authority. Restricting it to the system namespace keeps CA changes in platform engineers' hands.
  - resource: |
      `MeshTrust`
    scope: |
      Global or zone CP
    k8s_namespace: |
      System namespace
    why: |
      Same authority-scoping rationale as `MeshIdentity`.
  - resource: |
      `MeshTrafficPermission`
    scope: |
      Global or zone CP
    k8s_namespace: |
      Any namespace
    why: |
      A workload-level policy. Application teams can manage it in their own namespace.
  - resource: |
      `MeshFaultInjection`
    scope: |
      Global or zone CP
    k8s_namespace: |
      Any namespace
    why: |
      A workload-level policy.
  - resource: |
      `MeshPassthrough`
    scope: |
      Global or zone CP
    k8s_namespace: |
      Any namespace
    why: |
      A workload-level policy.
  - resource: |
      `MeshTLS`
    scope: |
      Global or zone CP
    k8s_namespace: |
      Any namespace
    why: |
      A workload-level policy.
{% endtable %}
<!-- vale on -->

The "global or zone CP" resources sync to the other control plane type over KDS either way, so a security team can manage `MeshIdentity` centrally while application teams manage `MeshTrafficPermission` locally in their own zone.

{:.warning}
> Apply `Mesh` and `MeshMultiZoneService` only to the global CP. On a Kubernetes-hosted global CP, use `kubectl apply` against its kubeconfig and the system namespace; arbitrary namespaces and CRDs aren't supported. On a Universal global CP, use `kumactl apply` against its API.

## Kubernetes system namespace

`MeshIdentity` is a cluster-wide identity authority: it tells every Envoy proxy in the mesh which CA certificate to use when establishing its SPIFFE identity. That's not a per-application setting, it's a certificate authority configuration, which is why it (along with `MeshTrust`) must be created in the system namespace (typically `kong-mesh-system`) rather than an application namespace.

Placing it in the system namespace enforces two properties:

* **Access control**: the system namespace is typically restricted to platform engineers, not application developers. This prevents a developer from accidentally, or intentionally, changing the CA for every service in the mesh.
* **Clear authority**: it signals to operators that the resource is infrastructure-level, the same way a `ClusterIssuer` in cert-manager belongs to the platform rather than to a single app.

## Universal mode scoping

In Universal mode, there are no Kubernetes namespaces. Resources are identified by their `name` and `mesh` fields only, and the control plane type (global vs. zone) is determined purely by which CP API you point `kumactl` at:

```bash
# Applying to the global CP
kumactl config control-planes use global-cp
kumactl apply -f mesh.yaml

# Applying to a specific zone CP
kumactl config control-planes use zone-eu-cp
kumactl apply -f mesh-traffic-permission.yaml
```

{:.info}
> Verify which CP you're pointing at with `kumactl get control-planes`.
