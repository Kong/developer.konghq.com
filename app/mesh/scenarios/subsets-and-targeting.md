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
    The older `MeshSubset`, `MeshServiceSubset`, and top-level `MeshService` kinds are legacy targeting shapes. Use `Dataplane` selectors and explicit service resources instead.
next_steps:
  - text: "Observability in Practice"
    url: "/mesh/scenarios/observability-in-practice/"
---
{{site.mesh_product_name}} uses two targeting primitives: a **`Dataplane`** label selector for scoping a policy to a group of proxies, and explicit **`MeshService`** (and `MeshMultiZoneService`, `MeshExternalService`) resources for addressing destinations. The older `MeshSubset` / `MeshServiceSubset` virtual kinds are retained for compatibility, but will be removed in the near future.

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
    toplevel: "`Dataplane` with `labels:` (e.g. `kuma.io/zone: zone1`)"
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
  - feature: "Target mesh-scoped zone proxies"
    toplevel: "`Dataplane` with `labels:` (`kuma.io/listener-zoneingress` / `kuma.io/listener-zoneegress`) and optional `sectionName`"
    tochain: "Usually `Mesh`, `MeshExternalService`, or listener-scoped policy rules depending on the policy"
{% endtable %}


## 1. Dataplane with labels: The "Cross-Cutting" Proxy Policy

Use a top-level `targetRef` of **`Dataplane`** with a `labels:` selector when you want to apply a policy to a group of proxies based on shared environmental traits, rather than their specific service identity. This replaces the older `MeshSubset` / `MeshServiceSubset` top-level kinds.

### Example: Regional Timeouts
If you want every sidecar in your `zone1` zone to have a specific timeout (perhaps due to known cross-zone latency), label the matching workloads and select them with `Dataplane`. This applies to **all** services in that region.

{% navtabs "subset-timeout" %}
{% navtab "Kubernetes (Zone CP)" %}
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
      kuma.io/zone: zone1
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 15s' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Zone CP)" %}
```bash
echo 'type: MeshTimeout
name: regional-baseline
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/zone: zone1
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 15s' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

## 2. Explicit MeshService: The "Standard"

In {{site.mesh_product_name}}, you manage rollout-oriented "subsets" (like Canary vs. Stable) by creating **distinct `MeshService` resources**. This is called **Explicit Subsetting**. The control plane can also generate baseline `MeshService` resources automatically for workloads. The explicit resources in this section are for the cases where you want named, independently routable destinations.

In 2.14, this model becomes cleaner again if you enable:

```yaml
experimental:
  inboundTagsDisabled: true
```

With that setting, generated `MeshService` resources can match workloads by `dataplaneLabels` instead of inbound tags such as `kuma.io/service`.

By naming your subsets explicitly, your routing rules become clear, predictable, and easy to audit. This model moves away from implicit tag-matching and toward a first-class resource management system.

{% tip %}
For a step-by-step tutorial on implementing rollouts using this model, see [Traffic Splitting with MeshServices](/mesh/scenarios/traffic-splitting-meshservices/).
{% endtip %}


## Why Use Explicit MeshServices instead of legacy Subsets?

1.  **Deterministic Routing**: The Control Plane resolves named resources directly to a known set of IP addresses, making the mesh more reliable at scale.
2.  **Granular Metrics**: You get separate metrics for `passenger-portal-v1` and `passenger-portal-v2` automatically. No more filtering logs by tags.
3.  **Kubernetes Native**: This pattern matches how Argo CD, Flagger, and the Gateway API handle traffic splitting, so existing automation tooling works the same way.

## Deprecation note: MeshSubset and MeshServiceSubset
{% danger %}
`MeshSubset` and `MeshServiceSubset` are older "virtual kinds" used before explicit `MeshService` resources existed. These scenarios use `Dataplane` with `labels:` at the top level, and `MeshService` (or `MeshMultiZoneService` / `MeshExternalService`) in `to[].targetRef` / `backendRefs`.
{% enddanger %}
