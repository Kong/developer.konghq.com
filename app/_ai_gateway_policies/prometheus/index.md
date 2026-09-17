---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: Expose metrics related to {{site.ai_gateway_name}} in Prometheus exposition format
related_resources:
  - text: "{{site.konnect_product_name}} Observability"
    url: /observability/
  - text: "OpenTelemetry Policy"
    url: /ai-gateway/policies/opentelemetry/
  - text: "Monitor AI LLM metrics"
    url: /ai-gateway/monitor-ai-llm-metrics/
---

This AI Policy allows you to expose metrics related to {{site.ai_gateway}} and proxied upstream services in [Prometheus](https://prometheus.io/docs/introduction/overview/) exposition format, which can be scraped by a Prometheus Server.

Metrics tracked by this AI Policy are available on the Status API at the `/metrics` endpoint. See [Accessing the metrics](#accessing-the-metrics) for more information.

This AI Policy records and exposes metrics at the node level. Your Prometheus server will need to discover all {{site.ai_gateway}} data plane nodes via a Service discovery mechanism, and consume data from each node's configured `/metrics` endpoint. This means metrics reflect the internal service and route data model rather than the user-facing entity model.

{:.success}
> **Grafana dashboard**: Metrics exported by this policy can be graphed in Grafana using a drop-in [dashboard](https://grafana.com/grafana/dashboards/24329-kong-ai-gateway-dashboard/).

## Accessing the metrics

To collect metrics you must enable the Status API on each data plane by passing the `KONG_STATUS_LISTEN` environment variable, the standard value is `KONG_STATUS_LISTEN=0.0.0.0:8100`. Your Prometheus instance must be able to reach each data plane on this port over the network.

Configure a Prometheus AI Policy with `ai_metrics: true` to capture {{site.ai_gateway_name}} traffic:

{% entity_example %}
type: policy
data:
  name: my-prometheus-policy
  type: prometheus
  display_name: "My Prometheus Policy"
  config:
    ai_metrics: true
    status_code_metrics: true
    latency_metrics: true
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

Set your [Prometheus configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/) to scrape data by targeting your data plane by it's hostname and the metrics endpoint at the port you set.

For example, a simple Prometheus configuration file could include:

```yaml
scrape_configs:
- job_name: kong-gateway
  static_configs:
  - targets:
    - ai-quickstart-gateway:8100
```

## Available metrics

You can expose the following metrics:

- **DB reachability**: A gauge type with a value of 0 or 1, which represents
  whether the database can be reached by a {{site.ai_gateway}} node.
- **Connections**: Various Nginx connection metrics like active, reading,
  writing, and number of accepted connections.
- **Data Plane Status**: The last seen timestamp, config hash, config sync status, and certificate expiration timestamp for
Data Plane nodes are exported to the Control Plane.
- **Enterprise License Information**: The {{site.ai_gateway}} license expiration date, features and
license signature. Those metrics are only exported on self-managed {{site.ai_gateway}}.
- **DB Entity Count**: A gauge metric that
    measures the current number of database entities.
- **Number of Nginx timers**: A gauge metric that measures the total number of Nginx
    timers in a Running or Pending state.
- **AI LLM metrics**: AI LLM metrics are available per provider, model, cache, database name (if cached), embeddings provider (if cached), embeddings model (if cached), and Workspace.

{:.info}
> **Note:** Metrics in Prometheus may be prefixed by a `kong` label.

### Optional metrics
The following metrics are disabled by default as it may create high cardinality of metrics and may
cause performance issues.

{% include md/ai-gateway/v2/llm-metrics.md %}

#### Status code metrics
When [`config.status_code_metrics`](/ai-gateway/policies/prometheus/reference/#schema--config-status-code-metrics) is set to true:
- **Status codes**: HTTP status codes returned by {{site.ai_gateway}}.
  - **`http_requests_total`**: HTTP status codes per Consumer/Service/Route at {{site.ai_gateway}}.
  - **`stream_session_total`**: Stream status codes per Service/Route in {{site.ai_gateway}}.

#### Latency metrics
When [`config.latency_metrics`](/ai-gateway/policies/prometheus/reference/#schema--config-latency-metrics) is set to true:
- **Latencies Histograms**: Latency (in ms), as measured at {{site.ai_gateway}}:
   - **Request**: Total time taken by {{site.ai_gateway}} and upstream services to serve
     requests.
   - **{{site.ai_gateway}}**: Time taken for {{site.ai_gateway}} to route a request and run all configured
     plugins.
   - **Upstream**: Time taken by the upstream service to respond to requests.

#### Bandwidth metrics
When [`config.bandwidth_metrics`](/ai-gateway/policies/prometheus/reference/#schema--config-bandwidth-metrics) is set to true:
- **Bandwidth**: Total Bandwidth (egress/ingress) flowing through {{site.ai_gateway}}.
  This metric is available per Service and as a sum across all Services.

#### Upstream health metrics
When [`config.upstream_health_metrics`](/ai-gateway/policies/prometheus/reference/#schema--config-upstream-health-metrics) is set to true:
- **Target Health**: The healthiness status (`healthchecks_off`, `healthy`, `unhealthy`, or `dns_error`) of Targets
  belonging to a given Upstream as well as their subsystem (`http` or `stream`).

{:.info}
> **Note:** Upstream targets' health information is exported once per subsystem. If both
stream and HTTP listeners are enabled, targets' health will appear twice. Health metrics
have a `subsystem` label to indicate which subsystem the metric refers to.

## Metrics output example

Here is an example of output you could expect from the `/metrics` endpoint:

```bash
curl -i http://localhost:8100/metrics
```

Response:
```sh
HTTP/1.1 200 OK
Date: Thu, 17 Sep 2026 16:04:29 GMT
Content-Type: text/plain; charset=UTF-8
Transfer-Encoding: chunked
Connection: keep-alive
Access-Control-Allow-Origin: *
X-Kong-Status-Request-ID: swA08FHVHQdk3rSJAqf96TKAWjBpYLCf
X-Kong-Admin-Latency: 2
Server: kong/2.1.0-ai-gateway

# HELP kong_ai_llm_provider_latency_ms LLM response Latency for each AI plugins per ai_provider in Kong
# TYPE kong_ai_llm_provider_latency_ms histogram
kong_ai_llm_provider_latency_ms_bucket{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot",le="1500"} 1
kong_ai_llm_provider_latency_ms_bucket{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot",le="2000"} 1
...
kong_ai_llm_provider_latency_ms_bucket{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot",le="+Inf"} 1
kong_ai_llm_provider_latency_ms_count{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot"} 1
kong_ai_llm_provider_latency_ms_sum{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot"} 1029
# HELP kong_ai_llm_requests_total AI requests total per ai_provider in Kong
# TYPE kong_ai_llm_requests_total counter
kong_ai_llm_requests_total{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot"} 1
# HELP kong_ai_llm_tokens_total AI requests cost per ai_provider/cache in Kong
# TYPE kong_ai_llm_tokens_total counter
kong_ai_llm_tokens_total{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",token_type="completion_tokens",workspace="default",consumer=""} 12
kong_ai_llm_tokens_total{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",token_type="prompt_tokens",workspace="default",consumer=""} 13
kong_ai_llm_tokens_total{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",token_type="total_tokens",workspace="default",consumer=""} 25
# HELP kong_ai_llm_tpot_latency_ms LLM time per token latency for each AI plugins per ai_provider in Kong
# TYPE kong_ai_llm_tpot_latency_ms histogram
kong_ai_llm_tpot_latency_ms_bucket{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot",le="100"} 1
kong_ai_llm_tpot_latency_ms_bucket{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot",le="200"} 1
...
kong_ai_llm_tpot_latency_ms_bucket{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot",le="+Inf"} 1
kong_ai_llm_tpot_latency_ms_count{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot"} 1
kong_ai_llm_tpot_latency_ms_sum{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot"} 85.75
# HELP kong_ai_llm_ttft_latency_ms LLM time to first token latency for each AI plugins per ai_provider in Kong
# TYPE kong_ai_llm_ttft_latency_ms histogram
kong_ai_llm_ttft_latency_ms_bucket{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot",le="1500"} 1
kong_ai_llm_ttft_latency_ms_bucket{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot",le="2000"} 1
...
kong_ai_llm_ttft_latency_ms_bucket{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot",le="+Inf"} 1
kong_ai_llm_ttft_latency_ms_count{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot"} 1
kong_ai_llm_ttft_latency_ms_sum{ai_provider="openai",ai_model="gpt-4o",cache_status="",vector_db="",embeddings_provider="",embeddings_model="",workspace="default",consumer="",request_mode="oneshot"} 1029
# HELP kong_control_plane_connected Kong connected to control plane, 0 is unconnected
# TYPE kong_control_plane_connected gauge
kong_control_plane_connected 1
# HELP kong_data_plane_cluster_cert_expiry_timestamp Unix timestamp of Data Plane's cluster_cert expiry time
# TYPE kong_data_plane_cluster_cert_expiry_timestamp gauge
kong_data_plane_cluster_cert_expiry_timestamp 1792252942
# HELP kong_datastore_reachable Datastore reachable from Kong, 0 is unreachable
# TYPE kong_datastore_reachable gauge
kong_datastore_reachable 1
# HELP kong_http_requests_total HTTP status codes per consumer/service/route in Kong
# TYPE kong_http_requests_total counter
kong_http_requests_total{service="ai-gateway",route="openai-chat",code="200",source="service",type="",workspace="default",consumer=""} 1
# HELP kong_kong_internal_latency_ms Internal latency for each service/route in Kong, excluding the I/O latency
# TYPE kong_kong_internal_latency_ms histogram
kong_kong_internal_latency_ms_bucket{service="ai-gateway",route="openai-chat",workspace="default",le="10"} 1
kong_kong_internal_latency_ms_bucket{service="ai-gateway",route="openai-chat",workspace="default",le="15"} 1
kong_kong_internal_latency_ms_bucket{service="ai-gateway",route="openai-chat",workspace="default",le="20"} 1
...
```