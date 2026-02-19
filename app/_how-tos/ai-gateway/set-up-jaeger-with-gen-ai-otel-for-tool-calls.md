---
title: Validate Gen AI tool calls with Jaeger and OpenTelemetry
permalink: /how-to/set-up-jaeger-with-gen-ai-otel-for-tool-calls/
content_type: how_to
related_resources:
  - text: Set up Jaeger with Gen AI OpenTelemetry
    url: /how-to/set-up-jaeger-with-otel/
  - text: Set up Dynatrace with OpenTelemetry
    url: /how-to/set-up-dynatrace-with-otel/

description: Use the OpenTelemetry plugin to capture and validate LLM tool call attributes in Jaeger dashboards when using function calling with AI providers.

products:
  - ai-gateway
  - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.13'

plugins:
  - opentelemetry
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
    - analytics
    - monitoring
    - ai
    - openai

tech_preview: true

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  gateway:
    - name: KONG_TRACING_INSTRUMENTATIONS
    - name: KONG_TRACING_SAMPLING_RATE
  konnect:
    - name: KONG_TRACING_INSTRUMENTATIONS
    - name: KONG_TRACING_SAMPLING_RATE
  inline:
  - title: OpenAI
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
    content: |
      This tutorial requires you to install [Jaeger](https://www.jaegertracing.io/docs/2.5/getting-started/).

      In a new terminal window, deploy a Jaeger instance with Docker in `all-in-one` mode:
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
    icon_url: /assets/icons/third-party/jaeger.svg

tldr:
    q: How do I validate LLM tool call attributes in Jaeger traces?
    a: Configure the AI Proxy plugin with `logging.log_statistics` and `logging.log_payloads` enabled. Enable the OpenTelemetry plugin pointing to your Jaeger endpoint. Send requests with tool definitions to your AI provider. Jaeger traces will include `gen_ai.tool.*` attributes such as `gen_ai.tool.name`, `gen_ai.tool.type`, and `gen_ai.tool.call.id` when the LLM responds with tool calls.

tools:
    - deck

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
## Configure the AI Proxy plugin

The AI Proxy plugin routes LLM requests to external providers like OpenAI. To observe tool call interactions in detail, enable the plugin's logging capabilities, which instrument requests and responses as OpenTelemetry spans.

Configure AI Proxy to route traffic to OpenAI and enable trace logging:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_api_key}
        model:
          provider: openai
          name: gpt-5-mini
          options:
            max_tokens: 512
            temperature: 1.0
        logging:
          log_statistics: true
          log_payloads: true
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

The `logging` configuration controls what the AI Proxy plugin records:
- `log_statistics`: Captures token usage, latency, and model metadata
- `log_payloads`: Records the complete request prompts and LLM responses

These logs become OpenTelemetry span attributes when the OpenTelemetry plugin is enabled.

## Enable the OpenTelemetry plugin

The OpenTelemetry plugin instruments {{site.base_gateway}} to export distributed traces. This allows you to observe request flows, measure latency, and inspect AI proxy operations including tool call requests and responses.

Configure the plugin to send traces to your Jaeger collector:

{% entity_examples %}
entities:
  plugins:
  - name: opentelemetry
    config:
      traces_endpoint: "http://${jaeger-host}:4318/v1/traces"
      resource_attributes:
        service.name: "kong-dev"

variables:
  jaeger-host:
    value: $JAEGER_HOST
{% endentity_examples %}

The `traces_endpoint` points to Jaeger's OTLP HTTP receiver on port 4318. The `service.name` attribute identifies this {{site.base_gateway}} instance in the Jaeger UI, allowing you to filter traces by service.

For more information about the ports Jaeger uses, see [API Ports](https://www.jaegertracing.io/docs/2.5/apis/) in the Jaeger documentation.

## Validate

Send a request that includes a tool definition. The LLM will respond with a tool call if it determines the user's query requires function execution.

<!-- vale off -->
{% validation request-check %}
url: /anything
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    model: gpt-5-mini
    stream: false
    tools:
        - type: function
          function:
            name: get_temperature
            description: Get the current temperature for a city
            parameters:
                type: object
                required:
                    - city
                properties:
                    city:
                        type: string
                        description: The name of the city
    messages:
        - role: user
          content: What is the temperature in New York?
{% endvalidation %}
<!-- vale on -->

## Validate `gen_ai.tool` attributes in Jaeger

Verify that the trace includes the expected span attributes for LLM tool call operations.

1. Open the Jaeger UI at `http://localhost:16686/`.
1. In the **Service** dropdown, select `kong-dev`.
1. Click **Find Traces**.
1. Click a trace result for the `kong-dev` service.
1. In the trace detail view, locate and expand the span labeled `kong.access.plugin.ai-proxy`.
1. Locate and expand the child span labeled `kong.gen_ai`.
1. Verify the following span attributes are present:
   - `gen_ai.operation.name`: Set to `chat`
   - `gen_ai.provider.name`: Set to `openai`
   - `gen_ai.request.model`: The model identifier (for example, `gpt-5-mini`)
   - `gen_ai.request.max_tokens`: Maximum token limit (for example, `512`)
   - `gen_ai.request.temperature`: Sampling temperature (for example, `1`)
   - `gen_ai.response.finish_reasons`: Array containing `["tool_calls"]` when the LLM responds with a tool call
   - `gen_ai.response.id`: Unique identifier for the API response
   - `gen_ai.response.model`: Actual model version used (for example, `gpt-5-mini-2025-08-07`)
   - `gen_ai.tool.call.id`: Unique identifier for the specific tool call (for example, `call_KsEYAR17QngwYlWmNY5Q3K7D`)
   - `gen_ai.tool.name`: Name of the function the LLM wants to call (for example, `get_temperature`)
   - `gen_ai.tool.type`: Set to `function`
   - `gen_ai.usage.input_tokens`: Token count for the request
   - `gen_ai.usage.output_tokens`: Token count for the response
   - `gen_ai.output.type`: Set to `json`

The presence of `gen_ai.tool.*` attributes indicates the LLM determined a tool call was needed to answer the user's query. The `gen_ai.response.finish_reasons` array will contain `tool_calls` instead of `stop` when function calling is triggered.