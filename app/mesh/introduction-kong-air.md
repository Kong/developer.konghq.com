---
title: Introduction to the Kong Air scenarios
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

The [{{site.mesh_product_name}} scenarios](/mesh/scenarios/) follow Kong Air, a fictional global airline that modernizes its flight systems.
Kong Air's applications run in three places:

* Kubernetes, for the services that passengers use
* VMs, for the older booking systems
* SaaS providers, for the weather feed and the external certificate authority

The Kong Air platform team moves these applications into one multi-zone {{site.mesh_product_name}} deployment.

The Kong Air mesh is named `kong-air-mesh`.
A self-managed control plane creates a mesh named `default`, but production deployments usually run one named mesh for each environment or business unit.
Every YAML example in the scenarios names `kong-air-mesh`, as you do in a production deployment.

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

Solid arrows show traffic inside the mesh.
Dashed arrows show traffic to external dependencies, which the scenarios describe as `MeshExternalService` resources.
HashiCorp Vault works with the control plane to sign workload certificates, so it carries no application traffic.

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
  - persona: "[Developer](/mesh/persona/developer/)"
    owns: |
      Passenger experience services: 
      * `passenger-portal`
      * `check-in-api`
    consumes: |
      * `flight-control`
      * `flight-db`
      * `weather-api`
  - persona: "[Operator](/mesh/persona/operator/)"
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
  - persona: "[Security architect](/mesh/persona/security/)"
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
  - role: "[Developer](/mesh/persona/developer/)"
    focus: Resilience and routing
    capabilities: |
      * Traffic routing: `MeshHTTPRoute` sends traffic to canary releases or A/B tests without code changes.
      * Resilience: `MeshRetry`, `MeshTimeout`, and `MeshFaultInjection` protect applications from cascading failures.
  - role: "[Operator](/mesh/persona/operator/)"
    focus: Scale and stability
    capabilities: |
      * Health checks: `MeshHealthCheck` and `MeshCircuitBreaker` find unhealthy instances and stop sending them traffic.
      * Observability: `MeshMetric` provides the same telemetry in every cluster.
      * Load balancing: `MeshLoadBalancingStrategy` spreads traffic and prefers instances in the same zone.
  - role: "[Security architect](/mesh/persona/security/)"
    focus: Zero trust
    capabilities: |
      * Encryption: `MeshIdentity` gives each workload that it selects a certificate and turns on mutual TLS (mTLS), and the certificates rotate automatically.
      * Access control: `MeshTrafficPermission` allows each call explicitly, and the proxies deny everything else.
{% endtable %}
<!-- vale on -->

## Scenario roadmap

The Kong Air scenarios have five phases.
We recommend that you follow them in order, because each phase builds on the resources of the previous one:

1. [Fundamentals](/mesh/scenarios/#phase-1-fundamentals): Learn the architecture, secure your first services, and select proxies with policies.
2. [Observability and security](/mesh/scenarios/#phase-2-observability-and-security): See every flight-critical request and protect passenger data.
3. [Global mesh operations](/mesh/scenarios/#phase-3-global-mesh-operations): Connect cloud regions and data centers into one mesh.
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
