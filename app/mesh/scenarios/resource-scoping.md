---
title: "Understanding Resource Scoping in {{site.mesh_product_name}}"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: Learn why some {{site.mesh_product_name}} resources must be applied to the Global Control Plane, and why certain resources on Kubernetes must live in the system namespace. A foundational guide for operators new to the mesh.
products:
  - mesh
tldr:
  q: How do I know where to apply my Kong Mesh resources?
  a: |
    Resources follow a "Source of Truth" requirement. Global-scoped resources (like `Mesh`) must be applied to the Global CP. Policy resources can often be applied to either the Global or Zone CP. On Kubernetes, infrastructure-level identities must live in a dedicated system namespace.
faqs:
  - q: What happens if I apply a Mesh resource to a Zone CP?
    a: |
      The request will be blocked by the Admission Webhook (on Kubernetes) or the API Server (on Universal) with a `403 Forbidden` error, stating that the resource can only be modified on a Global Control Plane.
  - q: Why can't I apply MeshIdentity to my application namespace?
    a: |
      `MeshIdentity` is a cluster-wide authority. Restricting it to the system namespace (e.g., `kong-mesh-system`) prevents application-level misconfigurations from affecting the entire mesh's security posture.
next_steps:
  - text: "Getting Started: Your First Policy"
    url: "/mesh/scenarios/getting-started-policy/"
---
{{site.mesh_product_name}} can be deployed in two main architectures:

### 1. Standalone Mode (Simple)
In **Standalone mode**, you have a single Control Plane that manages everything. This is common for single Kubernetes clusters or single-site Universal deployments. 
*   **The CP is the only authority.**
*   **All resources** (Meshes, Policies, etc.) are applied directly to this one CP.
*   Scoping rules (Global vs Zone) do not apply because there is only one tier.

### 2. Multi-zone Mode (Production/Scale)
In **Multi-zone mode**, the architecture is split into two distinct tiers:

{% mermaid %}
flowchart TD
    GCP["🌐 Global Control Plane<br/>──────────────────────<br/>Authoritative registry for all meshes<br/>Runs on K8s or Universal server<br/>Syncs config DOWN via KDS"]

    GCP -- "Kuma Distribution Service (KDS)" --> ZCP_EU
    GCP -- "Kuma Distribution Service (KDS)" --> ZCP_US

    ZCP_EU["Zone CP: EU<br/>─────────────<br/>Kubernetes<br/>Zone proxies"]
    ZCP_US["Zone CP: US<br/>─────────────<br/>Universal VM<br/>Zone proxies"]
{% endmermaid %}

The **Global CP** is the single source of truth. It distributes policies and infrastructure resources to all Zone CPs using the **Kuma Distribution Service (KDS)**. 

When a Zone CP is connected to a Global CP, it is technically called a **Federated Zone**. In this state, the Zone CP automatically becomes "read-only" for Global resources, as it now defers to the Global CP as the authoritative leader.

### The Benefits (and Responsibility) of Scale

Separating the **Global** and **Zone** tiers provides massive benefits for a growing organization like Kong Air:

- **Operational Safety**: If the Global CP is offline for maintenance, your Zone CPs keep running. Your flights keep flying, even if you can't push a *new* policy at that exact moment.
- **Geographic Scale**: A Zone CP in `EU` doesn't need to talk to a Zone CP in `US` to handle local traffic. This keeps latency low and reliability high.
- **Security Scoping**: You can grant your `EU` infrastructure team access only to their local Zone CP, while the core platform team manages the Global CP.

**Because of this separation, we have to be specific about where we target our resources.** If we allowed every Zone CP to change the "Master" Mesh settings, we would quickly end up with conflicting configurations and a "split-brain" mesh.

---

## Why This Matters: Who "Owns" Each Resource?

Each resource type in {{site.mesh_product_name}} has a defined **owner**: the tier that is authorised to create, modify, and delete it.

{% danger %}
If you apply a **Global-only** resource to a Zone CP, the resource will be rejected or overwritten when KDS syncs. You may not see an immediate error, making this hard to debug.
{% enddanger %}

### Global CP Only: Mesh Infrastructure

These resources define the **structure** of your mesh. Kong Air's network operations team controls them from a single point of authority.

| Resource | Why Global Only |
| :--- | :--- |
| `Mesh` | Defines a mesh and its mTLS config. Zones receive a read-only copy via KDS. |
| `MeshMultiZoneService` | Declares a service that spans multiple zones. The Global CP is the only entity with the full cross-zone topology picture. |

{% warning %}
**Always apply `Mesh` and `MeshMultiZoneService` to the Global Control Plane.** If your Global CP is Kubernetes-based, use `kubectl apply` against the Global CP kubeconfig. If it is Universal (a standalone server), use `kumactl apply` pointed at the Global CP API.
{% endwarning %}

