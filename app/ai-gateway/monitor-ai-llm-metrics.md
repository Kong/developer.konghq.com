---
title: "Monitor AI LLM metrics"
content_type: reference
layout: reference

products:
  - ai-gateway
  - gateway
breadcrumbs:
  - /ai-gateway/
tags:
  - ai
  - monitoring

plugins:
  - prometheus
  - ai-proxy
  - ai-proxy-advanced

min_version:
  gateway: '3.7'

description: "This guide walks you through collecting AI metrics and sending them to Prometheus."

related_resources:
  - text: Kong AI Gateway
    url: /ai-gateway/
  - text: Kong AI Gateway plugins
    url: /plugins/?category=ai
  - text: Status API
    url: /api/gateway/status/
  - text: Admin API
    url: /api/gateway/admin-ee/
  - text: Visualize AI metrics with Grafana
    url: /how-to/visualize-llm-metrics-with-grafana/

works_on:
  - on-prem
  - konnect
---

Kong AI Gateway calls LLM-based services according to the settings of the [AI Proxy](/plugins/ai-proxy/) and [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugins.
You can aggregate the LLM provider responses to count the number of tokens used by the AI plugins.
If you have defined input and output costs in the models, you can also calculate cost aggregation.
The metrics details also expose whether the requests have been cached by {{site.base_gateway}}, saving the cost of contacting the LLM providers, which improves performance.

Kong AI Gateway exposes metrics related to Kong and proxied upstream services in
[Prometheus](https://prometheus.io/docs/introduction/overview/)
exposition format, which can be scraped by a Prometheus server.

The metrics are available on both the [Admin API](/api/gateway/admin-ee/) and the
[Status API](/api/gateway/status/)  at the `http://{host}:{port}/metrics` endpoint.
Note that the URL to those APIs is specific to your
installation. See [Accessing the metrics](#accessing-the-metrics) for more information.

The [Prometheus plugin](/plugins/prometheus/) records and exposes metrics at the node level. Your Prometheus
server will need to discover all Kong nodes via a service discovery mechanism,
and consume data from each node's configured `/metrics` endpoint.

AI metrics exported by the plugin can be graphed in Grafana using a [drop-in
dashboard](https://grafana.com/grafana/dashboards/21162-kong-cx-ai/).

## Available metrics

When the `config.ai_metrics` parameter is set to `true` in the Prometheus plugin, you can get the following AI LLM metrics:

- **AI Requests**: AI request sent to LLM providers.
- **AI Cost**: AI cost charged by LLM providers.
- **AI Tokens**: AI tokens counted by LLM providers.
- **AI LLM Latency**: {% new_in 3.8 %} Time taken to return a response by LLM providers.
- **AI Cache Fetch Latency**: {% new_in 3.8 %} Time taken to return a response from the cache.
- **AI Cache Embeddings Latency**: {% new_in 3.8 %} Time taken to generate embedding during the cache.

These metrics are available per provider, model, cache, database name (if cached), embeddings provider (if cached), embeddings model (if cached), and Workspace. The AI Tokens metrics are also available per token type.


AI metrics are disabled by default as it may create high cardinality of metrics and may
cause performance issues. To enable them:

* Set `config.ai_metrics` to `true` in the [Prometheus plugin configuration](/plugins/prometheus/reference/).
* Set `config.logging.log_statistics` to `true` in the [AI Proxy](/plugins/ai-proxy/reference/) or [AI Proxy Advanced plugin](/plugins/ai-proxy-advanced/reference/).

Here is an example of output you could expect from the `/metrics` endpoint:

```sh
# HELP ai_llm_requests_total AI requests total per ai_provider in Kong
# TYPE ai_llm_requests_total counter
ai_llm_requests_total{ai_provider="provider1",ai_model="model1",cache_status="hit",vector_db="redis",embeddings_provider="openai",embeddings_model="text-embedding-3-large",Workspace="workspace1"} 100

# HELP ai_llm_cost_total AI requests cost per ai_provider/cache in Kong
# TYPE ai_llm_cost_total counter
ai_llm_cost_total{ai_provider="provider1",ai_model="model1",cache_status="hit",vector_db="redis",embeddings_provider="openai",embeddings_model="text-embedding-3-large",Workspace="workspace1"} 50

# HELP ai_llm_provider_latency AI latencies per ai_provider in Kong
# TYPE ai_llm_provider_latency bucket
ai_llm_provider_latency_ms_bucket{ai_provider="provider1",ai_model="model1",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",Workspace="workspace1",le="+Inf"} 2

# HELP ai_llm_tokens_total AI tokens total per ai_provider/cache in Kong
# TYPE ai_llm_tokens_total counter
ai_llm_tokens_total{ai_provider="provider1",ai_model="model1",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",token_type="prompt_tokens",Workspace="workspace1"} 1000
ai_llm_tokens_total{ai_provider="provider1",ai_model="model1",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",token_type="completion_tokens",Workspace="workspace1"} 2000
ai_llm_tokens_total{ai_provider="provider1",ai_model="model1",cache_status="hit",vector_db="redis",embeddings_provider="openai",embeddings_model="text-embedding-3-large",token_type="total_tokens",Workspace="workspace1"} 3000

# HELP ai_cache_fetch_latency AI cache latencies per ai_provider/database in Kong
# TYPE ai_cache_fetch_latency bucket
ai_cache_fetch_latency{ai_provider="provider1",ai_model="model1",cache_status="hit",vector_db="redis",embeddings_provider="openai",embeddings_model="text-embedding-3-large",Workspace="workspace1",le="+Inf"} 2

# HELP ai_cache_embeddings_latency AI cache latencies per ai_provider/database in Kong
# TYPE ai_cache_embeddings_latency bucket
ai_cache_embeddings_latency{ai_provider="provider1",ai_model="model1",cache_status="hit",vector_db="redis",embeddings_provider="openai",embeddings_model="text-embedding-3-large",Workspace="workspace1",le="+Inf"} 2

# HELP ai_llm_provider_latency AI cache latencies per ai_provider/database in Kong
# TYPE ai_llm_provider_latency bucket
ai_llm_provider_latency{ai_provider="provider1",ai_model="model1",cache_status="hit",vector_db="redis",embeddings_provider="openai",embeddings_model="text-embedding-3-large",Workspace="workspace1",le="+Inf"} 2
```

{:.info}
> **Note:** If you don't use any cache plugins, then `cache_status`, `vector_db`,
`embeddings_provider`, and `embeddings_model` values will be empty.
>
> To expose the `ai_llm_cost_total` metric, you must define the `model.options.input_cost` `model.options.output_cost` parameters. See the [AI Proxy](/plugins/ai-proxy/reference/#schema--config-model-options-input-cost) and [AI Proxy Advanced](/plugins/ai-proxy-advanced/reference/#schema--config-targets-model-options-input-cost) configuration references for more details.

## Accessing the metrics

In most configurations, the Kong Admin API will be behind a firewall or would
need to be set up to require authentication. Here are a couple of options to
allow access to the `/metrics` endpoint to Prometheus:


* If the Status API is enabled with the `status_listen` parameter in the [{{site.base_gateway}} configuration](/gateway/configuration/#status-listen), then its `/metrics` endpoint can be used. This is the preferred method, and this is also the only method compatible with {{site.konnect_short_name}}, since Data Planes can't use the Admin API.

* The `/metrics` endpoint is also available on the Admin API, which can be used
if the Status API is not enabled. Note that this endpoint is unavailable
when [RBAC](/api/gateway/admin-ee/#/operations/get-rbac-users) is enabled on the
Admin API, as Prometheus doesn't support key authentication to pass the RBAC token.


