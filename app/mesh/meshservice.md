---
title: MeshService
description: The resource that represents a service in the mesh, and the destination policies and routes point at.
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
  - text: MeshMultiZoneService
    url: /mesh/meshmultizoneservice/
  - text: MeshExternalService
    url: /mesh/meshexternalservice/
  - text: Migrate policies to {{site.mesh_product_name}} 3.x
    url: /mesh/migrate-policies-to-3/
  - text: "Concepts: Service model"
    url: /mesh/concepts/#service-model
min_version:
  mesh: '3.0'
---

`MeshService` represents one service in the mesh. It includes:

* Which proxies back it
* Which ports it exposes
* Which identities it presents

It's the resource a policy names as a destination, in
`spec.to[].targetRef` and in a route's `backendRefs`.

A client proxy reaches a `MeshService` only if it lists it in `reachableBackends` (the
`kuma.io/reachable-backends` annotation on Kubernetes). A proxy without `reachableBackends` gets
no outbounds at all.

## MeshService sources

On Kubernetes the control plane generates a `MeshService` from each `Service`. Change the
`Service` instead of the generated resource; the ports and protocols follow from it.

`MeshService` is read-only on the global control plane, since zones are what produce it.

{:.warning}
> A zone control plane accepts a hand-written `MeshService`, and it
> accepts edits to a generated one. The change is stored and is not reconciled back from
> the `Service`. Editing a generated `MeshService` therefore breaks routing to that service
> until you undo it. For example, changing a port makes every request to the service fail, and
> the change persists. Treat these as control-plane output and leave them alone.

On Universal the zone control plane generates a `MeshService` for each distinct
`kuma.io/workload` label value on a `Dataplane`, with a port per inbound. For more information, see
[Control plane automation](/mesh/universal/#control-plane-automation).
You should only create one manually if you turn generation off.

## Selecting the proxies behind a service

`spec.selector` takes exactly one of two forms:

* `dataplaneLabels`: Selects every proxy whose labels match, through `matchLabels`
* `dataplaneRef.name`: Selects one named `Dataplane`.

## Ports

`spec.ports[]` lists what the service exposes. Each entry takes a `port`, an optional `name`, an
optional `targetPort`, and an `appProtocol` that defaults to `tcp`.

`appProtocol` accepts `tcp`, `http`, `http2` and `grpc`. An HTTP-based protocol makes [MeshHTTPRoute](/mesh/policies/meshhttproute/) apply to the port, and makes it take precedence over [MeshTCPRoute](/mesh/policies/meshtcproute/).
`appProtocol` also gates the L7 filters on the port. `tcp` gets no HTTP access log fields, no `MeshTimeout` HTTP timeouts, and no `MeshFaultInjection`.

A port's `name` is what a policy's `sectionName` refers to, so naming ports lets a
policy apply to one port of a service rather than all of them.

## Identities

`spec.identities[]` publishes the SPIFFE IDs that proxies backing this service present, which is
how a client knows what to expect from the destination. Each entry has a `type` of `SpiffeID`
and the ID as its `value`.

Every [MeshIdentity](/mesh/policies/meshidentity/) matching those proxies contributes its ID, so
during a trust domain migration the list carries both and peers accept either.

## Reading the status

The control plane reports what it computes for a `MeshService` in the resource's `status`. The following table describes its
fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: Reports
    key: what
rows:
  - field: "`addresses`"
    what: "The hostnames generated for the service, and which generator produced each."
  - field: "`vips`"
    what: "The virtual IP assigned to the service."
  - field: "`tls.status`"
    what: "`Ready`, `NotReady` or `Pending`."
  - field: "`dataplaneProxies`"
    what: "`total`, `connected` and `healthy` counts for the proxies the selector matched."
  - field: "`hostnameGenerators`"
    what: "Per-generator status, for diagnosing a hostname that wasn't produced."
{% endtable %}

`spec.state` is `Available` when at least one endpoint is healthy and `Unavailable` otherwise.
A [MeshMultiZoneService](/mesh/meshmultizoneservice/)
aggregating this service uses the state to decide whether to send cross-zone traffic to it.

`dataplaneProxies` is the first thing to read when a destination isn't receiving traffic. A
`total` of 0 means the selector matches nothing; a `healthy` of 0 with a non-zero `total` means
the proxies are there and failing their health checks.

### Pending TLS status

`tls.status: Pending` means every proxy backing the service has a certificate, but its clients
haven't been told to originate mTLS yet.

A proxy gets its identity independently of its destination's. Flipping clients to mTLS in the
same pass that certifies the destination would drop every request sent before the destination's
inbound TLS chain arrived, so the status holds at `Pending` for one interval to give the
destination that time. The next pass promotes it to `Ready`.

A status stuck at `Pending` across many intervals is therefore not the handover in progress:
look at whether a [MeshIdentity](/mesh/policies/meshidentity/) is actually issuing certificates
to the destination's proxies.

## Schema

{% json_schema MeshServices %}