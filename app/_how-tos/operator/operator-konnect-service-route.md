---
title: Create a Service and Route
description: "Provision and manage Gateway Services and Routes in {{site.konnect_short_name}} using KGO custom resources."
content_type: how_to

permalink: /operator/konnect/crd/gateway/service-and-route/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: "Konnect CRDs: Gateway"

products:
  - operator

works_on:
  - konnect
search_aliases:
  - kgo service
entities: []

tags:
  - konnect-crd
 
tldr:
  q: How can I create a Service and Route for {{site.konnect_short_name}} using KGO?
  a: Define a `KongService` and `KongRoute` in your Kubernetes cluster to provision and configure Gateway entities in {{site.konnect_short_name}}.


prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

cleanup:
  inline:
    - title: Delete the resources created in this guide
      content: |
        Deleting the `KonnectGatewayControlPlane` also deletes the control plane the {{site.operator_product_name}} created in {{ site.konnect_short_name }}:

        ```bash
        kubectl delete -n kong --ignore-not-found \
          kongroute/route-with-service \
          kongservice/service \
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

## Create a `KongService` 

Create a Gateway Service in {{site.konnect_short_name}}. The Service must reference an existing `KonnectGatewayControlPlane`.

<!-- vale off -->
{% konnect_crd %}
kind: KongService
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: service
spec:
  name: service
  host: example.com
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->

## Create a `KongRoute`

To expose the Service, create a `KongRoute` associated with the `KongService` defined above.

<!-- vale off -->
{% konnect_crd %}
kind: KongRoute
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: route-with-service
spec:
  name: route-with-service
  protocols:
  - http
  hosts:
  - example.com
  serviceRef:
    type: namespacedRef
    namespacedRef:
      name: service
{% endkonnect_crd %}
<!-- vale on -->

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongService
name: service
{% endvalidation %}
<!-- vale on -->