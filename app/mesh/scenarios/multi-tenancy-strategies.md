---
title: Multi-Tenancy
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: Explore multi-tenancy models in {{site.mesh_product_name}}, comparing soft multi-tenancy (shared mesh) with hard multi-tenancy (isolated meshes) for identity, security, and operational decoupling.
products:
  - mesh
next_steps:
  - text: "Global Canary Releases"
    url: "/mesh/scenarios/global-canary-releases/"
---
Multi-tenancy allows multiple teams or applications to share the same {{site.mesh_product_name}} infrastructure while maintaining appropriate levels of isolation. {{site.mesh_product_name}} supports two primary models: **Soft Multi-Tenancy** (shared trust) and **Hard Multi-Tenancy** (isolated trust).

## 1. Soft Multi-Tenancy: Shared Mesh

In this model, multiple teams share a single logical mesh. This is the most common approach for organizations that want a balance between isolation and ease of management.

### Architecture: 1 Team -> N Namespaces
Teams are assigned one or more Kubernetes namespaces (or Universal environments) within a single mesh.
*   **Shared Cluster**: Multiple teams run their workloads on the same physical infrastructure.
*   **mTLS for Zero-Trust**: All services within the mesh use the same Root CA. Traffic is encrypted and authenticated by default.
*   **Shared Services**: It is easy for Team A to consume a service provided by Team B, as they are part of the same trust domain. Access is controlled via `MeshTrafficPermission` policies.
*   **Centralized Operations**: A central platform team typically manages the mesh infrastructure and global policies.

## 2. Hard Multi-Tenancy: Isolated Meshes

For organizations requiring strict isolation (e.g., highly regulated environments or distinct business units), the hard multi-tenancy model provides complete separation.

### Architecture: 1 Team -> 1 Mesh
Each team is assigned its own dedicated mesh.
*   **Isolated Trust Domains**: Each mesh has its own unique Root CA. A sidecar in Mesh A cannot communicate with a sidecar in Mesh B without explicitly traversing a gateway.
*   **mTLS with Different CAs**: Even if teams share the same cluster, their identity systems are completely decoupled.
*   **Decoupled Operations**: Teams have full autonomy over their mesh. They can manage their own CI/CD pipelines, policy lifecycles, and configuration without affecting other teams.
*   **Policy Scope**: Policies applied to Mesh A are physically and logically invisible to Mesh B.

## Comparison: Soft vs. Hard Multi-Tenancy

| Feature | Soft (Shared Mesh) | Hard (Isolated Meshes) |
| :--- | :--- | :--- |
| **Trust Domain** | Single Shared Root CA | Unique Root CA per Mesh |
| **Identity Scope** | Global across mesh | Local to each mesh |
| **Communication** | Direct (mTLS) | Via Cross-Mesh Gateways |
| **Policy Management**| Centralized/Federated | Completely Decentralized |
| **Operational Overhead**| Low | Higher (per-mesh management) |
| **Recommended for** | Intra-org internal services | High-compliance, B2B, or separate LOBs |

## Decoupling CI/CD and Policy Scope

{{site.mesh_product_name}} allows you to decouple the lifecycle of application delivery from the lifecycle of mesh policies.

*   **Policy Ownership**: Use Kubernetes RBAC or {{site.mesh_product_name}} permissions to define who can create/edit specific policies. For example, a "Security" role might own `MeshTLS`, while "Developers" own `MeshHTTPRoute`.
*   **Pipeline Segregation**: In a multi-mesh model, pipelines are naturally segregated by the `mesh` field in the policy metadata. This ensures that an errant policy update in a development mesh cannot impact a production mesh.
*   **Versioned Policies**: Treat your Mesh policies as code (GitOps). Store them alongside your application manifests and use the same delivery pipelines to ensure consistency across environments.

---

Whether you choose a shared mesh for simplicity or isolated meshes for strict security, {{site.mesh_product_name}} provides the flexibility to support your organization's evolving multi-tenancy requirements.
