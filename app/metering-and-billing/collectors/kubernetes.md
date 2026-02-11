---
title: "Kubernetes Collector"
content_type: reference
description: "Learn how to use the Kubernetes collector to meter pod resource usage in {{site.konnect_short_name}} {{site.metering_and_billing}}."
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

The {{site.metering_and_billing}} Kubernetes Collector is a standalone application you can install in your Kubernetes cluster to meter resource usage, such as Pod runtime CPU, memory, and storage allocation. 
This is useful if you want to monetize customer workloads with usage-based billing and invoicing.

## How it works

The collector periodically scrapes the Kubernetes API to collect running pods and resources and emits them as [CloudEvents](https://cloudevents.io/) to {{site.metering_and_billing}}. 
This allows you to track usage and monetize your Kubernetes workloads.

Once you have the usage data ingested into {{site.metering_and_billing}}, you can use it to set up prices and billing for your customers based on their usage.

### Example: Billing per CPU-core minute

Let's say you want to charge your customers $0.05 per CPU-core minute. The Collector will emit the following events every 10 seconds from your Kubernetes Pods:

```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "specversion": "1.0",
  "type": "workload",
  "source": "kubernetes-api",
  "time": "2025-01-01T00:00:00Z",
  "subject": "my-customer-id",
  "data": {
    "pod_name": "my-pod",
    "pod_namespace": "my-namespace",
    "duration_seconds": 10,
    "cpu_request_millicores": 0.5,
    "cpu_request_millicores_per_second": 5,
    "memory_request_bytes": 4294967296,
    "memory_request_bytes_per_second": 42949672960,
    "gpu_type": "A100",
    "gpu_request_count": 1,
    "gpu_request_count_per_second": 10
  }
}
```

{:.info}
> **Note:** The collector normalizes the collected metrics to a second, which is configurable, making it easy to set per second, minute, or hour pricing similar to how AWS EC2 pricing works.

## Kubernetes metrics

The collector can meter the following metrics:

<!--vale off-->
{% table %}
columns:
  - title: Metric
    key: metric
  - title: Description
    key: description
rows:
  - metric: "`cpu_request_millicores`"
    description: "The number of CPU cores requested for the pod."
  - metric: "`cpu_request_millicores_per_second`"
    description: "The number of CPU cores requested per second."
  - metric: "`cpu_limit_millicores`"
    description: "The number of CPU cores limited for the pod."
  - metric: "`cpu_limit_millicores_per_second`"
    description: "The number of CPU cores limited per second."
  - metric: "`memory_request_bytes`"
    description: "The amount of memory requested for the pod."
  - metric: "`memory_request_bytes_per_second`"
    description: "The amount of memory requested per second."
  - metric: "`memory_limit_bytes`"
    description: "The amount of memory limited for the pod."
  - metric: "`memory_limit_bytes_per_second`"
    description: "The amount of memory limited per second."
  - metric: "`gpu_request_count`"
    description: "The number of GPUs requested for the pod."
  - metric: "`gpu_request_count_per_second`"
    description: "The number of GPUs requested per second."
  - metric: "`gpu_limit_count`"
    description: "The number of GPUs limited for the pod."
  - metric: "`gpu_limit_count_per_second`"
    description: "The number of GPUs limited per second."
{% endtable %}
<!--vale on-->

## Get started

Follow the steps below to get started with the Kubernetes collector.

### Installation

The simplest method for installing the collector is through [Helm](https://helm.sh/):

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
  --set openmeter.token=$KONNECT_SYSTEM_ACCESS_TOKEN \
  --set preset=kubernetes-pod-exec-time
```

Replace `$KONNECT_SYSTEM_ACCESS_TOKEN` with your own [system access token](/konnect-api/#system-accounts-and-access-tokens).

With the default settings, the collector will report on pods running in the `default` namespace every 15 seconds.

### Capture CPU and memory limits

A common use case for monetizing workloads running on Kubernetes is to charge based on resource consumption. One way to do that is to include resource limits of containers in the ingested data.

Although it requires a custom configuration, it's straightforward to achieve with the Kubernetes collector:

```yaml
input:
  # just use the defaults

pipeline:
  processors:
    - mapping: |
        root = {
          "id": uuid_v4(),
          "specversion": "1.0",
          "type": "kube-pod-exec-time",
          "source": "kubernetes-api",
          "time": meta("schedule_time"),
          "subject": this.metadata.annotations."openmeter.io/subject".or(this.metadata.name),
          "data": this.metadata.annotations.filter(item -> item.key.has_prefix("data.openmeter.io/")).map_each_key(key -> key.trim_prefix("data.openmeter.io/")).assign({
            "pod_name": this.metadata.name,
            "pod_namespace": this.metadata.namespace,
            "duration_seconds": (meta("schedule_interval").parse_duration() / 1000 / 1000 / 1000).round().int64(),
            "memory_limit": this.spec.containers.index(0).resources.limits.memory,
            "memory_requests": this.spec.containers.index(0).resources.requests.memory,
            "cpu_limit": this.spec.containers.index(0).resources.limit.cpu,
            "cpu_requests": this.spec.containers.index(0).resources.requests.cpu,
          }),
        }
    - json_schema:
        schema_path: 'file://./cloudevents.spec.json'
    - catch:
        - log:
            level: ERROR
            message: 'Schema validation failed due to: ${!error()}'
        - mapping: 'root = deleted()'
```

### Start metering

To start measuring Kubernetes pod execution time, create a meter in {{site.konnect_short_name}}:

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. Click **New generic meter**.
1. Configure the meter with the following settings:
    * **Slug**: `pod_execution_time`
    * **Event Type**: `kube-pod-exec-time`
    * **Value Property**: `$.duration_seconds`
    * **Aggregation**: `SUM`
    * **Group By**: `pod_name`, `pod_namespace`

## Configuration

The collector accepts several configuration values as environment variables:

<!--vale off-->
{% table %}
columns:
  - title: Variable
    key: variable
  - title: Default
    key: default
  - title: Description
    key: description
rows:
  - variable: "`SCRAPE_NAMESPACE`"
    default: "`default`"
    description: "The namespace to scrape. Leave empty to scrape all namespaces."
  - variable: "`SCRAPE_INTERVAL`"
    default: "`15s`"
    description: "The interval for scraping in Go duration format (minimum interval: 1 second)."
  - variable: "`BATCH_SIZE`"
    default: "`20`"
    description: "The minimum number of events to wait for before reporting. The collector will report events in a single batch (set to `0` to disable)."
  - variable: "`BATCH_PERIOD`"
    default: "-"
    description: "The maximum duration to wait before reporting the current batch, in Go duration format."
  - variable: "`DEBUG`"
    default: "`false`"
    description: "If set to `true`, every reported event is logged to stdout."
{% endtable %}
<!--vale on-->

These values can be set in the Helm chart's `values.yaml` file using `env` or `envFrom`.

### Mapping

The collector maps information from each pod to CloudEvents according to the following rules:

* **Event type** is set as `kube-pod-exec-time`.
* **Event source** is set as `kubernetes-api`.
* The subject name is mapped from the value of the `openmeter.io/subject` annotation. It falls back to the pod name if the annotation isn't present.
* Pod execution time is mapped to `duration_seconds` in the `data` section.
* Pod name and namespace are mapped to `pod_name` and `pod_namespace` in the `data` section.
* Annotations labeled `data.openmeter.io/KEY` are mapped to `KEY` in the `data` section.

### Performance tuning

The ideal performance tuning options for this collector depend on the specific use case and the context in which it is being used. For instance, reporting on a large number of pods infrequently requires different settings than reporting on a few pods frequently.

The primary factors influencing performance that you can adjust are `SCRAPE_INTERVAL`, `BATCH_SIZE`, and `BATCH_PERIOD`.

* A lower `SCRAPE_INTERVAL` implies the need for more accurate information about pod execution time, but it also generates more events.
* To mitigate increased load, you can raise `BATCH_SIZE` and/or set or increase `BATCH_PERIOD`. This approach reduces the number of requests to {{site.metering_and_billing}}.
* Managing a large number of pods typically requires a higher `SCRAPE_INTERVAL` to avoid overburdening the Kubernetes API.

### Advanced configuration

The Kubernetes collector uses [Redpanda Connect](https://benthos.dev) to gather pod information, convert it to CloudEvents, and reliably transmit it to {{site.metering_and_billing}}.

The configuration file for the collector is available on [GitHub](https://github.com/openmeterio/openmeter/blob/main/collector/benthos/presets/kubernetes-pod-exec-time/config.yaml).

To tailor the configuration to your needs, you can edit this file and mount it to the collector container using the `config` or `configFile` options in the Helm chart.
