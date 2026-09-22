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

related_resources:
  - text: Provision a Gateway
    url: /operator/get-started/gateway-api/deploy-gateway/
  - text: Reference Konnect authentication across multiple namespaces
    url: /operator/konnect/how-to/auth-cross-namespace-reference/

min_version:
  operator: '2.1'

prereqs:
  operator:
    konnect:
      auth: true
---

By default, {{ site.operator_product_name }} generates unique, dynamic names for `KonnectGatewayControlPlane` resources created from a `Gateway`. 

The `gateway-operator.konghq.com/static-naming: "true"` annotation instructs {{site.operator_product_name}} to use static, predictable names for the resources it generates from a `Gateway`. The `KonnectGatewayControlPlane` resource is named after the `Gateway`, and the control plane this resource creates in {{site.konnect_short_name}} is named `<namespace>_<gateway-name>` (for example, `default_hybrid`). This enables you to configure references before the control plane is created.

{:.warning}
> The name of a `KonnectGatewayControlPlane` resource can't be modified after creation, and the name of the control plane in {{site.konnect_short_name}} is derived from the Gateway's namespace and name when that control plane is created. Plan your naming carefully before enabling this annotation, and keep in mind that control planes created before you upgrade {{site.operator_product_name}} keep the name they already have.

When static naming is enabled, {{site.operator_product_name}} names the `KonnectGatewayControlPlane` resource after the `Gateway`, and names the control plane it creates in {{site.konnect_short_name}} `<namespace>_<gateway-name>`.

The namespace is part of the {{site.konnect_short_name}} name because control plane names must be unique across your whole {{site.konnect_short_name}} organization, while Gateway names only have to be unique within a namespace. The two parts are joined with an underscore, which can't appear in a namespace or a Gateway name, so the namespace and the Gateway name stay unambiguously separated. As a result, the Kubernetes and {{site.konnect_short_name}} names of the same control plane differ, for example `hybrid` and `kong_hybrid`.

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

You should see a control plane named `kong_hybrid`.

You can now reference the control plane in other resources using the name of the `KonnectGatewayControlPlane` resource, which matches the Gateway name. No resource looks up the control plane by its {{site.konnect_short_name}} name. For example, here's how to reference it in a `KongConsumer` resource:

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