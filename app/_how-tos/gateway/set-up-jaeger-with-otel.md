---
title: Set up Jaeger with OpenTelemetry
permalink: /how-to/set-up-jaeger-with-otel/
content_type: how_to
related_resources:
  - text: Set up Dynatrace with OpenTelemetry
    url: /how-to/set-up-dynatrace-with-otel/

description: Use the OpenTelemetry plugin to send {{site.base_gateway}} analytics and monitoring data to Jaeger dashboards.


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

plugins:
  - opentelemetry

entities: 
  - service
  - route
  - plugin

tags:
    - analytics
    - monitoring
    - dynatrace

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
    a: You can use the OpenTelemetry plugin with Jaeger to send analytics and monitoring data to Jaeger dashboards. Set `KONG_TRACING_INSTRUMENTATIONS=all` and `KONG_TRACING_SAMPLING_RATE=1.0`. Enable the OTEL plugin with your Jaeger tracing endpoint, and specify the name you want to track the traces by in `resource_attributes.service.name`.

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

## Enable the OTEL plugin

In this tutorial, we'll be configuring the OpenTelemetry plugin to send {{site.base_gateway}} traces to Jaeger.

Enable the OTEL plugin with Jaeger settings configured:

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

For more information about the ports Jaeger uses, see [API Ports](https://www.jaegertracing.io/docs/2.5/apis/) in the Jaeger documentation.

## Validate

Send a `POST` request to generate traffic that we can use to validate that Jaeger is receiving the traces:

{% validation request-check %}
url: /anything
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
{% endvalidation %}

In the [Jaeger UI](http://localhost:16686/), search for `kong-dev` in Service and click **Find Traces**. You should see a trace for the request you just sent. Sometimes it can take a few seconds to display.