---
title: Enable Debug Logging
description: "Enable debug logging for {{ site.operator_product_name }} to troubleshoot issues"
content_type: how_to

permalink: /operator/dataplanes/how-to/enable-debug-logging/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

works_on:
  - konnect
  - on-prem

tldr:
  q: How do I enable debug logging for {{ site.operator_product_name }}?
  a: Configure the `--zap-log-level` and `--zap-devel` flags via Helm values.

related_resources:
  - text: "Configuration Options"
    url: /operator/reference/configuration-options/
---

## Overview

When troubleshooting issues with {{ site.operator_product_name }}, enabling debug logging can provide additional insight into the operator's behavior.

## Enable debug logging using args

When installing or upgrading {{ site.operator_product_name }} with Helm, you can enable debug logging by adding the following to your `values.yaml`:

```yaml
args:
  - --zap-log-level=debug
  - --zap-devel=true
  - --zap-time-encoding=iso8601
```

Apply the configuration:

```bash
helm upgrade --install kong-operator kong/kong-operator \
  -n kong-system --create-namespace \
  -f values.yaml
```

## Enable debug logging using environment variables

Alternatively, you can configure logging using environment variables in your `values.yaml`:

```yaml
env:
  zap_log_level: debug
  zap_devel: "true"
  zap_time_encoding: iso8601
```

The Helm chart automatically converts these keys to environment variables with the `KONG_OPERATOR_` prefix (for example, `zap_log_level` becomes `KONG_OPERATOR_ZAP_LOG_LEVEL`).

{:.note}
> The `env` and `args` sections are mutually exclusive. When both are provided, `args` takes precedence.

## Logging options

| Flag | Environment Variable | Description |
|------|---------------------|-------------|
| `--zap-log-level` | `KONG_OPERATOR_ZAP_LOG_LEVEL` | Log verbosity level: `debug`, `info`, `error`, `panic`, or an integer (higher values = more verbose) |
| `--zap-devel` | `KONG_OPERATOR_ZAP_DEVEL` | Enable development mode (`true` or `false`). When enabled, sets console encoding, debug level, and warn-level stack traces |

## View the logs

After enabling debug logging, view the operator logs:

```bash
kubectl logs -n kong-system deployment/<release-name>-kong-operator-controller-manager -f
```

{:.info}
> Development mode (`--zap-devel=true`) uses a console encoder with colored, human-readable output. Production mode uses JSON encoding suitable for log aggregation systems.

## Disable debug logging

To return to normal logging levels, remove the debug configuration and upgrade:

```bash
helm upgrade kong-operator kong/kong-operator \
  -n kong-system \
  --reset-values
```
