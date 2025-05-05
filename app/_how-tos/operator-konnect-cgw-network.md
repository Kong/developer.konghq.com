---
title: Create a Cloud Gateways Network
description: "TODO"
content_type: how_to

permalink: /operator/konnect/crd/cloud-gateways/network/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: "Konnect CRDs: Cloud Gateways"

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
kind: KonnectExample
metadata:
  name: example-name
spec:
  name: example
  other: field
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}
<!-- vale on -->

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KonnectExample
name: example-name
{% endvalidation %}
<!-- vale on -->