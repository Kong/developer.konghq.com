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
  - text: Prometheus Policy
    url: /ai-gateway/policies/prometheus/
  - text: "{{ site.ai_gateway }} audit log reference"
    url: /ai-gateway/ai-audit-log-reference/

works_on:
  - konnect
---

{{site.ai_gateway}} calls LLM-based services according to the settings of your [AI Model Providers](/ai-gateway/entities/ai-model-provider/) and [Models](/ai-gateway/entities/ai-model/). You can use the built in logging and a [Prometheus](/ai-gateway/policies/prometheus/) Policy to aggregate the LLM provider responses to count the number of tokens sent through {{site.ai_gateway}}. If you have defined input and output costs in the models, you can also calculate aggregate costs. You can also track whether the requests have been cached by {{site.ai_gateway}}, saving the cost of contacting the LLM providers, which improves performance.

In addition to LLM usage, {{site.ai_gateway}} can also log MCP server traffic. [MCP logging](/ai-gateway/entities/ai-mcp-server/#logging-and-audits) provides visibility into latency, response sizes, and error rates when AI Policies invoke external MCP tools and servers.

Create a [Prometheus Policy](/ai-gateway/policies/prometheus/) to expose metrics in the [Prometheus](https://prometheus.io/docs/introduction/overview/) exposition format, which can be scraped by a Prometheus server.

The [Prometheus Policy](/ai-gateway/policies/prometheus/) records and exposes metrics at the node level. Your Prometheus server will need to discover all Kong nodes via a service discovery mechanism,
and consume data from each node's Prometheus `/metrics` endpoint.

## Available metrics

The following sections describe the AI metrics that are available.

{% include md/ai-gateway/v2/llm-metrics.md %}

## Overview

AI metrics are disabled by default, as generating them may create a high number of metrics and affect performance. To enable them, set `config.ai_metrics` to `true` in the [Prometheus Policy configuration](/ai-gateway/policies/prometheus/reference/). The [AI Model](/ai-gateway/entities/ai-model/) entity automatically collects the statistics that populate these metrics, so no separate AI Model-level configuration is required.

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

{{site.ai_gateway}} data plane nodes don't expose an Admin API, so the Status API is the only way to reach the `/metrics` endpoint. Enable the Status API with the `status_listen` parameter in the [{{site.ai_gateway}} configuration](/ai-gateway/configuration/#status_listen), then point your Prometheus server at each node's `/metrics` endpoint.

In most configurations, this endpoint should sit behind a firewall or require authentication, since it isn't exposed publicly by default.
