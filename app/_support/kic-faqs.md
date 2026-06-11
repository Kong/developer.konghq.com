---
title: "{{site.kic_product_name}} FAQs"
content_type: support
description: "Answers to common questions about {{site.kic_product_name}}, including gathering metrics and creating additional Kubernetes resources with the Helm chart."
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: Where can I find answers to common {{site.kic_product_name}} questions?
  a: |
    This page collects frequently asked questions about {{site.kic_product_name}}: how to gather
    metrics from the controller, and how to create additional Kubernetes resources when deploying
    with the Kong Helm chart.
related_resources: []
---

## Observability

### How do I gather {{site.kic_product_name}} metrics?

By default, the {{site.kic_product_name}} exposes a `/metrics` endpoint over port `10255`.

1. Port forward the controller pod on port `10255`:

   ```bash
   kubectl port-forward -n kong <KIC pod name> 10255:10255
   ```

2. Query the metrics endpoint:

   ```bash
   curl http://localhost:10255/metrics
   ```

This lists all available metrics along with an explanation of their meanings. To export these metrics to Prometheus, see the [Prometheus and Grafana documentation](/kubernetes-ingress-controller/observability/prometheus/).

## Helm chart

### How do I create additional Kubernetes resources with the Helm chart?

The Kong Helm charts support an array parameter, `extraObjects`, that you can use to create additional Kubernetes resources on deployment. Each new resource is an entry in the array. For example, the following array contains two manifests that create Kubernetes `Secret` objects:

```yaml
image:
  repository: kong/kong-gateway

extraObjects:
  - apiVersion: v1
    data:
      kongCredType: YmFzaWMtYXV0aA==
      password: a29uZw==
      username: Z3J1YmVy
    kind: Secret
    metadata:
      name: basic-auth
  - apiVersion: v1
    data:
      password: a29uZw==
      username: bWNjbGFuZQo=
    kind: Secret
    metadata:
      name: uid-pw
```

For the full list of chart options, see the [Kong Helm chart parameters](https://github.com/Kong/charts/tree/main/charts/kong#general-parameters).
