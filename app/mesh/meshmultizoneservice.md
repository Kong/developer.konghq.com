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
  - text: How policies select traffic
    url: /mesh/policy-targeting/
  - text: MeshService
    url: /mesh/meshservice/
  - text: MeshLoadBalancingStrategy policy
    url: /mesh/policies/meshloadbalancingstrategy/
  - text: Migrate policies to {{site.mesh_product_name}} 3
    url: /mesh/migrate-policies-to-3/
---

`MeshMultiZoneService` gathers the [MeshServices](/mesh/meshservice/) for one service across
zones into a single destination. A client names it instead of a per-zone service, and reaches
whichever zones are available.

It is the destination kind that cross-zone failover attaches to:
`MeshLoadBalancingStrategy`'s `localityAwareness.crossZone` is accepted **only** on a `to` entry
targeting a `MeshMultiZoneService`, because the failover order is a statement about zones and
this is the resource that spans them.

It is not a policy — there is no `targetRef`, the resource is the destination — and it is created
on the **global** control plane only, then synced out to zones.

## Aggregate a service across zones

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
synced `MeshService`'s resource name carries a zone-specific hash while its display name does
not.

Adding `kuma.io/zone` narrows the aggregate to particular zones, which is how a service is
exposed across a subset of them.

## Ports

`spec.ports[]` lists the ports the aggregate exposes, and at least one is required — an empty
list is rejected with `in body should have at least 1 items`. Each takes a `port`, an optional
`name`, and an `appProtocol` that defaults to `tcp`.

The ports are the aggregate's own, drawn from the selected services. They have to line up with
what those services expose for traffic to arrive.

A `MeshMultiZoneService` referenced in a route's `backendRefs` **requires a `port`** on the
reference, unlike a `MeshService`, where it can be inferred. Omitting it is rejected with
`must be defined with kind MeshMultiZoneService`.

## Reading the status

{% table %}
columns:
  - title: Field
    key: field
  - title: Reports
    key: what
rows:
  - field: "`meshServices`"
    what: "Every matched `MeshService`, with its name, namespace, zone and mesh. This is the list to check first when traffic is not reaching a zone."
  - field: "`vips`"
    what: "The virtual IPs assigned to the aggregate."
  - field: "`addresses`"
    what: "The generated hostnames, and which generator produced each."
  - field: "`hostnameGenerators`"
    what: "Per-generator status."
  - field: "`conditions`"
    what: "`MeshServicesMatched`, with a reason of `MatchesFound` or `NoMatchesFound`."
{% endtable %}

A `MeshServicesMatched` condition reporting `NoMatchesFound` means the selector matched nothing.
Where the labels look right, check that the per-zone `MeshService` resources have synced to the
global control plane, and that you are matching on `kuma.io/display-name` rather than the hashed
resource name.

## Which zones receive traffic

A matched `MeshService` is used only while its own `spec.state` is `Available`, which it is when
at least one of its endpoints is healthy. That state is what the aggregate consults when
deciding whether a zone can take traffic, so a zone whose service has no healthy endpoints drops
out without any change here.

How traffic is distributed across the zones that remain is
[MeshLoadBalancingStrategy](/mesh/policies/meshloadbalancingstrategy/)'s job: locality awareness
prefers the local zone, and `crossZone.failover` sets the order the others are tried in.
Deciding which endpoints count as healthy needs a
[MeshHealthCheck](/mesh/policies/meshhealthcheck/) or a
[MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/) — without one there is nothing to
count, and failover never starts.
