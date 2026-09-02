---
title: Add metrics to a custom plugin
description: Register and record custom metrics from your custom plugin using the Metrics PDK.
  
content_type: how_to

permalink: /custom-plugins/get-started/add-metrics/
breadcrumbs:
  - /custom-plugins/

series:
  id: plugin-dev-get-started
  position: 6

tldr:
  q: How do I add custom metrics to my custom plugin?
  a: Register a counter or gauge with `kong.metrics` in your plugin's `handler.lua`, record values against it in a request phase, and enable the OpenTelemetry plugin to export it.

tags:
  - custom-plugins
  - pdk
  - metrics
  - monitoring

products:
  - gateway

min_version:
  gateway: '3.16'

works_on:
  - on-prem

prereqs:
  skip_product: true

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
  - text: Metrics PDK
    url: /custom-plugins/metrics-pdk/
  - text: OpenTelemetry plugin
    url: /plugins/opentelemetry/

automated_tests: false
---

The Metrics PDK (`kong.metrics`) lets your custom plugin register and record its own counter, gauge, and histogram metrics, alongside {{site.base_gateway}}'s built-in metrics. This guide adds a counter and a gauge to the `my-plugin` handler from this series, then exports them with the [OpenTelemetry plugin](/plugins/opentelemetry/) so you can query them in Prometheus.

For the full API and concepts behind the Metrics PDK, see the [Metrics PDK reference](/custom-plugins/metrics-pdk/).

## Register the metrics

Open the `handler.lua` file you created in [Set up a custom plugin project](/custom-plugins/get-started/set-up-plugin-project/), and register a counter and a gauge as module-level locals, above the plugin handler table:

```lua
local MyPluginHandler = {
  PRIORITY = 1000,
  VERSION = "0.0.1",
}

local request_count = kong.metrics.counter("my_plugin.request.count", {
  description = "Number of requests processed by my-plugin",
  unit = "{request}",
})

local in_flight = kong.metrics.gauge("my_plugin.requests.in_flight", {
  description = "Number of requests currently being processed by my-plugin",
  unit = "{request}",
})
```

{:.info}
> **Note**: Register each metric once, when the plugin module loads. Don't call `kong.metrics.counter()` or `kong.metrics.gauge()` from a request phase. Only the record calls, like `:add()` and `:record()`, belong in `access`, `response`, or `log`.

## Record values

Add an `access` function that increments the gauge as a request comes in, and a `log` function that increments the counter and decrements the gauge once the request finishes:

```lua
function MyPluginHandler:access(conf)
  in_flight:add(1)
end

function MyPluginHandler:log(conf)
  request_count:add(1, {
    status = kong.response.get_status(),
    method = kong.request.get_method(),
  })

  in_flight:add(-1)
end
```

The full `handler.lua` file now looks like this:

```lua
local MyPluginHandler = {
  PRIORITY = 1000,
  VERSION = "0.0.1",
}

local request_count = kong.metrics.counter("my_plugin.request.count", {
  description = "Number of requests processed by my-plugin",
  unit = "{request}",
})

local in_flight = kong.metrics.gauge("my_plugin.requests.in_flight", {
  description = "Number of requests currently being processed by my-plugin",
  unit = "{request}",
})

function MyPluginHandler:response(conf)
    kong.response.set_header("X-MyPlugin", "response")
end

function MyPluginHandler:access(conf)
  in_flight:add(1)
end

function MyPluginHandler:log(conf)
  request_count:add(1, {
    status = kong.response.get_status(),
    method = kong.request.get_method(),
  })

  in_flight:add(-1)
end

return MyPluginHandler
```

`request_count` only ever gets `:add(1)`, because a counter must not decrease. `in_flight` uses `:add(1)` and `:add(-1)`, because a gauge accepts negative deltas.

## Enable export through the OpenTelemetry plugin

Custom metrics leave {{site.base_gateway}} only through the [OpenTelemetry plugin](/plugins/opentelemetry/). Add the plugin to your configuration with metrics enabled and an OTLP endpoint set. For example, in a declarative configuration file:

```yaml
plugins:
  - name: opentelemetry
    config:
      metrics:
        endpoint: "http://otel-collector:4318/v1/metrics"
```

See [Collect metrics, logs, and traces with the OpenTelemetry plugin](/how-to/collect-metrics-logs-and-traces-with-opentelemetry/) for a full setup using an OpenTelemetry Collector and Prometheus.

## Verify

1. Send a few requests through the route where `my-plugin` is enabled.

1. In Prometheus, query the counter:

   ```
   my_plugin_request_count_total
   ```

   You should see a series with a value equal to the number of requests you sent, labeled with `status` and `method`.

1. Query the gauge:

   ```
   my_plugin_requests_in_flight
   ```

   The value returns to `0` between requests, since `access` and `log` add and subtract the same amount.

{:.info}
> **Note**: If a metric doesn't appear, check {{site.base_gateway}}'s error log. The Metrics PDK degrades to a no-op on invalid input rather than disrupting the request path, so a registration or recording mistake logs an error instead of failing the request.
