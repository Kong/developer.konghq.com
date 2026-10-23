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
The operator is a platform engineer at Kong Air.
The operator runs the mesh as a shared platform for application teams, such as the [developer](/mesh/persona/developer/)'s team.
The operator keeps the flight logistics platform available, observable, and fast in every region.

## How the operator runs the control planes

Kong Air runs one global control plane and one zone control plane in each zone:

* **Global control plane**: {{site.konnect_short_name}} hosts and operates it for Kong Air. A policy that the operator creates on the global control plane reaches every zone.
* **Zone control plane**: The operator runs one in each zone, such as `zone1` and `zone2`. It sends configuration to the local sidecars over xDS. A policy that a team creates on a zone control plane stays in that zone, unless it's a producer policy.

For which control plane owns each resource, see [Resource scoping](/mesh/resource-scoping/).
For how far each policy reaches, see [Policy scope](/mesh/policy-targeting/#policy-scope).

## How the operator connects zones

Kong Air's flight search service runs in several regions, so traffic must cross zones.
The operator deploys a zone ingress and a zone egress for `kong-air-mesh` in each zone.
Each one is an ordinary `Dataplane` with a zone ingress or zone egress listener.

The control plane adds the `kuma.io/listener-zoneingress: enabled` or `kuma.io/listener-zoneegress: enabled` label to each zone proxy.
The operator uses these labels to select the zone proxies in a policy's `targetRef`.

### Zone ingress

Every zone runs a zone ingress.
The zone ingress accepts mTLS traffic from other zones and forwards it to a local instance of the service.
The zone control plane publishes the address of the zone ingress as a `MeshZoneAddress`, so other zones know where to connect.

### Zone egress

Aviation regulations require Kong Air to control traffic to external services.
The operator deploys a zone egress, and every request to a `MeshExternalService` leaves the zone through it:

* **Compliance**: Only the zone egress needs a network path to the internet, not every sidecar.
* **Auditing**: The operator audits external requests in one place.

Cross-zone traffic between mesh services doesn't use the zone egress by default.
A caller's sidecar connects directly to the zone ingress of the other zone.
For both paths, see [Traffic paths](/mesh/mesh-scoped-zone-proxies/#traffic-paths).

The operator enables both proxies for each mesh in the `meshes:` list of the Helm values, not in the `Mesh` resource:

```yaml
# One entry for each mesh that needs zone proxies
meshes:
  - name: kong-air-mesh
    ingress:
      enabled: true
    egress:
      enabled: true
```
{:.no-copy-code}

## How the operator runs the gateway

The operator runs `booking-gateway`, a {{site.base_gateway}} deployment that exposes the developer's services to passengers.
The operator adds replicas during peak travel season.
The gateway joins the mesh through an ordinary sidecar.
A policy selects the gateway proxies with a `Dataplane` `targetRef` and the gateway's own labels, such as `app: booking-gateway`.
See [Application ingress](/mesh/application-ingress/).

## How the operator provides observability

The operator configures observability for the whole mesh, so application teams don't need to decide where their logs and traces go.

### Distributed tracing with `MeshTrace`

The operator defines one `MeshOpenTelemetryBackend` for the OpenTelemetry collector.
Every observability policy references it with a `backendRef`.
The operator's `MeshTrace` policy then exports the spans of every zone to that collector.
See [MeshOpenTelemetryBackend](/mesh/meshopentelemetrybackend/).

### Access logs with `MeshAccessLog`

To keep a record of every flight search request, the operator sends the access logs to a central logging server with a `Tcp` backend.
For the full `MeshTrace` and `MeshAccessLog` configuration, see [Observe mesh traffic in practice](/mesh/observe-mesh-traffic-in-practice/).

{:.info}
> To apply a policy to part of the mesh, such as a zone, an environment, or a region, the operator uses a top-level `targetRef` of `kind: Dataplane` with `labels`, for example `kuma.io/zone: zone1` or `environment: production`.
> The top-level `targetRef` accepts only `Mesh` or `Dataplane`, so labels are how the operator selects anything narrower than the whole mesh.
> See [Target workloads and services](/mesh/target-workloads-and-services/).

## How the operator monitors the mesh

The operator monitors the mesh with the metrics that the control planes expose:

* **Configuration delay**: how long a policy change takes to reach the sidecars
* **Cross-zone latency**: the network performance between the US and EU zones
* **Resource use**: the CPU and memory of the zone ingress and zone egress proxies

The operator also limits how much configuration the control plane generates.
With `reachableBackends`, each proxy receives configuration only for the destinations its workload calls.
The amount of configuration then stays stable as Kong Air adds services.
See [Prepare the mesh for production](/mesh/prepare-the-mesh-for-production/).

The operator runs the control planes, zone proxies, gateway, and observability stack.
The developer's and the security architect's teams configure behavior with policies and don't manage the network themselves.
