---
title: Monitor {{site.base_gateway}} with Prometheus using direct scraping
description: "Learn how to enable and scrape Prometheus metrics from your data plane."
content_type: how_to
permalink: /operator/how-to/observability/prometheus-direct-scraping/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"
products:
  - operator

tldr:
  q: How can I scrape data plane metrics using Prometheus?
  a: |
    Create a `KongPlugin` resource for the `prometheus` plugin, and apply the plugin using `KongPluginBinding` or the `konghq.com/plugins` annotation.

works_on:
  - konnect
  - on-prem

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true
  inline:
    - title: Create Gateway resources
      include_content: /prereqs/operator/gateway
---

{% include /operator/prometheus.md %}

In this example, we'll use direct scraping.

## Enable the Prometheus plugin

Create a `KongPlugin` resource to enable the [Prometheus](/plugins/prometheus/) plugin:

```sh
echo '
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: prometheus-global
  namespace: kong
plugin: prometheus
config:
  bandwidth_metrics: true
  latency_metrics: true
  status_code_metrics: true' | kubectl apply -f -
```

## Apply the plugin globally

{% navtabs "Deployment" %}
{% navtab "Konnect" %}

Create a `KongPluginBinding` resource and set `spec.scope` to `GlobalInControlPlane`:
```sh
echo '
apiVersion: configuration.konghq.com/v1alpha1
kind: KongPluginBinding
metadata:
  name: global-prometheus
  namespace: kong
spec:
  pluginRef:
    name: prometheus-global
  scope: GlobalInControlPlane
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane' | kubectl apply -f -
```
{% endnavtab %}

{% navtab "Self-managed" %}

Enable the plugin by annotating the `Gateway` resource with `konghq.com/plugins: prometheus-global`:

```sh
echo '
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
  namespace: kong
  annotations:
    konghq.com/plugins: prometheus-global
spec:
  gatewayClassName: gateway-class
  listeners:
  - name: proxy
    port: 80
    protocol: HTTP' | kubectl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

## Validate

You can verify that metrics are being collected by port-forwarding to the data plane Pod:

1. Get the data plane Pod name:
   ```bash
   POD_NAME=$(kubectl get pods -n kong -o jsonpath='{.items[0].metadata.name}')
   ```

1. Port forward the metrics port:
   ```sh
   kubectl port-forward $POD_NAME 8100:8100 -n kong
   ```

1. Access the metrics:
   ```bash
   curl http://localhost:8100/metrics | grep kong_
   ```
