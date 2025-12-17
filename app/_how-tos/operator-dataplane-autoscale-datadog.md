---
title: Autoscale workloads with Datadog
description: 'Use the Gateway Operator and Datadog metrics to automatically scale {{site.base_gateway}} Data Plane workloads.'
content_type: how_to

permalink: /operator/dataplanes/how-to/autoscale-workloads/datadog/
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
  enterprise: true
  kubernetes:
    gateway_api: true
  entities:
    services:
      - command-service
    routes:
      - command

tldr:
  q: How can I autoscale {{site.base_gateway}} workloads using Datadog metrics?
  a: |
    Deploy a `DataPlaneMetricsExtension` to collect metrics (like latency) from a target service,
    expose those metrics on the `/metrics` endpoint, and configure the operator to reference this
    data for scaling decisions.

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

1. Create a GatewayConfiguration that uses it:

    ```bash
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

{{ site.operator_product_name }} can be integrated with [Datadog Metrics](https://docs.datadoghq.com/metrics/) in order to use {{ site.base_gateway }} latency metrics to autoscale workloads based on their metrics.

## Install Datadog in your Kubernetes cluster

### Datadog API and application keys

To install Datadog agents in your cluster you will need a Datadog API key
and an application key. Please refer to [this Datadog manual page](https://docs.datadoghq.com/account_management/api-app-keys/) to obtain those.

### Installing

To install Datadog in your cluster, you can follow [this guide](https://docs.datadoghq.com/containers/kubernetes/installation/?tab=helm)
or use the following `values.yaml`:

```yaml
echo '
datadog:
  kubelet:
    tlsVerify: false

clusterAgent:
  enabled: true
  # Enable the metricsProvider to be able to scale based on metrics in Datadog
  metricsProvider:
    # Set this to true to enable Metrics Provider
    enabled: true
    # Enable usage of DatadogMetric CRD to autoscale on arbitrary Datadog queries
    useDatadogMetrics: true

  prometheusScrape:
    enabled: true
    serviceEndpoints: true

agents:
  containers:
    agent:
      env:
      - name: DD_HOSTNAME
        valueFrom:
          fieldRef:
            fieldPath: spec.nodeName
' > values.yaml
```

To install [Datadog's helm chart](https://github.com/DataDog/helm-charts/tree/main/charts/datadog):

```bash
helm repo add datadog https://helm.datadoghq.com
helm repo update
helm install -n datadog datadog --set datadog.apiKey=${DD_APIKEY} --set datadog.AppKey=${DD_APPKEY} datadog/datadog
```

## Send traffic

To trigger autoscaling, run the following command in a new terminal window. This will cause the underlying deployment to sleep for 100ms on each request and thus increase the average response time to that value.

```bash
while curl -k "http://$(kubectl get gateway kong -o custom-columns='name:.status.addresses[0].value' --no-headers -n default)/echo/shell?cmd=sleep%200.1" ; do sleep 1; done
```

Keep this running while we move on to next steps.

## Annotate {{ site.operator_product_name }} with Datadog checks config

Add the following annotation on {{ site.operator_product_name }}'s Pod to tell Datadog how to scrape {{ site.operator_product_name }}'s metrics:

```bash
POD_NAME=$(kubectl get pods -n kong-system -o custom-columns='name:.metadata.name' --no-headers)
kubectl annotate -n kong-system pod $POD_NAME \
  'ad.datadoghq.com/kube-rbac-proxy.checks={
    "openmetrics": {
      "instances": [
        {
          "prometheus_url": "https://%%host%%:8080/metrics",
          "namespace": "autoscaling",
          "metrics": [
            "kong_upstream_latency_ms_bucket",
            "kong_upstream_latency_ms_sum",
            "kong_upstream_latency_ms_count"
          ],
          "send_histograms_buckets": true,
          "send_distribution_buckets": true
        }
      ]
    }
  }'
