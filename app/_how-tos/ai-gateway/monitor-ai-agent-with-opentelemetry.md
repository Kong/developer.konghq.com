---
title: Monitor AI Agent traffic with OpenTelemetry
content_type: how_to
permalink: /ai-gateway/monitor-ai-agent-with-opentelemetry/
description: Attach an OpenTelemetry AI Policy to an AI Agent entity to export A2A traces and metrics to an OTLP collector
products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-agent
  - ai-policy

tags:
  - ai
  - a2a
  - tracing
  - metrics
  - observability

tldr:
  q: How do I export OpenTelemetry traces and metrics for A2A agent traffic in {{site.ai_gateway}}?
  a: |
    Attach an [OpenTelemetry Policy](/ai-gateway/policies/opentelemetry/) to an [AI Agent](/ai-gateway/entities/ai-agent/) entity to export distributed traces and OTLP metrics for A2A traffic to a collector.
    Configure `traces_endpoint` and `metrics.endpoint` on the Policy to send A2A span and metric data to your observability backend.

    This tutorial shows you how to create an AI Agent alongside an OpenTelemetry Policy using [kongctl](/kongctl/), send an A2A request, and validate both the resulting trace span and OTLP metrics in a local OpenTelemetry Collector.

tools:
  - kongctl

prereqs:
  konnect:
    - name: KONG_TRACING_INSTRUMENTATIONS
      value: all
    - name: KONG_TRACING_SAMPLING_RATE
      value: 1.0
  inline:
    - title: OpenAI API key
      content: |
        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export your key:
           ```bash
           export OPENAI_API_KEY='OPENAI_API_KEY'
           ```
      icon_url: /assets/icons/openai.svg

    - title: A2A agent
      include_content: md/ai-gateway/v2/prereqs/a2a-agent
      icon_url: /assets/icons/ai.svg

    - title: OpenTelemetry Collector
      include_content: md/ai-gateway/v2/prereqs/opentelemetry-collector
      icon_url: /assets/icons/opentelemetry.svg

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: OpenTelemetry Policy
    url: /ai-gateway/policies/opentelemetry/
  - text: Gen AI OpenTelemetry metrics reference
    url: /ai-gateway/ai-otel-metrics/
  - text: Get started with AI Agent
    url: /ai-gateway/get-started-with-ai-agent/
  - text: A2A protocol specification
    url: https://a2a-protocol.org/latest/

cleanup:
  inline:
    - title: Stop the A2A agent and OpenTelemetry Collector
      content: |
        ```sh
        docker compose down
        docker rm -f a2a-kongair-agent otel-collector
        ```
        {: data-test-cleanup="block" }
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

