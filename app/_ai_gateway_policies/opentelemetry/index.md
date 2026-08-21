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

- [Metrics](#metrics)
- [Tracing](#tracing)
- [Logging](#logging)
 
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

Resource attributes describe the entity that produced the telemetry and are shared across all signals.

You can add or override resource attributes by configuring the [`config.resource_attributes`](./reference/#schema--config-resource-attributes) parameter. Custom resource attributes are merged with the default attributes and are included with all exported telemetry data. Some metric backends, such as Prometheus, apply resource attributes to every metric. Be mindful of the impact on cardinality.

## Metrics

{% include /md/ai-gateway/v2/policies/otel/ai-metric-setup.md  %}

For all available metrics, see the [OpenTelemetry metrics reference](/ai-gateway/ai-otel-metrics/).


## Tracing

### Built-in tracing instrumentations

{{site.ai_gateway}} has a series of built-in tracing instrumentations which are configured by the `tracing_instrumentations` parameter. {{site.ai_gateway}} creates a top-level span for each request by default when `tracing_instrumentations` is enabled.

The top level span has the following attributes:
- `http.method`: HTTP method
- `http.url`: HTTP URL
- `http.host`: HTTP host
- `http.scheme`: HTTP scheme (http or https)
- `http.flavor`: HTTP version
- `net.peer.ip`: Client IP address

For more information, see the [Tracing reference](/gateway/tracing/).

{:.info}
>**Note**: When the OpenTelemetry Policy is used together with the [Proxy Cache Advanced](/ai-gateway/policies/proxy-cache-advanced/reference/) Policy, cache-HIT responses are not traced.
> This is expected behavior. When a request results in a cache-HIT, the response is served before the request lifecycle reaches the phase where the OpenTelemetry Policy executes. As a result, no spans are generated for cache-HIT requests. Cache-MISS requests continue through the full request lifecycle and are traced normally.

### Gen AI tracing attributes

AI-specific span attributes are emitted following the [OpenTelemetry Gen AI semantic conventions](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/). These attributes capture model parameters, token usage, and tool-call metadata.

### Propagation

The OpenTelemetry AI Policy supports propagation of the following header formats:
- `w3c`: [W3C trace context](https://www.w3.org/TR/trace-context/)
- `b3` and `b3-single`: [Zipkin headers](https://github.com/openzipkin/b3-propagation)
- `jaeger`: [Jaeger headers](https://www.jaegertracing.io/docs/)
- `ot`: [OpenTracing headers](https://github.com/opentracing/specification/blob/master/rfc/trace_identifiers.md)
- `datadog`: [Datadog headers](https://docs.datadoghq.com/tracing/trace_collection/library_config/go/#trace-context-propagation-for-distributed-tracing)
- `aws`: [AWS X-Ray header](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-tracingheader)
- `gcp`: [GCP X-Cloud-Trace-Context header](https://cloud.google.com/trace/docs/setup#force-trace)

{% include /md/ai-gateway/v2/policies/tracing-headers-propagation.md %}

See the Policy's [configuration reference](/ai-gateway/policies/opentelemetry/reference/#schema--config-propagation) for a complete overview of the available options and values.

{:.info}
> **Note:** If any of the [`config.propagation.*`](/ai-gateway/policies/opentelemetry/reference/#schema--config-propagation) configuration options (`extract`, `clear`, or `inject`) are configured, the `config.propagation` configuration takes precedence over the deprecated `header_type` parameter.
If none of the `config.propagation.*` configuration options are set, the `header_type` parameter is still used to determine the propagation behavior.

### OTLP exporter

The OpenTelemetry AI Policy implements the [OTLP/HTTP](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/protocol/otlp.md#otlphttp) exporter, which uses Protobuf payloads encoded in binary format and is sent via an HTTP/1.1.

[`config.connect_timeout`](/ai-gateway/policies/opentelemetry/reference/#schema--config-connect-timeout), [`config.read_timeout`](/ai-gateway/policies/opentelemetry/reference/#schema--config-read-timeout), and [`config.send_timeout`](/ai-gateway/policies/opentelemetry/reference/#schema--config-send-timeout) are used to set the timeouts for the HTTP request.

[`config.batch_span_count`](/ai-gateway/policies/opentelemetry/reference/#schema--config-batch-span-count) and [`config.batch_flush_delay`](/ai-gateway/policies/opentelemetry/reference/#schema--config-batch-flush-delay) are used to set the maximum number of spans and the delay between two consecutive batches.

### Create a custom span

The OpenTelemetry AI Policy is built on top of the {{site.ai_gateway}} tracing PDK. You can customize the spans and add your own spans through the universal tracing PDK.

1. Create a file named `custom-span.lua` with the following content:

   ```lua
   -- Modify the root span
   local root_span = kong.tracing.get_root_span()
   root_span:set_attribute("custom.attribute", "custom value")

   -- Modify the active span
   local active_span = kong.tracing.active_span()
   active_span:set_attribute("custom.attribute", "custom value")

   -- Create a custom span
   local span = kong.tracing.start_span("custom-span")

   -- Append attributes
   span:set_attribute("custom.attribute", "custom value")

   -- Close the span
   span:finish()
   ```

2. Apply the Lua code with the [Post-function Policy](/ai-gateway/policies/post-function/) using a cURL file upload:

   ```bash
   curl -i -X POST http://localhost:8001/plugins \
     -F "name=post-function" \
     -F "config.access[1]=@custom-span.lua"
   ```

## Logging

This AI Policy supports [OpenTelemetry Logging](https://opentelemetry.io/docs/specs/otel/logs/), which can be configured as described in the [configuration reference](/ai-gateway/policies/opentelemetry/reference/#schema--config-traces_endpoint) to export logs in OpenTelemetry format to an OTLP-compatible backend.

### Log scopes

Two different kinds of logs are exported:
  * API transactional logs (also known as access logs) represent metadata about client requests. These access logs are produced during the request lifecycle. These logs typically don't have a severity.
  * Runtime and error logs aren't directly associated with a request. They're produced by the data plane and provide data about its internal execution. For example, they could be logs generated asynchronously (in a timer) or during a worker's startup.

### Log level

Logs are recorded based on the log level that is configured for {{site.ai_gateway}}. If a log is emitted with a level that is lower than the configured log level, it is not recorded or exported.

{:.info}
> **Note:** Not all logs are guaranteed to be recorded. Logs that aren't recorded include those produced by the Nginx master process and low-level errors produced by Nginx. Operators are expected to still capture the Nginx `error.log` file (which always includes all such logs) in addition to using this feature, to avoid losing any details that might be useful for deeper troubleshooting.

### Runtime and error log entry

Each log entry adheres to the [OpenTelemetry Logs Data Model](https://opentelemetry.io/docs/specs/otel/logs/data-model/). The available information depends on the log scope and on whether [**tracing**](#tracing) is enabled for this Policy.

Every log entry includes the following fields:
- `Timestamp`: Time when the event occurred.
- `ObservedTimestamp`: Time when the event was observed.
- `SeverityText`: The severity text (log level).
- `SeverityNumber`: Numerical value of the severity.
- `Body`: The error log line.
- `Resource`: Configurable resource attributes.
- `InstrumentationScope`: Metadata that describes {{site.ai_gateway}}'s data emitter.
- `Attributes`: Additional information about the event.
  - `introspection.source`: Full path of the file that emitted the log.
  - `introspection.current.line`: Line number that emitted the log.

In addition to the above, request-scoped logs include:
- `Attributes`: Additional information about the event.
  - `request.id`: {{site.ai_gateway}}'s request ID.

In addition to the above, when **tracing** is enabled, request-scoped logs include:
- `TraceID`: Request trace ID.
- `SpanID`: Request span ID.
- `TraceFlags`: W3C trace flag.

### Logging for custom Policies

The custom [plugin PDK](/gateway/pdk/reference/kong.plugin/) `kong.telemetry.log` module lets you configure OTLP logging for a custom plugin.
The module records a structured log entry, which is reported via the OpenTelemetry plugin.

## Queuing

{% include_cached /md/ai-gateway/v2/policies/queues.md name=page.name %}

## Trace IDs in serialized logs

When the OpenTelemetry AI Policy is configured along with a Policy that uses the Log Serializer, the trace ID of each request is added to the key `trace_id` in the serialized log output.

The value of this field is an object that can contain different formats of the current request's trace ID. In case there are multiple tracing headers in the same request, the `trace_id` field includes one trace ID format for each different header format, as in the following example:

```
"trace_id": {
  "w3c": "4bf92f3577b34da6a3ce929d0e0e4736",
  "datadog": "11803532876627986230"
},
```

## Custom attributes by Lua

{% include /md/ai-gateway/v2/policies/log-custom-fields-by-lua.md
custom_fields_by_lua='config.access_logs.custom_attributes_by_lua'
custom_fields_by_lua_slug='config-access-logs-custom-attributes-by-lua'
custom_fields_by_lua_name='custom_attributes_by_lua'
name=page.name
slug=page.slug %}

## Troubleshooting

The OpenTelemetry spans are printed to the console when the log level is set to `debug` in the {{site.ai_gateway}} configuration file.

The following is an example of the debug logs output:

```bash
2022/06/02 15:28:42 [debug] 650#0: *111 [lua] instrumentation.lua:302: runloop_log_after(): [tracing] collected 6 spans:
Span #1 name=GET /wrk duration=1502.994944ms attributes={"http.url":"/wrk","http.method":"GET","http.flavor":1.1,"http.host":"127.0.0.1","http.scheme":"http","net.peer.ip":"172.18.0.1"}
Span #2 name=rewrite phase: opentelemetry duration=0.391936ms
Span #3 name=router duration=0.013824ms
Span #4 name=access phase: cors duration=1500.824576ms
Span #5 name=cors: heavy works duration=1500.709632ms attributes={"username":"kongers"}
Span #6 name=balancer try #1 duration=0.99328ms attributes={"net.peer.ip":"104.21.11.162","net.peer.port":80}
```