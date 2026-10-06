---
title: Production readiness checklist
content_type: reference
layout: reference
description: The {{site.mesh_product_name}} 3.0 defaults to set deliberately and the control plane settings that shape configuration at scale before a mesh carries production traffic.
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
related_resources:
  - text: Prepare the mesh for production
    url: /mesh/prepare-the-mesh-for-production/
  - text: Concepts
    url: /mesh/concepts/
  - text: Multi-zone architecture
    url: /mesh/multi-zone-architecture/
---

Before a {{site.mesh_product_name}} 3.0 mesh carries production traffic, check the control plane settings that decide how much configuration it generates and how fast that configuration propagates, then work through the defaults that 3.0 closes rather than leaves open.

## Controls that shape configuration at scale

`reachableBackends` is the largest lever, because it is the one that scales with the service count. See [Prepare the mesh for production](/mesh/prepare-the-mesh-for-production/) to declare it. Three other controls decide how much work the control plane does and how quickly its output arrives.

### The xDS refresh interval

The control plane regenerates the xDS configuration of every connected proxy on `xdsServer.dataplaneConfigurationRefreshInterval` (`KUMA_XDS_SERVER_DATAPLANE_CONFIGURATION_REFRESH_INTERVAL`), which defaults to `10s` in 3.0 instead of the previous `1s`. Regenerating every proxy every second kept the control plane busy and scaled poorly with the number of proxies.

Changes to meshes, policies, and services now take up to ten seconds to reach proxies. So do trust bundles, which has one consequence worth planning for: a CA rotation must leave the old CA in place for at least one refresh interval after the new one is added, or proxies that have not yet refreshed fail mTLS. See [Integrate an external CA](/mesh/integrate-an-external-ca/). If a deployment genuinely needs faster propagation, lower the interval deliberately and budget the control plane CPU for it.

### KDS synchronization between zones

In a multi-zone deployment the global and zone control planes exchange resources over KDS, and the event-based watchdog defaults changed in 3.0:

<!-- vale off -->
{% table %}
columns:
  - title: Setting
    key: setting
  - title: Before
    key: before
  - title: "3.0"
    key: after
rows:
  - setting: "`flushInterval`"
    before: "`1s`"
    after: "`5s`"
  - setting: "`fullResyncInterval`"
    before: "`1s`"
    after: "`1m`"
  - setting: "`delayFullResync`"
    before: "`false`"
    after: "`true`"
{% endtable %}
<!-- vale on -->

These apply to both `multizone.global.kds.eventBasedWatchdog` and `multizone.zone.kds.eventBasedWatchdog`. At `1s` every connected zone rebuilt and re-hashed its entire snapshot every second and shipped an identical one. Changes still travel on the event path, coalesced over `flushInterval`, and a change missed on that path is repaired by the next full resync rather than within a second. See [Multi-zone architecture](/mesh/multi-zone-architecture/).

### Policy target breadth

A policy with a top-level `targetRef` of `kind: Mesh` has to be evaluated for every proxy in the mesh. Selecting the workloads a policy is actually meant to affect keeps that work proportional to the policy's real scope, and makes the policy easier to reason about when several of them overlap. See [Policy targeting and precedence](/mesh/policy-targeting-and-precedence/) and [Target workloads and services](/mesh/target-workloads-and-services/).

## Defaults to set deliberately

The following items are things {{site.mesh_product_name}} 3.0 expects you to decide rather than inherit. Each one is covered in full by the scenario it links to.

<!-- vale off -->
{% table %}
columns:
  - title: Area
    key: area
  - title: What to do
    key: action
  - title: Where
    key: where
rows:
  - area: "Outbound to the internet"
    action: "Outbound passthrough defaults to `None`, so a transparent proxy that no `MeshPassthrough` selects drops traffic to anything outside the mesh. Allow the destinations your workloads use."
    where: "[Secure the perimeter with MeshPassthrough](/mesh/secure-the-perimeter-with-meshpassthrough/)"
  - area: "Retries"
    action: "A new mesh gets no default policies. Timeouts and circuit breakers keep the values the control plane writes anyway, but a mesh without a `MeshRetry` does not retry at all. Apply one."
    where: "[Validate resilience with fault injection](/mesh/validate-resilience-with-fault-injection/)"
  - area: "Inbound ports"
    action: "Strict inbound ports can no longer be turned off. A sidecar with transparent proxy and a workload identity accepts traffic only on the ports of its inbounds, so declare every port the workload receives on."
    where: "[Concepts](/mesh/concepts/#inbound)"
  - area: "Identity"
    action: "Replace the autogenerated per-zone CA with one you control, so trust distribution and rotation belong to your identity platform rather than to a manual zone-to-zone operation."
    where: "[Integrate an external CA](/mesh/integrate-an-external-ca/)"
  - area: "Authorization"
    action: "Run `MeshTLS` in `Strict` mode and keep `MeshTrafficPermission` default-deny, so an undeclared call path fails at authorization as well as at resolution."
    where: "[Manage workload identity and mTLS](/mesh/manage-workload-identity-and-mtls/)"
  - area: "External services"
    action: "A `MeshExternalService` cluster requires a `MeshIdentity`. Confirm one matches the proxies that call it before the dependency is load bearing."
    where: "[Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/)"
  - area: "Cross-zone load balancing"
    action: "`MeshLoadBalancingStrategy` accepts `localityAwareness.crossZone` only on a `to` entry targeting a `MeshMultiZoneService`. The same block on a `Mesh`, `MeshService`, or `MeshExternalService` target is rejected."
    where: "[Multi-zone architecture](/mesh/multi-zone-architecture/)"
  - area: "Naming"
    action: "Names of `Mesh`, `Zone`, `MeshService`, `MeshExternalService`, and `MeshMultiZoneService` must be RFC 1035 labels, because `HostnameGenerator` renders them into DNS hostnames. Non-conforming names are rejected rather than warned about."
    where: "[Resource scoping](/mesh/resource-scoping/)"
  - area: "Observability"
    action: "Wire `MeshMetric`, `MeshTrace`, and `MeshAccessLog` to backends that share labels for mesh, zone, workload, and service, so one query spans every zone."
    where: "[Observe mesh traffic in practice](/mesh/observe-mesh-traffic-in-practice/)"
{% endtable %}
<!-- vale on -->
