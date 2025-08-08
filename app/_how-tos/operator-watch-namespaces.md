---
title: Operator multi-tenancy using watch namespaces
description: "Multi-tenancy with watch namespaces"
content_type: how_to
permalink: /operator/configuration/how-to/watch-namespaces/
breadcrumbs:
  - /operator/
  - index: operator
    group: Operator configuration

products:
  - operator
works_on:
  - on-prem

entities: []

tags:
  - multi-tenancy

tldr:
  q: What is multi-tenancy in the context of {{ site.operator_product_name }}?
  a: An approach allowing multiple instances of the {{ site.operator_product_name }} to share the same underlying infrastructure while keeping their data isolated and more specifically to watch disjoint namespaces.

min_version:
  operator: '2.0'

---

By default, the {{ site.operator_product_name }} watches all namespaces in the cluster.
For most setups this is sufficient but more advanced installations might require some more fine grained control and separation.

This is where operator's watch namespaces come into play.

With couple of simple configuration changes, you can limit the operator's watch to specific namespaces.

## Set the CLI flags / environment variables

{{ site.operator_product_name }} provides several CLI flags to customize the operator's behavior, including the namespaces it watches.

To specify the comma separated list of namespaces to watch you can use the `--watch-namespaces` flag:

```bash
... --watch-namespaces namespace-a,namespace-b ...
```

or an equivalent environment variable: `KONG_OPERATOR_WATCH_NAMESPACES`.

When using the `kong-operator` Helm chart, you can use the `env` top level configuration in your `values.yaml`:

```yaml
env:
  watch_namespace: namespace-a,namespace-b
```

## Controlling the `ControlPlane`'s watch namespaces

It is also possible to further customize the isolation by setting the watch namespaces on `ControlPlane` resources.
To do this refer to [this ControlPlane guide](/operator/konnect/control-plane-watch-namespaces/).

Do note that these 2 options have to be set so that they don't conflict with each other.

When the operator watches namespaces A and B, the `ControlPlane` resource must not define any additional watch namespaces outside of A and B.
If that happens, the `ControlPlane` object will receive an appropriate status condition and will stop to reconcile your configuration.

## Conclusion

With these several simple steps, we've configured the {{ site.operator_product_name }} to watch specific namespaces, enabling a multi-tenancy setup that isolates data and resources effectively.
