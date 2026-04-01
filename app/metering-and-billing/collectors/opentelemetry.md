---
title: "OpenTelemetry Collector"
content_type: reference
description: "Learn how to use the OpenTelemetry collector to meter usage from logs in {{site.konnect_short_name}} {{site.metering_and_billing}}."
layout: reference
products:
  - metering-and-billing
tools:
    - konnect-api
works_on:
  - konnect
breadcrumbs:
  - /metering-and-billing/
  - /metering-and-billing/collectors/
related_resources:
  - text: "{{site.konnect_short_name}} {{site.metering_and_billing}}"
    url: /metering-and-billing/
  - text: "Collectors"
    url: /metering-and-billing/collectors/
---

Non-sampled logs (for example, access logs) are excellent sources of usage information. Combined with the [OpenTelemetry](https://opentelemetry.io) open standard for log forwarding, you can extract usage information from your logs and forward them to {{site.metering_and_billing}}.

## Prerequisites

You will need an OpenTelemetry-compatible log-forwarding solution. You can get started with the [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/).

## Configuration

First, create a new YAML file for the collector configuration. Use the `otel_log` Redpanda Connect input:

```yaml
input:
  otel_log:
    # Point your log forwarder to this address using the OTLP gRPC protocol.
    address: 127.0.0.1:4317
```

{:.info}
> **Note:** This is a custom input plugin that is not part of the official Redpanda Connect distribution. You can find the source code of the plugin on [GitHub](https://github.com/openmeterio/openmeter/blob/main/collector/benthos/input/otel_log.go).

Next, configure the mapping from your log schema to [CloudEvents](https://cloudevents.io) using [bloblang](https://docs.redpanda.com/redpanda-connect/guides/bloblang/about):

```yaml
pipeline:
  processors:
    - mapping: |
        root = {
          "id": uuid_v4(),
          "specversion": "1.0",
          "type": "api-calls",
          "source": "otlp-log",
          "time": this.record.attributes.time,
          "subject": this.record.attributes.subject,
          "data": {
            "method": this.record.attributes.method,
            "path": this.record.attributes.path,
            "region": this.record.attributes.region,
            "zone": this.record.attributes.zone,
            "duration_ms": this.record.attributes.duration,
          },
        }
```

{:.info}
> **About log attributes:** `this.record.attributes` contains the log attributes extracted by the `otel_log` input plugin.

Finally, configure the output:

```yaml
output:
  label: 'openmeter'
  drop_on:
    error: false
    error_patterns:
      - Bad Request
  output:
    http_client:
      url: '${OPENMETER_URL:https://us.api.konghq.com}/v3/openmeter/events'
      verb: POST
      headers:
        Authorization: 'Bearer $KONNECT_SYSTEM_ACCESS_TOKEN'
        Content-Type: 'application/json'
      timeout: 30s
      retry_period: 15s
      retries: 3
      max_retry_backoff: 1m
      max_in_flight: 64
      batch_as_multipart: false
      drop_on:
        - 400
      batching:
        count: 100
        period: 1s
        processors:
          - metric:
              type: counter
              name: openmeter_events_sent
              value: 1
          - archive:
              format: json_array
      dump_request_log_level: DEBUG
```

Replace `$KONNECT_SYSTEM_ACCESS_TOKEN` with your own [system access token](/konnect-api/#system-accounts-and-access-tokens).

## Example use case

A fully working example is available on [GitHub](https://github.com/openmeterio/openmeter/tree/main/examples/collectors/otel-log).

## Installation

{% include /konnect/metering-and-billing/collector-install.md %}
