---
title: Policy targeting and precedence
content_type: reference
layout: reference
description: How the Kong Air scenarios select proxies with targetRef, choose traffic with to and rules, and decide which policy wins when several apply.
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
next_steps:
  - text: "Reference: Resource scoping"
    url: "/mesh/resource-scoping/"
related_resources:
  - text: Policy targeting reference
    url: /mesh/policy-targeting/
  - text: MeshTrafficPermission
    url: /mesh/policies/meshtrafficpermission/
---

A {{site.mesh_product_name}} policy has the same shape whatever it configures.
A selector picks the proxies that receive the policy, and the rest of the policy describes the behavior.
This page shows how the Kong Air scenarios use that shape.
For the complete rules, see [Policy targeting](/mesh/policy-targeting/).

## How Kong Air selects proxies with `targetRef`

Every policy has a `spec.targetRef` field.
It selects the proxies that receive the policy.
This field is the top-level selector, because it sits directly under `spec`.
Some policies also have a `targetRef` inside each `spec.to[]` entry, which selects a destination instead of a proxy.

The top-level `targetRef` accepts two kinds, `Mesh` and `Dataplane`.
The Kong Air scenarios use them in the following ways:

<!-- vale off -->
{% table %}
columns:
  - title: Top-level `targetRef`
    key: kind
  - title: Selected proxies
    key: scope
  - title: Kong Air example
    key: use_case
rows:
  - kind: "`kind: Mesh`"
    scope: "Every proxy the policy can reach, including gateways and zone proxies."
    use_case: "Access logging for all of `kong-air-mesh`."
  - kind: "`kind: Dataplane` without `labels`"
    scope: "The same proxies as `kind: Mesh`, with a higher priority."
    use_case: "A default that wins over a `kind: Mesh` policy of the same type."
  - kind: "`kind: Dataplane` with `labels`"
    scope: "The proxies that have all the listed labels."
    use_case: "A longer timeout for proxies labeled `kuma.io/zone: zone1`, or permissions for proxies labeled `app: check-in-api`."
  - kind: "`kind: Dataplane` with `labels` and `sectionName`"
    scope: "One named listener on the matching proxies."
    use_case: "Permissions for one port of a zone egress."
{% endtable %}
<!-- vale on -->

The namespace and the control plane where you create a policy limit which proxies it can reach.
For example, a policy that you create on a zone control plane reaches only that zone, unless the control plane classifies it as a producer policy.
For the full scope rules, see [Policy scope](/mesh/policy-targeting/#policy-scope).

### Select zone proxies with their listener labels

Zone ingresses and zone egresses are `Dataplane` resources, so a `kind: Mesh` policy also applies to them.
To select only zone proxies, use the labels that the control plane adds to them.
When a `Dataplane` has a zone ingress listener, the control plane sets `kuma.io/listener-zoneingress: enabled` on it.
When a `Dataplane` has a zone egress listener, the control plane sets `kuma.io/listener-zoneegress: enabled`.

The following `targetRef` selects every zone egress that the policy can reach:

```yaml
targetRef:
  kind: Dataplane
  labels:
    kuma.io/listener-zoneegress: enabled
```
{:.no-copy-code}

Not every policy supports zone proxies.
Before you target one, check the policy's reference page.
For an example, see [Proxy and traffic selection](/mesh/mesh-scoped-zone-proxies/#proxy-and-traffic-selection).

## How Kong Air chooses traffic with `to` and `rules`

After `targetRef` selects the proxies, the policy chooses the traffic it applies to:

* `spec.to[]` applies to traffic that the selected proxies send. Each entry names a destination, such as a `MeshService`. For example, a `MeshTimeout` selects the `passenger-portal` proxies and sets a timeout only for their calls to `check-in-api`.
* `spec.rules[]` applies to traffic that the selected proxies receive. Each rule matches the caller, such as its SPIFFE ID. For example, [Create a security policy](/mesh/create-a-security-policy/) selects the `check-in-api` proxies and allows the SPIFFE ID of `flight-control`.

Some policies support both fields, and some support only one.
For example, `MeshTrafficPermission` and `MeshTLS` support only `rules`.
Each [policy reference page](/mesh/policies/) lists the fields and the destination kinds it accepts.

## Which policy wins

Several policies of the same type can select the same proxy.
In that case, the control plane sorts them by priority and merges them.
A higher-priority policy overrides the fields it sets and keeps the other fields from lower-priority policies.
For the order, see [Policy precedence](/mesh/policy-targeting/#policy-precedence).

`MeshTrafficPermission` doesn't merge this way.
The destination proxy evaluates every `deny` before any `allow`, so a narrower `allow` can't override a `deny`.
A caller that no permission allows is denied.
For the details, see [Overlapping permissions](/mesh/policies/meshtrafficpermission/#overlapping-permissions).

{:.warning}
> `MeshTrafficPermission` has no effect on a proxy without a workload identity.
> Apply a `MeshIdentity` before you rely on permissions.
> See [Create a security policy](/mesh/create-a-security-policy/).
