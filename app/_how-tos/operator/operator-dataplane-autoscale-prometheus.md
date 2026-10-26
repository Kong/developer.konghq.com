---
title: Autoscale workloads with Prometheus
description: 'Use Prometheus and the Gateway Operator to scale Data Plane workloads based on latency or other metrics exposed through the `/metrics` endpoint.'
content_type: how_to

permalink: /operator/dataplanes/how-to/autoscale-workloads/prometheus/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

tools:
  - operator

works_on:
  - konnect
  - on-prem

prereqs:
  kubernetes:
    gateway_api: true
  entities:
    services:
      - command-service
    routes:
      - command

tldr:
  q: How can I autoscale {{ site.base_gateway }} workloads using Prometheus metrics?
  a: |
    Deploy a `DataPlaneMetricsExtension` to expose latency metrics from a Service,
    then configure the {{site.operator_product_name}} to associate those metrics with the Data Plane.
    This enables external tools like Prometheus and KEDA to trigger scaling decisions.
cleanup:
  inline:
    - title: Delete the resources created in this guide
      content: |
        Uninstall the metrics stack this guide installs, delete the resources it created, then remove the operator. Deleting the `kong-system` namespace removes the operator:

        ```bash
        helm uninstall prometheus-adapter -n prometheus
        helm uninstall prometheus -n prometheus
        kubectl delete --ignore-not-found namespace prometheus
        kubectl delete -n kong --ignore-not-found \
          horizontalpodautoscaler/command \
          servicemonitor/gateway-operator \
          httproute/command \
          gateway/kong \
          gatewayconfiguration/kong
        kubectl delete --ignore-not-found gatewayclass/kong
        kubectl delete --ignore-not-found namespace kong
        helm uninstall kong-operator -n kong-system
        kubectl delete --ignore-not-found namespace kong-system
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/kubernetes.svg
---

{% assign gatewayApiVersion = "v1" %}

## Autoscaling Workloads

This tutorial shows how to autoscale workloads based on Service latency. The `command` service created in the prerequisites allows us to inject an artificial delay in to responses to trigger autoscaling.

## Create a `DataPlaneMetricsExtension`

The `DataPlaneMetricsExtension` allows {{ site.operator_product_name }} to monitor Service latency and expose it on the `/metrics` endpoint.

1. Create a `DataPlaneMetricsExtension` that points to the `command` service:

    ```yaml
    echo '
    kind: DataPlaneMetricsExtension
    apiVersion: gateway-operator.konghq.com/v1alpha1
    metadata:
      name: kong
      namespace: kong
    spec:
      serviceSelector:
        matchNames:
        - name: command
      config:
        latency: true
    ' | kubectl apply -f -
    ```
    {: data-test-step="block" }

1. Create a GatewayConfiguration that uses it:

    ```yaml
    echo '
    kind: GatewayConfiguration
    apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
    metadata:
      name: kong
      namespace: kong
    spec:
      extensions:
      - kind: DataPlaneMetricsExtension
        group: gateway-operator.konghq.com
        name: kong
    ' | kubectl apply -f -
    ```
    {: data-test-step="block" }

1. Patch the GatewayClass to use the config:

    ```bash
    kubectl patch -n kong --type=json gatewayclass kong -p='[
        {
            "op":"add",
            "path":"/spec/parametersRef",
            "value":{
                    "group": "gateway-operator.konghq.com",
                    "kind": "GatewayConfiguration",
                    "name": "kong",
                    "namespace": "kong",
            }
        }
    ]'
    ```
    {: data-test-step="block" }

## Install Prometheus

{:.info}
> **Note:** You can reuse your current Prometheus setup and skip this step
> but please be aware that it needs to be able to scrape {{ site.operator_product_name }}'s metrics
> (e.g. through [`ServiceMonitor`](https://github.com/prometheus-operator/prometheus-operator/blob/release-0.53/Documentation/api.md#servicemonitor)) and note down the namespace
> in which it's deployed.

1. Add the `prometheus-community` helm charts:

   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   ```
   {: data-test-step="block" }

