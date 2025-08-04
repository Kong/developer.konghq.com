---
title: "Monitor LLM traffic with Prometheus and Grafana"
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Prometheus plugin
    url: /plugins/prometheus/
  - text: Visualize AI metrics with Grafana
    url: /ai-gateway/monitor-ai-llm-metrics/

description: Learn how to monitor LLM traffic and visualize AI metrics in Grafana using the AI Proxy Advanced and Prometheus plugins in {{ site.base_gateway }}.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem

min_version:
  gateway: '3.11'

plugins:
  - ai-proxy-advanced
  - prometheus

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - observability
  - prometheus
  - grafana

tldr:
  q: How can I visualize LLM traffic metrics in Kong AI Gateway?
  a: |
    Enable the AI Proxy Advanced plugin to collect detailed request and model statistics. Then configure the Prometheus plugin to expose these metrics for scraping. Finally, connect Grafana to visualize model performance, usage trends, and traffic distribution in real time.

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: Mistral
      include_content: prereqs/mistral
      icon_url: /assets/icons/mistral.svg
    - title: Grafana
      content: |
        Ensure Grafana is installed locally and accessible:

        ```sh
        docker run -d -p 3000:3000 --name=grafana grafana/grafana-enterprise
        ```
      icon_url: /assets/icons/third-party/grafana.svg
  entities:
    services:
      - example-service
    routes:
      - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---


## Configure the AI Proxy Advanced plugin

Configure the AI Proxy Advanced plugin to log payloads and collect detailed performance statistics from your LLMs. In this example, traffic is balanced between OpenAI's GPT-4.1 and Mistral's Tiny model using a round-robin algorithm. The plugin will capture metrics such as request counts, latencies, and model-specific usage, which Prometheus will later scrape for visualization.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        balancer:
          algorithm: round-robin
        targets:
          - model:
              provider: openai
              name: gpt-4.1
              options:
                max_tokens: 512
                temperature: 1.0
            route_type: llm/v1/chat
            logging:
              log_payloads: true
              log_statistics: true
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            weight: 50
          - model:
              provider: mistral
              name: mistral-tiny
              options:
                mistral_format: openai
                upstream_url: https://api.mistral.ai/v1/chat/completions
            route_type: llm/v1/chat
            logging:
              log_payloads: true
              log_statistics: true
            auth:
              header_name: Authorization
              header_value: Bearer ${mistral_api_key}
            weight: 50
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
  mistral_api_key:
    value: $MISTRAL_API_KEY
{% endentity_examples %}


## Enable the Prometheus plugin

Before you configure Prometheus, enable the [Prometheus plugin](/plugins/prometheus/) on {{site.base_gateway}}:

{% entity_examples %}
entities:
  plugins:
    - name: prometheus
      config:
        status_code_metrics: true
        ai_metrics: true
{% endentity_examples %}

## Configure Prometheus

Create a `prometheus.yml` file:

```sh
touch prometheus.yml
```

Now, add the following to the `prometheus.yml` file to configure Prometheus to scrape {{site.base_gateway}} metrics:

```yaml
scrape_configs:
 - job_name: 'kong'
   scrape_interval: 5s
   static_configs:
     - targets: ['kong-quickstart-gateway:8001']
```
{: data-deployment-topology="on-prem" }

```yaml
scrape_configs:
 - job_name: 'kong'
   scrape_interval: 5s
   static_configs:
     - targets: ['kong-quickstart-gateway:8100']
```
{: data-deployment-topology="konnect" }

Run a Prometheus server, and pass it the configuration file created in the previous step:

```sh
docker run -d --name kong-quickstart-prometheus \
  --network=kong-quickstart-net -p 9090:9090 \
  -v $(PWD)/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:latest
```

Prometheus will begin to scrape metrics data from {{site.base_gateway}}.

## Configure Grafana

## Validate

You can validate that the plugin is collecting metrics by generating traffic to the example service.

Now, we can run the script from the previous tutorial again:

```bash
test
```


Run the following to query the collected `kong_ai_llm_requests_total` metric data:

```sh
curl -s 'localhost:9090/api/v1/query?query=kong_ai_llm_requests_total'
```


This should return something like the following:
```
test
```

You can also view the [Prometheus expression](https://prometheus.io/docs/prometheus/latest/querying/basics/) viewer by opening [http://localhost:9090/graph](http://localhost:9090/graph) in a browser.