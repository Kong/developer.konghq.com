---
title: Install {{site.operator_product_name}} for Dev Portal
description: Install {{site.operator_product_name}} and prepare a Kubernetes cluster for Konnect Dev Portal CRDs.
content_type: how_to
permalink: /operator/get-started/dev-portal/install/

series:
  id: operator-get-started-dev-portal
  position: 1

breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

products:
  - operator

works_on:
  - konnect

prereqs:
  skip_product: true

tldr:
  q: How do I prepare a cluster for Dev Portal CRDs with {{site.operator_product_name}}?
  a: Create a `kong` namespace, install {{site.operator_product_name}}, and wait for the controller to be ready.

tags:
  - install
  - helm
  - dev-portal
---

This guide walks through managing {{site.konnect_short_name}} Dev Portal resources with {{site.operator_product_name}}.

By the end of the series, you will have:

- a `Portal`
- a `PortalPage`
- a `PortalCustomization`
- a `PortalEmailConfig`
- a `PortalTeam`
- a `PortalCustomDomain`
- a `PortalIdentityProviderRequest`

## Create the `kong` namespace

```bash
kubectl create namespace kong
```

If the namespace already exists, Kubernetes returns an `AlreadyExists` message, which is safe to ignore.

## Install {{site.operator_product_name}}

{% include prereqs/products/operator.md raw=true v_maj=2 %}

## Wait for the operator to be ready

{% include prereqs/products/operator-validate-deployment.md %}

## Validation

Verify that the operator is running:

```bash
kubectl get pods -n kong-system
```

Once the controller is ready, continue to [Create API Authentication](/operator/get-started/dev-portal/authentication/).
