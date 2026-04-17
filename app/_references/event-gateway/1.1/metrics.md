---
# **Auto-generated** - Do not edit manually. See https://github.com/kong-gateway/event-gateway/blob/main/api/metrics.md

title: "{{site.event_gateway}} metrics"

description: Reference for all metrics exposed by {{site.event_gateway}}.

related_resources:
  - text: "{{site.event_gateway}}"
    url: /event-gateway/
  - text: Set up observability for {{site.event_gateway_short}}
    url: /how-to/event-gateway/configure-observability-with-otel/
---

<!--vale off-->

## Config

### `kong.keg.config.errors`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** Count of errors when loading the config received from the control plane

**Labels:**

No labels documented.

### `kong.keg.config.loaded`

|Type      |Unit      |
|:---------|:---------|
|Gauge     |N/A       |


**Description:** The version of the configuration loaded from the control plane

**Labels:**

No labels documented.

## Kafka

### `kong.keg.kafka.acl.attempts`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** Counts the results of every ACL attempt

**Labels:**

- `kong.keg.acl.resource_type`: The type of Kafka resource being accessed (Possible values: `transactional_id`, `group`, `topic`, `cluster`)
- `kong.keg.result`: The result of the ACL check (allowed or denied) (Possible values: `allowed`, `denied`)

### `kong.keg.kafka.backend.connection.errors`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of connection errors to the backend cluster

**Labels:**

- `kong.keg.connection.error.origin`: The origin of the connection error (Possible values: `io`, `peer`, `local`)

### `kong.keg.kafka.backend.roundtrip.duration`

|Type      |Unit      |
|:---------|:---------|
|Histogram |`seconds` |


**Description:** The time spent communicating with backend cluster (send request and receive response)

**Labels:**

No labels documented.

### `kong.keg.kafka.connection.errors`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of proxied connections that resulted in an error

**Labels:**

No labels documented.

### `kong.keg.kafka.connections`

|Type      |Unit      |
|:---------|:---------|
|Gauge     |N/A       |


**Description:** The number of active proxied connections

**Labels:**

No labels documented.

### `kong.keg.kafka.decrypt.attempts`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of attempts to decrypt records. This includes both successful and failed calls

**Labels:**

- `kong.keg.result`: The result of the operation (success or failure) (Possible values: `success`, `fail`)

### `kong.keg.kafka.encrypt.attempts`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of attempts to encrypt records. This includes both successful and failed calls

**Labels:**

- `kong.keg.result`: The result of the operation (success or failure) (Possible values: `success`, `fail`)

### `kong.keg.kafka.kscheme.attempts`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of attempts to run kscheme scripts. This includes both successful and failed calls

**Labels:**

- `kong.keg.result`: The result of the operation (success or failure) (Possible values: `success`, `fail`)

### `kong.keg.kafka.metadata.update.duration`

|Type      |Unit      |
|:---------|:---------|
|Histogram |`seconds` |


**Description:** The time to update the metadata from the backend broker

**Labels:**

No labels documented.

### `kong.keg.kafka.namespace.topic.conflict`

|Type      |Unit      |
|:---------|:---------|
|Gauge     |N/A       |


**Description:** Indicates whether the namespace topic mapping encountered conflicts (1) or not (0).

**Labels:**

No labels documented.

### `kong.keg.kafka.policy.condition.failures`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of times the policy condition failed to execute due to an error

**Labels:**

No labels documented.

### `kong.keg.kafka.policy.invocation.duration`

|Type      |Unit      |
|:---------|:---------|
|Histogram |`seconds` |


**Description:** The time to process a policy

**Labels:**

No labels documented.

### `kong.keg.kafka.policy.invocations`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of policy invocation for policies. This includes both successful and failed invocations

**Labels:**

- `kong.keg.result`: The result of the operation (success or failure) (Possible values: `success`, `fail`)

### `kong.keg.kafka.proxy.duration`

|Type      |Unit      |
|:---------|:---------|
|Histogram |`seconds` |


**Description:** The end-to-end time for the entire proxy operation

**Labels:**

No labels documented.

### `kong.keg.kafka.request.processing.duration`

|Type      |Unit      |
|:---------|:---------|
|Histogram |`seconds` |


**Description:** The time spent processing the received request before forwarding it to the backend cluster

**Labels:**

No labels documented.

### `kong.keg.kafka.request.received`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of requests coming from the client

**Labels:**

No labels documented.

### `kong.keg.kafka.request.sent`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of requests sent to the backend broker

