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
  id: operator-konnectcrds-get-started
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

related_resources:
  - text: Deploy a DataPlane
    url: /operator/dataplanes/get-started/hybrid/deploy-dataplane/

---

## Create a `KonnectGatewayControlPlane`

Use the `KonnectGatewayControlPlane` resource to define the {{site.konnect_short_name}} Control Plane that your CRDs will target. This enables your cluster to send configuration to Konnect.

A `KonnectAPIAuthConfiguration` must already exist to authenticate with the Konnect API. If you haven’t created one yet, see [Create API Authentication](/operator/konnect/get-started/authentication/).

Apply the following configuration to define a Control Plane named `gateway-control-plane`:


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

This resource links your cluster to a specific Control Plane instance in {{site.konnect_short_name}} using the credentials provided in `konnect-api-auth`.


## Bind the Control Plane using a `KonnectExtension`

To finalize the connection between your cluster and the {{site.konnect_short_name}} control plane, create a `KonnectExtension` object. This resource binds your local Gateway or Data Plane to the {{site.konnect_short_name}} control plane you've defined.

<!-- vale off -->
{% konnect_crd %}
kind: KonnectExtension
apiVersion: konnect.konghq.com/{{ site.operator_konnectextension_api_version }}
metadata:
  name: my-konnect-config
  namespace: kong
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

The `KonnectExtension` resource handles automatic certificate generation and establishes secure communication between your cluster and {{site.konnect_short_name}}.

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KonnectGatewayControlPlane
name: gateway-control-plane
{% endvalidation %}
<!-- vale on -->

Once these resources are in place, your cluster is connected to {{site.konnect_short_name}} and can begin managing entities such as `KongService`, `KongRoute`, and `KongPlugin`.