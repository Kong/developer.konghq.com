---
title: Developer
content_type: reference
layout: reference
description: How the developer uses {{site.mesh_product_name}} at Kong Air to manage traffic, ensure resilience, and optimize flight booking services.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
  - /mesh/persona/
products:
  - mesh
works_on:
  - on-prem
  - konnect
---
The developer is a senior software engineer on the Passenger Experience team at Kong Air.
The developer owns the services that passengers interact with:

* `passenger-portal`: the booking and check-in UI
* `check-in-api`: the back end that assigns seats and issues boarding passes

Other teams own the operational core (`flight-control`), the ingress gateway (`booking-gateway`), and the databases (`flight-db`).
The developer's job is to make their own services fast, resilient, and observable, and to call the services of other teams safely.

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

The dashed arrow points to `weather-api`, an external SaaS service.
The developer reaches it through a `MeshExternalService` that the operator configured.
For the full picture, see [Kong Air](/mesh/introduction/#kong-air).

## How the developer finds the services of other teams

The developer's services need predictable hostnames for the services they call.
The [operator](/mesh/persona/operator/) sets up these hostnames for the whole mesh, with resources in the system namespace.
The developer uses the hostnames and doesn't manage the resources.

### Hostnames in the same zone

The operator applies a custom `HostnameGenerator` for the mesh.
It gives each `MeshService` that its selector matches a hostname such as `<service>.svc.kongair.mesh`.
Without a custom generator, a workload on Kubernetes calls a service in its own zone by its Kubernetes DNS name, which ends in `.svc.cluster.local`.
The developer only needs to know the naming convention:

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

The operator applies the `HostnameGenerator` resource in the system namespace.
For how {{site.mesh_product_name}} names services, see [MeshService](/mesh/meshservice/).

{:.info}
> On Kubernetes, the developer can also call another service in the cluster by its Kubernetes address, for example `check-in-api.kong-air-production.svc.cluster.local`.
> The sidecar proxies that traffic like any other mesh traffic.
> A hostname from the `HostnameGenerator` doesn't depend on Pod addresses, and it follows the same convention in every zone that has the generator.

### Services in other zones

`passenger-portal` runs in `zone1` and calls `flight-control`, which can run in `zone1` or `zone2`.
The operator applies a `MeshMultiZoneService` that combines the `flight-control` services of both zones into one destination.
The developer calls one hostname, and the mesh picks the zone and fails over when a zone is unavailable.
For how the operator defines it, see [MeshMultiZoneService](/mesh/meshmultizoneservice/).

### External services

The operator registers the SaaS weather feed as a `MeshExternalService`.
`check-in-api` calls it by its mesh hostname, like any service in the mesh.
For how the operator registers it, see [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/).

## How the developer controls traffic

The developer controls how requests reach their services with three policies.

### Canary routing with `MeshHTTPRoute`

To release a new version of `passenger-portal`, the developer applies a `MeshHTTPRoute` that sends a percentage of the traffic to the new version.
The developer then checks its performance before sending all traffic to it.
See [Split traffic with MeshService resources](/mesh/split-traffic-with-meshservice-resources/).

{:.info}
> A route and a load balancer make different decisions:
>
> 1. `MeshHTTPRoute` uses `weight` to choose the destination, `v1` or `v2`, for each request.
> 2. `MeshLoadBalancingStrategy` then chooses the instance (Pod) of that destination that receives the request.

### Load balancing with `MeshLoadBalancingStrategy`

The developer applies a `MeshLoadBalancingStrategy` to spread requests across the instances of a service.
For example, a `LeastRequest` load balancer compares a few random instances and sends each request to the one with the fewest active requests.
See [MeshLoadBalancingStrategy](/mesh/policies/meshloadbalancingstrategy/).

### Rate limits with `MeshRateLimit`

During peak boarding times, a misbehaving client can overload `check-in-api`.
To prevent this, the developer applies a `MeshRateLimit` to the `check-in-api` proxies.
The policy limits the requests that these proxies receive, so its top-level `targetRef` selects `check-in-api`, and its `rules` set the limit.
See [MeshRateLimit](/mesh/policies/meshratelimit/).

## How the developer makes services resilient

Failures happen, so the developer adds several layers of protection.
The developer then tests them with fault injection.
See [Validate resilience with fault injection](/mesh/validate-resilience-with-fault-injection/).

### Active health checks with `MeshHealthCheck`

With `MeshHealthCheck`, the sidecars of the calling services send health check requests to each instance of the developer's services.
The sidecars stop sending traffic to an instance that fails the checks.
See [MeshHealthCheck](/mesh/policies/meshhealthcheck/).

### Passive health checks with `MeshCircuitBreaker`

With `MeshCircuitBreaker`, the calling sidecars watch the responses from each instance.
If one instance of `check-in-api` returns errors, the sidecars stop sending it traffic for a time.
See [MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/).

### Retries with `MeshRetry`

A new mesh doesn't retry failed requests.
The developer applies a `MeshRetry`, so the sidecars retry short network failures before a passenger sees an error.
See [MeshRetry](/mesh/policies/meshretry/).

## How the developer observes services

The developer uses `MeshMetric` to collect both the sidecar metrics and the metrics that the application exposes, such as `checkins_per_second`.
See [Observe mesh traffic in practice](/mesh/observe-mesh-traffic-in-practice/).

## How the developer works with the gateway

`booking-gateway` runs {{site.base_gateway}} and is the entry point to the developer's services.
The operator runs the gateway, and the developer makes sure that their services work with it:

* **Ingress**: {{site.base_gateway}} terminates the external HTTPS connection and routes the request to `passenger-portal` in the mesh.
* **Passenger identity**: {{site.base_gateway}} validates the passenger's JWT and sends the claims to the services as request headers. The mesh identity of the connection is still the gateway's. So the developer's services allow the gateway with a `MeshTrafficPermission`, and read the passenger from the headers. For what makes those headers trustworthy, see [Security architect](/mesh/persona/security/).

For how a gateway connects to the mesh, see [Application ingress](/mesh/application-ingress/) and [Operator](/mesh/persona/operator/).

With these policies, the developer spends less time on the network and more time on features for passengers.
