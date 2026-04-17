---
title: "Proxy A2A agents through {{site.ai_gateway_name}}"
content_type: how_to
description: "Route Agent2Agent (A2A) protocol traffic through {{site.base_gateway}} with the AI A2A Proxy plugin"

products:
  - gateway
  - ai-gateway


works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.14'

plugins:
  - ai-a2a-proxy
  - opentelemetry

entities:
  - service
  - route
  - plugin

permalink: /how-to/proxy-a2a-agents/

tags:
  - ai
  - a2a

tldr:
  q: "How do I route A2A protocol traffic through {{site.ai_gateway}}?"
  a: "Create a service pointing to your A2A agent, add a route, and enable the AI A2A Proxy plugin. Kong proxies A2A JSON-RPC traffic and can export A2A metrics and payloads as OpenTelemetry span attributes."
tools:
  - deck

related_resources:
  - text: AI A2A Proxy plugin reference
    url: /plugins/ai-a2a-proxy/
  - text: A2A protocol specification
    url: https://a2a-protocol.org/latest/
  - text: Set up Jaeger with Gen AI OpenTelemetry
    url: /how-to/set-up-jaeger-with-gen-ai-otel/

prereqs:
  entities:
    services:
      - a2a-kongair-agent
    routes:
      - a2a-kongair-route
  gateway:
    - name: KONG_TRACING_INSTRUMENTATIONS
    - name: KONG_TRACING_SAMPLING_RATE
  konnect:
    - name: KONG_TRACING_INSTRUMENTATIONS
    - name: KONG_TRACING_SAMPLING_RATE
  inline:
  - title: OpenAI API key
    include_content: prereqs/openai
    icon_url: /assets/icons/openai.svg
  - title: Tracing environment variables
    position: before
    content: |
      Set the following OTel tracing variables before you configure the Data Plane:
      ```sh
      export KONG_TRACING_INSTRUMENTATIONS=all
      export KONG_TRACING_SAMPLING_RATE=1.0
      ```
  - title: OpenTelemetry Collector
    content: |
      In this tutorial, we'll collect data in OpenTelemetry Collector. Use the following command to launch a Collector instance with default configuration that listens on port 4318 and writes its output to a text file:

      ```sh
      docker run \
        --name otel-collector \
        -p 127.0.0.1:4319:4318 \
        otel/opentelemetry-collector:0.141.0 \
        2>&1 | tee collector-output.txt
      ```

      In a new terminal, export the OTEL Collector host. In this example, use the following host:
      ```sh
      export DECK_OTEL_HOST=host.docker.internal
      ```
    icon: assets/icons/opentelemetry.svg
  - title: A2A agent
    include_content: prereqs/a2a-kongair-agent
    icon_url: /assets/icons/ai.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    - title: Stop the A2A agent and OpenTelemetry Collector
      icon_url: /assets/icons/ai.svg
      content: |
        Stop and remove the sample A2A agent and OpenTelemetry Collector containers:

        ```sh
        docker compose down
        docker rm -f otel-collector
        ```

