---
title: "Persona: Ollie the Operator"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
  - /mesh/scenarios/persona/
description: How Ollie manages the global infrastructure, multi-zone networking, and consolidated observability for Kong Air's flight systems.
products:
  - mesh
next_steps:
  - text: "Observability in Practice"
    url: "/mesh/scenarios/observability-in-practice/"
  - text: "Multi-Zone Architecture"
    url: "/mesh/scenarios/multi-zone-architecture/"
  - text: "Mesh-Scoped Zone Proxies"
    url: "/mesh/scenarios/mesh-scoped-zone-proxies/"
---

Ollie is a Platform Engineer at **Kong Air**. His mission is to provide a "Service Mesh as a Service" to teams like Devin's. He manages the underlying infrastructure, ensuring that the **Global Flight Logistics** platform remains highly available, observable, and performant across multiple geographic regions.

## 1. Global Infrastructure Control

Ollie manages a distributed architecture consisting of a **Global Control Plane** and multiple **Zone Control Planes**.

- **Global CP**: Acts as the single source of truth for all {{site.mesh_product_name}} policies. Ollie applies configurations once at the global level, and they are automatically synchronized to all zones.
- **Zone CP**: Handles the actual distribution of xDS configuration to local sidecars in zones like `zone1` and `zone2`.

## 2. Multi-Zone Networking

For the "Global Flight Search" service to span continents, Ollie configures specialized infrastructure proxies.

### Entry Points with `ZoneIngress`
Ollie ensures that every zone has a **ZoneIngress**. This proxy acts as the gateway for all cross-zone mTLS traffic. It automatically discovers local services and advertises them to other zones via the Global CP.

### Secure Exits with `ZoneEgress`
To satisfy strict aviation industry regulations, Ollie routes all outgoing traffic (to other zones or the internet) through a **ZoneEgress**.
*   **Centralized Compliance**: Instead of every sidecar needing a path to the internet, only the ZoneEgress needs it.
*   **Auditability**: Ollie has a single point to audit every request leaving the zone.

```yaml
# Ollie ensures ZoneEgress is enabled on the kong-air-mesh
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: kong-air-mesh
spec:
  routing:
    zoneEgress: true
```

### Mesh-scoped zone proxies

For a mesh-per-tenant model, Ollie deploys dedicated zone proxies per mesh using the Helm `meshes:` list. Each entry provisions its own ingress/egress with independent HPA, PDB, and ServiceAccount, keeping `kong-air-mesh` isolated from any sibling meshes (for example, a separate mesh for ground operations). Two operational details:

*   The new embedded **ZoneEgress listeners are deny-by-default**. Every `MeshExternalService` is SNI-matched; Ollie needs to coordinate with Sarah on `MeshTrafficPermission` `Allow` rules tied to the caller's SPIFFE identity before any external call works.
*   The mesh-scoped model is the preferred operational shape for new deployments.

The recommended Helm shape for `kong-air-mesh` is:

```yaml
meshes:
  - name: kong-air-mesh
    ingress:
      enabled: true
    egress:
      enabled: true
```

Ollie only enables this after he confirms that `kong-air-mesh` is running with `spec.meshServices.mode: Exclusive`; otherwise the control plane skips zone proxy listener generation.

### How Ollie targets mesh-scoped zone proxies

Once the mesh-scoped proxies exist, Ollie works with them as ordinary `Dataplane` targets rather than as a special policy type:

- `kuma.io/listener-zoneingress: enabled` selects all mesh-scoped zone ingress proxies
- `kuma.io/listener-zoneegress: enabled` selects all mesh-scoped zone egress proxies
- `sectionName` narrows a policy to a single listener, for example `ze-port`

```yaml
targetRef:
  kind: Dataplane
  labels:
    kuma.io/listener-zoneegress: enabled
  sectionName: ze-port
```

That is the standard shape for policies such as `MeshTrace` or zone-egress-specific traffic controls.

### Envoy admin API on UDS

Sidecar Envoy admin uses a **Unix domain socket by default**. A readiness reverse-proxy on TCP `9902` exposes the admin endpoints for `kubectl exec`, probes, and existing debug scripts. The `KUMA_EXPERIMENTAL_ADMIN_UNIX_SOCKET` environment variable is renamed to `KUMA_BOOTSTRAP_SERVER_PARAMS_ADMIN_UNIX_SOCKET`. Any tooling Ollie has wired to `localhost:9901` needs to switch to the UDS path or `localhost:9902`.

## 3. High-Availability Gateway Infrastructure

Ollie manages the **MeshGatewayInstance** resources that surface Devin's services to the outside world. He ensures they are scaled for peak travel season. The `tags` block below defines the gateway's own identity. When a *policy* needs to target this gateway, address it as a `MeshService` rather than a `kuma.io/service` tag selector, that label-selected model is the modern targeting story used throughout these scenarios.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: booking-gateway-ha
  namespace: kong-air-gateways
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  replicas: 5 # Ensuring plenty of capacity for peak travel season
  serviceType: LoadBalancer
  tags:
    kuma.io/service: booking-gateway
```

## 4. Global Observability Policies

Ollie provides "Observability as a Service" so Devin doesn't have to worry about where his logs and traces go.

### Distributed Tracing (`MeshTrace`)
Ollie sets up end-to-end tracing across all zones, exporting spans via OTLP/gRPC to a global collector. In 2.14, the recommended pattern is to define one `MeshOpenTelemetryBackend` and reference it from every observability policy, see [Observability in Practice](/mesh/scenarios/observability-in-practice/) for the full pattern. In 2.14 only the gRPC OTel transport is supported; the earlier HTTP/HTTPS OTel transports have been removed.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: global-flight-trace
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            name: kong-air-otel
    sampling:
      overall: 100 # High sampling for mission-critical logistics
```

### Log Aggregation (`MeshAccessLog`)
To maintain a historical record of all flight search requests, Ollie streams access logs to a central logging server.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: global-audit-logs
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: Tcp
        tcp:
          address: log-aggregator.internal.kongair:5000
          format:
            type: Plain
            plain: '[%START_TIME%] %KUMA_SOURCE_SERVICE% -> %KUMA_DESTINATION_SERVICE% (%RESPONSE_CODE%)'
```

{% tip %}
To scope a policy to a slice of the fleet (a whole zone, an environment, a region), Ollie sets the top-level `targetRef` to **`Dataplane`** with a `labels:` selector, for example `kuma.io/zone: zone1` or `environment: production`. Top-level `MeshSubset`, `MeshServiceSubset`, and `MeshService` are older targeting shapes; use `Dataplane` with labels going forward. See the [Subsets & Targeting Guide](/mesh/scenarios/subsets-and-targeting/) for examples.
{% endtip %}

## 5. Operational Health & Lifecycle

Ollie monitors the health of the mesh using the Control Plane's built-in metrics. He tracks:
- **CP-to-DP Latency**: How quickly policy changes reach Devin's sidecars.
- **Cross-Zone Latency**: The performance of the network between US and EU zones.
- **Resource Utilization**: Ensuring ZoneIngress and Egress proxies have sufficient CPU/RAM.

## Ollie's Result
By operating the control plane, zone proxies, gateways, and observability stack centrally, Ollie gives Devin's and Sarah's teams a consistent platform to build on, they configure behavior through policy without managing the underlying networking themselves.
