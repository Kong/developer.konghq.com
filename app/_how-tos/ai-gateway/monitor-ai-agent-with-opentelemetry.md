---
title: Monitor AI Agent traffic with OpenTelemetry
content_type: how_to
permalink: /ai-gateway/monitor-ai-agent-with-opentelemetry/
description: Attach an OpenTelemetry Policy to an AI Agent entity to export A2A traces and metrics to an OTLP collector
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

    This tutorial shows you how to create an AI Agent alongside an OpenTelemetry Policy using kongctl, send an A2A request, and validate both the resulting trace span and OTLP metrics in a local OpenTelemetry Collector.

tools:
  - kongctl

prereqs:
  konnect:
    - name: KONG_TRACING_INSTRUMENTATIONS
    - name: KONG_TRACING_SAMPLING_RATE
  inline:
    - title: OpenAI API key
      content: |
        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export your key:
           ```bash
           export OPENAI_API_KEY='YOUR_OPENAI_API_KEY'
           ```
      icon_url: /assets/icons/openai.svg

    - title: A2A agent
      include_content: md/ai-gateway/v2/prereqs/a2a-agent
      icon_url: /assets/icons/ai.svg

    - title: OpenTelemetry Collector
      content: |
        Launch a local OpenTelemetry Collector that listens on port 4318 and writes received data to a text file:

        ```sh
        docker run \
          --name otel-collector \
          -p 127.0.0.1:4318:4318 \
          otel/opentelemetry-collector:0.141.0 \
          2>&1 | tee collector-output.txt
        ```

        In a new terminal, keep the container running so it can receive traces and metrics from {{site.ai_gateway}}.
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
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

faqs:
  - q: Does the AI Agent need any logging configuration to emit A2A traces and metrics?
    a: |
      Set `config.logging.payloads` to `true` on the [AI Agent](/ai-gateway/entities/ai-agent/) if you also want request and response bodies captured alongside the telemetry.
      A2A span and metric emission itself doesn't depend on a separate flag on the agent. The OpenTelemetry Policy's `traces_endpoint` and `metrics.endpoint` control where that data is exported.

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

automated_tests: false

---

## Create an AI Agent and OpenTelemetry Policy

Create an [OpenTelemetry Policy](/ai-gateway/policies/opentelemetry/) that exports traces and metrics to your collector, and an [AI Agent](/ai-gateway/entities/ai-agent/) that attaches it:

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

By default, an AI Policy applies to every resource on your {{site.ai_gateway}}. Setting `global` to `false` changes that: the `otel-a2a` Policy now only takes effect on entities that explicitly list it, instead of applying gateway-wide.

The `kongair-flight-booking-agent` entity does exactly that by referencing `otel-a2a` in its `policies` list. As a result, every request that goes through the agent is traced and measured, and that data is exported to the collector you started earlier. The `service.name` value under `resource_attributes` is just a label attached to that exported data, so if you're running multiple {{site.ai_gateway}}s or services into the same collector, you can tell which one a given trace or metric came from.

## Send an A2A request

Send a `message/send` JSON-RPC request to test the agent:

```bash
curl -X POST "http://localhost:8000/a2a" \
  -H "Content-Type: application/json" \
  --json '{
    "jsonrpc": "2.0",
    "id": "1",
    "method": "message/send",
    "params": {
      "message": {
        "kind": "message",
        "messageId": "msg-001",
        "role": "user",
        "parts": [
          {
            "kind": "text",
            "text": "What flights are available on route KA-123?"
          }
        ]
      }
    }
  }'
```

A successful response (status 200) contains the agent's reply.

## Validate traces

Search `collector-output.txt` for `kong.a2a` to find the emitted span. You should see the following data:

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

`kong.a2a.protocol.version` is `unknown` because the request didn't carry an `A2A-Version` header. See [AI Agent OpenTelemetry span attributes](/ai-gateway/entities/ai-agent/#opentelemetry-span-attributes) for the full attribute list.

## Validate metrics

Search `collector-output.txt` for `kong.gen_ai.a2a` to find the emitted metrics. You should see data like the following:

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

`kong.route.name` carries a `-route` suffix because {{site.ai_gateway}} auto-generates a Route for the agent. `kong.konnect.cp.id` identifies the {{site.ai_gateway}}  control plane the metric originated from.

See [A2A metrics](/ai-gateway/ai-otel-metrics/#a2a-metrics) for the full metric reference, including `kong.gen_ai.a2a.request.duration`, `kong.gen_ai.a2a.response.size`, `kong.gen_ai.a2a.ttfb`, and `kong.gen_ai.a2a.request.error.count`.

{:.success}
> You can also view A2A traffic metrics without setting up a collector, using {{site.konnect_short_name}} Analytics:
> 1. Go to **Observability > Dashboards**.
> 1. Click **Create dashboard > Create from template**.
> 1. Select the **Agentic analytics** dashboard. This dashboard highlights which tools are called most frequently, breaks down tool usage by consumer, and tracks average latency per tool over time, helping teams operating agentic services understand usage patterns and identify performance bottlenecks.
> 1. Click **Use template** to see agent traffic volume, error rates, and other stats.
