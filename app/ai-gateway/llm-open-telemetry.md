---
title: "Gen AI OpenTelemetry spans attributes reference"
content_type: reference
layout: reference

toc_depth: 4

products:
  - ai-gateway
  - gateway

breadcrumbs:
  - /ai-gateway/

tags:
  - ai
  - monitoring
  - tracing

plugins:
  - opentelemetry
  - ai-proxy
  - ai-proxy-advanced

min_version:
  gateway: '3.13'

tech_preview: true

description: "Reference for OpenTelemetry Gen AI span attributes emitted by {{site.ai_gateway}} for generative AI requests."

related_resources:
  - text: "Gen AI OpenTelemetry metrics reference"
    url: /ai-gateway/ai-otel-metrics/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: OpenTelemetry plugin
    url: /plugins/opentelemetry/
  - text: Zipkin plugin
    url: /plugins/zipkin/
  - text: "{{site.base_gateway}} tracing guide"
    url: /gateway/tracing/
  - text: Set up Jaeger with Gen AI OpenTelemetry
    url: /how-to/set-up-jaeger-with-gen-ai-otel/
  - text: Validate Gen AI tool calls with Jaeger and OpenTelemetry
    url: /how-to/set-up-jaeger-with-gen-ai-otel-for-tool-calls/

works_on:
  - on-prem
  - konnect
---

{% new_in 3.13 %} {{site.ai_gateway}} supports [OpenTelemetry](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/#genai-attributes) instrumentation for generative AI traffic. When the OpenTelemetry (OTEL) plugin is enabled in {{site.ai_gateway}}, a set of **Gen AI-specific attributes** are emitted on tracing spans. These attributes complement the core tracing instrumentations described in the [{{site.base_gateway}} tracing guide](/gateway/tracing), giving insight into the Gen AI request lifecycle (inputs, model, and outputs), usage, and tool/agent interactions. {% new_in 3.14 %} [A2A agent traffic](#a2a-span-attributes) is also instrumented via the [AI A2A Proxy plugin](/plugins/ai-a2a-proxy/).

You can export these attributes via a supported backend such as [Jaeger](/how-to/set-up-jaeger-with-otel/) configured through Kong's [OpenTelemetry plugin](/plugins/opentelemetry) or the [Zipkin plugin](/plugins/zipkin) to:

* Inspect which model or provider handled a request
* Track conversation/session identifiers across requests
* Analyze prompt structure (system vs. user vs. tool messages)
* Evaluate model parameters (such as temperature, top-k)
* Measure tool-call behavior (which tools were invoked, and their metadata)
* Monitor token usage (input vs. output) for cost or performance analysis

The span data is sent to the configured OTEL endpoint through the existing tracing plugins. Use the OpenTelemetry plugin or Zipkin plugin to export these spans to backends such as Jaeger.

{:.info}
> This page covers **span attributes** (per-request tracing data). {{site.ai_gateway}} also supports **OTLP metrics** (aggregated counters and histograms for latency, token usage, cost, and error rates). See the [Gen AI OpenTelemetry metrics reference](/ai-gateway/ai-otel-metrics/) for details.

{% include plugins/otel/collecting-otel-data.md  %}

{:.warning}
> Some Gen AI span attributes can include sensitive request or response payload data. In particular, `gen_ai.input.messages` and `gen_ai.output.messages` may contain prompts, model outputs, PII, secrets, or credentials. Review your tracing, retention, access-control, and redaction requirements before enabling or exporting payload-related tracing data.

{% include plugins/otel/span_attribute_tables.md %}




