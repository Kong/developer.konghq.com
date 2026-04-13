---
title: "Events"
content_type: reference
description: "Learn how events work in {{site.konnect_short_name}} {{site.metering_and_billing}}."
layout: reference
products:
  - metering-and-billing
tools:
    - konnect-api
works_on:
  - konnect
breadcrumbs:
  - /metering-and-billing/
related_resources:
  - text: "{{site.konnect_short_name}} {{site.metering_and_billing}}"
    url: /metering-and-billing/
  - text: "Meters"
    url: /metering-and-billing/metering/
  - text: "Collectors"
    url: /metering-and-billing/collectors/
  - text: "Get started with metering and billing"
    url: /how-to/get-started-with-metering-and-billing/
faqs:
  - q: Why don't I see any events in my customer's invoice?
    a: |
      {% include faqs/no-events-in-invoice.md %}
---

An event can be anything you need to track accurately over time for billing or analytics purposes. For example, a CI/CD product can include active or parallel jobs, build minutes, network traffic, storage used, or other product-related actions.

## How it works

{{site.metering_and_billing}} uses a stream processing architecture to collect usage events and turn them into metered consumption. This guide explains how {{site.metering_and_billing}} ingests events via [Kafka](https://kafka.apache.org/) and transfers them into [ClickHouse](https://clickhouse.com/), the columnar database used as long-term storage.

### Stream processing pipeline

First, the {{site.metering_and_billing}} API accepts events in the [CloudEvents](https://cloudevents.io/) format and publishes them to Kafka topics before further processing them. This allows {{site.metering_and_billing}} to process events in batches and handle traffic spikes efficiently.

The events are then processed by a custom [Kafka Consumer](https://github.com/openmeterio/openmeter/tree/main/cmd/sink-worker) written in Go, which, validates events and ensures consistent deduplication and exactly-once inserts into ClickHouse. The Kafka Consumer scales horizontally by Kafka partitions, allowing for parallel processing of events and ensuring high availability.

{% mermaid %}
flowchart LR
    A[{{site.konnect_short_name}} API] --> B[Kafka]
    B --> C[Go worker]
    B --> D[Go worker]
    B --> E[Go worker]
    C --> F[Clickhouse]
    D --> F
    E --> F
{% endmermaid %}

## Sending events

{{site.metering_and_billing}} leverages the [CloudEvents](https://cloudevents.io/) specification, which offers a standardized and flexible way to describe event data, making it easier to connect your services and tools seamlessly.

To ingest events into {{site.metering_and_billing}}, you need to send them to the {{site.konnect_short_name}} API:

<!-- vale off -->
{% konnect_api_request %}
url: /v3/openmeter/events
status_code: 200
method: POST
headers:
  - 'Content-Type: application/cloudevents+json'
body:
  specversion: "1.0"
  type: "request"
  id: "00001"
  source: "service-0"
  time: "2023-01-01T00:00:00.001Z"
  subject: "customer-1"
  data:
    method: "GET"
    route: "/hello"
{% endkonnect_api_request %}
<!--vale on-->

An event contains the following properties:

{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`specversion`"
    description: "CloudEvents spec version (currently `1.0`)."
  - property: "`type`"
    description: "Event type, used to match the event to a meter."
  - property: "`id`"
    description: "Unique event ID. Combined with `source` for deduplication."
  - property: "`time`"
    description: "Timestamp in RFC3339 format. Defaults to the time the event was received."
  - property: "`source`"
    description: "Origin of the event (e.g. service name)."
  - property: "`subject`"
    description: "The entity being metered (e.g. customer ID)."
  - property: "`data`"
    description: "JSON payload. Individual values can be extracted using [JSONPath](https://github.com/json-path/JsonPath)."
{% endtable %}

## Event processing

{{site.metering_and_billing}} continuously processes usage events, allowing you to update meters in real-time. Once an event is ingested, {{site.metering_and_billing}} aggregates the data based on your defined meters. For example, you can define meters called "Parallel jobs", and {{site.metering_and_billing}} will aggregate the maximum number of jobs by each customer over a given time period.

Using an example, let’s dive into how {{site.metering_and_billing}}’s event processing works. Imagine you want to track serverless execution duration by endpoint and you defined the following meter:

```yaml
meters:
  - slug: api_requests_total
    description: API Requests
    eventType: request
    valueProperty: $.duration_seconds
    aggregation: SUM
    groupBy:
      method: $.method
      route: $.route
```

For more information, see [Create a meter](/metering-and-billing/metering/#create-a-meter).

The meter config above tells {{site.metering_and_billing}} that expect CloudEvents with `type=request` where the usage value is stored in the `data.duration_seconds` and we need to sum them by `data.route`. {{site.metering_and_billing}} will track the usage value for every time window when least one event was reported and tracks it for every `subject` and `groupBy` permutation.

Note that `$.duration_seconds` is a JSONPath expression to access the `data.duration_seconds` property, providing powerful capabilities to extract values from nested data properties.

For example, when sending the following event:

```json
{
  "specversion": "1.0",
  "type": "request",
  "id": "00001",
  "time": "2024-01-01T00:00:00.001Z",
  "source": "service-0",
  "subject": "customer-1",
  "data": {
    "duration_seconds": "10",
    "method": "GET",
    "route": "/hello"
  }
}
```

{{site.metering_and_billing}} will track the usage value for the time window and customer as:
```
windowstart   = "2024-01-01T00:00"
windowend     = "2024-01-01T00:01"
subject       = "customer-1"
duration_seconds   = 10
method        = "GET"
route         = "/hello"
```

When sending a second event (with a different `id` and `duration_seconds` value):
```json
{
  "specversion": "1.0",
  "type": "request",
  "id": "00002",
  "time": "2024-01-01T00:00:00.001Z",
  "source": "service-0",
  "subject": "customer-1",
  "data": {
    "duration_seconds": "20",
    "method": "GET",
    "route": "/hello"
  }
}
```

{{site.metering_and_billing}} will increase sum of the duration for the two events for the same time window (`windowstart`, `windowend`), `method`, `route` and `subject`:
```
windowstart   = "2024-01-01T00:00"
windowend     = "2024-01-01T00:01"
subject       = "customer-1"
duration      = 30
method        = "GET"
route         = "/hello"
```

## Event deduplication

CloudEvents are unique by `id` and `source`. For more information, see [CloudEvent's specification](https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md).

{:.warning}
> Producers **must** ensure that the `source` and `id` combination is unique for each distinct event.
> If a duplicate event is re-sent (e.g. due to a network error) it may have the same `id`.
> Consumers may assume that events with identical `source` and `id` are duplicates.

{{site.metering_and_billing}} deduplicates events by id and source. This ensures that if multiple events with the same id and source are sent, they will be processed only once. This is useful when you want to retry or replay events in your infrastructure.

## Event enrichment

You may need to pre-process events before they are ingested into {{site.metering_and_billing}}, to normalize data, enrich events, or calculate derived fields like cost for example.

To pre-process events, use [Collectors](/metering-and-billing/collectors/), which support [Bloblang](https://docs.redpanda.com/redpanda-connect/guides/bloblang) mapping for transformations.

## Monitoring event ingestion

{{site.metering_and_billing}} provides a way to monitor the event ingestion pipeline in your infrastructure. Event ingestion monitoring can be useful for debugging, monitoring data quality, and ensuring that events are sent to {{site.metering_and_billing}} correctly.

Monitoring the event ingestion pipeline can help you notice when:

* Your system stopped sending events to {{site.metering_and_billing}}.
* Ingested events are incorrect or missing fields.
* {{site.metering_and_billing}} is having trouble processing events.

The **TODO** API endpoint provides metrics in Prometheus format. You can use a Prometheus server or any other monitoring system that supports the [Prometheus format](https://prometheus.io/docs/instrumenting/exposition_formats/) to collect these metrics.

### Counter resets

The metrics counters reset at midnight UTC. The Prometheus query language offers functions like `increase` and `rate` to handle counter resets correctly.

For example:
* `increase(openmeter_events_total[24h])` returns the number of events for the last 24 hours
* `rate(openmeter_events_total[1h])` returns the average per-second event read rate for the last hour

### Available metrics

The **TODO** API provides the `openmeter_events_total` metric, which counts the number of ingested events for each subject. Monitoring the number of ingested events can help you ensure that events are sent and processed correctly.

Here's an example of the response for the `openmeter_events_total` counter metric:

```
# HELP openmeter_events Number of ingested events
# TYPE openmeter_events counter
openmeter_events_total{subject="customer-1"} 12345.0
openmeter_events_total{subject="customer-2"} 67890.0
```

We recommend setting up an alert when the number of ingested events is significantly lower than expected. The correct threshold for the number of ingested events depends on your use case.

