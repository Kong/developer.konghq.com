---
title: Operator
content_type: reference
layout: reference
description: How the operator manages the global infrastructure, multi-zone networking, and consolidated observability for Kong Air's flight systems.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
  - /mesh/persona/
products:
  - mesh
works_on:
  - on-prem
  - konnect
---

The operator is a Platform Engineer at Kong Air. The operator's mission is to provide a "Service Mesh as a Service" to teams like the developer's. The operator manages the underlying infrastructure, ensuring that the Global Flight Logistics platform remains highly available, observable, and performant across multiple geographic regions.

## Global infrastructure control

The operator manages a distributed architecture consisting of a Global Control Plane and multiple Zone Control Planes.

- Global CP: Acts as the single source of truth for all {{site.mesh_product_name}} policies. The operator applies configurations once at the global level, and they are automatically synchronized to all zones. The global control plane runs in Universal mode backed by Postgres; a Kubernetes-native global control plane is not supported.
- Zone CP: Handles the actual distribution of xDS configuration to local sidecars in zones like `zone1` and `zone2`.

## Multi-zone networking

For the "Global Flight Search" service to span continents, the operator configures specialized infrastructure proxies.

A zone proxy is an ordinary `Dataplane` that carries zone ingress or zone egress listeners. The control plane computes the `kuma.io/listener-zoneingress` and `kuma.io/listener-zoneegress` labels on that `Dataplane`, which is how the operator selects it from policy. There is no separate `ZoneIngress` or `ZoneEgress` resource to manage.

### Entry points: zone ingress listeners
The operator ensures that every zone has a proxy carrying zone ingress listeners. It accepts cross-zone mTLS traffic and routes it to a local instance. Service state reaches other zones through KDS synchronization between the control planes, and the reachable address is published as a `MeshZoneAddress`.

### Secure exits: zone egress listeners
To satisfy strict aviation industry regulations, the operator routes outgoing traffic (to other zones or the internet) through a proxy carrying zone egress listeners.
*   Centralized Compliance: Instead of every sidecar needing a path to the internet, only the zone egress needs it.
*   Auditability: The operator has a single point to audit every request leaving the zone.

The operator provisions this pair per mesh through the Helm `meshes:` list rather than a field on the `Mesh` resource:

```yaml
# One entry per mesh that needs cross-zone connectivity
meshes:
  - name: kong-air-mesh
    ingress:
      enabled: true
    egress:
      enabled: true
```

### Mesh-scoped zone proxies

For a mesh-per-tenant model, the operator deploys dedicated zone proxies per mesh using the Helm `meshes:` list. Each entry provisions its own ingress/egress with independent HPA, PDB, and ServiceAccount, keeping `kong-air-mesh` isolated from any sibling meshes (for example, a separate mesh for ground operations). Two operational details:

*   Zone egress listeners are deny-by-default. Every `MeshExternalService` is SNI-matched; the operator needs to coordinate with the security architect on `MeshTrafficPermission` `Allow` rules tied to the caller's SPIFFE identity before any external call works.
*   The mesh-scoped model is the preferred operational shape for new deployments.

Zone proxy listeners are generated for every mesh that has an entry in the Helm `meshes:` list, with no additional field to set on the `Mesh` resource. See [Configure mesh-scoped zone proxies](/mesh/configure-mesh-scoped-zone-proxies/) for the Helm `meshes:` shape and for how the operator targets the proxies as ordinary `Dataplane` targets, using the `kuma.io/listener-zoneingress` / `kuma.io/listener-zoneegress` labels and `sectionName` for policies such as `MeshTrace`.

### Envoy admin API on UDS

Sidecar Envoy admin uses a Unix domain socket by default. A readiness reverse-proxy on TCP `9902` exposes the admin endpoints for `kubectl exec`, probes, and existing debug scripts. The `KUMA_EXPERIMENTAL_ADMIN_UNIX_SOCKET` environment variable is renamed to `KUMA_BOOTSTRAP_SERVER_PARAMS_ADMIN_UNIX_SOCKET`. Any tooling the operator has wired to `localhost:9901` needs to switch to the UDS path or `localhost:9902`.

## High-availability gateway infrastructure

The operator runs a delegated gateway ({{site.base_gateway}}) to surface the developer's services to the outside world, scaling replicas for peak travel season. The gateway's proxies are marked with the `kuma.io/gateway` label, and a policy targets them as a `Dataplane` with a `labels:` selector, which is the label-selected targeting model used throughout these scenarios.

## Global observability policies

The operator provides "Observability as a Service" so the developer doesn't have to worry about where the developer's logs and traces go.

### Distributed tracing (`MeshTrace`)
The operator sets up end-to-end tracing across all zones, exporting spans via OTLP/gRPC to a global collector. The operator defines one `MeshOpenTelemetryBackend` and references it from every observability policy through a `backendRef`; only the gRPC OTel transport is supported.

### Log aggregation (`MeshAccessLog`)
To maintain a historical record of all flight search requests, the operator streams access logs to a central logging server through a `Tcp` backend. See [Observe mesh traffic in practice](/mesh/observe-mesh-traffic-in-practice/) for the full `MeshTrace` and `MeshAccessLog` configuration.

{:.info}
> To scope a policy to a slice of the fleet (a whole zone, an environment, a region), the operator sets the top-level `targetRef` to `Dataplane` with a `labels:` selector, for example `kuma.io/zone: zone1` or `environment: production`. A top-level `targetRef` accepts only `Mesh` or `Dataplane`, so `Dataplane` with labels is how you scope to anything narrower than the whole mesh. See [Target workloads and services](/mesh/target-workloads-and-services/) for examples.

## Operational health and lifecycle

The operator monitors the health of the mesh using the Control Plane's built-in metrics. The operator tracks:
- CP-to-DP Latency: How quickly policy changes reach the developer's sidecars.
- Cross-Zone Latency: The performance of the network between US and EU zones.
- Resource Utilization: Ensuring the zone ingress and zone egress proxies have sufficient CPU/RAM.

## The operator's result
By operating the control plane, zone proxies, gateways, and observability stack centrally, the operator gives the developer's and the security architect's teams a consistent platform to build on, they configure behavior through policy without managing the underlying networking themselves.
