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
  - text: Custom plugins
    url: /custom-plugins/
  - text: Custom plugins reference
    url: /custom-plugins/reference/
  - text: Add metrics to a custom plugin
    url: /custom-plugins/get-started/add-metrics/
  - text: "kong.metrics PDK reference"
    url: /gateway/pdk/reference/kong.metrics/
  - text: OpenTelemetry plugin
    url: /plugins/opentelemetry/
  - text: "{{site.base_gateway}} OpenTelemetry metrics reference"
    url: /gateway/otel-metrics/
---

The Metrics PDK is a `kong.metrics` namespace that lets a custom plugin define and record its own counter, gauge, and histogram metrics, alongside {{site.base_gateway}}'s built-in metrics. You register a metric once and record values against it on every request. Custom metrics flow through {{site.base_gateway}}'s existing [OpenTelemetry plugin](/plugins/opentelemetry/) export path, alongside the built-in metrics.

For the full function-by-function API, including parameters and return values, see the [`kong.metrics` PDK reference](/gateway/pdk/reference/kong.metrics/). This page covers the concepts you need to use it well: how metrics are stored and exported, what the PDK validates, and where its limits are.

{:.info}
> **Note**: The Metrics PDK isn't available in [Pre-function](/plugins/pre-function/) or [Post-function](/plugins/post-function/) plugins.

## Overview

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
rows:
  - constructor: "`kong.metrics.counter(name, opts)`"
    kind: Monotonic sum
    methods: "`:add()`"
    use: Counts that only go up, like requests or errors.
  - constructor: "`kong.metrics.gauge(name, opts)`"
    kind: Settable value
    methods: "`:record()`, `:add()`"
    use: Current values that go up and down, like queue depth.
  - constructor: "`kong.metrics.histogram(name, opts)`"
    kind: Distribution
    methods: "`:record()`"
    use: Value distributions, like latencies or sizes.
{% endtable %}
<!--vale on-->

Metrics are stored in the `kong_metrics` shared dictionary and exported as OTLP data points by the OpenTelemetry plugin.

## Requirements

