---
title: Collect metrics, logs, and traces with the OpenTelemetry plugin
permalink: /how-to/collect-metrics-logs-and-traces-with-opentelemetry/
content_type: how_to

description: Use the OpenTelemetry plugin to send {{site.base_gateway}} metrics, logs, and traces to OpenTelemetry Collector.

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.13'

plugins:
  - opentelemetry

entities: 
  - service
  - route
  - plugin

tags:
    - analytics
    - monitoring

search_aliases:
  - otel

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  gateway:
    - name: KONG_TRACING_INSTRUMENTATIONS
      value: all
    - name: KONG_TRACING_SAMPLING_RATE
      value: 1.0
  konnect:
    - name: KONG_TRACING_INSTRUMENTATIONS
      value: all
    - name: KONG_TRACING_SAMPLING_RATE
      value: 1.0
  inline:
  - title: OpenTelemetry Collector
    content: |
      In this tutorial, we'll collect data in OpenTelemetry Collector. Use the following command to launch a Collector instance with default configuration that listens on port 4318 and writes its output to a text file:

      ```sh
      docker run \
        -p 127.0.0.1:4318:4318 \
        otel/opentelemetry-collector:0.141.0 \
        2>&1 | tee collector-output.txt
      ```

      In a new terminal, export the OTEL Collector host. In this example, use the following host:
      ```sh
      export DECK_OTEL_HOST=host.docker.internal
      ```
    icon: assets/icons/opentelemetry.svg
      

tldr:
    q: How do I send {{site.base_gateway}} data to OpenTelemetry Collector?
    a: |
     For a basic configuration that sends traces, metrics, and logs to a locally running OpenTelemetry Collector, 
     first set `KONG_TRACING_INSTRUMENTATIONS=all` and `KONG_TRACING_SAMPLING_RATE=1.0` when deploying {{site.base_gateway}} 
     to enable tracing. Then deploy OpenTelemetry Collector with the default configuration and enable the OTEL plugin with your OpenTelemetry Collector's default OTLP endpoints.

tools:
    - deck

related_resources:
  - text: Send OpenTelemetry data to Grafana Cloud
    url: /how-to/send-otel-data-to-grafana-cloud/

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

## Enable the OTEL plugin

In this tutorial, let's configure the [OpenTelemetry plugin](/plugins/opentelemetry/) to send {{site.base_gateway}} metrics, traces, and logs to OpenTelemetry Collector.

Enable the OTEL plugin with the OTEL Collector endpoints settings configured:

{% entity_examples %}
entities:
  plugins:
  - name: opentelemetry
    config:
      traces_endpoint: "http://${otel-host}:4318/v1/traces"
      access_logs_endpoint: "http://${otel-host}:4318/v1/logs"
      logs_endpoint: "http://${otel-host}:4318/v1/logs"
      metrics:
        endpoint: "http://${otel-host}:4318/v1/metrics"
      resource_attributes:
        service.name: "kong-dev"

variables:
  otel-host:
    value: $OTEL_HOST
{% endentity_examples %}

## Validate

Send a `POST` request to generate traffic that we can use to validate that OpenTelemetry Collector is receiving the telemetry data:

{% validation request-check %}
url: /anything
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
{% endvalidation %}

You should see data in your OpenTelemetry Collector terminal. You can also search for `kong-dev` in the `collector-output.txt` output file. You should see the following data:

