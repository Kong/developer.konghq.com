---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: Expose metrics related to {{site.ai_gateway_name}} in Prometheus exposition format
---

This AI Policy allows you to expose metrics related to {{site.ai_gateway}} and proxied upstream services in [Prometheus](https://prometheus.io/docs/introduction/overview/) exposition format, which can be scraped by a Prometheus Server.

Metrics tracked by this AI Policy are available on the Status API at the `/metrics` endpoint. See [Accessing the metrics](#accessing-the-metrics) for more information.

This AI Policy records and exposes metrics at the node level. Your Prometheus server will need to discover all {{site.ai_gateway}} data plane nodes via a Service discovery mechanism, and consume data from each node's configured `/metrics` endpoint. This means metrics reflect the internal service and route data model rather than the user-facing entity model.

{:.success}
> **Grafana dashboard**: Metrics exported by this policy can be graphed in Grafana using a drop-in [dashboard](https://grafana.com/grafana/dashboards/24329-kong-ai-gateway-dashboard/).

## Accessing the metrics

To collect metrics you must enable the Status API on each data plane by passing the `KONG_STATUS_LISTEN` environment variable, the standard value is `KONG_STATUS_LISTEN=0.0.0.0:8100`. Your Prometheus instance must be able to reach each data plane on this port over the network.

Set you [Prometheus configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/) to scrape data by targeting your data plane by it's hostname and the metrics endpoint at the port you set. 

For example, a simple Prometheus configuration file might include:

```yaml
scrape_configs:
- job_name: kong-gateway
  static_configs:
  - targets:
    - ai-quickstart-gateway:8100
```

## Configure the Prometheus policy 

Configure an Prometheus AI Policy with `ai_metrics: true` to capture {{site.ai_gateway_name}} traffic:

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

## Metrics output example
Here is an example of output you could expect from the `/metrics` endpoint:

```bash
curl -i http://localhost:8001/metrics
```

Response:
```sh
HTTP/1.1 200 OK
Server: openresty/1.15.8.3
Date: Tue, 7 Jun 2020 16:35:40 GMT
Content-Type: text/plain; charset=UTF-8
Transfer-Encoding: chunked
Connection: keep-alive
Access-Control-Allow-Origin: *

# HELP kong_control_plane_connected Kong connected to control plane, 0 is unconnected
# TYPE kong_control_plane_connected gauge
kong_control_plane_connected{instance="localhost:8100", job="kong"}	1
# HELP kong_data_plane_cluster_cert_expiry_timestamp Unix timestamp of Data Plane's cluster_cert expiry time
# TYPE kong_data_plane_cluster_cert_expiry_timestamp gauge
kong_data_plane_cluster_cert_expiry_timestamp 2068058801
# HELP kong_bandwidth_bytes Total bandwidth (ingress/egress) throughput in bytes
# TYPE kong_bandwidth_bytes counter
kong_bandwidth_bytes{service="google",route="google.route-1",direction="egress",consumer=""} 264
kong_bandwidth_bytes{service="google",route="google.route-1",direction="ingress",consumer=""} 93
# HELP kong_datastore_reachable Datastore reachable from {{site.base_gateway}}, 0 is unreachable
# TYPE kong_datastore_reachable gauge
kong_datastore_reachable 1
# HELP kong_http_requests_total HTTP status codes per Consumer/Service/Route in {{site.base_gateway}}
# TYPE kong_http_requests_total counter
kong_http_requests_total{service="google",route="google.route-1",code="200",source="service",consumer=""} 1
# HELP kong_node_info {{site.base_gateway}} Node metadata information
# TYPE kong_node_info gauge
kong_node_info{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",version="3.0.0"} 1
# HELP kong_kong_latency_ms Latency added by {{site.base_gateway}} and enabled plugins for each Service/Route in {{site.base_gateway}}
# TYPE kong_kong_latency_ms histogram
kong_kong_latency_ms_bucket{service="google",route="google.route-1",le="5"} 1
kong_kong_latency_ms_bucket{service="google",route="google.route-1",le="7"} 1
kong_kong_latency_ms_bucket{service="google",route="google.route-1",le="10"} 1
kong_kong_latency_ms_bucket{service="google",route="google.route-1",le="15"} 1
kong_kong_latency_ms_bucket{service="google",route="google.route-1",le="20"} 1
kong_kong_latency_ms_bucket{service="google",route="google.route-1",le="30"} 1
kong_kong_latency_ms_bucket{service="google",route="google.route-1",le="50"} 1
kong_kong_latency_ms_bucket{service="google",route="google.route-1",le="75"} 1
kong_kong_latency_ms_bucket{service="google",route="google.route-1",le="100"} 1
kong_kong_latency_ms_bucket{service="google",route="google.route-1",le="200"} 1
kong_kong_latency_ms_bucket{service="google",route="google.route-1",le="500"} 1
kong_kong_latency_ms_bucket{service="google",route="google.route-1",le="750"} 1
kong_kong_latency_ms_bucket{service="google",route="google.route-1",le="1000"} 1
kong_kong_latency_ms_bucket{service="google",route="google.route-1",le="+Inf"} 1
kong_kong_latency_ms_count{service="google",route="google.route-1"} 1
kong_kong_latency_ms_sum{service="google",route="google.route-1"} 4
...
```

## Available metrics

You can expose the following metrics:

- **DB reachability**: A gauge type with a value of 0 or 1, which represents
  whether the database can be reached by a {{site.ai_gateway}} node.
- **Connections**: Various Nginx connection metrics like active, reading,
  writing, and number of accepted connections.
- **Dataplane Status**: The last seen timestamp, config hash, config sync status, and certificate expiration timestamp for
Data Plane nodes are exported to the Control Plane.
- **Enterprise License Information**: The {{site.ai_gateway}} license expiration date, features and
license signature. Those metrics are only exported on self-managed {{site.ai_gateway}}.
- **DB Entity Count**: A gauge metric that
    measures the current number of database entities.
- **Number of Nginx timers** : A gauge metric that measures the total number of Nginx
    timers in a Running or Pending state.
- **AI LLM metrics**: AI LLM metrics are available per provider, model, cache, database name (if cached), embeddings provider (if cached), embeddings model (if cached), and Workspace.

### Optional metrics
The following metrics are disabled by default as it may create high cardinality of metrics and may
cause performance issues.

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

{% include md/ai-gateway/v2/llm-metrics.md %}