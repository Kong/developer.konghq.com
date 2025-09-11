---
title: Install {{ site.gateway_operator_product_name }} in {{ site.konnect_short_name }} hybrid mode
description: "Learn how to install {{ site.gateway_operator_product_name }} in Konnect hybrid mode using Helm"
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
  q: How do I install {{ site.gateway_operator_product_name }} in {{ site.konnect_short_name }} hybrid mode?
  a: Update the Helm repository and use Helm to install {{ site.gateway_operator_product_name }} in {{ site.konnect_short_name }}.

prereqs:
  show_works_on: false
  skip_product: true
---

{% assign gwapi_version = "1.3.0" %}

## Deploying Data Planes

{{ site.gateway_operator_product_name }} can deploy and manage Data Planes attached to a {{ site.konnect_short_name }} Control Plane. All the Services, Routes, and plugins are configured in {{ site.konnect_short_name }} and sent to the Data Planes automatically.

## Install CRDs

If you want to use Gateway API resources, run this command:

```shell
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v{{ gwapi_version }}/standard-install.yaml
```

## Install {{ site.gateway_operator_product_name }}

{% include prereqs/products/operator.md raw=true v_maj=2 %}

{% include k8s/cert-manager.md %}

## Validate

Wait for {{ site.gateway_operator_product_name }} to be ready

{% validation custom-command %}
command: |
  kubectl -n kong-system wait --for=condition=Available=true --timeout=120s deployment/kong-operator-kong-operator-controller-manager
expected:
  stdout: "deployment.apps/kong-operator-kong-operator-controller-manager condition met"
  return_code: 0
{% endvalidation %}

Once the `kong-operator-kong-operator-controller-manager` deployment is ready, you can deploy a `DataPlane` resource that is attached to a {{ site.konnect_short_name }} Gateway Control Plane.
You can use [this guide](/operator/dataplanes/konnectextension/#konnect-control-plane-reference) to learn more about how to do this.