faqs:
  - q: What logging configuration does the AI Agent need to emit A2A traces and metrics?
    a: |
      A2A span and metric emission itself doesn't depend on a separate flag on the agent. The OpenTelemetry Policy's `traces_endpoint` and `metrics.endpoint` control where that data is exported.
      Set `config.logging.payloads` to `true` on the [AI Agent](/ai-gateway/entities/ai-agent/) if you also want request and response bodies captured alongside the telemetry.

  - q: Can one OpenTelemetry Policy cover multiple AI Agents or AI Models?
    a: |
      Yes. Set `global: true` on the Policy to apply it to every resource on the {{site.ai_gateway}} instead of listing it in each entity's `policies` field.
      Keep `global: false` and reference the Policy by name (or `!ref`) from each entity's `policies` array to scope export to specific agents or models.

  - q: What span attributes does {{site.ai_gateway}} emit for A2A traffic?
    a: |
      A `kong.a2a` child span carries attributes like `kong.a2a.operation`, `kong.a2a.task.id`, `kong.a2a.task.state`, and `kong.a2a.context.id`.
      See the full list in [AI Agent OpenTelemetry span attributes](/ai-gateway/entities/ai-agent/#opentelemetry-span-attributes).

  - q: What metrics are available for A2A traffic?
    a: |
      Counters and histograms in the `kong.gen_ai.a2a.*` namespace cover request volume, duration, response size, time to first byte, errors, and task state transitions.
      See [A2A metrics](/ai-gateway/ai-otel-metrics/#a2a-metrics) for the full reference.

---

## Create an AI Agent and OpenTelemetry Policy

Create an [OpenTelemetry Policy](/ai-gateway/policies/opentelemetry/) that exports traces and metrics to your collector, and an [AI Agent](/ai-gateway/entities/ai-agent/) that attaches it. Setting `global` to `false` on the Policy means it only applies to entities that reference it instead of every resource on your {{site.ai_gateway}}, so the `kongair-flight-booking-agent` entity lists `otel-a2a` in its `policies` field to opt in. The `service.name` value under `resource_attributes` labels the exported data, which is useful if multiple gateways or services send to the same collector.

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: ai-gateway-get-started

ai_gateway_policies:
  - ref: otel-a2a
    name: otel-a2a
    display_name: "otel-a2a"
    ai_gateway: !lookup {id: $AI_GATEWAY_ID}
    type: opentelemetry
    enabled: true
    global: false
    config:
      traces_endpoint: http://host.docker.internal:4318/v1/traces
      metrics:
        endpoint: http://host.docker.internal:4318/v1/metrics
        enable_ai_metrics: true
      resource_attributes:
        service.name: kong-a2a

ai_gateway_agents:
  - ref: kongair-flight-booking-agent
    ai_gateway: !lookup {id: $AI_GATEWAY_ID}
    name: kongair-flight-booking-agent
    display_name: "Kong Air Flight Booking Agent"
    type: a2a
    enabled: true
    policies: [ !ref otel-a2a#name ]
    config:
      url: http://host.docker.internal:10000
      route:
        paths:
          - /a2a
        methods:
          - GET
          - POST
        protocols:
          - http
          - https
        strip_path: true
      max_request_body_size: 8388608
EOF
```
{:data-test-step="block"}

## Send an A2A request

Send a `message/send` JSON-RPC request to test the agent:

{% validation request-check %}
url: /a2a/
display_headers: true
status_code: 200
retry: true
method: POST
headers:
  - "Content-Type: application/json"
body:
  jsonrpc: '2.0'
  id: '1'
  method: message/send
  params:
    message:
      kind: message
      messageId: msg-001
      role: user
      parts:
      - kind: text
        text: What flights are available on route KA-123?
{% endvalidation %}

A successful response (status 200) contains the agent's reply.

## Validate traces

Search the collector's logs for `kong.a2a` to find the emitted span:

{% validation custom-command %}
command: |
  docker logs otel-collector 2>&1 | grep -A 15 kong.a2a
expected:
  return_code: 0
render_output: false
{% endvalidation %}

You should see a `kong.a2a` span with the same shape. The `Trace ID`, `Parent ID`, `ID`, `Start time`, `End time`, `kong.a2a.task.id`, and `kong.a2a.context.id` values are generated per request, so yours will differ from the example:

```
Span #3
    Trace ID       : 1bfc19e17dd9121769882cd9b8bf5de1
    Parent ID      : de4e6ed2c16a2dd3
    ID             : 240b2b9ac3ac9e38
    Name           : kong.a2a
    Kind           : Internal
    Start time     : 2026-04-03 06:48:41.44707456 +0000 UTC
    End time       : 2026-04-03 06:48:47.140356608 +0000 UTC
    Status code    : Unset
    Status message :
Attributes:
     -> kong.a2a.protocol.version: Str(unknown)
     -> rpc.system: Str(jsonrpc)
     -> rpc.method: Str(message/send)
     -> kong.a2a.task.id: Str(8a98bbbf-7d09-4336-b3aa-afe73e3a38d3)
     -> kong.a2a.task.state: Str(completed)
     -> kong.a2a.context.id: Str(df2e34aa-27ce-44ee-b5d3-3130b4f10985)
     -> kong.a2a.operation: Str(message/send)
```
{:.collapsible}

The remaining attributes are fixed values you can match against directly. `rpc.system` is always `jsonrpc`, and `rpc.method` and `kong.a2a.operation` reflect the JSON-RPC method you sent, `message/send` in this example. `kong.a2a.task.state` reflects the task's outcome, `completed` for a successful response. `kong.a2a.protocol.version` is `unknown` because the request didn't carry an `A2A-Version` header. See [AI Agent OpenTelemetry span attributes](/ai-gateway/entities/ai-agent/#opentelemetry-span-attributes) for the full attribute list.

## Validate metrics

Search the collector's logs for `kong.gen_ai.a2a` to find the emitted metrics:

{% validation custom-command %}
command: |
  docker logs otel-collector 2>&1 | grep -A 15 kong.gen_ai.a2a
expected:
  return_code: 0
render_output: false
{% endvalidation %}

You should see metrics with the same shape. `kong.konnect.cp.id` identifies your {{site.ai_gateway}} control plane and is unique to your environment, and the `Count`, `Sum`, and `Value` fields depend on how many requests you sent and their actual duration or size, so match on the overall structure rather than the exact numbers:

```
Metric #0
Descriptor:
     -> Name: kong.gen_ai.a2a.request.count
     -> Description: Counts A2A requests.
     -> Unit: {request}
     -> DataType: Sum
     -> IsMonotonic: true
     -> AggregationTemporality: Cumulative
NumberDataPoints #0
Data point attributes:
     -> kong.gen_ai.a2a.binding: Str(jsonrpc)
     -> kong.konnect.cp.id: Str(e221e0b2-f56d-4f30-871b-183d5c4146a0)
     -> kong.service.name: Str(kongair-flight-booking-agent)
     -> kong.route.name: Str(kongair-flight-booking-agent-route)
     -> kong.workspace.name: Str(default)
     -> kong.gen_ai.a2a.method: Str(message/send)
Value: 1

Metric #1
Descriptor:
     -> Name: kong.gen_ai.a2a.request.duration
     -> Description: Measures A2A request duration in seconds.
     -> Unit: s
     -> DataType: Histogram
     -> AggregationTemporality: Cumulative
HistogramDataPoints #0
Data point attributes:
     -> kong.gen_ai.a2a.binding: Str(jsonrpc)
     -> kong.konnect.cp.id: Str(e221e0b2-f56d-4f30-871b-183d5c4146a0)
     -> kong.service.name: Str(kongair-flight-booking-agent)
     -> kong.route.name: Str(kongair-flight-booking-agent-route)
     -> kong.workspace.name: Str(default)
     -> kong.gen_ai.a2a.method: Str(message/send)
Count: 1
Sum: 22.988000

Metric #2
Descriptor:
     -> Name: kong.gen_ai.a2a.response.size
     -> Description: Measures A2A response body size in bytes.
     -> Unit: By
     -> DataType: Histogram
     -> AggregationTemporality: Cumulative
HistogramDataPoints #0
Data point attributes:
     -> kong.gen_ai.a2a.binding: Str(jsonrpc)
     -> kong.konnect.cp.id: Str(e221e0b2-f56d-4f30-871b-183d5c4146a0)
     -> kong.service.name: Str(kongair-flight-booking-agent)
     -> kong.route.name: Str(kongair-flight-booking-agent-route)
     -> kong.workspace.name: Str(default)
     -> kong.gen_ai.a2a.method: Str(message/send)
Count: 1
Sum: 1496.000000

Metric #3
Descriptor:
     -> Name: kong.gen_ai.a2a.task.state.count
     -> Description: Counts A2A task state transitions.
     -> Unit: {state}
     -> DataType: Sum
     -> IsMonotonic: true
     -> AggregationTemporality: Cumulative
NumberDataPoints #0
Data point attributes:
     -> kong.konnect.cp.id: Str(e221e0b2-f56d-4f30-871b-183d5c4146a0)
     -> kong.service.name: Str(kongair-flight-booking-agent)
     -> kong.route.name: Str(kongair-flight-booking-agent-route)
     -> kong.workspace.name: Str(default)
     -> kong.gen_ai.a2a.task.state: Str(completed)
Value: 1
```
{:.collapsible}

The rest of the attributes are fixed values you can match against directly. `kong.service.name` and `kong.route.name` match the entity names you created (`kong.route.name` carries a `-route` suffix because {{site.ai_gateway}} auto-generates a Route for the agent). `kong.workspace.name`, `kong.gen_ai.a2a.binding`, and `kong.gen_ai.a2a.method` reflect your configuration and the request you sent.

See [A2A metrics](/ai-gateway/ai-otel-metrics/#a2a-metrics) for the full metric reference, including `kong.gen_ai.a2a.request.duration`, `kong.gen_ai.a2a.response.size`, `kong.gen_ai.a2a.ttfb`, and `kong.gen_ai.a2a.request.error.count`.

{:.success}
> You can also view A2A traffic metrics without setting up a collector, using {{site.konnect_short_name}} Analytics:
> 1. Go to **Observability > Dashboards**.
> 1. Click **Create dashboard > Create from template**.
> 1. Select the **Agentic analytics** dashboard. This dashboard highlights which tools are called most frequently, breaks down tool usage by consumer, and tracks average latency per tool over time, helping teams operating agentic services understand usage patterns and identify performance bottlenecks.
> 1. Click **Use template** to see agent traffic volume, error rates, and other stats.
