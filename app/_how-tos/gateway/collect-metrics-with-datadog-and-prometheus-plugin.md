---
title: Collect metrics with Datadog and the Prometheus plugin
permalink: /how-to/collect-metrics-with-datadog-and-prometheus-plugin/
content_type: how_to
description: "Learn how to collect metrics from {{site.base_gateway}} with Datadog and the Prometheus plugin."
products:
    - gateway

related_resources:
  - text: "Datadog documentation: Prometheus and OpenMetrics metrics collection from a host"
    url: https://docs.datadoghq.com/integrations/guide/prometheus-host-collection/
  - text: Collect {{site.base_gateway}} metrics with the Prometheus plugin
    url: /how-to/collect-metrics-with-prometheus/
  - text: Monitor metrics with Prometheus and Grafana with KIC
    url: /kubernetes-ingress-controller/observability/prometheus-grafana/
  - text: "{{site.base_gateway}} monitoring and metrics"
    url: /gateway/monitoring/

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
    q: How do I scrape {{site.base_gateway}} metrics with Datadog and the Prometheus plugin?
    a: Install the Datadog Agent and enable the Prometheus plugin. Configure the Datadog Agent with the {{site.base_gateway}} `/metrics` endpoint and set `kong.*` for `metrics`. Restart the Datadog Agent, and send requests to generate metrics. You should see the metrics in Datadog Metrics summary.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  konnect:
    - name: KONG_STATUS_LISTEN
      value: '0.0.0.0:8100'
  ports:
    - "8100:8100"
  inline: 
    - title: Datadog
      content: |
        For this tutorial, you'll need to configure the following:
        * A [Datadog account](https://www.datadoghq.com/)
        * Install the Datadog Agent by navigating to the [Agent Installation](https://app.datadoghq.com/account/settings/agent/latest) page or **Integration** > **Install agents** in the Datadog UI.
        * Your Datadog [API key](https://docs.datadoghq.com/getting_started/site/) and [app key](https://app.datadoghq.com/access/application-keys). You can find these in the Datadog UI in **Organization settings**.

        Set the following as environment variables:
        ```sh
        export DD_API_KEY='YOUR-API-KEY'
        export DD_APP_KEY='YOUR-APPLICATION-KEY'
        export DD_SITE_API_URL='YOUR-API-SITE-URL'
        ```
        
        {:.warning}
        > * Some distributions require you to modify the `datadog.yaml` file and add your API key and Datadog site URL. Ensure this file is configured correctly or Datadog won't be able to scrape metrics.
        > * Your Datadog site API URL [varies depending on the region](https://docs.datadoghq.com/getting_started/site/) you're using. For example, for the `US5` region, the URL would be `https://api.us5.datadoghq.com`.
      icon_url: /assets/icons/third-party/datadog.svg

cleanup:
  inline:
    - title: Datadog
      content: |
        To stop collecting metrics, you can [uninstall the Datadog Agent](https://docs.datadoghq.com/agent/guide/how-do-i-uninstall-the-agent/).
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

## Enable the Prometheus plugin

Before you configure the Datadog Agent to scrape metrics from {{site.base_gateway}}, you first need to enable the [Prometheus plugin](/plugins/prometheus/). 

The following configuration enables the plugin globally and [exports status code metrics](/plugins/prometheus/reference/#schema--config-status-code-metrics), like the total number of HTTP requests:

{% entity_examples %}
entities:
  plugins:
    - name: prometheus
      config:
        status_code_metrics: true
{% endentity_examples %}


## Configure the Datadog Agent to collect {{site.base_gateway}} metrics

Now that the Prometheus plugin is configured, you can configure the Datadog Agent to scrape {{site.base_gateway}} metrics.

Create the `conf.yaml` file:

```sh
touch ./.datadog-agent/conf.d/openmetrics.d/conf.yaml
```

This command uses the macOS directory location. For other distributions, see Datadog's [Agent configuration directory](https://docs.datadoghq.com/agent/configuration/agent-configuration-files/#agent-configuration-directory). 

Copy and paste the following configuration in the `conf.yaml` file:

{% on_prem %}
content: |
  ```yaml
  instances:
    - openmetrics_endpoint: http://localhost:8001/metrics
      namespace: kong
      metrics:
        - kong.*
  ```

  This configuration pulls all the `kong.` prefixed metrics from the {{site.base_gateway}} metrics endpoint (`http://localhost:8001/metrics`).
{% endon_prem %}

{% konnect %}
content: |
  ```yaml
  instances:
    - openmetrics_endpoint: http://localhost:8100/metrics
      namespace: kong
      metrics:
        - kong.*
  ```

  This configuration pulls all the `kong.` prefixed metrics from the {{site.base_gateway}} [Status API metrics](/api/gateway/status/v1/#/paths/metrics/get) endpoint (`http://localhost:8100/metrics`).
{% endkonnect %}

{:.warning}
> **Important:** If you're running {{site.base_gateway}} and the Datadog Agent in Docker, you'll need to replace `localhost` in the `config.yaml` with the name of the {{site.base_gateway}} container. Also, both containers need to be running on the same network for them to communicate.

## Restart the Datadog Agent

You must restart the agent to start collecting metrics:

```sh
launchctl stop com.datadoghq.agent
```
```sh
launchctl start com.datadoghq.agent
```

This example is for macOS, see Datadog's [Agent commands](https://docs.datadoghq.com/agent/configuration/agent-commands/#start-stop-and-restart-the-agent) documentation for all restart commands.

The Datadog Agent may take a few minutes to restart.

## Validate

Now, you can validate that Datadog can scrape {{site.base_gateway}} metrics by first sending requests to generate metrics:

{% validation request-check %}
url: '/anything' 
count: 10
status_code: 200
{% endvalidation %}

You can validate that {{site.base_gateway}} is sending metrics to Datadog by running the following:

```sh
curl -X GET "$DD_SITE_API_URL/api/v1/search?q=kong.kong_http_requests.count" \
-H "Accept: application/json" \
-H "DD-API-KEY: $DD_API_KEY" \
-H "DD-APPLICATION-KEY: $DD_APP_KEY"
```

You should get the following response:
```sh
{"results":{"metrics":["kong.kong_http_requests.count"],"hosts":[]}}
```
{:.no-copy-code}

Alternatively, you can navigate to the Metrics Explorer page in the Datadog UI and search for `kong.kong_http_requests.count`. You should see the 10 requests that you just sent.

