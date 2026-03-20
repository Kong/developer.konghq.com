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
  - text: "{{site.event_gateway_short}} version support"
    url: /event-gateway/version-support-policy/
  - text: "{{site.event_gateway_short}} changelog"
    url: /event-gateway/changelog/
---

Before upgrading, review any configuration or breaking changes in the version you're upgrading to and prior versions that
affect your current installation.

## 1.1.x breaking changes

Review the [changelog](/event-gateway/changelog/#1-1-0) for all the changes in this release.

### 1.1.0

Breaking changes in the {{site.event_gateway_short}} 1.1.0 release.

#### Environment variable prefix for data planes

The data plane configuration prefix has changed from `KEG__KONNECT__` or `KONNECT_`to `KONG_KONNECT_`. The old variable environment variables are no longer accepted.

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
2. Suffix stripping: `_count`, `_seconds`, `_ms`, and `_active` suffixes removed. The unit is now in metadata only.
3. Unit normalization: All durations are now in seconds. Previously, the metrics were a mix of seconds and ms.
4. Label namespacing: Labels now use dotted namespaces (for example, `result` > `kong.keg.result`).
6. Common labels changed: 
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
    description: Proxied connections that errored.
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
