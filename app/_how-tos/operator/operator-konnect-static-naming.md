---
title: Enable static naming for {{site.konnect_short_name}} control planes with {{site.operator_product_name}}
description: "Ensure your {{site.konnect_short_name}} control planes use predictable names to support references from other resources."
content_type: how_to

permalink: /operator/konnect/how-to/static-naming/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

products:
  - operator

works_on:
  - konnect

tldr:
  q: How do I give my {{site.konnect_short_name}} control plane a predictable name?
  a: |
    Add the `gateway-operator.konghq.com/static-naming: "true"` annotation to your `Gateway` resource. 

min_version:
  operator: '2.1'

prereqs:
  operator:
    konnect:
      auth: true
---

By default, {{ site.operator_product_name }} generates unique, dynamic names for `KonnectGatewayControlPlane` resources created from a `Gateway`. 

The `gateway-operator.konghq.com/static-naming: "true"` annotation instructs {{site.operator_product_name}} to use a static, predictable name for the generated control plane based on the Gateway's namespace and name (for example, `default-hybrid`). This enables you to configure references before the control plane is created.

When static naming is enabled, {{site.operator_product_name}} derives the name for the `KonnectGatewayControlPlane` using the following logic:

* If the Gateway is in the same namespace as {{site.operator_product_name}}, the name will be the same as the Gateway name.
* If the Gateway is in a different namespace, the name will be the Gateway name prefixed with the namespace.

## Create the GatewayConfiguration and GatewayClass resources

Configure the `GatewayConfiguration` resources with your {{site.konnect_short_name}} authentication and configure the `GatewayClass` resource to reference the `GatewayConfiguration`:

```sh
echo '
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/v2beta1
metadata:
  name: hybrid
  namespace: kong
spec:
  konnect:
    authRef:
      name: konnect-api-auth
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
---
kind: GatewayClass
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: hybrid
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: hybrid
    namespace: kong ' | kubectl apply -f -
```

## Configure the Gateway with static naming

Configure the `Gateway` resource to reference the `GatewayClass` resource and add the `gateway-operator.konghq.com/static-naming: "true"` annotation:

```sh
echo '
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: hybrid
  namespace: kong
  annotations:
    gateway-operator.konghq.com/static-naming: "true"
spec:
  gatewayClassName: hybrid
  listeners:
  - name: http
    protocol: HTTP
    port: 80' | kubectl apply -f -
```

## Validate

To validate, fetch a list of control planes in {{site.konnect_short_name}}:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

You should see a control plane named `kong-hybrid`.

You can now reference the control plane in other resources using the Gateway name. For example, here's how to reference it in a `KongConsumer` resource:

```sh
echo '
kind: KongConsumer
apiVersion: configuration.konghq.com/v1
metadata:
  name: consumer1
  namespace: kong
username: consumer1
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: hybrid' | kubectl apply -f -
```