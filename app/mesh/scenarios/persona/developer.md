---
title: Developer
content_type: reference
layout: reference
description: How the developer uses {{site.mesh_product_name}} at Kong Air to manage traffic, ensure resilience, and optimize flight booking services.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
  - /mesh/scenarios/persona/
products:
  - mesh
works_on:
  - on-prem
  - konnect
---

The developer is a Senior Software Engineer at **Kong Air**, on the **Passenger Experience** team. The developer owns the services that the airline's passengers see and interact with, `passenger-portal` (the booking and check-in UI) and `check-in-api` (the back-end that processes seat assignments and boarding passes). The developer does **not** own the operational core (`flight-control`), the ingress gateway (`booking-gateway`), or the underlying databases (`flight-db`); those belong to other teams. The developer's job is to make these services fast, resilient, and observable while consuming everyone else's services safely.

### What the developer owns at Kong Air

{% mermaid %}
flowchart LR
  subgraph DEV["The developer's scope"]
    PP["passenger-portal"]
    CI["check-in-api"]
  end
  subgraph OTHERS["Owned by other teams"]
    BG["booking-gateway<br/>(the operator)"]
    FC["flight-control<br/>(the operator)"]
    DB[("flight-db<br/>(Infra)")]
    WX["weather-api<br/>(SaaS)"]
  end

  BG --> PP
  PP --> CI
  CI --> FC
  FC --> DB
  CI -.-> WX
{% endmermaid %}