1. Install Prometheus via [`kube-prometheus-stack` helm chart](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack):

   ```bash
   helm upgrade --install --create-namespace -n prometheus prometheus prometheus-community/kube-prometheus-stack
   ```
   {: data-test-step="block" }

## Create a ServiceMonitor to scrape {{ site.operator_product_name }}

To make Prometheus scrape {{ site.operator_product_name }}'s `/metrics` endpoint, we'll need to create a `ServiceMonitor`:

```yaml
echo '
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    release: prometheus
  name: gateway-operator
  namespace: kong-system
spec:
  endpoints:
  - port: http
    scheme: http
    path: /metrics
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
  selector:
    matchLabels:
      control-plane: controller-manager ' | kubectl apply -f -
```
{: data-test-step="block" }

After applying the above manifest you can check one of the metrics exposed by {{ site.operator_product_name }}
to verify that the scrape config has been applied.

To access the Prometheus UI, create a port-forward and visit <http://localhost:9090>:

```bash
kubectl port-forward service/prometheus-kube-prometheus-prometheus 9090:9090 -n prometheus
```

This can be verified by going to your Prometheus UI and querying:

```
up{service=~"kong-operator-kong-operator-metrics"}
```

{:.info}
> Prometheus metrics can take up to 2 minutes to appear.

## Install prometheus-adapter

The `prometheus-adapter` package makes Prometheus metrics usable in Kubernetes.

To deploy `prometheus-adapter`, you'll need to decide what time series to expose so that Kubernetes can consume it.

