---
title: Create a control plane
description: "Create a Hybrid mode control plane in {{ site.konnect_short_name }}"
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
  q: How do I create a Hybrid mode control plane in {{ site.konnect_short_name }}?
  a: Create a `KonnectGatewayControlPlane` object and add {{ site.konnect_short_name }} authentication.

prereqs:
  show_works_on: true
  skip_product: true
  operator:
    konnect:
      auth: true

---

## Create a `KonnectGatewayControlPlane`

Create a `KonnectGatewayControlPlane` object and add the {{ site.konnect_short_name }} authentication resource we created in the [prerequisites](#prerequisites).

<!-- vale off -->
{% konnect_crd %}
kind: KonnectGatewayControlPlane
apiVersion: konnect.konghq.com/{{ site.operator_konnectgatewaycontrolplane_api_version }}
metadata:
  name: gateway-control-plane
spec:
  createControlPlaneRequest:
    name: gateway-control-plane
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}
<!-- vale on -->


{:.info}
> Make sure that the `KonnectGatewayControlPlane` resource is in the same namespace as the `KonnectAPIAuthConfiguration` resource.

## Validate

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KonnectGatewayControlPlane
name: gateway-control-plane
{% endvalidation %}
<!-- vale on -->