```sh
Resource attributes:
     -> service.name: Str(kong-dev)
     -> service.instance.id: Str(9343ac04-81d6-4ac8-bb5a-c7322c823368)
     -> service.version: Str(3.14.0.0)
ScopeSpans #0
ScopeSpans SchemaURL: 
InstrumentationScope kong-internal 0.1.0
Span #0
    Trace ID       : 111216d769f06a7486de78aaf6bb3056
    Parent ID      : 
    ID             : 7ddb4028163987aa
    Name           : kong
    Kind           : Server
    Start time     : 2025-12-12 10:47:13.299000064 +0000 UTC
    End time       : 2025-12-12 10:47:13.417065216 +0000 UTC
    Status code    : Unset
    Status message : 
Attributes:
     -> http.route: Str(/anything)
     -> http.host: Str(localhost)
     -> http.scheme: Str(http)
     -> http.client_ip: Str(192.168.107.1)
     -> kong.request.id: Str(319d1e4e7862095f704a7d6c60e63260)
     -> net.peer.ip: Str(192.168.107.1)
     -> http.status_code: Int(200)
     -> http.method: Str(POST)
     -> http.url: Str(http://localhost/anything)
     -> http.flavor: Str(1.1)
Span #1
    Trace ID       : 111216d769f06a7486de78aaf6bb3056
    Parent ID      : 7ddb4028163987aa
    ID             : 0534077d2df6b03d
    Name           : kong.router
    Kind           : Internal
    Start time     : 2025-12-12 10:47:13.300975616 +0000 UTC
    End time       : 2025-12-12 10:47:13.303639808 +0000 UTC
    Status code    : Unset
    Status message : 
Span #2
    Trace ID       : 111216d769f06a7486de78aaf6bb3056
    Parent ID      : 7ddb4028163987aa
    ID             : 6032aadc108feff0
    Name           : kong.access.plugin.opentelemetry
    Kind           : Internal
    Start time     : 2025-12-12 10:47:13.304194816 +0000 UTC
    End time       : 2025-12-12 10:47:13.30826752 +0000 UTC
    Status code    : Unset
    Status message : 
Span #3
    Trace ID       : 111216d769f06a7486de78aaf6bb3056
    Parent ID      : 7ddb4028163987aa
    ID             : b944a061d680c460
    Name           : kong.dns
    Kind           : Client
    Start time     : 2025-12-12 10:47:13.308358656 +0000 UTC
    End time       : 2025-12-12 10:47:13.34368896 +0000 UTC
    Status code    : Unset
    Status message : 
Attributes:
     -> dns.record.domain: Str(httpbin.konghq.com)
     -> dns.record.port: Double(80)
     -> dns.record.ip: Str(37.16.15.184)
Span #4
    Trace ID       : 111216d769f06a7486de78aaf6bb3056
    Parent ID      : 7ddb4028163987aa
    ID             : 70a90cfe6d86a90d
    Name           : kong.header_filter.plugin.opentelemetry
    Kind           : Internal
    Start time     : 2025-12-12 10:47:13.416722176 +0000 UTC
    End time       : 2025-12-12 10:47:13.416754944 +0000 UTC
    Status code    : Unset
    Status message : 
Span #5
    Trace ID       : 111216d769f06a7486de78aaf6bb3056
    Parent ID      : 7ddb4028163987aa
    ID             : a897ad034a5cd2ab
    Name           : kong.balancer
    Kind           : Client
    Start time     : 2025-12-12 10:47:13.344075008 +0000 UTC
    End time       : 2025-12-12 10:47:13.417065216 +0000 UTC
    Status code    : Unset
    Status message : 
Attributes:
     -> net.peer.ip: Str(37.16.15.184)
     -> net.peer.port: Double(80)
     -> net.peer.name: Str(httpbin.konghq.com)
     -> peer.service: Str(example-service)
     -> try_count: Double(1)
	{"resource": {"service.instance.id": "c8d7404a-6cca-4788-990f-b2cdf17cefc7", "service.name": "otelcol", "service.version": "0.141.0"}, "otelcol.component.id": "debug", "otelcol.component.kind": "exporter", "otelcol.signal": "traces"}
2025-12-12T10:47:14.496Z	info	ResourceLog #0
Resource SchemaURL: 
Resource attributes:
     -> service.name: Str(kong-dev)
     -> service.instance.id: Str(9343ac04-81d6-4ac8-bb5a-c7322c823368)
     -> service.version: Str(3.14.0.0)
ScopeLogs #0
ScopeLogs SchemaURL: 
InstrumentationScope api-access 0.1.0
LogRecord #0
ObservedTimestamp: 2025-12-12 10:47:13.420526336 +0000 UTC
Timestamp: 2025-12-12 10:47:13.420526336 +0000 UTC
SeverityText: 
SeverityNumber: Unspecified(0)
Body: Str(POST /anything 200 119ms)
Attributes:
     -> url.path: Str(/anything)
     -> http.response.status_code: Int(200)
     -> url.query: Str()
     -> url.full: Str(http://localhost:8000/anything)
     -> http.request.header.host: Str(localhost:8000)
     -> http.response.size: Int(1004)
     -> http.request.size: Int(131)
     -> http.request.method: Str(POST)
     -> url.scheme: Str(http)
     -> kong.upstream.try.1.balancer_latency: Double(1)
     -> log.type: Str(access)
     -> kong.upstream.status_code: Int(200)
     -> kong.service.write_timeout: Int(60000)
     -> kong.service.retries: Int(5)
     -> client.address: Str(192.168.107.1)
     -> kong.service.read_timeout: Int(60000)
     -> kong.service.port: Int(80)
     -> kong.service.connect_timeout: Int(60000)
     -> kong.route.regex_priority: Int(0)
     -> kong.response.source: Str(upstream)
     -> kong.route.https_redirect_status_code: Int(426)
     -> http.response.header.server: Str(gunicorn/19.9.0)
     -> kong.upstream.uri: Str(/anything)
     -> http.response.header.content-length: Int(623)
     -> http.response.body.size: Int(623)
     -> kong.upstream.try.1.ip: Str(37.16.15.184)
     -> kong.upstream.try.1.balancer_latency_ns: Double(306688)
     -> kong.upstream.try.1.port: Int(80)
     -> kong.upstream.try.1.balancer_start: Double(1765536433343)
     -> kong.upstream.try.1.balancer_start_ns: Double(1765536433344075000)
     -> kong.upstream.try.1.target_id: Str(unknown)
     -> kong.route.name: Str(example-route)
     -> kong.upstream.try.1.keepalive: Bool(true)
     -> url.port: Double(8000)
     -> url.domain: Str(localhost)
     -> kong.latency.receive: Double(1)
     -> http.response.header.connection: Str(close)
     -> http.response.header.content-type: Str(application/json)
     -> http.response.header.x-kong-request-id: Str(319d1e4e7862095f704a7d6c60e63260)
     -> http.response.header.via: Str(1.1 kong/3.14.0.0-enterprise-edition)
     -> kong.latency.upstream: Double(72)
     -> kong.subsystem: Str(http)
     -> http.response.header.x-kong-proxy-latency: Double(45)
     -> http.response.header.access-control-allow-origin: Str(*)
     -> http.response.header.x-kong-upstream-latency: Double(72)
     -> http.response.header.date: Str(Fri, 12 Dec 2025 10:47:13 GMT)
     -> kong.service.ws_id: Str(5765984d-7e48-4a2d-a3ce-1357895f3a87)
     -> kong.service.created_at: Int(1765535849)
     -> kong.service.updated_at: Int(1765535849)
     -> kong.service.host: Str(httpbin.konghq.com)
     -> kong.service.protocol: Str(http)
     -> kong.service.enabled: Bool(true)
     -> kong.service.path: Str(/anything)
     -> kong.service.id: Str(2c87bb4c-beed-4805-a3d2-e23ae2477bb2)
     -> kong.latency.total: Double(119)
     -> kong.workspace.name: Str(default)
     -> kong.latency.client: Double(1.526784)
     -> kong.latency.third_party.http_client: Double(0)
     -> kong.latency.third_party.socket: Double(0)
     -> kong.latency.third_party.redis: Double(0)
     -> kong.latency.third_party.dns: Double(35.279616)
     -> kong.latency.third_party.total: Double(35.279616)
     -> kong.workspace.id: Str(5765984d-7e48-4a2d-a3ce-1357895f3a87)
     -> kong.service.name: Str(example-service)
     -> kong.route.request_buffering: Bool(true)
     -> kong.route.response_buffering: Bool(true)
     -> kong.route.strip_path: Bool(true)
     -> kong.route.preserve_host: Bool(false)
     -> kong.latency.internal: Double(45)
     -> kong.route.created_at: Int(1765535849)
     -> kong.route.updated_at: Int(1765535849)
     -> http.response.header.access-control-allow-credentials: Str(true)
     -> kong.route.ws_id: Str(5765984d-7e48-4a2d-a3ce-1357895f3a87)
     -> kong.route.path_handling: Str(v0)
     -> kong.route.id: Str(7e95f889-75ff-46ee-9ed1-64ba9a78af53)
     -> kong.route.service.id: Str(2c87bb4c-beed-4805-a3d2-e23ae2477bb2)
     -> kong.route.protocols.1: Str(http)
     -> kong.route.protocols.2: Str(https)
     -> kong.route.paths.1: Str(/anything)
     -> kong.request.id: Str(319d1e4e7862095f704a7d6c60e63260)
     -> http.request.header.accept: Str(application/json)
     -> http.request.header.content-type: Str(application/json)
     -> http.request.header.user-agent: Str(curl/8.7.1)
     -> http.request.header.traceparent: Str(00-111216d769f06a7486de78aaf6bb3056-a897ad034a5cd2ab-01)
     -> user_agent.original: Str(curl/8.7.1)
     -> kong.request.started_at: Double(1765536433299)
...
Resource attributes:
     -> service.name: Str(kong-dev)
     -> service.instance.id: Str(9343ac04-81d6-4ac8-bb5a-c7322c823368)
     -> service.version: Str(3.14.0.0)
ScopeMetrics #0
ScopeMetrics SchemaURL: 
InstrumentationScope kong-internal 0.1.0
Metric #0
Descriptor:
     -> Name: kong.db.entity.count
     -> Description: Shows the number of entities stored in the Kong database.
     -> Unit: {entity}
     -> DataType: Gauge
NumberDataPoints #0
StartTimestamp: 2025-12-12 10:39:30.785713408 +0000 UTC
Timestamp: 2025-12-12 10:47:51.154927872 +0000 UTC
Value: 6
Metric #1
Descriptor:
     -> Name: kong.nginx.connection.count
     -> Description: Measures the number of client connections in Nginx.
     -> Unit: {connection}
     -> DataType: Gauge
NumberDataPoints #0
Data point attributes:
     -> kong.connection.state: Str(accepted)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.776530176 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150012416 +0000 UTC
Value: 75
NumberDataPoints #1
Data point attributes:
     -> kong.connection.state: Str(handled)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.776549632 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150177792 +0000 UTC
Value: 75
NumberDataPoints #2
Data point attributes:
     -> kong.connection.state: Str(total)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.776566272 +0000 UTC
Timestamp: 2025-12-12 10:47:51.1501824 +0000 UTC
Value: 105
NumberDataPoints #3
Data point attributes:
     -> kong.connection.state: Str(active)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.776581632 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150186752 +0000 UTC
Value: 12
NumberDataPoints #4
Data point attributes:
     -> kong.connection.state: Str(reading)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.776597504 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150191872 +0000 UTC
Value: 0
NumberDataPoints #5
Data point attributes:
     -> kong.connection.state: Str(writing)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.776627968 +0000 UTC
Timestamp: 2025-12-12 10:47:51.1501952 +0000 UTC
Value: 12
NumberDataPoints #6
Data point attributes:
     -> kong.connection.state: Str(waiting)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.776761088 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150198784 +0000 UTC
Value: 0
Metric #2
Descriptor:
     -> Name: kong.db.entity.error.count
     -> Description: Shows the number of errors seen during database entity count collection.
     -> Unit: {error}
     -> DataType: Sum
     -> IsMonotonic: true
     -> AggregationTemporality: Cumulative
NumberDataPoints #0
StartTimestamp: 2025-12-12 10:37:15.770924032 +0000 UTC
Timestamp: 2025-12-12 10:37:15.782457344 +0000 UTC
Value: 0
Metric #3
Descriptor:
     -> Name: kong.nginx.timer.count
     -> Description: Measures the number of scheduled timers Nginx is running in the background.
     -> Unit: {timer}
     -> DataType: Gauge
NumberDataPoints #0
Data point attributes:
     -> kong.timer.state: Str(pending)
StartTimestamp: 2025-12-12 10:39:30.776779008 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150206208 +0000 UTC
Value: 2
NumberDataPoints #1
Data point attributes:
     -> kong.timer.state: Str(running)
StartTimestamp: 2025-12-12 10:39:30.776788992 +0000 UTC
Timestamp: 2025-12-12 10:47:51.15021312 +0000 UTC
Value: 257
Metric #4
Descriptor:
     -> Name: kong.ee.license.expiration
     -> Description: Shows the Unix epoch time in seconds when the license expires, subtracted by 24 hours to avoid timezone differences.
     -> Unit: s
     -> DataType: Gauge
NumberDataPoints #0
StartTimestamp: 2025-12-12 10:39:30.785829632 +0000 UTC
Timestamp: 2025-12-12 10:47:51.155048704 +0000 UTC
Value: 1766145600
Metric #5
Descriptor:
     -> Name: kong.ee.license.features
     -> Description: Indicates whether Kong can read or write entities in the database under the current license, where 1 means allowed and 0 means not allowed.
     -> Unit: 1
     -> DataType: Gauge
NumberDataPoints #0
Data point attributes:
     -> kong.ee.license.feature: Str(ee_entity_write)
StartTimestamp: 2025-12-12 10:39:30.785869568 +0000 UTC
Timestamp: 2025-12-12 10:47:51.155072512 +0000 UTC
Value: 1
NumberDataPoints #1
Data point attributes:
     -> kong.ee.license.feature: Str(ee_entity_read)
StartTimestamp: 2025-12-12 10:39:30.785861888 +0000 UTC
Timestamp: 2025-12-12 10:47:51.155066624 +0000 UTC
Value: 1
Metric #6
Descriptor:
     -> Name: kong.shared_dict.usage
     -> Description: Shows the current memory usage of a shared dict in bytes.
     -> Unit: By
     -> DataType: Gauge
NumberDataPoints #0
Data point attributes:
     -> kong.shared_dict.name: Str(kong)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.777533184 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150955776 +0000 UTC
Value: 45056
NumberDataPoints #1
Data point attributes:
     -> kong.shared_dict.name: Str(kong_locks)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.777545728 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150959616 +0000 UTC
Value: 61440
NumberDataPoints #2
Data point attributes:
     -> kong.shared_dict.name: Str(kong_healthchecks)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.777558016 +0000 UTC
Timestamp: 2025-12-12 10:47:51.1509632 +0000 UTC
Value: 40960
NumberDataPoints #3
Data point attributes:
     -> kong.shared_dict.name: Str(kong_cluster_events)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.777824 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150966016 +0000 UTC
Value: 40960
NumberDataPoints #4
Data point attributes:
     -> kong.shared_dict.name: Str(kong_basic_auth_counters)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.77783808 +0000 UTC
Timestamp: 2025-12-12 10:47:51.1509696 +0000 UTC
Value: 86016
NumberDataPoints #5
Data point attributes:
     -> kong.shared_dict.name: Str(kong_rate_limiting_counters)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.7778496 +0000 UTC
Timestamp: 2025-12-12 10:47:51.15097216 +0000 UTC
Value: 86016
NumberDataPoints #6
Data point attributes:
     -> kong.shared_dict.name: Str(kong_ace_rate_limiting_counters)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.777860352 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150975232 +0000 UTC
Value: 86016
NumberDataPoints #7
Data point attributes:
     -> kong.shared_dict.name: Str(kong_core_db_cache)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.777870336 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150978048 +0000 UTC
Value: 802816
NumberDataPoints #8
Data point attributes:
     -> kong.shared_dict.name: Str(kong_core_db_cache_miss)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.777884672 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150981632 +0000 UTC
Value: 86016
NumberDataPoints #9
Data point attributes:
     -> kong.shared_dict.name: Str(kong_db_cache)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.777955584 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150984704 +0000 UTC
Value: 815104
NumberDataPoints #10
Data point attributes:
     -> kong.shared_dict.name: Str(kong_db_cache_miss)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.777966336 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150989568 +0000 UTC
Value: 86016
NumberDataPoints #11
Data point attributes:
     -> kong.shared_dict.name: Str(kong_consumers_db_cache)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.77797504 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150992384 +0000 UTC
Value: 794624
NumberDataPoints #12
Data point attributes:
     -> kong.shared_dict.name: Str(kong_consumers_db_cache_miss)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778080512 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150995456 +0000 UTC
Value: 86016
NumberDataPoints #13
Data point attributes:
     -> kong.shared_dict.name: Str(kong_secrets)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778129408 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150998528 +0000 UTC
Value: 40960
NumberDataPoints #14
Data point attributes:
     -> kong.shared_dict.name: Str(kong_vitals_counters)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778374656 +0000 UTC
Timestamp: 2025-12-12 10:47:51.1510016 +0000 UTC
Value: 315392
NumberDataPoints #15
Data point attributes:
     -> kong.shared_dict.name: Str(kong_vitals_lists)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778383872 +0000 UTC
Timestamp: 2025-12-12 10:47:51.15100416 +0000 UTC
Value: 16384
NumberDataPoints #16
Data point attributes:
     -> kong.shared_dict.name: Str(kong_vitals)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.7783936 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151007488 +0000 UTC
Value: 16384
NumberDataPoints #17
Data point attributes:
     -> kong.shared_dict.name: Str(kong_counters)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778400512 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151010048 +0000 UTC
Value: 16384
NumberDataPoints #18
Data point attributes:
     -> kong.shared_dict.name: Str(kong_reports_consumers)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778533632 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151012864 +0000 UTC
Value: 73728
NumberDataPoints #19
Data point attributes:
     -> kong.shared_dict.name: Str(kong_reports_routes)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.77860096 +0000 UTC
Timestamp: 2025-12-12 10:47:51.15101568 +0000 UTC
Value: 16384
NumberDataPoints #20
Data point attributes:
     -> kong.shared_dict.name: Str(kong_reports_services)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.77860864 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151019008 +0000 UTC
Value: 16384
NumberDataPoints #21
Data point attributes:
     -> kong.shared_dict.name: Str(kong_reports_workspaces)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778614272 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151021824 +0000 UTC
Value: 16384
NumberDataPoints #22
Data point attributes:
     -> kong.shared_dict.name: Str(kong_keyring)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778620416 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151024128 +0000 UTC
Value: 40960
NumberDataPoints #23
Data point attributes:
     -> kong.shared_dict.name: Str(kong_profiling_state)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778626304 +0000 UTC
Timestamp: 2025-12-12 10:47:51.1510272 +0000 UTC
Value: 20480
NumberDataPoints #24
Data point attributes:
     -> kong.shared_dict.name: Str(kong_vaults_hcv)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778631424 +0000 UTC
Timestamp: 2025-12-12 10:47:51.15102976 +0000 UTC
Value: 16384
NumberDataPoints #25
Data point attributes:
     -> kong.shared_dict.name: Str(kong_debug_session)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778637824 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151032064 +0000 UTC
Value: 16384
NumberDataPoints #26
Data point attributes:
     -> kong.shared_dict.name: Str(prometheus_metrics)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.7786432 +0000 UTC
Timestamp: 2025-12-12 10:47:51.15103488 +0000 UTC
Value: 40960
NumberDataPoints #27
Data point attributes:
     -> kong.shared_dict.name: Str(otel_metrics)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778679808 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151037696 +0000 UTC
Value: 40960
Metric #7
Descriptor:
     -> Name: kong.ee.license.error.count
     -> Description: Shows the number of errors occurred while collecting license information.
     -> Unit: {error}
     -> DataType: Sum
     -> IsMonotonic: true
     -> AggregationTemporality: Cumulative
NumberDataPoints #0
StartTimestamp: 2025-12-12 10:37:15.770968832 +0000 UTC
Timestamp: 2025-12-12 10:37:15.782564608 +0000 UTC
Value: 0
Metric #8
Descriptor:
     -> Name: kong.shared_dict.size
     -> Description: Shows the total memory size of a shared dict in bytes.
     -> Unit: By
     -> DataType: Gauge
NumberDataPoints #0
Data point attributes:
     -> kong.shared_dict.name: Str(kong)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779246336 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779247104 +0000 UTC
Value: 5242880
NumberDataPoints #1
Data point attributes:
     -> kong.shared_dict.name: Str(kong_locks)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779255296 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779255808 +0000 UTC
Value: 8388608
NumberDataPoints #2
Data point attributes:
     -> kong.shared_dict.name: Str(kong_healthchecks)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779259392 +0000 UTC
Timestamp: 2025-12-12 10:37:15.77926016 +0000 UTC
Value: 5242880
NumberDataPoints #3
Data point attributes:
     -> kong.shared_dict.name: Str(kong_cluster_events)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.7792704 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779271168 +0000 UTC
Value: 5242880
NumberDataPoints #4
Data point attributes:
     -> kong.shared_dict.name: Str(kong_basic_auth_counters)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779289856 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779290624 +0000 UTC
Value: 12582912
NumberDataPoints #5
Data point attributes:
     -> kong.shared_dict.name: Str(kong_rate_limiting_counters)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779296256 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779296768 +0000 UTC
Value: 12582912
NumberDataPoints #6
Data point attributes:
     -> kong.shared_dict.name: Str(kong_ace_rate_limiting_counters)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779309824 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779310592 +0000 UTC
Value: 12582912
NumberDataPoints #7
Data point attributes:
     -> kong.shared_dict.name: Str(kong_core_db_cache)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.77931392 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779314432 +0000 UTC
Value: 134217728
NumberDataPoints #8
Data point attributes:
     -> kong.shared_dict.name: Str(kong_core_db_cache_miss)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779318528 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779319296 +0000 UTC
Value: 12582912
NumberDataPoints #9
Data point attributes:
     -> kong.shared_dict.name: Str(kong_db_cache)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779325952 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779332096 +0000 UTC
Value: 134217728
NumberDataPoints #10
Data point attributes:
     -> kong.shared_dict.name: Str(kong_db_cache_miss)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779350016 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779350784 +0000 UTC
Value: 12582912
NumberDataPoints #11
Data point attributes:
     -> kong.shared_dict.name: Str(kong_consumers_db_cache)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779353856 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779354624 +0000 UTC
Value: 134217728
NumberDataPoints #12
Data point attributes:
     -> kong.shared_dict.name: Str(kong_consumers_db_cache_miss)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.77935872 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779359232 +0000 UTC
Value: 12582912
NumberDataPoints #13
Data point attributes:
     -> kong.shared_dict.name: Str(kong_secrets)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779364352 +0000 UTC
Timestamp: 2025-12-12 10:37:15.77936512 +0000 UTC
Value: 5242880
NumberDataPoints #14
Data point attributes:
     -> kong.shared_dict.name: Str(kong_vitals_counters)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.7793728 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779373568 +0000 UTC
Value: 52428800
NumberDataPoints #15
Data point attributes:
     -> kong.shared_dict.name: Str(kong_vitals)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779398656 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779399424 +0000 UTC
Value: 1048576
NumberDataPoints #16
Data point attributes:
     -> kong.shared_dict.name: Str(kong_counters)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779405056 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779405568 +0000 UTC
Value: 1048576
NumberDataPoints #17
Data point attributes:
     -> kong.shared_dict.name: Str(kong_reports_consumers)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779410432 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779410944 +0000 UTC
Value: 10485760
NumberDataPoints #18
Data point attributes:
     -> kong.shared_dict.name: Str(otel_metrics)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779468032 +0000 UTC
Timestamp: 2025-12-12 10:37:15.7794688 +0000 UTC
Value: 5242880
NumberDataPoints #19
Data point attributes:
     -> kong.shared_dict.name: Str(prometheus_metrics)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.7794624 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779462912 +0000 UTC
Value: 5242880
NumberDataPoints #20
Data point attributes:
     -> kong.shared_dict.name: Str(kong_debug_session)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779458048 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779458816 +0000 UTC
Value: 1048576
NumberDataPoints #21
Data point attributes:
     -> kong.shared_dict.name: Str(kong_vaults_hcv)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779453696 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779454208 +0000 UTC
Value: 1048576
NumberDataPoints #22
Data point attributes:
     -> kong.shared_dict.name: Str(kong_profiling_state)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.77944832 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779448832 +0000 UTC
Value: 1572864
NumberDataPoints #23
Data point attributes:
     -> kong.shared_dict.name: Str(kong_keyring)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779444736 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779445248 +0000 UTC
Value: 5242880
NumberDataPoints #24
Data point attributes:
     -> kong.shared_dict.name: Str(kong_reports_workspaces)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.77942912 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779429632 +0000 UTC
Value: 1048576
NumberDataPoints #25
Data point attributes:
     -> kong.shared_dict.name: Str(kong_reports_services)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.779421184 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779421696 +0000 UTC
Value: 1048576
NumberDataPoints #26
Data point attributes:
     -> kong.shared_dict.name: Str(kong_reports_routes)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.77941376 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779414272 +0000 UTC
Value: 1048576
NumberDataPoints #27
Data point attributes:
     -> kong.shared_dict.name: Str(kong_vitals_lists)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:37:15.77938304 +0000 UTC
Timestamp: 2025-12-12 10:37:15.779383808 +0000 UTC
Value: 1048576
Metric #9
Descriptor:
     -> Name: kong.memory.workers.lua_vm
     -> Description: Measures how much memory the worker Lua VM is using in bytes.
     -> Unit: By
     -> DataType: Gauge
NumberDataPoints #0
Data point attributes:
     -> kong.pid: Str(2732)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778701056 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151047168 +0000 UTC
Value: 67684407
NumberDataPoints #1
Data point attributes:
     -> kong.pid: Str(2733)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778712064 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151052032 +0000 UTC
Value: 66817031
NumberDataPoints #2
Data point attributes:
     -> kong.pid: Str(2734)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778722304 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151056384 +0000 UTC
Value: 66817707
NumberDataPoints #3
Data point attributes:
     -> kong.pid: Str(2735)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778732288 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151060992 +0000 UTC
Value: 66817031
NumberDataPoints #4
Data point attributes:
     -> kong.pid: Str(2736)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778741504 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151064064 +0000 UTC
Value: 66830855
NumberDataPoints #5
Data point attributes:
     -> kong.pid: Str(2737)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.77874944 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151066624 +0000 UTC
Value: 66817031
NumberDataPoints #6
Data point attributes:
     -> kong.pid: Str(2738)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778757632 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151069952 +0000 UTC
Value: 66817031
NumberDataPoints #7
Data point attributes:
     -> kong.pid: Str(2739)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778920704 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151072512 +0000 UTC
Value: 71818907
NumberDataPoints #8
Data point attributes:
     -> kong.pid: Str(2740)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.778948864 +0000 UTC
Timestamp: 2025-12-12 10:47:51.15107584 +0000 UTC
Value: 66817031
NumberDataPoints #9
Data point attributes:
     -> kong.pid: Str(2741)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.77909504 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151079168 +0000 UTC
Value: 76209463
NumberDataPoints #10
Data point attributes:
     -> kong.pid: Str(2742)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.77929472 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151081984 +0000 UTC
Value: 66817031
NumberDataPoints #11
Data point attributes:
     -> kong.pid: Str(2743)
     -> kong.subsystem: Str(http)
StartTimestamp: 2025-12-12 10:39:30.779652608 +0000 UTC
Timestamp: 2025-12-12 10:47:51.151085056 +0000 UTC
Value: 66817031
Metric #10
Descriptor:
     -> Name: kong.db.connection.status
     -> Description: Shows whether Kong could connect to the database. A value of 1 means able to connect. A value of 0 means not able to connect.
     -> Unit: 1
     -> DataType: Gauge
NumberDataPoints #0
StartTimestamp: 2025-12-12 10:39:30.777023488 +0000 UTC
Timestamp: 2025-12-12 10:47:51.150394112 +0000 UTC
Value: 1
Metric #11
Descriptor:
     -> Name: kong.ee.license.signature
     -> Description: Shows the last 8 bytes of the Enterprise license signature as a number.
     -> Unit: 1
     -> DataType: Gauge
NumberDataPoints #0
StartTimestamp: 2025-12-12 10:39:30.785728512 +0000 UTC
Timestamp: 2025-12-12 10:47:51.154936576 +0000 UTC
Value: 1000461175230928640
```
{:.no-copy-code}