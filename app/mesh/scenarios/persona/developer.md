---
title: Developer
content_type: reference
layout: reference
description: How the developer uses {{site.mesh_product_name}} at Kong Air to route traffic to new versions, make services resilient, and call the services of other teams.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "{{site.mesh_product_name}} scenarios"
    url: /mesh/scenarios/
  - text: Operator
    url: /mesh/scenarios/persona/operator/
  - text: Security architect
    url: /mesh/scenarios/persona/security/
  - text: Introduction to Kong Air
    url: /mesh/scenarios/introduction-kong-air/
  - text: Policy targeting
    url: /mesh/policy-targeting/
  - text: Split traffic with MeshService resources
    url: /mesh/split-traffic-with-meshservice-resources/
  - text: Target workloads and services
    url: /mesh/target-workloads-and-services/
  - text: Observe mesh traffic in practice
    url: /mesh/observe-mesh-traffic-in-practice/
  - text: Manage external services with MeshExternalService
    url: /mesh/manage-external-services-with-meshexternalservice/
  - text: Validate resilience with fault injection
    url: /mesh/validate-resilience-with-fault-injection/
  - text: Send traffic between zones
    url: /mesh/send-traffic-between-zones/
  - text: Prepare the mesh for production
    url: /mesh/prepare-the-mesh-for-production/
---
The developer is a senior software engineer on the Passenger Experience team at Kong Air.
The developer owns the services that passengers interact with:

* `passenger-portal`: the booking and check-in UI
* `check-in-api`: the back end that assigns seats and issues boarding passes

Other teams own the operational core (`flight-control`) and the baggage service (`baggage-api`), and the operator registers the external dependencies.
The developer's job is to release their own services safely, make them resilient, and call the services of other teams.

### What the developer owns at Kong Air

{% mermaid %}
flowchart LR
  subgraph DEV["The developer's scope"]
    PP["passenger-portal"]
    CI["check-in-api"]
  end
  subgraph OTHERS["Owned by other teams"]
    FC["flight-control<br/>(the operator)"]
    BAG["baggage-api<br/>(zone2)"]
    AP["aeropay-api<br/>(AeroPay)"]
  end

  FC --> CI
  CI --> PP
  PP --> BAG
  PP -.-> AP
{% endmermaid %}

The dashed arrow points to AeroPay, Kong Air's payment provider, which runs outside the mesh.
For the full picture, see [Kong Air](/mesh/scenarios/introduction-kong-air/#kong-air).

## How the developer calls the services of other teams

The developer's services call each destination by a hostname.
The developer doesn't manage the resources behind these hostnames:

<!-- vale off -->
{% table %}
columns:
  - title: Destination
    key: destination
  - title: Hostname the developer calls
    key: hostname
  - title: Where it comes from
    key: source
rows:
  - destination: "`check-in-api`, in the same zone"
    hostname: "`check-in-api.kong-air-production.svc.cluster.local`"
    source: "The Kubernetes `Service`. The sidecar proxies the traffic like any other mesh traffic."
  - destination: "`baggage-api`, in `zone2`"
    hostname: "`baggage-api.kong-air-production.svc.zone2.mesh.local`"
    source: "The `MeshService` that `zone2` generates and the global control plane syncs to `zone1`. See [Send traffic between zones](/mesh/send-traffic-between-zones/)."
  - destination: "AeroPay, outside the mesh"
    hostname: "`aeropay-api.extsvc.mesh.local`"
    source: "The `MeshExternalService` that the operator registers. See [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/)."
{% endtable %}
<!-- vale on -->

A hostname doesn't grant access.
Each call also needs a `MeshTrafficPermission` that the [security architect](/mesh/scenarios/persona/security/) manages.

## How the developer releases a new version

To release `passenger-portal` v2, the developer gives each version its own `MeshService`, and applies a `MeshHTTPRoute` that sends 90% of the traffic to `v1` and 10% to `v2`.
The developer then checks the new version before sending it more traffic.
See [Split traffic with MeshService resources](/mesh/split-traffic-with-meshservice-resources/).

## How the developer makes services resilient

### Retries with `MeshRetry`

A new mesh doesn't retry failed requests.
The developer wants every caller of `check-in-api` to retry requests that fail with a `5xx` status.
The developer creates the `MeshRetry` in the namespace of `check-in-api` and selects it as the destination, which makes it a producer policy that reaches every caller.
See [Target workloads and services](/mesh/target-workloads-and-services/).

Calls to AeroPay also get retries: a `MeshRetry` makes the `passenger-portal` sidecar retry failed calls to `aeropay-api` up to three times.
See [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/).

### Test failures with `MeshFaultInjection`

The developer checks how callers handle a failing `check-in-api`.
A `MeshFaultInjection` makes the `check-in-api` sidecar return errors, add latency, or slow its responses to `flight-control`, without changing the application.
See [Validate resilience with fault injection](/mesh/validate-resilience-with-fault-injection/).

## How the developer observes services

The operator collects the metrics and access logs of every sidecar.
The developer reads them in the Workload Health and Workload Debug Grafana dashboards, and reads the access log of a sidecar to see why a call failed, for example a `403` from a missing permission.
See [Observe mesh traffic in practice](/mesh/observe-mesh-traffic-in-practice/).

## How the developer declares what each service calls

Before the mesh carries production traffic, each workload declares the destinations it calls in the `kuma.io/reachable-backends` annotation.
For example, `passenger-portal` declares `check-in-api`, `baggage-api` in `zone2`, and `aeropay-api`.
Each proxy then receives configuration only for these destinations, and can't reach anything else after the operator turns on `restrictOutbound`.
See [Prepare the mesh for production](/mesh/prepare-the-mesh-for-production/).

With these policies, the developer spends less time on the network and more time on features for passengers.
