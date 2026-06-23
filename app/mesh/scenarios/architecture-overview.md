---
title: Architecture Overview
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: A detailed overview of the {{site.mesh_product_name}} architecture, explaining the relationship between Global/Zone control planes and the Envoy-based data plane.
products:
  - mesh
next_steps:
  - text: "Getting Started: Your First Policy"
    url: "/mesh/scenarios/getting-started-policy/"
---
{{site.mesh_product_name}} separates the **Control Plane** (the brain) from the **Data Plane** (the muscle) and introduces a multi-zone model for distributed environments. For an organization like **Kong Air**, this architecture enables a unified management layer that spans from legacy booking systems to modern cloud-native APIs.

## Core architecture pillars

{% table %}
columns:
  - title: Pillar
    key: pillar
  - title: Role
    key: role
  - title: Key components
    key: components
rows:
  - pillar: Control Plane
    role: "Manages mesh state and policy distribution."
    components: |
      * **Global CP**: Central authority for policies and resource registry.
      * **Zone CP**: Discovers local services and distributes xDS config to Envoy.
  - pillar: Data Plane
    role: "Enforces policies and intercepts traffic."
    components: |
      * **Envoy Proxy**: Sidecar proxy running alongside application instances. Enforces mTLS, retries, and rate limits.
  - pillar: Networking
    role: "Enables secure cross-zone communication."
    components: |
      * **ZoneIngress**: Entry point for cross-zone traffic.
      * **ZoneEgress**: Exit point for outgoing mesh traffic.
  - pillar: Service Model
    role: "Standardized service discovery."
    components: |
      * **MeshService**: Defines services within a single zone. These may be generated automatically for workloads, or authored explicitly when Kong Air needs stable, named rollout targets like `passenger-portal-v1` and `passenger-portal-v2`.
      * **MeshMultiZoneService**: Aggregates services across zones for failover.
      * **MeshExternalService**: Manages traffic to services outside the mesh.
  - pillar: Workload Identity
    role: "Issues and validates SPIFFE identities for every workload."
    components: |
      * **MeshIdentity**: The system of record for workload identity. Supports `Bundled`, `Spire`, and `Extension` providers.
      * **MeshTrust**: Declares trusted CA bundles per trust domain. By default, the control plane can generate a `MeshTrust` from a `MeshIdentity`, but operators can also manage it explicitly.
{% endtable %}

{% tip %}
These scenarios set **`meshServices.mode: Exclusive`** on the `kong-air-mesh` `Mesh` resource:

```yaml
spec:
  meshServices:
    mode: Exclusive
```

In Exclusive mode, the control plane generates a first-class `MeshService` resource for every workload, and policies address those `MeshService` objects directly instead of the older `kuma.io/service` tags. This is the modern model the rest of these scenarios assume, and it is a prerequisite for features like mesh-scoped zone proxies. You'll see it listed as a prerequisite in the hands-on guides that follow.
{% endtip %}

## Day-2 operations: how this compares to Istio-style meshes

Many teams arrive at {{site.mesh_product_name}} from an **Istio-style mesh**, the model built around multiple traffic-management CRDs (`VirtualService`, `DestinationRule`, `ServiceEntry`) on a Kubernetes-first control plane. These are mature, capable meshes, and most of what these scenarios cover (mTLS, traffic routing, observability) works well in either. Standing a mesh up on **day 1** is a solved problem either way. The differences that matter show up on **day 2**: once the mesh is in production, spanning regions, and being operated, upgraded, and debugged by a team. {{site.mesh_product_name}}'s design choices are aimed at reducing the operational surface area you carry through that phase.

{% table %}
columns:
  - title: Day-2 concern
    key: concern
  - title: Istio-style mesh
    key: istio
  - title: "{{site.mesh_product_name}}"
    key: mesh
rows:
  - concern: Reasoning about a policy
    istio: "A single behavior can span several resources, routing in `VirtualService`, load balancing and outlier detection in `DestinationRule`, external hosts in `ServiceEntry`. (Newer versions are adopting the Kubernetes Gateway API for routing.)"
    mesh: "One policy per concern, all sharing the same `targetRef` structure, fewer interacting resource types to reason about when you're troubleshooting a production issue."
  - concern: Running across regions
    istio: "Multi-cluster is assembled from topologies you choose and maintain (multi-primary, primary-remote)."
    mesh: "A built-in **Global / Zone** model with automatic KDS sync. Adding a region means adding a Zone CP, not redesigning a topology, and if the Global CP is offline, each Zone CP keeps serving its last-known config, so data-plane traffic is unaffected."
  - concern: Hybrid estate (VMs + Kubernetes)
    istio: "Kubernetes-native; VMs run through `WorkloadEntry` / `WorkloadGroup`."
    mesh: "Kubernetes and **Universal** (VMs, bare metal) use the same resource model, so one team operates one mesh across both, no separate paradigm for the legacy estate."
{% endtable %}

