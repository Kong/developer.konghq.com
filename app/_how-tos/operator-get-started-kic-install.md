---
title: Install {{ site.operator_product_name }} with {{ site.kic_product_name }}
description: "Learn how to install {{ site.operator_product_name }} with {{ site.kic_product_name }} using Helm"
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
  kgo: '1.6.1'
products:
  - operator

works_on:
  - konnect
  - on-prem

prereqs:
  show_works_on: false
  skip_product: true

tldr:
  q: How do I install {{ site.operator_product_name }} with {{ site.kic_product_name }} using Helm?
  a: Update the Helm repository and use Helm to install {{ site.operator_product_name }} with {{ site.kic_product_name }}.
---
{% assign gwapi_version = "1.3.0" %}

## Install CRDs

```shell
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v{{ gwapi_version }}/standard-install.yaml
```

## Install {{ site.operator_product_name }}

1. Add the Kong Helm charts:

   ```bash
   helm repo add kong https://charts.konghq.com
   helm repo update
   ```

1. Install {{ site.kic_product_name }} using Helm:

   ```bash
   helm upgrade --install ko kong/kong-operator -n kong-system \
     --create-namespace \
     --set image.tag={{ site.data.operator_latest.release }} \
     --set kubernetes-configuration-crds.enabled=true \
     --set env.ENABLE_CONTROLLER_KONNECT=true
   ```

{% include k8s/cert-manager.md %}


## Wait for {{ site.operator_product_name }} to be ready

{% validation custom-command %}
command: |
  kubectl -n kong-system wait --for=condition=Available=true --timeout=120s deployment/ko-kong-operator-controller-manager
expected:
  stdout: "deployment.apps/ko-kong-operator-controller-manager condition met"
  return_code: 0
{% endvalidation %}
