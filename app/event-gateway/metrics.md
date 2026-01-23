---
# **Auto-generated** - Do not edit manually. See https://github.com/kong-gateway/event-gateway/blob/main/api/metrics.md

title: "{{site.event_gateway}} metrics"
content_type: reference
layout: reference

description: Reference for all metrics exposed by {{site.event_gateway}}.
  
related_resources:
  - text: "{{site.event_gateway}}"
    url: /event-gateway/
  - text: Set up observability for {{site.event_gateway_short}}
    url: /how-to/event-gateway/configure-observability-with-otel/

products:
    - event-gateway

breadcrumbs:
  - /event-gateway/
---

<!--vale off-->

## Kafka

### `kong_keg_kafka_acl_attempts_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** Counts the results of every ACL attempt

**Labels:**

- `resource_type`: The type of Kafka resource being accessed (Possible values: `transactional_id`, `group`, `topic`, `cluster`)
- `result`: The result of the ACL check (allowed or denied) (Possible values: `allowed`, `denied`)

### `kong_keg_kafka_backend_connection_error_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of connection errors to the backend cluster

**Labels:**

- `origin`: The origin of the connection error (Possible values: `io`, `peer`, `local`)

### `kong_keg_kafka_backend_roundtrip_duration_seconds`

|Type      |Unit      |
|:---------|:---------|
|Histogram |`seconds` |


**Description:** The time spent communicating with backend cluster (send request and receive response)

**Labels:**

No labels documented.

### `kong_keg_kafka_connections_active`

|Type      |Unit      |
|:---------|:---------|
|Gauge     |N/A       |


**Description:** The number of active proxied connections

**Labels:**

No labels documented.

### `kong_keg_kafka_metadata_update_duration_seconds`

|Type      |Unit      |
|:---------|:---------|
|Histogram |`seconds` |


**Description:** The time to update the metadata from the backend broker

**Labels:**

No labels documented.

### `kong_keg_kafka_namespace_topic_conflict`

|Type      |Unit      |
|:---------|:---------|
|Gauge     |N/A       |


**Description:** Indicates whether the namespace topic mapping encountered conflicts (1) or not (0).

**Labels:**

No labels documented.

### `kong_keg_kafka_policy_invocation_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of policy invocation for policies. This includes both successful and failed invocations

**Labels:**

- `result`: The result of the operation (success or failure) (Possible values: `success`, `fail`)

### `kong_keg_kafka_policy_invocation_duration_ms`

|Type      |Unit      |
|:---------|:---------|
|Histogram |`milliseconds`|


**Description:** The time to process a policy

**Labels:**

No labels documented.

### `kong_keg_kafka_proxy_total_duration_seconds`

|Type      |Unit      |
|:---------|:---------|
|Histogram |`seconds` |


**Description:** The end-to-end time for the entire proxy operation

**Labels:**

No labels documented.

### `kong_keg_kafka_request_processing_duration_ms`

|Type      |Unit      |
|:---------|:---------|
|Histogram |`milliseconds`|


**Description:** The time spent processing the received request before forwarding it to the backend cluster

**Labels:**

No labels documented.

### `kong_keg_kafka_request_received_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of requests coming from the client

**Labels:**

No labels documented.

### `kong_keg_kafka_request_sent_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of requests sent to the backend broker

**Labels:**

No labels documented.

### `kong_keg_kafka_response_processing_duration_ms`

|Type      |Unit      |
|:---------|:---------|
|Histogram |`milliseconds`|


**Description:** The time spent processing the received response before forwarding it to the client

**Labels:**

No labels documented.

### `kong_keg_kafka_response_received_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of responses received from the backend broker

**Labels:**

No labels documented.

### `kong_keg_kafka_response_received_error_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of response messages received from the backend that contain at least one error. The error_code label represents the lowest error in the response

**Labels:**

- `error_code`: The lowest error code in the response

