---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
---

The OpenTelemetry [AI Policy](/ai-gateway/entities/ai-policy/) provides metrics, traces, and logs in the OpenTelemetry format and can be used with any OpenTelemetry compatible backend.

You can configure a OpenTelemetry AI Policy to apply globally across every resource on your {{site.ai_gateway}} or only on resources where it is referenced.

The OpenTelemetry AI Policy allows you to collect data for the following signals:
* [Metrics](#metrics)
* [Traces](#tracing)
* [Logging](#logging)

## Use cases

Common use cases for the OpenTelemetry AI Policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Monitor AI Agent traffic with OpenTelemetry](/ai-gateway/monitor-ai-agent-with-opentelemetry/)"
    description: Export A2A traces and metrics to an OTLP collector

  - use_case: "[Monitor MCP traffic with OpenTelemetry](/ai-gateway/monitor-mcp-traffic-with-otel/)"
    description: Export OTLP metrics for MCP tool traffic to a collector.

{% endtable %}
<!--vale on-->

{% include /md/ai-gateway/v2/policies/otel/collecting-otel-data.md plugin=page.name %}

## Resource attributes

The OpenTelemetry AI Policy attaches additional resource attributes to all telemetry data it sends to an OTLP endpoint. Resource attributes describe the entity that produced the telemetry and are shared across all signals.

The OpenTelemetry AI Policy automatically sets the following resource attributes:

{% include /md/ai-gateway/v2/policies/otel/resource_attributes.md %}

You can add or override resource attributes by configuring the [`config.resource_attributes`](./reference/#schema--config-resource-attributes) parameter. Custom resource attributes are merged with the default attributes and are included with all exported telemetry data. Some metric backends, such as Prometheus, apply resource attributes to every metric. Be mindful of the impact on cardinality.