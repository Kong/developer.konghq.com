---
title: Introduction
content_type: reference
layout: reference
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: A beginner-friendly introduction to {{site.mesh_product_name}}, detailing its value for developers, operators, and security teams through Mesh policies.
products:
  - mesh
next_steps:
  - text: "Architecture Overview"
    url: "/mesh/scenarios/architecture-overview/"
---
{{site.mesh_product_name}} is an enterprise-grade service mesh that provides a unified control plane to manage services across Kubernetes, VMs, and bare metal. Its policy-driven model works the same regardless of the underlying infrastructure, a deliberate focus on **day-2 operations**: running, upgrading, and troubleshooting the mesh in production, across regions and mixed infrastructure, not just standing it up on day 1. The [Architecture Overview](/mesh/scenarios/architecture-overview/) unpacks what that means in practice, including [how it compares to Istio-style meshes](/mesh/scenarios/architecture-overview/#day-2-operations-how-this-compares-to-istio-style-meshes).

## Meet Kong Air

Throughout these scenarios, we follow the journey of **Kong Air**, a global airline modernizing its flight-critical infrastructure. Their applications span Kubernetes (passenger-facing services), VMs (legacy booking systems), and SaaS dependencies (weather feeds and external certificate authorities). The platform team is migrating this fragmented landscape into a single, multi-zone {{site.mesh_product_name}} deployment.

The Kong Air mesh is named **`kong-air-mesh`**. We chose a non-default name on purpose: {{site.mesh_product_name}} ships with a `default` mesh out of the box, but in production you'll typically run a named mesh per environment or business unit. Every YAML example in these scenarios targets `kong-air-mesh` explicitly, the pattern you'll need in any real deployment.

### The Kong Air service landscape

{% mermaid %}
graph LR
  BG["booking-gateway<br/>(Kong Gateway)"]
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

Solid arrows are intra-mesh traffic. Dashed arrows are traffic to external dependencies modelled as `MeshExternalService`. Vault is shown for context, it integrates with the control plane, not data-plane traffic.

### Who owns what

The scenarios reference three personas. Each owns a different slice of Kong Air:

{% table %}
columns:
  - title: Persona
    key: persona
  - title: Owns
    key: owns
  - title: Consumes
    key: consumes
rows:
  - persona: "**[Devin the Developer](/mesh/scenarios/persona/developer/)**"
    owns: |
      Passenger Experience services: `passenger-portal`, `check-in-api`.
    consumes: |
      `flight-control`, `flight-db`, `weather-api`.
  - persona: "**[Ollie the Operator](/mesh/scenarios/persona/operator/)**"
    owns: |
      Mesh control plane, zone ingress and egress, mesh-scoped zone proxies, observability stack, `booking-gateway`, the operational core service `flight-control` (which Devin's services *consume* but don't own), and the `kong-air-mesh` resource itself.
    consumes: |
      Operates the platform Devin and Sarah build on.
  - persona: "**[Sarah the Security Architect](/mesh/scenarios/persona/security/)**"
    owns: |
      Zero-trust posture (`MeshTLS`, `MeshTrafficPermission`), workload identity (`MeshIdentity`, `MeshTrust`), Vault integration.
    consumes: |
      Sets the rules every service in the mesh runs under.
  - persona: "**Infra team (out of scope)**"
    owns: |
      `flight-db` (RDS), `weather-api` SaaS subscription.
    consumes: |
      Reached from inside the mesh through `MeshExternalService`.
{% endtable %}

Delivering these capabilities as a standardized, built-in layer means teams configure networking behavior through policies rather than implementing it in each service.

## Benefits by role

{% table %}
columns:
  - title: Role
    key: role
  - title: Focus area
    key: focus
  - title: Key capabilities
    key: capabilities
rows:
  - role: "[Developers](/mesh/scenarios/persona/developer/)"
    focus: Resilience & Routing
    capabilities: |
      * **Traffic Routing**: Manage traffic flows like canary releases or A/B testing via `MeshHTTPRoute` without code changes.
      * **Resilience**: Protect apps from cascading failures with `MeshRetry`, `MeshTimeout`, and `MeshFaultInjection`.
  - role: "[Operators](/mesh/scenarios/persona/operator/)"
    focus: Scalability & Stability
    capabilities: |
      * **Self-Healing**: Automatically detect and remove unhealthy instances with `MeshHealthCheck` and `MeshCircuitBreaker`.
      * **Observability**: Gain instant visibility with `MeshMetric` and consistent telemetry across all clusters.
      * **Traffic Strategy**: Optimize distribution with `MeshLoadBalancingStrategy`, including locality-aware routing.
  - role: "[Security](/mesh/scenarios/persona/security/)"
    focus: Zero Trust
    capabilities: |
      * **Encryption**: Enable Mutual TLS (mTLS) automatically with `MeshTLS`, including handled certificate rotation.
      * **Access Control**: Authorize traffic explicitly with `MeshTrafficPermission` to enforce a "deny-all" security posture.
{% endtable %}

## Scenario Roadmap

The Kong Air modernization is divided into four stages. We recommend following them in order to build a complete, zero-trust global network:

1. **Foundations**: Understand the architecture and resource scoping required for a multi-zone deployment.
2. **Connectivity & Security**: Establish mTLS, authorize traffic, and manage service identity across Kubernetes and VMs.
3. **Resilience & Governance**: Implement fine-grained traffic boundaries and simulate failures with Chaos Engineering.
4. **Advanced Operations**: Master multi-zone canary releases and integrate with enterprise PKI like HashiCorp Vault.

## Technical Foundation

Before starting the hands-on scenarios, familiarize yourself with these three core components:

* **Dataplane (DP)**: The sidecar component that runs alongside your application workload to manage all incoming and outgoing traffic. It provides your service with a secure identity and enforces the networking rules defined by your policies.
* **Control Plane (CP)**: The authoritative management layer responsible for discovering workloads and distributing configuration updates to every Dataplane in the mesh.
* **Kuma Discovery Service (KDS)**: A generalization of Envoy's [xDS protocol](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol) used to synchronize policies and service state between a **Global CP** and its **Zone CPs**.

### Key terms you'll see

These acronyms appear throughout the scenarios, here's the short version:

{% table %}
columns:
  - title: Term
    key: term
  - title: What it means
    key: meaning
rows:
  - term: "**xDS**"
    meaning: "The family of discovery APIs Envoy uses to receive its configuration (listeners, clusters, routes, secrets) from a control plane. The {{site.mesh_product_name}} Zone CP serves xDS to every sidecar."
  - term: "**SPIFFE ID**"
    meaning: "A workload's cryptographic identity, expressed as a URI like `spiffe://kong-air-mesh.mesh.local/ns/<namespace>/sa/<service-account>`. Issued via `MeshIdentity` and used by `MeshTrafficPermission` to authorize traffic."
  - term: "**SNI**"
    meaning: "*Server Name Indication*, the hostname a TLS client requests. {{site.mesh_product_name}} uses it to match traffic to a specific destination (notably `MeshExternalService`) at the zone egress."
  - term: "**KRI**"
    meaning: "*Kuma Resource Identifier*, the canonical `kri_...` name for a resource, seen in fields like a Dataplane's `issuedBackend` (for example `kri_mid_kong-air-mesh___kong-air-identity_`) and in 2.14 Envoy stat names."
  - term: "**DataplaneInsight**"
    meaning: "A read-only status resource the control plane maintains per dataplane. It reports live state such as the mTLS `issuedBackend` and certificate expiry, the go-to object for verifying identity is active."
  - term: "**{{site.konnect_short_name}}**"
    meaning: "Kong's hosted control-plane platform. In a {{site.konnect_short_name}}-managed mesh the **Global CP** runs in {{site.konnect_short_name}} and you apply global resources with `kumactl` or the {{site.konnect_short_name}} UI; Zone CPs still run in your own clusters."
{% endtable %}

{% tip %}
Because {{site.mesh_product_name}} scales across clouds and data centers, knowing *where* each resource is applied (Global vs Zone CP, system namespace) matters. The [Understanding Resource Scoping](/mesh/scenarios/resource-scoping/) guide covers this in depth; it comes right after your first hands-on policies in the learning path below.
{% endtip %}
