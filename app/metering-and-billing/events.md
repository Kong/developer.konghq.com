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
  - text: "Subjects"
    url: /metering-and-billing/subjects/
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

### Scaling through partitions

Given that Kafka scales via partitions (with a single topic backed by multiple partitions), we adopted a similar strategy for our consumer workers. This approach is relatively simple to implement, thanks to the inherent rebalancing logic in Kafka clients. When clients subscribe to Kafka topics, they subscribe to specific partitions of a topic, where the Kafka broker determines the allocation. While various rebalancing strategies exist, we currently employ the default `RangeAssignor`, which assigns consumer partitions in a lexicographic sequence. Check out this [detailed article](https://medium.com/streamthoughts/understanding-kafka-partition-assignment-strategies-and-how-to-write-your-own-custom-assignor-ebeda1fc06f3) to learn about Kafka partition assignments and strategies.

{% mermaid %}
flowchart TB
    subgraph TopicA["Topic A"]
        A_P0[P0]
        A_P1[P1]
    end

    subgraph TopicB["Topic B"]
        B_P0[P0]
        B_P1[P1]
    end

    subgraph ConsumerGroup["Consumer Group"]
        C1[Consumer 1]
        C2[Consumer 2]
        C3[Consumer 3]
    end

    A_P0 --> C1
    A_P1 --> C2
    B_P0 --> C2
    B_P1 --> C3
{% endmermaid %}

## Sending events

{{site.metering_and_billing}} leverages the [CloudEvents](https://cloudevents.io/) specification, which offers a standardized and flexible way to describe event data, making it easier to connect your services and tools seamlessly.

To ingest events into {{site.metering_and_billing}}, you need to send them to the {{site.konnect_short_name}} API:

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
* `specversion`: The CloudEvents spec version (currently 1.0).
* `type`: The event type. This is used to match the event to a meter.
* `id`: The event's unique ID.
* `time`: The event's timestamp in RFC3339 format. Defaults to the time the event was received.
* `source`: The event's source (e.g. the service name).
* `subject`: The event's subject (e.g. the customer ID). Meter values are aggregated by subjects.
* `data`: The event's payload. This property can contain any valid JSON object, and when configuring meters using [JSONPath](https://github.com/json-path/JsonPath), individual values can be extracted.

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

{{site.metering_and_billing}} supports this through the [Collectors](/metering-and-billing/collectors/) and [Bloblang](https://docs.redpanda.com/redpanda-connect/guides/bloblang).

To calculate the cost of the container, you can use the following Bloblang mapping:

```yaml
pipeline:
  processors:
    - mapping: |
        root = this
        # initialize cost
        let cost = 0
        # 1 cent per MB memory cost
        let cost = $cost + this.data.mem_mb.int64() * 0.001
        # CPU core cost depends on the CPU family
        let cost = $cost + this.data.cpu_cores.int64() * match this.data.cpu_family {
          "intel" => 1.0,
          "graviton" => 1.5,
          _ => 0, # Default case for unmatched CPU family: could be some default price
        }
        # Volume discount for CPU count
        let cost = $cost + this.data.gpu_count.int64() * match this.data.gpu_count {
          this > 5 => 0.5,
          this > 2 => 0.8,
          _ => 1,
        } * match this.data.gpu {
          "A100-40" => 1.0,
          "A100-60" => 1.5,
          _ => 0, # Default case for unmatched GPU type: could be some default price
        }
        root.data.cost = $cost
        # For advanced mapping logic, consider writing unit tests:
        # https://docs.redpanda.com/redpanda-connect/guides/bloblang/walkthrough/#unit-testing
output:
  stdout:
    codec: lines
```

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

