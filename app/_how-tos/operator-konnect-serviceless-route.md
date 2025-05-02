---
title: Create a Serviceless Route
description: "TODO"
content_type: how_to

permalink: /operator/konnect/crd/serviceless-route/
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