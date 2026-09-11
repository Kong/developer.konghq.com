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
  - text: How policies select traffic
    url: /mesh/policy-targeting/
  - text: MeshMultiZoneService
    url: /mesh/meshmultizoneservice/
  - text: MeshExternalService
    url: /mesh/meshexternalservice/
  - text: Migrate policies to {{site.mesh_product_name}} 3
    url: /mesh/migrate-policies-to-3/
---

`MeshService` represents one service in the mesh: which proxies back it, which ports it exposes,
and which identities it presents. It is the resource a policy names as a destination, in
`spec.to[].targetRef` and in a route's `backendRefs`.

It is not a policy. There is no `targetRef` — a `MeshService` *is* the target — and on Kubernetes
you do not write one at all.

## Where MeshServices come from

On Kubernetes the control plane generates a `MeshService` from each `Service`, and the resource
is read-only. Writing one is rejected with
`Mesh Service is read only on this control plane and cannot be created or updated`. Change the
`Service` instead; the ports and protocols follow from it.

On Universal you author them, selecting proxies with `spec.selector`.

Either way, reading a `MeshService` is how you find out what a policy will resolve to. Its
`status` reports the VIP, the hostnames, how many proxies are backing it and whether mTLS is
ready.

## Selecting the proxies behind a service

`spec.selector` takes exactly one of two forms, and setting both is rejected with
`must specify only one of: dataplaneRef or dataplaneLabels`:

{% table %}
columns:
  - title: Selector
    key: selector
  - title: Selects
    key: what
rows:
  - selector: "`dataplaneLabels`"
    what: "Every proxy whose labels match, through `matchLabels`."
  - selector: "`dataplaneRef.name`"
    what: "One named `Dataplane`."
{% endtable %}

{:.warning}
> `spec.selector.dataplaneTags` was removed in 3.0. A `MeshService` carrying only that selector
> is read back with an **empty selector and matches no proxies**, which makes the service
> unavailable rather than producing an error. The control plane reports it as a deprecation:
> `has no selector, so it matches no data plane proxies`. Migrate those to `dataplaneLabels`.

## Ports

`spec.ports[]` lists what the service exposes. Each entry takes a `port`, an optional `name`, an
optional `targetPort`, and an `appProtocol` that defaults to `tcp`.

`appProtocol` accepts `tcp`, `http`, `http2` and `grpc`; anything else is rejected. It decides
more than it looks like it does:

- An HTTP-based protocol is what makes [MeshHTTPRoute](/mesh/policies/meshhttproute/) apply to
  the port, and what makes it take precedence over
  [MeshTCPRoute](/mesh/policies/meshtcproute/).
- It gates the L7 filters on the port, so `tcp` means no HTTP access log fields, no
  `MeshTimeout` HTTP timeouts, and no `MeshFaultInjection`.

A port's `name` is what a policy's `sectionName` refers to, so naming ports is what lets a
policy apply to one port of a service rather than all of them.

## Identities

`spec.identities[]` publishes the SPIFFE IDs that proxies backing this service present, which is
how a client knows what to expect from the destination. Each entry has a `type` of `SpiffeID`
and the ID as its `value`.

Every [MeshIdentity](/mesh/policies/meshidentity/) matching those proxies contributes its ID, so
during a trust domain migration the list carries both and peers accept either.

{:.warning}
> `type: ServiceTag` is no longer accepted. A persisted `ServiceTag` entry is rejected once the
> updated schema is in place. Service-tag-based naming now falls back to the `kuma.io/service`
> label or the resource name instead.

## Reading the status

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
    what: "Per-generator status, for diagnosing a hostname that was not produced."
{% endtable %}

`spec.state` is `Available` when at least one endpoint is healthy and `Unavailable` otherwise.
It matters beyond this resource: a [MeshMultiZoneService](/mesh/meshmultizoneservice/)
aggregating this service uses the state to decide whether to send cross-zone traffic to it.

`dataplaneProxies` is the first thing to read when a destination is not receiving traffic. A
`total` of 0 means the selector matches nothing; a `healthy` of 0 with a non-zero `total` means
the proxies are there and failing their health checks.

### Why TLS status has a Pending state

`tls.status: Pending` means every proxy backing the service has a certificate, but its clients
have not been told to originate mTLS yet.

A proxy gets its identity independently of its destination's. Flipping clients to mTLS in the
same pass that certifies the destination would drop every request sent before the destination's
inbound TLS chain arrived, so the status holds at `Pending` for one interval to give the
destination that time. The next pass promotes it to `Ready`.

A status stuck at `Pending` across many intervals is therefore not the handover in progress —
look at whether the destination's proxies are actually being issued certificates by a
[MeshIdentity](/mesh/policies/meshidentity/).

## Naming

A `MeshService`'s name has to be an RFC 1035 label: lower-case letters, digits and dashes, starting with a letter. This is stricter than it was, because the name appears in generated hostnames and
SNI values.
