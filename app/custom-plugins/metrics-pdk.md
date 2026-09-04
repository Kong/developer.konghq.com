---
title: Metrics PDK
content_type: reference
layout: reference

breadcrumbs:
  - /custom-plugins/

products:
    - gateway

works_on:
    - konnect
    - on-prem

description: Learn how to register and record custom metrics from a custom plugin using the Metrics PDK.

tags:
  - custom-plugins
  - metrics
  - monitoring

min_version:
  gateway: '3.16'

related_resources:
  - text: "kong.metrics PDK module reference"
    url: /gateway/pdk/reference/kong.metrics/
  - text: Custom plugins
    url: /custom-plugins/
  - text: Custom plugins reference
    url: /custom-plugins/reference/
  - text: Add metrics to a custom plugin
    url: /custom-plugins/get-started/add-metrics/
  - text: OpenTelemetry plugin
    url: /plugins/opentelemetry/
  - text: "{{site.base_gateway}} OpenTelemetry metrics reference"
    url: /gateway/otel-metrics/
---

The Metrics PDK is a `kong.metrics` namespace that lets a custom plugin define and record its own counter, gauge, and histogram metrics, alongside {{site.base_gateway}}'s built-in metrics.
You register a metric once and record values against it on every request.
Custom metrics flow through {{site.base_gateway}}'s existing [OpenTelemetry plugin](/plugins/opentelemetry/) export path, alongside the built-in metrics.

This reference covers the concepts you need to use the module, which includes how metrics are stored and exported, what the PDK validates, and where its limits are.
For more information, also see:
* [`kong.metrics` PDK reference](/gateway/pdk/reference/kong.metrics/): Full PDK function reference, including parameters and return values.
* [Add metrics to a custom plugin](/custom-plugins/get-started/add-metrics/): How-to guide on setting up a custom plugin with the metrics PDK.

