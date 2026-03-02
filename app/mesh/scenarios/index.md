---
title: Learning Path
permalink: /mesh/scenarios/

content_type: reference
layout: reference
breadcrumbs:
  - /mesh/
description: A curriculum-style guide to mastering {{site.mesh_product_name}}, from basic concepts to advanced multi-zone operations.
products:
  - mesh
works_on:
  - on-prem
  - konnect
tags:
  - get-started
  - service-mesh
  - quickstart
---

# {{site.mesh_product_name}} Learning Path: The Kong Air Journey

Welcome to the **Kong Air** modernization journey. This curriculum-style guide follows the evolution of a global airline's service mesh, from securing their first "Check-in" API to managing global, multi-cloud flight operations with zero-trust security.

## Phase 1: Fundamentals
Follow Kong Air as they build their foundation, securing their first services and mastering policy targeting.

1.  **[Introduction to {{site.mesh_product_name}}](/mesh/scenarios/introduction/)**: High-level value for every persona.
2.  **[Architecture Overview](/mesh/scenarios/architecture-overview/)**: Control Plane vs. Data Plane and the Envoy proxy.
3.  **[Resource Scoping: Where to Apply Policies](/mesh/scenarios/resource-scoping/)**: Global CP vs. Zone CP ownership and the system namespace rule: read this before applying your first resource.
4.  **[Getting Started: Your First Policy](/mesh/scenarios/getting-started-policy/)**: A hands-on guide to installation and your first mTLS block.
5.  **[How to Use {{site.mesh_product_name}} Policies](/mesh/scenarios/using-policies/)**: Deep dive into the `targetRef` system (To, From, Default).
6.  **[Traffic Splitting with MeshServices](/mesh/scenarios/traffic-splitting-meshservices/)**: Implementing rollouts using the modern resource model.
7.  **[Understanding MeshSubsets](/mesh/scenarios/subsets-and-targeting/)**: Mastering global vs. service-specific targeting.

## Phase 2: Scaling & Security
See how Kong Air protects passenger data and gains visibility into every flight-critical request.

8.  **[Observability in Practice](/mesh/scenarios/observability-in-practice/)**: Metrics, Traces, and Logs.
9.  **[Workload Identity & Trust](/mesh/scenarios/workload-identity/)**: Moving beyond simple mTLS to SPIFFE-based identities.
10. **[External CA & Vault Integration](/mesh/scenarios/external-ca-vault/)**: Roots of trust in enterprise PKI.

## Phase 3: Global Mesh Operations
Connect Kong Air's disparate cloud regions and legacy data centers into a single, unified flight fabric.

11. **[Multi-Zone Architecture](/mesh/scenarios/multi-zone-architecture/)**: ZoneIngress, ZoneEgress, and Global CP sync.
12. **[Multi-Tenancy Strategies](/mesh/scenarios/multi-tenancy-strategies/)**: Sharing a mesh across teams and namespaces.
13. **[Global Canary Releases](/mesh/scenarios/global-canary-releases/)**: Advanced traffic management across regions.
14. **[Global Color Routing](/mesh/scenarios/global-color-routing/)**: Affinity-based routing with full-chain transparency.

## Phase 4: Expert Operations
Advanced patterns for Kong Air's platform engineers to control the perimeter and ensure 24/7 resilience.

15. **[Securing the Perimeter: MeshPassthrough](/mesh/scenarios/mesh-passthrough/)**: Moving to a Default-Deny posture for external traffic.
16. **[First-Class Dependencies: MeshExternalService](/mesh/scenarios/meshexternalservice/)**: Managing external APIs and databases as mesh citizens.
17. **[Ingress mTLS Bridge](/mesh/scenarios/ingress-mtls-bridge/)**: Solving 502s and connection resets in Ingress setups.
18. **[Chaos Engineering: Fault Injection](/mesh/scenarios/chaos-engineering/)**: Proactively testing mesh resilience.
19. **[Advanced Envoy Customization: MeshProxyPatch](/mesh/scenarios/mesh-proxy-patch/)**: The escape hatch for low-level Envoy configuration.

20. **[{{site.mesh_product_name}} vs. Ambient: Beyond Resource Usage](/mesh/scenarios/kong-mesh-vs-ambient/)**: A deep dive into the security and latency trade-offs of sidecarless meshes.
21. **[Istio to {{site.mesh_product_name}}: The Strategic Guide](/mesh/scenarios/istio-to-kong-mesh/)**: Both a technical comparison and a tactical migration roadmap.

---

## Choose Your Persona
Prefer to see the world through your specific job role? Start with our persona-based deep dives:

*   **[Devin the Developer](/mesh/scenarios/persona/developer/)**: Focus on resilience, routing, and APIs.
*   **[Ollie the Operator](/mesh/scenarios/persona/operator/)**: Focus on infrastructure, scale, and multi-zone.
*   **[Sarah the Security Architect](/mesh/scenarios/persona/security/)**: Focus on zero-trust, compliance, and identity.
