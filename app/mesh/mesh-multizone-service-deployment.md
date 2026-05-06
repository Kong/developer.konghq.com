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
  - text: Install {{site.mesh_product_name}}
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

{{site.mesh_product_name}} supports running your service mesh in multiple zones, including a mix of Kubernetes and Universal zones. Your mesh environment can include multiple isolated service meshes and workloads running in different regions, on different clouds, or in different data centers. A zone can be a Kubernetes cluster, a VPC, or any other deployment you need to include in the same distributed mesh environment.
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

## How it works

{{site.mesh_product_name}} abstracts away zones, so your data plane proxies find services wherever they run.
You can make a service multi-zone by having data planes use the same `kuma.io/service` in different zones. This gives you automatic failover of services if a specific zone fails.

Let's look at how a service `backend` in `zone-b` is advertised to `zone-a` and a request from the local zone `zone-a` is routed to the remote
service in `zone-b`.

### Destination service zone

When the new service `backend` joins the mesh in `zone-b`, the `zone-b` zone control plane adds this service to the `availableServices` on the `zone-b` `ZoneIngress` resource.
The `kuma-dp` proxy running as a [zone ingress](/mesh/zone-ingress/) is configured with this list of
services so that it can route incoming requests.
This `ZoneIngress` resource is then also synchronized to the global control plane.

The global control plane propagates the zone ingress resources and all policies to all other zones over {{site.mesh_product_name}} Discovery Service (KDS), which is a protocol based on xDS.

### Source service zone

The `zone-b` `ZoneIngress` resource is synchronized from the global control
plane to the `zone-a` zone control plane.
Requests to the `availableServices` from `zone-a` are load balanced between local instances and remote instances of this service.
Requests sent to `zone-b` are routed to the zone ingress proxy of `zone-b`.

For load balancing, zone ingress endpoints are weighted by the number of instances running behind them, so a zone with two instances receives twice as much traffic as a zone with one instance.
You can also favor local service instances with [locality-aware load balancing](/mesh/policies/meshloadbalancingstrategy/#localityawareness).

When a [zone egress](/mesh/zone-egress/) is present, traffic routes through the local zone egress before reaching the remote zone ingress.

When using [transparent proxying](/mesh/transparent-proxying/) (default in Kubernetes), {{site.mesh_product_name}} generates a VIP and a DNS entry with the format `<kuma.io/service>.mesh`, and listens on the service VIP port (default 80).

{:.info}
> A zone ingress is not an API gateway. It only handles cross-zone communication within a mesh. API gateways are supported in {{site.mesh_product_name}} [gateway mode](/mesh/ingress/) and can be deployed in addition to zone ingresses.

## Components of a multi-zone deployment

A multi-zone deployment includes:

{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibilities
    key: responsibilities
rows:
  - component: Global control plane
    responsibilities: |
      * Accept connections only from zone control planes.
      * Accept creation and changes to [policies](/mesh/policies/) that will be applied to the data plane proxies.
      * Send policies down to zone control planes.
      * Send zone ingresses down to zone control planes.
      * Keep an inventory of all data plane proxies running in all zones (this is only done for observability but is not required for operations).
      * Reject connections from data plane proxies.
  - component: Zone control planes
    responsibilities: |
      * Accept connections from data plane proxies started within the zone.
      * Receive policy updates from the global control plane.
      * Send data plane proxies and zone ingress changes to the global control plane.
      * Compute and send configurations using XDS to the local data plane proxies.
      * Update the list of services available in the zone in the zone ingress.
      * Reject policy changes that do not come from the global control plane.
  - component: Data plane proxies
    responsibilities: |
      * Connect to the local zone control plane.
      * Receive configurations using XDS from the local zone control plane.
      * Connect to other local data plane proxies.
      * Connect to zone ingresses to send cross-zone traffic.
      * Receive traffic from local data plane proxies and local zone ingresses.
  - component: Zone ingress
    responsibilities: |
      * Receive XDS configuration from the local zone control plane.
      * Proxy traffic from other zone data plane proxies to local data plane proxies.
  - component: Zone egress (optional)
    responsibilities: |
      * Receive XDS configuration from the local zone control plane.
      * Proxy traffic from local data plane proxies to zone ingress proxies from other zones.
      * Proxy traffic from local data plane proxies to external services from local zone.
{% endtable %}

## Failure modes

The following table describes how {{site.mesh_product_name}} behaves when components of a multi-zone deployment become unavailable or lose connectivity:

<!-- vale off -->
{% table %}
columns:
  - title: Failure mode
    key: mode
  - title: Impact
    key: impact
  - title: What still works
    key: still_works
rows:
  - mode: Global control plane offline
    impact: |
      * Policy updates are impossible.
      * Changes in the service list between zones won't propagate: new services won't be discoverable in other zones, and services removed from a zone will still appear available in other zones.
      * Zones can't be deleted or disabled.
    still_works: |
      * Local and cross-zone application traffic.
      * Data plane proxy changes continue to propagate within their zones.
  - mode: Zone control plane offline
    impact: |
      * New data plane proxies can't join the mesh, including new instances (Pod/VM) created by automatic deployment mechanisms such as rolling updates. A control plane connection failure could block application updates.
      * On mTLS-enabled meshes, a data plane proxy may fail to refresh its client certificate before it expires (defaults to 24 hours), causing traffic failures.
      * Data plane proxy configuration won't be updated.
    still_works: |
      * Communication between data plane proxies.
      * Cross-zone communication.
      * Other zones are unaffected.
  - mode: Communication between global and zone control plane failing
    impact: |
      Can occur when there is a misconfiguration or network connectivity issues between control planes.

      * Policy changes won't propagate to the zone control plane.
      * `ZoneIngress`, `ZoneEgress`, and `Dataplane` changes won't propagate to the global control plane, leaving the global inventory of data plane proxies outdated.
      * Other zones won't see new or removed services from this zone, or changes in instance counts.
      * Local data plane proxies won't see new or removed services from other zones, or changes in instance counts.
    still_works: |
      * All operations inside the zone: data plane proxies can join, leave, and receive configuration updates.
      * Local and cross-zone application traffic.
  - mode: Communication between two zones failing
    impact: |
      Can occur when there are network connectivity issues between: a control plane and zone ingress or egress from another zone; a zone egress and zone ingress from another zone; or when all zone ingress or egress instances in a zone are down.

      * Cross-zone communication fails.

      {:.info}
      > With the right resiliency setup ([MeshRetries](/mesh/policies/meshretry), [MeshHealthCheck](/mesh/policies/meshhealthcheck), [MeshLoadBalancingStrategy](/mesh/policies/meshloadbalancingstrategy), [MeshCircuitBreakers](/mesh/policies/meshcircuitbreaker)), the failing zone can be quickly severed and traffic re-routed to another zone.
    still_works: |
      * Communication and operations within each zone.
{% endtable %}
<!-- vale on -->