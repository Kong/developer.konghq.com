---
title: Reference an existing Control Plane
description: "Reference an existing Hybrid mode Control Plane in {{ site.konnect_short_name }}"
content_type: how_to

permalink: /operator/konnect/crd/control-planes/mirror/
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
  q: How do I reference an existing Hybrid mode Control Plane in {{ site.konnect_short_name }} from other CRDs?
  a: |
    Using {{ site.operator_product_name }}, create a `KonnectGatewayControlPlane` object with `spec.source: Mirror` and add {{ site.konnect_short_name }} authentication.

prereqs:
  operator:
    konnect:
      auth: true
  inline:
    - title: "Set the {{ site.konnect_short_name }} Control Plane ID"
      content: |
        Set the `KONNECT_CONTROL_PLANE_ID` variable to the ID of the control plane that you want to reference:

        ```bash
        export KONNECT_CONTROL_PLANE_ID='YOUR CONTROL PLANE ID'
        ```
      icon_url: /assets/icons/self-hosted.svg

next_steps:
  - text: Create a Gateway Service
    url: /operator/konnect/crd/gateway/service-and-route/

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
  source: Mirror
  mirror:
    konnect:
      id: $KONNECT_CONTROL_PLANE_ID
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

Now you can reference the `gateway-control-plane` resource from other CRDs as though it was created by {{ site.operator_product_name }}.
