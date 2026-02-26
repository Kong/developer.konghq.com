---
title: Multi-Zone Architecture
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: An in-depth look at multi-zone specific features in {{site.mesh_product_name}}, covering infrastructure components, service federation, and global telemetry.
products:
  - mesh
tldr:
  q: How do I manage a global service mesh across multiple regions?
  a: |
    Kong Mesh provides a specialized multi-zone fabric to:
    1. **Bridge hybrid environments** (Kubernetes and Universal) seamlessly.
    2. **Scale operations** with ZoneIngress for cross-zone connectivity and ZoneEgress for controlled routing.
    3. **Ensure resilience** via Global Control Plane orchestration and KDS synchronization.
next_steps:
  - text: "Multi-Tenancy Strategies"
    url: "/mesh/scenarios/multi-tenancy-strategies/"
---
This guide explores the specialized components and patterns that make global, resilient deployments simple to operate.

## 1. Multi-Zone Components

In a multi-zone deployment, traffic doesn't just flow between sidecars; it often needs to cross network boundaries. {{site.mesh_product_name}} uses specialized proxies to manage this transition.

### ZoneIngress: The Entry Point
The **ZoneIngress** is a dedicated proxy that handles traffic entering a zone from other zones.
*   **Encapsulation**: It receives encrypted and authenticated mTLS traffic from other zones and routes it to the correct local service instance.
*   **Service Discovery**: It advertises the services available in its local zone to the Global Control Plane, which then informs other zones.
*   **Automatic Setup**: In most environments, {{site.mesh_product_name}} can automatically deploy and manage ZoneIngress instances.

### ZoneEgress: The Exit Point (Optional but Recommended)
The **ZoneEgress proxy** provides a centralized way for all traffic to leave a zone.
*   **Centralized Control**: Routes all outgoing traffic (to other zones or external services) through a single point, enabling strict firewall rules.
*   **Unified Egress Visibility**: Provides a single vantage point to monitor and audit all traffic leaving the zone, simplifying global traffic analysis.
*   **Isolation**: Ensures that sidecars don't need direct routable access to every other zone; they only need to reach their local ZoneEgress.

## 2. Service Federation

Service Federation is the mechanism that allows services to discover and communicate with each other across zone boundaries.

### Automatic Cross-Zone Discovery
{{site.mesh_product_name}} automatically synchronizes service information across zones via the Global Control Plane.
*   **Global DNS**: Services can be reached using a unified DNS name (e.g., `service.namespace.svc.mesh.local`).
*   **Locality-Aware Routing**: By default, {{site.mesh_product_name}} prefers to route traffic to the most "local" instance of a service (within the same zone) to reduce latency.

### MeshMultiZoneService
The **MeshMultiZoneService** (MMZS) resource allow Kong Air to explicitly define services that span multiple zones, such as the `flight-control` system.
*   **Unified Identity**: It groups instances of `flight-control` across different clusters into a single logical entity.
*   **Failover**: If the `flight-control` instances in the `us-east-1` data center fail, traffic is automatically rerouted to `eu-west-1`.
*   **Load Balancing**: Kong Air can customize how traffic is weighted across zones to support global active-active flight registries.

## 3. Global Telemetry

Observability in a multi-zone mesh requires consolidating data from many distributed sources into a unified view.

### Consolidated Metrics
While each Zone Control Plane collects metrics from its local proxies, {{site.mesh_product_name}} allows you to aggregate these at a global level.
*   **MeshMetric Policy**: Define how metrics (Prometheus/OpenTelemetry) are collected across the entire mesh.
*   **Global Dashboarding**: Use one Grafana instance to view the health of your services, regardless of which cloud or data center they are running in.

### Distributed Tracing
{{site.mesh_product_name}} supports end-to-end distributed tracing across zone boundaries.
*   **MeshTrace Policy**: Configure tracing backends (like Jaeger, Zipkin, or Datadog) globally.
*   **Context Propagation**: Tracing headers are automatically propagated as requests move from a sidecar in Zone A, through ZoneIngress, into Zone B, and finally to the destination sidecar.

### Traffic Logging
Using the **MeshAccessLog** policy, you can send logs from every zone to a centralized logging server (like Splunk or ELK). This ensures you have a complete audit trail for all cross-zone interactions.

---

By combining these specialized components and policies, {{site.mesh_product_name}} transforms a collection of isolated clusters into a single, cohesive, and resilient global infrastructure.
