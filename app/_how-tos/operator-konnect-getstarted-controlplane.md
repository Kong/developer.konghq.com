---
title: Create a Control Plane
description: Define a Konnect Gateway Control Plane and bind it to your cluster using a `KonnectExtension`.
content_type: how_to
permalink: /operator/konnect/get-started/control-plane/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: kgo-get-started
  position: 3

tldr:
  q: How do I create a Control Plane
  a: |
    Define a `KonnectGatewayControlPlane` to point to your Konnect instance, and a `KonnectExtension` to bind your Data Plane or Gateway to it.

products:
  - operator

works_on:
  - konnect

entities: []

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: false

---

## Create a `KonnectGatewayControlPlane`

To manage Gateway configurations from your Kubernetes cluster, define a `KonnectGatewayControlPlane` resource. This resource identifies which control plane in {{site.konnect_short_name}} your CRDs will target.

You must also create a `KonnectAPIAuthConfiguration` first to provide authentication credentials to the {{site.konnect_short_name}} API.

Defines a control plane configuration named `gateway-control-plane`:

<!-- vale off -->
{% konnect_crd %}
kind: KonnectGatewayControlPlane
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: gateway-control-plane
spec:
  name: gateway-control-plane
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}
<!-- vale on -->

This links your local configuration to a specific {{site.konnect_short_name}} control plane using the credentials provided in `konnect-api-auth`.

## Bind the Control Plane using a `KonnectExtension`

To finalize the connection between your cluster and the {{site.konnect_short_name}} control plane, create a `KonnectExtension` object. This resource binds your local Gateway or Data Plane to the {{site.konnect_short_name}} control plane you've defined.

<!-- vale off -->
{% konnect_crd %}
kind: KonnectExtension
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: my-konnect-config
spec:
  clientAuth:
    certificateSecret:
      provisioning: Automatic
  konnect:
    controlPlane:
      ref:
        type: konnectNamespacedRef
        konnectNamespacedRef:
          name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->

The `KonnectExtension` will automatically discover the associated control plane and credentials, and handle authentication and binding internally.

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KonnectGatewayControlPlane
name: gateway-control-plane
{% endvalidation %}
<!-- vale on -->

Once created, your cluster is fully connected to the {{site.konnect_short_name}} Control Plane and ready to manage resources like `KongService`, `KongRoute`, and more.
