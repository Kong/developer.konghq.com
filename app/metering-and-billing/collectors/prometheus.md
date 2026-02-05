---
title: "Prometheus Collector"
content_type: reference
description: "Learn how to use the Prometheus collector to meter usage from Prometheus metrics in {{site.konnect_short_name}} {{site.metering_and_billing}}."
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

The {{site.metering_and_billing}} Collector can query Prometheus to collect metrics for billing and invoicing. 
This is useful for companies using Prometheus to monitor their infrastructure and want to bill and invoice their customers based on already collected metrics.

## How it works

The collector periodically queries your Prometheus instance using PromQL queries and emits the results as [CloudEvents](https://cloudevents.io/) to {{site.metering_and_billing}}. 
This allows you to track usage and billing for your Prometheus workloads.

Sending Prometheus metrics into {{site.metering_and_billing}} as billing events also helps to have a record of the billing events that you can audit. 
Most Prometheus instances keep metrics only for a short period of time, while {{site.metering_and_billing}} can keep the billing events for a long time, providing a record of the usage and billing for auditing and accounting purposes.

## Example use cases

For example, if you already have Prometheus metrics about the number of API requests your application is serving for your customers, you can use the Collector to turn the Prometheus metrics into billable events and send them to {{site.metering_and_billing}} for billing.

## Monetizing Prometheus metrics

{:.warning}
> Prometheus metrics and queries are not designed for billing and can lead to inaccuracies due to:
> * Metrics can be lost when the app restarts and the metric wasn't collected by the Prometheus scraper.
> * Metrics duplicates aren't removed, so you can get multiple metrics for the same event.
>
> We only recommend monetizing Prometheus metrics for long running workloads, where the impact of inaccuracies is negligible.

## Get started

First, create a new YAML file for the collector configuration. You will use the `prometheus` Redpanda Connect input:

```yaml
input:
  prometheus:
    # Prometheus server URL the collector will query
    url: '${PROMETHEUS_URL}'
    # Scrape interval for the collector, e.g. once per minute
    schedule: '0 * * * * *'
    # Time offset for queries to account for delays in metric availability
    query_offset: '1m'
    # List of PromQL queries to execute
    queries:
      - query:
          # Unique identifier for the query results
          name: 'node_cpu_usage'
          # PromQL query to execute
          # [1m] is the query interval for the query, keep in sync with the collector's schedule
          promql: sum(increase(node_cpu_seconds_total{mode!='idle'}[1m])) by(instance)
```

{:.warning}
> **Important:** Be sure to keep the collector's schedule interval in sync with the PromQL interval. If the query interval is not for the same period as the collector runs, you can miss or double collect metrics.

### Configuration options

See the following table for supported configuration options:

<!--vale off-->
{% table %}
columns:
  - title: Option
    key: option
  - title: Description
    key: description
  - title: Default
    key: default
  - title: Required
    key: required
rows:
  - option: "`url`"
    description: "Prometheus server URL"
    default: "-"
    required: "Yes"
  - option: "`schedule`"
    description: "Cron expression for the scrape interval"
    default: "`0 * * * * *`"
    required: "No"
  - option: "`query_offset`"
    description: "Time offset for queries to account for delays in metric availability"
    default: "`0s`"
    required: "No"
  - option: "`queries`"
    description: "List of PromQL queries to execute"
    default: "-"
    required: "Yes"
{% endtable %}
<!--vale on-->

Each query in the `queries` list requires a `name` (unique identifier for the query results) and a `promql` expression to execute.

Next, configure the mapping from the Prometheus metrics to CloudEvents using bloblang:

```yaml
pipeline:
  processors:
    # Map each value to a separate message with name, timestamp, and value
    - mapping: |
        root = this.values.map_each(value -> {
          "id": uuid_v4(),
          "specversion": "1.0",
          "type": this.name,
          "source": "prometheus",
          "time": this.timestamp,
          "subject": value.metric.instance,
          "data": {
            "value": value.value,
            "metric": value.metric
          }
        })
    # Convert JSON array to individual messages
    - unarchive:
        format: json_array
```

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

## Scheduling

The collector runs on a schedule defined by the `schedule` parameter using cron syntax. It supports:

* Standard cron expressions (for example, `0 * * * * *` for once per minute)
* Duration syntax with the `@every` prefix (for example, `@every 1m`)

## Query offset

The `query_offset` parameter allows you to query for data from a point in the past, which is useful when metrics have a delay before they're available in Prometheus. For example, setting `query_offset: "1m"` means each query will be executed against data from one minute ago.

## Installation

{% include /konnect/metering-and-billing/collector-install.md %}
