---
title: "Gateway configuration"
description: "Customize your {{ site.base_gateway }} deployments when using the Gateway resource"
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

{{ site.operator_product_name }} provides a `GatewayConfiguration` CRD to customise the deployment of `ControlPlane` and `DataPlane` resources.

These customizations are primarily used to set the container image and any environment variables that are required by the containers.

See the following examples of how to use `GatewayConfiguration`:

- [Customize the DataPlane image](/operator/dataplanes/how-to/set-dataplane-image/)
- [Deploy a sidecar container](/operator/dataplanes/how-to/deploy-sidecars/)

For more information about `GatewayConfiguration` see the [GatewayConfiguration CRD reference](/operator/reference/custom-resources/#gatewayconfiguration).