{:.info}
> **Note:** {{ site.operator_product_name }} enriches specific metrics for use with `prometheus-adapter`. See the [overview](/operator/dataplanes/reference/autoscale-workloads/#metrics-support-for-enrichment) for a complete list.

Create a `values.yaml` file to deploy the [`prometheus-adapter` helm chart](https://artifacthub.io/packages/helm/prometheus-community/prometheus-adapter).
This configuration calculates a `kong_upstream_latency_ms_60s_average` metric, which exposes a 60s moving average of upstream response latency:

```yaml
echo $'
prometheus:
  # Update this value if Prometheus is installed in a different namespace
  url: http://prometheus-kube-prometheus-prometheus.prometheus.svc

rules:
  default: false
  custom:
  - seriesQuery: \'{__name__=~"^kong_upstream_latency_ms_(sum|count)",kubernetes_namespace!="",kubernetes_name!="",kubernetes_kind!=""}\'
    resources:
      overrides:
        exported_namespace:
          resource: "namespace"
        exported_service:
          resource: "service"
    name:
      as: "kong_upstream_latency_ms_60s_average"
    metricsQuery: |
      sum by (exported_service) (rate(kong_upstream_latency_ms_sum{<<.LabelMatchers>>}[60s:10s]))
        /
      sum by (exported_service) (rate(kong_upstream_latency_ms_count{<<.LabelMatchers>>}[60s:10s]))
' > values.yaml
```
{: data-test-step="block" }

Install `prometheus-adapter` using Helm:

```bash
helm upgrade --install --create-namespace -n prometheus --values values.yaml prometheus-adapter prometheus-community/prometheus-adapter
```
{: data-test-step="block" }

## Send traffic

1. Wait for the `Gateway` and the `command` `HTTPRoute` to be programmed:

   ```bash
   kubectl wait --for=condition=Programmed gateway/kong -n kong --timeout=5m
   kubectl wait --for=jsonpath='{.status.parents[0].conditions[?(@.type=="Programmed")].status}'=True httproute/command -n kong --timeout=5m
   ```
   {: data-test-step="block" }

1. Get the `Gateway`'s external IP address:

   ```bash
   export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath='{.status.addresses[0].value}')
   ```
   {: data-test-step="block" }

1. To trigger autoscaling, run the following command. This will cause the underlying deployment to sleep for 100ms on each request and thus increase the average response time to that value. The loop sends 100 requests, which builds up enough latency data over the 60 seconds window that the metric uses:

{% validation custom-command %}
command: |
  for _ in {1..100}; do
    curl -k --no-progress-meter --fail-with-body "http://$PROXY_IP/command/shell?cmd=sleep%200.1"
    sleep 1
  done
expected:
  return_code: 0
render_output: false
indent: 3
{% endvalidation %}

## Verify metrics are exposed in Kubernetes

When all is configured, you should be able to see the metric you've configured in `prometheus-adapter` exposed via the Kubernetes Custom Metrics API. Wait until the metric is populated, then query it:

```bash
timeout 240 bash -c 'until kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/kong/services/command/kong_upstream_latency_ms_60s_average" | grep -q kong_upstream_latency_ms_60s_average; do sleep 10; done'
kubectl get --raw '/apis/custom.metrics.k8s.io/v1beta1/namespaces/kong/services/command/kong_upstream_latency_ms_60s_average' | jq
```
{: data-test-step="block" }

{:.warning}
> **Note:** The `prometheus-adapter` may take up to 2 minutes to populate the custom metrics

This should result in:

```json
{
  "kind": "MetricValueList",
  "apiVersion": "custom.metrics.k8s.io/v1beta1",
  "metadata": {},
  "items": [
    {
      "describedObject": {
        "kind": "Service",
        "namespace": "kong",
        "name": "command",
        "apiVersion": "/v1"
      },
      "metricName": "kong_upstream_latency_ms_60s_average",
      "timestamp": "2024-03-06T13:11:12Z",
      "value": "102312m",
      "selector": null
    }
  ]
}
```
{:.no-copy-code}

{:.info}
> **Note:** `102312m` is a Kubernetes way of expressing numbers as integers.
> `value` represents the latency in microseconds, and is approximately equivalent to 102 milliseconds (ms).

## Use exposed metric in HorizontalPodAutoscaler

When the metric configured in `prometheus-adapter` is available through Kubernetes's Custom Metrics API,
we can use it in `HorizontalPodAutoscaler` to autoscale our workload, specifically the `command` `Deployment`.

This can be done by using the following manifest, which will scale the underlying `command` `Deployment` between 1 and 10 replicas, trying to keep the average latency across last 60s at 40ms.

```yaml
echo '
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: command
  namespace: kong
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: command
  minReplicas: 1
  maxReplicas: 10
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 1
      policies:
      - type: Percent
        value: 100
        periodSeconds: 10
    scaleUp:
      stabilizationWindowSeconds: 1
      policies:
      - type: Percent
        value: 100
        periodSeconds: 2
      - type: Pods
        value: 4
        periodSeconds: 2
      selectPolicy: Max

  metrics:
  - type: Object
    object:
      metric:
        name: "kong_upstream_latency_ms_60s_average"
      describedObject:
        apiVersion: v1
        kind: Service
        name: command
      target:
        type: Value
        value: "40" ' | kubectl apply -f -
```
{: data-test-step="block" }

## Observe Kubernetes `SuccessfulRescale` events

You can watch `SuccessfulRescale` events using the following `kubectl` command:

{% validation custom-command %}
command: |
  timeout 60 kubectl get events -n kong --field-selector involvedObject.name=command,involvedObject.kind=HorizontalPodAutoscaler -w | grep -m1 SuccessfulRescale
expected:
  return_code: 0
render_output: false
{% endvalidation %}

If everything went well we should see the `SuccessfulRescale` events:

```bash
12m          Normal   SuccessfulRescale   horizontalpodautoscaler/command   New size: 2; reason: Service metric kong_upstream_latency_ms_60s_average above target
12m          Normal   SuccessfulRescale   horizontalpodautoscaler/command   New size: 4; reason: Service metric kong_upstream_latency_ms_60s_average above target
12m          Normal   SuccessfulRescale   horizontalpodautoscaler/command   New size: 8; reason: Service metric kong_upstream_latency_ms_60s_average above target
12m          Normal   SuccessfulRescale   horizontalpodautoscaler/command   New size: 10; reason: Service metric kong_upstream_latency_ms_60s_average above target
```
{:.no-copy-code}

Then when latency drops (when you stop sending traffic with the `curl` command) you should observe the `SuccessfulRescale` events scaling your workloads down:

```bash
4s          Normal   SuccessfulRescale   horizontalpodautoscaler/command   New size: 1; reason: All metrics below target
```
{:.no-copy-code}
