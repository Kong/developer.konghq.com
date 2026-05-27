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
    {{site.mesh_product_name}} provides a specialized multi-zone fabric to:
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

### Mesh-scoped zone proxies (2.14+)

In 2.14, {{site.mesh_product_name}} introduces a **mesh-scoped zone proxy** model: instead of (or alongside) a single fleet-wide ZoneIngress / ZoneEgress, you can deploy a dedicated pair per mesh. This is configured via the Helm `meshes:` list and gives Kong Air-style multi-tenant deployments isolation between mesh boundaries (per-mesh HPA, PDB, ServiceAccount, and so on).

{% tip %}
**If you're on 2.13:** stay with the original fleet-wide `ingress` / `egress` deployment model. The rest of this section is specifically about the new 2.14 mesh-scoped deployment shape, which is additive rather than a flag day migration.
{% endtip %}

Two operational implications worth knowing:

*   **Embedded ZoneEgress listeners are deny-by-default.** Each `MeshExternalService` is matched on SNI inside the listener and refused unless a `MeshTrafficPermission` `Allow` rule names the caller's SPIFFE identity. There is no implicit "everything is allowed through ZE" semantic any more — an explicit allow is mandatory.
*   **Coexists with the global model.** You can still run the original fleet-wide `ingress`/`egress` chart values; the new `meshes:` list is additive. Migrate per mesh as it makes sense.

## 2. Service Federation

Service Federation is the mechanism that allows services to discover and communicate with each other across zone boundaries.

### Automatic Cross-Zone Discovery
{{site.mesh_product_name}} automatically synchronizes service information across zones via the Global Control Plane.
*   **Per-zone service import**: In an `Exclusive` mesh, each zone receives synced copies of remote `MeshService` resources. The built-in `HostnameGenerator` gives those imported services zone-qualified hostnames such as `flight-control.kong-air-production.svc.zone2.mesh.local`.
*   **Generated VIPs**: Imported cross-zone services are assigned Kuma VIPs from the multi-zone range (for example `241.0.0.0`). Clients talk to the VIP or generated hostname, and the local zone routes through ZoneIngress / ZoneEgress as needed.
*   **Locality-aware by design**: A direct zonal hostname points at a specific remote zone. Use it when Kong Air knows exactly which remote zone should serve the request.

{% warning %}
**2.13 validation note.** On the test mesh, zone-qualified hostnames such as `flight-control.kong-air-production.svc.zone2.mesh.local` and `check-in-api.kong-air-production.svc.zone2.mesh.local` resolved correctly in `zone1`, but after enabling `MeshIdentity` the direct cross-zone request path was not reliable end to end. The destination dataplanes in `zone2` repeatedly timed out their initial SDS secret fetch and reset the connection before serving the request. Plain names such as `flight-control.mesh` or `flight-control.kong-air-production.svc.mesh.local` also did **not** resolve automatically.
{% endwarning %}

{% tip %}
For 2.13 production guidance, treat the direct per-zone `MeshService` hostname as an advanced path that still needs final engineering validation in your environment. The validated cross-zone service abstraction in this scenario set is `MeshMultiZoneService`.
{% endtip %}

### MeshMultiZoneService
The **MeshMultiZoneService** (MMZS) resource allows Kong Air to explicitly define services that span multiple zones, such as the `flight-control` system.
*   **Unified Identity**: It groups instances of `flight-control` across different clusters into a single logical entity.
*   **Failover**: If the `flight-control` instances in the `us-east-1` data center fail, traffic is automatically rerouted to `eu-west-1`.
*   **Load Balancing**: Kong Air can customize how traffic is weighted across zones to support global active-active flight registries.

The important distinction is:

*   Use the **synced per-zone `MeshService` hostname** when you want a specific remote zone and you have separately validated that direct cross-zone path in your environment, for example `flight-control.kong-air-production.svc.zone2.mesh.local`.
*   Use **`MeshMultiZoneService`** when you want a single mesh-wide service name that can represent one or more zones, for example `flight-control-global.mzsvc.mesh.local`. This is the validated 2.13 pattern from the live mesh.

{% navtabs "mmzs-example" %}
{% navtab "Universal / Global CP" %}
```bash
echo 'type: MeshMultiZoneService
name: flight-control-global
mesh: kong-air-mesh
labels:
  kuma.io/display-name: flight-control-global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: flight-control
        k8s.kuma.io/namespace: kong-air-production
  ports:
    - port: 8080
      appProtocol: tcp' | kumactl apply -f -
```
{% endnavtab %}
{% navtab "What this creates" %}
```text
Hostname: flight-control-global.mzsvc.mesh.local
VIP:      243.0.0.0
```
{% endnavtab %}
{% endnavtabs %}

{% tip %}
**Validated 2.13 behavior.** After applying the `MeshMultiZoneService` above on the Konnect Global CP, both zones received a synced copy with `status.addresses[0].hostname: flight-control-global.mzsvc.mesh.local`. Requests from `zone1` to that hostname reached `flight-control` in `zone2`.
{% endtip %}

{% warning %}
**Name length: 63 characters max.** MMZS names must be valid RFC 1035 DNS labels (≤63 chars, lowercase alphanumeric or `-`, start with a letter, end with an alphanumeric). 2.14 emits a deprecation warning on longer names; 3.0 will reject them outright. The same limit applies to `MeshService` and `MeshExternalService`.
{% endwarning %}

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
