---
title: "Collectors"
content_type: reference
description: "Learn about collectors in {{site.konnect_short_name}} {{site.metering_and_billing}} and how to collect usage data from various sources."
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
  - text: "Metering"
    url: /metering-and-billing/metering/
---

The OpenMeter Collector is an open-source software you can run in your own infrastructure to meter external systems like Kubernetes, GPUs, and import usage from datasources into {{site.metering_and_billing}}.
While collectors provide a higher abstraction than the API, you can always use the API to integrate new data sources.

## Available collectors

The following collectors are available:

<!--vale off-->
{% table %}
columns:
  - title: Collector
    key: collector
  - title: Description
    key: description
rows:
  - collector: "[Kubernetes](/metering-and-billing/collectors/kubernetes/)"
    description: "Collect resource usage from Kubernetes pods including CPU, memory, and GPU allocation."
  - collector: "[Run:ai](/metering-and-billing/collectors/run-ai/)"
    description: "Collect GPU and compute metrics from Nvidia Run:ai workloads."
  - collector: "[OpenTelemetry](/metering-and-billing/collectors/opentelemetry/)"
    description: "Collect usage data from OpenTelemetry logs and metrics."
  - collector: "[Prometheus](/metering-and-billing/collectors/prometheus/)"
    description: "Query Prometheus metrics and convert them to billing events."
  - collector: "[S3](/metering-and-billing/collectors/s3/)"
    description: "Ingest usage data from S3-compatible object storage."
{% endtable %}
<!--vale on-->

## How it works

The OpenMeter Collector is built on top of Redpanda Connect (previously Benthos), a robust in-proces stream processing tool that can connect to a wide range of data sources. 
The tool's strong delivery guarantees and capability to retry failed messages make it an excellent choice as a collector for {{site.metering_and_billing}}.

### Architecture

The Collector connects data sources to sinks through a pipeline comprising various processing steps. It reads messages from a streaming source, processes them (validation, transformation, enrichment, etc.), and then sends them to {{site.metering_and_billing}}. 
It does so with strong delivery guarantees, ensuring that messages are recovered and will be retried until they are successfully delivered to their destination.

The three major components of the Collector pipeline:

- **Inputs**: Read usage data from various sources
- **Processors**: Validate, transform, and filter usage events  
- **Output**: Send data to {{site.metering_and_billing}} with retry and buffer

### Ingesting data

When using the collector, the output of the pipeline is always a {{site.metering_and_billing}} instance:

```yaml
output:
  openmeter:
    url: https://us.api.konghq.com/v3/openmeter # default
    token: '<YOUR TOKEN>' # required
```

