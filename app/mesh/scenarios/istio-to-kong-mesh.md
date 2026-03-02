---
title: "Istio to Kong Mesh: Migration Guide"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: A comprehensive technical and strategic guide for platform engineers comparative features and migrating complex service mesh environments from Istio to {{site.mesh_product_name}} with zero downtime.
products:
  - mesh
next_steps:
  - text: "Back to Learning Path"
    url: "/mesh/scenarios/"
---
For **Kong Air**, migrating from Istio was a strategic necessity to simplify their global flight operations. By moving to {{site.mesh_product_name}}, they gained native multi-platform support (VMs + K8s) and a unified security model that bridged their legacy data centers and modern cloud regions.

## 1. Architectural Philosophy: Simplicity by Design

When comparing Istio and {{site.mesh_product_name}}, the difference is primarily one of philosophy:

| Feature | Istio | {{site.mesh_product_name}} |
| :--- | :--- | :--- |
| **Mindset** | Kubernetes-Centric | Universal (K8s, VMs, Bare Metal) |
| **Scaling** | Global Config (Sidecar Bloat) | Scoped Intent (`targetRef`) |
| **Multi-Zone** | Primary-Remote (High Complexity) | Global/Zone (Native & Simple) |
| **Policies** | Fragmented (VS, DR, PeerAuth) | Unified (TargetRef for everything) |
| **Security** | Opaque (Citadel/Cert-manager) | Native (Built-in CAs & Trust Domain) |

### Simplicity Snapshot: The "Day 2" Difference

Platform engineers often find that while "Day 1" (installation) is comparable, "Day 2" (operations) is where {{site.mesh_product_name}} shines:

*   **Unified Management**: In Istio, a multi-zone setup requires managing shared secrets, multiple gateways, and manual endpoint discovery across clusters. In {{site.mesh_product_name}}, you deploy the Global CP, connect the Zone CPs, and the mesh handles the rest: federation is a first-class citizen, not a bolt-on.
*   **Reduced Resource Sprawl**: Instead of maintaining a portfolio of `VirtualServices` and `DestinationRules` per application, you use a single `MeshHTTPRoute`. This reduces cognitive load and simplifies debugging.
*   **Zero-Overhead Scaling**: {{site.mesh_product_name}}'s `targetRef` system prevents the "Global Broadcast" problem, ensuring that as you scale from 10 to 1,000 services, your proxy memory footprint remains lean and predictable.

### Why Platform Teams Migrate
*   **Operational Simplicity**: {{site.mesh_product_name}} eliminates the need to manage secret sharing and port-forwarding for multi-cluster synchronization.
*   **Performance at Scale**: The native `targetRef` system ensures proxies only hold the config they need, keeping memory usage low.
*   **Enterprise Compliance**: Native integration with HashiCorp Vault, FIPS support, and cross-platform consistency for hybrid cloud.

---

## 2. Technical Comparison: The Scalability Gap

### Enforcement Scoping vs. Global Broadcast
In Istio, configuration is globally scoped by default. A single `VirtualService` is broadcast to every proxy, leading to high control plane CPU and sidecar memory bloat.

{{site.mesh_product_name}} uses **Enforcement Scoping**. When you apply a policy to a `MeshService`, the Control Plane only sends those updates to the relevant proxies.

### Endpoint Visibility: Reachable Services
While both meshes provide ways to limit endpoint distribution, {{site.mesh_product_name}} automates this via `autoReachableServices`. Istio requires the high-maintenance `Sidecar` CRD whitelist approach, where missing an entry leads to runtime failures (404/503).

### What about Istio Ambient?
Ambient mode aims to reduce the "sidecar tax," but introduces trade-offs:
*   **Security**: Shared "ztunnels" on nodes increase the blast radius compared to {{site.mesh_product_name}}'s per-pod isolation.
*   **Latency**: L7 features require "Waypoint" proxies, adding extra network hops.
*   **Complexity**: Operates as a three-tier system (ztunnel, Waypoint, CNI) instead of {{site.mesh_product_name}}'s single-proxy model.

---

## 3. Migration Architecture: The Parallel Bridge

Use a **Bridge Architecture** to migrate without downtime. Trust domain federation allows products in both meshes to communicate via mTLS during the transition.

{% mermaid %}
graph LR
    subgraph IstioCluster["Istio Cluster"]
        ISvc[Istio Service] --> IGW[istio-ingressgateway]
    end
    
    IGW -.-> KG["Kong Gateway (Gateway API)"]
    
    subgraph KongCluster["{{site.mesh_product_name}} Cluster"]
        KG --> KSvc[{{site.mesh_product_name}} Service]
    end
    
    style IGW fill:#f9f,stroke:#333,stroke-width:2px
    style KG fill:#69f,stroke:#333,stroke-width:2px
{% endmermaid %}

### Bridging Strategies
*   **Layer 4 Connectivity**: Routable IP spaces or **Kong Gateway** to expose services.
*   **Trust Domain Federation**: Use `MeshTrust` to allow {{site.mesh_product_name}} to trust certificates issued by Istio's Citadel, enabling cross-mesh mTLS.

---

## 4. Policy Mapping Deep-Dive

### Traffic Routing: VirtualService -> MeshHTTPRoute
Istio's "Host-based" routing maps 1-to-1 with {{site.mesh_product_name}}'s "Targeting" model.

{% warning %}
**Terminology Bridge:**
*   **`to`**: Like Istio's `hosts`. The "Original Destination".
*   **`backendRefs`**: Like Istio's `destination.host`. Where traffic is forwarded.
{% endwarning %}

**Example: The "Reroute" Pattern**
Intercept traffic for `api-v1` and send it to `api-v2`.

```yaml
# Istio VirtualService (Before)
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
spec:
  hosts:
  - api-v1
  http:
  - route:
    - destination:
        host: api-v2
```

```yaml
# {{site.mesh_product_name}} HTTPRoute (After)
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: api-v1
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                name: api-v2
                weight: 100
```

### Case Study: Locality-Aware Failover
In Istio, failover is a "Three-Way Handshake": `MeshConfig` (Enable) + `DestinationRule` (Define) + `OutlierDetection` (Trigger). 

In {{site.mesh_product_name}}, it's a single `MeshLoadBalancingStrategy` policy targeted to the service.

---

## 5. Operational Cheat Sheet

### CLI Equivalence
| Goal | `istioctl` | `kumactl` |
| :--- | :--- | :--- |
| **Check Health** | `proxy-status` | `inspect dataplanes` |
| **View Config** | `proxy-config all` | `inspect dataplanes --type=config` |
| **Proxy Stats** | `dashboard envoy` | `inspect dataplanes --type=stats` |

### Sidecar Lifecycle
*   **Startup**: {{site.mesh_product_name}} handles proxy-readiness natively via the sidecar injector.
*   **Probes**: {{site.mesh_product_name}} handles probe redirection automatically; no `rewriteAppHTTPProbe` needed.

---

## 6. Common Pitfalls to Avoid

1.  **Duplicate Injection**: Never label a namespace with both mesh injectors.
2.  **DNS Overlap**: Use `HostnameGenerator` to prevent collision of `.cluster.local` names.
3.  **Default Deny**: Apply a global `MeshTrafficPermission` permit rule *before* enabling mTLS if moving from Istio's "Allow All".
