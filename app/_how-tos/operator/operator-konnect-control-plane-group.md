---
title: Create a Control Plane Group
description: "Create a Control Plane, and a Control Plane Group that contains the Control Plane"
content_type: how_to

permalink: /operator/konnect/crd/control-planes/control-plane-group/
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
  q: How can I create a Control Plane group?
  a: Create a `KonnectGatewayControlPlane` object, then create a Control Plane group using a `KonnectGatewayControlPlane` object with the `CLUSTER_TYPE_CONTROL_PLANE_GROUP` cluster type.

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

## Create a `KonnectGatewayControlPlane`

Create a Control Plane using the `KonnectGatewayControlPlane` object:

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

## Create a `KonnectGatewayControlPlane` with members

Create a new `KonnectGatewayControlPlane` object, add the `CLUSTER_TYPE_CONTROL_PLANE_GROUP` cluster type, and add the Control Plane created in the previous step as a member:

<!-- vale off -->
{% konnect_crd %}
kind: KonnectGatewayControlPlane
apiVersion: konnect.konghq.com/{{ site.operator_konnectgatewaycontrolplane_api_version }}
metadata:
  name: control-plane-group
spec:
  createControlPlaneRequest:
    name: control-plane-group
    cluster_type: CLUSTER_TYPE_CONTROL_PLANE_GROUP
  members:
    - name: gateway-control-plane
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}
<!-- vale on -->

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KonnectGatewayControlPlane
name: control-plane-group
{% endvalidation %}
<!-- vale on -->