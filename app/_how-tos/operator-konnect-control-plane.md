---
title: Create a Control Plane
description: "TODO"
content_type: how_to

permalink: /operator/konnect/crd/control-plane/
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

---

## TODO

TODO

{% konnect_crd %}
kind: KonnectGatewayControlPlane
metadata:
  name: gateway-control-plane
spec:
  name: gateway-control-plane
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}