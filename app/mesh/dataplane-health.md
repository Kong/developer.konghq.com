---
title: "{{site.mesh_product_name}} data plane health"
description: Learn about health mechanisms in {{site.mesh_product_name}} including circuit breakers, Service probes, and health checks for managing traffic based on Service health.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
min_version:
  mesh: '2.6'

related_resources:
  - text: Control plane configuration
    url: /mesh/control-plane-configuration/
  - text: Observability
    url: /mesh/observability/
---

{{site.mesh_product_name}} can use health status to select endpoints for communication between data plane proxies.
Orchestrators, such as Kubernetes, use Service health status to manage container lifecycles.

{{site.mesh_product_name}} supports several mechanisms to regulate traffic based on the health of a Service:

* The [`MeshCircuitBreaker`](/mesh/policies/meshcircuitbreaker/) policy: A passive {{site.mesh_product_name}} policy that configures a data plane proxy to monitor its existing mesh traffic in order to evaluate the data plane health. The data plane can be configured to respond to a wide range of errors and events that it may detect during communication with remote endpoints.

* The [`MeshHealthCheck`](/mesh/policies/meshhealthcheck/) policy: An active {{site.mesh_product_name}} policy that configures a data plane proxy to send extra traffic to other data plane proxies in order to evaluate their health. In some meshes, health checks can be useful for specific Routes which are not frequently used, but still need to detect failures quickly.

* Service probes: A configuration of centralized health probing of Services, either directly by the {{site.mesh_product_name}} control plane, or by the underlying platform, such as Kubernetes. This approach detects problems from the control plane's perspective and propagates failures across the entire mesh. However, centralized health probing requires the control plane to be available. This differs from policies, which operate independently on the data plane.
