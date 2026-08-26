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
  - text: OpenTelemetry Policy
    url: /ai-gateway/policies/opentelemetry/
  - text: "{{site.base_gateway}} OpenTelemetry metrics reference"
    url: /gateway/otel-metrics/
  - text: "{{site.base_gateway}} tracing guide"
    url: /gateway/tracing/
  - text: "{{site.ai_gateway}} audit log reference"
    url: /ai-gateway/ai-audit-log-reference/
  - text: Model cost management
    url: /ai-gateway/model-cost-management/

works_on:
  - konnect
---

{{site.ai_gateway}} can export OpenTelemetry (OTLP) metrics for generative AI, MCP, and A2A traffic through an [OpenTelemetry AI Policy](/ai-gateway/policies/opentelemetry/). These metrics are aggregated time-series data points (counters, histograms) pushed to a configured OTLP metrics endpoint on a regular interval. They are separate from the per-request [Gen AI span attributes](/ai-gateway/llm-open-telemetry/) emitted on traces.

You can use these metrics to:

* Track LLM request latency and upstream provider processing time
* Monitor token consumption across AI Model Providers, AI Models, and AI Consumers
* Measure time-to-first-token (TTFT) and inter-token latency (TPOT) for streaming responses
* Calculate AI request costs
* Observe MCP tool-call latency, error rates, and ACL decisions
* Monitor A2A agent request volume, duration, and task state transitions

## Prerequisites

{% include /md/ai-gateway/v2/policies/otel/ai-metric-setup.md  %}

## Gen AI metrics (OTLP semantic conventions)

These metrics follow the [OpenTelemetry Gen AI semantic conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-metrics/). They capture request duration, upstream latency, token usage, and streaming performance.

### Metric reference

{% include md/ai-gateway/v2/policies/otel/metric_tables.md metric_prefixes="gen_ai." %}

## Kong Gen AI metrics

These metrics use the `kong.gen_ai.*` namespace and capture Kong-specific AI observability data, including cost tracking, cache and RAG latency, and AWS Guardrails processing time.

To populate `kong.gen_ai.llm.cost`, define `targets[].config.input_cost` and `targets[].config.output_cost` in your AI Model configuration.

{% include md/ai-gateway/v2/policies/otel/metric_tables.md metric_prefixes="kong.gen_ai." %}

## MCP metrics

These metrics provide observability into MCP (Model Context Protocol) server interactions, including latency, response sizes, errors, and ACL decisions.

{% include md/ai-gateway/v2/policies/otel/metric_tables.md metric_prefixes="mcp.,kong.gen_ai.mcp." %}

## A2A metrics

These metrics provide observability into [A2A (Agent-to-Agent)](/ai-gateway/entities/ai-agent/) traffic, including request volume, latency, response sizes, and task state transitions.

{% include md/ai-gateway/v2/policies/otel/metric_tables.md metric_prefixes="kong.gen_ai.a2a." %}
