---
title: Understanding IngressClass / GatewayClass
short_title: IngressClass / GatewayClass

description: |
  Which resources require an IngressClass / GatewayClass to be reconciled by {{site.kic_product_name}}?

content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Gateway API
    url: /kubernetes-ingress-controller/gateway-api/
---


## IngressClass

[IngressClass](https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-class) in Kubernetes allows `Ingress` definitions to be processed by different controllers. {{ site.kic_product_name }} reconciles any resources attached to a resource that has an `IngressClass` of `kong`. This `IngressClass` can be set in the `spec.ingressClassName` field, or using the `kubernetes.io/ingress.class` annotation.

{:.info}
> `kong` is the default value and can be changed using the `--ingress-class` CLI flag, or the `CONTROLLER_INGRESS_CLASS` environment variable.


If the `IngressClass` used by {{site.kic_product_name}} (specified in flag `--ingress-class`) has `ingressclass.kubernetes.io/is-default-class` set to `true`, all resources that don't have an explicit Ingress Class set are also reconciled by {{site.kic_product_name}}. This doesn't include Gateway API resources.

## GatewayClass

{{ site.kic_product_name }} reconciles any resources attached to a [`GatewayClass`](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.GatewayClass) that has a `spec.controllerName` of `konghq.com/kic-gateway-controller`. 

Gateway API resources are attached to a `Gateway` object using the `spec.parentRefs` field, and the `Gateway` references a `GatewayClass` using the `spec.gatewayClassName` field.

{:.info}
> `konghq.com/kic-gateway-controller` is the default value and can be changed using the `--gateway-api-controller-name` CLI flag, or the `CONTROLLER_GATEWAY_API_CONTROLLER_NAME` environment variable.
 
## Resource types

Kong CRDs can be one of three types:

* **Global**: Used by all {{ site.kic_product_name }} installations.
* **Dependent**: Included if they reference a resource that contains an `IngressClass` or a `GatewayClass`. For example, a `KongPlugin` that refers to an `Ingress`.
* **Independent**: Resources that don't rely on a resource containing an `IngressClass`. These resources must be annotated with the `kubernetes.io/ingress.class` annotation.

### Global resources

The `KongLicense` resource is the only global resource. If a `KongLicense` resource exists in the cluster, all {{ site.kic_product_name }} instances will send it in the configuration payload to {{ site.base_gateway }}.

### Dependent resources

Any resources that are attached to a resource containing an `IngressClass` or `GatewayClass` that {{ site.kic_product_name }} reconciles will be automatically included in reconciliation.

This includes:

* `KongCustomEntity`
* `KongPlugin`
* `KongUpstreamPolicy`

### Independent resources

The following resources require the `kubernetes.io/ingress.class` annotation to be added explicitly:

* `KongClusterPlugin`
* `KongConsumer`
* `KongConsumerGroup`
* `KongVault`
* `TCPIngress`
* `UDPIngress`

{:.info}
> The `kubernetes.io/ingress.class` annotation is used even when using Gateway API CRDs. This annotation is how {{ site.kic_product_name }} selects resources to reconcile.