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
    url: "/mesh/scenarios/resource-scoping/"
related_resources:
  - text: Introduction to policies
    url: /mesh/policies-introduction/
  - text: MeshTrafficPermission
    url: /mesh/policies/meshtrafficpermission/
---
{{site.mesh_product_name}} uses one consistent shape for every policy: you select the proxies to affect with `targetRef`, then describe the behavior in the same resource. For the full policy model, how `targetRef`, `to[]`, `rules[]`, and `default` work, how precedence resolves, and which older shapes are deprecated, see [Introduction to policies](/mesh/policies-introduction/), the source of truth for the model. This page shows how Kong Air applies that model to its own workloads.

## What Kong Air targets with `targetRef`

At the top level, Kong Air attaches its policies to one of these:

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
    use_case: "Baseline mTLS and access logging for all of `kong-air-mesh`."
  - kind: "`Dataplane` with `labels:`"
    scope: "The proxies whose labels match."
    use_case: "Override timeouts for `kuma.io/zone: zone1`, or allow callers into `app: check-in-api`."
  - kind: "`MeshGateway`"
    scope: "A built-in mesh gateway."
    use_case: "Policies that apply to a gateway Kong Air runs inside the mesh."
{% endtable %}
<!-- vale on -->

{:.info}
> Zone proxies are targetable too (2.14). You can attach `MeshTrafficPermission`, `MeshTimeout`, `MeshRateLimit`, `MeshFaultInjection`, `MeshCircuitBreaker`, `MeshHealthCheck`, `MeshMetric`, `MeshTrace`, and `MeshAccessLog` directly to zone ingress or zone egress with `targetRef.kind: Dataplane` plus the computed listener labels (for example `kuma.io/listener-zoneegress: enabled`).

## MeshTrafficPermission precedence caveat

Most policies follow most-specific-wins, but `MeshTrafficPermission` does not.

{:.warning}
> `MeshTrafficPermission` evaluates all matching rules for a request, and if any matched rule produces a `Deny`, the deny wins. To enforce a default-deny posture cleanly, delete the permissive `allow-all` policy first, then layer narrower allows on top. Treat it as an RBAC-style allow/deny pass rather than a most-specific-wins override.