faqs:
  - q: What is the A2A protocol?
    a: |
      The Agent2Agent (A2A) protocol is an open standard originally developed by Google that
      defines how AI agents communicate with each other. It uses JSON-RPC over HTTP and supports
      capability discovery through Agent Cards, task lifecycle management, multi-turn conversations,
      and streaming responses. See the [A2A protocol documentation](https://a2a-protocol.org/latest/)
      for the full specification.
  - q: How is A2A different from MCP?
    a: |
      MCP (Model Context Protocol) standardizes how agents connect to tools, APIs, and data
      sources. A2A standardizes how agents communicate with other agents. They are complementary:
      use MCP for agent-to-tool communication and A2A for agent-to-agent communication.
  - q: Can I add authentication to the A2A endpoint?
    a: |
      Yes. Apply any {{site.base_gateway}} authentication plugin (Key Auth, OAuth2, JWT, etc.)
      to the same service or route. The AI A2A Proxy plugin handles A2A protocol concerns
      independently of authentication.

automated_tests: false
---

## Enable the AI A2A Proxy plugin

The AI A2A Proxy plugin parses A2A JSON-RPC requests and proxies them to the upstream agent.
With logging enabled, the plugin records A2A metrics and payloads as OpenTelemetry span
attributes.

{% entity_examples %}
entities:
  plugins:
    - name: ai-a2a-proxy
      config:
        max_request_body_size: 0
        logging:
          log_statistics: true
          log_payloads: true
{% endentity_examples %}

`log_statistics` adds A2A metrics to Kong log plugin output. `log_payloads` records request and response bodies, and requires `log_statistics` to be enabled. See the [AI A2A Proxy plugin reference](/plugins/ai-a2a-proxy/reference/) for all available parameters.

## Retrieve the Agent Card

A2A agents expose their capabilities through an Agent Card at the `/.well-known/agent-card.json` endpoint. Retrieve it through the gateway:

{% validation request-check %}
url: /a2a/.well-known/agent-card.json
status_code: 200
method: GET
{% endvalidation %}

You should see the following response:

```json
{"capabilities":{"pushNotifications":false,"streaming":false},"defaultInputModes":["text","text/plain"],"defaultOutputModes":["text","text/plain"],"description":"An A2A-compatible agent powered by LangGraph and OpenAI that queries KongAir APIs for flights, routes, bookings, and loyalty info.","name":"KongAir OpenAI Agent","preferredTransport":"JSONRPC","protocolVersion":"0.3.0","skills":[{"description":"Find KongAir routes between airports.","examples":["Show me routes from SFO to JFK","Find flights from LHR to SFO"],"id":"search_routes","name":"Search KongAir routes","tags":["kongair","flights","travel","routes"]},{"description":"Get available flights for a specific route.","examples":["What flights are available on route KA-123?"],"id":"get_flights","name":"Get flights","tags":["kongair","flights"]},{"description":"Look up a booking by ID.","examples":["Check booking BK-456"],"id":"check_booking","name":"Check booking","tags":["kongair","bookings"]},{"description":"Get loyalty program information for a customer.","examples":["What's my loyalty status for customer C-789?"],"id":"loyalty_info","name":"Loyalty program info","tags":["kongair","loyalty","rewards"]}],"url":"http://a2a-agent:10000/","version":"1.0.0"}
```
{:.no-copy-code}

## Enable the OpenTelemetry plugin

The OpenTelemetry plugin exports distributed traces for each A2A request to your Jaeger instance. Combined with the `logging` configuration on the AI A2A Proxy plugin, traces include A2A-specific span attributes.

{% entity_examples %}
entities:
  plugins:
    - name: opentelemetry
      config:
        traces_endpoint: http://${otel-host}:4319/v1/traces
        metrics:
          endpoint: http://${otel.host}:4319/v1/metrics
          enable_ai_metrics: true
        resource_attributes:
          service.name: kong-a2a
variables:
  otel-host:
    value: $OTEL_HOST
{% endentity_examples %}

The `traces_endpoint` points to the OpenTelemetry Collector's OTLP HTTP receiver on port 4318. The `service.name` attribute identifies this {{site.ai_gateway}} instance in the collector output.

## Send an A2A request

Send a `message/send` JSON-RPC request to the gateway route:

<!-- vale off -->
{% validation request-check %}
url: /a2a
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  jsonrpc: "2.0"
  id: "1"
  method: message/send
  params:
    message:
      kind: message
      messageId: msg-001
      role: user
      parts:
        - kind: text
          text: "Check booking BK-456"
{% endvalidation %}
<!-- vale on -->

{{site.base_gateway}} proxies the request to the A2A agent and returns the agent's JSON-RPC response. A successful response contains either a completed task with artifacts, or a task in `input-required` state if the agent needs more information.

## Validate traces

You should see data in your OpenTelemetry Collector terminal. You can also search for `kong-a2a` in the `collector-output.txt` output file. You should see the following data:

```
ResourceSpans #0
Resource SchemaURL:
Resource attributes:
     -> service.instance.id: Str(9c214152-1621-456a-8b42-6f1309dac551)
     -> service.name: Str(kong-a2a)
     -> service.version: Str(3.14.0.0)
ScopeSpans #0
ScopeSpans SchemaURL:
InstrumentationScope kong-internal 0.1.0
Span #0
    Trace ID       : 1bfc19e17dd9121769882cd9b8bf5de1
    Parent ID      :
    ID             : 779db508077de69f
    Name           : kong
    Kind           : Server
    Start time     : 2026-04-03 06:48:41.446000128 +0000 UTC
    End time       : 2026-04-03 06:48:47.139977728 +0000 UTC
    Status code    : Unset
    Status message :
Attributes:
     -> http.flavor: Str(1.1)
     -> http.route: Str(/a2a)
     -> http.url: Str(http://localhost/a2a)
     -> http.scheme: Str(http)
     -> http.client_ip: Str(192.168.65.1)
     -> http.method: Str(POST)
     -> net.peer.ip: Str(192.168.65.1)
     -> http.status_code: Int(200)
     -> http.host: Str(localhost)
     -> kong.request.id: Str(8221291c2cac1842d7c77118ca409e6a)
Span #1
    Trace ID       : 1bfc19e17dd9121769882cd9b8bf5de1
    Parent ID      : 779db508077de69f
    ID             : a3b699c33700feee
    Name           : kong.router
    Kind           : Internal
    Start time     : 2026-04-03 06:48:41.446752256 +0000 UTC
    End time       : 2026-04-03 06:48:41.44679424 +0000 UTC
    Status code    : Unset
    Status message :
Span #2
    Trace ID       : 1bfc19e17dd9121769882cd9b8bf5de1
    Parent ID      : 779db508077de69f
    ID             : de4e6ed2c16a2dd3
    Name           : kong.access.plugin.ai-a2a-proxy
    Kind           : Internal
    Start time     : 2026-04-03 06:48:41.446919936 +0000 UTC
    End time       : 2026-04-03 06:48:41.447105024 +0000 UTC
    Status code    : Unset
    Status message :
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
Span #4
    Trace ID       : 1bfc19e17dd9121769882cd9b8bf5de1
    Parent ID      : 779db508077de69f
    ID             : c1573adfe53ae258
    Name           : kong.access.plugin.opentelemetry
    Kind           : Internal
    Start time     : 2026-04-03 06:48:41.447129088 +0000 UTC
    End time       : 2026-04-03 06:48:41.447464448 +0000 UTC
    Status code    : Unset
    Status message :
Span #5
    Trace ID       : 1bfc19e17dd9121769882cd9b8bf5de1
    Parent ID      : 779db508077de69f
    ID             : 1c44c62490a4dc00
    Name           : kong.dns
    Kind           : Client
    Start time     : 2026-04-03 06:48:41.44754304 +0000 UTC
    End time       : 2026-04-03 06:48:41.447862272 +0000 UTC
    Status code    : Unset
    Status message :
Attributes:
     -> dns.record.port: Double(10000)
     -> dns.record.ip: Str(172.18.0.2)
     -> dns.record.domain: Str(a2a-kongair-agent)
Span #6
    Trace ID       : 1bfc19e17dd9121769882cd9b8bf5de1
    Parent ID      : 779db508077de69f
    ID             : 811a109d1908068d
    Name           : kong.header_filter.plugin.ai-a2a-proxy
    Kind           : Internal
    Start time     : 2026-04-03 06:48:47.139697664 +0000 UTC
    End time       : 2026-04-03 06:48:47.139731712 +0000 UTC
    Status code    : Unset
    Status message :
Span #7
    Trace ID       : 1bfc19e17dd9121769882cd9b8bf5de1
    Parent ID      : 779db508077de69f
    ID             : ff3f295f3b8cf464
    Name           : kong.header_filter.plugin.opentelemetry
    Kind           : Internal
    Start time     : 2026-04-03 06:48:47.139753728 +0000 UTC
    End time       : 2026-04-03 06:48:47.1397632 +0000 UTC
    Status code    : Unset
    Status message :
Span #8
    Trace ID       : 1bfc19e17dd9121769882cd9b8bf5de1
    Parent ID      : 779db508077de69f
    ID             : f8718c5342d3bc70
    Name           : kong.balancer
    Kind           : Client
    Start time     : 2026-04-03 06:48:41.447897088 +0000 UTC
    End time       : 2026-04-03 06:48:47.139977728 +0000 UTC
    Status code    : Unset
    Status message :
Attributes:
     -> net.peer.ip: Str(172.18.0.2)
     -> net.peer.port: Double(10000)
     -> net.peer.name: Str(a2a-kongair-agent)
     -> try_count: Double(1)
     -> peer.service: Str(a2a-kongair-agent)
```
{:.collapsible}

## Validate metrics

You should also see metrics data in the OpenTelemetry Collector output. Search for `kong.gen_ai.a2a` in the `collector-output.txt` file. You should see the following data:

```
ResourceMetrics #0
Resource SchemaURL:
Resource attributes:
     -> service.instance.id: Str(9c214152-1621-456a-8b42-6f1309dac551)
     -> service.name: Str(kong-a2a)
     -> service.version: Str(3.14.0.0)
ScopeMetrics #0
ScopeMetrics SchemaURL:
InstrumentationScope kong-internal 0.1.0
Metric #0
Descriptor:
     -> Name: kong.gen_ai.a2a.request.duration
     -> Description: Measures A2A request duration in seconds.
     -> Unit: s
     -> DataType: Histogram
     -> AggregationTemporality: Cumulative
HistogramDataPoints #0
Data point attributes:
     -> kong.service.name: Str(a2a-kongair-agent)
     -> kong.route.name: Str(a2a-kongair-route)
     -> kong.gen_ai.a2a.method: Str(message/send)
     -> kong.workspace.name: Str(default)
     -> kong.gen_ai.a2a.binding: Str(jsonrpc)
StartTimestamp: 2026-04-03 06:40:44.823196672 +0000 UTC
Timestamp: 2026-04-03 06:48:47.141009664 +0000 UTC
Count: 3
Sum: 20.365000
Min: 5.692000
Max: 8.950000
Metric #1
Descriptor:
     -> Name: kong.gen_ai.a2a.response.size
     -> Description: Measures A2A response body size in bytes.
     -> Unit: By
     -> DataType: Histogram
     -> AggregationTemporality: Cumulative
HistogramDataPoints #0
Data point attributes:
     -> kong.service.name: Str(a2a-kongair-agent)
     -> kong.route.name: Str(a2a-kongair-route)
     -> kong.gen_ai.a2a.method: Str(message/send)
     -> kong.workspace.name: Str(default)
     -> kong.gen_ai.a2a.binding: Str(jsonrpc)
StartTimestamp: 2026-04-03 06:40:44.823648 +0000 UTC
Timestamp: 2026-04-03 06:48:47.141217024 +0000 UTC
Count: 3
Sum: 3994.000000
Min: 1304.000000
Max: 1345.000000
Metric #2
Descriptor:
     -> Name: kong.gen_ai.a2a.request.count
     -> Description: Counts A2A requests.
     -> Unit: {request}
     -> DataType: Sum
     -> IsMonotonic: true
     -> AggregationTemporality: Cumulative
NumberDataPoints #0
Data point attributes:
     -> kong.service.name: Str(a2a-kongair-agent)
     -> kong.route.name: Str(a2a-kongair-route)
     -> kong.gen_ai.a2a.method: Str(message/send)
     -> kong.workspace.name: Str(default)
     -> kong.gen_ai.a2a.binding: Str(jsonrpc)
StartTimestamp: 2026-04-03 06:40:44.822096128 +0000 UTC
Timestamp: 2026-04-03 06:48:47.14095616 +0000 UTC
Value: 3
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
     -> kong.workspace.name: Str(default)
     -> kong.service.name: Str(a2a-kongair-agent)
     -> kong.route.name: Str(a2a-kongair-route)
     -> kong.gen_ai.a2a.task.state: Str(completed)
StartTimestamp: 2026-04-03 06:40:44.824023552 +0000 UTC
Timestamp: 2026-04-03 06:48:47.141275648 +0000 UTC
Value: 3
```
{:.collapsible}