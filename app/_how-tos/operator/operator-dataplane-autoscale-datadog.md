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
  inline:
    - title: Get Datadog API and application keys
      include_content: /prereqs/operator/datadog-account

tldr:
  q: How can I autoscale {{site.base_gateway}} workloads using Datadog metrics?
  a: |
    Deploy a `DataPlaneMetricsExtension` to collect metrics (like latency) from a target service,
    expose those metrics on the `/metrics` endpoint, and configure the operator to reference this
    data for scaling decisions.

---

{% assign gatewayApiVersion = "v1" %}

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

1. Create the following configuration file:

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

1. Install [Datadog's helm chart](https://github.com/DataDog/helm-charts/tree/main/charts/datadog):

   ```bash
   helm repo add datadog https://helm.datadoghq.com
   helm repo update
   helm install -n default datadog -f values.yaml --set datadog.apiKey=${DD_API_KEY} --set datadog.appKey=${DD_APP_KEY} --set datadog.site=${DD_SITE} datadog/datadog
   ```

1. Wait for the `DatadogMetric` CRD to be established before continuing:

   ```bash
   kubectl wait --for=condition=Established crd/datadogmetrics.datadoghq.com --timeout=120s
   ```

## Send traffic

To trigger autoscaling, run the following command in a new terminal window. This will cause the underlying deployment to sleep for 100ms on each request and thus increase the average response time to that value.

```bash
while curl -k "http://$(kubectl get gateway kong -o custom-columns='name:.status.addresses[0].value' --no-headers -n kong)/command/shell?cmd=sleep%200.1" ; do sleep 1; done
```

Keep this running while we move on to next steps.

## Annotate {{ site.operator_product_name }} with Datadog checks config

In a new terminal window, add the following annotation on {{ site.operator_product_name }}'s Pod to tell Datadog how to scrape {{ site.operator_product_name }}'s metrics:

```bash
POD_NAME=$(kubectl get pods -n kong-system -l control-plane=controller-manager -o custom-columns='name:.metadata.name' --no-headers)
kubectl annotate -n kong-system pod $POD_NAME \
  'ad.datadoghq.com/manager.checks={
    "openmetrics": {
      "instances": [
        {
          "prometheus_url": "http://%%host%%:8080/metrics",
          "namespace": "autoscaling",
          "metrics": [
            "kong_upstream_latency_ms"
          ],
          "send_histograms_buckets": true,
          "send_distribution_buckets": true
        }
      ]
    }
  }'
```

After applying the above you should see `avg:autoscaling.kong_upstream_latency_ms{service:command}` metrics in your Datadog Metrics explorer.

## Expose Datadog metrics to Kubernetes

To use an external metric in `HorizontalPodAutoscaler`, we need to configure the Datadog agent to expose it.

There are several ways to achieve this but we'll use a Kubernetes native way and
use the [`DatadogMetric` CRD](https://docs.datadoghq.com/containers/guide/cluster_agent_autoscaling_metrics/?tab=helm#autoscaling-with-datadogmetric-queries):

```yaml
echo '
apiVersion: datadoghq.com/v1alpha1
kind: DatadogMetric
metadata:
  name: command-kong-upstream-latency-ms-avg
  namespace: kong
spec:
  query: autoscaling.kong_upstream_latency_ms{service:command} ' | kubectl apply -f -
```

{:.info}
> **Note:** The Datadog Cluster Agent only starts refreshing a `DatadogMetric`'s status once it's referenced by a `HorizontalPodAutoscaler`. Its `ACTIVE`/`VALID`/`VALUE` fields will stay empty until you create the HPA in the next section — that's expected, not an error.

### Use `DatadogMetric` in `HorizontalPodAutoscaler`

The `command-kong-upstream-latency-ms-avg` `DatadogMetric` from the `kong` namespace can be used by the Kubernetes `HorizontalPodAutoscaler` to autoscale our workload, specifically the `command` `Deployment`. The `HorizontalPodAutoscaler` must be created in the same namespace as the `command` `Deployment` it targets, which is `kong`.

1. Run the following command to scale the underlying `command` `Deployment` between 1 and 10 replicas, trying to keep the average latency across last 30s at 40ms:

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
     - type: External
       external:
         metric:
           name: datadogmetric@kong:command-kong-upstream-latency-ms-avg
         target:
           type: Value
           value: 40 ' | kubectl apply -f -
   ```

1. Once the HPA is created, wait for `DatadogMetric` to become active and valid:

   ```bash
   kubectl wait --for=jsonpath='{.status.conditions[?(@.type=="Active")].status}'=True -n kong datadogmetric/command-kong-upstream-latency-ms-avg --timeout=120s
   kubectl wait --for=jsonpath='{.status.conditions[?(@.type=="Valid")].status}'=True -n kong datadogmetric/command-kong-upstream-latency-ms-avg --timeout=120s
   kubectl get -n kong datadogmetric command-kong-upstream-latency-ms-avg
   ```
   
   You should get the following result:
   
   ```bash
   NAME                                   ACTIVE   VALID   VALUE               REFERENCES          UPDATE TIME
   command-kong-upstream-latency-ms-avg   True     True    104.46194839477539  hpa:kong/command   38s
   ```
   {:.no-copy-code}


## Validate

1. Run the following command to get the `command-kong-upstream-latency-ms-avg` metric via the Kubernetes External Metrics API:

   ```bash
   kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/kong/datadogmetric@kong:command-kong-upstream-latency-ms-avg" | jq
   ```

   You should get the following result:

   ```json
   {
     "kind": "ExternalMetricValueList",
     "apiVersion": "external.metrics.k8s.io/v1beta1",
     "metadata": {},
     "items": [
       {
         "metricName": "datadogmetric@kong:command-kong-upstream-latency-ms-avg",
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

1. Check for `SuccessfulRescale` events:

   ```bash
   kubectl get events -n kong --field-selector involvedObject.name=command,involvedObject.kind=HorizontalPodAutoscaler,reason=SuccessfulRescale --sort-by='.lastTimestamp'
   ```

   The result should look like this:

   ```bash
   LAST SEEN   TYPE     REASON              OBJECT                            MESSAGE
   38s         Normal   SuccessfulRescale   horizontalpodautoscaler/command   New size: 5; reason: external metric datadogmetric@kong:command-kong-upstream-latency-ms-avg(nil) above target
   23s         Normal   SuccessfulRescale   horizontalpodautoscaler/command   New size: 10; reason: external metric datadogmetric@kong:command-kong-upstream-latency-ms-avg(nil) above target
   ```
   {:.no-copy-code}
