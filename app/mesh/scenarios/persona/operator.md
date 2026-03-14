---
title: "Persona: Ollie the Operator"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
  - /mesh/scenarios/persona/
description: A deep-dive into how Ollie manages the global infrastructure, multi-zone networking, and consolidated observability for Kong Air's flight systems.
products:
  - mesh
---

Ollie is a Platform Engineer at **Kong Air**. His mission is to provide a "Service Mesh as a Service" to teams like Devin's. He manages the underlying infrastructure, ensuring that the **Global Flight Logistics** platform remains highly available, observable, and performant across multiple geographic regions.

## 1. Global Infrastructure Control

Ollie manages a distributed architecture consisting of a **Global Control Plane** and multiple **Zone Control Planes**.

- **Global CP**: Acts as the single source of truth for all {{site.mesh_product_name}} policies. Ollie applies configurations once at the global level, and they are automatically synchronized to all zones.
- **Zone CP**: Handles the actual distribution of xDS configuration to local sidecars in regions like `us-east-1` and `eu-central-1`.

## 2. Multi-Zone Networking Deep Dive

For the "Global Flight Search" service to span continents, Ollie configures specialized infrastructure proxies.

### Entry Points with `ZoneIngress`
Ollie ensures that every zone has a **ZoneIngress**. This proxy acts as the gateway for all cross-zone mTLS traffic. It automatically discovers local services and advertises them to other zones via the Global CP.

### Secure Exits with `ZoneEgress`
To satisfy strict aviation industry regulations, Ollie routes all outgoing traffic (to other zones or the internet) through a **ZoneEgress**.
*   **Centralized Compliance**: Instead of every sidecar needing a path to the internet, only the ZoneEgress needs it.
*   **Auditability**: Ollie has a single point to audit every request leaving the zone.

```yaml
# Ollie ensures ZoneEgress is enabled in the Mesh configuration
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  routing:
    zoneEgress: true
```

## 3. High-Availability Gateway Infrastructure

Ollie manages the **MeshGatewayInstance** resources that Devin's team uses. He ensures they are scaled for high load.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: booking-gateway-ha
  namespace: kong-air-gateways
spec:
  replicas: 5 # Ensuring plenty of capacity for peak travel season
  serviceType: LoadBalancer
  tags:
    kuma.io/service: booking-gateway
```

## 4. Global Observability Policies

Ollie provides "Observability as a Service" so Devin doesn't have to worry about where his logs and traces go.

### Distributed Tracing (`MeshTrace`)
Ollie sets up End-to-End tracing across all zones, exporting spans to a global Jaeger instance.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: global-flight-trace
  namespace: kong-air-ops
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: otel-collector.monitoring.svc:4317
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
  namespace: kong-air-ops
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
Ollie often uses **`MeshSubset`** at the top level of his policies to target entire zones or environments without needing to list every service individually. Learn more in the [Subsets & Targeting Guide](/mesh/scenarios/subsets-and-targeting/).
{% endtip %}

## 5. Operational Health & Lifecycle

Ollie monitors the health of the mesh using the Control Plane's built-in metrics. He tracks:
- **CP-to-DP Latency**: How quickly policy changes reach Devin's sidecars.
- **Cross-Zone Latency**: The performance of the network between US and EU zones.
- **Resource Utilization**: Ensuring ZoneIngress and Egress proxies have sufficient CPU/RAM.

## Ollie's Result
By providing a robust, global infrastructure, Ollie has enabled Kong Air to scale their digital platform globally with zero downtime. He has decoupled the physical reality of the network from the application logic, allowing developers to focus on features while he ensures the global logistics machine never stops running.
