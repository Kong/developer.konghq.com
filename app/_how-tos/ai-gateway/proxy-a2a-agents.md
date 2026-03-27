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
      - a2a-currency-agent
    routes:
      - a2a-route
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
      Set the following Jaeger tracing variables before you configure the Data Plane:
      ```sh
      export KONG_TRACING_INSTRUMENTATIONS=all
      export KONG_TRACING_SAMPLING_RATE=1.0
      ```
  - title: Jaeger
    icon_url: /assets/icons/third-party/jaeger.svg
    content: |
      Deploy a Jaeger instance with Docker in `all-in-one` mode:

      ```sh
      docker run --rm --name jaeger \
        -e COLLECTOR_OTLP_ENABLED=true \
        -p 16686:16686 \
        -p 4317:4317 \
        -p 4318:4318 \
        -p 5778:5778 \
        -p 9411:9411 \
        jaegertracing/jaeger:2.5.0
      ```

      The `COLLECTOR_OTLP_ENABLED` environment variable must be set to `true` to enable the OpenTelemetry Collector.

      In this tutorial, we're using `host.docker.internal` as our host instead of the `localhost` that Jaeger is using because {{site.base_gateway}} is running in a container that has a different `localhost` to you. Export the host as an environment variable in the terminal window you used to set the other {{site.base_gateway}} environment variables:
      ```sh
      export DECK_JAEGER_HOST=host.docker.internal
      ```
  - title: A2A agent
    include_content: prereqs/a2a-agent
    icon_url: /assets/icons/ai.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    - title: Stop the A2A agent and Jaeger
      icon_url: /assets/icons/ai.svg
      content: |
        Stop and remove the sample A2A agent container:

        ```sh
        docker compose down
        docker rm -f jaeger
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
{"capabilities":{"pushNotifications":true,"streaming":true},"defaultInputModes":["text","text/plain"],"defaultOutputModes":["text","text/plain"],"description":"Helps with exchange rates for currencies","name":"Currency Agent","preferredTransport":"JSONRPC","protocolVersion":"0.3.0","skills":[{"description":"Helps with exchange values between various currencies","examples":["What is exchange rate between USD and GBP?"],"id":"convert_currency","name":"Currency Exchange Rates Tool","tags":["currency conversion","currency exchange"]}],"url":"http://0.0.0.0:10000/","version":"1.0.0"}%
```
{:.no-copy-code}

## Enable the OpenTelemetry plugin

The OpenTelemetry plugin exports distributed traces for each A2A request to your Jaeger instance. Combined with the `logging` configuration on the AI A2A Proxy plugin, traces include A2A-specific span attributes.

{% entity_examples %}
entities:
  plugins:
    - name: opentelemetry
      config:
        traces_endpoint: "http://${jaeger-host}:4318/v1/traces"
        resource_attributes:
          service.name: kong-a2a
variables:
  jaeger-host:
    value: $JAEGER_HOST
{% endentity_examples %}

The `traces_endpoint` points to Jaeger's OTLP HTTP receiver on port 4318. The `service.name` attribute identifies this {{site.ai_gateway}} instance in the Jaeger UI.

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
          text: "How much is 100 USD in EUR?"
{% endvalidation %}
<!-- vale on -->

The gateway proxies the request to the A2A agent and returns the agent's JSON-RPC response. A successful response contains either a completed task with artifacts, or a task in `input-required` state if the agent needs more information.

## Validate traces in Jaeger

1. Open the Jaeger UI at `http://localhost:16686/`.
2. In the **Service** dropdown, select `kong-a2a`.
3. Click **Find Traces**.
4. Click a trace result. The trace includes the following spans:
   * `kong.access.plugin.ai-a2a-proxy` with a child span `kong.a2a` containing A2A-specific attributes
   * `kong.access.plugin.opentelemetry`
   * `kong.dns` for upstream DNS resolution
   * `kong.balancer` showing the request forwarded to the A2A agent
   * `kong.header_filter.plugin.ai-a2a-proxy` and `kong.header_filter.plugin.opentelemetry` for response processing