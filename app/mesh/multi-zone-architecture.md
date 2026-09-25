---
title: Multi-zone architecture
content_type: reference
layout: reference
description: Understand how the global control plane, zone control planes, mesh-scoped zone proxies, identity, and service resources work together across zones.
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
  - text: "Configure mesh-scoped zone proxies"
    url: "/mesh/configure-mesh-scoped-zone-proxies/"
related_resources:
  - text: Resource scoping
    url: /mesh/resource-scoping/
  - text: Manage workload identity and mTLS
    url: /mesh/manage-workload-identity-and-mtls/
  - text: Deploy mesh-scoped zone proxies
    url: /mesh/zone-proxies/
---

The earlier Kong Air scenarios use one Kubernetes zone, `zone1`. A multi-zone deployment adds another environment, `zone2`, to the same global control plane. Applications continue to talk to service hostnames; the mesh resolves where the destination runs and carries remote traffic across the zone boundary.

This page explains what changes when the second zone is added. The next scenario applies that model by deploying the zone proxies.

## The multi-zone control plane

The global control plane and each zone control plane have different responsibilities:

<!-- vale off -->
{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibility
    key: responsibility
  - title: Does application traffic pass through it?
    key: traffic
rows:
  - component: "Global control plane"
    responsibility: "Owns global resources, coordinates zones over KDS, and provides the central inventory."
    traffic: "No"
  - component: "Zone control plane"
    responsibility: "Discovers local workloads, exchanges supported resources over KDS, and sends xDS configuration to local proxies."
    traffic: "No"
  - component: "Application data plane"
    responsibility: "Intercepts workload traffic and enforces routing, mTLS, authorization, and other policy."
    traffic: "Yes"
  - component: "Mesh-scoped zone ingress and egress"
    responsibility: "Carry data-plane traffic across zone boundaries for one mesh."
    traffic: "Yes"
{% endtable %}
<!-- vale on -->

{% mermaid %}
flowchart LR
    K["Global control plane"]

    subgraph Z1["zone1"]
      C1["Zone CP"]
      A1["check-in-api<br/>data plane"]
    end

    subgraph Z2["zone2"]
      C2["Zone CP"]
      I2["Zone ingress"]
      A2["flight-control<br/>data plane"]
    end

    K <-.->|KDS| C1
    K <-.->|KDS| C2
    C1 -.->|xDS| A1
    C2 -.->|xDS| I2
    C2 -.->|xDS| A2
    A1 --> I2
    I2 --> A2
{% endmermaid %}

KDS and xDS are control-plane channels. The solid path is the application request; it does not pass through the global or zone control planes.

This is the default path. The calling sidecar connects straight to the remote zone's ingress, so only one zone proxy sits in the request path. Deploying a mesh-scoped zone egress inserts it as an extra hop before the remote ingress. Topology decides this in 3.0: the `routing.zoneEgress` toggle was removed from the `Mesh` schema, so whether a zone egress exists for the mesh is what determines the path.

## Mesh-scoped zone proxies

Each zone deploys a zone ingress for every mesh that needs cross-zone connectivity. A zone egress is optional, and is only needed when the mesh routes outbound traffic through it.

Because these proxies are `Dataplane` resources inside `kong-air-mesh`, they:

* Receive a workload identity from a matching `MeshIdentity`.
* Enforce the same policy model as application sidecars when the policy supports their listener role.
* Expose metrics and access logs that belong to this mesh rather than a mixture of unrelated meshes.
* Can be selected with listener labels such as `kuma.io/listener-zoneingress: enabled` and `kuma.io/listener-zoneegress: enabled`.

The zone ingress accepts traffic arriving from another zone and routes it to a local service instance. The zone egress provides the outbound hop when the mesh topology routes cross-zone or `MeshExternalService` traffic through it. The zone control planes and KDS synchronize service state; the zone ingress does not advertise services itself.

What advertises the ingress is a separate resource. When a mesh-scoped zone ingress comes up, its zone control plane publishes a `MeshZoneAddress` holding the address and port other zones should dial for that mesh:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshZoneAddress
metadata:
  name: kong-mesh-kong-air-mesh-ingress
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/zone: zone1
```
{:.no-copy-code}

`MeshZoneAddress` takes priority over the older deployment-wide `ZoneIngress` resource for any zone that publishes one, which is what makes the ingress path per-mesh rather than shared. Scaling a zone ingress to zero withdraws its `MeshZoneAddress`, so other zones stop routing to it.

## Identity and authorization across zones

Cross-zone security has three separate requirements:

1. The application sidecars and zone proxies need identities issued by `MeshIdentity`.
1. Each zone must trust the CA that issued the peer zone's certificates.
1. `MeshTrafficPermission` must authorize the peer-zone caller's SPIFFE ID.

The first requirement is not only a security control. The control plane programs remote endpoints for a `MeshService` only when mTLS is in place, so without workload identity a caller gets no cross-zone endpoints at all and the request fails at resolution rather than at authorization.

With the autogenerated Bundled provider used in the first scenario, each zone creates its own CA and zone-aware trust domain. KDS sends the generated trust to the global control plane for visibility, but it does not automatically install that trust in every other zone. Complete [Extend autogenerated identity across zones](/mesh/manage-workload-identity-and-mtls/#extend-autogenerated-identity-across-zones) before testing remote traffic.

In production, Kong Air would normally use a shared managed CA or SPIRE so trust distribution is part of the identity platform rather than a manual zone-to-zone operation.

## Service federation

Every zone creates `MeshService` resources for its local services. KDS synchronizes the service information needed by the rest of the deployment, and the default `synced-kube-mesh-service` hostname generator gives a Kubernetes service a zone-qualified hostname from the template `{% raw %}{{ .DisplayName }}.{{ .Namespace }}.svc.{{ .Zone }}.mesh.local{% endraw %}`:

```text
flight-control.kong-air-production.svc.zone2.mesh.local
```
{:.no-copy-code}

Use that hostname when the caller must reach the service in one specific zone. The hostname describes the destination; it does not by itself grant permission or establish trust.

## One destination spanning zones

Use `MeshMultiZoneService` when callers should use one stable destination while the backing services can run in several zones. The global control plane owns this resource because it needs the service inventory from every zone.

```yaml
type: MeshMultiZoneService
name: flight-control-global
mesh: kong-air-mesh
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/mesh: kong-air-mesh
        k8s.kuma.io/service-name: flight-control
        k8s.kuma.io/namespace: kong-air-production
  ports:
    - port: 8080
      appProtocol: http
```

The selector matches `MeshService` resources on their labels alone, with no implicit mesh filter, so include `kuma.io/mesh` to keep a same-named service in another mesh out of `status.meshServices`. `appProtocol` defaults to `tcp` when omitted.

Create the resource through the global control plane. Each zone then receives a read-only copy and resolves the generated hostname:

```text
flight-control-global.mzsvc.mesh.local
```
{:.no-copy-code}

`MeshMultiZoneService` defines the multi-zone destination and its backends. `MeshLoadBalancingStrategy` controls locality preference and cross-zone failover, while `MeshHTTPRoute` can split or redirect traffic between destinations. Keeping those decisions in separate resources makes it possible to change rollout behavior without changing the hostname used by applications.

## Observability across zones

The control planes configure telemetry; they do not collect application telemetry or aggregate it automatically at the global level.

* `MeshMetric` configures metric exposure or export on selected data planes. Prometheus or an OpenTelemetry collector gathers the data from each zone.
* `MeshTrace` configures proxy-generated spans and their backend. Applications must propagate trace context across their own internal request hops for one end-to-end trace.
* `MeshAccessLog` sends proxy access records to the configured file, TCP, or OpenTelemetry destination.

A global dashboard is therefore an observability-backend design: send or scrape data from all zones into backends that share labels for mesh, zone, workload, and service. The global control plane does not aggregate application telemetry.

## Before continuing

Before deploying or testing cross-zone routes, make sure:

1. `zone1` and `zone2` are both online.
1. `kong-air-mesh` is present in both zones.
1. The workload identity, `MeshTLS`, and required `MeshTrafficPermission` policy exist in each zone.
1. Each zone trusts certificates issued by the other zone.
1. Every mesh that needs cross-zone connectivity has mesh-scoped zone proxies enabled in both zones.

The next scenario configures those proxies and shows how to verify that they belong to `kong-air-mesh` before any application route depends on them.
