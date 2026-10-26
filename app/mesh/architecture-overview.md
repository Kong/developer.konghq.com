---
title: Architecture overview
content_type: reference
layout: reference
description: Learn how the {{site.mesh_product_name}} global control plane, zone control planes, and Envoy-based data plane work together, and how a request travels between zones.
breadcrumbs:
  - /mesh/
products:
  - mesh
works_on:
  - konnect
related_resources:
  - text: Multi-zone architecture
    url: /mesh/multi-zone-architecture/
  - text: Resource scoping
    url: /mesh/resource-scoping/
  - text: Service meshes
    url: /mesh/service-mesh/
  - text: Concepts
    url: /mesh/concepts/
  - text: Mesh-scoped zone proxies
    url: /mesh/mesh-scoped-zone-proxies/
---
{{site.mesh_product_name}} separates the control plane, which manages configuration, from the data plane, which carries traffic.
A zone represents one environment where workloads run, such as a Kubernetes cluster or a group of VMs.
Each zone runs a zone control plane close to its workloads, and the zone control planes connect to a global control plane.

## Core architecture

{{site.mesh_product_name}} uses the following components:

* Global control plane: It stores the central view of the meshes and resources.
* Zone control planes: Each one finds the local workloads, exchanges resources with the global control plane over the [Kuma Discovery Service (KDS)](/mesh/concepts/#kds), and sends configuration to the local proxies over [xDS](/mesh/concepts/#xds).
* Data plane: [Envoy proxies](/mesh/concepts/#data-plane-proxy-or-sidecar) that intercept application traffic and apply policies.
* [Mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/): `Dataplane` resources with a zone ingress or zone egress listener. They carry traffic into and out of a zone.
* Service model: [`MeshService`](/mesh/meshservice/), [`MeshMultiZoneService`](/mesh/meshmultizoneservice/), and [`MeshExternalService`](/mesh/meshexternalservice/) resources that describe the destinations.
* Identity and trust: [`MeshIdentity`](/mesh/policies/meshidentity/) and [`MeshTrust`](/mesh/policies/meshtrust/) resources that give workloads their identity and decide which certificate authorities they trust.

For what changes when a second zone joins, see [Multi-zone architecture](/mesh/multi-zone-architecture/).
For which control plane owns each resource, see [Resource scoping](/mesh/resource-scoping/).

## Day-2 operations compared with other meshes

Teams that evaluate {{site.mesh_product_name}} often already run an Istio-style mesh.
That model uses several traffic-management resources, such as `VirtualService`, `DestinationRule`, and `ServiceEntry`, on a control plane designed for Kubernetes first.
Both models support mTLS, traffic routing, and observability, and the first setup takes similar effort.
The differences appear in day-2 operations: running the mesh in production, across regions, and through upgrades.

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
    istio: "One behavior can span several resources: routing in `VirtualService`, load balancing and outlier detection in `DestinationRule`, and external hosts in `ServiceEntry`. Newer versions use the Kubernetes Gateway API for routing."
    mesh: "One [policy](/mesh/policies/) for each concern, and every policy uses the same [`targetRef` structure](/mesh/policy-targeting/). When you troubleshoot a production issue, you have fewer resource types that interact."
  - concern: Running across regions
    istio: "You choose and maintain a multi-cluster topology, such as multi-primary or primary-remote."
    mesh: "A built-in global and zone model that syncs over KDS. To add a region, you add a zone control plane. If the global control plane goes offline, each zone control plane keeps the global resources that it last received and keeps configuring its proxies, so data plane traffic continues."
  - concern: Kubernetes and VMs together
    istio: "Designed for Kubernetes. VMs join through `WorkloadEntry` and `WorkloadGroup`."
    mesh: "Kubernetes and [Universal](/mesh/universal/) (VMs and bare metal) use the same resources, so one team runs one mesh across both."
{% endtable %}
<!-- vale on -->

## {{site.mesh_product_name}} architecture

The following diagrams show how the control planes are distributed, and how a request travels through a zone.
Both diagrams use the same notation:

- A solid arrow is data plane traffic.
- A dashed arrow is a control plane channel: xDS or KDS.

### How the control planes connect

The global control plane stores global resources and the central view of the deployment.
Each zone control plane exchanges resources with the global control plane over KDS, and sends xDS configuration to its local data plane proxies.
The zone control plane also sends the resources that its zone creates, such as discovered workloads and zone policies, to the global control plane.

{% mermaid %}
flowchart TD
    GCP["Global control plane"]
    Z1CP["Zone control plane<br/>(Kubernetes, zone1)"]
    Z2CP["Zone control plane<br/>(Kubernetes, zone2)"]
    DP1["Data plane proxies<br/>(Envoy sidecars)"]
    DP2["Data plane proxies<br/>(Envoy sidecars)"]

    GCP <-.->|KDS| Z1CP
    GCP <-.->|KDS| Z2CP
    Z1CP -.->|xDS| DP1
    Z2CP -.->|xDS| DP2
{% endmermaid %}

Every arrow in this diagram is a control plane channel, and no application traffic uses these links.
If the global control plane goes offline, each zone control plane keeps the global resources that it last received and keeps configuring its data plane proxies, so the mesh keeps working.

### How a request travels between zones

Inside a zone, each workload runs next to an Envoy sidecar.
The sidecar applies [mTLS](/mesh/policies/meshtls/), [retries](/mesh/policies/meshretry/), [timeouts](/mesh/policies/meshtimeout/), and [access policies](/mesh/policies/meshtrafficpermission/).
Requests from outside the mesh enter through an API gateway, such as {{site.base_gateway}}.
For more information, see [Application ingress](/mesh/application-ingress/).
For cross-zone service discovery and routing, see [Multi-zone architecture](/mesh/multi-zone-architecture/).

{% mermaid %}
flowchart LR
    subgraph Zone1["zone1 (Kubernetes)"]
        Z1CP["Zone control plane"]
        KG["{{site.base_gateway}}"]
        subgraph FESvc["frontend pod"]
            FE_App["frontend"]
            FE_Envoy["Envoy sidecar"]
        end
        subgraph ORSvc["orders pod"]
            OR_App["orders"]
            OR_Envoy["Envoy sidecar"]
        end
        ZE_Z1["Zone egress<br/>(Dataplane)"]
    end
    subgraph Zone2["zone2 (Kubernetes)"]
        ZI_Z2["Zone ingress<br/>(Dataplane)"]
        subgraph PASvc["payments pod"]
            PA_App["payments"]
            PA_Envoy["Envoy sidecar"]
        end
    end
    EXT["external-api (SaaS)"]

    Z1CP -.->|xDS| FE_Envoy
    Z1CP -.->|xDS| OR_Envoy
    Z1CP -.->|xDS| ZE_Z1

    KG --> FE_Envoy
    FE_Envoy --> FE_App
    FE_App --> FE_Envoy
    FE_Envoy --> OR_Envoy
    OR_Envoy --> OR_App
    OR_App --> OR_Envoy
    OR_Envoy --> ZI_Z2
    ZI_Z2 --> PA_Envoy
    PA_Envoy --> PA_App
    OR_Envoy --> ZE_Z1
    ZE_Z1 --> EXT
{% endmermaid %}

In this example, when `orders` in `zone1` calls `payments` in `zone2`, the request takes five steps:

1. `orders` sends the request to its own Envoy sidecar over localhost.
2. The sidecar finds `payments` in the configuration that the `zone1` control plane sent. `payments` runs in another zone, so the sidecar sends the request to the zone ingress of `zone2`, at the address that `zone2` published as a [`MeshZoneAddress`](/mesh/mesh-scoped-zone-proxies/#make-ingress-reachable-from-other-zones).
3. The zone ingress uses its configuration from the `zone2` control plane to choose a healthy `payments` instance.
   It forwards the encrypted connection without decrypting it.
4. The Envoy sidecar of `payments` receives the request.
5. That sidecar forwards the request to the `payments` application over localhost.

Between the two sidecars, the connection uses mTLS with the [Secure Production Identity Framework for Everyone (SPIFFE) identities](/mesh/policies/meshidentity/#spiffe-id) that `MeshIdentity` issues.
Only the first and last steps, between an application and its own sidecar, use plaintext, because that traffic never leaves the Pod or VM.

The call to `external-api`, a service outside the mesh, takes a different path.
`external-api` is a `MeshExternalService`, so the sidecar sends the request to the zone egress of `zone1`, which forwards it to the SaaS endpoint.
For both paths, see [Traffic paths](/mesh/mesh-scoped-zone-proxies/#traffic-paths).

## Scalability and fault tolerance

The global and zone control planes are separate, so the mesh can grow to thousands of services in several regions without a single point of failure.
If a zone loses its connection to the global control plane, its zone control plane keeps serving the workloads in that zone.
The zone receives changes from the global control plane again when the connection returns.
