---
title: "Observe GitHub MCP traffic with Kong AI Gateway"
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Prometheus plugin
    url: /plugins/prometheus/
  - text: Monitor AI LLM metrics
    url: /ai-gateway/monitor-ai-llm-metrics/
permalink: /mcp/observe-mcp-traffic

series:
    id: mcp-traffic
    position: 3

description: Learn how to observe MCP traffic within GitHub remote MCP server with the AI Proxy Advanced and {{ site.base_gateway }} Prometheus plugin

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.10'

plugins:
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How can I observe my MCP traffic using Kong AI Gateway?
  a: |
    Use the AI Proxy Advanced plugin to enable detailed logging of request payloads and statistics for all AI models. Then enable and configure the Prometheus plugin on Kong AI Gateway to scrape these metrics. This setup allows you to monitor MCP traffic in real time and analyze model usage and performance with Prometheus.

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: GitHub
      content: |
        To complete this tutorial, you'll need access to GitHub, access to GitHub repository and [Github Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).

        Once you've created your Github Personal Access Token, make sure to export it as an environment variable by running the following command:

        ```bash
        export GITHUB_PAT=<YOUR_GITHUB_TOKEN>
        ```
      icon_url: /assets/icons/third-party/github.svg
  prereqs:
    entities:
        services:
            - example-clean-service
        routes:
            - example-clean-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Reconfigure the AI Proxy Advanced plugin

Now we enable detailed logging for all configured models in the AI Proxy Advanced plugin. This captures request/response payloads and performance statistics. We then scrape those statistics using the Prometheus plugin for monitoring and analysis. Apply the configuration below to enable logging for both used models.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        balancer:
          algorithm: round-robin
        targets:
          - model:
              name: gpt-4
              provider: openai
              options:
                max_tokens: 512
                temperature: 1.0
            route_type: llm/v1/responses
            logging:
              log_payloads: true
              log_statistics: true
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            weight: 50
          - model:
              name: gpt-4o
              provider: openai
              options:
                max_tokens: 512
                temperature: 1.0
            route_type: llm/v1/responses
            logging:
              log_payloads: true
              log_statistics: true
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            weight: 50
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

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

## Validate

You can validate that the plugin is collecting metrics by generating traffic to the example service.

Now, we can run the script from the previous tutorial again:

```bash
for i in {1..10}; do
  echo -n "Request #$i — Model: "
  curl -s -X POST "http://localhost:8000/anything/v1/responses" \
    -H "Accept: application/json" \
    -H "apikey: hello_world" \
    -H "Content-Type: application/json" \
    --json "{
      \"tools\": [
        {
          \"type\": \"mcp\",
          \"server_label\": \"gitmcp\",
          \"server_url\": \"https://api.githubcopilot.com/mcp/x/repos\",
          \"require_approval\": \"never\",
          \"headers\": {
            \"Authorization\": \"Bearer $GITHUB_PAT\"
          }
        }
      ],
      \"input\": \"tools available with github mcp\"
    }" | jq -r '.model'
  sleep 3
done
```


Run the following to query the collected `kong_ai_llm_requests_total` metric data:

```sh
curl -s 'localhost:9090/api/v1/query?query=kong_ai_llm_requests_total'
```

This should return something like the following:
```
{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"kong_ai_llm_requests_total","ai_model":"gpt-4o","ai_provider":"openai","instance":"kong-quickstart-gateway:8001","job":"kong","workspace":"default"},"value":[1750768729.300,"21"]},{"metric":{"__name__":"kong_ai_llm_requests_total","ai_model":"gpt-4","ai_provider":"openai","instance":"kong-quickstart-gateway:8001","job":"kong","workspace":"default"},"value":[1750768729.300,"19"]},{"metric":{"__name__":"kong_ai_llm_requests_total","ai_model":"gpt-4.1","ai_provider":"UNSPECIFIED","instance":"kong-quickstart-gateway:8001","job":"kong","workspace":"default"},"value":[1750768729.300,"1"]}]}}
```

You can also view the [Prometheus expression](https://prometheus.io/docs/prometheus/latest/querying/basics/) viewer by opening [http://localhost:9090/graph](http://localhost:9090/graph) in a browser.