---
title: "Observe GitHub MCP traffic with {{site.ai_gateway}}"
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Prometheus plugin
    url: /plugins/prometheus/
  - text: Monitor AI LLM metrics
    url: /ai-gateway/monitor-ai-llm-metrics/
permalink: /mcp/observe-mcp-traffic/
breadcrumbs:
  - /mcp/

series:
    id: mcp-traffic
    position: 3

description: Learn how to observe MCP traffic within GitHub remote MCP server with the AI Proxy Advanced and {{ site.base_gateway }} Prometheus plugin

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem

min_version:
  gateway: '3.11'

plugins:
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai
  - mcp

tldr:
  q: How can I observe my MCP traffic using {{site.ai_gateway}}?
  a: |
    Use the AI Proxy Advanced plugin to enable detailed logging of request payloads and statistics for all AI models. Then enable and configure the Prometheus plugin on {{site.ai_gateway}} to scrape these metrics. This setup allows you to monitor MCP traffic in real time and analyze model usage and performance with Prometheus.

tools:
  - deck


cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg


automated_tests: false
---

## Reconfigure the AI Proxy Advanced plugin

Now, you can enable detailed logging for all configured models in the AI Proxy Advanced plugin. This captures request/response payloads and performance statistics. You can then scrape those statistics using the Prometheus plugin for monitoring and analysis. Apply the configuration below to enable logging for both models.

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
for i in {1..5}; do
  echo -n "Request #$i — Model: "
  curl -s -X POST "http://localhost:8000/anything" \
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
      \"input\": \"test\"
    }" | jq -r '.model'
  sleep 10
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