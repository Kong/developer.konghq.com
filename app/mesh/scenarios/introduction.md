---
title: Introduction
content_type: reference
layout: reference
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: A beginner-friendly introduction to {{site.mesh_product_name}}, detailing its value for developers, operators, and security teams through powerful Mesh policies.
products:
  - mesh
next_steps:
  - text: "Architecture Overview"
    url: "/mesh/scenarios/architecture-overview/"
---
{{site.mesh_product_name}} is an enterprise-grade service mesh that provides a unified control plane to manage services across Kubernetes, VMs, and bare metal. Unlike traditional meshes that require complex, platform-specific configurations, {{site.mesh_product_name}} offers a simplified, policy-driven approach that works identically regardless of your underlying infrastructure.

## The Kong Air Journey

Throughout these scenarios, we will follow the journey of **Kong Air**, a global airline modernizing its flight-critical infrastructure. You will step into the shoes of the platform team as they transform a fragmented application landscape, consisting of legacy flight booking engines on VMs and new check-in services on Kubernetes, into a resilient, secure global mesh.

By providing these capabilities as a standardized, built-in management layer, {{site.mesh_product_name}} eliminates the operational overhead of manually implementing complex networking features. This approach delivers the power of a global mesh with a level of operational simplicity that avoids the steep learning curves and heavy boilerplate often found in other solutions, allowing teams like Kong Air to focus on traveler experiences.

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

Before you dive into the hands-on scenarios, familiarize yourself with these three core components:

* **Dataplane (DP)**: The sidecar component that runs alongside your application workload to manage all incoming and outgoing traffic. It provides your service with a secure identity and enforces the networking rules defined by your policies.
* **Control Plane (CP)**: The authoritative management layer responsible for discovering workloads and distributing configuration updates to every Dataplane in the mesh.
* **Kuma Distribution Service (KDS)**: The high-speed protocol used to synchronize policies and service state between a **Global CP** and its **Zone CPs**.

{% tip %}
**Getting Started**: Because Kong Mesh scales across clouds and data centers, understanding where to apply each resource is critical. We strongly recommend reading the [Understanding Resource Scoping](/mesh/scenarios/resource-scoping/) guide before applying your first policy.
{% endtip %}