### `kong_keg_kafka_response_sent_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of responses sent by the proxy to the client

**Labels:**

No labels documented.

### `kong_keg_kafka_response_sent_error_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of response messages sent back to the client that contain at least one error.

**Labels:**

- `error_code`: The lowest error code in the response

### `kong_keg_kafka_schema_validation_attempt_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of attempts to validate schema. This includes both successful and failed calls

**Labels:**

- `result`: The result of the operation (success or failure) (Possible values: `success`, `fail`)

## Konnect

### `kong_keg_konnect_analytics_bytes_sent_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** Total number of analytics bytes sent in binary websocket messages to the analytics endpoint

**Labels:**

No labels documented.

### `kong_keg_konnect_analytics_messages_sent_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** Total number of analytics messages sent to the analytics endpoint

**Labels:**

No labels documented.

### `kong_keg_konnect_analytics_queue_dropped_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** Number of events dropped from the queue because the max queue size was reached

**Labels:**

No labels documented.

### `kong_keg_konnect_analytics_queue_event_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** Total number of events added to the queue

**Labels:**

No labels documented.

### `kong_keg_konnect_analytics_websocket_error_count`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** Number of times an error occurred on the analytics websocket connection while sending or receiving messages

**Labels:**

No labels documented.

### `kong_keg_konnect_request_count`

|Type      |Unit      |
|:---------|:---------|
|Histogram |N/A       |


**Description:** The time to update the metadata from the upstream broker

**Labels:**

- `konnect_api`: The konnect api operation being performed (Possible values: `fetch_config`, `update_dp_state`)
- `status_code`: The status code of an http response (Possible values: `2xx`, `3xx`, `4xx`, `5xx`)

### `kong_keg_konnect_request_duration_seconds`

|Type      |Unit      |
|:---------|:---------|
|Histogram |`seconds` |


**Description:** The time sending and receiving the response to a request to the upstream broker

**Labels:**

- `konnect_api`: The konnect api operation being performed (Possible values: `fetch_config`, `update_dp_state`)

## Lifecycle

### `kong_keg_lifecycle_component_ready`

|Type      |Unit      |
|:---------|:---------|
|Gauge     |N/A       |


**Description:** Is a specific component ready, the global service being ready implies that all its components are ready

**Labels:**

- `component`: The component name

### `kong_keg_lifecycle_service_healthy`

|Type      |Unit      |
|:---------|:---------|
|Gauge     |N/A       |


**Description:** Is the service healthy

**Labels:**

No labels documented.

### `kong_keg_lifecycle_service_ready`

|Type      |Unit      |
|:---------|:---------|
|Gauge     |N/A       |


**Description:** Is the service ready

**Labels:**

No labels documented.

## Listener

### `kong_keg_listener_connections_limit`

|Type      |Unit      |
|:---------|:---------|
|Gauge     |N/A       |


**Description:** The number of allowed connections to the listener

**Labels:**

No labels documented.

## Common Labels

The following labels are commonly used across multiple metrics:

### Resource Identification

- `topic`: Kafka topic name
- `listener`: Listener identifier
- `policy`: Policy identifier

### Konnect Integration

- `policy_konnect_type`: Policy type in Konnect
- `policy_konnect_id`: Policy ID in Konnect
- `policy_konnect_name`: Policy name in Konnect
- `listener_konnect_id`: Listener ID in Konnect
- `listener_konnect_name`: Listener name in Konnect

### Operations

- `chain_type`: Type of policy chain (e.g., produce, consume)
- `result`: Result of operation (success, fail, allowed, denied)
- `part`: Part being processed (key, value)
- `resource_type`: ACL resource type (transactional_id, group, topic, cluster)
- `origin`: Connection error origin (io, peer, local)

### HTTP/Network

- `status_code`: HTTP status code
- `error_code`: Kafka error code
- `api_key`: Kafka API key

<!--vale on-->