---
title: Visualize {{site.ai_gateway}} metrics
permalink: /how-to/visualize-ai-gateway-metrics-with-kibana/
content_type: how_to

description: Use a sample Elasticsearch, Logstash, and Kibana stack to visualize data from the AI Proxy plugin.

products:
  - ai-gateway
  - gateway

works_on:
    - on-prem

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy
  - key-auth
  - http-log

entities:
  - service
  - route
  - plugin

tags:
    - ai
    - openai

tldr:
    q: How can I visualize AI Proxy logs?
    a: |
        You can use any [logging plugin](/plugins/?category=logging) to send your {{site.ai_gateway}} metrics and logs to your dashboarding tool.
        For testing purposes, you can start our [sample observability stack](https://github.com/KongHQ-CX/kong-ai-gateway-observability), send requests to `/gpt4o`, and visualize the results at `http://localhost:5601/app/dashboards#/view/aa8e4cb0-9566-11ef-beb2-c361d8db17a8`.

        If you're using {{site.konnect_short_name}}, you can visualize {{site.ai_gateway}} metrics with [{{site.observability}}](/observability/).

prereqs:
  skip_product: true
  inline:
  - title: OpenAI
    content: |
        This tutorial uses OpenAI:
        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Create a decK variable with the API key:
        ```sh
        export OPENAI_AUTH_HEADER='Bearer {api-key}'
        ```
    icon_url: /assets/icons/openai.svg

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Get started with {{site.ai_gateway}}
    url: /ai-gateway/get-started/
  - text: Use LangChain with AI Proxy
    url: /how-to/use-langchain-with-ai-proxy/

automated_tests: false
---

## Clone the sample repository

Kong provides a sample stack using Elasticsearch, Logstash, and Kibana to visualize {{site.ai_gateway}} metrics.

The [kong-ai-gateway-observability](https://github.com/KongHQ-CX/kong-ai-gateway-observability) GitHub repository comes with a configured {{site.base_gateway}} instance. You can see the sample {{site.base_gateway}} configuration in [`kong.yaml`](https://github.com/KongHQ-CX/kong-ai-gateway-observability/blob/main/kong.yaml). It includes:
* A [Gateway Service](/gateway/entities/service/)
* A [Route](/gateway/entities/route/) with the `/gpt4o` path
* A [Consumer](/gateway/entities/consumer/) with the API key `Bearer department-1-api-key`
* Three plugins:
    * [HTTP Log](/plugins/http-log/) to send logs to the pre-configured Logstash server
    * [Key Authentication](/plugins/key-auth/) to authenticate the Consumer
    * [AI Proxy](/plugins/ai-proxy/) configured with OpenAI to enable a chat route

{:.info}
> The AI Proxy plugin is pre-configured with to fetch the OpenAI key from the `OPENAI_AUTH_HEADER` environment variable, as defined in the [prerequisites](#prerequisites).

To use this stack, clone the repository:
```sh
git clone https://github.com/KongHQ-CX/kong-ai-gateway-observability
cd kong-ai-gateway-observability
```

## Start the stack

Use the following command to start the sample stack:
```sh
docker compose up
```

## Send requests

Once the stack is running, open a new terminal and send some requests to the `/gpt4o` endpoint with the Consumer's API key to generate metrics. For example:
{% validation request-check %}
url: /gpt4o
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer department-1-api-key'
body:
    messages:
        - role: "system"
          content: "You are a mathematician"
        - role: "user"
          content: "What is 1+1?"
{% endvalidation %}

## Visualize the metrics

Go to the following URL to visualize your metrics in Kibana:
```
http://localhost:5601/app/dashboards#/view/aa8e4cb0-9566-11ef-beb2-c361d8db17a8
```

