---
title: "Multi-tenancy"
description: "Understand how to run multiple isolated {{ site.base_gateway }} instances on the same Kubernetes cluster using {{ site.operator_product_name }}."
content_type: reference
layout: reference

breadcrumbs:
  - /operator/
  - index: operator
    group: Reference

products:
  - operator

works_on:
  - on-prem

min_version:
  operator: '1.6'

related_resources:
  - text: "Deploy multiple isolated gateways on the same cluster"
    url: /operator/dataplanes/how-to/multi-tenancy/setup/
  - text: "{{site.operator_product_name}} architecture"
    url: /operator/reference/architecture/
  - text: "Limiting namespaces watched by ControlPlane"
    url: /operator/reference/control-plane-watch-namespaces/
  - text: "Gateway configuration"
    url: /operator/dataplanes/gateway-configuration/
  - text: "Managed Gateways"
    url: /operator/dataplanes/managed-gateways/
  - text: "Custom Resources"
    url: /operator/reference/custom-resources/
---

Multi-tenancy in {{ site.operator_product_name }} means running multiple isolated {{ site.base_gateway }} instances — each with their own routing configuration, data plane, and namespace scope — on the same Kubernetes cluster, managed by a single {{ site.operator_product_name }} installation.

Common use cases include separating a public-facing API gateway from an internal one, or giving different teams independent gateway instances without requiring separate clusters. For a step-by-step walkthrough, see [Deploy multiple isolated gateways](/operator/dataplanes/how-to/multi-tenancy/setup/).

## How it works

Each tenant is represented by a `Gateway`, provisioned using three resources:

* `GatewayConfiguration`: A Kong-specific resource that configures the control plane and data plane options for a gateway, such as the proxy image, environment variables, and namespace watch scope.
* `GatewayClass`: A cluster-scoped Gateway API resource that registers {{ site.operator_product_name }} as the controller for gateways of this class. It references the `GatewayConfiguration` via `parametersRef`.
* `Gateway`: A namespaced Gateway API resource that declares a gateway instance. It references the `GatewayClass` via `gatewayClassName`, which is how {{ site.operator_product_name }} associates it with the correct `GatewayConfiguration`.

For each `Gateway`, {{ site.operator_product_name }} creates:

* One in-memory {{ site.kic_product_name_short }} instance embedded inside the {{ site.operator_product_name }} Pod, which watches Gateway API resources and translates them into Kong configuration.
* One data plane deployment running {{ site.base_gateway }} in DB-less mode.

Multiple `Gateway` resources can coexist in the same cluster. The resulting in-memory {{ site.kic_product_name_short }} instances and data plane Pods are independent of each other. A single {{ site.operator_product_name }} installation manages them all.

## Namespace isolation

By default, each in-memory {{ site.kic_product_name_short }} instance watches all namespaces for Gateway API resources (`HTTPRoute`, `GRPCRoute`, etc.). Without additional configuration, one tenant's {{ site.kic_product_name_short }} would also process another tenant's routes, so namespace isolation is required for multi-tenancy.

Set `watchNamespaces` on `GatewayConfiguration.spec.controlPlaneOptions` to restrict each gateway's in-memory {{ site.kic_product_name_short }} to its own namespace. For the full field reference, type options, `WatchNamespaceGrant` configuration, and operator-level scoping, see [Limiting namespaces watched by ControlPlane](/operator/reference/control-plane-watch-namespaces/).