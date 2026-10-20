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
  - text: Mesh-scoped zone proxies
    url: /mesh/mesh-scoped-zone-proxies/
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

## Where a policy applies

On Kubernetes, the namespace a policy is created in restricts which proxies it can reach.
`targetRef` narrows within that reach; it cannot widen it. The control plane works out the
reach from the policy's shape and records it in the `kuma.io/policy-role` label, which it
computes on every write. Leave the label out: a value that differs from the computed one is
rejected.

{% table %}
columns:
  - title: Policy
    key: policy
  - title: "`kuma.io/policy-role`"
    key: role
  - title: Reaches
    key: reach
rows:
  - policy: "Created on the **global** control plane"
    role: "`system`"
    reach: "Every proxy in the mesh, in every zone."
  - policy: "Created in the system namespace, `{{site.mesh_namespace}}`, of a zone control plane"
    role: "`system`"
    reach: "Every proxy in **that zone**. It is not distributed to other zones."
  - policy: "Created in an application namespace, every `to[]` item a `MeshService` or `MeshHTTPRoute` selected by exactly three labels: `kuma.io/display-name`, `k8s.kuma.io/namespace` set to the policy's own namespace, and `kuma.io/zone` set to the local zone"
    role: "`producer`"
    reach: "Every client of that destination, in any namespace and any zone."
  - policy: "Created in an application namespace, with `to[]` items that are not all of that form"
    role: "`consumer`"
    reach: "Only proxies in the policy's own namespace."
  - policy: "Created in an application namespace, with no `to[]` at all"
    role: "`workload-owner`"
    reach: "Only proxies in the policy's own namespace."
{% endtable %}

A policy cannot mix producer and consumer items. One that names a single destination in one
`to[]` item and something broader in another is rejected on admission.

{:.warning}
> `targetRef.kind: Mesh` does not mean "the whole mesh" on its own. In a `consumer` or
> `workload-owner` policy it means every proxy in that policy's namespace. Creating it in
> `{{site.mesh_namespace}}` widens it to the whole **zone**, not the whole mesh: a policy
> created on a zone control plane stays in that zone. Only the global control plane, or a
> producer policy, reaches every zone.

A selector with only `kuma.io/display-name`, or with any extra label, makes the item a
consumer item.

A zone control plane sets the `kuma.io/origin: zone` label on the policies created there. You
don't need to set it, and if you do, any value other than `zone` is rejected.

Universal has no namespaces, so every policy there is `system`. A policy created on the global
control plane reaches every zone, and one created on a zone control plane reaches only that
zone.

## Policy precedence

When several policies of the same type apply to the same traffic, the control plane merges
them in order of priority. A higher-priority policy overrides the fields it sets, and inherits
the fields it leaves out. The following criteria decide the order, from lowest to highest
priority, and each one applies only when the previous ones tie:

1. Top-level `targetRef.kind`: `Mesh`, then `Dataplane`. An omitted `targetRef` counts as
   `Mesh`.
1. A `Dataplane` `targetRef` with `sectionName` ranks above one without.
1. Origin: created on the global control plane, then created on a zone control plane.
1. Role: `system`, then `producer`, `consumer`, and `workload-owner`.
1. For outbound configuration, the `to[].targetRef.kind`: `Mesh`, then a destination kind
   (a `MeshService` with `sectionName` ranks above one without), then `MeshHTTPRoute`.
1. Name: the policy whose name comes first alphabetically has the highest priority.

## Why outbound names a destination and inbound matches an identity

A **destination** is something the proxy chooses to call. Your proxy decides to send a
request to `backend`, so naming that service is both sufficient and natural:
`kind: MeshService`.

A **client** is remote and describes itself. If an inbound rule selected a caller by label or
by service tag, it would be trusting the caller's own claim about what it is, and a workload
can assert any tag. So inbound matches on the SPIFFE ID that
[MeshIdentity](/mesh/policies/meshidentity/) issued and mTLS proves, which the caller cannot
forge.

For this reason, {{site.mesh_product_name}} 3.x removes the `from` array, and with it client
selection by `MeshServiceSubset`, from every policy: those selectors matched an inbound client
on tags the client set itself. Inbound policies such as
[MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) match clients in `rules` instead.

## What each field accepts

### `spec.targetRef`

`Mesh` or `Dataplane`. Nothing else.

Use `Mesh` to apply a policy across the mesh, or `Dataplane` with `labels` to narrow it to a
set of proxies. `targetRef.sectionName` narrows further, to one named listener or inbound of
the selected proxy.

{:.warning}
> `MeshSubset`, `MeshService` and `MeshServiceSubset` are rejected here in
> {{site.mesh_product_name}} 3.x. A policy still using one fails validation, including when a
> global control plane replicates it to an upgraded zone, so it can silently stop syncing.

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
    accepted: "Every policy that has a `to` array, except `MeshHTTPRoute` and `MeshTCPRoute`, which must name a destination."
  - kind: "`MeshService`, `MeshExternalService`, `MeshMultiZoneService`"
    accepted: "Most policies with a `to` array."
  - kind: "`MeshHTTPRoute`"
    accepted: "`MeshAccessLog`, `MeshLoadBalancingStrategy`, `MeshRetry` and `MeshTimeout` only. `MeshCircuitBreaker` rejects it, because circuit breaking applies to a whole destination rather than to one route."
{% endtable %}

`MeshRateLimit` and `MeshFaultInjection` are narrower still: they accept `kind: Mesh` only,
and only when the top-level `targetRef` is `kind: Mesh` or omitted. With `kind: Dataplane`,
`to` must be empty.

`MeshSubset` and `MeshServiceSubset` are rejected in `to[]` by every policy, and
`MeshServiceSubset` is also rejected in a route's `backendRefs[]`.

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
