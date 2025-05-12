---
title: Create a {{ site.kic_product_name }} Control Plane
description: "Create a new {{ site.kic_product_name }} Control Plane in {{ site.konnect_short_name }}"
content_type: how_to

permalink: /operator/konnect/crd/control-planes/kubernetes/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: "Konnect CRDs: Control Planes"

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

## Create a `KonnectGatewayControlPlane`

<!-- vale off -->
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
<!-- vale on -->

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongDataPlaneClientCertificate
name: gateway-control-plane
{% endvalidation %}
<!-- vale on -->