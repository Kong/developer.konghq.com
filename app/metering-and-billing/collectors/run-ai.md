---
title: "Run:ai Collector"
content_type: reference
description: "Learn how to use the Nvidia Run:ai collector to meter GPU workloads in {{site.konnect_short_name}} {{site.metering_and_billing}}."
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

The {{site.metering_and_billing}} Collector can integrate with Nvidia's Run:ai to collect allocated and used resources for your AI/ML workloads, including GPUs, CPUs, and memory. 
This is useful for companies using Run:ai to run GPU workloads that want to bill and invoice their customers based on consumption of allocated and used resources.

## How it works

You can install the Collector as a Kubernetes pod in your Run:ai cluster to collect metrics from your Run:ai platform automatically. 
The collector periodically scrapes the metrics from your Run:ai platform and emits them as [CloudEvents](https://cloudevents.io/) to {{site.metering_and_billing}}. 
This allows you to track usage and monetize Run:ai workloads.

Once you have the usage data ingested into {{site.metering_and_billing}}, you can use it to set up prices and billing for your customers based on their usage.

### Example

Let's say you want to charge your customers $0.2 per GPU minute and $0.05 per CPU minute. The Collector will emit the following events every 30 seconds from your Run:ai workloads:

```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "specversion": "1.0",
  "type": "workload",
  "source": "run_ai",
  "time": "2025-01-01T00:00:00Z",
  "subject": "my-customer-id",
  "data": {
    "name": "my-runai-workload",
    "namespace": "my-runai-benchmark-test",
    "phase": "Running",
    "project": "my-project-id",
    "department": "my-department-id",
    "workload_minutes": 1.0,
    "cpu_limit_core_minutes": 96,
    "cpu_request_core_minutes": 96,
    "cpu_usage_core_minutes": 80,
    "cpu_memory_limit_gigabyte_minutes": 384,
    "cpu_memory_request_gigabyte_minutes": 384,
    "cpu_memory_usage_gigabyte_minutes": 178,
    "gpu_allocation_minutes": 1,
    "gpu_usage_minutes": 1,
    "gpu_memory_request_gigabyte_minutes": 40,
    "gpu_memory_usage_gigabyte_minutes": 27
  }
}
```

{:.info}
> **Note:** The collector normalizes the collected metrics to a minute, which is configurable, so you can set per second, minute, or hour pricing similar to how AWS EC2 pricing works.

## Run:ai metrics

The Collector supports the following Run:ai metrics:

### Pod metrics

See the following table for supported pod metrics:

<!--vale off-->
{% table %}
columns:
  - title: Metric Name
    key: metric_name
  - title: Description
    key: description
rows:
  - metric_name: "`GPU_UTILIZATION_PER_GPU`"
    description: "GPU utilization percentage per individual GPU"
  - metric_name: "`GPU_UTILIZATION`"
    description: "Overall GPU utilization percentage for the pod"
  - metric_name: "`GPU_MEMORY_USAGE_BYTES_PER_GPU`"
    description: "GPU memory usage in bytes per individual GPU"
  - metric_name: "`GPU_MEMORY_USAGE_BYTES`"
    description: "Total GPU memory usage in bytes for the pod"
  - metric_name: "`CPU_USAGE_CORES`"
    description: "Number of CPU cores currently being used"
  - metric_name: "`CPU_MEMORY_USAGE_BYTES`"
    description: "Amount of CPU memory currently being used in bytes"
  - metric_name: "`GPU_GRAPHICS_ENGINE_ACTIVITY_PER_GPU`"
    description: "Graphics engine utilization percentage per GPU"
  - metric_name: "`GPU_SM_ACTIVITY_PER_GPU`"
    description: "Streaming Multiprocessor (SM) activity percentage per GPU"
  - metric_name: "`GPU_SM_OCCUPANCY_PER_GPU`"
    description: "SM occupancy percentage per GPU"
  - metric_name: "`GPU_TENSOR_ACTIVITY_PER_GPU`"
    description: "Tensor core usage percentage per GPU"
  - metric_name: "`GPU_FP64_ENGINE_ACTIVITY_PER_GPU`"
    description: "FP64 (double precision) engine activity percentage per GPU"
  - metric_name: "`GPU_FP32_ENGINE_ACTIVITY_PER_GPU`"
    description: "FP32 (single precision) engine activity percentage per GPU"
  - metric_name: "`GPU_FP16_ENGINE_ACTIVITY_PER_GPU`"
    description: "FP16 (half precision) engine activity percentage per GPU"
  - metric_name: "`GPU_MEMORY_BANDWIDTH_UTILIZATION_PER_GPU`"
    description: "Memory bandwidth usage percentage per GPU"
  - metric_name: "`GPU_NVLINK_TRANSMITTED_BANDWIDTH_PER_GPU`"
    description: "NVLink transmitted bandwidth per GPU"
  - metric_name: "`GPU_NVLINK_RECEIVED_BANDWIDTH_PER_GPU`"
    description: "NVLink received bandwidth per GPU"
  - metric_name: "`GPU_PCIE_TRANSMITTED_BANDWIDTH_PER_GPU`"
    description: "PCIe transmitted bandwidth per GPU"
  - metric_name: "`GPU_PCIE_RECEIVED_BANDWIDTH_PER_GPU`"
    description: "PCIe received bandwidth per GPU"
  - metric_name: "`GPU_SWAP_MEMORY_BYTES_PER_GPU`"
    description: "Amount of GPU memory swapped to system memory per GPU"
{% endtable %}
<!--vale on-->

### Workload metrics

See the following table for supported workload metrics:

<!--vale off-->
{% table %}
columns:
  - title: Metric Name
    key: metric_name
  - title: Description
    key: description
rows:
  - metric_name: "`GPU_UTILIZATION`"
    description: "Overall GPU usage percentage across all GPUs in the workload"
  - metric_name: "`GPU_MEMORY_USAGE_BYTES`"
    description: "Total GPU memory usage in bytes across all GPUs"
  - metric_name: "`GPU_MEMORY_REQUEST_BYTES`"
    description: "Requested GPU memory in bytes for the workload"
  - metric_name: "`CPU_USAGE_CORES`"
    description: "Number of CPU cores currently being used"
  - metric_name: "`CPU_REQUEST_CORES`"
    description: "Number of CPU cores requested for the workload"
  - metric_name: "`CPU_LIMIT_CORES`"
    description: "Maximum number of CPU cores allowed for the workload"
  - metric_name: "`CPU_MEMORY_USAGE_BYTES`"
    description: "Amount of CPU memory currently being used in bytes"
  - metric_name: "`CPU_MEMORY_REQUEST_BYTES`"
    description: "Requested CPU memory in bytes for the workload"
  - metric_name: "`CPU_MEMORY_LIMIT_BYTES`"
    description: "Maximum CPU memory allowed in bytes for the workload"
  - metric_name: "`POD_COUNT`"
    description: "Total number of pods in the workload"
  - metric_name: "`RUNNING_POD_COUNT`"
    description: "Number of currently running pods in the workload"
  - metric_name: "`GPU_ALLOCATION`"
    description: "Number of GPUs allocated to the workload"
{% endtable %}
<!--vale on-->

## Get started

First, create a new YAML file for the collector configuration. Use the `run_ai` Redpanda Connect input:

```yaml
input:
  run_ai:
    url: '${RUNAI_URL:}'
    app_id: '${RUNAI_APP_ID:}'
    app_secret: '${RUNAI_APP_SECRET:}'
    schedule: '*/30 * * * * *'
    metrics_offset: '30s'
    resource_type: 'workload'
    metrics:
      - CPU_LIMIT_CORES
      - CPU_MEMORY_LIMIT_BYTES
      - CPU_MEMORY_REQUEST_BYTES
      - CPU_MEMORY_USAGE_BYTES
      - CPU_REQUEST_CORES
      - CPU_USAGE_CORES
      - GPU_ALLOCATION
      - GPU_MEMORY_REQUEST_BYTES
      - GPU_MEMORY_USAGE_BYTES
      - GPU_UTILIZATION
      - POD_COUNT
      - RUNNING_POD_COUNT
    http:
      timeout: 30s
      retry_count: 1
      retry_wait_time: 100ms
      retry_max_wait_time: 1s
```

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
    description: "Run:ai base URL"
    default: "-"
    required: "Yes"
  - option: "`app_id`"
    description: "Run:ai app ID"
    default: "-"
    required: "Yes"
  - option: "`app_secret`"
    description: "Run:ai app secret"
    default: "-"
    required: "Yes"
  - option: "`resource_type`"
    description: "Run:ai resource to collect metrics from (`workload` or `pod`)"
    default: "`workload`"
    required: "No"
  - option: "`metrics`"
    description: "List of Run:ai metrics to collect"
    default: "All available"
    required: "No"
  - option: "`schedule`"
    description: "Cron expression for the scrape interval"
    default: "`*/30 * * * * *`"
    required: "No"
  - option: "`metrics_offset`"
    description: "Time offset for queries to account for delays in metric availability"
    default: "`0s`"
    required: "No"
  - option: "`http`"
    description: "HTTP client configuration"
    default: "-"
    required: "No"
{% endtable %}
<!--vale on-->

Next, configure the mapping from the Run:ai metrics to CloudEvents using bloblang:

```yaml
pipeline:
  processors:
    - mapping: |
        let duration_seconds = (meta("scrape_interval").parse_duration() / 1000 / 1000 / 1000).round().int64()
        let gpu_allocation_minutes = this.allocatedResources.gpu.number(0) * $duration_seconds / 60
        let cpu_limit_core_minutes = this.metrics.values.CPU_LIMIT_CORES.number(0) * $duration_seconds / 60
        # Add metrics as needed...
        
        root = {
          "id": uuid_v4(),
          "specversion": "1.0",
          "type": meta("resource_type"),
          "source": "run_ai",
          "time": now(),
          "subject": this.name,
          "data": {
            "tenant": this.tenantId,
            "project": this.projectId,
            "department": this.departmentId,
            "cluster": this.clusterId,
            "type": this.type,
            "gpuAllocationMinutes": $gpu_allocation_minutes,
            "cpuLimitCoreMinutes": $cpu_limit_core_minutes,
          }
        }
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

- Standard cron expressions (for example, `*/30 * * * * *` for every 30 seconds)
- Duration syntax with the `@every` prefix (for example, `@every 30s`)

## Resource types

The collector can collect metrics from two different resource types:

- `workload`: Collects metrics at the workload level, which represents a group of pods
- `pod`: Collects metrics at the individual pod level

## Installation

{% include /konnect/metering-and-billing/collector-install.md %}