* **Shared dictionary.** Metrics are stored in the `lua_shared_dict kong_metrics` shared dictionary (`stream_kong_metrics` for the stream subsystem). The dictionary is sized by the [`metrics_mem_size`](/gateway/configuration/#metrics-mem-size) configuration parameter, which defaults to `10m`. High attribute cardinality multiplies the number of keys stored. Increase `metrics_mem_size` if you use many distinct attribute-value combinations.
* **Export requires the OpenTelemetry plugin.** Custom metrics leave {{site.base_gateway}} only through the [OpenTelemetry plugin](/plugins/opentelemetry/), which merges your metrics into its OTLP export batch. Without the OpenTelemetry plugin configured with metrics enabled and an OTLP endpoint set, values still accumulate in the shared dictionary but are never exported. The Prometheus and StatsD plugins don't currently export custom metrics.

## Register and record metrics

Register each metric once, for example as a plugin-module-level local variable or in your plugin's `init_worker` handler, and keep the returned handle to record values against later, typically from the `access`, `response`, or `log` phase:

```lua
-- Registered once, when the handler module loads (Gateway startup),
-- not per request.
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

See the [`kong.metrics` PDK reference](/gateway/pdk/reference/kong.metrics/) for the full parameter and return value details for `counter()`, `gauge()`, and `histogram()`.

## Validation and rules

* **Metric name pattern:** `^[a-z_][a-z0-9_.]*$`. Names use lowercase letters, digits, `_`, and `.`, and must start with a letter or underscore. The same pattern applies to attribute names.
* **Reserved names:** You can't register a name that matches a built-in {{site.base_gateway}} metric, for example `http.server.request.count` or `kong.nginx.connection.count`.
* **Attribute count** is capped at 15 per `:add()` or `:record()` call, to protect the Gateway against cardinality blow-ups. A call that exceeds this limit drops the data point and logs an error.
* **Attribute value constraints:** Values must be strings or numbers, must not be `NaN`, and strings must not contain `,`, `{`, or `}`.
* **Duplicate registration** isn't supported. Registering a metric name that's already in use is rejected and logs an error.
* **Value constraints:** Counter and histogram values must be finite numbers greater than or equal to `0`. Gauge values must be finite, and may be negative. Non-finite values (`NaN`, `±inf`) are rejected everywhere.

## Recording semantics

* **Counter:** A cumulative, monotonic sum. Exported with `is_monotonic = true` and cumulative aggregation temporality.
* **Gauge:** A last-write value. `:record()` sets it. `:add()` applies a delta. Exported with cumulative aggregation temporality.
* **Histogram:** Tracks `count`, `sum`, `min`, `max`, and per-bucket counts. Exported with cumulative aggregation temporality.

## Export and OTLP mapping

The OpenTelemetry plugin appends custom metrics to its OTLP export batch on its push interval:

* `attributes`, the table passed at record time, becomes OTLP data-point attributes, one per key-value pair.
* `value_type` becomes `as_int` or `as_double` for counter and gauge points.
* Histogram points export `count`, `sum`, `min`, `max`, `bucket_counts`, and `explicit_bounds`.
* `description` and `unit` are carried on the exported metric.

{{site.base_gateway}}'s built-in metrics and custom PDK metrics are exported together. If the OpenTelemetry plugin hasn't produced any built-in metrics on a given cycle, custom metrics are still exported on their own.

## Error handling and no-op behavior

The Metrics PDK is designed to never disrupt the request path:

* If the `kong_metrics` shared dictionary is unavailable, or the metrics subsystem fails to initialize, `kong.metrics` returns no-op handles: `:add()` and `:record()` do nothing.
* Invalid registration input, like a bad name, a reserved name, malformed options, or a conflicting duplicate, logs an error and returns a no-op handle. The calling code continues to work.
* Invalid record-time input, like the wrong attribute count, a non-finite value, a negative value where it isn't allowed, or the wrong method for the metric kind, logs an error and drops that single observation.

Because failures degrade to no-ops, check {{site.base_gateway}}'s error log when a custom metric doesn't appear as expected.

## Limitations

* **Not supported in Pre-function or Post-function plugins.** `kong.metrics` isn't available from the [Pre-function](/plugins/pre-function/) or [Post-function](/plugins/post-function/) plugins.
* **Duplicate metric names are rejected.** Registering a name that's already in use fails. See [Validation and rules](#validation-and-rules).
* **Data doesn't clear without a restart.** Metric data lives in a shared dictionary (`kong_metrics`). There's no runtime flush. Restart the Gateway to clear existing data. For stream custom plugins specifically, if a metric's definition changes, you must restart the Gateway for that change to take effect.
* **Double values require an explicit `value_type`.** If you record a fractional value, like `1.23`, on a counter or gauge, set `opts.value_type = kong.metrics.VALUE_TYPE.AS_DOUBLE` at registration. Otherwise {{site.base_gateway}} treats it as an integer.
* **Attribute values are always stringified.** A numeric attribute value like `123` is stored and exported as the string `"123"`, not a number.
* **Only one meter exists.** All metrics currently share a single, implicit meter.

## Recommendations

* **Namespace your own metrics**, for example `customer_name.request.count`, to avoid collisions with {{site.base_gateway}}'s built-in metrics and other plugins.
* **Follow OpenTelemetry semantic naming conventions**: dot-separated, lowercase, with no unit suffix in the name. Units belong in `opts.unit`. For example, use `customer_name.request.count` rather than `customer_name_request_count_total`.
* **Register once, record many.** Don't call the constructor on every request.
* **Keep attribute cardinality low.** Each distinct combination of `attributes` creates a separate stored series and OTLP data point. Avoid high-cardinality values like user IDs, request IDs, or raw tokens. Prefer bounded dimensions like service name, route name, or status class, and size `metrics_mem_size` accordingly.
* **Keep attribute keys consistent across calls to the same metric.** The Metrics PDK doesn't enforce a fixed key set. Each `:add()` or `:record()` call can pass any `attributes` table. Recording the same metric with different attribute keys can cause unintended behavior, such as Prometheus treating it as an entirely new series, which can break existing dashboards and queries.
* **Provide stable attribute values.** Fall back to a constant like `"unknown"` when an entity or field might be absent, rather than passing `nil`, which is an invalid attribute value.