### Global or Zone CP: Identity & Policy Resources

These resources can be created at either tier and will be synced to the other via KDS. This gives teams flexibility: a security team might manage `MeshIdentity` centrally, while application teams manage `MeshTrafficPermission` locally in their zone.

| Resource | Where to Apply | Notes |
| :--- | :--- | :--- |
| `MeshIdentity` | Global CP **or** Zone CP | Must be in the system namespace on K8s |
| `MeshTrust` | Global CP **or** Zone CP | Must be in the system namespace on K8s |
| `MeshTrafficPermission` | Global CP **or** Zone CP | Any namespace |
| `MeshFaultInjection` | Global CP **or** Zone CP | Any namespace |
| `MeshPassthrough` | Global CP **or** Zone CP | Any namespace |
| `MeshTLS` | Global CP **or** Zone CP | Any namespace |

## The Kubernetes System Namespace Rule

On Kubernetes, resources like **`MeshIdentity`** and **`MeshTrust`** must be created in the **system namespace** (typically `kong-mesh-system`). Here's why.

### Why a system namespace?

`MeshIdentity` is a **cluster-wide identity authority**. It tells every Envoy proxy in the mesh which CA certificate to use when establishing its SPIFFE identity. This is not a per-application setting; it's a certificate authority configuration.

Placing it in the system namespace enforces two key properties:
1. **Access control**: The system namespace is typically restricted to platform engineers, not application developers. This prevents a developer from accidentally (or intentionally) changing the CA for all services in the mesh.
2. **Clear authority**: It signals to operators that this resource is at the "infrastructure" level, just like a `ClusterIssuer` in cert-manager belongs to the platform, not to a single app.

If you `kubectl apply` a `MeshIdentity` into an application namespace (e.g., `kong-air-production`), the API will reject it with a validation error.

### Summary for Kubernetes Users

| Resource | Namespace |
| :--- | :--- |
| `Mesh` | Applied to Global CP (any ns or CRD) |
| `MeshMultiZoneService` | Any namespace |
| `MeshIdentity` | **`kong-mesh-system`** (system namespace only) |
| `MeshTrust` | **`kong-mesh-system`** (system namespace only) |
| `MeshTrafficPermission` | Any namespace (workload or system) |
| `MeshFaultInjection` | Any namespace |
| `MeshPassthrough` | Any namespace |

## Universal Mode: Simpler Scoping

In Universal mode, there are no Kubernetes namespaces. Resources are identified by their `name` and `mesh` fields only. The tiering (Global vs Zone) is determined purely by **which CP API you point `kumactl` at**.

```bash
# Applying to the Global CP
kumactl config control-planes use global-cp
kumactl apply -f mesh.yaml

# Applying to a specific Zone CP
kumactl config control-planes use zone-eu-cp
kumactl apply -f mesh-traffic-permission.yaml
```

{% tip %}
In Universal mode, you can verify which CP you're pointing at with `kumactl get control-planes`.
{% endtip %}

## Quick Reference Card

| Resource | Apply To | K8s Namespace |
| :--- | :--- | :--- |
| `Mesh` | ⚡ Global CP **only** | N/A (Global CP level) |
| `MeshMultiZoneService` | ⚡ Global CP **only** | Any namespace |
| `MeshIdentity` | Global or Zone | 🔒 System NS only |
| `MeshTrust` | Global or Zone | 🔒 System NS only |
| `MeshTrafficPermission` | Global or Zone | ✅ Any namespace |
| `MeshFaultInjection` | Global or Zone | ✅ Any namespace |
| `MeshPassthrough` | Global or Zone | ✅ Any namespace |
| `MeshTLS` | Global or Zone | ✅ Any namespace |

---

## How This Appears in the Documentation

Throughout the {{site.mesh_product_name}} scenario guides, code blocks use tabs to show both Kubernetes and Universal variations. The tab label tells you **which control plane tier** to target:

| Tab Label | Meaning |
| :--- | :--- |
| **`Kubernetes (Global CP)`** | Run `kubectl apply` against your **Global Control Plane** kubeconfig. Only relevant when your Global CP is K8s-hosted. |
| **`Universal (Global CP)`** | Run `kumactl apply` pointed at your **Global CP** API. Applies when the Global CP is a standalone Universal server. |
| **`Kubernetes`** | Run `kubectl apply` against any K8s cluster running a zone CP (or standalone). No Global CP context required. |
| **`Universal`** | Run `kumactl apply` against any Universal zone CP or standalone deployment. |

{% tip %}
When you see the **(Global CP)** qualifier on a tab, that is your signal that only the Global CP has authority over that resource. If you attempt to apply it to a Zone CP, the API or Admission Webhook will block the request with a `Forbidden` error.
{% endtip %}
