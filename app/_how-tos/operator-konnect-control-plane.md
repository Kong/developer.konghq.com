---
title: Create a Control Plane
description: "Create a Hybrid mode Control Plane in {{ site.konnect_short_name }}"
content_type: how_to

permalink: /operator/konnect/crd/control-planes/hybrid/
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
  q: How do I create a Hybrid mode Control Plane in {{ site.konnect_short_name }}?
  a: Create a `KonnectGatewayControlPlane` object and add {{ site.konnect_short_name }} authentication.

prereqs:
  operator:
    konnect:
      auth: true

---

## Create a `KonnectGatewayControlPlane`

Create a `KonnectGatewayControlPlane` object and add the {{ site.konnect_short_name }} authentication resource we created in the [prerequisites](#prerequisites).

<!-- vale off -->
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
<!-- vale on -->

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KonnectGatewayControlPlane
name: gateway-control-plane
{% endvalidation %}
<!-- vale on -->