The dashed arrow to `weather-api` is an external SaaS, the developer reaches it through a `MeshExternalService` that the operator has configured. See the [Meet Kong Air section](/mesh/scenarios/introduction/#meet-kong-air) for the full picture.

## Service discovery and consuming services the developer doesn't own

The developer's services need predictable hostnames for the things they call. Both the in-zone DNS naming (via `HostnameGenerator`) and the cross-zone abstraction (via `MeshMultiZoneService`) are typically set up by the **operator**, they're cluster-wide concerns that live in the system namespace and apply to every service. The developer's job is to use them.

### The developer's view of in-zone DNS

The operator has applied a **custom** `HostnameGenerator` for the mesh (Kong Air's own naming scheme, the built-in default for zone-local services is `.svc.cluster.local` on Kubernetes). It generates a DNS name like `<service>.svc.kongair.mesh` for every `MeshService`. The developer just needs to know the convention:

<!-- vale off -->
{% table %}
columns:
  - title: Service
    key: service
  - title: Hostname the developer calls
    key: hostname_developer_calls
rows:
  - service: |
      `check-in-api` (the developer's own service)
    hostname_developer_calls: |
      `check-in-api.svc.kongair.mesh`
  - service: |
      `flight-control` (the operator's service)
    hostname_developer_calls: |
      `flight-control.svc.kongair.mesh`
{% endtable %}
<!-- vale on -->

The `HostnameGenerator` resource itself is applied by the operator and lives in the system namespace. See [Multi-zone architecture](/mesh/scenarios/multi-zone-architecture/) for how the naming scheme is configured.

{:.info}
> On Kubernetes, the developer can call other in-cluster services directly by their Kubernetes service address (for example, `check-in-api.kong-air-production.svc.cluster.local`), the mesh transparently proxies that traffic. The HostnameGenerator just gives the developer a stable, mesh-native name that works the same in every zone.

### The developer's view of cross-zone services

When `passenger-portal` (running in zone1) needs to call `flight-control` (which may be in zone1 *or* zone2), the operator has defined a `MeshMultiZoneService` that aggregates both zones into one logical service. The developer calls a single hostname and the mesh handles locality and failover. The `MeshMultiZoneService` is applied by the operator, see [Multi-zone architecture](/mesh/scenarios/multi-zone-architecture/) for how it is defined.

### External services

For the SaaS weather feed, the operator has registered a `MeshExternalService`, which the developer's `check-in-api` calls by its mesh-generated name like any other in-mesh service. The `MeshExternalService` is applied by the operator, see [Manage external services with MeshExternalService](/mesh/scenarios/manage-external-services-with-meshexternalservice/) for how it is registered.

## Traffic management

The developer needs full control over how requests land on these services.

### Canary routing with `MeshHTTPRoute`
Launching v2 of the passenger portal? The developer shifts a percentage of traffic to the new version with a `MeshHTTPRoute` to verify its performance before a full rollout. See [Split traffic with MeshService resources](/mesh/scenarios/split-traffic-with-meshservice-resources/) for weighted canary routing, and [Route across zones with canary rollouts and color rings](/mesh/scenarios/route-across-zones-with-canary-rollouts-and-color-rings/) for progressive cross-zone rollouts.

{:.warning}
> The traffic hierarchy: routing versus load balancing.
>
> It is easy to confuse `weight` in a route with load balancing, but they happen at different layers:
> 1. **Selection (the route)**: `MeshHTTPRoute` uses `weight` to decide which subset (`v1` or `v2`) the request belongs to.
> 2. **Distribution (the strategy)**: Once a subset is chosen, `MeshLoadBalancingStrategy` decides which specific instance (Pod) within that subset receives the traffic.

### Advanced load balancing
To ensure fair distribution across the backend instances, the developer configures a `MeshLoadBalancingStrategy` (for example, a `LeastRequest` load balancer that sends traffic to the least busy instance). See [MeshLoadBalancingStrategy](/mesh/policies/meshloadbalancingstrategy/) for the policy fields.

### Safety with `MeshRateLimit`
To prevent a misbehaving client from overwhelming the check-in service during peak boarding times, the developer applies a `MeshRateLimit` to the `check-in-api` proxies (an inbound policy, so the top-level `targetRef` selects the receiving workloads and `rules` configures the limit). See [MeshRateLimit](/mesh/policies/meshratelimit/) for the policy fields.

## Deep resilience

The developer knows that failure is inevitable. The developer builds multiple layers of defense, then proves they work with fault injection. See [Validate resilience with fault injection](/mesh/scenarios/validate-resilience-with-fault-injection/) for how these policies are exercised together.

### Active health checks (`MeshHealthCheck`)
The mesh actively pings the developer's services to ensure they are ready to receive traffic. See [MeshHealthCheck](/mesh/policies/meshhealthcheck/) for the policy fields.

### Passive health checks (`MeshCircuitBreaker`)
If a specific instance of `check-in-api` starts returning 500s unexpectedly, the circuit breaker temporarily ejects it. See [MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/) for the policy fields.

### Self-healing with `MeshRetry`
Transient network blips should not reach the passenger, so the developer configures automatic retries. See [MeshRetry](/mesh/policies/meshretry/) for the policy fields.

## Observability

The developer needs to see what is happening inside the code. The developer uses `MeshMetric` to aggregate both sidecar metrics and custom application metrics (like `checkins_per_second`). See [Observe mesh traffic in practice](/mesh/scenarios/observe-mesh-traffic-in-practice/) for how metrics, traces, and logs are collected across Kong Air.

## Gateway integration

Finally, **booking-gateway** ({{site.base_gateway}}, owned by the operator) is the entry point into the developer's services. The developer doesn't operate the gateway itself, but just makes sure these services play well with it:

*   **Ingress**: {{site.base_gateway}} terminates external HTTPS and forwards into the mesh. Passengers hit the gateway; the gateway routes to `passenger-portal`.
*   **Bridge**: It translates external JWT authentication into the mesh identity, so the developer's services see which passenger is making the request.

The gateway itself is the operator's responsibility, see the [Operator](/mesh/scenarios/persona/operator/) for how the gateway is wired into the mesh.

---

By mastering these policies, the developer has turned **Kong Air** into a resilient, high-scale digital airline. The developer spends less time worrying about the network and more time building features that get passengers where they need to go.
