---
title: Collect metrics, logs, and traces with the OpenTelemetry plugin
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
      In this tutorial, we'll collect data in OpenTelemetry Collector. Use the following command to launch a Collector instance that listens on port 4318 and writes its output to a text file:

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
    a: You can use the OpenTelemetry plugin to send telemetry data to OpenTelemetry Collector. Set `KONG_TRACING_INSTRUMENTATIONS=all` and `KONG_TRACING_SAMPLING_RATE=1.0` for tracing. Enable the OTEL plugin with your OpenTelemetry Collector tracing, logging, and metrics endpoints, and specify the name you want to track the traces by in `resource_attributes.service.name`.

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

## Enable the OTEL plugin

In this tutorial, we'll be configuring the OpenTelemetry plugin to send {{site.base_gateway}} traces to Jaeger.

Enable the OTEL plugin with Jaeger settings configured:

{% entity_examples %}
entities:
  plugins:
  - name: opentelemetry
    config:
      traces_endpoint: "http://${otel-host}:4318/v1/traces"
      access_logs_endpoint: "http://${otel-host}:4318/v1/logs"
      logs_endpoint: "http://${otel-host}:4318/v1/traces"
      metrics:
        endpoint: "http://${otel-host}:4318/v1/traces"
      resource_attributes:
        service.name: "kong-dev"

variables:
  otel-host:
    value: $OTEL_HOST
{% endentity_examples %}

## Validate

Send a `POST` request to generate traffic that we can use to validate that OpenTelemetry Collector is receiving the traces:

{% validation request-check %}
url: /anything
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
{% endvalidation %}

You should see data in your OpenTelemetry Collector terminal. You can also search the output file:
```sh
grep "kong-dev" collector-output.txt
```
