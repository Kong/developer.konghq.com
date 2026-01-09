---
title: Install {{ site.operator_product_name }} with self-managed Control Plane
description: "Learn how to install {{ site.operator_product_name }} with self-managed Control Plane using Helm"
content_type: how_to

permalink: /operator/dataplanes/get-started/kic/install/
series:
  id: operator-get-started-kic
  position: 1

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "Get Started"
min_version:
  operator: '1.6.1'
products:
  - operator

works_on:
  - konnect
  - on-prem

prereqs:
  show_works_on: false
  skip_product: true

tldr:
  q: How do I install {{ site.operator_product_name }} with self-managed Control Plane using Helm?
  a: Update the Helm repository and use Helm to install {{ site.operator_product_name }} with self-managed Control Plane.

tags:
  - install
  - helm
---

{% include k8s/kong-namespace.md %}

## Install {{ site.operator_product_name }}

{% include prereqs/products/operator.md raw=true v_maj=2 %}


## Wait for {{ site.operator_product_name }} to be ready

{% validation custom-command %}
command: |
  kubectl -n kong-system wait --for=condition=Available=true --timeout=120s deployment/kong-operator-kong-operator-controller-manager
expected:
  stdout: "deployment.apps/kong-operator-kong-operator-controller-manager condition met"
  return_code: 0
{% endvalidation %}
