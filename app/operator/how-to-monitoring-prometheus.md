---
title: Monitor Kong Gateway with Prometheus
description: "Learn how to enable and scrape Prometheus metrics from your Data Plane using the Prometheus plugin and DataPlaneMetricsExtension."
content_type: how_to
permalink: /operator/how-to/observability/prometheus/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"
products:
  - operator
---

Monitoring your Gateway is critical for understanding traffic patterns, latency, and system health. {{ site.operator_product_name }} provides two ways to collect metrics with Prometheus:

1.  **Direct Data Plane Scraping**: Standard Prometheus plugin metrics scraped directly from the Data Plane pods.
2.  **Enriched Operator Metrics**: Using the `DataPlaneMetricsExtension` to enrich metrics with Kubernetes metadata and re-expose them via the Operator's metrics endpoint.

## Prerequisites

- {{ site.operator_product_name }} installed and running.
- A `Gateway` and `DataPlane` deployed.
- Prometheus installed in your cluster (e.g., via the kube-prometheus-stack).

---

## Method 1: Direct Data Plane Scraping (Basic)

This method enables the standard Kong Prometheus plugin. Metrics are exposed on each Data Plane pod on port `8100` (by default).

### 1. Enable the Prometheus Plugin

Create a `KongPlugin` resource to enable Prometheus:

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: prometheus-global
  namespace: kong
plugin: prometheus
config:
  bandwidth_metrics: true
  latency_metrics: true
  status_code_metrics: true
```

### 2. Apply the Plugin Globally

- **Konnect-Managed**: Use `KongPluginBinding` with `scope: GlobalInControlPlane`.
- **Self-Managed**: Use the `konghq.com/plugins` annotation on your `Gateway` or `HTTPRoute` resource, or use a `KongPluginBinding` targeting specific routes.

#### Example: Konnect Global Binding

```yaml
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
      name: gateway-control-plane
```

#### Example: Self-Managed Gateway Annotation

For standalone Gateway deployments, you can enable the plugin by annotating the `Gateway` resource:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
  namespace: kong
  annotations:
    konghq.com/plugins: prometheus-global
spec:
  gatewayClassName: kong
  listeners:
  - name: proxy
    port: 80
    protocol: HTTP
```

### 3. Verify the Endpoint

You can verify that metrics are being collected by port-forwarding to a Data Plane pod:

```bash
# Find a Data Plane pod
POD_NAME=$(kubectl get pods -n kong -l app=dataplane-kong -o jsonpath='{.items[0].metadata.name}')

# Port forward the metrics port (default 8100)
kubectl port-forward $POD_NAME 8100:8100 -n kong
```

Access the metrics:
```bash
curl http://localhost:8100/metrics | grep kong_
```

---

## Method 2: Enriched Metrics via DataPlaneMetricsExtension (Advanced)

The `DataPlaneMetricsExtension` allows the Operator to scrape Data Plane metrics, enrich them with Kubernetes-specific metadata (like Pod names and Namespaces), and re-expose them on the Operator's own `/metrics` endpoint.

### 1. Create a DataPlaneMetricsExtension

This resource defines which metrics to collect and which Data Plane services to scrape.

```yaml
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
    - name: dataplane-ingress-kong # The name of the Data Plane service
```

### 2. Attach the Extension

Attach the extension to your `GatewayConfiguration` or a self-managed `ControlPlane`.

#### Option A: GatewayConfiguration (for Gateways)

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: kong-config
  namespace: kong
spec:
  extensions:
  - group: gateway-operator.konghq.com
    kind: DataPlaneMetricsExtension
    name: gateway-metrics
```

#### Option B: ControlPlane (Self-Managed)

If you are using the `ControlPlane` CRD directly:

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: my-control-plane
  namespace: kong
spec:
  extensions:
  - group: gateway-operator.konghq.com
    kind: DataPlaneMetricsExtension
    name: gateway-metrics
```

### 3. Scrape from the Operator

Once attached, the Operator will begin re-exposing these metrics on its own metrics service (default port 8443).

Enriched metrics will have a `k8s_` prefix or additional labels identifying the source Kubernetes resources.


### Example ServiceMonitor for Data Planes

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kong-dataplane-monitor
  namespace: monitoring
spec:
  selector:
    matchLabels:
      gateway-operator.konghq.com/managed-by: dataplane
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
```

### Example ServiceMonitor for the Operator (Enriched Metrics)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kong-operator-monitor
  namespace: monitoring
spec:
  selector:
    matchLabels:
      control-plane: controller-manager
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
```
