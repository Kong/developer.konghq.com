---
title: Set up Dynatrace with OpenTelemetry
permalink: /how-to/set-up-dynatrace-with-otel/
content_type: how_to
related_resources:
  - text: Kong Premium Partners
    url: /premium-partners/
  - text: "{{site.konnect_catalog}} Dynatrace integration reference"
    url: /catalog/integrations/dynatrace/
  - text: "Monitor Dynatrace SLOs {{site.konnect_catalog}} with the {{site.konnect_short_name}} UI"
    url: /how-to/monitor-dynatrace-slos-with-konnect-ui/
  - text: "Monitor Dynatrace SLOs {{site.konnect_catalog}} with the {{site.konnect_short_name}} API"
    url: /how-to/monitor-dynatrace-slos-with-konnect-api/

breadcrumbs:
  - /premium-partners/

premium_partner: true

description: Use Dynatrace SaaS to send analytics and monitoring data to Dynatrace dashboards.


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.8'

plugins:
  - opentelemetry

entities: 
  - service
  - route
  - plugin

tags:
    - analytics
    - monitoring
    - premium
    - partnership

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
      Set the following Dynatrace tracing variables before you configure the Data Plane:
      ```sh
      export KONG_TRACING_INSTRUMENTATIONS=all
      export KONG_TRACING_SAMPLING_RATE=1.0
      ```
  - title: Dynatrace
    content: |
      This tutorial requires you to have a [Dynatrace](https://www.dynatrace.com/) SaaS account.

      1. In Dynatrace, find your [environment ID](https://docs.dynatrace.com/docs/discover-dynatrace/get-started/monitoring-environment#environment-id).
      1. [Generate an API token](https://docs.dynatrace.com/docs/discover-dynatrace/references/dynatrace-api/basics/dynatrace-api-authentication#create-token) with the `openTelemetryTrace.ingest` and `metrics.ingest` scopes.

      Export those values as environment variables:
      ```sh
      export DECK_DYNATRACE_ENVIRONMENT_ID='ENVIRONMENT-ID-HERE'
      export DECK_DYNATRACE_API_TOKEN='TOKEN-HERE'
      ```
    icon_url: /assets/icons/third-party/dynatrace.png

tldr:
    q: How do I send {{site.base_gateway}} traces, metrics, and logs to Dynatrace?
    a: You can use the OpenTelemetry plugin with Dynatrace SaaS to send analytics and monitoring data to Dynatrace dashboards. Set `KONG_TRACING_INSTRUMENTATIONS=all` and `KONG_TRACING_SAMPLING_RATE=1.0`. Enable the OTEL plugin with your Dynatrace tracing and log endpoint, specify the name you want to track the traces by in `resource_attributes.service.name`, and add the Dynatrace API token as an Authorization header.

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
  - q: How do I export application span metrics?
    a: |
      {{site.base_gateway}} relies on the OpenTelemetry Collector to calculate the metrics based on the traces the OpenTelemetry plugin generates.

      To include span metrics for application traces, configure the collector exporters section of the OpenTelemetry Collector configuration file:

      ```yaml
      connectors:
      spanmetrics:
        dimensions:
          - name: http.method
            default: GET
          - name: http.status_code
          - name: http.route
        exclude_dimensions:
          - status.code
        metrics_flush_interval: 15s
        histogram:
          disable: false

      service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: []
          exporters: [spanmetrics]
        metrics:
          receivers: [spanmetrics]
          processors: []
          exporters: [otlphttp]
      ```
  - q: I want to use the Dynatrace Collector between {{site.base_gateway}} and Dynatrace, how do I configure that?
    a: |
      Make an `otel-collector-config.yaml` file with the following configuration:

      ```yaml
      receivers:
        otlp:
          protocols:
            http:
              endpoint: 0.0.0.0:4318

      exporters:
        otlphttp:
          endpoint: "https://{yourEnvironmentId}.live.dynatrace.com/api/v2/otlp"
          headers: 
            "Authorization": "Api-Token <your-api-token>"

      service:
        pipelines:
          traces:
            receivers: [otlp]
            processors: []
            exporters: [otlphttp]
          logs:
            receivers: [otlp]
            processors: []
            exporters: [otlphttp]
      ```
  - q: I'm getting a `200 OK` when I make requests, but nothing is showing up in Dynatrace, how do I fix this?
    a: Make sure your API token in Dynatrace has the `openTelemetryTrace.ingest` and `metrics.ingest` scopes. Sometimes it can take a few minutes for the traces to display in Dynatrace.
  - q: "I'm getting a `Missing authorization parameter., context: ngx.timer` in {{site.base_gateway}} logs when I send a request after configuring the OpenTelemetry plugin with Dynatrace, how do I fix this?"
    a: This error is because you need to add the [Dynatrace API token as an Authorization header](https://docs.dynatrace.com/docs/ingest-from/opentelemetry/getting-started/otlp-export#authentication-export-to-activegate) when you configure the OpenTelemetry plugin. 


automated_tests: false
---

## Enable the OTEL plugin

In this tutorial, we'll be configuring the OpenTelemetry plugin to send {{site.base_gateway}} traces and logs to Dynatrace SaaS. This configuration is good for testing purposes, but we recommend using a collector, like [Dynatrace Collector](https://docs.dynatrace.com/docs/ingest-from/opentelemetry/collector), in production environments.

Enable the OTEL plugin with Dynatrace settings configured:

{% entity_examples %}
entities:
  plugins:
  - name: opentelemetry
    config:
      traces_endpoint: "https://${dynatrace_environment_id}.live.dynatrace.com/api/v2/otlp/v1/traces"
      logs_endpoint: "https://${dynatrace_environment_id}.live.dynatrace.com/api/v2/otlp/v1/logs"
      resource_attributes:
        service.name: "kong-dev"
      headers:
        Authorization: Api-Token ${dynatrace_api_token}

variables:
  dynatrace_environment_id:
    value: $DYNATRACE_ENVIRONMENT_ID
  dynatrace_api_token:
    value: $DYNATRACE_API_TOKEN
{% endentity_examples %}

## Validate

Send a `POST` request to generate traffic that we can use to validate that Dynatrace is receiving the traces:

{% validation request-check %}
url: /anything
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
{% endvalidation %}

In the Dynatrace UI, navigate to Distributed Traces and search for `Service name` of `kong-dev`. You should see a trace for the request you just sent. Sometimes it can take a few seconds to display.