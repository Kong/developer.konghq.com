---
title: "Managed Gateways"
description: "Learn how {{ site.gateway_operator_product_name }} reconciles `Gateway` resources, automatically configuring listeners as needed"
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

{{ site.gateway_operator_product_name }} reconciles `Gateway` resources differently to {{ site.kic_product_name }}. {{ site.gateway_operator_product_name }}'s approach is known as _managed_ gateways, and the {{ site.kic_product_name }} approach is referred to as [_unmanaged_ gateways](/kubernetes-ingress-controller/gateway-api/#unmanaged-gateways).

When {{ site.gateway_operator_product_name }} detects a new `Gateway`, it creates a `ControlPlane` ({{ site.kic_product_name }}) and a `DataPlane` ({{ site.base_gateway }}). This `ControlPlane` reconciles exactly one `Gateway`.

As {{ site.gateway_operator_product_name }} manages the lifecycle of {{ site.base_gateway }} deployments, it can dynamically configure the `DataPlane` based on information in the `Gateway` listeners.

For example, when creating a Gateway with only one HTTP listener on port 80, the `DataPlane` ingress service will be configured so that only port 80 will be exposed. If you add a `Gateway` HTTPS listener on port 443, this change will be taken by {{ site.gateway_operator_product_name }} and applied to the `DataPlane`. The final result will be an ingress service exposing ports 80 for HTTP traffic and 443 for HTTPS traffic.

{:.info}
> Ports 80 and 443 are examples. You can configure any combination of `Gateway` listeners that you need, and {{ site.gateway_operator_product_name }} will configure your `DataPlane` appropriately.
