---
title: Introduction
content_type: reference
layout: reference
description: A beginner-friendly introduction to {{site.mesh_product_name}}, detailing its value for developers, operators, and security teams through Mesh policies.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
next_steps:
  - text: "Architecture overview"
    url: "/mesh/scenarios/architecture-overview/"
related_resources:
  - text: Service meshes
    url: /mesh/service-mesh/
  - text: Concepts
    url: /mesh/concepts/
  - text: Resource scoping
    url: /mesh/scenarios/resource-scoping/
---
{{site.mesh_product_name}} is an enterprise-grade service mesh that provides a unified control plane to manage services across Kubernetes, VMs, and bare metal. Its policy-driven model works the same regardless of the underlying infrastructure, and focuses on day-2 operations: running, upgrading, and troubleshooting the mesh in production, across regions and mixed infrastructure. 

For more details, see the [Architecture overview](/mesh/scenarios/architecture-overview/).

## Kong Air

Throughout these [scenarios](/mesh/scenarios/), we follow the journey of Kong Air, a global airline modernizing its flight-critical infrastructure. Their applications span Kubernetes (passenger-facing services), VMs (legacy booking systems), and SaaS dependencies (weather feeds and external certificate authorities). The platform team is migrating this fragmented landscape into a single, multi-zone {{site.mesh_product_name}} deployment.

The Kong Air mesh is named `kong-air-mesh`. {{site.mesh_product_name}} ships with a `default` mesh out of the box, but in production you'll typically run a named mesh per environment or business unit. Every YAML example in these scenarios targets `kong-air-mesh` explicitly, the pattern you'll need in any real deployment.

### Service landscape

{% mermaid %}
graph LR
  BG["booking-gateway<br/>({{site.base_gateway}})"]
  subgraph ZE["zone1"]
    PP_E["passenger-portal"]
    CI_E["check-in-api"]
    FC_E["flight-control"]
  end
  subgraph ZW["zone2"]
    PP_W["passenger-portal"]
    CI_W["check-in-api"]
    FC_W["flight-control"]
  end
  subgraph EXT["External dependencies"]
    DB[("flight-db<br/>RDS Postgres")]
    WX["weather-api<br/>(SaaS)"]
    VAULT["HashiCorp Vault<br/>(External CA)"]
  end
  BG --> PP_E
  BG --> PP_W
  PP_E --> CI_E
  PP_W --> CI_W
  CI_E --> FC_E
  CI_W --> FC_W
  CI_E -.-> WX
  CI_W -.-> WX
  FC_E -.-> DB
  FC_W -.-> DB
{% endmermaid %}

Solid arrows are intra-mesh traffic. Dashed arrows are traffic to external dependencies modelled as `MeshExternalService`. The vault is shown for context; it integrates with the control plane, not data plane traffic.

### Personas

The scenarios reference three personas. Each owns a different slice of Kong Air:

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
      * `flight-control`
      * `flight-db`
      * `weather-api`
  - persona: "[Operator](/mesh/scenarios/persona/operator/)"
    owns: |
      * Mesh control plane
      * Zone ingress and egress
      * Mesh-scoped zone proxies 
      * Observability stack 
      * `booking-gateway`
      * The operational core service `flight-control`
      * The `kong-air-mesh` resource
    consumes: |
      N/A
  - persona: "[Security architect](/mesh/scenarios/persona/security/)"
    owns: |
      * Zero-trust posture (`MeshTLS`, `MeshTrafficPermission`)
      * Workload identity (`MeshIdentity`, `MeshTrust`)
      * Vault integration
    consumes: |
      N/A
  - persona: "Infrastructure team (out of scope)"
    owns: |
      * `flight-db` (RDS)
      * `weather-api` SaaS subscription
    consumes: |
      N/A
{% endtable %}
<!-- vale on -->

Delivering these capabilities as a standardized, built-in layer means teams configure networking behavior through policies rather than implementing it in each service.

## Benefits by role

<!-- vale off -->
{% table %}
columns:
  - title: Role
    key: role
  - title: Focus area
    key: focus
  - title: Key capabilities
    key: capabilities
rows:
  - role: "[Developer](/mesh/scenarios/persona/developer/)"
    focus: Resilience and routing
    capabilities: |
      * Traffic routing: Manage traffic flows like canary releases or A/B testing via `MeshHTTPRoute` without code changes.
      * Resilience: Protect apps from cascading failures with `MeshRetry`, `MeshTimeout`, and `MeshFaultInjection`.
  - role: "[Operator](/mesh/scenarios/persona/operator/)"
    focus: Scalability and stability
    capabilities: |
      * Self-healing: Automatically detect and remove unhealthy instances with `MeshHealthCheck` and `MeshCircuitBreaker`.
      * Observability: Gain instant visibility with `MeshMetric` and consistent telemetry across all clusters.
      * Traffic strategy: Optimize distribution with `MeshLoadBalancingStrategy`, including locality-aware routing.
  - role: "[Security architect](/mesh/scenarios/persona/security/)"
    focus: Zero trust
    capabilities: |
      * Encryption: Enable Mutual TLS (mTLS) automatically with `MeshTLS`, including handled certificate rotation.
      * Access control: Authorize traffic explicitly with `MeshTrafficPermission` to enforce a "deny-all" security posture.
{% endtable %}
<!-- vale on -->

## Scenario roadmap

The Kong Air modernization is divided into four stages. We recommend following them in order to build a complete, zero-trust global network:

1. [Fundamentals](/mesh/scenarios/#phase-1-fundamentals): Understand the architecture, secure your first services, and master policy targeting.
2. [Observability and security](/mesh/scenarios/#phase-2-observability--security): Gain visibility into every flight-critical request and protect passenger data.
3. [Global mesh operations](/mesh/scenarios/#phase-3-global-mesh-operations): Connect cloud regions and legacy data centers into a single mesh.
4. [Expert operations](/mesh/scenarios/#phase-4-expert-operations): Control the perimeter, manage external services, and validate resilience with fault injection.

## Technical foundation

These scenarios assume familiarity with the core service mesh building blocks: 
* The control plane that manages mesh state and policy
* The data plane sidecar that enforces it
* The Kuma Discovery Service (KDS) that syncs a global CP with its zone CPs. 

For more information about what a service mesh is and the problems it solves, see [Service meshes](/mesh/service-mesh/). 
For component definitions and the terminology used throughout these scenarios (xDS, SPIFFE ID, SNI, KRI, and more), see [Concepts](/mesh/concepts/).

{:.info}
> Because {{site.mesh_product_name}} scales across clouds and data centers, knowing where each resource is applied (global vs zone CP, system namespace) matters. The [Resource scoping](/mesh/scenarios/resource-scoping/) guide covers this in depth.
