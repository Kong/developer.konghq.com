---
title: 'Multi-zone deployment'
description: 'Group equivalent MeshServices across zones and expose a unified, zone-agnostic service with global failover capabilities.'
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

min_version:
  mesh: '2.6'

tags:
  - multi-zone
  - zones

related_resources:
  - text: Mesh DNS
    url: '/mesh/dns/'
  - text: '{{site.mesh_product_name}} resource sizing guidelines'
    url: '/mesh/resource-sizing-guidelines/'
  - text: '{{site.mesh_product_name}} version compatibility'
    url: '/mesh/version-compatibility/'
  - text: Install Kong Mesh
    url: /mesh/#install-kong-mesh
  - text: Multi-zone authentication
    url: '/mesh/multi-zone-authentication/'
  - text: 'Single-zone deployment'
    url: '/mesh/single-zone/'
  - text: '{{site.mesh_product_name}} data plane on Kubernetes'
    url: /mesh/data-plane-kubernetes/
  - text: "{{ site.mesh_product_name }} data plane proxy"
    url: /mesh/data-plane-proxy/
  - text: "{{site.mesh_product_name}} data plane on Universal"
    url: /mesh/data-plane-universal/
  - text: Service discovery
    url: /mesh/service-discovery/
---

## About

{{site.mesh_product_name}} supports running your service mesh in multiple zones, including a mix of Kubernetes and Universal zones. Your mesh environment can include multiple isolated service meshes (multi-tenancy), and workloads running in different regions, on different clouds, or in different datacenters. A zone can be a Kubernetes cluster, a VPC, or any other deployment you need to include in the same distributed mesh environment.
The only condition is that all the data planes running within the zone can connect to the other data planes in the same zone.

{% mermaid %}
flowchart TB
    GCP[Global control plane]

    subgraph ZA[Zone A]
        ZCPA[Zone control plane]
        DPPA[Data plane proxies]
        ZEA[Zone egress]
        ZIA[Zone ingress]
    end

    subgraph ZB[Zone B]
        ZCPB[Zone control plane]
        DPPB[Data plane proxies]
        ZEB[Zone egress]
        ZIB[Zone ingress]
    end

    GCP <-->|KDS| ZCPA
    GCP <-->|KDS| ZCPB
    ZCPA <-->|xDS| DPPA & ZEA & ZIA
    ZCPB <-->|xDS| DPPB & ZEB & ZIB
    DPPA -->|outbound| ZEA -->|cross-zone| ZIB -->|inbound| DPPB
    DPPB -->|outbound| ZEB -->|cross-zone| ZIA -->|inbound| DPPA
{% endmermaid %}

Or without the optional zone egress:

{% mermaid %}
flowchart TB
    GCP[Global control plane]

    subgraph ZA[Zone A]
        ZCPA[Zone control plane]
        DPPA[Data plane proxies]
        ZIA[Zone ingress]
    end

    subgraph ZB[Zone B]
        ZCPB[Zone control plane]
        DPPB[Data plane proxies]
        ZIB[Zone ingress]
    end

    GCP <-->|KDS| ZCPA
    GCP <-->|KDS| ZCPB
    ZCPA <-->|xDS| DPPA & ZIA
    ZCPB <-->|xDS| DPPB & ZIB
    DPPA -->|cross-zone| ZIB -->|inbound| DPPB
    DPPB -->|cross-zone| ZIA -->|inbound| DPPA
{% endmermaid %}

## How it works

{{site.mesh_product_name}} abstracts away zones, so your data plane proxies find services wherever they run.
You can make a service multi-zone by having data planes use the same `kuma.io/service` in different zones. This gives you automatic failover of services if a specific zone fails.

Let's look at how a service `backend` in `zone-b` is advertised to `zone-a` and a request from the local zone `zone-a` is routed to the remote
service in `zone-b`.

### Destination service zone

When the new service `backend` joins the mesh in `zone-b`, the `zone-b` zone control plane adds this service to the `availableServices` on the `zone-b` `ZoneIngress` resource.
The `kuma-dp` proxy running as a zone ingress is configured with this list of
services so that it can route incoming requests.
This `ZoneIngress` resource is then also synchronized to the global control plane.

The global control plane propagates the zone ingress resources and all policies to all other zones over {{site.mesh_product_name}} Discovery Service (KDS), which is a protocol based on xDS.

### Source service zone

The `zone-b` `ZoneIngress` resource is synchronized from the global control
plane to the `zone-a` zone control plane.
Requests to the `availableServices` from `zone-a` are load balanced between local instances and remote instances of this service.
Requests sent to `zone-b` are routed to the zone ingress proxy of `zone-b`.

For load balancing, zone ingress endpoints are weighted by the number of instances running behind them, so a zone with 2 instances receives twice as much traffic as a zone with 1 instance.
You can also favor local service instances with [locality-aware load balancing](/mesh/policies/meshloadbalancingstrategy).

