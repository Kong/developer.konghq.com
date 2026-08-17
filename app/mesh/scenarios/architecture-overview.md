---
title: Architecture overview
content_type: reference
layout: reference
description: A detailed overview of the {{site.mesh_product_name}} architecture, explaining the relationship between global/zone control planes and the Envoy-based data plane.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
next_steps:
  - text: "Get started with your first policy"
    url: "/mesh/scenarios/get-started-with-your-first-policy/"
related_resources:
  - text: "{{site.mesh_product_name}} architecture"
    url: "/mesh/architecture/"
  - text: Multi-zone deployment
    url: /mesh/mesh-multizone-service-deployment/
---
{{site.mesh_product_name}} separates the control plane from the data plane and introduces a multi-zone model for distributed environments. For an organization like Kong Air, this architecture enables a unified management layer that spans from legacy booking systems to modern cloud-native APIs.

## Core architecture

{{site.mesh_product_name}} is built from:
* A control plane (a global CP that owns policy and the resource registry, and zone CPs that discover local services and serve xDS to Envoy)
* An Envoy-based data plane that enforces policy and intercepts traffic, networking proxies (zone ingress and egress) for cross-zone communication, 
* A standardized service model (`MeshService`, `MeshMultiZoneService`, `MeshExternalService`)
* Workload identity (`MeshIdentity`, `MeshTrust`). 

For definitions of each component and their configuration options, see the [{{site.mesh_product_name}} architecture](/mesh/architecture/) reference.

{:.info}
> These scenarios set `meshServices.mode: Exclusive` on the `kong-air-mesh` `Mesh` resource:
>
> ```yaml
> spec:
>   meshServices:
>     mode: Exclusive
> ```
>
> In Exclusive mode, the control plane generates a first-class `MeshService` resource for every workload, and policies address those `MeshService` objects directly instead of the older `kuma.io/service` tags. This is the modern model the rest of these scenarios assume, and it is a prerequisite for features like mesh-scoped zone proxies. You'll see it listed as a prerequisite in the hands-on guides that follow.

## Day-2 operations: differences from Istio-style meshes

Teams evaluating {{site.mesh_product_name}} are often already running an Istio-style mesh, a model built around multiple traffic-management CRDs (`VirtualService`, `DestinationRule`, `ServiceEntry`) on a Kubernetes-first control plane. Both models support mTLS, traffic routing, and observability, and initial setup is comparable in either. The differences appear in day-2 operations, running the mesh in production, across regions, and through upgrades, which is what the comparison below covers.

<!-- vale off -->
{% table %}
columns:
  - title: Day-2 concern
    key: concern
  - title: Istio-style mesh
    key: istio
  - title: "{{site.mesh_product_name}}"
    key: mesh
rows:
  - concern: Policy structure
    istio: "A single behavior can span several resources, routing in `VirtualService`, load balancing and outlier detection in `DestinationRule`, external hosts in `ServiceEntry`. Newer versions are adopting the Kubernetes Gateway API for routing."
    mesh: "One policy per concern, all sharing the same `targetRef` structure, which means fewer interacting resource types to handle when troubleshooting a production issue."
  - concern: Running across regions
    istio: "Multi-cluster is assembled from topologies you choose and maintain (multi-primary, primary-remote)."
    mesh: "A built-in global/zone model with automatic KDS sync. Adding a region means adding a zone CP, not redesigning a topology, and if the global CP is offline, each zone CP keeps serving its last-known config, so data plane traffic is unaffected."
  - concern: Hybrid estate (VMs + Kubernetes)
    istio: "Kubernetes-native; VMs run through `WorkloadEntry` / `WorkloadGroup`."
    mesh: "Kubernetes and Universal (VMs, bare metal) use the same resource model, so one team operates one mesh across both, no separate paradigm for the legacy estate."
{% endtable %}
<!-- vale on -->

In summary, {{site.mesh_product_name}} uses fewer resource types per policy, treats multi-region as a deployment mode rather than a topology you build and maintain, and applies the same resource model to both Kubernetes and Universal workloads.

## {{site.mesh_product_name}} architecture

the two sections below show a high-level view of how the control plane is distributed, and a zone-level view of how data plane traffic flows.

The following elements are used in both diagrams::
- Solid arrow: data plane traffic (encrypted with mTLS between sidecars).
- Dashed arrow: control plane channel (xDS, KDS, admin API).
- Box border: control plane that owns the resource (global CP or a specific zone CP).

### High-level: global CP and zone CPs

The global CP is the single source of truth for the mesh. Each zone runs its own zone CP, which syncs from the global CP over the Kuma Discovery Service (KDS) and serves xDS to the local data planes.

{% mermaid %}
flowchart TD
    GUI["Konnect/kumactl"]
    GCP["Global control plane"]
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

Everything in this diagram is a control plane channel, no application traffic crosses these links. If the global CP goes offline, zone CPs continue to serve their last-known config to local data planes; the mesh stays operational.

### Zone-level: request flow

Inside a zone, every workload runs alongside an Envoy sidecar that enforces mTLS, retries, timeouts, and access policy, while cross-zone calls route through zone ingress and egress. For the canonical mechanics of cross-zone service discovery and routing, see [Multi-zone deployment](/mesh/mesh-multizone-service-deployment/).

{% mermaid %}
flowchart LR
    subgraph ZoneEast["zone1 (Kubernetes)"]
        ZECP["Zone CP"]
        KG["{{site.base_gateway}}<br/>(booking-gateway)"]
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

Tracing a cross-zone call, `check-in-api` (zone1) calling `flight-control` (zone2), the request passes through six hops:

1. `check-in-api` sends the request to its local Envoy sidecar over localhost.
2. The sidecar looks up the destination in its xDS config (served by the zone1 CP) and determines that `flight-control` lives in another zone, so it routes the request to the local `ZoneEgress`.
3. `ZoneEgress` forwards the request out of zone1 toward zone2's `ZoneIngress`.
4. `ZoneIngress` in zone2 receives the request and, based on its own xDS config from the zone2 CP, routes it to a healthy `flight-control` instance.
5. The request reaches the Envoy sidecar running alongside `flight-control`.
6. That sidecar forwards the request to the `flight-control` application over localhost.

Every hop between sidecars (steps 2 through 5) is encrypted and mutually authenticated using the SPIFFE identities issued by `MeshIdentity` and enforced by `MeshTLS`; only the first and last hops (app to local sidecar) are plaintext, since they never leave the pod or VM. Calls to external SaaS (here, `weather-api`) follow the same egress path but are modelled as `MeshExternalService` instead of a zone-to-zone `ZoneIngress` hop, since there is no remote mesh zone to route into.

## Scalability and fault tolerance
{{site.mesh_product_name}}'s separation of global and zone control planes ensures that your mesh can scale across thousands of services and multiple geographical regions without creating a single point of failure. Even if a zone becomes isolated from the global CP, it remains fully operational for existing and new workloads within that zone.
