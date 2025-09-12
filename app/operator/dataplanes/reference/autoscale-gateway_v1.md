---
title: "Autoscaling {{ site.base_gateway }}"
description: "Horizontally scale {{ site.base_gateway }} based on CPU usage"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Advanced Usage

min_version:
  operator: '1.0'
max_version:
  operator: '1.6'

---

{{ site.gateway_operator_product_name }} can deploy Data Planes that will horizontally autoscale based on user defined criteria.

This page shows how to autoscale Data Planes based on their average CPU utilization.

## Prerequisites

{{ site.gateway_operator_product_name }} uses Kubernetes [`HorizontalPodAutoscaler`](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) to perform horizontal autoscaling of data planes.

### Install {{ site.gateway_operator_product_name }}

{% include prereqs/products/operator.md raw=true v_maj=1 %}

### Install a metrics server

{% include k8s/install_metrics_server.md %}

{% include k8s/autoscale_gateway_with_dataplane_crd.md raw=true %}
