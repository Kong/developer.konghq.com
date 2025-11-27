---
title: "FAQ"
description: "Answers to common questions about managing {{site.konnect_short_name}} entities using the Operator."

content_type: reference
layout: reference
search_aliases:
  - KGO FAQ
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Reference

---

Managing {{site.konnect_short_name}} entities with {{ site.operator_product_name }} is an actively developed feature. This page answers frequently asked questions.

## I'm a {{ site.kic_product_name }} user. How much do I need to learn?

{{ site.operator_product_name }} uses the same custom resources as {{ site.kic_product_name }}. A `KongConsumer` is the same no matter which product you're using.

By default, all `Kong*` custom resources will be reconciled by {{ site.kic_product_name }}. To make {{ site.operator_product_name }} reconcile them with {{ site.konnect_short_name }}, you must provide a `spec.controlPlaneRef.type` of `konnectNamespacedRef`.

## Can I use `HTTPRoute` and Ingress definitions?

Not yet. The initial release uses a 1:1 mapping between custom resources and Konnect entities. Use `KongService` and `KongRoute` instead of `HTTPRoute` or `Ingress`.


Support for standard Kubernetes resources is planned for the future.

## How often does the reconcile loop run?

* New resources are created immediately via the {{site.konnect_short_name}} API.
* Existing resources are reconciled every 60 seconds by default.

This is customizable, but we recommend keeping the default value so that you do not hit the {{ site.konnect_short_name }} API rate limit.

For more information, see [how it works](/operator/konnect/reconciliation-loop/).

## I deleted a resource in the UI, but it wasn't recreated by the operator. Why?

The reconciliation loop runs once per minute. Wait 60 seconds, then refresh the UI.

## Can I use Secrets for Consumer credentials like in {{ site.kic_product_name }}?

{{ site.operator_product_name }} uses new `Credential` CRDs for managing [consumer credentials](/operator/konnect/crd/gateway/consumer/). We plan to support Kubernetes `Secret` resources in a future release. [#618](https://github.com/Kong/gateway-operator/issues/618).

## Can I adopt existing {{ site.konnect_short_name }} entities?

Adopting existing entities is planned, but not yet available. Only resources created by the operator can be managed using CRDs at this time. [#460](https://github.com/Kong/gateway-operator/issues/460)

## How do I create a global plugin?

You can also attach a plugin globally to a Control Plane by setting the `spec.scope` field to `GlobalInControlPlane` in the `KongPluginBinding` CRD.
Detailed guides are available in [Enable a global plugin](/operator/konnect/kongpluginbinding/#attaching-plugins-globally-to-a-control-plane).
