---
title: Install {{ site.operator_product_name }} in {{ site.konnect_short_name }} hybrid mode
description: "Learn how to install {{ site.operator_product_name }} in Konnect hybrid mode using Helm"
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
  kgo: '1.6.1'


entities: []

tldr:
  q: How do I install {{ site.operator_product_name }} in {{ site.konnect_short_name }} hybrid mode?
  a: Update the Helm repository and use Helm to install {{ site.operator_product_name }} in {{ site.konnect_short_name }}.

prereqs:
  show_works_on: false
  skip_product: true
  inline:
    - title: Cert manager
      include_content: prereqs/operator-cert-manager
---

{% assign gwapi_version = "1.3.0" %}

## Deploying Data Planes

{{ site.operator_product_name }} can deploy and manage Data Planes attached to a {{ site.konnect_short_name }} Control Plane. All the Services, Routes, and plugins are configured in {{ site.konnect_short_name }} and sent to the Data Planes automatically.

## Install CRDs

If you want to use Gateway API resources, run this command:

```shell
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v{{ gwapi_version }}/standard-install.yaml
```

## Install {{ site.operator_product_name }}

Update the Helm repository:

```bash
helm repo add kong https://charts.konghq.com
helm repo update kong
```

Install {{ site.operator_product_name }} with Helm:

```bash
helm upgrade --install kgo kong/gateway-operator -n kong-system --create-namespace \
  --set image.tag={{ site.data.operator_latest.release }} \
  --set env.ENABLE_CONTROLLER_KONNECT=true
```

## Wait for {{ site.operator_product_name }} to be ready

{% validation custom-command %}
command: |
  kubectl -n kong-system wait --for=condition=Available=true --timeout=120s deployment/kgo-gateway-operator-controller-manager
expected:
  stdout: "deployment.apps/kgo-gateway-operator-controller-manager condition met"
  return_code: 0
{% endvalidation %}

Once the `gateway-operator-controller-manager` deployment is ready, you can deploy a `DataPlane` resource that is attached to a {{ site.konnect_short_name }} Control Plane.
