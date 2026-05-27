---
title: "Targeting Workloads and Services"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: How to scope policies in {{site.mesh_product_name}} using Dataplane labels for proxy groups and MeshService for explicit destinations.
products:
  - mesh
tldr:
  q: How should I target groups of proxies and services?
  a: |
    Modern {{site.mesh_product_name}} uses two targeting primitives:
    1. **`Dataplane` with `labels:`** at the top level of a policy, to scope it to a slice of the fleet (a zone, an environment, a team).
    2. **`MeshService`** in `spec.to[].targetRef` and `backendRefs`, to address explicit destinations (including canaries and blue/green variants).
    The older `MeshSubset`, `MeshServiceSubset`, and top-level `MeshService` kinds are deprecated and will be removed in 3.0.
next_steps:
  - text: "Observability in Practice"
    url: "/mesh/scenarios/observability-in-practice/"
---
{{site.mesh_product_name}} has converged on two targeting primitives: a **`Dataplane`** label selector for scoping a policy to a group of proxies, and explicit **`MeshService`** (and `MeshMultiZoneService`, `MeshExternalService`) resources for addressing destinations. The older `MeshSubset` / `MeshServiceSubset` virtual kinds are deprecated; using them at the top level of a policy now emits a deprecation warning.

## Targeting matrix

{% table %}
columns:
  - title: Use case
    key: feature
  - title: Use this at the top level
    key: toplevel
  - title: Use this in `to[].targetRef` / `backendRefs`
    key: tochain
rows:
  - feature: "Scope a policy to a slice of the fleet (zone, environment, team)"
    toplevel: "`Dataplane` with `labels:` (e.g. `kuma.io/zone: us-east-1`)"
    tochain: "Usually `Mesh`"
  - feature: "Apply a policy to every proxy in the mesh"
    toplevel: "`Mesh`"
    tochain: "Specific `MeshService` / `MeshMultiZoneService` / `MeshExternalService`"
  - feature: "Route or split traffic to a named destination"
    toplevel: "`Mesh` (or `Dataplane` to scope which clients see the route)"
    tochain: "`MeshService` (named, e.g. `passenger-portal-v1` vs `passenger-portal-v2`)"
  - feature: "Address a built-in gateway"
    toplevel: "`MeshGateway`"
    tochain: "n/a"
{% endtable %}

{% warning %}
Top-level `targetRef.kind: MeshService`, `MeshServiceSubset`, and `MeshSubset` are deprecated. So is `MeshHTTPRoute` at the top level (use it in `spec.to[].targetRef`). Applying a policy with one of these kinds at the top level emits a deprecation warning and the field will be removed in 3.0.
{% endwarning %}

---

## 1. Dataplane with labels: The "Cross-Cutting" Proxy Policy

Use a top-level `targetRef` of **`Dataplane`** with a `labels:` selector when you want to apply a policy to a group of proxies based on shared environmental traits, rather than their specific service identity. This replaces the older `MeshSubset` / `MeshServiceSubset` top-level kinds, which are deprecated.

### Example: Regional Timeouts
If you want every sidecar in your `us-east-1` region to have a specific timeout (perhaps due to known cross-AZ latency), label the matching workloads and select them with `Dataplane`. This applies to **all** services in that region.

{% navtabs "subset-timeout" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: regional-baseline
  namespace: kong-air-production
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/zone: us-east-1
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 15s' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTimeout
name: regional-baseline
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/zone: us-east-1
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 15s' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

## 2. Explicit MeshService: The "Modern Standard"

In modern {{site.mesh_product_name}} (2.6+), you manage rollout-oriented "subsets" (like Canary vs. Stable) by creating **distinct `MeshService` resources**. This is called **Explicit Subsetting**. On current Kuma builds, the control plane can also generate baseline `MeshService` resources automatically for workloads, especially on Universal. The explicit resources in this section are for the cases where you want named, independently routable destinations.

By naming your subsets explicitly, your routing rules become clear, predictable, and easy to audit. This model moves away from implicit tag-matching and toward a first-class resource management system.

{% tip %}
**Practical Guide**: For a step-by-step tutorial on implementing rollouts using this model, see [Traffic Splitting with MeshServices](/mesh/scenarios/traffic-splitting-meshservices/).
{% endtip %}

---

## Why Use Explicit MeshServices instead of legacy Subsets?

1.  **Deterministic Routing**: The Control Plane resolves named resources directly to a known set of IP addresses, making the mesh more reliable at scale.
2.  **Granular Metrics**: You get separate metrics for `orders-stable` and `orders-canary` automatically. No more filtering logs by tags.
3.  **Kubernetes Native**: This pattern matches how Argo CD, Flagger, and the Gateway API handle traffic splitting, ensuring your automation tools work seamlessly.

---

## Deprecation note: MeshSubset and MeshServiceSubset
{% danger %}
`MeshSubset` and `MeshServiceSubset` are **deprecated**. Both were "virtual kinds" used before explicit `MeshService` resources existed. They still apply for backward compatibility, but the control plane emits a deprecation warning, and the fields will be removed in 3.0. Migrate to `Dataplane` with `labels:` at the top level, and `MeshService` (or `MeshMultiZoneService` / `MeshExternalService`) in `to[].targetRef` / `backendRefs`.
{% enddanger %}
