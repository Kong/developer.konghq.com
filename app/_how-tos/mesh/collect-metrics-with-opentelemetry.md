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
  - observability
related_resources:
  - text: Mesh Metric policy
    url: /mesh/policies/meshmetric/
  - text: Policy Hub
    url: /mesh/policies/
  - text: Service meshes
    url: /mesh/service-mesh/
next_steps:
  - text: Mesh Metric policy
    url: /mesh/policies/meshmetric/
  - text: Mesh Access Log policy with OpenTelemetry
    url: /mesh/policies/meshaccesslog/#opentelemetry
  - text: Mesh Trace policy with OpenTelemetry
    url: /mesh/policies/meshtrace/#opentelemetry
min_version:
  mesh: '2.9'
tldr:
  q: How do I collect metrics with OpenTelemetry in {{site.mesh_product_name}}?
  a: Install the {{site.mesh_product_name}} observability stack, deploy an OpenTelemetry collector with Helm, configure Prometheus to scrape the collector, and apply a `MeshMetric` policy to push data plane proxy metrics to the collector. Then view the metrics in the Grafana `Dataplane` dashboard.
faqs:
  - q: Can I use the same OpenTelemetry collector for traces and logs?
    a: Yes. This guide focuses on metrics, but you can extend the collector to handle traces and logs by adding `traces` and `logs` pipelines to the `service.pipelines` section of the configuration.
  - q: Where else can I export metrics to?
    a: |
      The `exporters` section controls where the metrics are sent. You can export to Datadog, Grafana Cloud, Honeycomb, and many other backends. See the [OpenTelemetry registry](https://opentelemetry.io/ecosystem/registry/?component=exporter) for the full list.
  - q: Can I filter or transform metrics before they're exported?
    a: |
      Yes. The OpenTelemetry collector supports processors that filter, modify, and batch metrics. The example configuration in this guide uses the `batch` processor. For the full list, see the [contrib processor catalog](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor).
  - q: Which OpenTelemetry collector distribution does this guide use?
    a: |
      This guide uses the [contrib distribution](https://github.com/open-telemetry/opentelemetry-collector-contrib), which bundles a wide range of receivers, processors, and exporters maintained by the OpenTelemetry community.
prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart
    - title: Install kumactl
      include_content: prereqs/tools/kumactl
    - title: Cursor
      content: |
        This guide uses Cursor as the editor for `kubectl edit`:
        1. Go to the [Cursor downloads](https://cursor.com/downloads) page.
        2. Download the installer for your operating system.
        3. Install Cursor on your machine.
        4. In Cursor, open the Command Palette and run **Shell Command: Install 'cursor' command in PATH**.
      icon_url: /assets/icons/cursor.svg
---

{{site.mesh_product_name}} integrates with [OpenTelemetry](https://opentelemetry.io/). You can collect and push data plane proxy and application metrics to an [OpenTelemetry collector](https://opentelemetry.io/docs/collector/), which lets you process and export metrics to multiple ecosystems, including [Dash0](https://www.dash0.com/), [Datadog](https://www.datadoghq.com/), [Middleware](https://middleware.io/), [Grafana Cloud](https://grafana.com/products/cloud/), and [Honeycomb](https://www.honeycomb.io/).

## Set up kumactl

Set up kumactl to install the observability stack:

1. Run the following command to expose the control plane's API server. We'll need this to access kumactl:

   ```sh
   kubectl port-forward svc/kong-mesh-control-plane -n kong-mesh-system 5681:5681
   ```

1. In a new terminal, check that kumactl is installed and that its directory is in your path:

   ```sh
   kumactl
   ```

   If the command is not found:

   1. Make sure that kumactl is [installed](#install-kumactl)
   1. Add the {{site.mesh_product_name}} binaries directory to your path:

      ```sh
      export PATH=$PATH:$(pwd)/{{site.mesh_product_name_path}}-{{site.data.mesh_latest.version}}/bin
      ```

## Install the {{site.mesh_product_name}} observability stack

The {{site.mesh_product_name}} observability stack is built on top of [Prometheus](https://prometheus.io/) and [Grafana](https://grafana.com/). You use this stack to scrape metrics from the OpenTelemetry collector and visualize them on {{site.mesh_product_name}} dashboards.

1. Install the observability stack:

   ```sh
   kumactl install observability | kubectl apply -f-
   ```

1. The quickstart guide applies restrictive `MeshTrafficPermission` policies, so allow traffic in the `mesh-observability` namespace:

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

## Install the OpenTelemetry collector

1. Create the OpenTelemetry collector configuration:

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

   This configuration makes the OpenTelemetry collector receive metrics on gRPC port `4317` from the data plane proxies and expose them in Prometheus format on port `8889`. Prometheus scrapes those metrics in the next step.

   `MY_POD_IP` is the collector pod's own IP. You don't need to set it: the OpenTelemetry collector Helm chart automatically injects it into each pod via the Kubernetes [Downward API](https://kubernetes.io/docs/concepts/workloads/pods/downward-api/).

1. Install the collector:

   ```sh
   helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
   helm install --namespace mesh-observability opentelemetry-collector open-telemetry/opentelemetry-collector -f values-otel.yaml
   ```

## Configure Prometheus to scrape the OpenTelemetry collector

1. Open the `prometheus-server` ConfigMap:

   ```sh
   KUBE_EDITOR='cursor --wait' kubectl edit configmap/prometheus-server -n mesh-observability
   ```

1. In the `prometheus.yml` value, add the following entry under `scrape_configs`:

   ```yaml
       - job_name: opentelemetry-collector
         scrape_interval: 15s
         static_configs:
         - targets:
           - opentelemetry-collector.mesh-observability.svc:8889
   ```

1. Save and close the file to apply the changes.

   Prometheus automatically picks up this config and starts scraping the OpenTelemetry collector.

1. Forward the Prometheus port to confirm the config was applied:

   ```sh
   kubectl port-forward svc/prometheus-server -n mesh-observability 9090:80
   ```

1. Open <http://127.0.0.1:9090/targets> and confirm the `opentelemetry-collector` target appears.

## Enable OpenTelemetry metrics

Apply the [Mesh Metric](/mesh/policies/meshmetric/) policy:

```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: otel-metrics
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: opentelemetry-collector.mesh-observability.svc:4317' | kubectl apply -f -
```

This policy configures all data plane proxies in the `default` Mesh to collect and push metrics to the OpenTelemetry collector.

## Generate traffic

1. Port-forward the demo app service on port `5050`:

   ```sh
   kubectl port-forward svc/demo-app -n kong-mesh-demo 5050:5050
   ```

1. Go to <http://127.0.0.1:5050> to open the demo app UI.

1. Enable **Auto-increment** to generate traffic.

## Validate

1. Forward the Grafana service:

   ```sh
   kubectl port-forward svc/grafana -n mesh-observability 3000:80
   ```

1. Open <http://127.0.0.1:3000> and log in with the default credentials `admin/admin`.

1. Click **Dashboard**.

1. Click **KUma Dataplane**.
   
   After a few minutes, you should see traffic data in the **HTTP** section.
