---
title: Prepare the mesh for production
content_type: how_to
permalink: /mesh/prepare-the-mesh-for-production/
description: Bound the outbound configuration each proxy receives with reachableBackends, and set the {{site.mesh_product_name}} 3.0 defaults that production depends on.
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
tags:
  - service-mesh
  - data-plane
  - performance
tldr:
  q: What do I have to get right before this mesh carries production traffic?
  a: |
    Declare `reachableBackends` on every data plane proxy. It bounds the configuration the control plane generates and ships to each proxy, and in {{site.mesh_product_name}} 3.0 a proxy without it reaches nothing at all, because restricted outbound is on by default.

    Then work through the rest of the 3.0 defaults that are now closed rather than open: outbound passthrough, retries, inbound ports, and the certificate authority behind your workload identity.
prereqs:
  inline:
    - title: Kong Air demo deployment
      content: |
        A running {{site.mesh_product_name}} deployment with the Kong Air demo apps in `kong-air-mesh`. See [Get started with your first policy](/mesh/get-started-with-your-first-policy/).
    - title: kongctl
      include_content: md/mesh/v3/prereqs/kongctl
cleanup:
  inline:
    - title: Remove the reachable backend declarations
      include_content: md/mesh/v3/cleanup/reachable-backends
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
next_steps:
  - text: "Explore by role"
    url: "/mesh/persona/"
related_resources:
  - text: Secure the perimeter with MeshPassthrough
    url: /mesh/secure-the-perimeter-with-meshpassthrough/
  - text: Manage external services with MeshExternalService
    url: /mesh/manage-external-services-with-meshexternalservice/
  - text: Integrate an external CA
    url: /mesh/integrate-an-external-ca/
  - text: Concepts
    url: /mesh/concepts/
---

Every scenario so far has added a capability to the Kong Air mesh. This one takes the mesh that results and makes it fit to run.

Two kinds of work are involved. The first is bounding what the control plane has to compute and ship, which is what decides whether the mesh still behaves when Kong Air has three hundred services instead of three. The second is setting the {{site.mesh_product_name}} 3.0 defaults that are closed rather than open, so that nothing a production workload depends on is left to an implicit fallback.

## Why every proxy needs reachableBackends

By default the control plane assumes any workload might call any destination in its mesh. Each proxy therefore receives a cluster and an endpoint set for every destination, and the total configuration the control plane generates grows with the number of services multiplied by the number of proxies. The control plane regenerates that configuration on a timer and ships it over xDS, so the cost lands on control plane CPU, on xDS bandwidth, and on how long a change takes to reach the fleet.

`reachableBackends` replaces that assumption with a declaration. A proxy that states which destinations its workload actually calls receives configuration for those destinations and nothing else, which keeps the per-proxy configuration flat as the service count grows.

In {{site.mesh_product_name}} 3.0 the control plane setting `defaults.restrictOutbound` defaults to `true`, and a data plane proxy that declares no `reachableBackends` receives no outbound clusters at all. It cannot reach any service through the proxy.

{:.warning}
> Setting `defaults.restrictOutbound` to `false` restores the pre-3.0 behavior, where every proxy can reach every destination. Treat that as a step to help onboard workloads, not as the default.

## Declare reachable backends for Kong Air

The Kong Air call graph is small enough to write out in full. `passenger-portal` calls `check-in-api`, `check-in-api` calls `flight-control`, and `flight-control` calls nothing. Three declarations cover the whole mesh.

1. Declare what `passenger-portal` reaches:

   ```sh
   kubectl patch deployment passenger-portal -n kong-air-production --type merge -p '
   spec:
     template:
       metadata:
         annotations:
           kuma.io/reachable-backends: |
             refs:
             - kind: MeshService
               labels:
                 kuma.io/display-name: check-in-api
                 k8s.kuma.io/namespace: kong-air-production
               port: 8080
   '
   ```

   A ref selects backends by `kind` and `labels`. `kuma.io/display-name` is the service name and `k8s.kuma.io/namespace` is its namespace, both computed by the control plane. `port` is optional and narrows the ref to a single port, which is worth setting on a service that exposes more than one.

