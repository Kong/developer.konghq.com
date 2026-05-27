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
  q: How do I manage policies in {{site.mesh_product_name}}?
  a: |
    {{site.mesh_product_name}} uses a unified **TargetRef** system to simplify policy management:
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
The `targetRef` pattern is a standard established by the **Kubernetes Gateway API**. {{site.mesh_product_name}} adopts this system for two primary reasons:
1. **Consistency**: By using the same pattern as the Gateway API, your service mesh policies feel familiar if you are already managing ingress traffic via Gateway resources.
2. **Ease of Use**: It eliminates the need for complex label matching in every policy. You target a resource once, and the mesh handles the underlying connectivity.

Policies follow a standard structure:

1.  **Top-Level `targetRef`**: Defines which sidecars the policy attaches to.
2.  **`to[]` (outbound) or `rules[]` (inbound)**: Defines the traffic flows affected.
3.  **`default` Config**: Defines the actual configuration values.

{% danger %}
**`spec.from` is deprecated.** The older `from`-style inbound configuration on `MeshTrafficPermission`, `MeshFaultInjection`, `MeshTLS`, `MeshAccessLog`, `MeshRateLimit`, `MeshCircuitBreaker`, and `MeshTimeout` is on the deprecation list and will be removed in 3.0. New policies should use `spec.rules[]` instead — see the "Inbound: `rules`" section below.
{% enddanger %}

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
    use_case: "Baseline mTLS and logging for every sidecar in `kong-air-mesh`."
  - level: Grouped
    kind: "`Dataplane` with `labels:`"
    use_case: "Override timeouts for `kuma.io/zone: us-east-1` or `environment: staging`."
  - level: Specific (gateway only)
    kind: "`MeshGateway`"
    use_case: "Policies that apply to a built-in gateway."
{% endtable %}

{% warning %}
At the **top level** of a policy, only `Mesh`, `Dataplane` (with `labels:`), and `MeshGateway` are recommended. `MeshSubset`, `MeshServiceSubset`, and `MeshService` are deprecated at the top level and emit a warning on apply. `MeshService`, `MeshMultiZoneService`, and `MeshExternalService` are still correct **inside `to[].targetRef` and `backendRefs`** — that's where they belong.
{% endwarning %}

## Policy types and traffic flow

Depending on the policy, you use either `to[]` (outbound), `rules[]` (inbound), or a direct `default` block.

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
  - direction: "Outbound (`to[]`)"
    logic: "Affects traffic leaving a proxy towards a destination."
    policy_kinds: "`MeshHTTPRoute`, `MeshRetry`, `MeshCircuitBreaker`"
    example: "Route 10% of `passenger-portal` traffic to `passenger-portal-v2`."
  - direction: "Inbound (`rules[]`)"
    logic: "Affects traffic entering a proxy from a source, matched by SPIFFE identity."
    policy_kinds: "`MeshTrafficPermission`, `MeshFaultInjection`, `MeshTLS`, `MeshAccessLog`, `MeshRateLimit`, `MeshCircuitBreaker`, `MeshTimeout`"
    example: "Only allow callers with SPIFFE ID `spiffe://kong-air-mesh/flight-control` to reach `check-in-api`."
  - direction: Direct (`default`)
    logic: "Configures proxy capabilities directly."
    policy_kinds: "`MeshMetric`, `MeshTrace`, `MeshProxyPatch`, `MeshPassthrough`"
    example: "Enable Prometheus metrics on every sidecar in the mesh."
{% endtable %}

## Inbound: `rules`

`rules[]` replaces the older `from[]`. Each rule has an optional `matches` block (filtering on SPIFFE identity, headers, etc.) and a `default` block with the policy configuration. The match value comes from `MeshIdentity` — every workload is issued an identity like `spiffe://<trust-domain>/<workload>`, and that identity is what other proxies see at the inbound listener.

Example — `MeshTrafficPermission` allowing only `flight-control` to reach `check-in-api`:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: only-flight-control-to-check-in
  namespace: {{site.mesh_system_namespace}}
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
              value: spiffe://kong-air-mesh/flight-control
```

The `Match` type supports `Exact` and `Prefix` matching on SPIFFE IDs. See the [Workload Identity & Trust](/mesh/scenarios/workload-identity/) scenario for how identities are issued.

## Policy precedence

{{site.mesh_product_name}} follows a **most-specific-wins** approach. A policy that targets a `Dataplane` with labels overrides a policy that targets `Mesh` for the proxies it matches. Within `rules[]`, a more specific `Exact` SPIFFE match wins over a `Prefix` match.

{% warning %}
`MeshTrafficPermission` is the important exception. Kuma evaluates **all** matching MTP rules for a request, and if any matched rule produces a `Deny`, that deny wins. So use the "most-specific-wins" mental model for the other inbound policies, but treat MTP as an RBAC-style allow/deny evaluation pass.
{% endwarning %}

**Best practice**: Define broad `Mesh`-level policies for baseline behaviour, then add narrower `Dataplane`-with-labels overrides only for the cases that need them.


## Key Vocabulary

| Term | Meaning |
| :--- | :--- |
| **`kind: Mesh`** | Broadest scope. Use for "baseline" security and reliability. |
| **`kind: Dataplane` with `labels:`** | Selective scope based on workload labels. Replaces the deprecated `MeshSubset`. |
| **`kind: MeshGateway`** | For built-in mesh gateways. |
| **`spiffeID` match (in `rules[]`)** | Identity-based filtering inside inbound rules. |

## Best Practice: Start Broad, Then Narrow
The most efficient way to manage a mesh is to define a `Mesh`-level policy for everything (mTLS, basic timeouts, broad permissions) and then add `Dataplane`-with-labels overrides only where they are needed. This keeps your configuration clean and easy to audit.
