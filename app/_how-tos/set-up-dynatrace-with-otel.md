---
title: Set up Dynatrace with OpenTelemetry
content_type: how_to
related_resources:
  - text: Kong Premium Partners
    url: /premium-partners/

breadcrumbs:
  - /premium-partners/

act_as_plugin: true
name: Dynatrace
publisher: dynatrace
premium_partner: true
icon: /assets/icons/third-party/dynatrace.png
categories:
  - analytics-monitoring

description: Use Dynatrace's OpenTelemetry Collector to send analytics and monitoring data to Dynatrace dashboards.


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.8'

plugins:
  - opentelemetry

entities: 
  - service
  - route
  - plugin

tags:
    - analytics
    - monitoring
    - premium
    - plugins
    - partnership

tldr:
    q: How do I send {{site.base_gateway}} traces, metrics, and logs to Dynatrace?
    a: You can use the OpenTelemetry plugin with Dynatrace's OpenTelemetry Collector to send analytics and monitoring data to Dynatrace dashboards.

tools:
    - deck

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

@todo https://docs.konghq.com/hub/kong-inc/opentelemetry/how-to/dynatrace/