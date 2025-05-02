---
title: Create a {{ site.kic_product_name }} Control Plane
description: "TODO"
content_type: how_to

permalink: /operator/konnect/crd/kubernetes-control-plane/
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
  name: kic-control-plane
  cluster_type: CLUSTER_TYPE_K8S_INGRESS_CONTROLLER
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}