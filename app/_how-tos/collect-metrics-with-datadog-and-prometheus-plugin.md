---
title: Collect metrics with Datadog and the Prometheus plugin
content_type: how_to
description: "Learn how to collect metrics from {{site.base_gateway}} with Datadog and the Prometheus plugin."
products:
    - gateway

related_resources:
  - text: "Datadog documentation: Prometheus and OpenMetrics metrics collection from a host"
    url: https://docs.datadoghq.com/integrations/guide/prometheus-host-collection/

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

entities: 
  - plugins

plugins:
    - prometheus

tags:
    - monitoring
    - datadog
    - prometheus
search_aliases:
  - Datadog
tldr:
    q: placeholder 
    a: placeholder

tools:
    - deck

prereqs:
  inline: 
    - title: Datadog
      content: |
        placeholder
      icon_url: /assets/icons/third-party/datadog.svg

cleanup:
  inline:
    - title: Datadog
      content: |
        placeholder
      icon_url: /assets/icons/third-party/datadog.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

next_steps:
  - text: Review the Prometheus plugin configuration reference
    url: /plugins/prometheus/reference/
---

## Install Datadog agent

https://app.datadoghq.com/account/settings/agent/latest

## Enable the Prometheus plugin

Before you configure the 

{% entity_examples %}
entities:
  plugins:
    - name: prometheus
      config:
        status_code_metrics: true
{% endentity_examples %}


## Configure the Datadog Agent to collect {{site.base_gateway}} metrics

macOS (others: https://docs.datadoghq.com/agent/configuration/agent-configuration-files/#agent-configuration-directory)
```
touch ./.datadog-agent/conf.d/openmetrics.d/conf.yaml
```

In the file:
```
instances:
 - prometheus_url: http://localhost:8001/metrics
   namespace: "kong"
   metrics:
     - kong_*
```
The following is an example configuration for pulling all the `kong_` prefixed metrics.

## Restart the Datadog Agent

You must restart the agent to start collecting metrics:

```
launchctl start com.datadoghq.agent
```

This is for macOS, see Datadog's [Agent commands](https://docs.datadoghq.com/agent/configuration/agent-commands/#start-stop-and-restart-the-agent) documentation for all restart commands.

## Validate

{% validation request-check %}
url: '/anything' # prepends the proxy URL, either konnect or on-prem
status_code: 200
{% endvalidation %}

You can validate that {{site.base_gateway}} is sending metrics to Datadog by navigating to the Metric summary page and searching for `kong`. 

