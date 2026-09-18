---
# **Auto-generated** - Do not edit manually. See https://github.com/kong-gateway/event-gateway/blob/main/api/metrics.md

title: "{{site.event_gateway}} metrics"

description: Reference for all metrics exposed by {{site.event_gateway}}.

related_resources:
  - text: "{{site.event_gateway}}"
    url: /event-gateway/
  - text: Set up observability for {{site.event_gateway_short}}
    url: /how-to/event-gateway/configure-observability-with-otel/
  - text: "{{site.event_gateway}} headers"
    url: /event-gateway/headers/
---

<!--vale off-->

Units follow the case-sensitive [UCUM](https://ucum.org/ucum) form (e.g. `s`, `By`).

## `http.client.request.duration`

|Type|Unit|
|:---|:---|
|Histogram|`s`|

Duration of outbound HTTP client requests.

**Labels:**

- `kong.http.client.name`: Logical name of the outbound HTTP client, set by the caller to tell multiple clients apart.
- `http.request.method`: HTTP request method. Any method outside the known set maps to `_OTHER`. (one of `CONNECT`, `DELETE`, `GET`, `HEAD`, `OPTIONS`, `PATCH`, `POST`, `PUT`, `TRACE`)
- `server.address`: Host name of the server the request was sent to.
- `server.port`: Port of the server the request was sent to.
- `url.scheme`: URL scheme of the request, e.g. `https`. (one of `http`, `https`)
- `network.protocol.version`: Negotiated HTTP version of the response. Absent when the request did not succeed. (one of `1.0`, `1.1`, `2`, `3`)
- `http.response.status_code`: The status code of an http response. Absent if a request did not succeed.
- `error.type`: The error type encountered on executing http request. Absent if a request was successful. (one of `timeout`, `connect`, `unknown`)

## `kong.capability_manager.batches_sent`

|Type|Unit|
|:---|:---|
|Counter|`{batch}`|

Total number of signal batches sent to the client.

**Labels:**

- `kong.control_plane`: The Control Plane URL a source is polling.

## `kong.capability_manager.channel_send_retries`

|Type|Unit|
|:---|:---|
|Counter|`{retry}`|

Total number of retries sending batches to the client channel (channel full).

**Labels:**

- `kong.control_plane`: The Control Plane URL a source is polling.

## `kong.capability_manager.client_processing_duration`

|Type|Unit|
|:---|:---|
|Histogram|`s`|

Time between sending batch to client and receiving acknowledgment.

**Labels:**

- `kong.control_plane`: The Control Plane URL a source is polling.

## `kong.capability_manager.consecutive_failures`

|Type|Unit|
|:---|:---|
|Gauge|`{failure}`|

Current number of consecutive poll failures.

**Labels:**

- `kong.control_plane`: The Control Plane URL a source is polling.

## `kong.capability_manager.signals_received`

|Type|Unit|
|:---|:---|
|Counter|`{signal}`|

Total number of signals received from the control plane (before filtering).

**Labels:**

- `kong.control_plane`: The Control Plane URL a source is polling.
- `kong.capability.type`: The capability type (e.g. `config_sync`).

## `kong.capability_manager.signals_sent`

|Type|Unit|
|:---|:---|
|Counter|`{signal}`|

Total number of signals sent to the client (after filtering).

**Labels:**

- `kong.control_plane`: The Control Plane URL a source is polling.

## `kong.core.task_registry.tracked_tasks`

|Type|Unit|
|:---|:---|
|Gauge|`{task}`|

Number of active tasks currently tracked by the task tracker.

**Labels:**

_None._

## `kong.dataplane.lifecycle.component.ready`

|Type|Unit|
|:---|:---|
|Gauge|`1`|

Is a specific component ready; the service being ready implies all components are ready.

**Labels:**

- `kong.dataplane.component`: The component name

## `kong.dataplane.lifecycle.service.healthy`

|Type|Unit|
|:---|:---|
|Gauge|`1`|

Is the service healthy.

**Labels:**

_None._

## `kong.dataplane.lifecycle.service.ready`

|Type|Unit|
|:---|:---|
|Gauge|`1`|

Is the service ready.

**Labels:**

_None._

## `kong.keg.config.errors`

|Type|Unit|
|:---|:---|
|Counter|`{error}`|

Count of errors when loading the config received from the control plane.

**Labels:**

_None._

## `kong.keg.config.loaded`

|Type|Unit|
|:---|:---|
|Gauge|`1`|

Version number of the configuration loaded from the control plane. Updated each time the control plane pushes a new config.

**Labels:**

_None._

## `kong.keg.kafka.acl.attempts`

|Type|Unit|
|:---|:---|
|Counter|`{attempt}`|

Counts the results of every ACL attempt.

**Labels:**

- `kong.keg.acl.resource_type`: The type of Kafka resource being accessed (one of `transactional_id`, `group`, `topic`, `cluster`)
- `kong.keg.result`: The result of the ACL check (allowed or denied) (one of `allowed`, `denied`)
- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.auth.virtual_cluster.processing.duration`

|Type|Unit|
|:---|:---|
|Histogram|`s`|

The time spent validating client credentials against virtual cluster auth rules. Passthrough rules are always considered successful even if the backend cluster rejects the authentication.

**Labels:**

- `kong.keg.auth.mechanism`: The authentication mechanism used by the client
- `kong.keg.result`: The result of the operation (success or failure) (one of `success`, `fail`)
- `kong.keg.auth.mediation`: How the proxy mediates authentication between the client and the backend cluster. Empty when no rule matched the requested mechanism. (one of `passthrough`, `validate_forward`, `terminate`, ``)
- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.backend.connection.errors`

|Type|Unit|
|:---|:---|
|Counter|`{connection}`|

The number of connection errors to the backend cluster.

**Labels:**

- `kong.keg.connection.error.origin`: The origin of the connection error (one of `io`, `peer`, `local`)

## `kong.keg.kafka.backend.roundtrip.duration`

|Type|Unit|
|:---|:---|
|Histogram|`s`|

The time spent communicating with backend cluster (send request and receive response).

**Labels:**

- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.connection.errors`

|Type|Unit|
|:---|:---|
|Counter|`{connection}`|

The number of proxied connections that resulted in an error.

**Labels:**

- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.listener.id`: The Konnect listener identifier
- `kong.konnect.listener.name`: The Konnect listener name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.connections`

|Type|Unit|
|:---|:---|
|Gauge|`{connection}`|

The number of active proxied connections.

**Labels:**

- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.listener.id`: The Konnect listener identifier
- `kong.konnect.listener.name`: The Konnect listener name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.decrypt.attempts`

> **Deprecated.** Use `kong.keg.kafka.policy.invocations` instead.

|Type|Unit|
|:---|:---|
|Counter|`{attempt}`|

The number of attempts to decrypt records. This includes both successful and failed calls

**Labels:**

- `kong.keg.result`: The result of the operation (success or failure) (one of `success`, `fail`)
- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.encrypt.attempts`

> **Deprecated.** Use `kong.keg.kafka.policy.invocations` instead.

|Type|Unit|
|:---|:---|
|Counter|`{attempt}`|

The number of attempts to encrypt records. This includes both successful and failed calls

**Labels:**

- `kong.keg.result`: The result of the operation (success or failure) (one of `success`, `fail`)
- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.kscheme.attempts`

> **Deprecated.** Use `kong.keg.kafka.policy.invocations` instead.

|Type|Unit|
|:---|:---|
|Counter|`{attempt}`|

The number of attempts to run kscheme scripts. This includes both successful and failed calls

**Labels:**

- `kong.keg.result`: The result of the operation (success or failure) (one of `success`, `fail`)
- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.metadata.update.duration`

|Type|Unit|
|:---|:---|
|Histogram|`s`|

The time to update the metadata from the backend broker.

**Labels:**

- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.namespace.topic.conflict`

|Type|Unit|
|:---|:---|
|Gauge|`1`|

Indicates whether the namespace topic mapping encountered conflicts (1) or not (0).

**Labels:**

- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name

## `kong.keg.kafka.policy.condition.failures`

|Type|Unit|
|:---|:---|
|Counter|`{failure}`|

The number of times the policy condition failed to execute due to an error.

**Labels:**

_None._

## `kong.keg.kafka.policy.invocation.duration`

|Type|Unit|
|:---|:---|
|Histogram|`s`|

The time to process a policy.

**Labels:**

- `kong.keg.failure_mode`: The configured policy failure mode (one of `error`, `reject`, `passthrough`, `mark`, `skip`)
- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.policy.invocations`

|Type|Unit|
|:---|:---|
|Counter|`{invocation}`|

The number of policy invocation for policies. This includes both successful and failed invocations.

**Labels:**

- `kong.keg.failure_mode`: The configured policy failure mode (one of `error`, `reject`, `passthrough`, `mark`, `skip`)
- `kong.keg.result`: The result of the operation (success or failure) (one of `success`, `fail`)
- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.proxy.duration`

|Type|Unit|
|:---|:---|
|Histogram|`s`|

The end-to-end time for the entire proxy operation.

**Labels:**

- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.request.processing.duration`

|Type|Unit|
|:---|:---|
|Histogram|`s`|

The time spent processing the received request before forwarding it to the backend cluster.

**Labels:**

- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.request.received`

|Type|Unit|
|:---|:---|
|Counter|`{request}`|

The number of requests coming from the client.

**Labels:**

- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.request.sent`

|Type|Unit|
|:---|:---|
|Counter|`{request}`|

The number of requests sent to the backend broker.

**Labels:**

- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.response.processing.duration`

|Type|Unit|
|:---|:---|
|Histogram|`s`|

The time spent processing the received response before forwarding it to the client.

**Labels:**

- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.response.received`

|Type|Unit|
|:---|:---|
|Counter|`{response}`|

The number of responses received from the backend broker.

**Labels:**

- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.response.received.errors`

> **Deprecated.** Use `kong.keg.kafka.response.received_errors` instead: the old name collided with `kong.keg.kafka.response.received` as a metric namespace.

|Type|Unit|
|:---|:---|
|Counter|`{response}`|

The number of response messages received from the backend that contain at least one error. The error_code label represents the lowest error in the response.

**Labels:**

- `kong.keg.kafka.error_code`: The lowest error code in the response
- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.response.received_errors`

|Type|Unit|
|:---|:---|
|Counter|`{response}`|

The number of response messages received from the backend that contain at least one error. The error_code label represents the lowest error in the response.

**Labels:**

- `kong.keg.kafka.error_code`: The lowest error code in the response
- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.response.sent`

|Type|Unit|
|:---|:---|
|Counter|`{response}`|

The number of responses sent by the proxy to the client.

**Labels:**

- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.response.sent.errors`

> **Deprecated.** Use `kong.keg.kafka.response.sent_errors` instead: the old name collided with `kong.keg.kafka.response.sent` as a metric namespace.

|Type|Unit|
|:---|:---|
|Counter|`{response}`|

The number of response messages sent back to the client that contain at least one error.

**Labels:**

- `kong.keg.kafka.error_code`: The lowest error code in the response
- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.response.sent_errors`

|Type|Unit|
|:---|:---|
|Counter|`{response}`|

The number of response messages sent back to the client that contain at least one error.

**Labels:**

- `kong.keg.kafka.error_code`: The lowest error code in the response
- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.schema.validation.attempts`

> **Deprecated.** Use `kong.keg.kafka.policy.invocations` instead.

|Type|Unit|
|:---|:---|
|Counter|`{attempt}`|

The number of attempts to validate schema. This includes both successful and failed calls

**Labels:**

- `kong.keg.record.part`: The part of the record (key or value) (one of `key`, `value`)
- `kong.keg.result`: The result of the operation (success or failure) (one of `success`, `fail`)
- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name

## `kong.keg.kafka.topic_alias.conflict`

|Type|Unit|
|:---|:---|
|Gauge|`1`|

Emitted (value=1) when a topic alias shadows a physical topic name.

**Labels:**

- `kong.keg.kafka.topic_alias.name`: The alias name that caused the conflict
- `kong.keg.kafka.topic_alias.shadowed_topic`: The physical topic name that is shadowed by the alias
- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name

## `kong.keg.konnect.analytics.bytes.sent`

> **Deprecated.** Use `kong.keg.konnect.analytics.sent` instead: the standard unit `By` belongs in metric metadata, not in the name.

|Type|Unit|
|:---|:---|
|Counter|`By`|

Total number of analytics bytes sent in binary websocket messages to the analytics endpoint

**Labels:**

_None._

## `kong.keg.konnect.analytics.messages.sent`

|Type|Unit|
|:---|:---|
|Counter|`{message}`|

Total number of analytics messages sent to the analytics endpoint.

**Labels:**

_None._

## `kong.keg.konnect.analytics.queue.dropped`

|Type|Unit|
|:---|:---|
|Counter|`{event}`|

Number of events dropped from the queue because the max queue size was reached.

**Labels:**

_None._

## `kong.keg.konnect.analytics.queue.events`

|Type|Unit|
|:---|:---|
|Counter|`{event}`|

Total number of events added to the queue.

**Labels:**

_None._

## `kong.keg.konnect.analytics.sent`

|Type|Unit|
|:---|:---|
|Counter|`By`|

Total bytes sent in binary websocket messages to the analytics endpoint.

**Labels:**

_None._

## `kong.keg.konnect.analytics.websocket.errors`

|Type|Unit|
|:---|:---|
|Counter|`{error}`|

Number of times an error occurred on the analytics websocket connection while sending or receiving messages.

**Labels:**

_None._

## `kong.keg.konnect.request.duration`

> **Deprecated.** Use `http.client.request.duration` with the `kong.http.client.name` label instead.

|Type|Unit|
|:---|:---|
|Histogram|`s`|

The time sending and receiving the response to a request to the Konnect control plane.

**Labels:**

- `kong.keg.konnect.api`: The konnect api operation being performed (one of `fetch_config`, `update_dp_state`)
- `error.type`: The error type encountered on executing http request. Absent if a request was successful. (one of `timeout`, `connect`, `unknown`)
- `http.response.status_code`: The status code of an http response. Absent if a request did not succeed.

## `kong.keg.lifecycle.component.ready`

> **Deprecated.** Use `kong.dataplane.lifecycle.component.ready` instead.

|Type|Unit|
|:---|:---|
|Gauge|`1`|

Is a specific component ready; the service being ready implies all components are ready.

**Labels:**

- `kong.keg.component`: The component name

## `kong.keg.lifecycle.service.healthy`

> **Deprecated.** Use `kong.dataplane.lifecycle.service.healthy` instead.

|Type|Unit|
|:---|:---|
|Gauge|`1`|

Is the service healthy.

**Labels:**

_None._

## `kong.keg.lifecycle.service.ready`

> **Deprecated.** Use `kong.dataplane.lifecycle.service.ready` instead.

|Type|Unit|
|:---|:---|
|Gauge|`1`|

Is the service ready.

**Labels:**

_None._

## `kong.keg.listener.connections.limit`

|Type|Unit|
|:---|:---|
|Gauge|`{connection}`|

The number of allowed connections to the listener.

**Labels:**

_None._

## `kong.keg.request_rule.condition.failures`

|Type|Unit|
|:---|:---|
|Counter|`{failure}`|

The number of times a request rule expression failed to execute due to an error.

**Labels:**

- `kong.keg.kafka.request`: The type of the Kafka request
- `kong.konnect.policy.id`: The Konnect policy identifier
- `kong.konnect.policy.name`: The Konnect policy name
- `kong.keg.component`: The component name

## `kong.keg.request_rule.evaluations`

|Type|Unit|
|:---|:---|
|Counter|`{evaluation}`|

Counts the result of every request rule evaluation. Incremented once per evaluated rule.

**Labels:**

- `kong.keg.request_rule.result`: The result of the request rule evaluation (pass or violation) (one of `pass`, `violation`)
- `kong.keg.request_rule.action`: The configured action of the evaluated rule (one of `reject`, `passthrough`)
- `kong.keg.kafka.request`: The type of the Kafka request
- `kong.konnect.policy.id`: The Konnect policy identifier
- `kong.konnect.policy.name`: The Konnect policy name
- `kong.konnect.virtual_cluster.id`: The Konnect virtual cluster identifier
- `kong.konnect.virtual_cluster.name`: The Konnect virtual cluster name
- `kong.konnect.backend_cluster.id`: The Konnect backend cluster identifier
- `kong.konnect.backend_cluster.name`: The Konnect backend cluster name
- `kong.keg.component`: The component name
