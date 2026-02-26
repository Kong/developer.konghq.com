---
title: "{{ site.operator_product_name }} ControlPlane feature gates and controllers"
description: "Configure feature gates and controllers for Kong ControlPlane in {{ site.operator_product_name }}"
content_type: reference
layout: reference
breadcrumbs:
  - /operator/

products:
  - operator

works_on:
  - konnect
  - on-prem

entities: []

min_version:
  operator: '2.0'

related_resources:
  - text: Gateway API reference
    url: /operator/dataplanes/gateway-api/
  - text: Get started with {{ site.operator_product_name }} in {{site.konnect_short_name}}
    url: /operator/get-started/gateway-api/install/
---

This guide explains how to configure feature gates and controllers for a ControlPlane in {{ site.operator_product_name }}. Feature gates (`spec.featureGates`) allow you to enable or disable specific features, while controllers (`spec.controllers`) allow you to enable or disable specific resource reconciliation.

You can use these for the following use cases:

* [Enable Gateway API support](#enable-gateway-api-support)
* [Minimal Ingress-only configuration](#minimal-ingress-only-configuration)
* [Enable experimental features](#enable-experimental-features)

## {{ site.operator_product_name }} feature gates

Feature gates control the availability of features in the ControlPlane. They follow the same concept as [Kubernetes feature gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/).

To configure feature gates, use the `spec.featureGates` field in your ControlPlane resource:

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: my-controlplane
spec:
  featureGates:
  - name: GatewayAlpha
    state: enabled
  - name: FillIDs
    state: enabled
  dataplane:
    type: managedByOwner
```

### Available feature gates

The following feature gates are available:

<!--vale off-->
{% table %}
columns:
  - title: Feature gate
    key: feature
  - title: Default
    key: default
  - title: Description
    key: description
rows:
  - feature: "`GatewayAlpha`"
    default: "`false`"
    description: Enables alpha maturity Gateway API features.
  - feature: "`FillIDs`"
    default: "`true`"
    description: Makes {{site.kic_product_name_short}} fill in ID fields of {{site.base_gateway}} entities (Gateway Services, Routes, Consumers) to ensure stable IDs across restarts.
  - feature: "`RewriteURIs`"
    default: "`false`"
    description: Enables the `konghq.com/rewrite` annotation.
  - feature: "`KongServiceFacade`"
    default: "`false`"
    description: Enables `KongServiceFacade` Custom Resource reconciliation.
  - feature: "`SanitizeKonnectConfigDumps`"
    default: "`true`"
    description: Enables sanitization of {{site.konnect_short_name}} config dumps.
  - feature: "`FallbackConfiguration`"
    default: "`false`"
    description: Enables generating fallback configuration when the {{site.base_gateway}} Admin API returns entity errors.
  - feature: "`KongCustomEntity`"
    default: "`true`"
    description: |
      Enables `KongCustomEntity` Custom Resource reconciliation for custom {{site.base_gateway}} entities.

      {:.info}
      > **Note:** The `KongCustomEntity` feature gate requires `FillIDs` to be enabled, as custom entities require stable IDs for their foreign field references.
{% endtable %}
<!--vale on-->

## {{ site.operator_product_name }} controllers

Controllers determine which Kubernetes resources the ControlPlane will reconcile. You can selectively enable or disable controllers based on your needs.

To configure controllers, use the `spec.controllers` field in your ControlPlane resource:

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: my-controlplane
spec:
  controllers:
  - name: INGRESS_NETWORKINGV1
    state: enabled
  - name: SERVICE
    state: enabled
  - name: KONG_PLUGIN
    state: enabled
  - name: GWAPI_GATEWAY
    state: disabled
  - name: GWAPI_HTTPROUTE
    state: disabled
  dataplane:
    type: managedByOwner
```

### Available {{ site.operator_product_name }} controllers

The following tables describe which controllers are available by product or tool.

#### Ingress controllers

The following Ingress controllers are available in {{ site.operator_product_name }}:
<!--vale off-->
{% table %}
columns:
  - title: Controller name
    key: controller
  - title: Enabled by default
    key: enabled
  - title: Description
    key: description
rows:
  - controller: "`INGRESS_NETWORKINGV1`"
    enabled: "Yes"
    description: Manages Kubernetes Ingress resources (networking/v1).
  - controller: "`INGRESS_CLASS_NETWORKINGV1`"
    enabled: "Yes"
    description: Manages Kubernetes IngressClass resources (networking/v1).
  - controller: "`INGRESS_CLASS_PARAMETERS`"
    enabled: "Yes"
    description: Manages IngressClass parameters.
{% endtable %}
<!--vale on-->

#### {{site.base_gateway}} controllers

The following {{site.base_gateway}} controllers are available in {{ site.operator_product_name }}:
<!--vale off-->
{% table %}
columns:
  - title: Controller name
    key: controller
  - title: Enabled by default
    key: enabled
  - title: Description
    key: description
rows:
  - controller: "`KONG_CLUSTERPLUGIN`"
    enabled: "Yes"
    description: Manages Kong cluster-scoped plugin resources.
  - controller: "`KONG_PLUGIN`"
    enabled: "Yes"
    description: Manages Kong plugin resources.
  - controller: "`KONG_CONSUMER`"
    enabled: "Yes"
    description: Manages Kong consumer resources.
  - controller: "`KONG_UPSTREAM_POLICY`"
    enabled: "Yes"
    description: Manages Kong upstream policy resources.
  - controller: "`KONG_SERVICE_FACADE`"
    enabled: "Yes"
    description: Manages Kong service facade resources.
  - controller: "`KONG_VAULT`"
    enabled: "Yes"
    description: Manages Kong vault resources.
  - controller: "`KONG_LICENSE`"
    enabled: "Yes"
    description: Manages Kong license resources.
  - controller: "`KONG_CUSTOM_ENTITY`"
    enabled: "Yes"
    description: Manages Kong custom entity resources.
{% endtable %}
<!--vale on-->


#### Kubernetes core controllers

The following kubernetes core controllers are available in {{ site.operator_product_name }}:
<!--vale off-->
{% table %}
columns:
  - title: Controller name
    key: controller
  - title: Enabled by default
    key: enabled
  - title: Description
    key: description
rows:
  - controller: "`SERVICE`"
    enabled: "Yes"
    description: Manages Kubernetes Service resources.
{% endtable %}
<!--vale on-->

#### Gateway API controllers

The following Gateway API controllers are available in {{ site.operator_product_name }}:
<!--vale off-->
{% table %}
columns:
  - title: Controller name
    key: controller
  - title: Enabled by default
    key: enabled
  - title: Description
    key: description
rows:
  - controller: "`GWAPI_GATEWAY`"
    enabled: "Yes"
    description: Manages Gateway API Gateway resources.
  - controller: "`GWAPI_HTTPROUTE`"
    enabled: "Yes"
    description: Manages Gateway API HTTPRoute resources.
  - controller: "`GWAPI_GRPCROUTE`"
    enabled: "Yes"
    description: Manages Gateway API GRPCRoute resources.
  - controller: "`GWAPI_REFERENCE_GRANT`"
    enabled: "Yes"
    description: Manages Gateway API ReferenceGrant resources.
{% endtable %}
<!--vale on-->

## Validate your feature gate and controller configuration

You can verify your configuration by checking the ControlPlane status:

```bash
kubectl get controlplane my-controlplane -o jsonpath='{.status}' | jq .
```

The status will show which feature gates and controllers are active.


## {{ site.operator_product_name }} feature gate and controller use case examples

The following sections provide examples using feature gates and controllers for common use cases.

### Enable Gateway API support

Use the following example to enable full Gateway API support:

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: gateway-api-controlplane
spec:
  featureGates:
  - name: GatewayAlpha
    state: enabled
  controllers:
  - name: GWAPI_GATEWAY
    state: enabled
  - name: GWAPI_HTTPROUTE
    state: enabled
  - name: GWAPI_GRPCROUTE
    state: enabled
  - name: GWAPI_REFERENCE_GRANT
    state: enabled
  dataplane:
    type: managedByOwner
```

### Minimal Ingress-only configuration

Use the following example for a minimal setup that only manages Ingress resources:

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: ingress-only-controlplane
spec:
  controllers:
  - name: INGRESS_NETWORKINGV1
    state: enabled
  - name: INGRESS_CLASS_NETWORKINGV1
    state: enabled
  - name: SERVICE
    state: enabled
  # Disable all other controllers
  - name: KONG_PLUGIN
    state: disabled
  - name: KONG_CONSUMER
    state: disabled
  - name: GWAPI_GATEWAY
    state: disabled
  - name: GWAPI_HTTPROUTE
    state: disabled
  dataplane:
    type: managedByOwner
```

### Enable experimental features

Use the following example to enable experimental features like URI rewriting and fallback configuration:

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: experimental-controlplane
spec:
  featureGates:
  - name: RewriteURIs
    state: enabled
  - name: FallbackConfiguration
    state: enabled
  - name: KongServiceFacade
    state: enabled
  dataplane:
    type: managedByOwner
```
