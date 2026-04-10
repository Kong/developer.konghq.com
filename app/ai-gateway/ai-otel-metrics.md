---
title: "Gen AI OpenTelemetry metrics reference"
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
  - ai-proxy
  - ai-proxy-advanced

min_version:
  gateway: '3.14'

tech_preview: true
toc_depth: 2

description: "Reference for OpenTelemetry metrics emitted by {{site.ai_gateway}} for generative AI, MCP, and A2A traffic."

related_resources:
  - text: "Gen AI OpenTelemetry span attributes"
    url: /ai-gateway/llm-open-telemetry/
  - text: "Monitor AI LLM metrics (Prometheus)"
    url: /ai-gateway/monitor-ai-llm-metrics/
  - text: "Proxy A2A agents through {{site.ai_gateway}}"
    url: /how-to/proxy-a2a-agents/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: OpenTelemetry plugin
    url: /plugins/opentelemetry/
  - text: "{{site.base_gateway}} tracing guide"
    url: /gateway/tracing/

works_on:
  - on-prem
  - konnect
---

{% new_in 3.14 %} {{site.ai_gateway}} can export OpenTelemetry (OTLP) metrics for generative AI, MCP, and A2A traffic through the [OpenTelemetry plugin](/plugins/opentelemetry/). These metrics are aggregated time-series data points (counters, histograms) pushed to a configured OTLP metrics endpoint on a regular interval. They are separate from the per-request [Gen AI span attributes](/ai-gateway/llm-open-telemetry/) emitted on traces.

For a step-by-step setup using an OpenTelemetry Collector, see [Collect metrics, logs, and traces with the OpenTelemetry plugin](/how-to/collect-metrics-logs-and-traces-with-opentelemetry/). To visualize Gen AI traces in Jaeger, see [Set up Jaeger with Gen AI OpenTelemetry](/how-to/set-up-jaeger-with-gen-ai-otel/).

Use these metrics to:

* Track LLM request latency and upstream provider processing time
* Monitor token consumption across providers, models, and consumers
* Measure time-to-first-token (TTFT) and inter-token latency (TPOT) for streaming responses
* Calculate AI request costs
* Observe MCP tool-call latency, error rates, and ACL decisions
* Monitor A2A agent request volume, duration, and task state transitions

## Prerequisites

To collect AI OTel metrics, enable the following settings:

<!-- vale off -->
{% table %}
columns:
  - title: Setting
    key: setting
  - title: Plugin
    key: plugin
  - title: Required for
    key: required_for
rows:
  - setting: "`config.metrics.enable_ai_metrics`: `true`"
    plugin: "[OpenTelemetry](/plugins/opentelemetry/reference/)"
    required_for: "All AI metrics"
  - setting: "`config.metrics.endpoint`"
    plugin: "[OpenTelemetry](/plugins/opentelemetry/reference/)"
    required_for: "All AI metrics (set to a valid OTLP-compatible metrics endpoint)"
  - setting: "`config.logging.log_statistics`: `true`"
    plugin: "[AI Proxy](/plugins/ai-proxy/reference/) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/reference/)"
    required_for: "[Gen AI metrics](#gen-ai-metrics-otel-semantic-conventions)"
  - setting: "`config.logging.log_statistics`: `true`"
    plugin: "[AI MCP Proxy](/plugins/ai-mcp-proxy/reference/)"
    required_for: "[MCP metrics](#mcp-metrics)"
  - setting: "`config.logging.log_statistics`: `true`"
    plugin: "[AI A2A Proxy](/plugins/ai-a2a-proxy/reference/)"
    required_for: "[A2A metrics](#a2a-metrics)"
{% endtable %}
<!-- vale on -->

Some metrics have additional requirements:

* `gen_ai.server.request.duration` and `mcp.client.operation.duration` require `config.metrics.enable_latency_metrics` set to `true` in the [OpenTelemetry plugin](/plugins/opentelemetry/reference/).
* The `error.type` attribute on duration metrics requires `config.metrics.enable_request_metrics` set to `true` in the [OpenTelemetry plugin](/plugins/opentelemetry/reference/).

