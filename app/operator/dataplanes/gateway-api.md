---
title: "Gateway API"
description: "Understand how {{ site.operator_product_name }} interacts with Gateway API resources"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Key Concepts

---

Both {{ site.operator_product_name }} and [{{ site.kic_product_name }}](/kubernetes-ingress-controller/) can be configured using the [Kubernetes Gateway API](https://github.com/kubernetes-sigs/gateway-api). Configure your vendor-independent `GatewayClass` and `Gateway` objects, and {{ site.operator_product_name }} translates those requirements into Kong specific configuration.

When using [managed gateways](/operator/dataplanes/managed-gateways/), {{ site.operator_product_name }} watches for `GatewayClass` resources where the `spec.controllerName` is `konghq.com/gateway-operator`. When a `Gateway` resource is detected, {{ site.operator_product_name }} creates a `ControlPlane` (an in memory instance of {{ site.kic_product_name }}) and a `DataPlane` ({{ site.base_gateway }}).

You can configure traffic routing using Gateway API resources such as `HTTPRoute`, `GRPCRoute`, `TCPRoute` and `UDPRoute`. These resources are translated into Kong configuration objects by {{ site.kic_product_name }} which proxies traffic to your internal services through {{ site.base_gateway }}.