```

After applying the above you should see `avg:autoscaling.kong_upstream_latency_ms{service:echo}` metrics in your Datadog Metrics explorer.

## Expose Datadog metrics to Kubernetes

To use an external metric in `HorizontalPodAutoscaler`, we need to configure the Datadog agent to expose it.

There are several ways to achieve this but we'll use a Kubernetes native way and
use the [`DatadogMetric` CRD](https://docs.datadoghq.com/containers/guide/cluster_agent_autoscaling_metrics/?tab=helm#autoscaling-with-datadogmetric-queries):

```yaml
echo '
apiVersion: datadoghq.com/v1alpha1
kind: DatadogMetric
metadata:
  name: echo-kong-upstream-latency-ms-avg
  namespace: default
spec:
  query: autoscaling.kong_upstream_latency_ms{service:echo} ' | kubectl apply -f -
```

You can check the status of `DatadogMetric` with:

```bash
kubectl get -n default datadogmetric echo-kong-upstream-latency-ms-avg -w
```

Which should look like this:

```bash
NAME                                ACTIVE   VALID   VALUE               REFERENCES         UPDATE TIME
echo-kong-upstream-latency-ms-avg   True     True    104.46194839477539                     38s
```

You should be able to get the metric via Kubernetes External Metrics API within 30 seconds:

```bash
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/default/datadogmetric@default:echo-kong-upstream-latency-ms-avg" | jq
```

```json
{
  "kind": "ExternalMetricValueList",
  "apiVersion": "external.metrics.k8s.io/v1beta1",
  "metadata": {},
  "items": [
    {
      "metricName": "datadogmetric@default:echo-kong-upstream-latency-ms-avg",
      "metricLabels": null,
      "timestamp": "2024-03-08T18:03:02Z",
      "value": "104233138021n"
    }
  ]
}
```
{:.no-copy-code}

{:.info}
> **Note:** `104233138021n` is a Kubernetes way of expressing numbers as integers.
> Since `value` here represents latency in milliseconds, it is approximately equivalent to 104.23ms.

### Use `DatadogMetric` in `HorizontalPodAutoscaler`

When we have the metric already available in Kubernetes External API we can use it in HPA like so:

The `echo-kong-upstream-latency-ms-avg` `DatadogMetric` from `default` namespace can be used by the Kubernetes `HorizontalPodAutoscaler` to autoscale our workload: specifically the `echo` `Deployment`.

The following manifest will scale the underlying `echo` `Deployment` between 1 and 10 replicas, trying to keep the average latency across last 30s at 40ms.

```yaml
echo '
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: echo
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: echo
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
  - type: External
    external:
      metric:
        name: datadogmetric@default:echo-kong-upstream-latency-ms-avg
      target:
        type: Value
        value: 40 ' | kubectl apply -f -
```

When everything is configured correctly, `DatadogMetric`'s status will update and it will now have a reference to the `HorizontalPodAutoscaler`:

Get the `DatadogMetric` using `kubectl`:

```bash
kubectl get -n default datadogmetric echo-kong-upstream-latency-ms-avg -w
```

You will see the HPA reference in the output:

```bash
NAME                                ACTIVE   VALID   VALUE               REFERENCES         UPDATE TIME
echo-kong-upstream-latency-ms-avg   True     True    104.46194839477539  hpa:default/echo  38s
```
{:.no-copy-code}

If everything went well we should see the `SuccessfulRescale` events:

```bash
12m          Normal   SuccessfulRescale   horizontalpodautoscaler/echo   New size: 2; reason: Service metric kong_upstream_latency_ms_30s_average above target
12m          Normal   SuccessfulRescale   horizontalpodautoscaler/echo   New size: 4; reason: Service metric kong_upstream_latency_ms_30s_average above target
12m          Normal   SuccessfulRescale   horizontalpodautoscaler/echo   New size: 8; reason: Service metric kong_upstream_latency_ms_30s_average above target
12m          Normal   SuccessfulRescale   horizontalpodautoscaler/echo   New size: 10; reason: Service metric kong_upstream_latency_ms_30s_average above target

# Then when latency drops
4s          Normal   SuccessfulRescale   horizontalpodautoscaler/echo   New size: 1; reason: All metrics below target
```
{:.no-copy-code}
