---
title: Choosing the correct Grafana dashboard for Kong Gateway
content_type: support
description: Kong publishes two Grafana dashboards, a legacy Vitals-based one and a current Prometheus plugin one, and only the Prometheus plugin dashboard has data on Kong Gateway 3.11.0.0 and later, since Vitals is deprecated and gated behind an extra license entitlement.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: What is the correct Grafana chart for Kong?
  a: |
    Kong publishes two Grafana dashboards for Kong Gateway: a Vitals-based Prometheus dashboard and a Prometheus-plugin dashboard. As of Kong Gateway 3.11.0.0, Vitals is deprecated, disabled by default, and gated behind an extra license entitlement most Enterprise licenses lack, so use the Prometheus plugin dashboard unless Vitals is specifically enabled and licensed.
related_resources:
  - text: Kong Vitals Prometheus dashboard (Grafana)
    url: "https://grafana.com/grafana/dashboards/11870-kong-vitals-prometheus-official/"
  - text: Kong official Prometheus plugin dashboard (Grafana)
    url: "https://grafana.com/grafana/dashboards/7424-kong-official/"
---

## Choosing the correct Grafana dashboard for Kong Gateway

Looking at Grafana dashboards for Kong I see two available for download. Which one is the correct one to use?

Kong Gateway supports uploading "Vitals" metrics to Prometheus for scraping into Grafana dashboards. In the case of visualizing Kong Gateway Vitals metrics you should use the Kong Vitals Prometheus dashboard.

Note: As of Kong Gateway 3.11.0.0 and later (including 3.14.0.0), Vitals is deprecated and disabled by default (`vitals = off`). Even on a standard Enterprise license, Vitals — and therefore the Prometheus Vitals strategy this dashboard is built to visualize — is gated behind an additional, undocumented license entitlement that most Enterprise licenses do not carry. If Vitals is not enabled and unlocked on your license, this dashboard will not have any data to display. For current metrics visualization, use the Prometheus plugin dashboard below instead.

Kong Gateway also has a plugin that can be applied to services and routes to export more detailed data to Prometheus. If you wish to visualize this data using Grafana, the recommended dashboard is the Kong official Prometheus plugin dashboard.
