---
title: "LabelSelectors"
description: "Label selectors to filter reconciled secrets and configMaps to reduce number of cached objects"
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

The number of `Secret`s and `ConfigMap`s could be very large, but there may be only a small amount of them are
used in {{ site.operator_product_name }}. To reduce the number of `Secret`s and `ConfigMap`s taken into reconciliation for reducing the memory cost,
{{ site.operator_product_name }} supports to set label selectors to limit the `Secret`s and `ConfigMap`s to reconcile.

## {{ site.operator_product_name }} Level Label Selectors

{{ site.operator_product_name }} supports to set label selectors for `Secret`s and `ConfigMap`s globally by CLI flags `--secret-label-selector` and `--config-map-label-selector`.
When the `--secret-label-selector` is not empty, ALL secrets must have the label with the key specified in `--secret-label-selector` set to "true" to be reconciled by {{ site.operator_product_name }}.
The filter also applies on the secrets reconciled by all the controllers spawned for `ControlPlane`s. The `--secret-label-selector` is set to `konghq.com/secret` by default.
Similarly, only configMaps with label `--config-map-label-selector` set to "true" are reconciled if the flag is not empty.  `--config-map-label-selector` is set to `konghq.com/configmap` by default.

For example, if the  `--secret-label-selector` is set to `konghq.com/secret`, you need to add the label `konghq.com/secret=true` for you cluster CA secret to get it reconciled by {{ site.operator_product_name }}.
Otherwise {{ site.operator_product_name }} cannot find the secret in its cached client then the deployment of {{site.base_gateway}} cannot continue.

## Label Selectors per ControlPlane

The `ControlPlane` CRD also supports configuring label selectors of reconciled `Secret`s and `ConfigMap`s by `spec.objectFilters.secrets.matchLabels` and `spec.objectFilters.configMaps.matchLabels`.
For example, the `ControlPlane` is configured to reconcile only secrets with the label `kong-cp-secret` set to "true":

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
the secrets must also set the label in `--secret-label-selector` set to "true" to get reconciled by the controller.

### Conflicts with {{ site.operator_product_name }} Level Label Selectors

If the label selectors configured in the `ControlPlane` include the same key as configured in {{ site.operator_product_name }}, it is considered as a conflict.
In this scenario, the controllers cannot be started for the `ControlPlane`. The `ControlPlane`'s status will be updated to include a `OptionsValid` condition set to `False` with the message to indicate that the conflict of label selectors happens.  
