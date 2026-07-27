---
title: Learning path
permalink: /mesh/scenarios/
content_type: reference
layout: reference
description: A curriculum-style guide to mastering {{site.mesh_product_name}}, from basic concepts to advanced multi-zone operations.
breadcrumbs:
  - /mesh/
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

Welcome to the **Kong Air** modernization journey. This guide follows the evolution of a global airline's service mesh adoption, from securing their first "check-in" API to operating a global, multi-cloud flight platform with zero-trust security.

Work through the scenarios in order, each builds on the last, or jump to the phase that matches what you're doing today.

## Phase 1: Fundamentals
Build the foundation: understand the architecture, secure your first services, and master policy targeting.

1.  **[Introduction](/mesh/scenarios/introduction/)**: High-level overview, and how these scenarios are organized.
2.  **[Architecture overview](/mesh/scenarios/architecture-overview/)**: Control Plane vs. Data Plane, the Envoy proxy, and how they fit together.
3.  **[Get started with your first policy](/mesh/scenarios/get-started-with-your-first-policy/)**: Workload identity with `MeshIdentity`, strict mTLS, and your first default-deny authorization.
4.  **[Policy targeting and precedence](/mesh/scenarios/policy-targeting-and-precedence/)**: The `targetRef` system, `to`, `rules`, `default`, and policy precedence.
5.  **[Resource scoping](/mesh/scenarios/resource-scoping/)**: Global CP vs. Zone CP ownership and the Kubernetes system-namespace rule.
6.  **[Split traffic with MeshService resources](/mesh/scenarios/split-traffic-with-meshservice-resources/)**: Weighted v1/v2 rollouts using explicit `MeshService` resources.
7.  **[Target workloads and services](/mesh/scenarios/target-workloads-and-services/)**: `Dataplane` label selectors vs. explicit `MeshService` targeting.

## Phase 2: Observability & security
See how Kong Air gains visibility into every flight-critical request and protects passenger data.

8.  **[Observe mesh traffic in practice](/mesh/scenarios/observe-mesh-traffic-in-practice/)**: Metrics, traces, logs, and the Grafana dashboards.
9.  **[Manage workload identity and mTLS](/mesh/scenarios/manage-workload-identity-and-mtls/)**: SPIFFE-based identity with `MeshIdentity` and `MeshTrust`.
10. **[Integrate an external CA](/mesh/scenarios/integrate-an-external-ca/)**: Rooting trust in Vault, cert-manager, or ACM Private CA.

## Phase 3: Global mesh operations
Connect Kong Air's cloud regions and legacy data centers into a single mesh.

11. **[Multi-zone architecture](/mesh/scenarios/multi-zone-architecture/)**: ZoneIngress, ZoneEgress, service federation, and Global/Zone CP sync.
12. **[Configure mesh-scoped zone proxies](/mesh/scenarios/configure-mesh-scoped-zone-proxies/)**: Per-mesh zone proxies via the Helm `meshes:` list (new in 2.14).
13. **[Route across zones with canary rollouts and color rings](/mesh/scenarios/route-across-zones-with-canary-rollouts-and-color-rings/)**: Weighted canary rollouts and permanent color rings across zones with `MeshMultiZoneService`.

## Phase 4: Expert operations
Advanced patterns for controlling the perimeter and integrating external dependencies.

14. **[Secure the perimeter with MeshPassthrough](/mesh/scenarios/secure-the-perimeter-with-meshpassthrough/)**: Move to a default-deny posture for outbound traffic.
15. **[Manage external services with MeshExternalService](/mesh/scenarios/manage-external-services-with-meshexternalservice/)**: Manage external APIs and databases as mesh citizens.
16. **[Validate resilience with fault injection](/mesh/scenarios/validate-resilience-with-fault-injection/)**: Proactively test mesh resilience with `MeshFaultInjection`.

## Explore by role
Prefer a role-based view? Each persona guide maps the scenarios to what that team owns:

- **[Devin the Developer](/mesh/scenarios/persona/developer/)**, routing, resilience, and observability for application teams.
- **[Ollie the Operator](/mesh/scenarios/persona/operator/)**, control plane, zone proxies, gateways, and observability-as-a-service.
- **[Sarah the Security Architect](/mesh/scenarios/persona/security/)**, zero-trust, workload identity, and egress control.
