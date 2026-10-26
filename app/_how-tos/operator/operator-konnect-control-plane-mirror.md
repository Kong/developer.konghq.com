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

        If you don't have a control plane yet, create one with the {{ site.konnect_short_name }} API and save its ID to the variable:

        {% konnect_api_request %}
        section: prereqs
        url: /v2/control-planes
        status_code: 201
        method: POST
        body:
            name: mirror-source-control-plane
        capture:
          - variable: KONNECT_CONTROL_PLANE_ID
            jq: ".id"
        {% endkonnect_api_request %}
      icon_url: /assets/icons/self-hosted.svg

next_steps:
  - text: Create a Gateway Service
    url: /operator/konnect/crd/gateway/service-and-route/

cleanup:
  inline:
    - title: Delete the resources created in this guide
      content: |
        Delete the `KonnectGatewayControlPlane` and the authentication configuration. Because this guide references an existing control plane rather than creating one, the control plane in {{ site.konnect_short_name }} is left untouched. If you created it for this guide with the API request in the [prerequisites](#prerequisites), delete it from {{ site.konnect_short_name }} separately:

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
