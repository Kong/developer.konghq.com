---
title: "Limiting namespaces watched by ControlPlane"
description: "Learn how to limit the namespaces that ControlPlane watches."
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: "Konnect CRDs: Control Planes"
related_resources:
  - text: "Create a Control Plane with KGO"
    url: /operator/konnect/crd/control-planes/hybrid/

min_version:
  operator: '1.6'
---

By default, {{ site.kgo_product_name }}'s `ControlPlane` watches all namespaces.
This provides a convenient out-of-the-box experience but may not suit all production environments, especially those where multiple teams share the same cluster or in multi-tenant setups.

To limit the namespaces watched by `ControlPlane`, you can set the `watchNamespaces` field in the `ControlPlane`'s `spec`.

## ControlPlane's watchNamespaces field

The `spec.watchNamespaces.type` field accepts three values to control this behavior:

- `all` (default): Watches resources in all namespaces.
- `own`: Watches resources only in the `ControlPlane`'s own namespace.
- `list`: Watches resources in the `ControlPlane`'s own namespace and in the specified list of additional namespaces.
  When using `list`, the `ControlPlane`'s own namespace is automatically added to the list of watched namespaces, because this behavior is required by {{ site.kic_product_name }}.  
  By default, the publish service (the `Service` for the `DataPlane`, exposed by {{ site.base_gateway }}) is created in the same namespace as the `ControlPlane`.

{:.info}
> **Note:** Setting this field in `ControlPlane` will configure the `CONTROLLER_WATCH_NAMESPACE` environment variable in the managed {{ site.kic_product_name }}.
> If you manually set the `CONTROLLER_WATCH_NAMESPACE` environment variable through `podTemplateSpec`, it will **override** this configuration.

The `all` and `own` types don't require any further changes or additional resources. The `list` type requires further configuration.

## Specify a list of namespaces to watch

The `list` type requires two additional steps:

1. Specify the namespaces to watch in the `spec.watchNamespaces.list` field.
   ```yaml
   spec:
     watchNamespaces:
       type: list
        list:
        - namespace-a
        - namespace-b
   ```

1. Create a `WatchNamespaceGrant` resource in each of the specified namespaces. This resource grants the `ControlPlane` permission to watch resources in the specified namespace. It can be defined as:

   ```yaml
   apiVersion: gateway-operator.konghq.com/v1alpha1
   kind: WatchNamespaceGrant
   metadata:
     name: watch-namespace-grant
     namespace: namespace-a
   spec:
     from:
     - group: gateway-operator.konghq.com
       kind: ControlPlane
       namespace: control-plane-namespace
   ```

For more information on the `WatchNamespaceGrant` CRD, see the [CRD reference](/operator/reference/custom-resources/#watchnamespacegrant).
