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

related_resources:
  - text: "Multi-tenancy"
    url: /operator/reference/multi-tenancy/
  - text: "Deploy multiple isolated gateways"
    url: /operator/dataplanes/how-to/multi-tenancy/setup/
  - text: "{{site.operator_product_name}} architecture"
    url: /operator/reference/architecture/
---

By default, {{ site.operator_product_name }}'s `ControlPlane` watches all namespaces. This provides a convenient out-of-the-box experience but may not suit production environments where multiple teams share the same cluster.

You can restrict namespace watching in two ways depending on how you manage your gateways:

* *Managed Gateways (Gateway API flow): Set `watchNamespaces` via `GatewayConfiguration.spec.controlPlaneOptions`. You do not create a `ControlPlane` directly. See [Multi-tenancy](/operator/reference/multi-tenancy/) for the full use case.
* Direct `ControlPlane` management: Set `watchNamespaces` directly in the `ControlPlane`'s `spec`.

## watchNamespaces types

The `watchNamespaces.type` field accepts three values:

* `all` (default): Watches resources in all namespaces.
* `own`: Watches resources only in the `ControlPlane`'s own namespace.
* `list`: Watches resources in the `ControlPlane`'s own namespace and in a specified list of additional namespaces. The `ControlPlane`'s own namespace is automatically included, as required by {{ site.kic_product_name }}.

{:.info}
> The `watchNamespaces` setting configures the `CONTROLLER_WATCH_NAMESPACE` environment variable in the managed {{ site.kic_product_name_short }}. If you set this variable manually through `podTemplateSpec`, it will override the `watchNamespaces` field.

The `all` and `own` types don't require any further changes or additional resources. The `list` type requires further configuration.

## Specify a list of namespaces to watch

The `list` type requires two additional steps:

1. Specify the namespaces to watch in the `spec.watchNamespaces.list` field:

   ```yaml
   spec:
     watchNamespaces:
       type: list
       list:
       - namespace-a
       - namespace-b
   ```

1. Create a `WatchNamespaceGrant` resource in each of the specified namespaces. This resource grants the `ControlPlane` permission to watch resources in that namespace:

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

## Operator-level namespace scoping {% new_in 2.0 %}

From v2.0, you can scope {{ site.operator_product_name }} itself to watch only specific namespaces. This is separate from the per-`ControlPlane` `watchNamespaces` configuration and is useful when running multiple {{ site.operator_product_name }} instances on the same cluster with strictly disjoint namespace assignments.

{:.warning}
> If you configure watch namespaces on both {{ site.operator_product_name }} and `ControlPlane` resources, they must not conflict. For example, if {{ site.operator_product_name }} watches namespaces A and B, the `ControlPlane` can only define watch namespaces A or B. Using namespace C would cause the `ControlPlane` to receive a failure status condition and stop reconciling.

You can set watch namespaces for {{ site.operator_product_name }} using several methods:

{% navtabs "multi-tenant-namespaces" %}
{% navtab "Helm chart" %}
When using the `kong-operator` Helm chart, use the `env` top-level configuration in your `values.yaml`:

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
Use the `--watch-namespaces` flag with a comma-separated list of namespaces:

```bash
... --watch-namespaces namespace-a,namespace-b ...
```
{% endnavtab %}
{% endnavtabs %}