1. Declare what `check-in-api` reaches:

   ```sh
   kubectl patch deployment check-in-api -n kong-air-production --type merge -p '
   spec:
     template:
       metadata:
         annotations:
           kuma.io/reachable-backends: |
             refs:
             - kind: MeshService
               labels:
                 kuma.io/display-name: flight-control
                 k8s.kuma.io/namespace: kong-air-production
               port: 8080
   '
   ```

1. Declare that `flight-control` reaches nothing:

   ```sh
   kubectl patch deployment flight-control -n kong-air-production --type merge -p '
   spec:
     template:
       metadata:
         annotations:
           kuma.io/reachable-backends: |
             refs: []
   '
   ```

   An empty `refs` list is a real declaration, not a missing one. `flight-control` is a leaf service: it answers requests and originates none. Writing that down means a future change that gives it an outbound dependency has to be declared too, rather than working by accident.

1. Wait for the new pods to roll out. The annotation lives on the pod template, so the control plane sees it when the pod is recreated:

   ```sh
   kubectl rollout status deployment -n kong-air-production --timeout=120s
   ```

### What else a ref can select

`kind` accepts `MeshService`, `MeshMultiZoneService`, and `MeshExternalService`, so a declaration covers in-zone services, multi-zone destinations, and external dependencies in one place. See [Concepts](/mesh/concepts/) for how those three resources differ.

`labels: {}` selects every backend of that kind. The empty map is required rather than optional, because an omitted `labels` field and an empty one are indistinguishable once the ref is stored, so the control plane rejects a ref that omits it. Reaching for `labels: {}` to get a workload moving gives back most of the benefit of declaring anything, so prefer it as a short-lived diagnostic over a committed configuration.

### Confirm the declaration reached the control plane

1. Read the generated `Dataplane` resources back from the control plane:

   ```sh
   kongctl get mesh dataplanes --control-plane-name "$MESH_CP" --mesh kong-air-mesh -o yaml
   ```

   Each of the three Kong Air proxies carries its declaration under `networking.transparentProxying.reachableBackends`, and `flight-control` carries an empty object rather than no field at all. This reports what the control plane computed rather than what you wrote, so it is the authoritative answer to whether the annotation parsed.

1. Confirm that a declared destination is still reachable. `passenger-portal` declared `check-in-api`:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   Expected output:

   ```text
   wget: server returned error: HTTP/1.1 403 Forbidden
   ```
   {:.no-copy-code}

   A `403` is the right result here. It comes from `check-in-api`'s own inbound listener, which can only refuse a connection that arrived, so the outbound cluster exists and the request was delivered. [Get started with your first policy](/mesh/get-started-with-your-first-policy/) authorized `flight-control` and nothing else, so `MeshTrafficPermission` still denies `passenger-portal`. Reachability and authorization are separate gates, and this request cleared the first one.

1. Confirm that an undeclared destination is not reachable. `passenger-portal` never declared `flight-control`:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://flight-control.kong-air-production.svc.cluster.local:8080/
   ```

   Expected output:

   ```text
   wget: error getting response: Resource temporarily unavailable
   ```
   {:.no-copy-code}

   No `403`, and no HTTP response at all. The caller's proxy has no cluster for that destination, so the request fails at the caller and never reaches `flight-control`. Without the declaration the same request returns `403`, so the two failures tell you which gate stopped the traffic.

1. Confirm that `refs: []` means what it says. `flight-control` reached `check-in-api` successfully at the end of the first scenario, and `MeshTrafficPermission` still authorizes it:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   Expected output:

   ```text
   wget: error getting response: Resource temporarily unavailable
   ```
   {:.no-copy-code}

   An authorized path that the caller has not declared is not a path. Treat this as the check on your own service map: if a workload turns out to need a destination, give it a ref rather than leaving the permission to carry the traffic on its own.

## Other controls that shape config at scale

`reachableBackends` is the largest lever, because it is the one that scales with the service count. Three others decide how much work the control plane does and how quickly its output arrives.

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

## Production readiness checklist

The remaining items are things {{site.mesh_product_name}} 3.0 expects you to decide rather than inherit. Each one is covered in full by the scenario it links to.

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
