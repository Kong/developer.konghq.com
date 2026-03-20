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

For example:
- Old metric: `kong_keg_kafka_backend_connection_error_count`
- New metric: `kong.keg.kafka.backend.connection.errors`

For all metrics in 1.1.0, see the [metrics reference](/event-gateway/metrics/1.1/).