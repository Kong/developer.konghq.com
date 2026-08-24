---
title: Wrong metrics from Prometheus plugin
content_type: support
description: "Metrics reported by the Prometheus plugin can be missing or incomplete because `status_code_metrics`/`latency_metrics` aren't enabled, or because the `prometheus_metrics` shared dictionary has reached its default size limit and is dropping older metrics."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why are metrics from the Prometheus plugin missing or incomplete in Kong Gateway?
  a: |
    Two things commonly cause this: `status_code_metrics` and `latency_metrics` are off by default in the Prometheus plugin config and must be explicitly enabled, and the `prometheus_metrics` shared dictionary can fill up under load, causing Kong to evict older metrics. Enable the two metric fields, and if the dictionary is full (check via the status endpoint's `lua_shared_dicts.prometheus_metrics`), increase its size with the `nginx_http_lua_shared_dict` config parameter.
related_resources: []
---

## Problem

Metrics reported by the Prometheus plugin are missing or incomplete in {{site.base_gateway}}, especially when running performance tests with a high number of routes. (Note: Kong Vitals is disabled by default as of {{site.base_gateway}} 3.14.0.0, so this is no longer a discrepancy against Vitals for most deployments, but the same underlying metric-loss issue still applies to the Prometheus plugin's own metrics.)

## Solution

Before troubleshooting missing metrics, confirm that the relevant metric fields are enabled: as of {{site.base_gateway}} 3.14.0.0, `status_code_metrics` and `latency_metrics` are off by default in the Prometheus plugin configuration and must be explicitly enabled, or no relevant metrics will be produced at all.

With those fields enabled, incomplete or lost metrics can be attributed to the `prometheus_metrics` shared dictionary reaching its default size limit and not storing all metrics. When the shared dictionary is full, Kong must remove old metrics to add new ones, leading to incomplete metrics reporting.

To resolve this issue, you can increase the size of the `prometheus_metrics` shared dictionary. Here are the steps to do so:

1. Check the current size of the shared dictionary by accessing the status endpoint of the Kong node. You may need to use `kubectl port-forward` if running in Kubernetes:

```bash

curl -s http://localhost:8100/status | jq .memory.lua_shared_dicts.prometheus_metrics
```

If the output shows that the `allocated_slabs` is equal to the `capacity`, it indicates that the dictionary is full.

```
{
  "allocated_slabs": "5.00 MiB",
  "capacity": "5.00 MiB"
}
```

To increase the dictionary size, add the following configuration parameter in the `env` section of your dataplanes' `values.yaml`:

```yaml

nginx_http_lua_shared_dict: "prometheus_metrics 100m"
```

Alternatively, set it as an environment variable:

```yaml

KONG_NGINX_HTTP_LUA_SHARED_DICT: "prometheus_metrics 100m"
```

After applying the configuration change, verify that the size of the shared dictionary has increased by checking the status endpoint again:

```bash

curl -s http://localhost:8100/status | jq .memory.lua_shared_dicts.prometheus_metrics
{
   "capacity": "100.00 MiB",
   "allocated_slabs": "26.48 MiB"
}
```

The `capacity` should now reflect the new size, such as `100.00 MiB`.

By following these steps, and ensuring `status_code_metrics`/`latency_metrics` are enabled, you should be able to ensure accurate, complete metrics reporting from the Prometheus plugin for your {{site.base_gateway}}'s performance.
