---
title: "Limiting namespaces watched by ControlPlane"
description: "Learn how to limit the namespaces that ControlPlane watches."
content_type: reference
layout: reference

breadcrumbs:
  - /operator/
  - index: operator
    group: Security hardening

products:
  - operator

min_version:
  operator: '1.6'
---

By default, {{ site.operator_product_name }}'s `ControlPlane` watches all namespaces.
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

## Multi-tenancy using watch namespaces {% new_in 2.0 %}

Multi-tenancy, in the context of {{ site.operator_product_name }}, is an approach that allows multiple instances of the {{ site.operator_product_name }} to share the same underlying infrastructure while keeping their data isolated and more specifically to watch disjoint namespaces.

This allows you to configure {{ site.operator_product_name }} itself to watch namespaces instead of always specifying them in the `ControlPlane` resources.

{:.warning}
> **Important:** If you configure watch namespaces on both {{ site.operator_product_name }} and `ControlPlane` resources, they must be configured so that they don't conflict. For example, if the {{ site.operator_product_name }} watches namespaces A and B, the `ControlPlane` resource can only define watch namespaces A and B. If you use other watch namespaces, such as namespace C, the `ControlPlane` object will receive an appropriate status condition and won't reconcile your configuration.

You can set watch namespaces for {{ site.operator_product_name }} using several methods:

{% navtabs "multi-tenant-namespaces" %}
{% navtab "Helm chart" %}
When using the `kong-operator` Helm chart, you can use the `env` top level configuration in your `values.yaml`:

```yaml
env:
  watch_namespace: namespace-a,namespace-b
```
{% endnavtab %}
{% navtab "Env var" %}
```sh
KONG_OPERATOR_WATCH_NAMESPACES='namespace-a,namespace-b'
```
{% endnavtab %}
{% navtab "CLI" %}
To specify the comma separated list of namespaces to watch you can use the `--watch-namespaces` flag:

```bash
... --watch-namespaces namespace-a,namespace-b ...
```
{% endnavtab %}
{% endnavtabs %}





