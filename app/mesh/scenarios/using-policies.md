---
title: How to use policies (TargetRef)
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: A comprehensive guide to the {{site.mesh_product_name}} TargetRef policy system, explaining how to target proxies, define traffic rules, and manage policy hierarchy.
products:
  - mesh
tldr:
  q: How do I manage policies in Kong Mesh?
  a: |
    Kong Mesh uses a unified **TargetRef** system to simplify policy management:
    1. **Target once** using `targetRef` to select workloads, services, or the entire mesh.
    2. **Define rules** within the same policy resource.
    3. **Override globally** with specific local rules using the built-in policy hierarchy.
next_steps:
  - text: "Traffic Splitting with MeshServices"
    url: "/mesh/scenarios/traffic-splitting-meshservices/"
---
In many service meshes, managing traffic requires juggling multiple, overlapping resources like `VirtualServices`, `DestinationRules`, `ServiceEntries`, and `Gateways`. {{site.mesh_product_name}} simplifies this with a unified **TargetRef** system. 

Instead of fragmented resources, you define your intent once in a single policy that handles the targeting, the traffic rules, and the configuration.

{{site.mesh_product_name}} uses the `targetRef` system to provide precise control over traffic and proxy configuration. 

### Why TargetRef?
The `targetRef` pattern is a standard established by the **Kubernetes Gateway API**. Kong Mesh adopts this system for two primary reasons:
1. **Consistency**: By using the same pattern as the Gateway API, your service mesh policies feel familiar if you are already managing ingress traffic via Gateway resources.
2. **Ease of Use**: It eliminates the need for complex label matching in every policy. You target a resource once, and the mesh handles the underlying connectivity.

Policies follow a standard structure:

1.  **Top-Level `targetRef`**: Defines which sidecars receive the configuration.
2.  **`to` / `from` Rules**: Defines the traffic flows affected by the policy.
3.  **`default` Config**: Defines the actual configuration values.

## Hierarchy levels

{% table %}
columns:
  - title: Level
    key: level
  - title: Target kind
    key: kind
  - title: Kong Air use case
    key: use_case
rows:
  - level: Global
    kind: "`Mesh`"
    use_case: "Baseline mTLS and logging for all Kong Air sidecars."
  - level: Grouped
    kind: "`MeshSubset`"
    use_case: "Override security policies for a `region: east` or `env: staging`."
  - level: Specific
    kind: "`MeshService`"
    use_case: "Fine-grained Canary routing for the `booking-engine`."
{% endtable %}

## Policy types and traffic flow

Depending on the policy, you use either `to`, `from`, or a direct `default` block.

{% table %}
columns:
  - title: Direction
    key: direction
  - title: Logic
    key: logic
  - title: Policy Kinds
    key: policy_kinds
  - title: Kong Air Example
    key: example
rows:
  - direction: "Outbound (`to`)"
    logic: "Affects traffic leaving a proxy towards a destination."
    policy_kinds: "`MeshHTTPRoute`, `MeshRetry`, `MeshCircuitBreaker`"
    example: "Route 10% of `passenger-portal` traffic to `booking-v2`."
  - direction: "Inbound (`from`)"
    logic: "Affects traffic entering a proxy from a source."
    policy_kinds: "`MeshTrafficPermission`"
    example: "Only allow `flight-control` to call the `check-in-api`."
  - direction: Dual-Purpose
    logic: "Can be applied to both incoming or outgoing flows."
    policy_kinds: "`MeshTimeout`, `MeshRateLimit`, `MeshAccessLog`"
    example: "Set a 5s outbound timeout on all requests leaving `flight-control`."
  - direction: Direct (`default`)
    logic: "Configures proxy capabilities directly."
    policy_kinds: "`MeshMetric`, `MeshTrace`, `MeshProxyPatch`"
    example: "Enable Prometheus metrics for every sidecar in the mesh."
{% endtable %}

## Policy precedence

{{site.mesh_product_name}} follows a "most specific wins" approach. A `MeshService` policy always overrides a `Mesh` policy for that specific service. 

**Best practice**: Define broad `Mesh` policies for baseline behavior and use `MeshService` overrides only for critical services requiring custom tuning.


## Key Vocabulary

| Term | Meaning |
| :--- | :--- |
| **`kind: Mesh`** | Absolute broadest scope. Use for "baseline" security and reliability. |
| **`kind: MeshSubset`** | Selective scope based on tags. Great for A/B testing or blue/green. |
| **`kind: MeshService`** | Targeted scope. Best for service-specific fine-tuning. |

## Best Practice: Start Broad, Then Narrow
The most efficient way to manage a mesh is to define a `Mesh` level policy for everything (mTLS, basic timeouts, broad permissions) and then add specific `MeshService` policies only where they are needed. This keeps your configuration clean and easy to audit.
