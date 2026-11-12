---
title: MeshMultiZoneService
description: Aggregate the same service across zones into one destination, so clients reach it wherever it runs.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - service-mesh
  - traffic-control
related_resources:
  - text: Policy targeting
    url: /mesh/policy-targeting/
  - text: MeshService
    url: /mesh/meshservice/
  - text: MeshLoadBalancingStrategy policy
    url: /mesh/policies/meshloadbalancingstrategy/
  - text: Migrate policies to {{site.mesh_product_name}} 3.x
    url: /mesh/migrate-policies-to-3/
  - text: "Concepts: Service model"
    url: /mesh/concepts/#service-model
min_version:
  mesh: '3.0'
---

`MeshMultiZoneService` gathers the [`MeshService`](/mesh/meshservice/) resources for one service across
zones into a single destination. A client names it instead of a per-zone service, and reaches
whichever zones are available.

`MeshMultiZoneService` is the destination kind that cross-zone failover attaches to:
`MeshLoadBalancingStrategy` accepts `localityAwareness.crossZone` only on a `to` entry
targeting a `MeshMultiZoneService`, because the failover order is a statement about zones and
this is the resource that spans them.

It isn't a policy: there is no `targetRef`, and the resource is the destination itself. You create it
on the global control plane only, which then syncs it out to zones.

## Aggregate a service across zones

The following example creates a `backend` destination from every `MeshService` named `backend`,
in every zone, and exposes their `http` port as port 80:

{% policy_yaml %}
```yaml
type: MeshMultiZoneService
mesh: default
name: backend
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/display-name: backend
  ports:
    - name: http
      port: 80
      appProtocol: http
```
{% endpolicy_yaml %}

## Selecting services

`spec.selector.meshService.matchLabels` picks the `MeshService` resources to aggregate. The
usual selector is `kuma.io/display-name`, which matches the same service in every zone, since a
synced `MeshService`'s resource name carries a zone-specific hash while its display name doesn't.

Adding `kuma.io/zone` narrows the aggregate to particular zones, which is how you
expose a service across a subset of them.

{:.warning}
> A display name is not unique across namespaces. `kuma.io/display-name: backend` matches every
> `MeshService` called `backend` in every namespace of every zone, including an unrelated
> service that happens to share the name. The aggregate then load balances across all of them,
> and requests that land on the unintended one usually fail authorization instead of
> returning a visible error. Add `k8s.kuma.io/namespace` on Kubernetes to pin the aggregate to one
> namespace, and read the `MeshServicesMatched` condition to confirm the count is what you
> expect.

## Ports

`spec.ports[]` lists the ports the aggregate exposes, and at least one is required. Each takes a `port`, an optional
`name`, and an `appProtocol` that defaults to `tcp`.

The ports are the aggregate's own, drawn from the selected services. The control plane matches each entry to a
port of each selected `MeshService` by name. The entry's `name` (or its `port` as
a string when `name` is unset) must equal a `MeshService` port's name or port number. A
`MeshService` with no matching port contributes no endpoints for that entry. On Kubernetes, a
generated `MeshService` port takes the `Service` port's name, or its number when the port is
unnamed.

A `MeshMultiZoneService` referenced in a route's `backendRefs` requires a `port` on the
reference, unlike a `MeshService`, where the control plane can infer it.

## Reading the status

The control plane reports what it computed for a `MeshMultiZoneService` in the resource's
`status`. The
following table describes its fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: Reports
    key: what
rows:
  - field: "`meshServices`"
    what: "Every matched `MeshService`, with its name, namespace, zone, and mesh. This is the list to check first when traffic isn't reaching a zone."
  - field: "`vips`"
    what: "The virtual IPs assigned to the aggregate."
  - field: "`addresses`"
    what: "The generated hostnames, and which generator produced each."
  - field: "`hostnameGenerators`"
    what: "Per-generator status."
  - field: "`conditions`"
    what: |
      `MeshServicesMatched`, with a reason of `MatchesFound` or `NoMatchesFound`.

      A `MeshServicesMatched` condition reporting `NoMatchesFound` means the selector matched nothing.
      If the labels look right, check that the per-zone `MeshService` resources have synced to the
      global control plane, and that you are matching on `kuma.io/display-name` rather than the hashed
      resource name.
{% endtable %}



## Zone eligibility

A matched `MeshService` from another zone is used only while its `spec.state` is `Available`,
which it is when at least one of its endpoints is healthy. That state is what the aggregate
consults when deciding whether a remote zone can take traffic, so a zone whose service has no
healthy endpoints drops out without any change here. The local zone's service is always used,
since it only contributes endpoints that exist.

Reaching another zone also requires a `MeshIdentity` in the mesh and a `MeshZoneAddress` for the
destination zone. Without them, remote services contribute no endpoints. For more information, see
[Mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/#make-ingress-reachable-from-other-zones).

A client also needs the `MeshMultiZoneService` in its `reachableBackends` (the
`kuma.io/reachable-backends` annotation on Kubernetes), or it gets no outbound for it.

How traffic is distributed across the zones that remain is
[`MeshLoadBalancingStrategy`](/mesh/policies/meshloadbalancingstrategy/) decides how traffic is distributed across the remaining zones. Locality awareness prefers the local zone, and `crossZone.failover` sets the order the others are tried in.
[`MeshHealthCheck`](/mesh/policies/meshhealthcheck/) and
[`MeshCircuitBreaker`](/mesh/policies/meshcircuitbreaker/) cover the other case: endpoints that
are present and reachable but answering badly, which nothing else detects.

## Schema

{% json_schema MeshMultiZoneServices %}
