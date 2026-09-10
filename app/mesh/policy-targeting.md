---
title: "How {{site.mesh_product_name}} policies select traffic"
description: "Understand the three selectors a policy carries, why outbound names a destination and inbound matches an identity, and which kinds each field accepts."
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - policy
  - service-mesh
  - traffic-control
related_resources:
  - text: MeshTrafficPermission policy
    url: /mesh/policies/meshtrafficpermission/
  - text: MeshIdentity policy
    url: /mesh/policies/meshidentity/
  - text: Apply policies to mesh-scoped zone proxies
    url: /mesh/zone-proxy-policies/
---

A {{site.mesh_product_name}} policy carries up to three selectors. They answer different
questions, and each accepts a different set of kinds.

{% table %}
columns:
  - title: Selector
    key: selector
  - title: Answers
    key: answers
rows:
  - selector: "`spec.targetRef`"
    answers: "Which proxies the policy is installed on."
  - selector: "`spec.to[]`"
    answers: "Which destination the configuration applies to, for traffic those proxies **send**."
  - selector: "`spec.rules[]`"
    answers: "Which client the configuration applies to, for traffic those proxies **receive**."
{% endtable %}

Not every policy has all three. A policy states its own shape on its own page.

## Why outbound names a destination and inbound matches an identity

This is the part that looks inconsistent and is not.

A **destination** is something the proxy chooses to call. Your proxy decides to send a
request to `backend`, so naming that service is both sufficient and natural:
`kind: MeshService`.

A **client** is remote and describes itself. If an inbound rule selected a caller by label or
by service tag, it would be trusting the caller's own claim about what it is — and a workload
can assert any tag. So inbound matches on the SPIFFE ID that
[MeshIdentity](/mesh/policies/meshidentity/) issued and mTLS proves, which the caller cannot
forge.

That is why {{site.mesh_product_name}} 3 removed the `from` array and `MeshServiceSubset`
from [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/): access control decided
on a self-asserted tag was not access control.

## What each field accepts

### `spec.targetRef`

`Mesh` or `Dataplane`. Nothing else.

Use `Mesh` to apply a policy across the mesh, or `Dataplane` with `labels` to narrow it to a
set of proxies. `targetRef.sectionName` narrows further, to one named listener or inbound of
the selected proxy.

{:.warning}
> `MeshSubset`, `MeshService` and `MeshServiceSubset` are rejected here in
> {{site.mesh_product_name}} 3. A policy still using one fails validation, including when a
> Global control plane replicates it to an upgraded Zone, so it can silently stop syncing.

### `spec.to[].targetRef`

A narrower selector than the top level, and the accepted kinds vary by policy:

{% table %}
columns:
  - title: Kind
    key: kind
  - title: Accepted by
    key: accepted
rows:
  - kind: "`Mesh`"
    accepted: "Every policy that has a `to` array."
  - kind: "`MeshService`, `MeshExternalService`, `MeshMultiZoneService`"
    accepted: "Most policies with a `to` array."
  - kind: "`MeshHTTPRoute`"
    accepted: "`MeshAccessLog`, `MeshLoadBalancingStrategy`, `MeshRetry` and `MeshTimeout` only. `MeshCircuitBreaker` rejects it, because circuit breaking applies to a whole destination rather than to one route."
{% endtable %}

`MeshRateLimit` and `MeshFaultInjection` are narrower still: they accept `kind: Mesh` only,
and only when the top-level `targetRef` selects a gateway.

`MeshSubset`, `MeshServiceSubset` and `MeshGateway` are rejected in `to[]` by every policy.
`MeshServiceSubset` survives only as a route's `backendRefs[].kind`.

### `spec.rules[]`

Where a policy supports inbound configuration, each rule may carry `matches`, and a match
selects on one of two fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: Matches on
    key: matches
  - title: "`type`"
    key: type
rows:
  - field: "`spiffeID`"
    matches: "The SPIFFE ID of the calling workload."
    type: "`Exact` or `Prefix`"
  - field: "`sni`"
    matches: "The SNI carried on the TLS connection. Used on zone egress, where the destination is identified by SNI rather than by client identity."
    type: "`Exact` only"
{% endtable %}

A match needs at least one of the two. A `Prefix` on a SPIFFE ID is how a group is addressed:
the ID is structured as `spiffe://<trust-domain>/ns/<namespace>/sa/<service-account>`, so a
prefix ending at the namespace selects every workload in it.

Some policies accept `rules` without `matches`, applying to all inbound traffic. Where that
is the case, the policy page says so.