It comes down to operational surface area: fewer resource types to reason about, multi-region as a deployment mode rather than a topology you build and maintain, and one model across Kubernetes and VMs. For a team that has to *run* the mesh, not just install it, that compounds over time.

---

## {{site.mesh_product_name}} architecture

We use two diagrams: a **high-level view** of how the control plane is distributed, and a **zone-level view** of how data plane traffic flows.

**Legend (used in both diagrams):**

- **Solid arrow** → data-plane traffic (encrypted with mTLS between sidecars).
- **Dashed arrow** ⇢ control-plane channel (xDS, KDS, admin API).
- **Box border** indicates the control plane that owns the resource (Global CP or a specific Zone CP).

### 1. High-level: Global CP and Zone CPs

The Global CP is the single source of truth for the mesh. Each zone runs its own Zone CP, which syncs from the Global CP over the Kuma Discovery Service (KDS) and serves xDS to the local data planes.

{% mermaid %}
flowchart TD
    GUI["Konnect / kumactl"]
    GCP["Global Control Plane"]
    Z1CP["Zone CP<br/>(Kubernetes, zone1)"]
    Z2CP["Zone CP<br/>(Universal VM, zone2)"]
    DP1["Data planes<br/>(Envoy sidecars)"]
    DP2["Data planes<br/>(Envoy sidecars)"]

    GUI -.- GCP
    GCP -.->|KDS| Z1CP
    GCP -.->|KDS| Z2CP
    Z1CP -.->|xDS| DP1
    Z2CP -.->|xDS| DP2
{% endmermaid %}

Everything in this diagram is a **control-plane** channel, no application traffic crosses these links. If the Global CP goes offline, Zone CPs continue to serve their last-known config to local data planes; the mesh stays operational.

### 2. Zone-level: how a request flows

Inside a zone, every workload runs alongside an Envoy sidecar. Sidecars enforce mTLS, retries, timeouts, and access policy. Cross-zone calls go through ZoneIngress and ZoneEgress.

{% mermaid %}
flowchart LR
    subgraph ZoneEast["zone1 (Kubernetes)"]
        ZECP["Zone CP"]
        KG["Kong Gateway<br/>(booking-gateway)"]
        subgraph PPSvc["passenger-portal pod"]
            PP_App["passenger-portal"]
            PP_Envoy["Envoy sidecar"]
        end
        subgraph CISvc["check-in-api pod"]
            CI_App["check-in-api"]
            CI_Envoy["Envoy sidecar"]
        end
        ZE_East["ZoneEgress"]
    end
    subgraph ZoneWest["zone2 (VMs)"]
        ZI_West["ZoneIngress"]
        subgraph FCSvc["flight-control VM"]
            FC_App["flight-control"]
            FC_Envoy["Envoy sidecar"]
        end
    end
    EXT["weather-api (SaaS)"]

    ZECP -.->|xDS| PP_Envoy
    ZECP -.->|xDS| CI_Envoy
    ZECP -.->|xDS| ZE_East

    KG --> PP_Envoy
    PP_Envoy --> PP_App
    PP_App --> PP_Envoy
    PP_Envoy --> CI_Envoy
    CI_Envoy --> CI_App
    CI_App --> CI_Envoy
    CI_Envoy --> ZE_East
    ZE_East --> ZI_West
    ZI_West --> FC_Envoy
    FC_Envoy --> FC_App
    CI_Envoy --> EXT
{% endmermaid %}

A request to `flight-control` from `check-in-api` traverses: app → local Envoy → ZoneEgress → ZoneIngress in the remote zone → remote Envoy → app. Every hop between sidecars is encrypted and authenticated by `MeshIdentity` and `MeshTLS`. Calls to external SaaS (here, `weather-api`) are modelled as `MeshExternalService` and routed through ZoneEgress.

## Scalability and fault tolerance
{{site.mesh_product_name}}'s separation of Global and Zone control planes ensures that your mesh can scale across thousands of services and multiple geographical regions without creating a single point of failure. Even if a zone becomes isolated from the global CP, it remains fully operational for existing and new workloads within that zone.
