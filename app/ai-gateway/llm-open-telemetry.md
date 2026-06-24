---
title: "Gen AI OpenTelemetry spans attributes reference"
content_type: reference
layout: reference

toc_depth: 4

products:
  - ai-gateway

breadcrumbs:
  - /ai-gateway/

tags:
  - ai
  - monitoring
  - tracing

plugins:
  - opentelemetry

min_version:
  ai-gateway: '2.0'

tech_preview: true

description: "Reference for OpenTelemetry Gen AI span attributes emitted by {{site.ai_gateway}} for generative AI requests."

related_resources:
  - text: "Gen AI OpenTelemetry metrics reference"
    url: /ai-gateway/ai-otel-metrics/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: OpenTelemetry Policy
    url: /plugins/opentelemetry/
  - text: Zipkin Policy
    url: /plugins/zipkin/
  - text: "{{site.base_gateway}} tracing guide"
    url: /gateway/tracing/

works_on:
  - konnect
---

{{site.ai_gateway}} supports [OpenTelemetry](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/#genai-attributes) instrumentation for generative AI traffic. When an OpenTelemetry (OTEL) Policy is enabled in {{site.ai_gateway}}, a set of **Gen AI-specific attributes** are emitted on tracing spans. These attributes provide insight into the Gen AI request lifecycle (inputs, model, and outputs), usage, and tool or agent interactions. 

You can also capture [A2A agent traffic](#a2a-span-attributes) by enabling statistics logging on [AI Agents](/ai-gateway/entities/ai-agent/#logging-and-observability).

You can export these attributes via a supported backend to:

* Inspect which model or provider handled a request
* Track conversation/session identifiers across requests
* Analyze prompt structure (system vs. user vs. tool messages)
* Evaluate model parameters (such as temperature, top-k)
* Measure tool-call behavior (which tools were invoked, and their metadata)
* Monitor token usage (input vs. output) for cost or performance analysis

The span data is sent to the configured OTEL endpoint through the [Kong tracing](/gateway/tracing/). Use a Policy configured with OpenTelemetry or Zipkin to export these spans to backends such as Jaeger.

{:.info}
> This page covers **span attributes** (per-request tracing data). {{site.ai_gateway}} also supports **OTLP metrics** (aggregated counters and histograms for latency, token usage, cost, and error rates). See the [Gen AI OpenTelemetry metrics reference](/ai-gateway/ai-otel-metrics/) for details.

{:.warning}
> Some Gen AI span attributes can include sensitive request or response payload data. In particular, `gen_ai.input.messages` and `gen_ai.output.messages` may contain prompts, model outputs, PII, secrets, or credentials. Review your tracing, retention, access-control, and redaction requirements before enabling or exporting payload-related tracing data.

## Span attribute reference

{% include md/ai-gateway/v2/policies/span_attribute_tables.md %}




