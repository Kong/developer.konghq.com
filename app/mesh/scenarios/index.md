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

Welcome to the **Kong Air** modernization journey. This guide follows the evolution of a global airline's service mesh adoption, from securing their first "check-in" API to operating a global, multi-cloud flight platform with zero-trust security.

Work through the scenarios in order, each builds on the last, or jump to the phase that matches what you're doing today.

## Phase 1: Fundamentals
Build the foundation: understand the architecture, secure your first services, and master policy targeting.

1.  **[Introduction to {{site.mesh_product_name}}](/mesh/scenarios/introduction/)**: High-level overview, and how these scenarios are organized.
2.  **[Architecture Overview](/mesh/scenarios/architecture-overview/)**: Control Plane vs. Data Plane, the Envoy proxy, and how they fit together.
3.  **[Getting Started: Your First Policy](/mesh/scenarios/getting-started-policy/)**: Workload identity with `MeshIdentity`, strict mTLS, and your first default-deny authorization.
4.  **[How to Use {{site.mesh_product_name}} Policies](/mesh/scenarios/using-policies/)**: The `targetRef` system, `to`, `rules`, `default`, and policy precedence.
5.  **[Understanding Resource Scoping](/mesh/scenarios/resource-scoping/)**: Global CP vs. Zone CP ownership and the Kubernetes system-namespace rule.
6.  **[Traffic Splitting with MeshServices](/mesh/scenarios/traffic-splitting-meshservices/)**: Weighted v1/v2 rollouts using explicit `MeshService` resources.
7.  **[Targeting Workloads and Services](/mesh/scenarios/subsets-and-targeting/)**: `Dataplane` label selectors vs. explicit `MeshService` targeting.

## Phase 2: Observability & Security
See how Kong Air gains visibility into every flight-critical request and protects passenger data.

8.  **[Observability in Practice](/mesh/scenarios/observability-in-practice/)**: Metrics, traces, logs, and the Grafana dashboards.
9.  **[Workload Identity & mTLS Evolution](/mesh/scenarios/workload-identity/)**: SPIFFE-based identity with `MeshIdentity` and `MeshTrust`.
10. **[Enterprise PKI: External CA Integration](/mesh/scenarios/external-ca-vault/)**: Rooting trust in Vault, cert-manager, or ACM Private CA.

## Phase 3: Global Mesh Operations
Connect Kong Air's cloud regions and legacy data centers into a single mesh.

11. **[Multi-Zone Architecture](/mesh/scenarios/multi-zone-architecture/)**: ZoneIngress, ZoneEgress, service federation, and Global/Zone CP sync.
12. **[Mesh-Scoped Zone Proxies](/mesh/scenarios/mesh-scoped-zone-proxies/)**: Per-mesh zone proxies via the Helm `meshes:` list (new in 2.14).
13. **[Global Routing: Canary Rollouts and Color Rings](/mesh/scenarios/global-routing/)**: Weighted canary rollouts and permanent color rings across zones with `MeshMultiZoneService`.

## Phase 4: Expert Operations
Advanced patterns for controlling the perimeter and integrating external dependencies.

14. **[Securing the Perimeter: MeshPassthrough](/mesh/scenarios/mesh-passthrough/)**: Move to a default-deny posture for outbound traffic.
15. **[First-Class Dependencies: MeshExternalService](/mesh/scenarios/meshexternalservice/)**: Manage external APIs and databases as mesh citizens.
16. **[Chaos Engineering: Fault Injection](/mesh/scenarios/chaos-engineering/)**: Proactively test mesh resilience with `MeshFaultInjection`.

## Explore by role
Prefer a role-based view? Each persona guide maps the scenarios to what that team owns:

- **[Devin the Developer](/mesh/scenarios/persona/developer/)**, routing, resilience, and observability for application teams.
- **[Ollie the Operator](/mesh/scenarios/persona/operator/)**, control plane, zone proxies, gateways, and observability-as-a-service.
- **[Sarah the Security Architect](/mesh/scenarios/persona/security/)**, zero-trust, workload identity, and egress control.