## Gen AI metrics (OTel semantic conventions)

These metrics follow the [OpenTelemetry Gen AI semantic conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-metrics/). They capture request duration, upstream latency, token usage, and streaming performance.

{% include plugins/otel/metric_tables.md metric_prefixes="gen_ai." %}

## Kong Gen AI metrics

These metrics use the `kong.gen_ai.*` namespace and capture Kong-specific AI observability data, including cost tracking, cache and RAG latency, and AWS Guardrails processing time.

### kong.gen_ai.llm.cost

Cost of AI requests. To populate this metric, define `model.options.input_cost` and `model.options.output_cost` in the [AI Proxy](/plugins/ai-proxy/reference/#schema--config-model-options-input-cost) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/reference/#schema--config-targets-model-options-input-cost) plugin configuration.

* **Type**: Counter
* **Unit**: `{cost}`

<!-- vale off -->
{% table %}
columns:
  - title: Attribute
    key: attr
  - title: Description
    key: desc
rows:
  - attr: "`gen_ai.provider.name`"
    desc: "Name of the Gen AI provider."
  - attr: "`gen_ai.request.model`"
    desc: "Model name targeted by the request."
  - attr: "`gen_ai.response.model`"
    desc: "Model name reported by the provider in the response."
  - attr: "`gen_ai.operation.name`"
    desc: "Operation requested, such as `chat` or `embeddings`."
  - attr: "`kong.gen_ai.cache.status`"
    desc: "Cache status: `hit` or empty if not cached."
  - attr: "`kong.gen_ai.vector_db`"
    desc: "Vector database used for caching, such as `redis`."
  - attr: "`kong.gen_ai.embeddings.provider`"
    desc: "Embeddings provider used for caching."
  - attr: "`kong.gen_ai.embeddings.model`"
    desc: "Embeddings model used for caching."
  - attr: "`kong.workspace.name`"
    desc: "Name of the Workspace."
  - attr: "`kong.auth.consumer.name`"
    desc: "Name of the authenticated Consumer."
  - attr: "`kong.gen_ai.request.mode`"
    desc: "Request mode: `oneshot`, `stream`, or `realtime`."
{% endtable %}
<!-- vale on -->

### kong.gen_ai.cache.fetch.latency

Time to fetch a response from the semantic cache.

* **Type**: Histogram
* **Unit**: `s` (seconds)

**Attributes:** Same as [`kong.gen_ai.llm.cost`](#konggen_aillmcost).

### kong.gen_ai.cache.embeddings.latency

Time to generate embeddings during cache operations.

* **Type**: Histogram
* **Unit**: `s` (seconds)

**Attributes:** Same as [`kong.gen_ai.llm.cost`](#konggen_aillmcost).

### kong.gen_ai.rag.fetch.latency

Time to fetch data from a RAG (Retrieval-Augmented Generation) source.

* **Type**: Histogram
* **Unit**: `s` (seconds)

**Attributes:** Same as [`kong.gen_ai.llm.cost`](#konggen_aillmcost).

### kong.gen_ai.rag.embeddings.latency

Time to generate embeddings for RAG operations.

* **Type**: Histogram
* **Unit**: `s` (seconds)

**Attributes:** Same as [`kong.gen_ai.llm.cost`](#konggen_aillmcost).

### kong.gen_ai.aws.guardrails.latency

Time for AWS Guardrails to process a request.

* **Type**: Histogram
* **Unit**: `s` (seconds)

<!-- vale off -->
{% table %}
columns:
  - title: Attribute
    key: attr
  - title: Description
    key: desc
rows:
  - attr: "`kong.gen_ai.aws.guardrails.id`"
    desc: "ID of the AWS Guardrails configuration."
  - attr: "`kong.gen_ai.aws.guardrails.version`"
    desc: "Version of the AWS Guardrails configuration."
  - attr: "`kong.gen_ai.aws.guardrails.mode`"
    desc: "Mode of the AWS Guardrails evaluation."
  - attr: "`kong.gen_ai.aws.guardrails.region`"
    desc: "AWS region of the Guardrails service."
  - attr: "`kong.workspace.name`"
    desc: "Name of the Workspace."
  - attr: "`kong.auth.consumer.name`"
    desc: "Name of the authenticated Consumer."
{% endtable %}
<!-- vale on -->

## MCP metrics

These metrics provide observability into MCP (Model Context Protocol) server interactions, including latency, response sizes, errors, and ACL decisions.

### mcp.client.operation.duration

Duration of the MCP request as observed by the sender. Only available when the [AI MCP Proxy plugin](/plugins/ai-mcp-proxy/) is in passthrough-listener mode (the upstream is an MCP server). Requires `enable_latency_metrics` set to `true`.

* **Type**: Histogram
* **Unit**: `s` (seconds)

<!-- vale off -->
{% table %}
columns:
  - title: Attribute
    key: attr
  - title: Description
    key: desc
rows:
  - attr: "`kong.service.name`"
    desc: "Name of the Gateway Service."
  - attr: "`kong.route.name`"
    desc: "Name of the Route."
  - attr: "`kong.workspace.name`"
    desc: "Name of the Workspace."
  - attr: "`mcp.method.name`"
    desc: "MCP method name, such as `tools/call`."
  - attr: "`gen_ai.tool.name`"
    desc: "Name of the tool invoked."
  - attr: "`error.type`"
    desc: "JSON-RPC error code, if the request failed."
  - attr: "`gen_ai.operation.name`"
    desc: "Operation name, such as `execute_tool` for `tools/call`."
{% endtable %}
<!-- vale on -->

### mcp.server.operation.duration

Duration of the MCP request as observed by the receiver.

* **Type**: Histogram
* **Unit**: `s` (seconds)

**Attributes:** Same as [`mcp.client.operation.duration`](#mcpclientoperationduration).

### kong.gen_ai.mcp.response.size

Size of the MCP response body.

* **Type**: Histogram
* **Unit**: `By` (bytes)

<!-- vale off -->
{% table %}
columns:
  - title: Attribute
    key: attr
  - title: Description
    key: desc
rows:
  - attr: "`kong.service.name`"
    desc: "Name of the Gateway Service."
  - attr: "`kong.route.name`"
    desc: "Name of the Route."
  - attr: "`kong.workspace.name`"
    desc: "Name of the Workspace."
  - attr: "`mcp.method.name`"
    desc: "MCP method name, such as `tools/call`."
  - attr: "`gen_ai.tool.name`"
    desc: "Name of the tool invoked."
{% endtable %}
<!-- vale on -->

### kong.gen_ai.mcp.request.error.count

Number of MCP request errors.

* **Type**: Counter
* **Unit**: `{error}`

<!-- vale off -->
{% table %}
columns:
  - title: Attribute
    key: attr
  - title: Description
    key: desc
rows:
  - attr: "`kong.service.name`"
    desc: "Name of the Gateway Service."
  - attr: "`kong.route.name`"
    desc: "Name of the Route."
  - attr: "`kong.workspace.name`"
    desc: "Name of the Workspace."
  - attr: "`mcp.method.name`"
    desc: "MCP method name, such as `tools/call`."
  - attr: "`gen_ai.tool.name`"
    desc: "Name of the tool invoked."
  - attr: "`error.type`"
    desc: "JSON-RPC error code."
{% endtable %}
<!-- vale on -->

### kong.gen_ai.mcp.acl.allowed

Number of MCP requests allowed by ACL rules.

* **Type**: Counter
* **Unit**: `{request}`

<!-- vale off -->
{% table %}
columns:
  - title: Attribute
    key: attr
  - title: Description
    key: desc
rows:
  - attr: "`kong.service.name`"
    desc: "Name of the Gateway Service."
  - attr: "`kong.route.name`"
    desc: "Name of the Route."
  - attr: "`kong.workspace.name`"
    desc: "Name of the Workspace."
  - attr: "`kong.gen_ai.mcp.primitive`"
    desc: "MCP primitive type, such as `tool`."
  - attr: "`kong.gen_ai.mcp.primitive_name`"
    desc: "Name of the MCP primitive."
{% endtable %}
<!-- vale on -->

### kong.gen_ai.mcp.acl.denied

Number of MCP requests denied by ACL rules.

* **Type**: Counter
* **Unit**: `{request}`

**Attributes:** Same as [`kong.gen_ai.mcp.acl.allowed`](#konggen_aimcpaclallowed).

## A2A metrics

These metrics provide observability into [A2A (Agent-to-Agent)](/plugins/ai-a2a-proxy/) traffic, including request volume, latency, response sizes, and task state transitions.

### kong.gen_ai.a2a.request.count

Total number of A2A requests.

* **Type**: Counter
* **Unit**: `{request}`

<!-- vale off -->
{% table %}
columns:
  - title: Attribute
    key: attr
  - title: Description
    key: desc
rows:
  - attr: "`kong.service.name`"
    desc: "Name of the Gateway Service."
  - attr: "`kong.route.name`"
    desc: "Name of the Route."
  - attr: "`kong.workspace.name`"
    desc: "Name of the Workspace."
  - attr: "`kong.gen_ai.a2a.method`"
    desc: "A2A method name."
  - attr: "`kong.gen_ai.a2a.binding`"
    desc: "A2A binding type."
{% endtable %}
<!-- vale on -->

### kong.gen_ai.a2a.request.duration

Duration of an A2A request.

* **Type**: Histogram
* **Unit**: `s` (seconds)

**Attributes:** Same as [`kong.gen_ai.a2a.request.count`](#konggen_aia2arequestcount).

### kong.gen_ai.a2a.response.size

Size of the A2A response body.

* **Type**: Histogram
* **Unit**: `By` (bytes)

**Attributes:** Same as [`kong.gen_ai.a2a.request.count`](#konggen_aia2arequestcount).

### kong.gen_ai.a2a.ttfb

Time to first byte for A2A streaming responses.

* **Type**: Histogram
* **Unit**: `s` (seconds)

**Attributes:** Same as [`kong.gen_ai.a2a.request.count`](#konggen_aia2arequestcount).

### kong.gen_ai.a2a.request.error.count

Number of A2A request errors.

* **Type**: Counter
* **Unit**: `{error}`

<!-- vale off -->
{% table %}
columns:
  - title: Attribute
    key: attr
  - title: Description
    key: desc
rows:
  - attr: "`kong.service.name`"
    desc: "Name of the Gateway Service."
  - attr: "`kong.route.name`"
    desc: "Name of the Route."
  - attr: "`kong.workspace.name`"
    desc: "Name of the Workspace."
  - attr: "`kong.gen_ai.a2a.method`"
    desc: "A2A method name."
  - attr: "`kong.gen_ai.a2a.binding`"
    desc: "A2A binding type."
  - attr: "`kong.gen_ai.a2a.error.type`"
    desc: "Type of the A2A error."
{% endtable %}
<!-- vale on -->

### kong.gen_ai.a2a.task.state.count

Number of A2A task state transitions.

* **Type**: Counter
* **Unit**: `{state}`

<!-- vale off -->
{% table %}
columns:
  - title: Attribute
    key: attr
  - title: Description
    key: desc
rows:
  - attr: "`kong.service.name`"
    desc: "Name of the Gateway Service."
  - attr: "`kong.route.name`"
    desc: "Name of the Route."
  - attr: "`kong.workspace.name`"
    desc: "Name of the Workspace."
  - attr: "`kong.gen_ai.a2a.task.state`"
    desc: "Task state, such as `completed`, `failed`, or `in_progress`."
{% endtable %}
<!-- vale on -->
