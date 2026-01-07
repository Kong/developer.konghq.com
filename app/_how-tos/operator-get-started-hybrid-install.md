---
title: Install {{ site.operator_product_name }} in {{ site.konnect_short_name }} hybrid mode
description: "Learn how to install {{ site.operator_product_name }} in {{ site.konnect_short_name }} hybrid mode using Helm"
content_type: how_to

permalink: /operator/dataplanes/get-started/hybrid/install/
series:
  id: operator-get-started-hybrid
  position: 1

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

min_version:
  operator: '1.6.1'


entities: []

tldr:
  q: How do I install {{ site.operator_product_name }} in {{ site.konnect_short_name }} hybrid mode?
  a: Update the Helm repository and use Helm to install {{ site.operator_product_name }} in {{ site.konnect_short_name }}.

prereqs:
  show_works_on: false
  skip_product: true

tags:
  - install
  - helm
---

{{ site.operator_product_name }} can deploy and manage data planes attached to a {{ site.konnect_short_name }} control plane. All the Services, Routes, and plugins are configured in {{ site.konnect_short_name }} and sent to the data planes automatically.

## Install {{ site.operator_product_name }}

{% include prereqs/products/operator.md raw=true v_maj=2 %}

## Validate

Wait for {{ site.operator_product_name }} to be ready

{% include prereqs/products/operator-validate-deployment.md %}

Once the `kong-operator-kong-operator-controller-manager` deployment is ready, you can deploy a `DataPlane` resource that is attached to a {{ site.konnect_short_name }} Gateway control plane.
