---
title: "LabelSelectors"
description: "Use label selectors to limit which Secrets and ConfigMaps are reconciled, reducing the number of objects cached by {{ site.operator_product_name }}"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment

min_version:
  operator: '2.0'
---

There can be many `Secrets `and `ConfigMaps` in the cluster, but only a few are actually used by {{ site.operator_product_name }}. To reduce the number of `Secret`s and `ConfigMap`s taken into reconciliation for reducing the memory cost,
{{ site.operator_product_name }} supports to set label selectors to limit the `Secret`s and `ConfigMap`s to reconcile.

## {{ site.operator_product_name }} level label selectors

{{ site.operator_product_name }} allows you to set label selectors for `Secret`s and `ConfigMap`s globally using the CLI flags `--secret-label-selector` and `--config-map-label-selector`.

`Secrets`:
  * When `--secret-label-selector` is not empty, only secrets that have a label matching the key specified in `--secret-label-selector` **and** with the value `"true"` will be reconciled by {{ site.operator_product_name }}.
  * This filter applies to all secrets reconciled by any controllers spawned for `ControlPlane`s.
  * By default, `--secret-label-selector` is set to `konghq.com/secret`.

`ConfigMaps`
  * Similarly, only configMaps that have a label matching the key specified in `--config-map-label-selector` **and** with the value `"true"` will be reconciled if the flag is set.
  * By default, `--config-map-label-selector` is set to `konghq.com/configmap`.

{:.success}
> For example, if the  `--secret-label-selector` is set to `konghq.com/secret`, you need to add the label `konghq.com/secret=true` for you cluster CA secret to get it reconciled by {{ site.operator_product_name }}.
Otherwise {{ site.operator_product_name }} cannot find the secret in its cached client then the deployment of {{site.base_gateway}} cannot continue.

## Label selectors per ControlPlane

The `ControlPlane` CRD also supports configuring label selectors of reconciled `Secret`s and `ConfigMap`s by `spec.objectFilters.secrets.matchLabels` and `spec.objectFilters.configMaps.matchLabels`.

For example, the `ControlPlane` is configured to reconcile only secrets with the label `kong-cp-secret` set to `true`:

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: controlplane-v2-label-selector-example
spec:
  ingressClass: kong
  dataplane:
    type: ref
    ref:
      name: dataplane-name
  featureGates:
  - name: GatewayAlpha
    state: enabled
  controllers:
  - name: Konnect
    state: enabled
  objectFilters:
    secrets:
      matchLabels:
        kong-cp-secret: "true"
```

Only the secrets with the label `kong-cp-secret` set to "true" are reconciled by the controller spawned for the `ControlPlane`. If the `--secret-label-selector` is also configured in the {{ site.operator_product_name }},
the secrets must also set the label in `--secret-label-selector` set to `true` to get reconciled by the controller.

### Conflicts with {{ site.operator_product_name }} level label selectors

If the label selectors configured in the `ControlPlane` include the same key as configured in {{ site.operator_product_name }}, it is considered as a conflict.

In this scenario, the controllers cannot be started for the `ControlPlane`. The `ControlPlane`'s status will be updated to include a `OptionsValid` condition set to `False` with the message to indicate that the conflict of label selectors happens.
