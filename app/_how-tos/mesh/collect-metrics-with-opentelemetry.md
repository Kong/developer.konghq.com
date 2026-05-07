---
title: Collect metrics with OpenTelemetry
description: "Collect and export metrics from {{site.mesh_product_name}} with OpenTelemetry and visualize them using Prometheus and Grafana."
content_type: how_to
permalink: /mesh/collect-metrics-with-opentelemetry/
products:
  - mesh
breadcrumbs:
  - /mesh/
works_on:
  - on-prem
tags:
  - metrics
related_resources:
  - text: Mesh observability
    url: /mesh/observability/
  - text: Policy Hub
    url: /mesh/policies/
  - text: Service meshes
    url: /mesh/service-mesh/
min_version:
  mesh: '2.7'
tldr:
  q: How do I collect metrics with OpenTelemetry in {{site.mesh_product_name}}?
  a: By the end of this guide, you will export {{site.mesh_product_name}} data plane proxy metrics through an OpenTelemetry collector and visualize them with Prometheus and Grafana.
prereqs:
  inline:
    - title: Complete the Kubernetes quickstart
      content: |
        Follow the [Deploy Kong Mesh on Kubernetes](/mesh/kubernetes/) guide to set up a zone control plane and the demo application.
    - title: Generate traffic from the demo application
      content: |
        Open [http://127.0.0.1:5000](http://127.0.0.1:5000) and enable auto-increment in the demo app UI.
---

{% assign kuma = site.mesh_install_archive_name | default: "kuma" %}
{% assign kuma-system = site.mesh_namespace | default: "kuma-system" %}
{% assign kuma-control-plane = kuma | append: "-control-plane" %}

{{site.mesh_product_name}} integrates with [OpenTelemetry](https://opentelemetry.io/). You can collect and push data plane proxy and application metrics to an [OpenTelemetry collector](https://opentelemetry.io/docs/collector/). This lets you process and export metrics to multiple ecosystems, including [Dash0](https://www.dash0.com/), [Datadog](https://www.datadoghq.com/), [Middleware](https://middleware.io/), [Grafana Cloud](https://grafana.com/products/cloud/), and [Honeycomb](https://www.honeycomb.io/).

## Install {{site.mesh_product_name}} observability stack

To start, install the {{site.mesh_product_name}} observability stack, which is built on top of [Prometheus](https://prometheus.io/) and [Grafana](https://grafana.com/).

```sh
kumactl install observability | kubectl apply -f-
```

You will use this stack to scrape metrics from the OpenTelemetry collector and visualize them on {{site.mesh_product_name}} dashboards.

The quickstart guide applies restrictive `MeshTrafficPermission` policies, so allow traffic in the `mesh-observability` namespace:

{% if_version lte:2.8.x %}
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: {{ site.mesh_namespace }}
  name: allow-observability
spec:
  targetRef:
    kind: MeshSubset
    tags:
      k8s.kuma.io/namespace: mesh-observability
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          k8s.kuma.io/namespace: mesh-observability
      default:
        action: Allow" | kubectl apply -f -
```
{% endif_version %}

{% if_version gte:2.9.x %}
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: mesh-observability
  name: allow-observability
spec:
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow" | kubectl apply -f -
```
{% endif_version %}

{% if_version gte:2.11.x %}
{:.info}
> If you are already familiar with the quickstart, you can set up the required environment with the following commands.

```sh
helm upgrade \
  --install \
  --create-namespace \
  --namespace {{ kuma-system }} \{% if version == "preview" %}
  --version {{ page.version }} \{% endif %}
  {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
```

```sh
kubectl wait -n {{ kuma-system }} --for=condition=ready pod --selector=app={{ kuma-control-plane }} --timeout=90s
```

```sh
kubectl apply -f kuma-demo://k8s/001-with-mtls.yaml
```
{% endif_version %}

<!-- vale Google.Headings = NO -->
## Install OpenTelemetry collector
<!-- vale Google.Headings = YES -->

First, create the OpenTelemetry collector configuration:

```sh
echo "
mode: deployment
config:
  exporters:
    prometheus:
      endpoint: \${env:MY_POD_IP}:8889
  extensions:
    health_check:
      endpoint: \${env:MY_POD_IP}:13133
  processors:
    batch: {}
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: \${env:MY_POD_IP}:4317
  service:
    extensions:
      - health_check
    pipelines:
      metrics:
        receivers: [otlp]
        exporters: [prometheus]
        processors: [batch]
ports:
  otlp:
    enabled: true
    containerPort: 4317
    servicePort: 4317
    hostPort: 4317
    protocol: TCP
    appProtocol: grpc
  prometheus:
    enabled: true
    containerPort: 8889
    servicePort: 8889
    protocol: TCP
image:
  repository: 'otel/opentelemetry-collector-contrib'
resources:
  limits:
    cpu: 250m
    memory: 512Mi
" > values-otel.yaml
```

This Helm chart configuration makes the OpenTelemetry collector listen on gRPC port `4317` for metrics pushed by the data plane proxy. It then processes those metrics and exposes them in Prometheus format on port `8889`. In the next step, you will configure Prometheus to scrape those metrics. This configuration uses [the contrib distribution](https://github.com/open-telemetry/opentelemetry-collector-contrib) of OpenTelemetry Collector.

The most important part of this configuration is the `pipelines` section:

```yaml
pipelines:
  metrics:
    receivers: [otlp]
    exporters: [prometheus]
```

This guide focuses on metrics, but you can extend the same collector to handle traces and logs. The `otlp` receiver accepts metrics pushed from data plane proxies.

The configuration also includes recommended processors to limit memory usage and process metrics in batches. You can filter, modify, and further process data with [available processors](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor).

The `exporters` section controls where the metrics are sent. You can export metrics to Prometheus, Datadog, Grafana Cloud, and more. See the [OpenTelemetry registry](https://opentelemetry.io/ecosystem/registry/?component=exporter) for the full list of exporters.

Add the Helm repository:

```sh
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```

Install the collector:

```sh
helm install --namespace mesh-observability opentelemetry-collector open-telemetry/opentelemetry-collector -f values-otel.yaml
```

## Configure Prometheus to scrape metrics from OpenTelemetry collector

Update the `prometheus-server` ConfigMap and add the following `scrape_configs` entry:

```yaml
- job_name: "opentelemetry-collector"
  scrape_interval: 15s
  static_configs:
    - targets: ["opentelemetry-collector.mesh-observability.svc:8889"]
```

Prometheus automatically picks up this config and starts scraping the OpenTelemetry collector. To confirm the config was applied, forward the Prometheus port:

```sh
kubectl port-forward svc/prometheus-server -n mesh-observability 9090:80
```

Then open [http://127.0.0.1:9090/targets](http://127.0.0.1:9090/targets) and confirm the `opentelemetry-collector` target appears.

## Enable OpenTelemetry metrics

By now, you have installed and configured the required observability tools: OpenTelemetry collector, Prometheus, and Grafana.

Apply the [Mesh Metric](/mesh/policies/meshmetric/) policy:

{% if_version lte:2.8.x %}
```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: otel-metrics
  namespace: {{ site.mesh_namespace }}
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: opentelemetry-collector.mesh-observability.svc:4317' | kubectl apply -f -
```
{% endif_version %}

{% if_version gte:2.9.x %}
```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: otel-metrics
  namespace: {{ site.mesh_namespace }}
  labels:
    kuma.io/mesh: default
spec:
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: opentelemetry-collector.mesh-observability.svc:4317' | kubectl apply -f -
```
{% endif_version %}

This policy configures all data plane proxies in the `default` Mesh to collect and push metrics to the OpenTelemetry collector.

## Validate

Forward the Grafana service:

```sh
kubectl port-forward svc/grafana -n mesh-observability 3000:80
```

Open [http://127.0.0.1:3000](http://127.0.0.1:3000) and log in with the default credentials `admin/admin`.

Confirm the `Dataplane` dashboard shows traffic metrics from your demo application. Metrics can take a minute or two to appear.

To continue exploring OpenTelemetry in {{site.mesh_product_name}}, see [Mesh Metric](/mesh/policies/meshmetric/), [Mesh Access Log](/mesh/policies/meshaccesslog/#opentelemetry), and [Mesh Trace](/mesh/policies/meshtrace/#opentelemetry).
