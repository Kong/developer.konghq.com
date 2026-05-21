---
title: "{{site.base_gateway}} OpenTelemetry metrics reference"
content_type: reference
layout: reference

products:
  - ai-gateway
  - gateway

breadcrumbs:
  - /ai-gateway/

tags:
  - ai
  - monitoring
  - metrics
  - tracing

plugins:
  - opentelemetry

min_version:
  gateway: '3.13'

description: "Reference for OpenTelemetry metrics emitted by {{site.base_gateway}}."

related_resources:
  - text: OpenTelemetry plugin
    url: /plugins/opentelemetry/
  - text: "{{site.base_gateway}} tracing guide"
    url: /gateway/tracing/
  - text: "Gen AI OpenTelemetry metrics reference"
    url: /ai-gateway/ai-otel-metrics/
  - text: "Gen AI OpenTelemetry span attributes"
    url: /ai-gateway/llm-open-telemetry/
  - text: "OpenTelemetry tutorials"
    url: /how-to/?products=gateway&products=ai-gateway&kong_plugins=opentelemetry

works_on:
  - on-prem
  - konnect
---

In {{site.base_gateway}}, metrics are natively supported by the OpenTelemetry plugin. 
You can send metrics using the parameters under [`config.metrics`](/plugins/opentelemetry/reference/#schema--config-metrics).

{:.info}
> To collect AI OTel metrics for {{site.ai_gateway}}, you will need to use the OpenTelemetry plugin with one of the AI Proxy or AI Proxy Advanced plugins. See [Gen AI OpenTelemetry metrics reference](/ai-gateway/ai-otel-metrics/) for details.

The following metrics are exposed:

{% include plugins/otel/metric_tables.md %}

