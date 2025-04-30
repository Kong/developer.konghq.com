---
title: 'OpenTelemetry'
name: 'OpenTelemetry'

content_type: plugin

publisher: kong-inc
description: 'Propagate spans and report space to a backend server through OTLP protocol.'

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.1'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: opentelemetry.png

categories:
  - analytics-monitoring

search_aliases:
  - otlp
  - otel
  - open telemetry
  - dynatrace
  - tracing
  - logging
  - analytics
  - monitoring
---

Propagate distributed tracing spans and report low-level spans to a OTLP-compatible server.

The OpenTelemetry plugin is fully compatible with the [OpenTelemetry specification](https://opentelemetry.io/docs/specs/) and can be used with any OpenTelemetry compatible backend.

## Collecting telemetry data

There are two ways to set up an OpenTelemetry backend:
* Using an OpenTelemetry-compatible backend directly, like Jaeger (v1.35.0+). 
  
  All the vendors supported by OpenTelemetry are listed in [OpenTelemetry's Vendor support](https://opentelemetry.io/vendors/).
* Using the OpenTelemetry Collector, which is middleware that can be used to proxy OpenTelemetry spans to a compatible backend.
  
  You can view all the available OpenTelemetry Collector exporters at [open-telemetry/opentelemetry-collector-contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter).

## Metrics {% new_in 3.8 %}
Metrics are enabled using the `contrib` version of the [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/installation/).

The `spanmetrics` connector allows you to aggregate traces and provide metrics to any third party observability platform.

To include span metrics for application traces, configure the collector exporters section of 
the OpenTelemetry Collector configuration file: 

```yaml
connectors:
  spanmetrics:
    dimensions:
      - name: http.method
        default: GET
      - name: http.status_code
      - name: http.route
    exclude_dimensions:
      - status.code
    metrics_flush_interval: 15s
    histogram:
      disable: false

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: []
      exporters: [spanmetrics]
    metrics:
      receivers: [spanmetrics]
      processors: []
      exporters: [otlphttp]
```

## Tracing

### Built-in tracing instrumentations

{{site.base_gateway}} has a series of built-in tracing instrumentations
which are configured by the `tracing_instrumentations` configuration.
{{site.base_gateway}} creates a top-level span for each request by default when `tracing_instrumentations` is enabled.


The top level span has the following attributes:
- `http.method`: HTTP method
- `http.url`: HTTP URL
- `http.host`: HTTP host
- `http.scheme`: HTTP scheme (http or https)
- `http.flavor`: HTTP version
- `net.peer.ip`: Client IP address

<!-- TODO: link to Gateway 3.0 tracing docs for details -->

### Propagation

The OpenTelemetry plugin supports propagation of the following header formats:
- `w3c`: [W3C trace context](https://www.w3.org/TR/trace-context/)
- `b3` and `b3-single`: [Zipkin headers](https://github.com/openzipkin/b3-propagation)
- `jaeger`: [Jaeger headers](https://www.jaegertracing.io/docs/)
- `ot`: [OpenTracing headers](https://github.com/opentracing/specification/blob/master/rfc/trace_identifiers.md)
- `datadog`: [Datadog headers](https://docs.datadoghq.com/tracing/trace_collection/library_config/go/#trace-context-propagation-for-distributed-tracing)
- `aws`: {% new_in 3.4 %} [AWS X-Ray header](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-tracingheader)
- `gcp`: {% new_in 3.5 %} [GCP X-Cloud-Trace-Context header](https://cloud.google.com/trace/docs/setup#force-trace)

{% include /plugins/tracing-headers-propagation.md %}

See the plugin's [configuration reference](/plugins/opentelemetry/reference/#schema--config-propagation) for a complete overview of the available options and values.


{:.info}
> **Note:** If any of the [`config.propagation.*`](/plugins/opentelemetry/reference/#schema--config-propagation) configuration options (`extract`, `clear`, or `inject`) are configured, the `config.propagation` configuration takes precedence over the deprecated `header_type` parameter. 
If none of the `config.propagation.*` configuration options are set, the `header_type` parameter is still used to determine the propagation behavior.

In {{site.base_gateway}} 3.6 or earlier, the plugin detects the propagation format from the headers and will use the appropriate format to propagate the span context.
If no appropriate format is found, the plugin will fallback to the default format, which is `w3c`.


### OTLP exporter

The OpenTelemetry plugin implements the [OTLP/HTTP](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/protocol/otlp.md#otlphttp) exporter, which uses Protobuf payloads encoded in binary format and is sent via HTTP/1.1.

[`config.connect_timeout`](/plugins/opentelemetry/reference/#schema--config-connect-timeout), [`config.read_timeout`](/plugins/opentelemetry/reference/#schema--config-read-timeout), and [`config.send_timeout`](/plugins/opentelemetry/reference/#schema--config-send-timeout) are used to set the timeouts for the HTTP request.

[`config.batch_span_count`](/plugins/opentelemetry/reference/#schema--config-batch-span-count) and [`config.batch_flush_delay`](/plugins/opentelemetry/reference/#schema--config-batch-flush-delay) are used to set the maximum number of spans and the delay between two consecutive batches.

### Create a custom span

The OpenTelemetry plugin is built on top of the {{site.base_gateway}} tracing PDK. You can customize the spans and add your own spans through the universal tracing PDK.

1. Create a file named `custom-span.lua` with the following content:

   ```lua
   -- Modify the root span
   local root_span = kong.tracing.active_span()
   root_span:set_attribute("custom.attribute", "custom value")

   -- Create a custom span
   local span = kong.tracing.start_span("custom-span")

   -- Append attributes
   span:set_attribute("custom.attribute", "custom value")
      
   -- Close the span
   span:finish()
   ```

2. Apply the Lua code with the [Post-function plugin](/plugins/post-function/) using a cURL file upload:

   ```bash
   curl -i -X POST http://localhost:8001/plugins \
     -F "name=post-function" \
     -F "config.access[1]=@custom-span.lua"
   ```

## Logging {% new_in 3.8 %}

This plugin supports [OpenTelemetry Logging](https://opentelemetry.io/docs/specs/otel/logs/), which can be configured as described in the [configuration reference](/plugins/opentelemetry/reference/#schema--config-traces_endpoint) to export logs in OpenTelemetry format to an OTLP-compatible backend.

### Log scopes

Two different kinds of logs are exported:
  * **Request** logs are directly associated with requests. These application logs are produced during the request lifecycle. For example, these could be logs generated by a plugin during its [Access or Response phase](/gateway/entities/plugin/#plugin-contexts), or by {{site.base_gateway}}'s core logic.
  * **Non-request** logs aren't directly associated with a request. They're produced outside the request lifecycle. For example, they could be logs generated asynchronously (in a timer) or during a worker's startup.

### Log level

Logs are recorded based on the [log level](/gateway/logs/#log-levels) that is configured for {{site.base_gateway}}. If a log is emitted with a level that is lower than the configured log level, it is not recorded or exported.

{:.info}
> **Note:** Not all logs are guaranteed to be recorded. Logs that aren't recorded include those produced by the Nginx master process and low-level errors produced by Nginx. Operators are expected to still capture the Nginx `error.log` file (which always includes all such logs) in addition to using this feature, to avoid losing any details that might be useful for deeper troubleshooting.

### Log entry

Each log entry adheres to the [OpenTelemetry Logs Data Model](https://opentelemetry.io/docs/specs/otel/logs/data-model/). The available information depends on the log scope and on whether [**tracing**](#tracing) is enabled for this plugin.

Every log entry includes the following fields:
- `Timestamp`: Time when the event occurred.
- `ObservedTimestamp`: Time when the event was observed.
- `SeverityText`: The severity text (log level).
- `SeverityNumber`: Numerical value of the severity.
- `Body`: The error log line.
- `Resource`: Configurable resource attributes.
- `InstrumentationScope`: Metadata that describes {{site.base_gateway}}'s data emitter.
- `Attributes`: Additional information about the event.
  - `introspection.source`: Full path of the file that emitted the log.
  - `introspection.current.line`: Line number that emitted the log.

In addition to the above, request-scoped logs include:
- `Attributes`: Additional information about the event.
  - `request.id`: {{site.base_gateway}}'s request ID.

In addition to the above, when **tracing** is enabled, request-scoped logs include:
- `TraceID`: Request trace ID.
- `SpanID`: Request span ID.
- `TraceFlags`: W3C trace flag.

### Logging for custom plugins

The custom [plugin PDK](/gateway/pdk/reference/kong.plugin/) `kong.telemetry.log` module lets you configure OTLP logging for a custom plugin. 
The module records a structured log entry, which is reported via the OpenTelemetry plugin.

## Queuing

{% include_cached /plugins/queues.md name=page.name %}

## Trace IDs in serialized logs {% new_in 3.5 %}

When the OpenTelemetry plugin is configured along with a plugin that uses the 
[Log Serializer](/gateway/pdk/reference/kong.log/#kong-log-serialize),
the trace ID of each request is added to the key `trace_id` in the serialized log output.

The value of this field is an object that can contain different formats
of the current request's trace ID. In case there are multiple tracing headers in the
same request, the `trace_id` field includes one trace ID format
for each different header format, as in the following example:

```
"trace_id": {
  "w3c": "4bf92f3577b34da6a3ce929d0e0e4736",
  "datadog": "11803532876627986230"
},
```

## Troubleshooting

The OpenTelemetry spans are printed to the console when the log level is set to `debug` in the {{site.base_gateway}} configuration file.

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

## Known issues

- Only supports the HTTP protocols (http/https) of {{site.base_gateway}}.
- May impact the performance of {{site.base_gateway}}.
  We recommend setting the sampling rate (`tracing_sampling_rate`)
  via the [{{site.base_gateway}} configuration file](/gateway/manage-kong-conf/) when using the OpenTelemetry plugin.
