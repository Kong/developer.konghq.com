---
title: Protect an unreliable upstream with the Circuit Breaker plugin
permalink: /how-to/protect-an-upstream-with-circuit-breaker/
content_type: how_to
description: Learn how to use the Circuit Breaker plugin to stop requests to a failing upstream, let the upstream recover, and export circuit breaker metrics with the OpenTelemetry plugin.

related_resources:
  - text: Circuit Breaker plugin
    url: /plugins/kong-circuit-breaker/
  - text: Health checks and circuit breakers
    url: /gateway/traffic-control/health-checks-circuit-breakers/
  - text: OpenTelemetry plugin
    url: /plugins/opentelemetry/
  - text: Collect metrics, logs, and traces with the OpenTelemetry plugin
    url: /how-to/collect-metrics-logs-and-traces-with-opentelemetry/

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.17'

plugins:
  - kong-circuit-breaker
  - opentelemetry

entities:
  - service
  - route
  - plugin

tags:
  - traffic-control
  - monitoring

search_aliases:
  - circuit breaker
  - fail fast
  - otel

tldr:
  q: How do I stop sending requests to a failing upstream and monitor the circuit?
  a: |
    1. Enable the [Circuit Breaker plugin](/plugins/kong-circuit-breaker/) on the [Service](/gateway/entities/service/), with `config.policy_circuit.enabled` set to `true` and a failure threshold in `config.policy_circuit.max_failures`.
    1. Enable the [OpenTelemetry plugin](/plugins/opentelemetry/) with `metrics.endpoint` to export the circuit breaker metrics.
    1. Send failing requests to open the circuit, and a healthy request after the recovery period to close it.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-clean-service
    routes:
        - example-clean-route
  inline:
    - title: OpenTelemetry Collector
      include_content: prereqs/otel-collector
      icon_url: /assets/icons/opentelemetry.svg

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

## Enable the Circuit Breaker plugin

A circuit stops requests to a failing upstream, so clients get a timely error and the upstream can recover.
The [Circuit Breaker plugin](/plugins/kong-circuit-breaker/) counts failures on a Service, and after a threshold, opens a circuit that rejects requests until the upstream is ready for traffic again.

Enable the plugin on the Service:

{% entity_examples %}
entities:
  plugins:
    - name: kong-circuit-breaker
      service: example-clean-service
      config:
        policy_circuit:
          enabled: true
          max_failures: 3
          sampling_window_seconds: 60
          recovery_period_ms: 15000
        half_open_calls: 1
{% endentity_examples %}

This configuration example uses low thresholds so that you can open the circuit quickly:
* `policy_circuit.max_failures`: The circuit opens after 3 failures in the sampling window.
* `policy_circuit.sampling_window_seconds`: The plugin counts failures over 60 seconds.
* `policy_circuit.recovery_period_ms`: The circuit stays open for 15 seconds before the next request can probe the upstream.
* `half_open_calls`: The plugin admits one probe request after the recovery period.

## Export circuit breaker metrics with OpenTelemetry

While a circuit is open, clients receive a `503` response.
By default, that response reads `The upstream server is currently unavailable`, the same message that {{site.base_gateway}} returns when an upstream is down.
A client sees the same response whether the circuit rejected the request or the upstream failed.

The Circuit Breaker plugin records metrics in {{site.base_gateway}}'s metrics registry.
Use the [OpenTelemetry plugin](/plugins/opentelemetry/) to export them to an OpenTelemetry backend.
In this guide, the backend is the OpenTelemetry Collector that you started in the prerequisites.

Enable the OpenTelemetry plugin with a `metrics.endpoint`.
The `push_interval` is short, so that metrics appear within seconds:

{% entity_examples %}
entities:
  plugins:
    - name: opentelemetry
      config:
        metrics:
          endpoint: "http://${otel-host}:4318/v1/metrics"
          push_interval: 5

variables:
  otel-host:
    value: $OTEL_HOST
{% endentity_examples %}

## Open the circuit

The Service points at `httpbin.konghq.com`, which returns the status code that you put in the request path.
The Route strips `/anything` from the path, so a request to `/anything/status/500` reaches the upstream as `/status/500` and gets a `500` response.

Send requests that make the upstream fail.
The first three requests reach the upstream, which returns a `500` response each time.
Each response counts as a failure:

{% validation request-check %}
url: '/anything/status/500'
status_code: 500
count: 3
display_headers: true
{% endvalidation %}

After the third failure, the circuit opens.

## Validate

Let's check that the circuit is rejecting requests correctly.

Send another request to `/anything/status/500`.
{{site.base_gateway}} rejects it with a `503` response before it reaches the upstream:

{% validation request-check %}
url: '/anything/status/500'
status_code: 503
display_headers: true
{% endvalidation %}

The circuit is open for the entire Service, so a request to a healthy path is also rejected until the circuit recovers:

{% validation request-check %}
url: '/anything/status/200'
status_code: 503
display_headers: true
{% endvalidation %}

### Let the circuit recover

Wait at least 15 seconds for the recovery period to end, then send a request to the healthy path.
This request becomes the probe, which reaches the upstream and succeeds, so the circuit closes:

{% validation request-check %}
url: '/anything/status/200'
status_code: 200
display_headers: true
sleep: 15
{% endvalidation %}

Send one more request. The circuit is now closed, so {{site.base_gateway}} proxies it to the upstream:

{% validation request-check %}
url: '/anything/status/200'
status_code: 200
display_headers: true
{% endvalidation %}

### View metrics

The requests that you sent opened a circuit, rejected two requests, and closed the circuit again.
Wait a few seconds for the next metrics push, then list the circuit breaker metrics in the Collector output:

{% validation custom-command %}
command: |
  docker logs otel-collector 2>&1 | grep 'Name: kong.circuit_breaker' | sort -u
expected:
  return_code: 0
render_output: false
{% endvalidation %}

You should see the following metrics:

```sh
     -> Name: kong.circuit_breaker.open
     -> Name: kong.circuit_breaker.policy.failure
     -> Name: kong.circuit_breaker.recovery
     -> Name: kong.circuit_breaker.request.rejected
     -> Name: kong.circuit_breaker.state
```
{:.no-copy-code}

The Collector writes a new block of metrics on every push. Counters are cumulative.
Look at the most recent block in the Collector logs to see the totals for the requests.

For example, the `kong.circuit_breaker.policy.failure` counter looks like this:

```sh
     -> Name: kong.circuit_breaker.policy.failure
     -> Description: Requests that counted as a policy failure.
     -> Unit: {request}
     -> DataType: Sum
     -> IsMonotonic: true
     -> AggregationTemporality: Cumulative
NumberDataPoints #0
Data point attributes:
     -> kong.service.name: Str(example-clean-service)
     -> kong.plugin.id: Str(2f4b6ea2-0060-4a41-9770-caf23711e1bc)
     -> kong.circuit_breaker.circuit: Str(policy)
Value: 3
```
{:.no-copy-code}

In production, these metrics let you:
* Confirm that the circuit opened because the upstream is failing.
* See how long the circuit stays open and how often it reopens.
* Find a threshold that is too low for your normal traffic, so that the circuit rejects requests to a healthy upstream.
* Verify that the circuit recovered.

When the latency circuit is enabled, you'll also see the `kong.circuit_breaker.latency.violation` metric.
The plugin also writes a log entry on every state transition. See [Logs](/plugins/kong-circuit-breaker/#logs) for all of the fields.
