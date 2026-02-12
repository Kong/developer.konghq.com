---
title: Deploy a data plane
description: "Deploy a data plane using {{ site.operator_product_name }}."
content_type: how_to

permalink: /operator/konnect/crd/dataplane/hybrid/

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "Get Started"

products:
  - operator

works_on:
  - konnect

entities: []

tldr:
  q: How can I deploy a data plane with {{ site.operator_product_name }}?
  a: Create a `DataPlane` object and use the `KonnectExtension` reference.

prereqs:
  skip_product: true
  operator:
    konnect:
      konnectextension: true
---

{% include /how-tos/steps/operator-hybrid-data-plane.md %}
