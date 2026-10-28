---
title: "{{site.event_gateway_short}} breaking changes and known issues"
content_type: reference
layout: reference
breadcrumbs:
  - /event-gateway/
products:
    - event-gateway

works_on:
    - konnect

tags:
    - upgrade
    - versioning

description: "Review {{site.event_gateway_short}} version breaking changes before upgrading."

related_resources:
  - text: Upgrading {{site.event_gateway_short}}
    url: /event-gateway/upgrade/
  - text: "{{site.event_gateway_short}} known limitations"
    url: /event-gateway/known-limitations/
  - text: "{{site.event_gateway_short}} version support"
    url: /event-gateway/version-support-policy/
  - text: "{{site.event_gateway_short}} changelog"
    url: /event-gateway/changelog/
  - text: "Verify {{site.event_gateway_short}} image signatures and attestations"
    url: /event-gateway/verify-image-signatures-and-attestations/
---

Before upgrading, review any configuration or breaking changes in the version you're upgrading to and prior versions that
affect your current installation.

## 1.3.x breaking changes

Review the [changelog](/event-gateway/changelog/#1-3-0) for all the changes in this release.

### 1.3.0

Breaking changes in the {{site.event_gateway_short}} 1.3.0 release.

#### Debug and profiling endpoints disabled by default

The debug and profiling endpoints (`/debug/pprof/*`) are disabled by default and no longer share the health and metrics listener.
Because the profiling endpoints now have their own listener, you can restrict access to them without affecting health checks and metrics scraping.

To enable them, set `KEG__RUNTIME__DEBUG_LISTENER_ADDRESS_PORT` to the address and port the dedicated listener should use, for example `0.0.0.0:8081`.
The `KEG__ENABLE_DEBUG_ENDPOINTS` boolean has been removed.

For more information, see the [{{site.event_gateway_short}} configuration reference](/event-gateway/configuration/).

#### Metrics renamed

The following metrics and labels have been renamed.
{{site.event_gateway_short}} still emits the old names as deprecated aliases during the migration window, so update your dashboards and alerts to the new names.

{% table %}
columns:
  - title: Old name
    key: old
  - title: New name
    key: new
rows:
  - old: "`kong.keg.lifecycle.*`"
    new: "`kong.dataplane.lifecycle.*`"
  - old: "`kong.keg.component`"
    new: "`kong.dataplane.component`"
  - old: "`kong.keg.kafka.response.received.errors`"
    new: "`kong.keg.kafka.response.received_errors`"
  - old: "`kong.keg.kafka.response.sent.errors`"
    new: "`kong.keg.kafka.response.sent_errors`"
  - old: "`kong.keg.konnect.analytics.*`"
    new: "`kong.dataplane.analytics.*`"
{% endtable %}

The Kafka response error metrics were renamed because the old names were ambiguous.

The following metrics are deprecated:

{% table %}
columns:
  - title: Deprecated metric
    key: metric
  - title: Replacement
    key: replacement
rows:
  - metric: "`kong.keg.konnect.request.duration`"
    replacement: "`http.client.request.duration` with the `kong.http.client.name` label"
  - metric: "`kong.keg.konnect.analytics.queue.dropped`"
    replacement: "None"
  - metric: "`otel.sdk.processor.log.errors`"
    replacement: "`otel.sdk.processor.log.processed` with the `error.type=\"queue_full\"` attribute"
{% endtable %}

For all metrics in 1.3.0, see the [metrics reference](/event-gateway/metrics/).

#### Config poll interval removed

The `KEG__CONFIG_POLL_INTERVAL` environment variable has been removed.
The control plane and data plane protocol now uses long-polling, so the interval can no longer be configured.

## 1.2.x breaking changes

Review the [changelog](/event-gateway/changelog/#1-2-0) for all the changes in this release.

### 1.2.0

Deprecations and behavior changes in the {{site.event_gateway_short}} 1.2.0 release.

#### Policy invocation result reflects the real policy result

Previously, the `kong.keg.result` label on `kong.keg.kafka.policy.invocations` reported `success` even when a policy failed under the `mark`, `skip`, or `passthrough` failure modes.
These invocations now report `kong.keg.result=fail`.
If you want to ignore failures handled by those modes, use the `kong.keg.failure_mode` label.

#### Missing fields in parsed-record CEL expressions are absent

Paths like `record.value.content[...]` that don't exist are no longer placed in the context map, while explicit `null` values remain.
To check for a field before reading or comparing it, use `'<path>' in record.value.content`.

#### Deprecated metrics and headers

{% table %}
columns:
  - title: Deprecated
    key: deprecated
  - title: Replacement
    key: replacement
rows:
  - deprecated: "`kong.keg.kafka.decrypt.attempts`, `kong.keg.kafka.encrypt.attempts`, `kong.keg.kafka.kscheme.attempts`, and `kong.keg.kafka.schema.validation.attempts`"
    replacement: "The unified `kong.keg.kafka.policy.invocations` metric"
  - deprecated: "`kong.keg.konnect.analytics.bytes.sent`"
    replacement: "`kong.keg.konnect.analytics.sent`. The replacement counter is emitted alongside the deprecated one during the migration window."
  - deprecated: "The `kong/sverr-{part}` header of the `schema_validation` policy"
    replacement: "`kong/policy-failure-{konnect_id}`, which carries the reason for the policy failure"
{% endtable %}

## 1.1.x breaking changes

Review the [changelog](/event-gateway/changelog/#1-1-0) for all the changes in this release.

### 1.1.0

Breaking changes in the {{site.event_gateway_short}} 1.1.0 release.

#### Environment variable prefix for data planes

The data plane configuration prefix has changed from `KEG__KONNECT__` or `KONNECT_` to `KONG_KONNECT_`. 
The old environment variables are no longer accepted.

For example, to pass configuration settings to a new data plane, you would use:

```sh
docker run -d \
-e "KONG_KONNECT_REGION=us" \
-e "KONG_KONNECT_DOMAIN=konghq.com" \
-e "KONG_KONNECT_GATEWAY_CLUSTER_ID=your-gateway-id" \
-e "KONG_KONNECT_CLIENT_CERT=example-cert" \
-e "KONG_KONNECT_CLIENT_KEY=example-key" \
-p 19092-19101:19092-19101 \
kong/kong-event-gateway:1.1.0
```

For more information about configuring data planes at startup and all options, see the [{{site.event_gateway_short}} configuration reference](/event-gateway/configuration/).

#### Metrics naming convention

{{site.event_gateway_short}} metrics have been renamed to more closely follow [OpenTelemetry semantic conventions](https://opentelemetry.io/docs/specs/semconv/).

Key changes:

1. Delimiter change: `_` > `.` (Prometheus > OTel convention)
1. Suffix stripping: `_count`, `_seconds`, `_ms`, and `_active` suffixes removed. The unit is now in metadata only.
1. Unit normalization: All durations are now in seconds. Previously, the metrics were a mix of seconds and ms.
1. Label namespacing: Labels now use dotted namespaces (for example, `result` > `kong.keg.result`).
1. Common labels changed: 
  * `topic` > `messaging.destination.name` 
  * `policy_konnect_*` > `kong.konnect.policy.*` and `kong.keg.policy.*`

For example:
- Old metric: `kong_keg_kafka_backend_connection_error_count`
- New metric: `kong.keg.kafka.backend.connection.errors`

Removed in 1.1:

{% table %}
columns:
  - title: 1.0 Metric
    key: metric
  - title: Description
    key: description
rows:
  - metric: "`kong_keg_konnect_request_count`"
    description: |
      Konnect request count histogram.
      Merged into `kong.keg.konnect.request.duration` and gained a `http.response.status_code` label.
{% endtable %}

New in 1.1:

{% table %}
columns:
  - title: 1.1 Metric
    key: metric
  - title: Description
    key: description
rows:
  - metric: "`kong.keg.config.errors`"
    description: Config loading error count.
  - metric: "`kong.keg.config.loaded`"
    description: Config version loaded from CP.
  - metric: "`kong.keg.kafka.connection.errors`"
    description: Proxied connections that have errors.
  - metric: "`kong.keg.kafka.decrypt.attempts`"
    description: Decryption attempt count.
  - metric: "`kong.keg.kafka.encrypt.attempts`"
    description: Encryption attempt count.
  - metric: "`kong.keg.kafka.kscheme.attempts`"
    description: Kscheme script attempt count.
  - metric: "`kong.keg.kafka.policy.condition.failures`"
    description: Policy condition execution errors.
{% endtable %}

For all metrics in 1.1.0, see the [metrics reference](/event-gateway/metrics/1.1/).
