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

The events are then processed by a custom [Kafka Consumer](https://github.com/openmeterio/openmeter/tree/main/cmd/sink-worker) written in Go, which validates events and ensures consistent deduplication and exactly-once inserts into ClickHouse. The Kafka Consumer scales horizontally by Kafka partitions, allowing for parallel processing of events and ensuring high availability.

{% mermaid %}
flowchart LR
    A[{{site.konnect_short_name}} API] --> B[Kafka]
    B --> C[Go worker]
    B --> D[Go worker]
    B --> E[Go worker]
    C --> F[ClickHouse]
    D --> F
    E --> F
{% endmermaid %}

## Sending events

{{site.metering_and_billing}} leverages the [CloudEvents](https://cloudevents.io/) specification, which offers a standardized and flexible way to describe event data, making it easier to connect your services and tools seamlessly.

To ingest events into {{site.metering_and_billing}}, send them to the {{site.konnect_short_name}} API:

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
    description: "The CloudEvents spec version (currently `1.0`)."
  - property: "`type`"
    description: "The event type, used to match the event to a meter."
  - property: "`id`"
    description: "A unique event ID. Combined with `source` for deduplication."
  - property: "`time`"
    description: "The timestamp in RFC3339 format. Defaults to the time the event was received."
  - property: "`source`"
    description: "The origin of the event (e.g. service name)."
  - property: "`subject`"
    description: "The entity being metered (e.g. customer ID)."
  - property: "`data`"
    description: "The JSON payload. Individual values can be extracted using [JSONPath](https://github.com/json-path/JsonPath)."
{% endtable %}

## Event processing

{{site.metering_and_billing}} continuously processes usage events, allowing you to update meters in real-time. Once an event is ingested, {{site.metering_and_billing}} aggregates the data based on your defined [meters](/metering-and-billing/metering/). For example, you can define meters called "Parallel jobs", and {{site.metering_and_billing}} will aggregate the maximum number of jobs by each customer over a given time period.

Let's say you want to track serverless execution duration by endpoint and you defined the following meter:

{% konnect_api_request %}
url: /v3/openmeter/meters
method: POST
headers:
  - 'Accept: application/json, application/problem+json'
body:
  slug: api_requests_total
  description: API Requests
  eventType: request
  valueProperty: $.duration_seconds
  aggregation: SUM
  groupBy:
    method: $.method
    route: $.route
{% endkonnect_api_request %}

{:.info}
> `$.duration_seconds` is a JSONPath expression to access the `data.duration_seconds` property, providing powerful capabilities to extract values from nested data properties.

The meter config above tells {{site.metering_and_billing}} to expect CloudEvents with `type=request` where the usage value is stored in the `data.duration_seconds`, and we need to sum them up by `data.route`. {{site.metering_and_billing}} will track the usage value for every time window when at least one event was reported and tracks it for every `subject` and `groupBy` permutation.

For example, when sending the following event:

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

{{site.metering_and_billing}} will track the usage value for the time window and customer as:
```
windowstart   = "2024-01-01T00:00"
windowend     = "2024-01-01T00:01"
subject       = "customer-1"
duration_seconds   = 10
method        = "GET"
route         = "/hello"

When sending a second event (with a different `id` and `duration_seconds` value):
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
  id: "00002"
  source: "service-0"
  time: "2024-01-01T00:00:00.001Z"
  subject: "customer-1"
  data:
    duration_seconds: 20
    method: "GET"
    route: "/hello"
{% endkonnect_api_request %}
<!--vale on-->

{{site.metering_and_billing}} will increase sum of the duration for the two events for the same time window (`windowstart`, `windowend`), `method`, `route` and `subject`:
```
windowstart   = "2024-01-01T00:00"
windowend     = "2024-01-01T00:01"
subject       = "customer-1"
duration_seconds      = 30
method        = "GET"
route         = "/hello"

## Event deduplication

CloudEvents are unique by `id` and `source`. For more information, see [CloudEvents specification](https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md).

{:.warning}
> Producers **must** ensure that the `source` and `id` combination is unique for each distinct event.
> If a duplicate event is re-sent (for example, due to a network error) it may have the same `id`.
> Consumers may assume that events with identical `source` and `id` are duplicates.

{{site.metering_and_billing}} deduplicates events by `id` and `source`. This ensures that if multiple events with the same `id` and `source` are sent, they are only processed once. This is useful when you want to retry or replay events in your infrastructure.

## Event enrichment

You may need to pre-process events before they are ingested into {{site.metering_and_billing}} to normalize data, enrich events, or calculate derived fields like cost for example.

To pre-process events, use [Collectors](/metering-and-billing/collectors/), which support [Bloblang](https://docs.redpanda.com/redpanda-connect/guides/bloblang) mapping for transformations.