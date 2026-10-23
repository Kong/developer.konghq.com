---
title: Multi-zone architecture
content_type: reference
layout: reference
description: Learn what changes when Kong Air adds a second zone, and which control planes, zone proxies, identity, and service resources carry traffic between zones.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
min_version:
  mesh: '3.0'
next_steps:
  - text: "How-to: Configure mesh-scoped zone proxies"
    url: "/mesh/configure-mesh-scoped-zone-proxies/"
related_resources:
  - text: Mesh-scoped zone proxies
    url: /mesh/mesh-scoped-zone-proxies/
  - text: MeshMultiZoneService
    url: /mesh/meshmultizoneservice/
  - text: Resource scoping
    url: /mesh/resource-scoping/
  - text: Manage workload identity and mTLS
    url: /mesh/manage-workload-identity-and-mtls/
---

The earlier Kong Air scenarios use one Kubernetes zone, `zone1`.
A multi-zone deployment connects a second zone, `zone2`, to the same global control plane.
Applications keep calling service hostnames.
The mesh finds the zone where the destination runs and carries the request across the zone boundary.

This page explains what changes when Kong Air adds `zone2`.
The next scenario deploys the zone proxies that carry the traffic.

## Components of a multi-zone deployment

The global control plane, the zone control planes, and the proxies each have a different job:

<!-- vale off -->
{% table %}
columns:
  - title: Component
    key: component
  - title: What it does
    key: responsibility
  - title: Carries application traffic
    key: traffic
rows:
  - component: "Global control plane"
    responsibility: "Stores global resources, sends them to the zones over KDS, and keeps an inventory of every zone."
    traffic: "No"
  - component: "Zone control plane"
    responsibility: "Finds the workloads in its zone, exchanges resources with the global control plane over KDS, and sends configuration to the local proxies over xDS."
    traffic: "No"
  - component: "Application proxy (sidecar)"
    responsibility: "Intercepts the traffic of its workload and applies routing, mTLS, authorization, and other policies."
    traffic: "Yes"
  - component: "Mesh-scoped zone ingress and zone egress"
    responsibility: "Carry the traffic of one mesh into and out of the zone."
    traffic: "Yes"
{% endtable %}
<!-- vale on -->

{% mermaid %}
flowchart LR
    K["Global control plane"]

    subgraph Z1["zone1"]
      C1["Zone control plane"]
      A1["check-in-api<br/>sidecar"]
    end

    subgraph Z2["zone2"]
      C2["Zone control plane"]
      I2["Zone ingress"]
      A2["flight-control<br/>sidecar"]
    end

    K <-.->|KDS| C1
    K <-.->|KDS| C2
    C1 -.->|xDS| A1
    C2 -.->|xDS| I2
    C2 -.->|xDS| A2
    A1 --> I2
    I2 --> A2
{% endmermaid %}

KDS and xDS carry configuration only.
The solid arrows show the application request, which never passes through a control plane.

In the default path, the `check-in-api` sidecar in `zone1` connects directly to the zone ingress in `zone2`.
The zone ingress then forwards the request to `flight-control`.
If you also deploy a zone egress in `zone1`, the request passes through it before it reaches the zone ingress.

## Mesh-scoped zone proxies

Each zone runs a zone ingress for every mesh that receives traffic from other zones.
A zone egress is optional.
The zone ingress and zone egress belong to `kong-air-mesh`, so they get a workload identity from its `MeshIdentity` and report metrics for that mesh only.

You can apply policies to the zone proxies.
The zone control plane adds the `kuma.io/listener-zoneingress: enabled` or `kuma.io/listener-zoneegress: enabled` label to each zone proxy, and a policy selects the zone proxies with that label in its `targetRef`.
Not every policy supports zone proxies, so check the policy reference first.
For example, `MeshTrafficPermission` applies to a zone egress, but not to a zone ingress.

Other zones find the zone ingress through a `MeshZoneAddress`.
On Kubernetes, the zone control plane creates it from the zone ingress Service.

For deployment, addressing, and policy details, see [Mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/).

## Identity and trust across zones

A cross-zone request succeeds only when three conditions are met:

1. A `MeshIdentity` gives a workload identity to the application sidecars and the zone proxies.
1. Each zone trusts the certificate authority (CA) that signed the certificates of the other zone.
1. A `MeshTrafficPermission` allows the SPIFFE ID of the caller from the other zone.

Workload identity also controls routing.
The zone control plane sends a caller the endpoints of a `MeshService` in another zone only when the caller has a workload identity.
Without one, the request fails before authorization.

In [Create a security policy](/mesh/create-a-security-policy/), each zone generates its own CA and its own trust domain.
Each zone sends its generated `MeshTrust` to the global control plane, but not to the other zones.
Before you test traffic between zones, complete [Extend autogenerated identity across zones](/mesh/manage-workload-identity-and-mtls/#extend-autogenerated-identity-across-zones).
In production, we recommend a shared CA, such as a managed CA or SPIRE, because the identity platform then distributes trust for you.

## Service hostnames across zones

Each zone control plane creates a `MeshService` for each local service and sends it to the other zones through the global control plane.
In `zone1`, `check-in-api` reaches `flight-control` in `zone2` with a hostname that includes the zone:

```text
flight-control.kong-air-production.svc.zone2.mesh.local
```
{:.no-copy-code}

Use this hostname when the caller needs the service in one specific zone.
A hostname doesn't grant access or establish trust.
For more information, see [MeshService](/mesh/meshservice/).

To give callers one hostname for a service that runs in several zones, create a `MeshMultiZoneService` on the global control plane.
For example, `flight-control-global` combines the `flight-control` services of both zones, and callers use this hostname:

```text
flight-control-global.mzsvc.mesh.local
```
{:.no-copy-code}

A `MeshLoadBalancingStrategy` decides which zone receives each request, and a `MeshHTTPRoute` can split traffic between destinations.
You can change these policies without changing the hostname that applications call.
For more information, see [MeshMultiZoneService](/mesh/meshmultizoneservice/).

## Observability across zones

The control planes configure telemetry, but they don't collect it.
Each proxy sends or exposes its own metrics, traces, and access logs:

* `MeshMetric` exposes or exports metrics. Prometheus or an OpenTelemetry collector collects them from each zone.
* `MeshTrace` makes the proxies create spans. Applications must forward the trace context between their own requests to produce one end-to-end trace.
* `MeshAccessLog` sends access logs to a file, a TCP endpoint, or an OpenTelemetry collector.

To build a dashboard for every zone, send the data of all zones to the same backends, and label it with the mesh, zone, workload, and service.
[Observe mesh traffic in practice](/mesh/observe-mesh-traffic-in-practice/) shows this setup for Kong Air.

## Requirements before you continue

Before you deploy or test routes between zones, make sure that:

1. `zone1` and `zone2` are both online.
1. `kong-air-mesh` exists in both zones.
1. Each zone has the workload identity, `MeshTLS`, and `MeshTrafficPermission` policies that the scenarios need.
1. Each zone trusts the certificates of the other zone.
1. Both zones run mesh-scoped zone proxies for `kong-air-mesh`.

The next scenario configures those zone proxies and shows how to confirm that they belong to `kong-air-mesh`.