{:.info}
> **Note**: The Metrics PDK isn't available for the [Pre-function](/plugins/pre-function/) or [Post-function](/plugins/post-function/) plugins.
> See the [limitations](#limitations-of-the-metrics-pdk) section for other caveats to note when using this PDK.

## How it works

`kong.metrics` exposes three metric constructors. Each one returns a metric handle that you keep and record values against:

<!--vale off-->
{% table %}
columns:
  - title: Constructor
    key: constructor
  - title: Metric kind
    key: kind
  - title: Record methods
    key: methods
  - title: Typical use
    key: use
  - title: Recording semantics
    key: semantics
rows:
  - constructor: "`kong.metrics.counter(name, opts)`"
    kind: Monotonic sum
    methods: "`:add()`"
    use: Counts that only go up, like requests or errors.
    semantics: A cumulative, monotonic sum. Exported with `is_monotonic = true` and cumulative aggregation temporality.
  - constructor: "`kong.metrics.gauge(name, opts)`"
    kind: Settable value
    methods: "`:record()`, `:add()`"
    use: Current values that go up and down, like queue depth.
    semantics: "A last-write value. `:record()` sets it. `:add()` applies a delta. Exported with cumulative aggregation temporality."
  - constructor: "`kong.metrics.histogram(name, opts)`"
    kind: Distribution
    methods: "`:record()`"
    use: Value distributions, like latencies or sizes.
    semantics: "Tracks `count`, `sum`, `min`, `max`, and per-bucket counts. Exported with cumulative aggregation temporality."
{% endtable %}
<!--vale on-->

Metrics are stored in the `kong_metrics` shared dictionary and exported as OTLP data points by the OpenTelemetry plugin.

### Requirements

* **Shared dictionary**: Metrics are stored in the `lua_shared_dict kong_metrics` shared dictionary (`stream_kong_metrics` for the stream subsystem). 
The dictionary is sized by the [`metrics_mem_size`](/gateway/configuration/#metrics-mem-size) configuration parameter, which defaults to `10m`. 
High attribute cardinality multiplies the number of keys stored. Increase `metrics_mem_size` if you use many distinct attribute-value combinations.
* **OpenTelemetry plugin**: Custom metrics leave {{site.base_gateway}} only through the [OpenTelemetry plugin](/plugins/opentelemetry/), which merges your metrics into its OTLP export batch. 
Without the OpenTelemetry plugin configured with metrics enabled and an OTLP endpoint set, values still accumulate in the shared dictionary but are never exported. 

### Validation and rules

The Metrics PDK validates every registration and record call against the following rules:

<!--vale off-->
{% table %}
columns:
  - title: Rule
    key: rule
  - title: Description
    key: description
rows:
  - rule: Metric and attribute name pattern
    description: |
      `^[a-z_][a-z0-9_.]*$`. Metric and attribute names use lowercase letters, digits, `_`, and `.`, and must start with a letter or underscore.
  - rule: Reserved names
    description: |
      You can't register a name that matches a built-in {{site.base_gateway}} metric, for example `http.server.request.count` or `kong.nginx.connection.count`.
  - rule: Attribute count
    description: |
      Capped at 15 per `:add()` or `:record()` call, to protect the Gateway against cardinality blow-ups. 
      A call that exceeds this limit drops the data point and logs an error.
  - rule: Attribute value constraints
    description: |
      Values must be strings or numbers, must not be `NaN`, and strings must not contain `,`, `{`, or `}`.
  - rule: Duplicate registration
    description: |
      Not supported. If you attempt to register a metric name that's already in use, the metric is rejected and logs an error.
  - rule: Value constraints
    description: |
      Counter and histogram values must be finite numbers greater than or equal to `0`. 
      Gauge values must be finite, and may be negative. Non-finite values (`NaN`, `±inf`) are rejected everywhere.
{% endtable %}
<!--vale on-->

### Export and OTLP mapping

The OpenTelemetry plugin appends custom metrics to its OTLP export batch on its push interval:

* `attributes`, the table passed at record time, becomes the OTLP data-point's attributes.
* `value_type` becomes `as_int` or `as_double` for counter and gauge points.
* Histogram points export `count`, `sum`, `min`, `max`, `bucket_counts`, and `explicit_bounds`.
* `description` and `unit` are carried on the exported metric.

{{site.base_gateway}}'s built-in metrics and custom PDK metrics are exported together. 
If the OpenTelemetry plugin hasn't produced any built-in metrics on a given cycle, custom metrics are still exported on their own.

### Error handling and no-op behavior

The Metrics PDK is designed to never disrupt the request path:

* If the `kong_metrics` shared dictionary isn't available, or the metrics subsystem fails to initialize, `kong.metrics` returns no-op handles. In this situation, `:add()` and `:record()` do nothing.
* Invalid registration input, like a bad name, a reserved name, malformed options, or a conflicting duplicate, logs an error and returns a no-op handle. The calling code continues to work.
* Invalid record-time input, like the wrong attribute count, a non-finite value, a negative value where it isn't allowed, or the wrong method for the metric kind, logs an error and drops that single observation.

Because failures degrade to no-ops, check [{{site.base_gateway}}'s error log](/gateway/configuration/#proxy-error-log) when a custom metric doesn't appear as expected.

### Registering and recording metrics

Register each metric once, for example as a plugin-module-level local variable or in your plugin's `init_worker` handler, and keep the returned handle to record values against later, typically from the `access`, `response`, or `log` phase:

```lua
-- Registered when the handler module loads at Gateway startup
local requests_total = kong.metrics.counter("my_plugin.requests", {
  description = "Number of requests processed by my_plugin",
  unit        = "{request}",
})

local MyPluginHandler = { PRIORITY = 1000, VERSION = "1.0.0" }

function MyPluginHandler:log(conf)
  requests_total:add(1, { ["kong.service.name"] = "example-service", status = "success" })
end

return MyPluginHandler
```

Each record call takes its own `attributes` table as its second argument, so different call sites for the same metric can report different attributes:

```lua
requests_total:add(1, { status = "success" })
requests_total:add(1, { consumer = consumer.id })
```

Here's an example of a complete plugin handler that registers a counter, a histogram, and a gauge, and records against each of them per request:

```lua
local requests_total = kong.metrics.counter("my_plugin.requests.total", {
  description = "Total requests processed by my_plugin",
  unit        = "{request}",
})

local requests_duration = kong.metrics.histogram("my_plugin.requests.duration", {
  description     = "Duration of requests processed by my_plugin",
  unit            = "s",
  explicit_bounds = { 0.01, 0.05, 0.1, 0.5, 1, 5 },
})

local body_size = kong.metrics.gauge("my_plugin.body.size", {
  description = "The size of the request body processed by my_plugin",
  unit        = "{By}",
  value_type  = kong.metrics.VALUE_TYPE.AS_DOUBLE,
})

-- Attribute values must be strings/numbers, keyed by attribute name.
-- Fall back to "unknown" for missing/unnamed entities.
local function get_attributes()
  local service = kong.router.get_service()
  local route   = kong.router.get_route()

  local service_name = (service and type(service.name) == "string") and service.name or "unknown"
  local route_name   = (route and type(route.name) == "string") and route.name or "unknown"

  return {
    ["kong.service.name"] = service_name,
    ["kong.route.name"]   = route_name,
  }
end

local MyPluginHandler = {
  PRIORITY = 1000,
  VERSION  = "1.0.0",
}

function MyPluginHandler:access(conf)
  ngx.ctx.start_time = ngx.now()

  requests_total:add(1, get_attributes())
  body_size:record(2.3, get_attributes())
end

function MyPluginHandler:response(conf)
  local start_time = ngx.ctx.start_time
  if not start_time then
    return
  end

  requests_duration:record(ngx.now() - start_time, get_attributes())
end

return MyPluginHandler
```
{:.collapsible}

{:.warning}
> **Warning**: The Metrics PDK doesn't mask or redact attribute values. You're responsible for what your plugin puts into an `attributes` table: don't record sensitive data, like personally identifiable information, credentials, or tokens, as an attribute value.

See the [`kong.metrics` PDK reference](/gateway/pdk/reference/kong.metrics/) for the full parameter and return value details for `counter()`, `gauge()`, and `histogram()`.

## Best practices

* **Namespace your metric names**, following OpenTelemetry semantic naming conventions: dot-separated, lowercase, with no unit suffix (units belong in `opts.unit`). For example, use `customer_name.request.count` rather than `customer_name_request_count_total`, to avoid colliding with {{site.base_gateway}}'s built-in metrics and other plugins.
* **Keep attribute cardinality low**: Each distinct combination of `attributes` creates a separate stored series and OTLP data point. Avoid high-cardinality values like user IDs, request IDs, or raw tokens. Prefer bounded dimensions like service name, route name, or status class.
* **Keep attribute keys consistent across calls to the same metric**: The Metrics PDK doesn't enforce a fixed key set, so each `:add()` or `:record()` call can pass any `attributes` table. Recording the same metric with different attribute keys can cause unintended behavior, such as Prometheus treating it as an entirely new series, which can break existing dashboards and queries.
* **Provide stable attribute values**: Fall back to a constant like `"unknown"` when an entity or field might be absent, rather than passing `nil`, which is an invalid attribute value.

## Limitations of the metrics PDK

The metrics PDK has some limitations. Go through each one before you build it into your custom plugins:

* `kong.metrics` isn't available from the [Pre-function](/plugins/pre-function/) or [Post-function](/plugins/post-function/) plugins.
* Registering a name that's already in use fails. See [Validation and rules](#validation-and-rules).
* Metric data lives in a shared dictionary (`kong_metrics`) with no runtime flush. Restarting the Gateway is the only way to clear existing data. For streaming custom plugins specifically, changing a metric's definition also requires a Gateway restart to take effect.
* Recording a fractional value, like `1.23`, on a counter or gauge requires an explicit `value_type`. Set `opts.value_type = kong.metrics.VALUE_TYPE.AS_DOUBLE` at registration, otherwise {{site.base_gateway}} treats the value as an integer.
* A numeric attribute value like `123` is stored and exported as the string `"123"` instead of a number.
* All metrics currently share a single, implicit meter.
