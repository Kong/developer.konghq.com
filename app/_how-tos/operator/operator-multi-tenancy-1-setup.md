---
title: Install Kong Operator for multi-tenancy
description: "Create tenant namespaces, install {{ site.operator_product_name }} scoped to those namespaces, and apply a KongLicense."
content_type: how_to

permalink: /operator/dataplanes/how-to/multi-tenancy/setup/
series:
  id: operator-multi-tenancy
  position: 1

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

works_on:
  - on-prem

min_version:
  operator: '2.0'

related_resources:
  - text: "Multi-tenancy reference"
    url: /operator/reference/multi-tenancy/
  - text: "Limiting namespaces watched by ControlPlane"
    url: /operator/reference/control-plane-watch-namespaces/

tldr:
  q: How do I set up {{ site.operator_product_name }} for multi-tenancy?
  a: |
    Install {{ site.operator_product_name }} with `env.watch_namespace` scoped to your
    tenant namespaces, then apply a single `KongLicense` in `kong-system`.

prereqs:
  skip_product: true
---

<!-- SOURCE: control-plane-watch-namespaces.md#multi-tenancy-using-watch-namespaces,
     Baptiste's gist https://gist.github.com/bcollard/44caa409cdf7d796506a7a2e61a4a0d5 -->

This guide deploys two independent {{ site.base_gateway }} instances — one public-facing, one private — on the same cluster using a single {{ site.operator_product_name }} installation. Each gateway is scoped to its own namespace so that its in-memory KIC only processes routes from that namespace.

## Create namespaces

Create the operator namespace and the two tenant namespaces:

```bash
kubectl create namespace kong-system
kubectl create namespace kong-gw-public
kubectl create namespace kong-gw-private
```

## Install {{ site.operator_product_name }}

<!-- SOURCE: control-plane-watch-namespaces.md#multi-tenancy-using-watch-namespaces -->

Add the Kong Helm chart repository:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

Install {{ site.operator_product_name }} scoped to the two tenant namespaces. The `watch_namespace` value prevents the operator from reconciling resources in any other namespace.

```bash
helm upgrade --install kong-operator kong/kong-operator \
  -n kong-system \
  --create-namespace \
  --set image.tag={{ site.data.operator_latest.release }} \
  --values - <<EOF
env:
  watch_namespace: kong-gw-public,kong-gw-private
EOF
```

## Validate

Wait for {{ site.operator_product_name }} to be ready:

{% include prereqs/products/operator-validate-deployment.md %}

## Apply a KongLicense

<!-- SOURCE: Baptiste's gist; KongLicense applied once in kong-system is shared by all Gateways -->
<!-- GAP: This behaviour is not documented in the product docs. A single KongLicense in
     kong-system covers all Gateways managed by this operator installation. -->

Apply the license once in `kong-system`. It is shared by all gateways managed by this operator installation. This assumes your license file is at `./license.json`.

```bash
kubectl -n kong-system apply -f - <<EOF
apiVersion: configuration.konghq.com/v1alpha1
kind: KongLicense
metadata:
  name: kong-license
rawLicenseString: '$(cat ./license.json)'
EOF
```
