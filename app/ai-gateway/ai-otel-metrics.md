---
title: "Gen AI OpenTelemetry metrics reference"
content_type: reference
layout: reference

products:
  - ai-gateway

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
  ai-gateway: '2.0'

tech_preview: true
toc_depth: 2

description: "Reference for OpenTelemetry metrics emitted by {{site.ai_gateway}} for generative AI, MCP, and A2A traffic."

related_resources:
  - text: "Gen AI OpenTelemetry span attributes"
    url: /ai-gateway/llm-open-telemetry/
  - text: "Monitor AI LLM metrics (Prometheus)"
    url: /ai-gateway/monitor-ai-llm-metrics/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: OpenTelemetry plugin
    url: /plugins/opentelemetry/
  - text: Full OpenTelemetry metrics reference
    url: /gateway/otel-metrics/
  - text: "{{site.base_gateway}} tracing guide"
    url: /gateway/tracing/

works_on:
  - konnect
---

{{site.ai_gateway}} can export OpenTelemetry (OTLP) metrics for generative AI, MCP, and A2A traffic through an [OpenTelemetry AI Policy](/plugins/opentelemetry/). These metrics are aggregated time-series data points (counters, histograms) pushed to a configured OTLP metrics endpoint on a regular interval. They are separate from the per-request [Gen AI span attributes](/ai-gateway/llm-open-telemetry/) emitted on traces.

You can use these metrics to:

* Track LLM request latency and upstream provider processing time
* Monitor token consumption across providers, models, and consumers
* Measure time-to-first-token (TTFT) and inter-token latency (TPOT) for streaming responses
* Calculate AI request costs
* Observe MCP tool-call latency, error rates, and ACL decisions
* Monitor A2A agent request volume, duration, and task state transitions

## Prerequisites

To collect AI OTLP metrics, enable the following settings:

<!-- vale off -->
{% table %}
columns:
  - title: Setting
    key: setting
  - title: Policy
    key: policy
  - title: Required for
    key: required_for
rows:
  - setting: "`config.metrics.enable_ai_metrics`: `true`"
    policy: "[OpenTelemetry](/plugins/opentelemetry/reference/)"
    required_for: "All AI metrics"
  - setting: "`config.metrics.endpoint`"
    policy: "[OpenTelemetry](/plugins/opentelemetry/reference/)"
    required_for: "All AI metrics (set to a valid OTLP-compatible metrics endpoint)"
  - setting: "`config.logging.log_statistics`: `true`"
    policy: "[AI Proxy](/plugins/ai-proxy/reference/) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/reference/)"
    required_for: "[Gen AI metrics](#gen-ai-metrics-otel-semantic-conventions)"
  - setting: "`config.logging.log_statistics`: `true`"
    policy: "[AI MCP Proxy](/plugins/ai-mcp-proxy/reference/)"
    required_for: "[MCP metrics](#mcp-metrics)"
  - setting: "`config.logging.log_statistics`: `true`"
    policy: "[AI A2A Proxy](/plugins/ai-a2a-proxy/reference/)"
    required_for: "[A2A metrics](#a2a-metrics)"
{% endtable %}
<!-- vale on -->

Some metrics have additional requirements:

* `gen_ai.server.request.duration` and `mcp.client.operation.duration` require `config.metrics.enable_latency_metrics` set to `true` in the [OpenTelemetry AI Policy](/plugins/opentelemetry/reference/).
* The `error.type` attribute on duration metrics requires `config.metrics.enable_request_metrics` set to `true` in the [OpenTelemetry AI Policy](/plugins/opentelemetry/reference/).

## Gen AI metrics (OTLP semantic conventions)

These metrics follow the [OpenTelemetry Gen AI semantic conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-metrics/). They capture request duration, upstream latency, token usage, and streaming performance.

### Metric reference

{% include md/ai-gateway/v2/policies/metric_tables.md metric_prefixes="gen_ai." %}

## Kong Gen AI metrics

These metrics use the `kong.gen_ai.*` namespace and capture Kong-specific AI observability data, including cost tracking, cache and RAG latency, and AWS Guardrails processing time.

To populate `kong.gen_ai.llm.cost`, define `model.options.input_cost` and `model.options.output_cost` in your model configuration.

{% include md/ai-gateway/v2/policies/metric_tables.md metric_prefixes="kong.gen_ai." %}

## MCP metrics

These metrics provide observability into MCP (Model Context Protocol) server interactions, including latency, response sizes, errors, and ACL decisions.

{% include md/ai-gateway/v2/policies/metric_tables.md metric_prefixes="mcp.,kong.gen_ai.mcp." %}

## A2A metrics

These metrics provide observability into [A2A (Agent-to-Agent)](/plugins/ai-a2a-proxy/) traffic, including request volume, latency, response sizes, and task state transitions.

{% include md/ai-gateway/v2/policies/metric_tables.md metric_prefixes="kong.gen_ai.a2a." %}