When a [zone egress](/mesh/zone-egress/) is present, traffic routes through the local zone egress before reaching the remote zone ingress.

When using [transparent proxy](/mesh/transparent-proxying/) (default in Kubernetes), {{site.mesh_product_name}} generates a VIP and a DNS entry with the format `<kuma.io/service>.mesh`, and listens for traffic on port 80. The `<kuma.io/service>.mesh:80` format is just a convention.

{:.info}
> A zone ingress is not an API gateway. It only handles cross-zone communication within a mesh. API gateways are supported in {{site.mesh_product_name}} [gateway mode](/mesh/ingress/) and can be deployed in addition to zone ingresses.

## Components of a multi-zone deployment

A multi-zone deployment includes:

- The **global control plane**:
  - Accept connections only from zone control planes.
  - Accept creation and changes to [policies](/mesh/policies/) that will be applied to the data plane proxies.
  - Send policies down to zone control planes.
  - Send zone ingresses down to zone control plane.
  - Keep an inventory of all data plane proxies running in all zones (this is only done for observability but is not required for operations).
  - Reject connections from data plane proxies.
- The **zone control planes**:
  - Accept connections from data plane proxies started within this zone.
  - Receive policy updates from the global control plane.
  - Send data plane proxies and zone ingress changes to the global control plane.
  - Compute and send configurations using XDS to the local data plane proxies.
  - Update the list of services available in the zone in the zone ingress.
  - Reject policy changes that do not come from global.
- The **data plane proxies**:
  - Connect to the local zone control plane.
  - Receive configurations using XDS from the local zone control plane.
  - Connect to other local data plane proxies.
  - Connect to zone ingresses for sending cross-zone traffic.
  - Receive traffic from local data plane proxies and local zone ingresses.
- The **zone ingress**:
  - Receive XDS configuration from the local zone control plane.
  - Proxy traffic from other zone data plane proxies to local data plane proxies.
- (optional) The **zone egress**:
  - Receive XDS configuration from the local zone control plane.
  - Proxy traffic from local data plane proxies:
    - to zone ingress proxies from other zones;
    - to external services from local zone;

## Failure modes

### Global control plane offline

- Policy updates will be impossible.
- Changes in the service list between zones will not propagate:
  - New services will not be discoverable in other zones.
  - Services removed from a zone will still appear available in other zones.
- You won't be able to disable or delete a zone.

{:.info}
> Both local and cross-zone application traffic is unaffected by this failure case.
> Data plane proxy changes continue to propagate within their zones.

### Zone control plane offline

- New data plane proxies won't be able to join the mesh. This includes new instances (Pod/VM) that are newly created by automatic deployment mechanisms (for example, a rolling update process), meaning a control plane connection failure could block updates of applications and events that create new instances.
- On mTLS enabled meshes, a data plane proxy may fail to refresh its client certificate before it expires (defaults to 24 hours), causing traffic to and from the data plane to fail.
- Data plane proxy configuration will not be updated.
- Communication between data plane proxies will still work.
- Cross-zone communication will still work.
- Other zones are unaffected.

{:.info}
> You can think of this failure case as "freezing" the zone mesh configuration.
> Communication still works, but changes are not reflected on existing data plane proxies.

### Communication between global and zone control plane failing

Misconfiguration or network connectivity issues between control planes can trigger this failure.

- Operations inside the zone continue to work correctly (data plane proxies can join, leave, and all configuration updates and sends correctly).
- Policy changes will not be propagated to the zone control plane.
- `ZoneIngress`, `ZoneEgress` and `Dataplane` changes will not be propagated to the global control plane:
  - The global inventory view of the data plane proxies will be outdated (this only impacts observability).
  - Other zones will not see new services registered inside this zone.
  - Other zones will not see services no longer running inside this zone.
  - Other zones will not see changes in number of instances of each service running in the local zone.
- Global control plane will not send changes from other zone ingresses to the zone:
  - Local data plane proxies will not see new services registered in other zones.
  - Local data plane proxies will not see services no longer running in other zones.
  - Local data plane proxies will not see changes in number of instances of each service running in other zones.

{:.info}
> Both local and cross-zone application traffic is unaffected by this failure case.

### Communication between two zones failing

This can happen if there are network connectivity issues:

- Between control plane and zone ingress from other zone.
- Between control plane and zone egress (when present).
- Between zone egress (when present) and zone ingress from other zone.
- All zone egress instances of a zone (when present) are down.
- All zone ingress instances of a zone are down.

When this happens:

- Communication and operations within each zone are unaffected.
- Communication across zones fails.

{:.info}
> With the right resiliency setup ([MeshRetries](/mesh/policies/meshretry), [MeshHealthCheck](/mesh/policies/meshhealthcheck), [MeshLoadBalancingStrategy](/mesh/policies/meshloadbalancingstrategy), [MeshCircuitBreakers](/mesh/policies/meshcircuitbreaker)) the failing zone can be quickly severed and traffic re-routed to another zone.
