---
title: Policy targeting and precedence
content_type: reference
layout: reference
description: A guide to the {{site.mesh_product_name}} policy model, explaining how to target proxies with targetRef, define inbound traffic with rules, and manage policy precedence.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - konnect
next_steps:
  - text: "Resource scoping"
    url: "/mesh/resource-scoping/"
related_resources:
  - text: Introduction to policies
    url: /mesh/policies-introduction/
  - text: MeshTrafficPermission
    url: /mesh/policies/meshtrafficpermission/
---
{{site.mesh_product_name}} uses one consistent shape for every policy: you select the proxies to target with `targetRef`, then describe the behavior in the same resource. For the full policy model, see [Introduction to policies](/mesh/policies-introduction/).

This page shows how Kong Air applies that model to workloads running across its zones.

## What Kong Air targets with `targetRef`

At the top level, Kong Air attaches policy to either the whole mesh or a selected group of data plane proxies:

<!-- vale off -->
{% table %}
columns:
  - title: Target kind
    key: kind
  - title: Scope
    key: scope
  - title: Kong Air use case
    key: use_case
rows:
  - kind: "`Mesh`"
    scope: "Every sidecar in the mesh."
    use_case: "Access logging for all of `kong-air-mesh`."
  - kind: "`Dataplane` with `labels`"
    scope: "The proxies whose labels match."
    use_case: "Override timeouts for `kuma.io/zone: zone1`, or allow callers into `app: check-in-api`."
{% endtable %}
<!-- vale on -->

{:.info}
> Mesh-scoped zone proxies are `Dataplane` resources too. Target a zone ingress or zone egress with its computed listener labels, for example `kuma.io/listener-zoneegress: enabled`, when a policy supports that proxy role.

## Select a destination with `to`

The top-level `targetRef` answers **which proxies receive this configuration?** A policy's `to` list answers **which destination does this behavior apply to?**

For example, a `MeshTimeout` can select the `passenger-portal` proxies at the top level, then use `to[].targetRef` to apply a timeout only when those proxies call `check-in-api`. Destination references use first-class resources such as `MeshService`, `MeshMultiZoneService`, and `MeshExternalService`. Check the policy reference before choosing a kind because each policy supports a specific set of destination targets.

Inbound policies such as `MeshTrafficPermission` use `rules` instead. The policy first selects the receiving proxies, then each rule matches properties of the incoming connection, such as the caller's authenticated SPIFFE ID. This is why the first-policy scenario targets `app: check-in-api` and allows the SPIFFE ID presented by `flight-control`.

## MeshTrafficPermission precedence caveat

`MeshTrafficPermission` is the exception to the most-specific-wins rule most other policies follow. It evaluates all matching rules for a request, and if any matched rule produces a `Deny`, the deny wins. Remove permissive `allow-all` policies before building narrower authorization rules. Treat the result as an RBAC-style allow/deny pass rather than a most-specific-wins override.
