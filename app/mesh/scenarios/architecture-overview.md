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
  - text: "Resource Scoping: Where to Apply Policies"
    url: "/mesh/scenarios/resource-scoping/"
---
{{site.mesh_product_name}} separates the **Control Plane** (the brain) from the **Data Plane** (the muscle) and introduces a multi-zone model for distributed environments. For an organization like **Kong Air**, this architecture enables a unified management layer that spans from legacy booking systems to modern cloud-native APIs.

{% tip %}
**Version guide.** This overview mixes concepts that work in 2.13 with the newer resource model the team is rolling out in 2.14 and beyond. When a feature is 2.14-specific (for example `MeshIdentity`, mesh-scoped zone proxies, or KRI-oriented naming), the scenario docs call that out explicitly. If you're on 2.13, keep the high-level control-plane / data-plane model from this page, but expect some of the implementation details in later scenarios to have a "current in 2.13" path and a "recommended in 2.14+" path.
{% endtip %}

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
      * **MeshIdentity** (2.14+): The system of record for workload identity. Supports `Bundled`, `Spire`, and `Extension` providers. Replaces the older mesh-wide identity model.
      * **MeshTrust** (2.14+): Declares trusted CA bundles per trust domain. By default, the control plane can generate a `MeshTrust` from a `MeshIdentity`, but operators can also manage it explicitly.
{% endtable %}

## Why this architecture is simpler

Traditional service meshes often require you to manage multiple disparate resources and API versions just to achieve basic connectivity. {{site.mesh_product_name}} simplifies this by introducing a **Unified Control Plane** model:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Other meshes
    key: traditional
  - title: {{site.mesh_product_name}}
    key: mesh
rows:
  - feature: Management
    traditional: "Disparate controllers for ingress, egress, and policy."
    mesh: "Single, unified binary for all mesh operations."
  - feature: Infrastructure
    traditional: "Heavy Kubernetes focus; VMs are often second-class citizens."
    mesh: "First-class support for K8s, VMs, and Bare Metal with the same API."
  - feature: Configuration
    traditional: "Fragmented resources (VirtualService, DestinationRule, Gateway)."
    mesh: "Streamlined `targetRef` policies that consolidate intent."
{% endtable %}

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
    Z1CP["Zone CP<br/>(Kubernetes, US East)"]
    Z2CP["Zone CP<br/>(Universal VM, US West)"]
    DP1["Data planes<br/>(Envoy sidecars)"]
    DP2["Data planes<br/>(Envoy sidecars)"]

    GUI -.- GCP
    GCP -.->|KDS| Z1CP
    GCP -.->|KDS| Z2CP
    Z1CP -.->|xDS| DP1
    Z2CP -.->|xDS| DP2
{% endmermaid %}

Everything in this diagram is a **control-plane** channel — no application traffic crosses these links. If the Global CP goes offline, Zone CPs continue to serve their last-known config to local data planes; the mesh stays operational.

### 2. Zone-level: how a request flows

Inside a zone, every workload runs alongside an Envoy sidecar. Sidecars enforce mTLS, retries, timeouts, and access policy. Cross-zone calls go through ZoneIngress and ZoneEgress.

{% mermaid %}
flowchart LR
    subgraph ZoneEast["Zone East (Kubernetes)"]
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
    subgraph ZoneWest["Zone West (VMs)"]
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
