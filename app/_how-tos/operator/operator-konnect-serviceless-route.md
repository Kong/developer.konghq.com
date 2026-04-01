---
title: Create a serviceless Route
description: "Create a Kong Route that does not have an attached Service. Useful when used with the Lambda plugin."
content_type: how_to

permalink: /operator/konnect/crd/gateway/serviceless-route/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: "Konnect CRDs: Gateway"

products:
  - operator

works_on:
  - konnect

entities: []

tags:
  - konnect-crd
 
tldr:
  q: How do I create a Route without an attached Service?
  a: Create a `KongRoute` object and specify a `controlPlaneRef`.

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

## Create a `KongRoute`

Create a `KongRoute` object and reference the Control Plane with `controlPlaneRef` to make the Route work without a Service.

<!-- vale on -->
{% konnect_crd %}
kind: KongRoute
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: route-without-service
spec:
  name: route-without-service
  protocols:
    - http
  hosts:
    - example.com
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongRoute
name: route-without-service
{% endvalidation %}
<!-- vale on -->