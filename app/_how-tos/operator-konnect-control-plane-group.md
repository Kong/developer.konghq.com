---
title: Create a Control Plane Group
description: "TODO"
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
  q: Question?
  a: Answer

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

## TODO

TODO

<!-- vale off -->
{% konnect_crd %}
kind: KonnectGatewayControlPlane
metadata:
  name: control-plane-group
spec:
  name: control-plane-group
  cluster_type: CLUSTER_TYPE_CONTROL_PLANE_GROUP
  members:
    - name: gateway-control-plane
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}
<!-- vale on -->