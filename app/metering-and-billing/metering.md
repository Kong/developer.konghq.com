---
title: "Metering"
content_type: reference
description: "Learn how metering works in {{site.konnect_short_name}} {{site.metering_and_billing}}."
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
  - q: Do I need to bill or create plans for my meters?
    a: No, you can use metering on it's own to track customer usage.
---

{{site.metering_and_billing}} provides a real-time event based usage metering to aggregate consumption over time precisely. It also provides deduplication and flexible usage attribution of events and consumers to billable customers.

{{site.metering_and_billing}} metering can help to track various usage:

<!--vale off-->
{% table %}
columns:
  - title: Use Case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: AI Tokens
    description: "Metering AI Tokens consumed by LLMs and AI agents."
  - use_case: API Requests
    description: "Metering API Requests count and duration."
  - use_case: Compute
    description: "Metering runtime of VMs, CPUs, GPUs, etc."
  - use_case: Seats
    description: "Metering number of unique users over sessions."
{% endtable %}
<!--vale on-->

You can meter {{site.base_gateway}} events, like API requests and LLM token usage, as well as generic events.

Each generic meter is comprised from the following attributes:
* Event type: The event type that the meter is tracking. This is used to filter the events that are used to calculate the meter.
* Value type: The JSON path to the property that contains the value to be metered. This is optional when the aggregation is `COUNT`.
* Aggregation type: The [aggregation type](#aggregation-types) to use for the meter.
* Group by: (Optional) A map of JSON paths to group the metered data by.

## Aggregation types

Aggregation types determine how usage data is aggregated for generic meters.

You can configure the following aggregation types for generic meters:
<!--vale off -->
{% table %}
columns:
  - title: Aggregation Type
    key: aggregation_type
  - title: Description
    key: description
rows:
  - aggregation_type: COUNT
    description: "The `COUNT` aggregation type counts the number of events that occur within a specific time window. This is often used for metrics that are inherently countable, such as the number of transactions processed or API calls made. The `COUNT` aggregation type doesn't have the `valueProperty`."
  - aggregation_type: SUM
    description: "The `SUM` aggregation type calculates the total sum of the metered values for a specific time window. `SUM` aggregates over the events `valueProperty`. This is useful for accumulating metrics like total LLM tokens used, total data transferred, or total time spent on a service."
  - aggregation_type: UNIQUE COUNT
    description: "The `UNIQUE_COUNT` aggregation type counts the number of unique events. This is useful when events are unique by a specific field. The `valueProperty` defines the field that makes the ingested event unique. The property's value in the ingested event must be a string or number."
  - aggregation_type: LATEST
    description: "The `LATEST` aggregation type returns the latest value for a specific time window. This is useful for when you track the size of a resource on your own and report periodically the value of it to {{site.metering_and_billing}}. For example disk size, number of resources or seats. The latest aggregation takes the last value reported for the period."
  - aggregation_type: MIN
    description: "The `MIN` aggregation type identifies the minimum value among the metered data points within a specific time window. This is useful for metrics where the lowest value is of interest, such as minimum available storage or minimum response time."
  - aggregation_type: MAX
    description: "The `MAX` aggregation type identifies the maximum value among the metered data points within a specific time window. This is useful for metrics where the highest value is of interest, such as maximum load on a server or maximum transaction value."
{% endtable %}
<!--vale on -->

## Event ingestion

{{site.metering_and_billing}} ingests {{site.konnect_short_name}} API Gateway and LLM events automatically when they're enabled. If you want to configure generic meters, you must use the [CloudEvents](https://cloudevents.io/) format for event ingestion.

As CloudEvents is generic, here are some best practices for defining events in {{site.metering_and_billing}}:
<!--vale off -->
{% table %}
columns:
  - title: Name
    key: name
  - title: Description
    key: description
  - title: Examples
    key: examples
rows:
  - name: "Subject (API Property: `event.subject`)"
    description: "Subjects in {{site.metering_and_billing}} are entities that consume resources you wish to meter. These can range from users, servers, and services to devices. The design of subjects is intentionally generic, enabling flexible application across various metering scenarios. Typically, a subject acts as a unique identifier within your system for a user or customer."
    examples: |
      - Customer ID or User ID
      - Hostname or IP address
      - Service or Application name
      - Device ID
  - name: "Source Property (API Property: `event.source`)"
    description: "The event's source (e.g. the service name). As events are unique by id and source, set different sources if you report the same transaction in multiple applications."
    examples: |
      - `my-service-name`
      - `my-application-name`
  - name: "Choosing Event ID"
    description: "Events are unique by `id` and `source` properties for idempotency. {{site.metering_and_billing}} deduplicates events by uniqueness. Therefore, picking an ID that makes the event unique and resilient to retries is important. For example, in the case of a metering API call, this can be the request ID. You can generate a new UUID if your application doesn't have a unique identifier."
    examples: |
      - HTTP Request ID, typically in headers: `Request-ID`, `X-Request-ID`
      - LLM Chat Completion ID: `id` field in ChatGPT response
      - Workflow ID: like activity ID in Temporal
      - Generate UUID: Node.js, Python, Go
  - name: "Data Property (API Property: `event.data`)"
    description: "{{site.metering_and_billing}} uses CloudEvents format's data property to ingest values and group bys. Be sure to always include in this data property what the meter requires, like value property and group bys."
    examples: |
        - Always include value property for non-`COUNT` aggregations.
        - Always include group by properties.
        - Use string quotation for numbers to preserve precision like `\"123\"`.
{% endtable %}
<!--vale on -->

## Create a meter

To configure a meter in {{site.konnect_short_name}}, do the following:

{% navtabs "create-meter" %}
{% navtab "{{site.base_gateway}} API requests" %}
To meter {{site.base_gateway}} API requests, you need traffic to a [Gateway Service](/gateway/entities/service/#set-up-a-gateway-service) and[Route](/gateway/entities/route/#set-up-a-route).

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. Enable **Gateway**.
1. Select a Gateway
1. Click **Enable Gateway**

{% endnavtab %}
{% navtab "{{site.ai_gateway}} LLM tokens" %}
To meter {{site.ai_gateway}} LLM token usage, you must have the [AI Proxy plugin](/plugins/ai-proxy/) configured.

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. Enable **{{site.ai_gateway}} Tokens**.

You will see `kong_konnect_llm_tokens` available from the list of available meters.
{% endnavtab %}
{% navtab "Generic meters" %}

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. Click **New generic meter**.
1. Configure the meter information as needed.
1. Send a CloudEvent to start collecting meter usage.

{% endnavtab %}
{% endnavtabs %}

## Example meter use cases

The following example show how you can configure meters and usage events for common use cases.

### LLM token usage

{:.info}
> If you want to meter {{site.ai_gateway}} LLM token usage, you can enable the built-in integration to meter usage in one click.

In most cases, AI applications want to count token usage for billing or cost control purposes. As a single AI interaction involves consuming multiple tokens, we define our generic meter with the `SUM` aggregation and report token usage in the data's tokens property. As most LLMs charge differently for input, output and system prompts and different models it makes sense to add model and prompt type to the group by.

{% navtabs "llm-token-usage" %}
{% navtab "Meter example" %}
```yaml
meters:
  - slug: tokens_total
    description: AI Token Usage
    # Filter events by type
    eventType: prompt
    aggregation: SUM
    # JSONPath to parse usage value
    valueProperty: $.tokens
    groupBy:
      # Model used: gpt4-turbo, etc.
      model: $.model
      # Prompt type: input, output, system
      type: $.type
```
{% endnavtab %}
{% navtab "Usage event example" %}
```json
{
  "specversion": "1.0",
  "type": "prompt",
  "id": "00001",
  "time": "2024-01-01T00:00:00.001Z",
  "source": "chat-app",
  "subject": "customer-1",
  "data": {
    "tokens": "123456",
    "model": "gpt4-turbo",
    "type": "output"
  }
}
```
{% endnavtab %}
{% endnavtabs %}

### GPU time

Metering GPUs is a common use-case for customer billing, internal charge back and cost control use cases.

{% navtabs "gpu-time" %}
{% navtab "Meter example" %}
```yaml
meters:
  - slug: gpu_execution_duration_seconds
    description: GPU Time
    eventType: gpu_time
    aggregation: SUM
    valueProperty: $.duration_seconds
    groupBy:
     	hostname: $.hostname
     	region: $.region
      # Type of GPU: e.g. nvidia_A100
 	    gpu_type: $.gpu_type
```
{% endnavtab %}
{% navtab "Usage event example" %}
```json
{
  "specversion": "1.0",
  "type": "gpu_time",
  "id": "00001",
  "time": "2024-01-01T00:00:00.001Z",
  "source": "my-image-generator",
  "subject": "customer-1",
  "data": {
    "duration_seconds": "12345",
    "hostname": "my-hostname",
    "region": "us-east-1",
    "gpu_type": "nvidia_A100"
  }
}
```
{% endnavtab %}
{% endnavtabs %}

### API request count

{:.info}
> If you want to meter {{site.base_gateway}} API requests, you can enable the built-in integration to meter usage in one click.

Products monetizing API usage may want to count the number of requests. With choosing the COUNT aggregation each event will increase the meter by one. For grouping we can add method and route. Note how we report the route template not the actual HTTP path to avoid differences around IDs and dynamic routes.

{% navtabs "request-count" %}
{% navtab "Meter example" %}
```yaml
meters:
  - slug: api_requests_total
    description: API Requests
    # Filter events by type
    eventType: request
    aggregation: COUNT
    groupBy:
      # HTTP Method: GET, POST, etc.
      method: $.method
      # Route: /products/:product_id
      route: $.route
```
{% endnavtab %}
{% navtab "Usage event example" %}
```json
{
  "specversion": "1.0",
  "type": "request",
  "id": "00001",
  "time": "2024-01-01T00:00:00.001Z",
  "source": "api-service",
  "subject": "customer-1",
  "data": {
    "method": "GET",
    "route": "/products/:product_id"
  }
}
```
{% endnavtab %}
{% endnavtabs %}

### API request duration

Similar to the API request, you can decide to track the request duration. This is basically how serverless products like AWS Lambda charge their customers. If you want to track both the request count and duration, you can check out our advanced example.

{% navtabs "request-duration" %}
{% navtab "Meter example" %}
```yaml
meters:
  - slug: api_request_duration
    description: API Request Duration
    # Filter events by type
    eventType: request
    aggregation: SUM
    # JSONPath to parse duration value
    valueProperty: $.duration_seconds
    groupBy:
      # HTTP Method: GET, POST, etc.
      method: $.method
      # Route: /products/:product_id
      route: $.route
```
{% endnavtab %}
{% navtab "Usage event example" %}
```json
{
  "specversion": "1.0",
  "type": "request",
  "id": "00001",
  "time": "2024-01-01T00:00:00.001Z",
  "source": "api-service",
  "subject": "customer-1",
  "data": {
    "method": "GET",
    "route": "/products/:product_id",
    "duration_seconds": "12345"
  }
}
```
{% endnavtab %}
{% endnavtabs %}

### Kubernetes pod execution duration

To track Kubernetes pod execution duration, use our native Kubernetes collector that already reports usage events in this format.

{% navtabs "k8s" %}
{% navtab "Meter example" %}
```yaml
meters:
  - slug: pod_execution_time
    description: Pod Execution Time
    eventType: kube-pod-exec-time
    aggregation: SUM
    valueProperty: $.duration_seconds
    groupBy:
      pod_name: $.pod_name
      pod_namespace: $.pod_namespace
```
{% endnavtab %}
{% navtab "Usage event example" %}
```json
{
  "specversion": "1.0",
  "type": "kube-pod-exec-time",
  "id": "f7f11c82-c415-4325-aec7-572606681817",
  "time": "2024-01-01T00:00:00.001Z",
  "source": "my-app",
  "subject": "customer-1",
  "data": {
    "duration_seconds": "123",
    "pod_name": "pod_name",
    "pod_namespace": "pod_namespace"
  }
}
```
{% endnavtab %}
{% endnavtabs %}

### Counting unique events

In some cases, you may want to count unique events, such as unique sessions. To achieve this, you can use the `UNIQUE_COUNT` aggregation.

{% navtabs "count-unique" %}
{% navtab "Meter example" %}
```yaml
meters:
  - slug: unique_sessions_total
    description: Unique Sessions
    eventType: login
    aggregation: UNIQUE_COUNT
    valueProperty: $.session_id
```
{% endnavtab %}
{% navtab "Usage event example" %}
```json
{
  "specversion": "1.0",
  "type": "auth_check",
  "id": "00001",
  "time": "2024-01-01T00:00:00.001Z",
  "source": "auth-service",
  "subject": "customer-1",
  "data": {
    "session_id": "session_id"
  }
}
```
{% endnavtab %}
{% endnavtabs %}

### Moving multiple meters with one event

In {{site.metering_and_billing}}, a single event can move multiple meters if the event type matches. Let's see an example of tracking an API request's occurrence, execution duration, and network usage.

{% navtabs "moving-meters" %}
{% navtab "Meter example" %}
```yaml
meters:
  - slug: api_requests_total
    description: API Requests
    eventType: request
    aggregation: COUNT
    groupBy:
      method: $.method
      route: $.route
  - slug: api_request_duration_seconds
    description: API Request Duration
    eventType: request
    aggregation: SUM
    valueProperty: $.duration_seconds
    groupBy:
      method: $.method
      route: $.route
  - slug: api_request_ingress_bytes
    description: Request Ingress Bytes
    eventType: request
    aggregation: SUM
    valueProperty: $.ingress_bytes
    groupBy:
      method: $.method
      route: $.route
```
{% endnavtab %}
{% navtab "Usage event example" %}
```json
{
  "specversion": "1.0",
  "type": "request",
  "id": "00001",
  "time": "2024-01-01T00:00:00.001Z",
  "source": "api-service",
  "subject": "customer-1",
  "data": {
    "method": "GET",
    "route": "/products/:product_id",
    "duration_seconds": "123",
    "ingress_bytes": "456",
    "egress_bytes": "789"
  }
}
```
{% endnavtab %}
{% endnavtabs %}

### Counting state changes

In some cases you want to count how many states a workflow or task went through as it progresses for example from `created` to `in_progress` and `success`. The challenge is that if you report a usage event for every state change and track state as a group by answering simple questions like how many workflows were in total would always require filtering by states like `created`, which is easy to forget and error-prone.

The recommended way to model states is to create separate meters per state.

{% navtabs "state-change" %}
{% navtab "Meter example" %}
```yaml
meters:
  - slug: workflow_created
    description: Workflows Created
    eventType: workflow_create
    aggregation: COUNT
    groupBy:
      task_type: $.task_type
  - slug: workflow_succeeded
    description: Workflow Succeeded
    eventType: workflow_success
    aggregation: COUNT
    groupBy:
      task_type: $.task_type
  - slug: workflow_failed
    description: Workflow Failed
    eventType: workflow_fail
    aggregation: COUNT
    groupBy:
      task_type: $.task_type
```
{% endnavtab %}
{% navtab "Usage event example" %}
```json
[
  {
    "specversion": "1.0",
    "type": "workflow_create",
    "id": "00001",
    "time": "2024-01-01T00:00:00.001Z",
    "source": "task-queue",
    "subject": "task-1",
    "data": {
      "type": "image-generate"
    }
  },
  {
    "specversion": "1.0",
    "type": "workflow_success",
    "id": "00001",
    "time": "2024-01-01T00:00:00.001Z",
    "source": "task-queue",
    "subject": "task-1",
    "data": {
      "task_type": "image-generate"
    }
  }
]
```
{% endnavtab %}
{% endnavtabs %}

### Translate AI demo

Example meters for the imaginary Translate AI product that translates PDF documents between languages. For example, you can use an LLM like GPT-4 to translate a PDF document from German to English. For this use case, you want to track the number of pages, words, and LLM tokens used for each translation.

{% navtabs "ai-demo" %}
{% navtab "Meter example" %}
Meter to count the number of pages translated:
```yaml
meters:
  - slug: pages_total
    description: Number of pages translated
    eventType: translate
    aggregation: SUM
    valueProperty: $.pages
```

Meter to count the number of words translated:
```yaml
meters:
  - slug: words_total
    description: Number of words translated
    eventType: translate
    aggregation: SUM
    valueProperty: $.words
```

Meter to count the number of LLM tokens used:
```yaml
meters:
  - slug: tokens_total
    description: Number of LLM tokens used
    eventType: translate
    aggregation: SUM
    valueProperty: $.tokens
    groupBy:
      model: $.model
```
{% endnavtab %}
{% navtab "Usage event example" %}
```json
{
  "specversion": "1.0",
  "id": "0b8bb322-90c2-4b46-b541-0380bac1b9a5",
  "source": "myapp",
  "type": "translate",
  "subject": "customer-123",
  "datacontenttype": "application/json",
  "time": "2025-02-18T16:37:44Z",
  "data": {
    "model": "gpt-4",
    "pages": 23,
    "tokens": 10200,
    "words": 6912
  }
}
```
{% endnavtab %}
{% endnavtabs %}
