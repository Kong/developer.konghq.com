---
title: "Visualize LLM traffic with Prometheus and Grafana"
permalink: /how-to/visualize-llm-metrics-with-grafana/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Prometheus plugin
    url: /plugins/prometheus/
  - text: Monitor AI metrics
    url: /ai-gateway/monitor-ai-llm-metrics/

description: Learn how to monitor LLM traffic and visualize AI metrics in Grafana using the AI Proxy Advanced and Prometheus plugins in {{ site.base_gateway }}.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

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
  - mistral

tldr:
  q: How can I visualize LLM traffic metrics in {{site.ai_gateway}}?
  a: |
    Enable the AI Proxy Advanced plugin to collect detailed request and model statistics. Then configure the Prometheus plugin to expose these metrics for scraping. Finally, connect Grafana to visualize model performance, usage trends, and traffic distribution in real time.

tools:
  - deck

prereqs:
  konnect:
    - name: KONG_STATUS_LISTEN
      value: '0.0.0.0:8100'
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

Before you configure Prometheus, enable the [Prometheus plugin](/plugins/prometheus/) on {{site.base_gateway}}. In this example, we’ve enabled two types of metrics: status code metrics, and AI metrics which expose detailed performance and usage data for AI-related requests.

{% entity_examples %}
entities:
  plugins:
    - name: prometheus
      config:
        status_code_metrics: true
        ai_metrics: true
        bandwidth_metrics: true
        latency_metrics: true
        upstream_health_metrics: true
{% endentity_examples %}

## Configure Prometheus

Create a `prometheus.yml` file:

```sh
touch prometheus.yml
```

Now, add the following to the `prometheus.yml` file to configure Prometheus to scrape {{site.base_gateway}} metrics:

{% on_prem %}
content: |
  ```yaml
  scrape_configs:
   - job_name: 'kong'
     scrape_interval: 5s
     static_configs:
       - targets: ['kong-quickstart-gateway:8001']
  ```
{% endon_prem %}

{% konnect %}
content: |
  ```yaml
  scrape_configs:
   - job_name: 'kong'
     scrape_interval: 5s
     static_configs:
       - targets: ['kong-quickstart-gateway:8100']
  ```
{% endkonnect %}

Now, run a Prometheus server, and pass it the configuration file created in the previous step:

```sh
docker run -d --name kong-quickstart-prometheus \
  --network=kong-quickstart-net -p 9090:9090 \
  -v $(PWD)/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:latest
```

Prometheus will begin to scrape metrics data from {{site.ai_gateway}}.


## Configure Grafana dashboard

### Add Prometheus data source

1. In the Grafana UI, go to **Connections** > **Data Sources**. If you're using the Grafana setup from the [prerequisites](/how-to/visualize-llm-metrics-with-grafana/#grafana), you can access the UI at [http://localhost:3000/](http://localhost:3000/).
2. Click **Add data source**.
3. Select **Prometheus** from the list.
4. In the **Prometheus server URL** field, enter: `http://host.docker.internal:9090`.
5. Scroll down to the bottom of the page and click **Save & test** to verify the connection. If successful, you'll see the following message:
  ```text
  Successfully queried the Prometheus API.
  ```

### Import Dashboard

1. In the Grafana UI, navigate to **Dashboards**.
1. Select "Import" from the **New** dropdown menu.
2. Enter `21162` in the **Find and import dashboards for common applications** field.
1. Click **Load**.
3. In the **Prometheus** dropdown, select the Prometheus data source you created previously.
3. Click **Import**.

## View Grafana configuration

Now, we can generate traffic by running the following CURL request:

```bash
for i in {1..5}; do
  echo -n "Request #$i — Model: "
  curl -s -X POST "http://localhost:8000/anything" \
    -H "Content-Type: application/json" \
    --data '{
      "messages": [
        {
          "role": "user",
          "content": "Hello!"
        }
      ]
    }' | jq -r '.model'
  sleep 10
done
```

Once it's finished, you'll see something like the following in the output. Notice that the requests were routed to different models based on the load balancing you configured earlier:

```text
Request #1 — Model: gpt-4.1-2025-04-14
Request #2 — Model: mistral-tiny
Request #3 — Model: mistral-tiny
Request #4 — Model: mistral-tiny
Request #5 — Model: gpt-4.1-2025-04-14
```
{: .no-copy-code }

## View metrics in Grafana

Now you can visualize that traffic in the Grafana dashboard.

1. Open Grafana in your browser at [http://localhost:3000](http://localhost:3000).
1. Navigate to **Dashboards** in the sidebar.
1. Click the **Kong CX AI** dashboard you imported earlier.
1. You should see the following:
   - **AI Total Request**: Total request count and breakdown by provider.
   - **Tokens consumption**: Counts for `completion_tokens`, `prompt_tokens`, and `total_tokens`.
   - **Cost AI Request**: Estimated cost of AI requests (shown if `input_costs` and `output_costs` are configured).
   - **DB Vector**: Vector database request metrics (shown if `vector_db` is enabled).
   - **AI Requests Details**: Timeline of recent AI requests.

The visualized metrics in Grafana will look similar to this example dashboard:

![Grafana AI Dashboard](/assets/images/ai-gateway/grafana-ai-dashboard.png)

