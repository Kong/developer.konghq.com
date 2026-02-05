---
# @TODO KO 2.1
title: Monitor {{site.base_gateway}} with Prometheus using enriched metrics
description: "Learn how to enable enriched Prometheus metrics using DataPlaneMetricsExtension."
content_type: how_to
permalink: /operator/how-to/observability/prometheus-enriched-metrics/
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
  q: TODO
  a: |
    TODO
    
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

related_resources:
  - text: Monitor {{site.base_gateway}} with Prometheus using direct scraping
    url: /operator/how-to/observability/prometheus-direct-scraping/
---

{% include /operator/prometheus.md %}

In this example, we'll use enriched metrics. For an example of direct scraping, see [Monitor {{site.base_gateway}} with Prometheus using direct scraping](/operator/how-to/observability/prometheus-direct-scraping/)

## Install Prometheus

1. Add the `prometheus-community` helm charts:

   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   ```

1. Install Prometheus via [`kube-prometheus-stack` helm chart](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack):

   ```bash
   helm upgrade --install -n kong prometheus prometheus-community/kube-prometheus-stack
   ```

## Create a DataPlaneMetricsExtension

This resource defines which metrics to collect and which Data Plane services to scrape.

```sh
echo '
apiVersion: gateway-operator.konghq.com/v1alpha1
kind: DataPlaneMetricsExtension
metadata:
  name: gateway-metrics
  namespace: kong
spec:
  config:
    latency: true
    bandwidth: true
    statusCode: true
    upstreamHealth: true
  serviceSelector:
    matchNames:
    - name: dataplane-ingress-kong' | kubectl apply -f -
```

## Attach the extension

Attach the extension to your `GatewayConfiguration` or a self-managed `ControlPlane`.

#### Option A: GatewayConfiguration (for Gateways)

```sh
echo '
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: gateway-configuration
  namespace: kong
spec:
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
            - image: kong/kong-gateway:3.13
              name: proxy
  extensions:
  - group: gateway-operator.konghq.com
    kind: DataPlaneMetricsExtension
    name: gateway-metrics' | kubectl apply -f -
```

#### Option B: ControlPlane (Self-Managed)

If you are using the `ControlPlane` CRD directly:

```sh
echo '
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: kong
  namespace: kong
spec:
  extensions:
  - group: gateway-operator.konghq.com
    kind: DataPlaneMetricsExtension
    name: gateway-metrics' | kubectl apply -f -
```

## Scrape from the Operator

Once attached, the Operator will begin re-exposing these metrics on its own metrics service (default port 8443).

Enriched metrics will have a `k8s_` prefix or additional labels identifying the source Kubernetes resources.

```sh
echo '
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kong-dataplane-monitor
  namespace: kong
spec:
  selector:
    matchLabels:
      gateway-operator.konghq.com/managed-by: dataplane
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s' | kubectl apply -f -
```

```sh
echo '
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kong-operator-monitor
  namespace: kong-system
spec:
  selector:
    matchLabels:
      control-plane: controller-manager
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s' | kubectl apply -f -
```
