---
title: Install {{site.operator_product_name}}
description: Install the {{site.operator_product_name}} with Helm and enable {{ site.konnect_short_name }} CRD support.
content_type: how_to
permalink: /operator/konnect/get-started/install/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: operator-konnectcrds-get-started
  position: 1

products:
  - operator

works_on:
  - konnect

entities: []

prereqs:
  skip_product: true

tldr:
  q: How do I install {{site.operator_product_name}}?
  a: Use Helm and Kong's `kong-operator` chart.

tags:
  - install
  - helm
---

## Install {{site.operator_product_name}}

The {{site.operator_product_name}} can deploy and manage Data Planes connected to a {{ site.konnect_short_name }} Control Plane. Configuration for services, routes, and plugins is managed entirely through {{site.konnect_short_name}} and propagated automatically to Data Planes.

## Create the `kong` namespace

Create the `kong` namespace in your Kubernetes cluster, which is where the Getting Started guide will run:

```sh
kubectl create namespace kong
```

## Install the Operator

{% include prereqs/products/operator.md raw=true v_maj=1 %}

{% include k8s/cert-manager.md %}

### Wait for readiness

Wait for the {{site.operator_product_name}}'s controller deployment to become available before proceeding, ensuring it’s ready to manage resources:

{% include prereqs/products/operator-validate-deployment.md %}

Once the {{site.operator_product_name}} is ready, you can begin provisioning Gateway Control Planes and Data Planes using {{site.konnect_short_name}} CRDs.
