---
title: Target workloads and services
content_type: how_to
layout: how-to
permalink: /mesh/scenarios/target-workloads-and-services/
description: How to scope policies in {{site.mesh_product_name}} using Dataplane labels for proxy groups and MeshService for explicit destinations.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
tldr:
  q: How should I target groups of proxies and services?
  a: |
    Modern {{site.mesh_product_name}} uses two targeting primitives:
    1. **`Dataplane` with `labels:`** at the top level of a policy, to scope it to a slice of the fleet (a zone, an environment, a team).
    2. **`MeshService`** in `spec.to[].targetRef` and `backendRefs`, to address explicit destinations (including canaries and blue/green variants).
    The older `MeshSubset`, `MeshServiceSubset`, and top-level `MeshService` kinds are legacy targeting shapes. Use `Dataplane` selectors and explicit service resources instead.
prereqs:
  inline:
    - title: Kong Air demo deployment
      content: |
        A running {{site.mesh_product_name}} deployment with the Kong Air demo apps and `meshServices.mode: Exclusive` on the `kong-air-mesh` Mesh. See [Get started with your first policy](/mesh/scenarios/get-started-with-your-first-policy/).
next_steps:
  - text: "Observe mesh traffic in practice"
    url: "/mesh/scenarios/observe-mesh-traffic-in-practice/"
---

{{site.mesh_product_name}} uses two targeting primitives: a **`Dataplane`** label selector for scoping a policy to a group of proxies, and explicit **`MeshService`** (and `MeshMultiZoneService`, `MeshExternalService`) resources for addressing destinations. For the full targeting model and the per-policy `targetRef` support matrices, see [Policies](/mesh/policies-introduction/) and [MeshService](/mesh/meshservice/). This page focuses on how Kong Air applies those primitives.

## Dataplane with labels: the cross-cutting proxy policy

Use a top-level `targetRef` of **`Dataplane`** with a `labels:` selector when you want to apply a policy to a group of proxies based on shared environmental traits, rather than their specific service identity.

### Example: regional timeouts

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

## Explicit MeshService: the standard

In {{site.mesh_product_name}}, you manage rollout-oriented "subsets" (like Canary vs. Stable) by creating **distinct `MeshService` resources**. This is called **explicit subsetting**. The control plane can also generate baseline `MeshService` resources automatically for workloads; the explicit resources in this section are for the cases where you want named, independently routable destinations. For how generated `MeshService` resources match workloads, see [MeshService](/mesh/meshservice/).

By naming your subsets explicitly, your routing rules become clear, predictable, and easy to audit. This model moves away from implicit tag-matching and toward a first-class resource management system.

{:.info}
> For a step-by-step tutorial on implementing rollouts using this model, see [Split traffic with MeshService resources](/mesh/scenarios/split-traffic-with-meshservice-resources/).


## Why use explicit MeshServices instead of legacy subsets?

1.  **Deterministic Routing**: The Control Plane resolves named resources directly to a known set of IP addresses, making the mesh more reliable at scale.
2.  **Granular Metrics**: You get separate metrics for `passenger-portal-v1` and `passenger-portal-v2` automatically. No more filtering logs by tags.
3.  **Kubernetes Native**: This pattern matches how Argo CD, Flagger, and the Gateway API handle traffic splitting, so existing automation tooling works the same way.

## Deprecation note: MeshSubset and MeshServiceSubset

`MeshSubset` and `MeshServiceSubset` are legacy "virtual kinds" that predate explicit `MeshService` resources. Use `Dataplane` with `labels:` at the top level and `MeshService` (or `MeshMultiZoneService` / `MeshExternalService`) in `to[].targetRef` / `backendRefs` instead. See [Policies](/mesh/policies-introduction/) for the deprecation details.
