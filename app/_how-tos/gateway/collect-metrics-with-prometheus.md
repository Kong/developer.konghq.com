---
title: Collect {{site.base_gateway}} metrics with the Prometheus plugin
permalink: /how-to/collect-metrics-with-prometheus/
content_type: how_to
description: "Learn how to collect metrics from {{site.base_gateway}} with the Prometheus plugin."
products:
    - gateway

related_resources:
  - text: Prometheus plugin
    url: /plugins/prometheus/
  - text: Collect metrics with Datadog and the Prometheus plugin
    url: /how-to/collect-metrics-with-datadog-and-prometheus-plugin/
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
    - prometheus

tldr:
    q: How do I collect {{site.base_gateway}} metrics with the Prometheus plugin?
    a: |
        {{site.base_gateway}} supports Prometheus with the [Prometheus plugin](/plugins/prometheus/). It exposes {{site.base_gateway}} performance and proxied upstream service metrics on the `/metrics` endpoint. To collect metrics, enable the Prometheus plugin, configure a `prometheus.yml` file to expose {{site.base_gateway}} metrics, and then run a Prometheus server. 

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

cleanup:
  inline:
    - title: Prometheus
      content: |
        Once you are done experimenting with Prometheus, you can use the following
        commands to stop the Prometheus server you created in this guide:

        ```sh
        docker stop kong-quickstart-prometheus
        ```
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

Before you configure Prometheus, enable the [Prometheus plugin](/plugins/prometheus/) on {{site.base_gateway}}:

{% entity_examples %}
entities:
  plugins:
    - name: prometheus
      config:
        status_code_metrics: true
{% endentity_examples %}

## Configure Prometheus

Create a `prometheus.yml` file to configure Prometheus to scrape {{site.base_gateway}} metrics:

{% on_prem %}
content: |
  ```yaml
  cat <<EOF > prometheus.yml
  scrape_configs:
   - job_name: 'kong'
     scrape_interval: 5s
     static_configs:
       - targets: ['kong-quickstart-gateway:8001']
  EOF
  ```
{% endon_prem %}

{% konnect %}
content: |
  ```yaml
  cat <<EOF > prometheus.yml
  scrape_configs:
   - job_name: 'kong'
     scrape_interval: 5s
     static_configs:
       - targets: ['kong-quickstart-gateway:8100']
  EOF
  ```
{% endkonnect %}

Run a Prometheus server, and pass it the configuration file created in the previous step:

```sh
docker run -d --name kong-quickstart-prometheus \
  --network=kong-quickstart-net -p 9090:9090 \
  -v $(PWD)/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:latest
```

Prometheus will begin to scrape metrics data from {{site.base_gateway}}.

## Validate

You can validate that the plugin is collecting metrics by generating traffic to the example Service. 

Run the following in the same terminal:

{% validation traffic-generator %}
iterations: 60
url: '/anything'
sleep: 1
{% endvalidation %}

Run the following to query the collected `kong_http_requests_total` metric data:

```sh
curl -s 'localhost:9090/api/v1/query?query=kong_http_requests_total'
```

This should return something like the following:
```
{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"kong_http_requests_total","code":"200","instance":"kong-quickstart-gateway:8001","job":"kong","route":"example-route","service":"example-service","source":"service","workspace":"default"},"value":[1749000790.826,"42"]}]}}
```

You can also view the [Prometheus expression](https://prometheus.io/docs/prometheus/latest/querying/basics/) viewer by opening [http://localhost:9090/graph](http://localhost:9090/graph) in a browser.

