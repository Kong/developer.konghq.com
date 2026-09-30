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
  - on-prem
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

A top-level `targetRef` accepts only two kinds, `Mesh` or `Dataplane`. Kong Air uses them to attach policy to either the whole mesh or a selected group of data plane proxies:

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
    scope: "Every proxy in the mesh, including gateways and mesh-scoped zone proxies."
    use_case: "Access logging for all of `kong-air-mesh`."
  - kind: "`Dataplane` with no `labels`"
    scope: "Every proxy in the mesh, the same set that `Mesh` selects."
    use_case: "A mesh-wide default that you want to outrank any `Mesh`-scoped policy."
  - kind: "`Dataplane` with `labels`"
    scope: "The proxies whose labels all match."
    use_case: "Override timeouts for `kuma.io/zone: zone1`, or allow callers into `app: check-in-api`."
  - kind: "`Dataplane` with `labels` and `sectionName`"
    scope: "A single named inbound listener on the matching proxies, rather than the proxy as a whole."
    use_case: "Authorize traffic on one port of a zone egress."
{% endtable %}
<!-- vale on -->

{:.info}
> Mesh-scoped zone proxies are `Dataplane` resources, so `Mesh` and an unlabelled `Dataplane` both select them. To target a zone ingress or zone egress on its own, match its computed listener label, `kuma.io/listener-zoneingress: enabled` or `kuma.io/listener-zoneegress: enabled`, and check that the policy supports that proxy role.

### Zone and namespace limits on selection

Matching labels is not sufficient on its own. Two further conditions decide whether a policy reaches a proxy:

* **Zone**: a policy created in a zone selects only proxies in that same zone. A policy created on the global control plane reaches every zone.
* **Namespace**: a policy whose computed `kuma.io/policy-role` is `consumer` or `workload-owner` selects only proxies in the policy's own namespace. `system` and `producer` policies are not restricted this way. See [Policy precedence and merging](#policy-precedence-and-merging) for how the role is derived.

## Select a destination with `to`, match traffic with `rules`

The top-level `targetRef` answers **which proxies receive this configuration?** From there, a policy describes behavior in one of two directions:

* `to[]` configures outbound traffic and answers **which destination does this behavior apply to?** For example, a `MeshTimeout` can select the `passenger-portal` proxies at the top level, then use `to[].targetRef` to apply a timeout only when those proxies call `check-in-api`. Destination references are first-class resources: `Mesh`, `MeshService`, `MeshMultiZoneService`, `MeshExternalService`, and `MeshHTTPRoute`.
* `rules[]` configures inbound traffic. The policy selects the receiving proxies, then each rule matches properties of the incoming connection, such as the caller's authenticated SPIFFE ID. This is why the first-policy scenario targets `app: check-in-api` and allows the SPIFFE ID presented by `flight-control`.

The split is direction, not policy type, and many policies support both. `MeshTimeout`, `MeshCircuitBreaker`, `MeshAccessLog`, `MeshRateLimit`, and `MeshFaultInjection` carry `to` and `rules`. `MeshTLS` and `MeshTrafficPermission` are inbound only, so they carry `rules` alone. Check the policy reference before choosing a kind, because each policy supports its own set of destination targets.

## Policy precedence and merging

When several policies select the same proxy, {{site.mesh_product_name}} sorts them from lowest to highest priority, then merges their configuration with an [RFC 7396 JSON merge patch](https://www.rfc-editor.org/rfc/rfc7396). Later entries overwrite earlier ones field by field, so the highest-priority policy wins on every field it sets, and any field it leaves unset falls through from the policies underneath it.

Sorting applies each attribute in turn, using the next attribute only to break a tie:

<!-- vale off -->
{% table %}
columns:
  - title: Order
    key: order
  - title: Attribute
    key: attribute
  - title: Lowest to highest priority
    key: priority
rows:
  - order: "1"
    attribute: "Top-level `targetRef` kind"
    priority: "`Mesh`, then `Dataplane`"
  - order: "2"
    attribute: "`sectionName` on a `Dataplane` target"
    priority: "No `sectionName`, then `sectionName` set"
  - order: "3"
    attribute: "Origin, from the `kuma.io/origin` label"
    priority: "`global`, then `zone`"
  - order: "4"
    attribute: "Policy role, from the `kuma.io/policy-role` label"
    priority: "`system`, then `producer`, then `consumer`, then `workload-owner`"
  - order: "5"
    attribute: "Display name, from the `kuma.io/display-name` label"
    priority: "Inverted lexicographical order, so `zzz-timeouts` has lower priority than `aaa-timeouts`"
{% endtable %}
<!-- vale on -->

Labels do not affect the sort. A `Dataplane` target with `labels` and one without carry the same priority, and the tie is broken by origin, role, and display name.

The control plane computes `kuma.io/policy-role` from where the policy lives and whether it has `to` entries:

* `system`: a policy on the global control plane or in the zone's system namespace.
* `producer`: a policy in the same namespace as the service named by its `to[].targetRef`.
* `consumer`: a policy in another namespace that has `to[]` entries.
* `workload-owner`: a policy in a non-system namespace with no `to[]` entries.

For policies that use `to`, the concatenated `to[]` entries of all matching policies are sorted again by destination kind, from `Mesh` through `MeshService`, `MeshService` with `sectionName`, `MeshExternalService`, `MeshMultiZoneService`, and `MeshHTTPRoute`, before the same merge runs.

## MeshTrafficPermission precedence caveat

`MeshTrafficPermission` is the exception to the merge described in [Policy precedence and merging](#policy-precedence-and-merging). Its rules are not merged into one winning configuration. Every matching rule is evaluated for a request, and if any matched rule produces a `Deny`, the deny wins, because the control plane emits all deny matchers ahead of all allow matchers and the proxy stops at the first match. A connection that matches no rule at all is denied.

Remove permissive `allow-all` policies before building narrower authorization rules. A narrower `allow` does not override a broader one; only a `deny` does. Treat the result as an RBAC-style allow/deny pass rather than a most-specific-wins override.

{:.warning}
> `MeshTrafficPermission` takes effect only on proxies that hold a workload identity and terminate mTLS. If no `MeshIdentity` issues an identity to the proxy, or the inbound listener is not a TLS filter chain, the policy is skipped and traffic is not restricted. Apply `MeshIdentity` and `MeshTLS` first. See [Manage workload identity and mTLS](/mesh/manage-workload-identity-and-mtls/).
