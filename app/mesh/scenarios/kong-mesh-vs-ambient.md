---
title: "Kong Mesh vs. Istio Ambient"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: A technical analysis of the trade-offs between sidecar-based {{site.mesh_product_name}} and sidecarless Istio Ambient, focusing on security, latency, and operational simplicity.
products:
  - mesh
next_steps:
  - text: "Istio to {{site.mesh_product_name}}: The Strategic Migration Guide"
    url: "/mesh/scenarios/istio-to-kong-mesh/"
---
When **Kong Air** evaluated their next-generation service mesh, **Istio Ambient**'s promise of "sidecarless" resource efficiency was tempting. However, as a global airline with strict security and latency requirements, Kong Air's platform team knew that CPU usage was only one variable. Factors like **Security Isolation**, **L7 Latency**, and **Architectural Simplicity** were far more critical for their flight-control systems.

## 1. Security: Dedicated Isolation vs. Shared Identity

### {{site.mesh_product_name}} (Sidecar Model)
Every Pod has its own dedicated Envoy sidecar. This provides **Strict Security Isolation**:
*   **Identity per Pod**: Each sidecar has its own unique certificate (via SPIFFE). If one sidecar is compromised, the blast radius is limited to that single Pod.
*   **Encryption at the Edge**: Traffic is encrypted and decrypted within the Pod boundary.

### Istio Ambient (Shared Model)
Ambient uses a shared **ztunnel** proxy per Node for L4 traffic.
*   **Shared Identity**: Multiple Pods on the same node share the same proxy. This introduces a shared security domain where a compromise of the ztunnel could impact every Pod on that node.
*   **Identity Impersonation**: The ztunnel must "impersonate" different identities as it handles traffic for various Pods, increasing the complexity and risk of the identity system.

## 2. The "L7 Tax": Waypoint vs. Local Sidecar

Ambient claims to be faster by removing sidecars, but this only applies to simple L4 traffic. When you need **L7 features** (Retries, URL Routing, AuthZ, Observability), Ambient introduces a "Waypoint" proxy.

| Feature | {{site.mesh_product_name}} (Sidecar) | Istio Ambient (Waypoint) |
| :--- | :--- | :--- |
| **L7 Hop Count** | 0 extra hops (local) | **1 extra network hop** (per direction) |
| **Logic Placement** | Inside the Pod | On a separate node or shared proxy |
| **Latency Consistency**| Highly Predictable | Variable (dependant on node-to-node network) |

{% warning %}
Because Waypoint proxies are separate from your application Pods, L7 traffic must leave the node, travel to a Waypoint, be processed, and then travel back to the destination. In many cases, this **negates the latency gains** touted by sidecarless architectures.
{% endwarning %}

## 3. Operational Simplicity: One Proxy vs. Three

Managing a service mesh is an operational burden. {{site.mesh_product_name}} simplifies this by having exactly one type of data plane component: the Sidecar.

In contrast, Istio Ambient requires you to manage and troubleshoot a three-tier system:
1.  **Ztunnel**: Shared per-node proxy (Rust-based).
2.  **Waypoint**: Shared L7 proxy (Envoy-based).
3.  **Istio CNI**: A complex plugin required to redirect traffic into the ztunnel.

## 4. Multi-Platform Consistency (Universal)

Enterprise environments are rarely 100% Kubernetes. You likely have legacy workloads on **Linux VMs** or **Bare Metal**.
*   **{{site.mesh_product_name}}**: Use the same Envoy sidecar and the same policies on VMs and K8s. Your operational model is identical.
*   **Istio Ambient**: Does not natively support VMs in the sidecarless model. You end up with a "Hybrid" mess: Ambient for K8s and traditional sidecars for VMs, doubling your operational complexity.

## Summary Table: Why Resource Usage Isn't Everything

| Metric | {{site.mesh_product_name}} (Sidecar) | Istio Ambient |
| :--- | :--- | :--- |
| **Resource Usage** | Slightly Higher | **Winner (L4 only)** |
| **Security Isolation** | **Winner (Strict per-Pod)** | Shared per-Node |
| **L7 Latency** | **Winner (Local processing)** | Cross-node hops required |
| **VM Compatibility** | **Winner (Native/Universal)** | Not Supported |
| **Troubleshooting** | Predictable (Pod logs) | Complex (Ztunnel + Waypoint) |
