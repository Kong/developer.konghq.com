---
title: "Autoscaling workloads"
description: "Scale your Kubernetes workloads using latency information from {{ site.base_gateway }}"
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

related_resources:
  - text: Autoscale with Prometheus
    url: /operator/dataplanes/how-to/autoscale-workloads/prometheus/
  - text: Autoscale with Datadog
    url: /operator/dataplanes/how-to/autoscale-workloads/datadog/

---

{{ site.base_gateway }} provides extensive metrics through its [Prometheus plugin](/plugins/prometheus/). However, these metrics are labelled with Kong entities such as `Service` and `Route` rather than Kubernetes resources.

{{ site.operator_product_name }} can scrape {{ site.base_gateway }} and enrich it with Kubernetes metadata so that it can be used by users to autoscale their workloads.

{{ site.operator_product_name }} provides [`DataPlaneMetricsExtension`](/operator/reference/custom-resources/#dataplanemetricsextension), which scrapes the Kong metrics and enriches them with Kubernetes labels before exposing them on it's own `/metrics` endpoint.

These enriched metrics can be used with the Kubernetes [`HorizontalPodAutoscaler`](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) to autoscale workloads.

## How it works

Attaching a `DataPlaneMetricsExtension` resource to a `ControlPlane` will:

- Create a managed Prometheus `KongPlugin` instance with the [configuration](/plugins/prometheus/reference/) defined in [`MetricsConfig`](/operator/reference/custom-resources/#metricsconfig)
- Append the managed plugin to the selected `Service`s (through `DataPlaneMetricsExtension`'s [`serviceSelector`](/operator/reference/custom-resources/#serviceselector) field)
   `konghq.com/plugins` annotation
- Scrape {{ site.base_gateway }}'s metrics and enrich them with Kubernetes metadata
- Expose those metrics on {{ site.operator_product_name }}'s `/metrics` endpoint

## Metrics support for enrichment

- Upstream latency enabled via `latency` configuration option
  - `kong_upstream_latency_ms`

## Custom metrics providers support

Metrics exposed by {{ site.operator_product_name }} can be integrated with a variety of monitoring systems:

- [Prometheus](/operator/dataplanes/how-to/autoscale-workloads/prometheus/)
- [Datadog](/operator/dataplanes/how-to/autoscale-workloads/datadog/)

## Limitations

### Multi backend Kong services

{{ site.operator_product_name }} is not able to provide accurate measurements for multi backend Kong Services. For example, `HTTPRoute`s that have more than 1 `backendRef`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httproute-testing
spec:
  parentRefs:
  - name: kong
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /httproute-testing
    backendRefs:
    - name: httpbin
      kind: Service
      port: 80
      weight: 75
    - name: nginx
      kind: Service
      port: 8080
      weight: 25
```
