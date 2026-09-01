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

This AI Policy records and exposes metrics at the node level. Your Prometheus server will need to discover all {{site.ai_gateway}} nodes via a Service discovery mechanism, and consume data from each node's configured `/metrics` endpoint. This means metrics reflect the internal service and route data model rather than the user-facing entity model.

{:.success}
> **Grafana dashboard**: Metrics exported by the Prometheus AI Policy can be graphed in Grafana using a drop-in dashboard: [https://grafana.com/grafana/dashboards/7424-kong-official/](https://grafana.com/grafana/dashboards/7424-kong-official/).

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

## Accessing the metrics

In most configurations the {{site.ai_gateway}} will be deployed using {{site.konnect_short_name}}, you must enable the Status API to use the `/metrics` endpoint.

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
# HELP kong_memory_lua_shared_dict_bytes Allocated slabs in bytes in a shared_dict
# TYPE kong_memory_lua_shared_dict_bytes gauge
kong_memory_lua_shared_dict_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong",kong_subsystem="http"} 40960
kong_memory_lua_shared_dict_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_cluster_events",kong_subsystem="http"} 40960
kong_memory_lua_shared_dict_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_core_db_cache",kong_subsystem="http"} 823296
kong_memory_lua_shared_dict_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_core_db_cache_miss",kong_subsystem="http"} 90112
kong_memory_lua_shared_dict_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_db_cache",kong_subsystem="http"} 794624
kong_memory_lua_shared_dict_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_db_cache_miss",kong_subsystem="http"} 86016
kong_memory_lua_shared_dict_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_healthchecks",kong_subsystem="http"} 40960
kong_memory_lua_shared_dict_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_locks",kong_subsystem="http"} 61440
kong_memory_lua_shared_dict_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_process_events",kong_subsystem="http"} 40960
kong_memory_lua_shared_dict_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_rate_limiting_counters",kong_subsystem="http"} 86016
kong_memory_lua_shared_dict_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="prometheus_metrics",kong_subsystem="http"} 57344
# HELP kong_memory_lua_shared_dict_total_bytes Total capacity in bytes of a shared_dict
# TYPE kong_memory_lua_shared_dict_total_bytes gauge
kong_memory_lua_shared_dict_total_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong",kong_subsystem="http"} 5242880
kong_memory_lua_shared_dict_total_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_cluster_events",kong_subsystem="http"} 5242880
kong_memory_lua_shared_dict_total_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_core_db_cache",kong_subsystem="http"} 134217728
kong_memory_lua_shared_dict_total_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_core_db_cache_miss",kong_subsystem="http"} 12582912
kong_memory_lua_shared_dict_total_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_db_cache",kong_subsystem="http"} 134217728
kong_memory_lua_shared_dict_total_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_db_cache_miss",kong_subsystem="http"} 12582912
kong_memory_lua_shared_dict_total_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_healthchecks",kong_subsystem="http"} 5242880
kong_memory_lua_shared_dict_total_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_locks",kong_subsystem="http"} 8388608
kong_memory_lua_shared_dict_total_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_process_events",kong_subsystem="http"} 5242880
kong_memory_lua_shared_dict_total_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="kong_rate_limiting_counters",kong_subsystem="http"} 12582912
kong_memory_lua_shared_dict_total_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",shared_dict="prometheus_metrics",kong_subsystem="http"} 5242880
# HELP kong_memory_workers_lua_vms_bytes Allocated bytes in worker Lua VM
# TYPE kong_memory_workers_lua_vms_bytes gauge
kong_memory_workers_lua_vms_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",pid="21173",kong_subsystem="http"} 64329517
kong_memory_workers_lua_vms_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",pid="21174",kong_subsystem="http"} 46314808
kong_memory_workers_lua_vms_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",pid="21175",kong_subsystem="http"} 46681598
kong_memory_workers_lua_vms_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",pid="21176",kong_subsystem="http"} 46637209
kong_memory_workers_lua_vms_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",pid="21177",kong_subsystem="http"} 46234336
kong_memory_workers_lua_vms_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",pid="21178",kong_subsystem="http"} 46180420
kong_memory_workers_lua_vms_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",pid="21179",kong_subsystem="http"} 46161105
kong_memory_workers_lua_vms_bytes{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",pid="21180",kong_subsystem="http"} 46366877
# HELP kong_nginx_connections_total Number of connections by subsystem
# TYPE kong_nginx_connections_total gauge
kong_nginx_connections_total{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",subsystem="http",state="accepted"} 296
kong_nginx_connections_total{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",subsystem="http",state="active"} 9
kong_nginx_connections_total{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",subsystem="http",state="handled"} 296
kong_nginx_connections_total{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",subsystem="http",state="reading"} 0
kong_nginx_connections_total{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",subsystem="http",state="total"} 296
kong_nginx_connections_total{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",subsystem="http",state="waiting"} 0
kong_nginx_connections_total{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",subsystem="http",state="writing"} 9
# HELP kong_nginx_metric_errors_total Number of nginx-lua-prometheus errors
# TYPE kong_nginx_metric_errors_total counter
kong_nginx_metric_errors_total 0
# HELP kong_nginx_requests_total Total number of requests
# TYPE kong_nginx_requests_total gauge
kong_nginx_requests_total{node_id="849373c5-45c1-4c1d-b595-fdeaea6daed8",subsystem="http"} 296
# HELP kong_nginx_timers Number of Nginx timers
# TYPE kong_nginx_timers gauge
kong_nginx_timers{state="pending"} 1
kong_nginx_timers{state="running"} 39
# HELP kong_request_latency_ms Total latency incurred during requests for each Service/Route in {{site.base_gateway}}
# TYPE kong_request_latency_ms histogram
kong_request_latency_ms_bucket{service="google",route="google.route-1",le="25"} 1
kong_request_latency_ms_bucket{service="google",route="google.route-1",le="50"} 1
kong_request_latency_ms_bucket{service="google",route="google.route-1",le="80"} 1
kong_request_latency_ms_bucket{service="google",route="google.route-1",le="100"} 1
kong_request_latency_ms_bucket{service="google",route="google.route-1",le="250"} 1
kong_request_latency_ms_bucket{service="google",route="google.route-1",le="400"} 1
kong_request_latency_ms_bucket{service="google",route="google.route-1",le="700"} 1
kong_request_latency_ms_bucket{service="google",route="google.route-1",le="1000"} 1
kong_request_latency_ms_bucket{service="google",route="google.route-1",le="2000"} 1
kong_request_latency_ms_bucket{service="google",route="google.route-1",le="5000"} 1
kong_request_latency_ms_bucket{service="google",route="google.route-1",le="10000"} 1
kong_request_latency_ms_bucket{service="google",route="google.route-1",le="30000"} 1
kong_request_latency_ms_bucket{service="google",route="google.route-1",le="60000"} 1
kong_request_latency_ms_bucket{service="google",route="google.route-1",le="+Inf"} 1
kong_request_latency_ms_count{service="google",route="google.route-1"} 1
kong_request_latency_ms_sum{service="google",route="google.route-1"} 6
# HELP kong_upstream_latency_ms Latency added by upstream response for each Service/Route in {{site.base_gateway}}
# TYPE kong_upstream_latency_ms histogram
kong_upstream_latency_ms_bucket{service="google",route="google.route-1",le="25"} 1
kong_upstream_latency_ms_bucket{service="google",route="google.route-1",le="50"} 1
kong_upstream_latency_ms_bucket{service="google",route="google.route-1",le="80"} 1
kong_upstream_latency_ms_bucket{service="google",route="google.route-1",le="100"} 1
kong_upstream_latency_ms_bucket{service="google",route="google.route-1",le="250"} 1
kong_upstream_latency_ms_bucket{service="google",route="google.route-1",le="400"} 1
kong_upstream_latency_ms_bucket{service="google",route="google.route-1",le="700"} 1
kong_upstream_latency_ms_bucket{service="google",route="google.route-1",le="1000"} 1
kong_upstream_latency_ms_bucket{service="google",route="google.route-1",le="2000"} 1
kong_upstream_latency_ms_bucket{service="google",route="google.route-1",le="5000"} 1
kong_upstream_latency_ms_bucket{service="google",route="google.route-1",le="10000"} 1
kong_upstream_latency_ms_bucket{service="google",route="google.route-1",le="30000"} 1
kong_upstream_latency_ms_bucket{service="google",route="google.route-1",le="60000"} 1
kong_upstream_latency_ms_bucket{service="google",route="google.route-1",le="+Inf"} 1
kong_upstream_latency_ms_count{service="google",route="google.route-1"} 1
kong_upstream_latency_ms_sum{service="google",route="google.route-1"} 2

# HELP kong_nginx_timers Number of nginx timers
# TYPE kong_nginx_timers gauge
kong_nginx_timers{state="running"} 3
kong_nginx_timers{state="pending"} 1
# HELP kong_datastore_reachable Datastore reachable from {{site.base_gateway}}, 0 is unreachable
# TYPE kong_datastore_reachable gauge
kong_datastore_reachable 1
# HELP kong_http_consumer_status HTTP status codes for customer per Service/Route in {{site.base_gateway}}
# TYPE kong_http_consumer_status counter
kong_http_consumer_status{service="s1",route="s1.route-1",code="200",consumer="CONSUMER_USERNAME"} 3
# HELP kong_http_status HTTP status codes per Service/Route in {{site.base_gateway}}
# TYPE kong_http_status counter
kong_http_status{code="301",service="google",route="google.route-1"} 2
# HELP kong_latency Latency added by {{site.base_gateway}} in ms, total request time and upstream latency for each Service in {{site.base_gateway}}
# TYPE kong_latency histogram
kong_latency_bucket{type="kong",service="google",route="google.route-1",le="00001.0"} 1
kong_latency_bucket{type="kong",service="google",route="google.route-1",le="00002.0"} 1
.
.
.
kong_latency_bucket{type="kong",service="google",route="google.route-1",le="+Inf"} 2
kong_latency_bucket{type="request",service="google",route="google.route-1",le="00300.0"} 1
kong_latency_bucket{type="request",service="google",route="google.route-1",le="00400.0"} 1
.
.
kong_latency_bucket{type="request",service="google",route="google.route-1",le="+Inf"} 2
kong_latency_bucket{type="upstream",service="google",route="google.route-1",le="00300.0"} 2
kong_latency_bucket{type="upstream",service="google",route="google.route-1",le="00400.0"} 2
.
.
kong_latency_bucket{type="upstream",service="google",route="google.route-1",le="+Inf"} 2
kong_latency_count{type="kong",service="google",route="google.route-1"} 2
kong_latency_count{type="request",service="google",route="google.route-1"} 2
kong_latency_count{type="upstream",service="google",route="google.route-1"} 2
kong_latency_sum{type="kong",service="google",route="google.route-1"} 2145
kong_latency_sum{type="request",service="google",route="google.route-1"} 2672
kong_latency_sum{type="upstream",service="google",route="google.route-1"} 527
# HELP kong_nginx_http_current_connections Number of HTTP connections
# TYPE kong_nginx_http_current_connections gauge
kong_nginx_http_current_connections{state="accepted"} 8
kong_nginx_http_current_connections{state="active"} 1
kong_nginx_http_current_connections{state="handled"} 8
kong_nginx_http_current_connections{state="reading"} 0
kong_nginx_http_current_connections{state="total"} 8
kong_nginx_http_current_connections{state="waiting"} 0
kong_nginx_http_current_connections{state="writing"} 1
# HELP kong_memory_lua_shared_dict_bytes Allocated slabs in bytes in a shared_dict
# TYPE kong_memory_lua_shared_dict_bytes gauge
kong_memory_lua_shared_dict_bytes{shared_dict="kong",kong_subsystem="http"} 40960
.
.
# HELP kong_memory_lua_shared_dict_total_bytes Total capacity in bytes of a shared_dict
# TYPE kong_memory_lua_shared_dict_total_bytes gauge
kong_memory_lua_shared_dict_total_bytes{shared_dict="kong",kong_subsystem="http"} 5242880
.
.
# HELP kong_memory_workers_lua_vms_bytes Allocated bytes in worker Lua VM
# TYPE kong_memory_workers_lua_vms_bytes gauge
kong_memory_workers_lua_vms_bytes{pid="7281",kong_subsystem="http"} 41124353
# HELP kong_data_plane_config_hash Config hash value of the data plane
# TYPE kong_data_plane_config_hash gauge
kong_data_plane_config_hash{node_id="d4e7584e-b2f2-415b-bb68-3b0936f1fde3",hostname="ubuntu-bionic",ip="127.0.0.1"} 1.7158931820287e+38
# HELP kong_data_plane_last_seen Last time data plane contacted control plane
# TYPE kong_data_plane_last_seen gauge
kong_data_plane_last_seen{node_id="d4e7584e-b2f2-415b-bb68-3b0936f1fde3",hostname="ubuntu-bionic",ip="127.0.0.1"} 1600190275
# HELP kong_data_plane_version_compatible Version compatible status of the data plane, 0 is incompatible
# TYPE kong_data_plane_version_compatible gauge
kong_data_plane_version_compatible{node_id="d4e7584e-b2f2-415b-bb68-3b0936f1fde3",hostname="ubuntu-bionic",ip="127.0.0.1",kong_version="2.4.1"} 1
# HELP kong_nginx_metric_errors_total Number of nginx-lua-prometheus errors
# TYPE kong_nginx_metric_errors_total counter
kong_nginx_metric_errors_total 0
# HELP kong_upstream_target_health Health status of targets of upstream. States = healthchecks_off|healthy|unhealthy|dns_error, value is 1 when state is populated.
kong_upstream_target_health{upstream="UPSTREAM_NAME",target="TARGET",address="IP:PORT",state="healthchecks_off",subsystem="http"} 0
kong_upstream_target_health{upstream="UPSTREAM_NAME",target="TARGET",address="IP:PORT",state="healthy",subsystem="http"} 1
kong_upstream_target_health{upstream="UPSTREAM_NAME",target="TARGET",address="IP:PORT",state="unhealthy",subsystem="http"} 0
kong_upstream_target_health{upstream="UPSTREAM_NAME",target="TARGET",address="IP:PORT",state="dns_error",subsystem="http"} 0
```
