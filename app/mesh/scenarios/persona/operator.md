---
title: Operator
content_type: reference
layout: reference
description: How the operator runs the Kong Air control planes, zone proxies, external service registrations, and observability stack.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "{{site.mesh_product_name}} scenarios"
    url: /mesh/scenarios/
  - text: Developer
    url: /mesh/scenarios/persona/developer/
  - text: Security architect
    url: /mesh/scenarios/persona/security/
  - text: Architecture overview
    url: /mesh/architecture-overview/
  - text: Install {{site.mesh_product_name}} and deploy Kong Air
    url: /mesh/install-kong-mesh-and-deploy-kong-air/
  - text: Resource scoping
    url: /mesh/resource-scoping/
  - text: Multi-zone architecture
    url: /mesh/multi-zone-architecture/
  - text: Connect a second zone
    url: /mesh/connect-a-second-zone/
  - text: Send traffic between zones
    url: /mesh/send-traffic-between-zones/
  - text: Deploy an OpenTelemetry collector
    url: /mesh/deploy-an-opentelemetry-collector/
  - text: Observe mesh traffic in practice
    url: /mesh/observe-mesh-traffic-in-practice/
  - text: Target workloads and services
    url: /mesh/target-workloads-and-services/
  - text: Manage external services with MeshExternalService
    url: /mesh/manage-external-services-with-meshexternalservice/
  - text: Prepare the mesh for production
    url: /mesh/prepare-the-mesh-for-production/
  - text: Production readiness checklist
    url: /mesh/production-readiness-checklist/
---
The operator is a platform engineer at Kong Air.
The operator runs the mesh as a shared platform for application teams, such as the [developer](/mesh/scenarios/persona/developer/)'s team, and owns the operational core service, `flight-control`.
The operator keeps the platform available, observable, and efficient in every zone.

## How the operator runs the control planes

Kong Air runs one global control plane and one zone control plane in each zone:

* Global control plane: {{site.konnect_short_name}} hosts and operates it for Kong Air. The operator creates `kong-air-mesh` on it with `kongctl`, and a policy created there reaches every zone.
* Zone control plane: The operator installs one with Helm in each Kubernetes zone, `zone1` and `zone2`. It sends configuration to the local sidecars over xDS. A policy that a team creates on a zone control plane stays in that zone, unless it's a producer policy.

See [Install {{site.mesh_product_name}} and deploy Kong Air](/mesh/install-kong-mesh-and-deploy-kong-air/) and [Connect a second zone](/mesh/connect-a-second-zone/).
For which control plane owns each resource, see [Resource scoping](/mesh/resource-scoping/).

## How the operator connects zones

Kong Air runs `baggage-api` in `zone2`, and `passenger-portal` in `zone1` calls it, so traffic must cross zones.
The operator deploys a mesh-scoped zone ingress and zone egress for `kong-air-mesh` in each zone, in the `meshes` entry of the Helm values.

### Zone ingress

Every zone runs a zone ingress.
The zone ingress receives mTLS traffic from other zones and forwards it to a local instance of the service, without decrypting it.
The zone control plane publishes the address of the zone ingress in a `MeshZoneAddress`, so other zones know where to connect.
See [Send traffic between zones](/mesh/send-traffic-between-zones/).

### Zone egress and external services

Kong Air depends on two services outside the mesh: AeroPay, its payment provider, and `flight-db`, a managed PostgreSQL database.
The operator registers each one as a `MeshExternalService` in the system namespace, so workloads call it by a mesh hostname and every request to it leaves the zone through the zone egress:

* Only the zone egress needs a network path to the external service, not every sidecar.
* The zone egress opens the TLS connection to AeroPay, so the applications don't manage third-party CA bundles.

See [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/).

Cross-zone traffic between mesh services doesn't use the zone egress.
A caller's sidecar connects directly to the zone ingress of the other zone.
For both paths, see [Traffic paths](/mesh/mesh-scoped-zone-proxies/#traffic-paths).

## How the operator sets baseline timeouts

Some `zone1` services call slow back-office systems, so the operator gives every sidecar in `zone1` a 30-second request timeout.
The `MeshTimeout` lives in the system namespace and selects the proxies by their `kuma.io/zone` label, so it reaches every proxy in the zone.
The operator also gives `flight-control` its own 5-second timeout, with a policy that selects only its proxies.
See [Target workloads and services](/mesh/target-workloads-and-services/).

## How the operator provides observability

The operator configures observability for the whole mesh, so application teams don't need to decide where their telemetry goes.

* Collector: The operator runs an OpenTelemetry collector as a `DaemonSet`, and names it in one `MeshOpenTelemetryBackend`. `MeshMetric`, `MeshTrace`, and `MeshAccessLog` reference that backend, so the operator changes one resource to move the collector. See [Deploy an OpenTelemetry collector](/mesh/deploy-an-opentelemetry-collector/).
* Dashboards: Prometheus scrapes every sidecar, the zone proxies, and the control plane, and Grafana shows the {{site.mesh_product_name}} dashboards, including the Control Plane, Zone Ingress, and Zone Egress dashboards. See [Observe mesh traffic in practice](/mesh/observe-mesh-traffic-in-practice/).

## How the operator prepares the mesh for production

The Kong Air control planes start with `restrictOutbound` set to `false`, so every proxy receives configuration for every destination in the mesh.
That configuration grows with the number of services and costs control plane CPU and xDS bandwidth.
After each workload declares its destinations in `reachableBackends`, the operator sets `restrictOutbound` to `true` on every zone control plane.
See [Prepare the mesh for production](/mesh/prepare-the-mesh-for-production/) and the [Production readiness checklist](/mesh/production-readiness-checklist/).

The operator runs the control planes, zone proxies, and observability stack.
The developer's and the security architect's teams configure behavior with policies and don't manage the network themselves.
