---
title: How to send metrics and logs to Datadog in a Kubernetes environment
content_type: support
description: Steps to send Kong metrics and logs to Datadog in a Kubernetes environment, using the Datadog Agent, the `prometheus` plugin, and Autodiscovery pod annotations.
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "Datadog Kong integration documentation"
    url: "https://docs.datadoghq.com/integrations/kong/?tab=containerized"
  - text: "Datadog site documentation"
    url: "https://docs.datadoghq.com/getting_started/site/"
  - text: "Datadog API and application keys documentation"
    url: "https://docs.datadoghq.com/account_management/api-app-keys/"
  - text: "Datadog Helm chart repository"
    url: "https://github.com/DataDog/helm-charts"
  - text: "Prometheus plugin documentation"
    url: "/plugins/prometheus/"
  - text: "Kong Helm chart podAnnotations reference"
    url: "https://github.com/Kong/charts/blob/main/charts/kong/values.yaml#L1040-L1042"
  - text: "Kong Helm chart status endpoint reference"
    url: "https://github.com/Kong/charts/blob/main/charts/kong/values.yaml#L235-L241"
tldr:
  q: How do I send Kong metrics and logs to Datadog in a Kubernetes environment?
  a: |
    Create a Datadog account and API key, then install the Datadog Agent via Helm. Enable the `prometheus` plugin in Kong so Datadog can scrape metrics via OpenMetrics, and add `podAnnotations` to the Kong Helm chart so Datadog's Autodiscovery can collect metrics and logs from Kong pods.
---

## Overview

How to send metrics and logs to Datadog in a Kubernetes environment?

## Steps

The procedure is described in the Datadog documentation.

1. Create an account in Datadog in a Datadog site, notice that each Datadog site is independent.

   ```bash
   export DD_SITE=datadoghq.eu
   ```

2. Create an API key on your Datadog account.

   ```bash
   export DD_API_KEY=123456789123456789123456789
   ```

3. Install the Datadog Agent via Helm chart.

   ```bash
   helm install datadog  \
   --set datadog.site=$DD_SITE \
   --set datadog.apiKey=$DD_API_KEY \
   --set datadog.logs.enabled=true \
   --set datadog.logs.containerCollectAll=true \
   --set datadog.kubelet.tlsVerify=false \
   datadog/datadog
   ```

   (`datadog.kubelet.tlsVerfiy = false` is required when running tests in minikube.)

4. Datadog uses OpenMetrics to scrape metrics, we need to run the `prometheus` plugin in Kong.

   ```yaml
   apiVersion: configuration.konghq.com/v1
   kind: KongClusterPlugin
   metadata:
     name: plugin-prometheus
     annotations:
       kubernetes.io/ingress.class: kong
     labels:
       global: "true"
   plugin: prometheus
   ```

   ```bash
   kubectl apply -f prometheus-plugin.yaml
   ```

5. Add required `podAnnotations` in the Kong Helm chart to allow the Datadog agent to use Autodiscovery to collect metrics and logs from Kong pods:

   ```yaml
   podAnnotations:
     ad.datadoghq.com/proxy.check_names: '["kong"]'
     ad.datadoghq.com/proxy.init_configs: '[{}]'
     ad.datadoghq.com/proxy.instances: '[{"openmetrics_endpoint": "http://%%host%%:8100/metrics"}]'
     ad.datadoghq.com/proxy.logs: '[{"source": "kong", "service": "kong-proxy"}]'
     ad.datadoghq.com/ingress-controller.logs: '[{"source": "kong", "service": "kong-ingress-controller"}]'
   ```

6. Make sure that the status endpoint is enabled on your Helm chart.
