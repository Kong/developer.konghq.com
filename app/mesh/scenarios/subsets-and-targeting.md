---
title: "Understanding MeshSubsets vs. Explicit MeshServices"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: A technical deep dive into the two ways of managing groups of endpoints in {{site.mesh_product_name}} and why explicit resources are now the standard.
products:
  - mesh
tldr:
  q: Should I use MeshSubsets or MeshServices for routing?
  a: |
    Understand the two targeting models in Kong Mesh:
    1. **MeshServices** are explicit, first-class resources representing stable endpoint groups. **(Recommended)**
    2. **MeshSubsets** are implicit groups defined by labels on your workloads.
    3. **Migration** from subsets to services enables more robust routing and automatic DNS management.
next_steps:
  - text: "Observability in Practice"
    url: "/mesh/scenarios/observability-in-practice/"
---
{{site.mesh_product_name}} offers two ways to target data plane proxies: **`MeshSubsets`** (implicit, tag-based groups) and **`MeshServices`** (explicit, resource-based endpoints). 

While the best practice is to use explicit **`MeshService`** resources for routing, understanding the distinction is critical for policy management.

## Targeting matrix

{% table %}
columns:
  - title: Feature
    key: feature
  - title: "`MeshSubset`"
    key: subset
  - title: "`MeshService` (Recommended)"
    key: service
rows:
  - feature: Logic
    subset: Implicit (Tag-based)
    service: Explicit (Resource-based)
  - feature: Usage in `targetRef`
    subset: "**Proxy Targeting** (Receivers)"
    service: "**Proxy & Destination Targeting**"
  - feature: Usage in `backendRef`
    subset: Not supported
    service: Supported (Primary destination)
  - feature: Best for
    subset: "Cross-cutting policies (e.g., Regional Latency at Kong Air)"
    service: "Canary, Blue/Green (e.g., Kong Air Booking V2)"
{% endtable %}

---

## 1. MeshSubset: The "Cross-Cutting" Proxy Policy

Use `MeshSubset` when you want to apply a policy to a group of proxies based on shared environmental traits, rather than their specific service identity.

### Example: Regional Timeouts
If you want every sidecar in your `us-east-1` region to have a specific timeout (perhaps due to known cross-AZ latency), you use `MeshSubset`. This applies to **all** services in that region.

{% navtabs "subset-timeout" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: regional-baseline
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshSubset
    tags:
      region: us-east-1
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
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      region: us-east-1
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

In modern {{site.mesh_product_name}} (2.6+), you manage "subsets" (like Canary vs. Stable) by creating **distinct `MeshService` resources**. This is called **Explicit Subsetting**.

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

## Legacy Note: MeshServiceSubset
{% tip %}
You may see `kind: MeshServiceSubset` in older documentation or legacy clusters. This was a "virtual kind" used before the introduction of explicit `MeshService` resources. While still supported for backwards compatibility, it is considered **Legacy** and should be avoided in new projects.
{% endtip %}
