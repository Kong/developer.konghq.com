---
title: "{{site.base_gateway}} tracing"
content_type: reference
layout: reference
breadcrumbs:
  - /gateway/
products:
    - gateway

tags:
  - tracing
  - monitoring
  - metrics
min_version:
  gateway: '3.4'

description: "Learn how {{site.base_gateway}} tracing works and about the tracing API."
search_aliases:
  - OTEL

related_resources:
  - text: OpenTelemetry plugin
    url: /plugins/opentelemetry/
  - text: Zipkin plugin
    url: /plugins/zipkin/
  - text: "{{site.base_gateway}} monitoring and metrics"
    url: /gateway/monitoring/

works_on:
  - on-prem
  - konnect
faqs:
  - q: When did OpenTelemetry replace the Granular Tracing feature?
    a: |
      Granular Tracing was removed from {{site.base_gateway}} starting in 3.7,
      and configurations like `tracing = on` are no longer available. Instead, use the
      OpenTelemetry tracing ([`tracing_instrumentations`](/gateway/configuration/#tracing-instrumentations)) described on this page.
---

OpenTelemetry tracing is now the standard for distributed tracing. Use the OpenTelemetry tracing guidance on this page to set up tracing in your environment.

## Core tracing instrumentations

To use tracing instrumentations, you must enable a plugin that uses Kong's [Tracing API](#tracing-api):
* [OpenTelemetry plugin](/plugins/opentelemetry/)
* [Zipkin plugin](/plugins/zipkin/)

{{site.base_gateway}} provides a set of core instrumentations for tracing, these can be configured in the [`tracing_instrumentations`](/gateway/configuration/#tracing-instrumentations) configuration in `kong.conf`:

<!--vale off-->
{% kong_config_table %}
config:
  - name: tracing_instrumentations
{% endkong_config_table %}
<!--vale on-->

## Header propagation

The tracing API supports propagating the following headers:
- [`w3c`](https://www.w3.org/TR/trace-context/)
- [`b3`, `b3-single`](https://github.com/openzipkin/b3-propagation)
- `jaeger`
- [`ot`](https://github.com/opentracing/specification/blob/master/rfc/trace_identifiers.md)

The tracing API detects the propagation format from the headers, and uses the appropriate format to propagate the span.
If no appropriate format is found, it falls back to the default format, which can be user-specified.

The propagation API works for both the OpenTelemetry plugin and the Zipkin plugin.

## Headers

The [headers parameter in `kong.conf`](/gateway/configuration/#headers) lists supported tracing headers:

<!--vale off-->
{% kong_config_table %}
config:
  - name: headers
{% endkong_config_table %}
<!--vale on-->

### X-Kong-Request-Id header {% new_in 3.5 %}

The `X-Kong-Request-Id` header is enabled by default and provides a unique ID for every client request, both upstream and downstream. This ID is especially useful for debugging, as it links specific requests to their corresponding error logs.

When {{site.base_gateway}} returns an error using the PDK function `kong.response.error`, the request ID is included in both the response body and the error logs, formatted as `request_id: xxx`.

The same ID appears in the debug header and debug response header, allowing you to trace requests in a log viewer UI. This is especially useful when the debug output is too long to fit in the response header.

## Tracing API

The tracing API is available under the `kong.tracing` namespace and follows the [OpenTelemetry API specification](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/api.md). This specification defines how to use the API to instrument your module.

If you're already familiar with the OpenTelemetry API, you'll find the `kong.tracing` API intuitive and consistent with those standards.

Using the tracing API, you can configure your module with the following operations:

- [Span](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/api.md#span)
- [Attributes](https://opentelemetry.io/docs/specs/semconv/general/attributes/)


### Create a tracer

{{site.base_gateway}} uses a global tracer internally to instrument the core modules and plugins.

By default, the tracer is a [NoopTracer](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/api.md#get-a-tracer). The tracer is first initialized when the `tracing_instrumentations` configuration is enabled.

You can create a new tracer manually, or use the global tracer instance:

```lua
local tracer

-- Create a new tracer
tracer = kong.tracing.new("custom-tracer")

-- Use the global tracer
tracer = kong.tracing
```

#### Sampling traces

Configure the sampling rate of a tracer:

```lua
local tracer = kong.tracing.new("custom-tracer", {
  -- Set the sampling rate to 0.1
  sampling_rate = 0.1,
})
```

A `sampling_rate` of `0.1` means that 1 of every 10 requests will be traced. A rate of `1` means that all requests will be traced.

### Create a span

A span represents a single operation within a trace. Spans can be nested to form trace trees. Each trace contains a root span, which typically describes the entire operation and, optionally, one or more sub-spans for its sub-operations.

```lua
local tracer = kong.tracing

local span = tracer:start_span("my-span")
```

The span properties can be set by passing a table to the `start_span` method:

```lua
local span = tracer:start_span("my-span", {
  start_time_ns = ngx.now() * 1e9, -- override the start time
  span_kind = 2, -- SPAN_KIND
                  -- UNSPECIFIED: 0
                  -- INTERNAL: 1
                  -- SERVER: 2
                  -- CLIENT: 3
                  -- PRODUCER: 4
                  -- CONSUMER: 5
  should_sample = true, -- by setting it to `true` to ignore the sampling decision
})
```

Make sure to end the span when you are done:

```lua
span:finish() -- ends the span
```

{:.info}
>**Note:** The span table will be cleared and put into the table pool after the span is finished. Don't use it after the span is finished.

### Get or set the active span

The active span is the span that is currently being executed.

To avoid overheads, the active span is manually set by calling the `set_active_span` method.
When you finish a span, the active span becomes the parent of the finished span.


Set or get the active span:

```lua
local tracer = kong.tracing
local span = tracer:start_span("my-span")
tracer.set_active_span(span)

local active_span = tracer.active_span() -- returns the active span
```

#### Scope

The tracers are scoped to a specific context by a namespace key.

To get the active span for a specific namespace, you can use the following:

```lua
-- get global tracer's active span, and set it as the parent of new created span
local global_tracer = kong.tracing
local tracer = kong.tracing.new("custom-tracer")

local root_span = global_tracer.active_span()
local span = tracer.start_span("my-span", {
  parent = root_span
})
```

### Set the span attributes

The attributes of a span are a map of key-value pairs
and can be set by passing a table to the `set_attributes` method.

```lua
local span = tracer:start_span("my-span")
```

The OpenTelemetry specification defines the general semantic attributes. You can use it to describe the span.
It could also be meaningful to visualize the span in a UI.

```lua
span:set_attribute("key", "value")
```

The following are defined semantic conventions for spans:

* [General](https://opentelemetry.io/docs/specs/semconv/general/attributes/): General semantic attributes that may be used in describing different kinds of operations.
* [HTTP](https://opentelemetry.io/docs/specs/semconv/http/http-spans/): For HTTP client and server spans.
* [Database](https://opentelemetry.io/docs/specs/semconv/database/): For SQL and NoSQL client call spans.
* [RPC/RMI](https://opentelemetry.io/docs/specs/semconv/rpc/rpc-spans/): For remote procedure call (e.g., gRPC) spans.
* [Messaging](https://opentelemetry.io/docs/specs/semconv/messaging/messaging-spans/): For messaging systems (queues, publish/subscribe, etc.) spans.
* [FaaS](https://opentelemetry.io/docs/specs/semconv/faas/faas-spans/): For Function as a Service (e.g., AWS Lambda) spans.
* [Exceptions](https://opentelemetry.io/docs/specs/semconv/exceptions/exceptions-spans/): For recording exceptions associated with a span.
* [Compatibility](https://opentelemetry.io/docs/specs/semconv/general/trace-compatibility/): For spans generated by compatibility components, e.g. OpenTracing Shim layer.

### Set the span events

The events of a span are time-series events that can be set by passing a table to the `add_event` method:

```lua
local span = kong.tracing:start_span("my-span")
span:add_event("my-event", {
  -- attributes
  ["key"] = "value",
})
```

#### Record error message

The event can also be used to record error messages:

```lua
local span = kong.tracing:start_span("my-span")
span:record_error("my-error-message")

-- or (same as above)
span:add_event("exception", {
  ["exception.message"] = "my-error-message",
})
```

#### Set the span status

The status of a span is a status code and can be set by passing a table to the `set_status` method:

```lua
local span = kong.tracing:start_span("my-span")

-- Status codes:
-- - `0` unset
-- - `1` ok
-- - `2` error
span:set_status(2)
```

### Release the span (optional)

The spans are stored in a pool, and can be released by calling the `release` method:

```lua
local span = kong.tracing:start_span("my-span")
span:release()
```

By default, the span will be released after the Nginx request ends.

### Visualize the trace

Because the traces are compatible with OpenTelemetry, they can be natively visualized through any OpenTelemetry UI.

See the [OpenTelemetry plugin](/plugins/opentelemetry/) to learn how to visualize the traces.

## Write a custom trace exporter

{{site.base_gateway}} bundled the OpenTelemetry plugin in core with a implementation of [OTLP/HTTP](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/protocol/otlp.md#otlphttp), but you can still write your own exporter at scale.

To write a custom trace exporter, you must gather the spans. The spans are stored in the tracer's buffer.
The buffer is a queue of spans that are waiting to be sent to the backend.

You can access the buffer and process the span using the `span_processor` function:

```lua
-- Use the global tracer
local tracer = kong.tracing

-- Process the span
local span_processor = function(span)
    -- clone the span so it can be processed after the original one is cleared
    local span_dup = table.clone(span)
    -- you can transform the span, add tags, etc. to other specific data structures
end
```

The `span_processor` function should be called in the [`log` phase](/gateway/entities/plugin/#plugin-contexts) of the plugin.

See [Github](https://github.com/Kong/kong/tree/master/spec/fixtures/custom_plugins/kong/plugins/tcp-trace-exporter) for an example of a custom trace exporter.

