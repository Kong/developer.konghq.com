---
title: Add metrics to a custom plugin
description: Register and record custom metrics from your custom plugin using the Metrics PDK.
  
content_type: how_to

permalink: /custom-plugins/get-started/add-metrics/
breadcrumbs:
  - /custom-plugins/

series:
  id: plugin-dev-get-started
  position: 5

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

The Metrics PDK (`kong.metrics`) lets your custom plugin register and record its own counter, gauge, and histogram metrics, alongside {{site.base_gateway}}'s built-in metrics. 
This guide adds a counter and a gauge to the `my-plugin` handler from this series, then exports them with the [OpenTelemetry plugin](/plugins/opentelemetry/) so you can query them in Prometheus.

For the full API and concepts behind the Metrics PDK, see the [Metrics PDK reference](/custom-plugins/metrics-pdk/).

## Register the metrics

Open the `handler.lua` file you last edited in [Consume external services](/custom-plugins/get-started/consume-external-services/), and register a counter and a gauge as module-level locals, above the plugin handler table:

```lua
local http  = require("resty.http")
local cjson = require("cjson.safe")

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
> **Note**: Register each metric once, when the plugin module loads. 
Don't call `kong.metrics.counter()` or `kong.metrics.gauge()` from a request phase. 
Only the record calls, like `:add()` and `:record()`, belong in `access`, `response`, or `log`.

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

{:.warning}
> **Warning**: The Metrics PDK doesn't mask or redact attribute values. You're responsible for what your plugin puts into an `attributes` table: don't record sensitive data, like personally identifiable information, credentials, or tokens, as an attribute value.

The full `handler.lua` file now looks like this:

```lua
local http  = require("resty.http")
local cjson = require("cjson.safe")

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

  kong.log("response handler")

  local httpc = http.new()

  local res, err = httpc:request_uri("http://httpbin.konghq.com/anything", {
    method = "GET",
  })

  if err then
    return kong.response.error(500,
      "Error when trying to access third-party service: " .. err,
      { ["Content-Type"] = "text/html" })
  end

  local body_table, err = cjson.decode(res.body)

  if err then
    return kong.response.error(500,
      "Error when decoding third-party service response: " .. err,
      { ["Content-Type"] = "text/html" })
  end

  kong.response.set_header(conf.response_header_name, body_table.url)

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

## Set up the export pipeline

Custom metrics leave {{site.base_gateway}} only through the [OpenTelemetry plugin](/plugins/opentelemetry/). 
Set up a small local pipeline with Docker Compose so you can query the metrics you just added: {{site.base_gateway}}, an OpenTelemetry Collector, and Prometheus, 

1. In your plugin project's root directory, create the OpenTelemetry Collector configuration. It receives OTLP data from {{site.base_gateway}} and forwards it to Prometheus:

   ```bash
   cat <<'EOF' > otel-collector-config.yaml
   receivers:
     otlp:
       protocols:
         http:
           endpoint: 0.0.0.0:4318

   processors:
     batch:

   exporters:
     otlphttp/prometheus:
       endpoint: http://prometheus:9090/api/v1/otlp

   service:
     pipelines:
       metrics:
         receivers: [otlp]
         processors: [batch]
         exporters: [otlphttp/prometheus]
   EOF
   ```

1. Create the Prometheus configuration to enable Prometheus's OTLP receiver:

   ```bash
   cat <<'EOF' > prometheus.yml
   storage:
     tsdb:
       out_of_order_time_window: 30m

   otlp:
     promote_resource_attributes:
       - service.name
   EOF
   ```

1. Create a declarative configuration file for {{site.base_gateway}}. The following configuration contains a Service and Route, `my-plugin`, and the OpenTelemetry plugin:

   ```bash
   cat <<'EOF' > kong.yml
   _format_version: "3.0"

   services:
     - name: example-service
       url: https://httpbin.konghq.com
       routes:
         - name: example-route
           paths:
           - "/anything"
           protocols:
           - http
           - https
   plugins:
     - name: my-plugin
       route: example-route
     - name: opentelemetry
       config:
         metrics:
           endpoint: "http://otel-collector:4318/v1/metrics"
           push_interval: 5
   EOF
   ```

1. Create the Docker Compose file:

   ```bash
   cat <<'EOF' > docker-compose.yaml
   services:
     kong:
       image: kong/kong-gateway:latest
       environment:
         KONG_DATABASE: "off"
         KONG_DECLARATIVE_CONFIG: /kong/declarative/kong.yml
         KONG_PLUGINS: bundled,my-plugin
         KONG_LUA_PACKAGE_PATH: /kong/plugins/?.lua;/kong/plugins/?/init.lua;;
       volumes:
         - ./kong.yml:/kong/declarative/kong.yml:ro
         - ./kong/plugins/my-plugin:/kong/plugins/my-plugin:ro
       ports:
         - "8000:8000"
         - "8001:8001"

     otel-collector:
       image: otel/opentelemetry-collector-contrib:latest
       command: ["--config=/etc/otel-collector-config.yaml"]
       volumes:
         - ./otel-collector-config.yaml:/etc/otel-collector-config.yaml:ro
       ports:
         - "4318:4318"

     prometheus:
       image: prom/prometheus:latest
       command:
         - "--config.file=/etc/prometheus/prometheus.yml"
         - "--web.enable-otlp-receiver"
       volumes:
         - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
       ports:
         - "9090:9090"
   EOF
   ```

1. Start the pipeline:

   ```sh
   docker compose up
   ```

## Verify

1. In a new terminal, send a few requests through the example Route:

   ```sh
   curl http://localhost:8000/anything
   ```

1. Open Prometheus at [http://localhost:9090](http://localhost:9090) and query the counter. Enter the following into the text box and click **Execute**:

   ```sh
   my_plugin_request_count_total
   ```

   You should see a series with a value equal to the number of requests you sent, labeled with `status` and `method`.

1. Now let's query the gauge. Enter the following into the text box and click **Execute**:

   ```sh
   my_plugin_requests_in_flight
   ```

   The value returns to `0` between requests, since `access` and `log` add and subtract the same amount.

{:.info}
> **Note**: If a metric doesn't appear, check {{site.base_gateway}}'s error log with `docker compose logs kong`. 
If an input is invalid, the Metrics PDK logs an error and does nothing, rather than disrupting the request path. 
A registration or recording mistake logs an error instead of failing the request.