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
  operator:
    konnect:
      auth: true

cleanup:
  inline:
    - title: Delete the resources created in this guide
      content: |
        Deleting the `KonnectGatewayControlPlane` also deletes the control plane the {{site.operator_product_name}} created in {{ site.konnect_short_name }}:

        ```bash
        kubectl delete -n kong --ignore-not-found \
          konnectgatewaycontrolplane/gateway-control-plane \
          konnectapiauthconfiguration/konnect-api-auth
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/kubernetes.svg

    - title: Delete the namespaces
      content: |
        ```bash
        helm uninstall kong-operator -n kong-system
        kubectl delete namespace kong kong-system
        ```
      icon_url: /assets/icons/kubernetes.svg

---

## Create a KonnectGatewayControlPlane

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