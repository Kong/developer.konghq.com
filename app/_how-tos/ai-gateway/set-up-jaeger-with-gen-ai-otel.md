---
title: Set up Jaeger with Gen AI OpenTelemetry
permalink: /how-to/set-up-jaeger-with-gen-ai-otel/
content_type: how_to
related_resources:
  - text: Set up Dynatrace with OpenTelemetry
    url: /how-to/set-up-dynatrace-with-otel/
  - text: Validate Gen AI tool calls with Jaeger and OpenTelemetry
    url: /how-to/set-up-jaeger-with-gen-ai-otel-for-tool-calls/

description: Use the OpenTelemetry plugin to send {{site.base_gateway}} analytics and monitoring data to Jaeger dashboards.


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
    - dynatrace
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
    q: How do I send {{site.base_gateway}} traces to Jaeger?
    a: You can use the OpenTelemetry plugin with Jaeger to send [Gen AI analytics](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/#genai-attributes) and monitoring data to Jaeger dashboards. Set `KONG_TRACING_INSTRUMENTATIONS=all` and `KONG_TRACING_SAMPLING_RATE=1.0`. Enable the OTEL plugin with your Jaeger tracing endpoint, and specify the name you want to track the traces by in `resource_attributes.service.name`.

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

faqs:
  - q: What if I'm using an incompatible OpenTelemetry APM vendor? How do I configure the OTEL plugin then?
    a: |
      Create a config file (`otelcol.yaml`) for the OpenTelemetry Collector:

      ```yaml
      receivers:
        otlp:
          protocols:
            grpc:
            http:

      processors:
        batch:

      exporters:
        logging:
          loglevel: debug
        zipkin:
          endpoint: "http://some.url:9411/api/v2/spans"
          tls:
            insecure: true

      service:
        pipelines:
          traces:
            receivers: [otlp]
            processors: [batch]
            exporters: [logging, zipkin]
          logs:
            receivers: [otlp]
            processors: [batch]
            exporters: [logging]
      ```

      Run the OpenTelemetry Collector with Docker:

      ```bash
      docker run --name opentelemetry-collector \
        -p 4317:4317 \
        -p 4318:4318 \
        -p 55679:55679 \
        -v $(pwd)/otelcol.yaml:/etc/otel-collector-config.yaml \
        otel/opentelemetry-collector-contrib:0.52.0 \
        --config=/etc/otel-collector-config.yaml
      ```

      See the [OpenTelemetry Collector documentation](https://opentelemetry.io/docs/collector/configuration/) for more information. Now you can enable the OTEL plugin.


automated_tests: false
---
## Configure the AI Proxy plugin

The AI Proxy plugin routes LLM requests to external providers like OpenAI. To observe these interactions in detail, enable the plugin's logging capabilities, which instrument requests and responses as OpenTelemetry spans.

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
          name: gpt-4o
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

The OpenTelemetry plugin instruments {{site.base_gateway}} to export distributed traces. This allows you to observe request flows, measure latency, and inspect AI proxy operations including the prompts sent to LLMs and the responses received.

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

{% validation request-check %}
url: /anything
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    messages:
        - role: "system"
          content: "You are a historian"
        - role: "user"
          content: "Who was the last emperor of the Byzantine empire?"

{% endvalidation %}

## Validate `gen_ai` traces in Jaeger

Verify that the trace includes the expected span attributes for LLM operations.

1. Open the Jaeger UI at `http://localhost:16686/`.
1. In the **Service** dropdown, select `kong-dev`.
1. Click **Find Traces**.
1. Click a trace result for the `kong-dev` service.
1. In the trace detail view, locate and expand the span labeled `kong.access.plugin.ai-proxy`.
1. Locate and expand the child span labeled `kong.gen_ai`.
1. Verify the following span attributes are present:
   - `gen_ai.operation.name`: Set to `chat`
   - `gen_ai.provider.name`: Set to `openai`
   - `gen_ai.request.model`: The model identifier (for example, `gpt-4o`)
   - `gen_ai.request.max_tokens`: Maximum token limit (for example, `512`)
   - `gen_ai.request.temperature`: Sampling temperature (for example, `1`)
   - `gen_ai.input.messages`: Array of messages sent to the LLM with `role` and `content` fields
   - `gen_ai.output.type`: Set to `json`
   - `gen_ai.output.messages`: Complete API response including choices, usage statistics, and metadata
   - `gen_ai.response.id`
   - `gen_ai.response.model`: Actual model version used (for example, `gpt-4o-2024-08-06`)
   - `gen_ai.response.finish_reasons`: Array of finish reasons (for example, `["stop"]`)
   - `gen_ai.usage.input_tokens`
   - `gen_ai.usage.output_tokens`