As of today, {{site.metering_and_billing}} requires ingested data to be in the [CloudEvents](https://cloudevents.io/) format. Redpanda Connect offers a range of processors that can transform, validate, and enrich messages. The most commonly used processor is known as mapping, which utilizes Redpanda Connect's mapping language, [bloblang](https://docs.redpanda.com/redpanda-connect/guides/bloblang/about).

Let's assume you have access logs are in the following format:

```json
{
  "timestamp": "2021-01-01T00:00:00.000Z",
  "method": "GET",
  "path": "/app",
  "user": "USERID",
  "duration": 100
}
```

You can use the mapping processor to transform the data into a usage event:

```yaml
pipeline:
  processors:
    - mapping: |
        root = {
          "id": uuid_v4(),
          "specversion": "1.0",
          "type": "api-call",
          "source": "api-gateway",
          "time": this.timestamp,
          "subject": this.user,
          "data": {
            "duration": this.duration,
          },
        }
```

### Installation

The OpenMeter Collector (custom Redpanda Connect distribution) is available via the following distribution strategies:

- Binaries can be downloaded from the [GitHub Releases](https://github.com/openmeterio/openmeter/releases) page
- Container images are available on [ghcr.io](https://github.com/openmeterio/openmeter/pkgs/container/benthos-collector)
- A Helm chart is also available on [GitHub Packages](https://github.com/openmeterio/openmeter/tree/main/deploy/charts/benthos-collector)

## High availability

The OpenMeter Collector is designed with strong delivery guarantees and capability to retry failed messages.
Using the event buffering you can handle network outages without loosing any data.

### Event buffering

The OpenMeter Collector uses a persistent queue to buffer events. This allows the collector to store events on a persistent disk and retry them later in case of network failures or other issues. 
Based on the load and disk size, the collector can buffer events for extended periods of time like hours or days and safely replay them to {{site.metering_and_billing}} when the network is restored.

### Retries

The OpenMeter Collector will retry failed messages up to 3 times (configurable). If the message still fails after 3 retries, it will be dropped.

### Event deduplication

{{site.metering_and_billing}} will deduplicate events based on the `id` and `source` fields. If a message with the same `id` and `source` is received multiple times, only the first occurrence will be processed.

### API and SDK passthrough

API can be pointed to the OpenMeter Collector endpoint to enrich events with additional metadata or increase the reliability of event delivery by leveraging the collector's buffer and retry capabilities.

## Event buffering

The OpenMeter Collector can operate in a passthrough mode where it buffers events on a local disk. This allows the collector to continue operating even if the network is down for an extended period of time. When the network is restored, the collector will replay the buffered events to {{site.metering_and_billing}}.

### How does event buffering work?

Installing the OpenMeter Collector with buffer enabled lets you send your usage events to the Collector instead of sending events directly to {{site.metering_and_billing}}. 
In this configuration, your app will first send the event to the Collector, which will forward the events to {{site.metering_and_billing}} and buffer them, retrying in the case of network failure.

To increase the resilience of your metering pipeline, the Collector comes with:

- Buffering
- Retries and backoff
- Deduplication
- OpenTelemetry metrics and logging

When buffering is enabled, in the case of connectivity issues, the Collector stores events on an attached persistent volume until the network recovers. 
The available space on the attached disk determines the size of the buffer.

The Collector also provides visibility into the buffer and processing states by exposing Prometheus metrics. 

### Get started with buffering

You can enable buffering with the Collector in two simple steps:

**1. Install the Collector:**

```bash
# Set your token
export OPENMETER_TOKEN=om_...

# Get the latest version
export LATEST_VERSION=$(curl -s https://api.github.com/repos/openmeterio/openmeter/releases/latest | jq -r '.tag_name' | cut -c2-)

# Install the collector in the openmeter-collector namespace
helm upgrade openmeter-collector oci://ghcr.io/openmeterio/helm-charts/benthos-collector \
  --version=${LATEST_VERSION} \
  --install --wait --create-namespace \
  --namespace openmeter-collector \
  --set fullnameOverride=openmeter-collector \
  --set openmeter.token=${OPENMETER_TOKEN} \
  --set service.enabled=true \
  --set storage.enabled=true \
  --set preset=http-server
```

**2. Point your API to the installed collector:**

Send events to the collector's URL in your infrastructure, e.g. `http://openmeter-collector.svc`.

```sh
curl -X POST http://openmeter-collector.svc \
  -H 'Content-Type: application/cloudevents+json' \
  -H 'Authorization: Bearer <API_TOKEN>' \
  --data '
  {
    "specversion" : "1.0",
    "type": "prompt",
    "id": "e4bacd05-5abd-4e1c-be6f-daf6b8e9dd92",
    "time": "2026-02-01T16:41:37.188Z",
    "source": "my-app",
    "subject": "customer-1",
    "data": {
      "tokens": "12345",
      "provider": "openai",
      "model": "gpt-5-nano",
      "type": "output"
    }
  }
  '
```

## Observability

The OpenMeter Collector exports OpenTelemetry metrics and logs for observability. The metrics are available on the `GET /metrics` endpoint if you want to scrape them with OpenTelemetry-compatible tools like Prometheus.

### Observability metrics

The Collector exports the following observability metrics:

**Batch metrics:**
<!--vale off-->
{% table %}
columns:
  - title: Metric Name
    key: metric_name
  - title: Description
    key: description
rows:
  - metric_name: "`batch_created`"
    description: "Counter of batches created"
  - metric_name: "`batch_sent`"
    description: "Counter of batches sent to the buffer"
{% endtable %}
<!--vale on-->

**Buffer metrics:**
<!--vale off-->
{% table %}
columns:
  - title: Metric Name
    key: metric_name
  - title: Description
    key: description
rows:
  - metric_name: "`buffer_batch_received`"
    description: "Counter of batches received from the buffer"
  - metric_name: "`buffer_batch_sent`"
    description: "Counter of batches sent to the buffer"
  - metric_name: "`buffer_latency_ns`"
    description: "Histogram of buffer latency"
{% endtable %}
<!--vale on-->

**Other metrics:**

- Processor metrics
- Output metrics

### Observability logs

The Collector logs the following:

- Collector startup and shutdown
- Collector errors
- Collector configuration errors
- Collector event source errors
- Collector event output errors
- Collector logs
