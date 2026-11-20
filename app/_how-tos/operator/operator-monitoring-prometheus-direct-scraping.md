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
  inline:
    - title: Create Gateway resources
      include_content: /prereqs/operator/gateway
cleanup:
  inline:
    - title: Delete the resources created in this guide
      content: |
        Deleting the `Gateway` also deletes the control plane and data plane resources {{ site.operator_product_name }} created for it. Deleting the `kong-system` namespace removes the operator:

        ```bash
        kubectl delete -n kong --ignore-not-found \
          kongpluginbinding/global-prometheus \
          kongplugin/prometheus-global \
          gateway/kong \
          gatewayconfiguration/gateway-configuration
        kubectl delete --ignore-not-found gatewayclass/gateway-class
        kubectl delete --ignore-not-found namespace kong
        helm uninstall kong-operator -n kong-system
        kubectl delete --ignore-not-found namespace kong-system
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/kubernetes.svg
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
{: data-test-step="block" }

## Apply the plugin globally

{% konnect %}
content: |
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
        name: kong' | kubectl apply -f -
  ```
  {: data-test-step="block" }
{% endkonnect %}

{% on_prem %}
content: |
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
  {: data-test-step="block" }
{% endon_prem %}

## Validate

You can verify that metrics are being collected by port-forwarding to the data plane Pod:

1. Wait for the `Gateway` to be programmed:

   ```sh
   kubectl wait --for=condition=Programmed gateway/kong -n kong --timeout=300s
   ```
   {: data-test-step="block" }

1. Get the data plane Pod name:

   ```bash
   POD_NAME=$(kubectl get pods -n kong -o jsonpath='{.items[0].metadata.name}')
   ```
   {: data-test-step="block" }

1. Port forward the metrics port. Run the port-forward in the background so that the next command can use it:

   ```sh
   kubectl port-forward $POD_NAME 8100:8100 -n kong >/dev/null 2>&1 &
   ```
   {: data-test-step="block" }

1. Access the metrics:

   <!-- vale off -->
{% validation custom-command %}
command: |
  curl -s http://localhost:8100/metrics | grep -m1 kong_
expected:
  return_code: 0
  message: 'kong_'
render_output: false
indent: 3
{% endvalidation %}
<!-- vale on -->
