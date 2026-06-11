---
title: Gathering {{site.kic_product_name}} metric information
content_type: support
description: By default, the {{site.kic_product_name}} exposes a metrics endpoint at /metrics over port 10255.
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I gather {{site.kic_product_name}} metric information?
  a: |
    By default, the {{site.kic_product_name}} exposes a `/metrics` endpoint over port `10255`.
    Port forward the controller pod with
    `kubectl port-forward -n kong <KIC pod name> 10255:10255`, then query the endpoint with
    `curl http://localhost:10255/metrics`. This lists all available metrics along with an
    explanation of their meanings.
related_resources:
  - text: "Prometheus metrics documentation for the {{site.kic_product_name}}"
    url: /kubernetes-ingress-controller/observability/prometheus/
---

## Overview

This article describes how to gather {{site.kic_product_name}} metric information.

## Steps

By default, the {{site.kic_product_name}} exposes a metrics endpoint `/metrics` over port `10255`.

Here are the steps to collect the KIC metrics:

1. Port forward the ingress controller pod on port number `10255`. [by default, the `10255` port of the KIC Pod provides a `/metrics` endpoint for access metrics]

   ```bash
   kubectl port-forward -n kong <KIC pod name> 10255:10255
   ```

2. Query the metrics endpoint:

   ```bash
   curl http://localhost:10255/metrics
   ```

This will list all the metrics available, along with an explanation of the meanings of these metrics.
