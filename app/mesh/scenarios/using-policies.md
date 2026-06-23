---
title: How to use policies
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: A guide to the {{site.mesh_product_name}} policy model, explaining how to target proxies with targetRef, define inbound traffic with rules, and manage policy precedence.
products:
  - mesh
tldr:
  q: How do I write policies in {{site.mesh_product_name}}?
  a: |
    Every policy has the same two parts:
    1. **`targetRef`** selects which proxies the policy attaches to.
    2. **`rules[]`** (inbound), **`to[]`** (outbound), or a direct **`default`** block describes the behavior.

    Use `rules[]` for new inbound policies. The older `from[]` block still parses but is deprecated.
next_steps:
  - text: "Resource Scoping: Where to Apply Policies"
    url: "/mesh/scenarios/resource-scoping/"
---
In many service meshes, managing traffic means juggling several overlapping resources: `VirtualService`, `DestinationRule`, `ServiceEntry`, `Gateway`. {{site.mesh_product_name}} uses one consistent shape for every policy instead. You select the proxies you want to affect, then describe the behavior in the same resource.

## How every policy is structured

Whatever the policy does, mTLS, routing, rate limiting, timeouts, it has the same two parts:

1. **`targetRef`** (top level): which proxies the policy attaches to.
2. A behavior block, one of:
   - **`rules[]`** for inbound traffic (matched by the caller's SPIFFE identity).
   - **`to[]`** for outbound traffic (toward a destination).
   - a direct **`default`** block for policies that configure the proxy itself (metrics, tracing).

`targetRef` is the pattern established by the **Kubernetes Gateway API**. {{site.mesh_product_name}} adopts it so mesh policies feel familiar if you already manage ingress with Gateway resources, and so you target a proxy once instead of repeating label selectors in every policy.

## What to target with `targetRef`

At the **top level**, attach policies to one of these:

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

`MeshService`, `MeshMultiZoneService`, and `MeshExternalService` are **destinations**, not attachment points. They belong inside `to[].targetRef` and `backendRefs`, not at the top level.

{% tip %}
**Zone proxies are targetable too (2.14).** You can attach `MeshTrafficPermission`, `MeshTimeout`, `MeshRateLimit`, `MeshFaultInjection`, `MeshCircuitBreaker`, `MeshHealthCheck`, `MeshMetric`, `MeshTrace`, and `MeshAccessLog` directly to zone ingress or zone egress with `targetRef.kind: Dataplane` plus the computed listener labels (for example `kuma.io/listener-zoneegress: enabled`).
{% endtip %}

## Inbound traffic: use `rules[]`

`rules[]` describes traffic **entering** a proxy, matched by the caller's SPIFFE identity. Each rule has an optional `matches` block and a `default` block with the configuration. Every workload is issued an identity by `MeshIdentity` of the form `spiffe://<trust-domain>/ns/<namespace>/sa/<service-account>`, and that identity is what the receiving proxy sees.

This `MeshTrafficPermission` allows only `flight-control` to reach `check-in-api`:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: only-flight-control-to-check-in
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: check-in-api
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: <flight-control-spiffe-id>
```

Replace `<flight-control-spiffe-id>` with the SPIFFE ID emitted by your `MeshIdentity` template (for example `spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/flight-control`). `spiffeID.type` supports `Exact` and `Prefix`. See [Workload Identity & Trust](/mesh/scenarios/workload-identity/) for how identities are issued.

The same `rules[]` shape is used by every inbound policy: `MeshTrafficPermission`, `MeshTLS`, `MeshFaultInjection`, `MeshAccessLog`, `MeshRateLimit`, `MeshCircuitBreaker`, and `MeshTimeout`.

## Outbound and direct policies

- **Outbound (`to[]`)** affects traffic a proxy sends toward a destination. The destination goes in `to[].targetRef` (`MeshService`, `MeshExternalService`, `MeshMultiZoneService`) or `backendRefs`. Used by `MeshHTTPRoute`, `MeshRetry`, `MeshCircuitBreaker`, `MeshTimeout`, and others.
- **Direct (`default`)** configures the proxy itself, with no source or destination to match. Used by `MeshMetric`, `MeshTrace`, `MeshPassthrough`.

## What is current and what is deprecated

The policy model is stable. A few older shapes still parse but emit a deprecation warning on apply, and you should avoid them in new policies.

{% table %}
columns:
  - title: Use this
    key: current
  - title: Instead of (deprecated)
    key: old
rows:
  - current: "`rules[]` for inbound traffic"
    old: "`from[]` (deprecated on every inbound policy; will be removed in 3.0)"
  - current: "Top-level `targetRef.kind: Dataplane` with `labels:`"
    old: "Top-level `targetRef.kind:` `MeshService`, `MeshServiceSubset`, or `MeshSubset`"
  - current: "`MeshHTTPRoute` inside `to[].targetRef`"
    old: "Top-level `targetRef.kind: MeshHTTPRoute`"
{% endtable %}

{% tip %}
`targetRef` and `to[]` are **not** going anywhere, they are the model. Only the older inbound shape (`from[]`) and a few top-level target kinds are deprecated. If you target proxies with `Mesh` / `Dataplane` and express inbound traffic with `rules[]`, you are on the supported path.
{% endtip %}

## Policy precedence

{{site.mesh_product_name}} follows a **most-specific-wins** approach. A policy targeting a `Dataplane` with labels overrides a `Mesh` level policy for the proxies it matches. Within `rules[]`, a more specific `Exact` SPIFFE match wins over a `Prefix` match.

{% warning %}
`MeshTrafficPermission` is the exception. it evaluates **all** matching MTP rules for a request, and if any matched rule produces a `Deny`, the deny wins. Use most-specific-wins for the other inbound policies, but treat MTP as an RBAC-style allow/deny pass.
{% endwarning %}

## Best practice: start broad, then narrow

Define a `Mesh`-level policy for baseline behavior (mTLS, default timeouts, broad permissions), then add `Dataplane`-with-labels overrides only where a specific workload or zone needs them. This keeps configuration easy to read and audit.
