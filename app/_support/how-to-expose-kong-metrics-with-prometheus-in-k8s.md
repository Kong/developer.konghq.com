---
title: How to expose Kong metrics with Prometheus in K8s
content_type: support
description: "Install Prometheus and configure a Kong Helm deployment with `serviceMonitor.enabled: true` so the Prometheus Operator can scrape Kong's metrics endpoint."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I expose Kong's metrics to Prometheus when Kong is deployed with Helm in Kubernetes?
  a: |
    Install Prometheus (e.g. via the `kube-prometheus-stack` Helm chart), set `serviceMonitor.enabled: true` in the Kong Helm chart's `values.yaml` so a `ServiceMonitor` object is created, and enable the Prometheus plugin globally to scrape Kong's proxy traffic metrics.
related_resources:
  - text: Kong Helm chart Prometheus Operator integration documentation
    url: https://github.com/Kong/charts/blob/main/charts/kong/README.md#prometheus-operator-integration
  - text: Kong Gateway Kubernetes install guide (Konnect)
    url: /gateway/install/kubernetes/konnect/
  - text: Kong Helm chart `ServiceMonitor` parameters
    url: https://github.com/Kong/charts/blob/kong-2.41.0/charts/kong/README.md#general-parameters
  - text: Prometheus plugin documentation
    url: /plugins/prometheus/
---

## Overview

I installed Kong using a Helm chart in Kubernetes — how do I expose Kong's metrics to Prometheus?

## Steps

1. Install Prometheus

   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   kubectl create ns monitoring
   helm upgrade -i prometheus prometheus-community/kube-prometheus-stack \
   --namespace monitoring \
   --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
   --set fullnameOverride=prometheus
   kubectl get all -n monitoring
   ```

   This Prometheus deployment is only for demo purposes and isn't suitable for a production environment.

2. Install Kong

   The following parameter is required in `values.yaml` when installing Kong with the Helm chart:

   ```yaml
   serviceMonitor:
     enabled: true
   ```

   Set this parameter in `values.yaml` and install Kong.

   This configuration creates a `ServiceMonitor` object in the same namespace as Kong, as shown in the example below, which tells Prometheus how to scrape metrics from Kong.

   ```yaml
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     labels:
       app.kubernetes.io/instance: kong
       app.kubernetes.io/managed-by: Helm
       app.kubernetes.io/name: kong
       app.kubernetes.io/version: "3.14"
       helm.sh/chart: kong-2.41.0
     name: kong-kong
     namespace: kong
   spec:
     endpoints:
     - scheme: http
       targetPort: status
     - scheme: http
       targetPort: cmetrics
     jobLabel: kong
     namespaceSelector:
       matchNames:
       - kong
     selector:
       matchLabels:
         app.kubernetes.io/instance: kong
         app.kubernetes.io/managed-by: Helm
         app.kubernetes.io/name: kong
         app.kubernetes.io/version: "3.14"
         enable-metrics: "true"
         helm.sh/chart: kong-2.41.0
   ```

3. Enable a global Prometheus plugin

   Enable the Prometheus plugin globally, then create `Service` and `Route` objects in Kong for proxy requests to upstreams. After that, send a few requests to Kong.

4. Forward port 9090 of the Prometheus Kubernetes service to localhost and check the metrics

   ```bash
   # Execute command to port forward 9090 port of the Prometheus K8S SVC to localhost
   kubectl port-forward service/prometheus-prometheus -n monitoring 9090:9090
   ```

   Now you can access `http://localhost:9090/` to open the Prometheus dashboard. You can see Kong's metrics on the Prometheus dashboard.
