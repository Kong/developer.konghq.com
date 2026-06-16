---
title: "Monitor AI LLM metrics"
content_type: reference
layout: reference

products:
  - ai-gateway
breadcrumbs:
  - /ai-gateway/
tags:
  - ai
  - monitoring

min_version:
  ai-gateway: '2.0'

description: "This guide walks you through collecting AI metrics and sending them to Prometheus."

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Status API
    url: /api/gateway/status/
  - text: Admin API
    url: /api/gateway/admin-ee/
  - text: Visualize AI metrics with Grafana
    url: /how-to/visualize-llm-metrics-with-grafana/

works_on:
  - konnect
---

{{site.ai_gateway}} calls LLM-based services according to the settings of your [Providers](/ai-gateway/entities/ai-provider/) and [Models](/ai-gateway/entities/ai-model/). You can use the built in logging and a [Prometheus](/plugins/prometheus/) Policy to aggregate the LLM provider responses to count the number of tokens sent through {{site.ai_gateway}}. If you have defined input and output costs in the models, you can also calculate aggregate costs. You can also track whether the requests have been cached by {{site.ai_gateway}}, saving the cost of contacting the LLM providers, which improves performance.

In addition to LLM usage, {{site.ai_gateway}} can also log MCP server traffic. [MCP logging](/ai-gateway/entities/ai-mcp-server/#logging-and-audits) provides visibility into latency, response sizes, and error rates when AI plugins invoke external MCP tools and servers.

Create a [Prometheus Policy](/plugins/prometheus/) to expose metrics in the [Prometheus](https://prometheus.io/docs/introduction/overview/) exposition format, which can be scraped by a Prometheus server.

The [Prometheus Policy](/plugins/prometheus/) records and exposes metrics at the node level. Your Prometheus server will need to discover all Kong nodes via a service discovery mechanism,
and consume data from each node's Prometheus `/metrics` endpoint.

AI metrics exported by the Prometheus plugin can be graphed in Grafana using [{{site.ai_gateway}} Dashboard](https://grafana.com/grafana/dashboards/21162-kong-cx-ai/).

## Available metrics

The following sections describe the AI metrics that are available.

{% include /ai-gateway/v2/llm-metrics.md %}

## Overview

AI metrics are disabled by default as it may create high number of metrics and may cause performance issues. To enable them:

* Set `config.ai_metrics` to `true` in the [Prometheus Policy configuration](/plugins/prometheus/reference/).
* Set `config.logging.log_statistics` to `true` in the [Model](/ai-gateway/entities/ai-model/).

### LLM traffic metrics overview

Here is an example of output you could expect from the `/metrics` endpoint for LLM traffic:

```sh
# HELP ai_llm_requests_total AI requests total per ai_provider in Kong
# TYPE ai_llm_requests_total counter
ai_llm_requests_total{ai_provider="provider1",ai_model="model1",cache_status="hit",vector_db="redis",embeddings_provider="openai",embeddings_model="text-embedding-3-large","request_mode"="oneshot",Workspace="workspace1",consumer="consumer1"} 100

# HELP ai_llm_cost_total AI requests cost per ai_provider/cache in Kong
# TYPE ai_llm_cost_total counter
ai_llm_cost_total{ai_provider="provider1",ai_model="model1",cache_status="hit",vector_db="redis",embeddings_provider="openai",embeddings_model="text-embedding-3-large","request_mode"="oneshot",Workspace="workspace1",consumer="consumer1"} 50

# HELP ai_llm_provider_latency AI latencies per ai_provider in Kong
# TYPE ai_llm_provider_latency bucket
ai_llm_provider_latency_ms_bucket{ai_provider="provider1",ai_model="model1",cache_status="",vector_db="",embeddings_provider="",embeddings_model="","request_mode"="oneshot",Workspace="workspace1",le="+Inf",consumer="consumer1"} 2

# HELP ai_llm_tokens_total AI tokens total per ai_provider/cache in Kong
# TYPE ai_llm_tokens_total counter
ai_llm_tokens_total{ai_provider="provider1",ai_model="model1",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",token_type="prompt_tokens",Workspace="workspace1",consumer="consumer1"} 1000
ai_llm_tokens_total{ai_provider="provider1",ai_model="model1",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",token_type="completion_tokens",Workspace="workspace1",consumer="consumer1"} 2000
ai_llm_tokens_total{ai_provider="provider1",ai_model="model1",cache_status="hit",vector_db="redis",embeddings_provider="openai",embeddings_model="text-embedding-3-large",token_type="total_tokens",Workspace="workspace1",consumer="consumer1"} 3000

# HELP ai_cache_fetch_latency AI cache latencies per ai_provider/database in Kong
# TYPE ai_cache_fetch_latency bucket
ai_cache_fetch_latency{ai_provider="provider1",ai_model="model1",cache_status="hit",vector_db="redis",embeddings_provider="openai",embeddings_model="text-embedding-3-large","request_mode"="oneshot",Workspace="workspace1",le="+Inf",consumer="consumer1"} 2

# HELP ai_cache_embeddings_latency AI cache latencies per ai_provider/database in Kong
# TYPE ai_cache_embeddings_latency bucket
ai_cache_embeddings_latency{ai_provider="provider1",ai_model="model1",cache_status="hit",vector_db="redis",embeddings_provider="openai",embeddings_model="text-embedding-3-large","request_mode"="oneshot",Workspace="workspace1",le="+Inf",consumer="consumer1"} 2

# HELP ai_llm_provider_latency AI cache latencies per ai_provider/database in Kong
# TYPE ai_llm_provider_latency bucket
ai_llm_provider_latency{ai_provider="provider1",ai_model="model1",cache_status="hit",vector_db="redis",embeddings_provider="openai",embeddings_model="text-embedding-3-large","request_mode"="oneshot",Workspace="workspace1",le="+Inf",consumer="consumer1"} 2
```

{:.info}
> **Note:** If you don't use any caching, then `cache_status`, `vector_db`,
`embeddings_provider`, and `embeddings_model` values will be empty.
>
> To expose the `ai_llm_cost_total` metric, you must define the `model.options.input_cost` `model.options.output_cost` parameters. See the [Model](/ai-gateway/entities/ai-model/) configuration reference for more details.

### MCP traffic metrics overview

Here is an example of output you could expect from the `/metrics` endpoint for MCP traffic:

```sh
# HELP kong_ai_mcp_response_body_size_bytes MCP server response body sizes in bytes
# TYPE kong_ai_mcp_response_body_size_bytes histogram
kong_ai_mcp_response_body_size_bytes_bucket{service="svc1",route="route1",method="tools/call",workspace="workspace1",tool_name="tool1",le="+Inf"} 1

# HELP kong_ai_mcp_latency_ms MCP server latencies in milliseconds
# TYPE kong_ai_mcp_latency_ms histogram
kong_ai_mcp_latency_ms_bucket{service="svc1",route="route1",method="tools/call",workspace="workspace1",tool_name="tool1",le="+Inf"} 1

# HELP kong_ai_mcp_error_total Total MCP server errors by type
# TYPE kong_ai_mcp_error_total counter
kong_ai_mcp_error_total{service="svc1",route="route1",type="Invalid Request",method="tools/call",workspace="workspace1",tool_name=""} 3
```

## Accessing the metrics

In most configurations, the Kong Admin API and Prometheus Policy will be behind a firewall or would
need to be set up to require authentication. Here are a couple of options to
allow access to the `/metrics` endpoint to Prometheus:

* If the Status API is enabled with the `status_listen` parameter in the [{{site.base_gateway}} configuration](/ai-gateway/configuration/#status-listen), then its `/metrics` endpoint can be used. This is the preferred method, and this is also the only method compatible with {{site.konnect_short_name}}, since Data Planes can't use the Admin API.

* The `/metrics` endpoint is also available on the Admin API, which can be used
if the Status API is not enabled. Note that this endpoint is unavailable
when [RBAC](/api/gateway/admin-ee/#/operations/get-rbac-users) is enabled on the
Admin API, as Prometheus doesn't support key authentication to pass the RBAC token.