**Labels:**

No labels documented.

### `kong.keg.kafka.response.processing.duration`

|Type      |Unit      |
|:---------|:---------|
|Histogram |`seconds` |


**Description:** The time spent processing the received response before forwarding it to the client

**Labels:**

No labels documented.

### `kong.keg.kafka.response.received`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of responses received from the backend broker

**Labels:**

No labels documented.

### `kong.keg.kafka.response.received.errors`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of response messages received from the backend that contain at least one error. The error_code label represents the lowest error in the response

**Labels:**

- `kong.keg.kafka.error_code`: The lowest error code in the response

### `kong.keg.kafka.response.sent`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of responses sent by the proxy to the client

**Labels:**

No labels documented.

### `kong.keg.kafka.response.sent.errors`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of response messages sent back to the client that contain at least one error.

**Labels:**

- `kong.keg.kafka.error_code`: The lowest error code in the response

### `kong.keg.kafka.schema.validation.attempts`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** The number of attempts to validate schema. This includes both successful and failed calls

**Labels:**

- `kong.keg.record.part`: The part of the record (key or value) (Possible values: `key`, `value`)
- `kong.keg.result`: The result of the operation (success or failure) (Possible values: `success`, `fail`)

## Konnect

### `kong.keg.konnect.analytics.bytes.sent`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** Total number of analytics bytes sent in binary websocket messages to the analytics endpoint

**Labels:**

No labels documented.

### `kong.keg.konnect.analytics.messages.sent`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** Total number of analytics messages sent to the analytics endpoint

**Labels:**

No labels documented.

### `kong.keg.konnect.analytics.queue.dropped`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** Number of events dropped from the queue because the max queue size was reached

**Labels:**

No labels documented.

### `kong.keg.konnect.analytics.queue.events`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** Total number of events added to the queue

**Labels:**

No labels documented.

### `kong.keg.konnect.analytics.websocket.errors`

|Type      |Unit      |
|:---------|:---------|
|Counter   |N/A       |


**Description:** Number of times an error occurred on the analytics websocket connection while sending or receiving messages

**Labels:**

No labels documented.

### `kong.keg.konnect.request.duration`

|Type      |Unit      |
|:---------|:---------|
|Histogram |`seconds` |


**Description:** The time sending and receiving the response to a request to the upstream broker

**Labels:**

- `kong.keg.konnect.api`: The konnect api operation being performed (Possible values: `fetch_config`, `update_dp_state`)
- `error.type`: The error type encountered on executing http request. Absent if a request was successful. (Possible values: `timeout`, `connect`, `unknown`)
- `http.response.status_code`: The status code of an http response. Absent if a request did not succeed.

## Lifecycle

### `kong.keg.lifecycle.component.ready`

|Type      |Unit      |
|:---------|:---------|
|Gauge     |N/A       |


**Description:** Is a specific component ready, the global service being ready implies that all its components are ready

**Labels:**

- `kong.keg.component`: The component name

### `kong.keg.lifecycle.service.healthy`

|Type      |Unit      |
|:---------|:---------|
|Gauge     |N/A       |


**Description:** Is the service healthy

**Labels:**

No labels documented.

### `kong.keg.lifecycle.service.ready`

|Type      |Unit      |
|:---------|:---------|
|Gauge     |N/A       |


**Description:** Is the service ready

**Labels:**

No labels documented.

## Listener

### `kong.keg.listener.connections.limit`

|Type      |Unit      |
|:---------|:---------|
|Gauge     |N/A       |


**Description:** The number of allowed connections to the listener

**Labels:**

No labels documented.

## Common Labels

The following labels are commonly used across multiple metrics:

### Resource Identification

- `messaging.destination.name`: Kafka topic name
### Konnect Integration

- `kong.keg.policy.type`: Policy type in Konnect
- `kong.konnect.policy.id`: Policy ID in Konnect
- `kong.konnect.policy.name`: Policy name in Konnect
- `kong.konnect.listener.id`: Listener ID in Konnect
- `kong.konnect.listener.name`: Listener name in Konnect
### Operations

- `kong.keg.policy.chain_type`: Type of policy chain (e.g., produce, consume)
- `result`: Result of operation (success, fail, allowed, denied)
- `kong.keg.record.part`: Part being processed (key, value)

- `origin`: Connection error origin (io, peer, local)

### HTTP/Network

- `status_code`: HTTP status code
- `error_code`: Kafka error code
- `api_key`: Kafka API key

<!--vale on-->