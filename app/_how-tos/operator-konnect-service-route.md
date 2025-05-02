---
title: Create a Service and Route
description: "TODO"
content_type: how_to

permalink: /operator/konnect/crd/service-and-route/
breadcrumbs:
  - /operator/
  - index: operator
    section: Konnect

products:
  - operator

works_on:
  - konnect

entities: []

tags:
  - konnect-crd
 
tldr:
  q: Question?
  a: Answer

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

## TODO

TODO

<!-- vale off -->
{% konnect_crd %}
kind: KongService
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: service
spec:
  name: service
  host: example.com
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->

<!-- vale off -->
{% konnect_crd %}
kind: KongRoute
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: route-with-service
spec:
  name: route-with-service
  protocols:
  - http
  hosts:
  - example.com
  serviceRef:
    type: namespacedRef
    namespacedRef:
      name: service
{% endkonnect_crd %}
<!-- vale on -->

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongService
name: service
{% endvalidation %}
<!-- vale on -->