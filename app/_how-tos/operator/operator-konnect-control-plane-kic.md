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
  q: How can I create a {{ site.kic_product_name }} Control Plane in {{ site.konnect_short_name }}?
  a: Create a `KonnectGatewayControlPlane` object with the cluster type `CLUSTER_TYPE_K8S_INGRESS_CONTROLLER`.

prereqs:
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

Create a Control Plane and add the cluster type `CLUSTER_TYPE_K8S_INGRESS_CONTROLLER`:

<!-- vale off -->
{% konnect_crd %}
kind: KonnectGatewayControlPlane
apiVersion: konnect.konghq.com/{{ site.operator_konnectgatewaycontrolplane_api_version }}
metadata:
  name: gateway-control-plane
spec:
  createControlPlaneRequest:
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
kind: KonnectGatewayControlPlane
name: gateway-control-plane
{% endvalidation %}
<!-- vale on -->