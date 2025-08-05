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
  gateway: '3.8'

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
        Ensure Grafana is installed locally and accessible. You can quickly start a Grafana instance using Docker:

        ```sh
        docker run -d -p 3000:3000 --name=grafana grafana/grafana-enterprise
        ```

        This command pulls the official Grafana Enterprise image and runs it on port `3000`. Once running, Grafana is accessible at [http://localhost:3000](http://localhost:3000).

        On first login, use the default credentials:
        - **Username:** `admin`
        - **Password:** `admin`

        Grafana will prompt you to set a new password after the initial login.
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

To expose AI traffic metrics to Prometheus, you must first configure the AI Proxy Advanced plugin to enable detailed logging. This makes request payloads, model performance statistics, and cost metrics available for collection.

In this example, traffic is balanced between OpenAI's `gpt-4.1` and Mistral's `mistral-tiny` models using a round-robin algorithm. For each model target, logging is enabled to capture request counts, latencies, token usage, and payload data. Additionally, we define `input_cost` and `output_cost` values to track estimated usage costs per 1,000 tokens, which are exposed as Prometheus metrics.

Apply the following configuration to enable metrics collection for both models:

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
                input_cost: 0.75
                output_cost: 0.75
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
                input_cost: 0.25
                output_cost: 0.25
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

### Add Prometheus Data Source

1. In the Grafana UI, go to **Connections** > **Data Sources**.
2. Click **Add data source**.
3. Select **Prometheus** from the list.
4. In the **Connection > Prometheus server URL** field, enter: `http://host.docker.internal:9090`.
5. Scroll down and click **Save & test** to verify the connection.

### Import Dashboard

1. In the Grafana UI, navigate to **Dashboards** > **New** > **Import**.
2. In the **Import via grafana.com** field, enter the dashboard ID: `21162`.
3. Click **Load**.

## Validate

You can validate that the plugin is collecting metrics by generating traffic to the example service.

```bash
test
```

Run the following to query the collected `kong_ai_llm_requests_total` metric data:

```sh
curl -s 'localhost:9090/api/v1/query?query=kong_ai_llm_requests_total'
```


This should return the following response:
```
test
```

<!-- TBA: see your Grafana dashboard. -->