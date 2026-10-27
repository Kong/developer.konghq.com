---
title: Introduction to the Kong Air scenarios
content_type: reference
layout: reference
description: Meet Kong Air, the fictional airline that the {{site.mesh_product_name}} scenarios follow, and the roles that use the mesh.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
next_steps:
  - text: "How-to: Install {{site.mesh_product_name}} and deploy Kong Air"
    url: "/mesh/install-kong-mesh-and-deploy-kong-air/"
related_resources:
  - text: Service meshes
    url: /mesh/service-mesh/
  - text: Concepts
    url: /mesh/concepts/
  - text: Resource scoping
    url: /mesh/resource-scoping/
---
{{site.mesh_product_name}} is an enterprise service mesh.
It gives you one control plane to manage services on Kubernetes, VMs, and bare metal.
Its policies work the same way on every platform.
{{site.mesh_product_name}} focuses on day-2 operations: running, upgrading, and managing the mesh in production, across regions and mixed infrastructure.

For more information, see [Architecture overview](/mesh/architecture-overview/).

## Kong Air

The [{{site.mesh_product_name}} scenarios](/mesh/scenarios/) follow Kong Air, a fictional global airline that moves its flight systems into one multi-zone {{site.mesh_product_name}} deployment.
Kong Air runs its services on Kubernetes, in two zones, and depends on two services outside the mesh:

* `zone1` runs `passenger-portal`, `check-in-api`, and `flight-control` in the `kong-air-production` namespace.
* `zone2` runs `baggage-api` in the same namespace.
* AeroPay, Kong Air's payment provider, and `flight-db`, a managed PostgreSQL database, run outside the mesh.

The Kong Air mesh is named `kong-air-mesh`.
A self-managed control plane creates a mesh named `default`, but production deployments usually run one named mesh for each environment or business unit.
Every YAML example in the scenarios names `kong-air-mesh`, as you do in a production deployment.

### Service landscape

{% mermaid %}
graph LR
  subgraph Z1["zone1"]
    PP["passenger-portal"]
    CI["check-in-api"]
    FC["flight-control"]
  end
  subgraph Z2["zone2"]
    BAG["baggage-api"]
  end
  subgraph EXT["External dependencies"]
    AP["aeropay-api<br/>(AeroPay)"]
    DB[("flight-db<br/>PostgreSQL")]
  end
  FC --> CI
  CI --> PP
  PP --> BAG
  PP -.-> AP
  FC -.-> DB
{% endmermaid %}

Solid arrows show the calls inside the mesh that the scenarios allow with a `MeshTrafficPermission`.
Dashed arrows show the calls to external dependencies, which the scenarios describe as `MeshExternalService` resources and send through the zone egress.

### Personas

The scenarios refer to three roles.
Each role owns a different part of Kong Air:

<!-- vale off -->
{% table %}
columns:
  - title: Persona
    key: persona
  - title: Owns
    key: owns
  - title: Consumes
    key: consumes
rows:
  - persona: "[Developer](/mesh/scenarios/persona/developer/)"
    owns: |
      Passenger experience services:
      * `passenger-portal`
      * `check-in-api`
    consumes: |
      * `baggage-api`
      * AeroPay
  - persona: "[Operator](/mesh/scenarios/persona/operator/)"
    owns: |
      * The zone control planes and the `kong-air-mesh` resource
      * The mesh-scoped zone ingress and zone egress
      * The `MeshExternalService` resources
      * The observability stack
      * The operational core service, `flight-control`
    consumes: |
      * `check-in-api`
      * `flight-db`
  - persona: "[Security architect](/mesh/scenarios/persona/security/)"
    owns: |
      * Workload identity (`MeshIdentity`, `MeshTrust`)
      * The zero-trust posture (`MeshTLS`, `MeshTrafficPermission`)
      * The mesh perimeter (`MeshPassthrough`)
      * The external CA integration
    consumes: |
      N/A
  - persona: "Other teams and providers (out of scope)"
    owns: |
      * `baggage-api`
      * The `flight-db` database
      * The AeroPay API
    consumes: |
      N/A
{% endtable %}
<!-- vale on -->

Because the mesh provides these features as a shared layer, teams configure network behavior with policies instead of building it into each service.

## Benefits by role

<!-- vale off -->
{% table %}
columns:
  - title: Role
    key: role
  - title: Focus area
    key: focus
  - title: Key features
    key: capabilities
rows:
  - role: "[Developer](/mesh/scenarios/persona/developer/)"
    focus: Releases and resilience
    capabilities: |
      * Traffic routing: `MeshHTTPRoute` sends a share of the traffic to a new version without code changes.
      * Resilience: `MeshRetry` retries failed requests, and `MeshFaultInjection` tests how callers handle failures.
  - role: "[Operator](/mesh/scenarios/persona/operator/)"
    focus: Scale and stability
    capabilities: |
      * Multi-zone: mesh-scoped zone proxies carry traffic between zones and to external services.
      * Observability: `MeshMetric`, `MeshTrace`, and `MeshAccessLog` send the telemetry of every sidecar to one collector.
      * Configuration size: `reachableBackends` and `restrictOutbound` limit the configuration that each proxy receives.
  - role: "[Security architect](/mesh/scenarios/persona/security/)"
    focus: Zero trust
    capabilities: |
      * Encryption: `MeshIdentity` gives each workload that it selects a certificate and turns on mutual TLS (mTLS), and the certificates rotate automatically.
      * Access control: `MeshTrafficPermission` allows each call explicitly, and the proxies deny everything else.
      * Perimeter: `MeshPassthrough` limits the external destinations that workloads reach.
{% endtable %}
<!-- vale on -->

## Scenario roadmap

The Kong Air scenarios have five phases.
We recommend that you follow them in order, because each phase builds on the resources of the previous one:

1. [Fundamentals](/mesh/scenarios/#phase-1-fundamentals): Learn the architecture, secure your first services, and select proxies with policies.
2. [Observability and security](/mesh/scenarios/#phase-2-observability-and-security): Collect the telemetry of every sidecar, add a second zone, and extend workload identity to it.
3. [Global mesh operations](/mesh/scenarios/#phase-3-global-mesh-operations): Send traffic between the two Kong Air zones.
4. [Expert operations](/mesh/scenarios/#phase-4-expert-operations): Control outbound traffic, manage external services, and test resilience with fault injection.
5. [Production readiness](/mesh/scenarios/#phase-5-production-readiness): Harden the mesh and limit the configuration that each proxy receives before it carries production traffic.

## What you need to know first

The scenarios assume that you know the main parts of a service mesh:

* The control plane, which stores the mesh state and policies
* The data plane sidecar, which applies the policies to traffic
* The Kuma Discovery Service (KDS), which syncs the global control plane with the zone control planes

For what a service mesh is and the problems it solves, see [Service meshes](/mesh/service-mesh/).
For the terms in the scenarios, such as xDS, SPIFFE ID, SNI, and KRI, see [Concepts](/mesh/concepts/).

{:.info}
> {{site.mesh_product_name}} runs across clouds and data centers, so you need to know where to apply each resource: on the global control plane, on a zone control plane, or in the system namespace.
> For the rules, see [Resource scoping](/mesh/resource-scoping/).
