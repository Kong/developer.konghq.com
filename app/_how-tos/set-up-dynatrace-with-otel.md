---
title: Set up Dynatrace with OpenTelemetry
content_type: how_to
related_resources:
  - text: Kong Premium Partners
    url: /premium-partners/

breadcrumbs:
  - /premium-partners/

act_as_plugin: true
name: Dynatrace
publisher: dynatrace
premium_partner: true
icon: /assets/icons/third-party/dynatrace.png
categories:
  - analytics-monitoring

description: Use Dynatrace's OpenTelemetry Collector to send analytics and monitoring data to Dynatrace dashboards.


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
    - plugins
    - partnership

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
  - title: Dynatrace
    content: |
      This tutorial requires you to have a Dynatrace SaaS account.

      In Dynatrace, find your [environment ID](https://docs.dynatrace.com/docs/discover-dynatrace/get-started/monitoring-environment#environment-id) and [generate an API token](https://docs.dynatrace.com/docs/discover-dynatrace/references/dynatrace-api/basics/dynatrace-api-authentication#create-token).

      Export those values as environment variables:
      ```sh
      export DYNATRACE_ENVRIONMENT_ID=<environment-id-here>
      export DYNATRACE_API_TOKEN=<token-here>
      ```
    icon_url: /assets/icons/third-party/dynatrace.svg

tldr:
    q: How do I send {{site.base_gateway}} traces, metrics, and logs to Dynatrace?
    a: You can use the OpenTelemetry plugin with Dynatrace's OpenTelemetry Collector to send analytics and monitoring data to Dynatrace dashboards.

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

---

## 1. Set env var

Set the following required {{site.base_gateway}} configuration that's required for Dynatrace:

```sh
export KONG_TRACING_INSTRUMENTATIONS=all
export KONG_TRACING_SAMPLING_RATE=1.0
```

## Dynatrace Collector

Make a `otel-collector-config.yaml` file with the following configuration:

```yaml
receivers:
 otlp:
   protocols:
     http:
       endpoint: 0.0.0.0:4318

exporters:
 otlphttp:
   endpoint: "https://{your-environment-id}.live.dynatrace.com/api/v2/otlp"
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

Validate your configuration file:
```sh
docker run -v $(pwd):$(pwd) -w $(pwd) ghcr.io/dynatrace/dynatrace-otel-collector/dynatrace-otel-collector:0.26.0 validate --config=$(pwd)/otel-collector-config.yaml
```

Create the Dynatrace Collector in a Docker container:
```
docker run -v $(pwd)/otel-collector-config.yaml:/etc/otelcol/otel-collector-config.yaml ghcr.io/dynatrace/dynatrace-otel-collector/dynatrace-otel-collector:0.26.0 --config=/etc/otelcol/otel-collector-config.yaml
```

## Enable the OTEL plugin

Enable the OTEL plugin with Dynatrace settings configured:

{% entity_examples %}
entities:
    plugins:
    - name: opentelemetry
      config:
        traces_endpoint: "https://${dynatrace_environment_id}.live.dynatrace.com/api/v2/otlp/v1/traces"
        logs_endpoint: "https://${dynatrace_environment_id}.live.dynatrace.com/api/v2/otlp/v1/logs"
        resource_attribute:
          service.name: kong-dev

variables:
  dynatrace_environment_id:
    value: $DYNATRACE_ENVRIONMENT_ID
{% endentity_examples %}

## Validate

Sent a `POST` request to generate traffic that we can use to validate that Dynatrace is receiving the traces:

{% validation request-check %}
url: /anything
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
{% endvalidation %}

for _ in {1..6}; do
  curl -i http://localhost:8000/anything
  echo
done

In Dynatrace, look for the traces.
