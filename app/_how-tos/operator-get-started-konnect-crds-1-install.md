---
title: Install {{site.operator_product_name}}
description: Install the {{site.operator_product_name}} with Helm and enable {{ site.konnect_short_name }} CRD support.
content_type: how_to
permalink: /operator/get-started/konnect-crds/install/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: operator-get-started-konnect-crds
  position: 1

products:
  - operator

works_on:
  - konnect

prereqs:
  skip_product: true

tldr:
  q: How do I install {{site.operator_product_name}}?
  a: Use Helm and Kong's `kong-operator` chart.

tags:
  - install
  - helm
---

{{site.operator_product_name}} can deploy and manage data planes connected to a {{ site.konnect_short_name }} control plane. Configuration for Services, Routes, and plugins is managed entirely through {{site.konnect_short_name}} and propagated automatically to data planes.

## Create the `kong` namespace

Create the `kong` namespace in your Kubernetes cluster, which is where the Getting Started guide will run:

```sh
kubectl create namespace kong
```

## Install {{site.operator_product_name}}

{% include prereqs/products/operator.md raw=true v_maj=2 %}

### Wait for readiness

Wait for {{site.operator_product_name}}'s controller deployment to become available before proceeding, ensuring it’s ready to manage resources:

{% include prereqs/products/operator-validate-deployment.md %}

Once the {{site.operator_product_name}} is ready, you can begin provisioning Gateway control planes and data planes using {{site.konnect_short_name}} CRDs.
