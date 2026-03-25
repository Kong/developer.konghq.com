---
title: "{{site.event_gateway}} changelog"
content_type: reference
layout: reference
description: "Changelog for supported {{site.event_gateway}} versions."
products:
  - event-gateway
breadcrumbs:
  - /event-gateway/

tags:
  - changelog
---

Changelog for supported {{site.event_gateway}} versions.

## 1.1

**Release date**: 2026/03/25

### **Breaking Changes**
  - **Observability stack migrated to OpenTelemetry**: All metrics, traces, and logs now use OpenTelemetry-native naming. Prometheus is still enabled by default but metric names, attribute keys, and duration units (all now in seconds) have changed. If you have dashboards or alerts based on previous metric names, you will need to update them.
  - **Environment variable names changed**: Legacy Konnect bootstrap environment variables are no longer supported. The variables now have a `KONG_` prefix. The gateway now logs a clear message indicating which variables to migrate if old-style names are detected:

    

### Features
  - **mTLS to backend Kafka clusters** You can now configure mutual TLS authentication between the gateway and your backend Kafka clusters, enabling encrypted and authenticated connections to brokers.
  - **mTLS between clients and the gateway** Clients can now authenticate to the gateway using TLS client certificates. Supports principal mapping to extract identity information from certificates for
  use in authorization policies.
  - **JWT claims in ACL expressions** OAuth/JWT claims are now available in the authentication context and can be used in `resource_names` expressions on ACL rules, enabling dynamic, claim-based access
  control per topic.
  - **Improved policy failure observability** Policy evaluation errors (CEL, schema validation, encryption) now emit detailed metrics and logs with sampling, making it easier to diagnose why requests
  are being rejected without overwhelming your logging pipeline.
  - **Header modification policy**: A new policy execution model is now available for header modification policies, providing a more flexible and extensible approach to transforming Kafka request and response headers.
  - **Backend clusters sharing SNI suffix**: Multiple backend clusters can now share a common SNI suffix, simplifying TLS configuration when clusters are behind a shared domain.
  - **Analytics for record count and message size**: Analytics events now include the number of records and byte sizes, giving you more granular visibility into traffic patterns in the Konnect analytics dashboard.
  - **Long polling for control plane configuration**: The gateway now supports long polling when fetching configuration from the Konnect control plane, reducing latency for configuration updates.
  - **Enhanced `validate` subcommand**: The `validate` CLI command now performs more thorough validation of your configuration, catching additional issues before startup.
  - **Configuration change observability**: Changes to the gateway's configuration (from the control plane or bootstrap) are now logged with details about what changed, making it easier to audit and debug configuration drift.

### Fixes
  - **Expressions using the `in` operator failed to parse**: ACL expressions containing the `in` keyword were incorrectly parsed by a regex-based parser. Switched to AST-based parsing to handle all valid expression syntax.
  - **Cryptic validation errors when environment variables resolved to empty strings**: Setting an env var reference (e.g., for SASL credentials) to an empty value produced an unhelpful error like `virtual_clusters.demo[1].auth.password: length is lower than 1`. Empty
  values are now caught at resolution time with a clear error message.
  - **Analytics payloads were double-compressed**: Analytics data sent to Konnect was being compressed twice, causing the backend to fail to decode it. Also fixed the healthcheck ping interval (was 5s, now uses the configured value).
  - **ACL default policy had no name in observability data**: Metrics and logs for the built-in default ACL policy were missing a policy name, making it difficult to distinguish from other policies in dashboards. Default policies now use the `__internal` prefix.
  - **Principal information missing for unauthenticated requests**: When running without authentication, the `auth.type` and `auth.principal.name` context values were not set, which could cause downstream policies or analytics to behave unexpectedly.
  - **Traces showed a misleading gap before authentication**: Request traces appeared to show a large delay before authentication started, but this was caused by the trace span starting before the full request was received. Traces now begin after the request is fully
  read.
