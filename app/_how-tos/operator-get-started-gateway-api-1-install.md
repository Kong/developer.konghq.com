---
title: Install {{ site.operator_product_name }}
description: "Deploy the {{ site.operator_product_name }}"
content_type: how_to

permalink: /operator/get-started/gateway-api/install/
series:
  id: operator-get-started-gateway-api
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
  - on-prem

entities: []

tldr:
  q: How do I manage a {{ site.base_gateway }} through the {{ site.operator_product_name }}?
  a: Update the Helm repository and use Helm to install {{ site.operator_product_name }}.

prereqs:
  skip_product: true

tags:
  - install
  - helm
---

## Install CRDs

{{ site.operator_product_name }} will automatically install the Cluster Resource Definitions as part of the Helm deployment.  If you are upgrading the CRDs as part of an existing {{ site.operator_product_name }} installation, you should deploy them manually: 

```shell
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v{{ site.gwapi_version }}/standard-install.yaml --server-side
```

{:.warning}
> {{ site.operator_product_name }} 2.1 enables [Combine HTTP routes](/kubernetes-ingress-controller/faq/combining-httproutes/) by default.  This will automatically reduce the number of Services with the same `backendRef`.  During an upgrade from {{ site.operator_product_name }} 2.0 to 2.1, this will mean a couple of seconds of downtime for your Services as they are automatically merged. To disable this, set the`spec.controlPlaneOptions.translation.combinedServicesFromDifferentHTTPRoutes` parameter to `disabled` in your `GatewayConfiguration`. 

## Install {{ site.operator_product_name }}

{% include prereqs/products/operator.md raw=true v_maj=2 %}


## Validate

Wait for {{ site.operator_product_name }} to be ready

{% include prereqs/products/operator-validate-deployment.md %}

Once the `kong-operator-kong-operator-controller-manager` deployment is ready, you can deploy a `Gateway` and a `GatewayClass` that references the `GatewayConfiguration` holding the {{ site.konnect_short_name }} parameters.
