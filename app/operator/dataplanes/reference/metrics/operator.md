---
title: "{{ site.operator_product_name }} metrics"
description: "See which metrics {{ site.operator_product_name }} exposes and learn how to authenticate using a ServiceAccount to scrape the values"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Observability

---

{{ site.operator_product_name }} exposes multiple sets of metrics on the `/metrics` endpoint:

- {{site.konnect_short_name}} entity operations
- Those provided by [controller-runtime](https://pkg.go.dev/sigs.k8s.io/controller-runtime/pkg/metrics).

## Configuration

{{ site.operator_product_name }} itself exposes the metrics on the address set by the `--metrics-bind-address` CLI flag or `GATEWAY_OPERATOR_METRICS_BIND_ADDRESS` environment variable.

The default is set to `:8080`.

## How to access

{{ site.operator_product_name }} uses [kube-rbac-proxy](https://github.com/brancz/kube-rbac-proxy) to secure its endpoints behind an RBAC proxy.
By default, [Kong's Gateway Operator Helm chart](https://github.com/Kong/charts/tree/main/charts/gateway-operator) creates a `Service` which is configured to expose `kube-rbac-proxy` behind port 8443.

Assuming the following `helm` installation invocation:

```bash
helm install kgo kong/gateway-operator -n kong-system --create-namespace
```

You can find the metrics `Service` by running:

```bash
kubectl get svc -n kong-system -lcontrol-plane=controller-manager
```

Which should give you:

```bash
NAME                                   TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
kgo-gateway-operator-metrics-service   ClusterIP   10.96.25.90   <none>        8443/TCP   31s
```

Because {{ site.operator_product_name }} uses `kube-rbac-proxy` simple HTTP(S) request without a token will be rejected.
You can verify that by port forwarding the exposed `Service` port:

```bash
kubectl port-forward -n kong-system svc/kgo-gateway-operator-metrics-service 8443
```

And sending a request:

```bash
curl -sk https://localhost:8443/metrics
Unauthorized
```

To access that endpoint you'll need to bind the scraping `Service`'s `ServiceAccount` to a `ClusterRole` which contains the following policy rule:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: metrics-reader
rules:
- nonResourceURLs:
  - "/metrics"
  verbs:
  - get
```

To verify that locally you can apply the following manifest:

```bash
echo 'apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-reader-sa
  namespace: kong-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: metrics-reader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: metrics-reader
subjects:
- kind: ServiceAccount
  name: metrics-reader-sa
  namespace: kong-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: metrics-reader
rules:
- nonResourceURLs:
  - /metrics
  verbs:
  - get ' | kubectl apply -f -
```

And create a temporary token for that `ServiceAccount`:

```bash
export TOKEN=$(kubectl create token -n kong-system metrics-reader-sa)
```

You can then use this token to access the metrics just as the in-cluster `Service` would:

```bash
curl -k --header "Authorization: Bearer $(TOKEN)" https://localhost:8443/metrics
```

## {{site.konnect_short_name}} Metrics {% new_in 1.5 %}

If [{{site.konnect_short_name}} entity management](/index/operator/#konnect--get-started) is enabled, {{ site.operator_product_name }} exposes metrics to show statistics of counts and durations of calling {{site.konnect_short_name}}'s CRUD APIs.
The metrics are grouped by server URLs, entity types, operation types (create/update/delete/get), and the status (success/fail).

* Counts of {{site.konnect_short_name}} entity operations are in the metric `gateway_operator_konnect_entity_operation_count`. It's a Prometheus counter.
* Durations of {{site.konnect_short_name}} entity operations are in the metric `gateway_operator_konnect_entity_operation_duration_milliseconds`. It's a Prometheus histogram.

{:.info}
> **Note**: When `success = "false"` indicates the operation failed, the `status_code` label shows the status code in the response. `status_code` is `"0"` and `success` is `"false"` are operations that failed but {{ site.operator_product_name }} cannot fetch the status code. When `success` is `"true"`, the `status_code` label is empty.

## Example metrics dump

Here's an example of what is available:

```
# HELP certwatcher_read_certificate_errors_total Total number of certificate read errors
# TYPE certwatcher_read_certificate_errors_total counter
certwatcher_read_certificate_errors_total 0
# HELP certwatcher_read_certificate_total Total number of certificate reads
# TYPE certwatcher_read_certificate_total counter
certwatcher_read_certificate_total 0
# HELP controller_runtime_active_workers Number of currently used workers per controller
# TYPE controller_runtime_active_workers gauge
controller_runtime_active_workers{controller="dataplane"} 0
controller_runtime_active_workers{controller="deployment"} 0
controller_runtime_active_workers{controller="secret"} 0
controller_runtime_active_workers{controller="service"} 0
# HELP controller_runtime_max_concurrent_reconciles Maximum number of concurrent reconciles per controller
# TYPE controller_runtime_max_concurrent_reconciles gauge
controller_runtime_max_concurrent_reconciles{controller="dataplane"} 1
controller_runtime_max_concurrent_reconciles{controller="deployment"} 1
controller_runtime_max_concurrent_reconciles{controller="secret"} 1
controller_runtime_max_concurrent_reconciles{controller="service"} 1
# HELP controller_runtime_reconcile_errors_total Total number of reconciliation errors per controller
# TYPE controller_runtime_reconcile_errors_total counter
controller_runtime_reconcile_errors_total{controller="dataplane"} 33
controller_runtime_reconcile_errors_total{controller="deployment"} 0
controller_runtime_reconcile_errors_total{controller="secret"} 0
controller_runtime_reconcile_errors_total{controller="service"} 0
# HELP controller_runtime_reconcile_time_seconds Length of time per reconciliation per controller
# TYPE controller_runtime_reconcile_time_seconds histogram
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.005"} 70
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.01"} 87
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.025"} 96
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.05"} 96
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.1"} 96
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.15"} 96
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.2"} 96
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.25"} 96
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.3"} 96
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.35"} 96
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.4"} 96
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.45"} 96
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.5"} 96
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.6"} 96
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.7"} 96
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.8"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="0.9"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="1"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="1.25"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="1.5"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="1.75"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="2"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="2.5"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="3"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="3.5"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="4"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="4.5"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="5"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="6"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="7"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="8"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="9"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="10"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="15"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="20"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="25"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="30"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="40"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="50"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="60"} 97
controller_runtime_reconcile_time_seconds_bucket{controller="dataplane",le="+Inf"} 98
controller_runtime_reconcile_time_seconds_sum{controller="dataplane"} 469.31872100000004
controller_runtime_reconcile_time_seconds_count{controller="dataplane"} 98
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.005"} 2
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.01"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.025"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.05"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.1"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.15"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.2"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.25"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.3"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.35"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.4"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.45"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.5"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.6"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.7"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.8"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="0.9"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="1"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="1.25"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="1.5"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="1.75"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="2"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="2.5"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="3"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="3.5"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="4"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="4.5"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="5"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="6"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="7"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="8"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="9"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="10"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="15"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="20"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="25"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="30"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="40"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="50"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="60"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="secret",le="+Inf"} 4
controller_runtime_reconcile_time_seconds_sum{controller="secret"} 0.014826584
controller_runtime_reconcile_time_seconds_count{controller="secret"} 4
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.005"} 20
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.01"} 24
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.025"} 28
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.05"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.1"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.15"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.2"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.25"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.3"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.35"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.4"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.45"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.5"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.6"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.7"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.8"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="0.9"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="1"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="1.25"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="1.5"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="1.75"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="2"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="2.5"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="3"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="3.5"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="4"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="4.5"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="5"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="6"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="7"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="8"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="9"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="10"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="15"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="20"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="25"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="30"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="40"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="50"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="60"} 29
controller_runtime_reconcile_time_seconds_bucket{controller="service",le="+Inf"} 29
controller_runtime_reconcile_time_seconds_sum{controller="service"} 0.12255604199999999
controller_runtime_reconcile_time_seconds_count{controller="service"} 29
# HELP controller_runtime_reconcile_total Total number of reconciliations per controller
# TYPE controller_runtime_reconcile_total counter
controller_runtime_reconcile_total{controller="dataplane",result="error"} 33
controller_runtime_reconcile_total{controller="dataplane",result="requeue"} 0
controller_runtime_reconcile_total{controller="dataplane",result="requeue_after"} 0
controller_runtime_reconcile_total{controller="dataplane",result="success"} 65
controller_runtime_reconcile_total{controller="deployment",result="error"} 0
controller_runtime_reconcile_total{controller="deployment",result="requeue"} 0
controller_runtime_reconcile_total{controller="deployment",result="requeue_after"} 0
controller_runtime_reconcile_total{controller="deployment",result="success"} 0
controller_runtime_reconcile_total{controller="secret",result="error"} 0
controller_runtime_reconcile_total{controller="secret",result="requeue"} 0
controller_runtime_reconcile_total{controller="secret",result="requeue_after"} 0
controller_runtime_reconcile_total{controller="secret",result="success"} 4
controller_runtime_reconcile_total{controller="service",result="error"} 0
controller_runtime_reconcile_total{controller="service",result="requeue"} 0
controller_runtime_reconcile_total{controller="service",result="requeue_after"} 0
controller_runtime_reconcile_total{controller="service",result="success"} 29
# HELP go_gc_duration_seconds A summary of the pause duration of garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 4.5334e-05
go_gc_duration_seconds{quantile="0.25"} 9.8916e-05
go_gc_duration_seconds{quantile="0.5"} 0.000139958
go_gc_duration_seconds{quantile="0.75"} 0.000154083
go_gc_duration_seconds{quantile="1"} 0.000198834
go_gc_duration_seconds_sum 0.001242373
go_gc_duration_seconds_count 10
# HELP go_goroutines Number of goroutines that currently exist.
# TYPE go_goroutines gauge
go_goroutines 101
# HELP go_info Information about the Go environment.
# TYPE go_info gauge
go_info{version="go1.21.1"} 1
# HELP go_memstats_alloc_bytes Number of bytes allocated and still in use.
# TYPE go_memstats_alloc_bytes gauge
go_memstats_alloc_bytes 8.373488e+06
# HELP go_memstats_alloc_bytes_total Total number of bytes allocated, even if freed.
# TYPE go_memstats_alloc_bytes_total counter
go_memstats_alloc_bytes_total 5.6075904e+07
# HELP go_memstats_buck_hash_sys_bytes Number of bytes used by the profiling bucket hash table.
# TYPE go_memstats_buck_hash_sys_bytes gauge
go_memstats_buck_hash_sys_bytes 1.477529e+06
# HELP go_memstats_frees_total Total number of frees.
# TYPE go_memstats_frees_total counter
go_memstats_frees_total 370458
# HELP go_memstats_gc_sys_bytes Number of bytes used for garbage collection system metadata.
# TYPE go_memstats_gc_sys_bytes gauge
go_memstats_gc_sys_bytes 4.662104e+06
# HELP go_memstats_heap_alloc_bytes Number of heap bytes allocated and still in use.
# TYPE go_memstats_heap_alloc_bytes gauge
go_memstats_heap_alloc_bytes 8.373488e+06
# HELP go_memstats_heap_idle_bytes Number of heap bytes waiting to be used.
# TYPE go_memstats_heap_idle_bytes gauge
go_memstats_heap_idle_bytes 1.0805248e+07
# HELP go_memstats_heap_inuse_bytes Number of heap bytes that are in use.
# TYPE go_memstats_heap_inuse_bytes gauge
go_memstats_heap_inuse_bytes 1.2787712e+07
# HELP go_memstats_heap_objects Number of allocated objects.
# TYPE go_memstats_heap_objects gauge
go_memstats_heap_objects 24652
# HELP go_memstats_heap_released_bytes Number of heap bytes released to OS.
# TYPE go_memstats_heap_released_bytes gauge
go_memstats_heap_released_bytes 4.743168e+06
# HELP go_memstats_heap_sys_bytes Number of heap bytes obtained from system.
# TYPE go_memstats_heap_sys_bytes gauge
go_memstats_heap_sys_bytes 2.359296e+07
# HELP go_memstats_last_gc_time_seconds Number of seconds since 1970 of last garbage collection.
# TYPE go_memstats_last_gc_time_seconds gauge
go_memstats_last_gc_time_seconds 1.69512232411449e+09
# HELP go_memstats_lookups_total Total number of pointer lookups.
# TYPE go_memstats_lookups_total counter
go_memstats_lookups_total 0
# HELP go_memstats_mallocs_total Total number of mallocs.
# TYPE go_memstats_mallocs_total counter
go_memstats_mallocs_total 395110
# HELP go_memstats_mcache_inuse_bytes Number of bytes in use by mcache structures.
# TYPE go_memstats_mcache_inuse_bytes gauge
go_memstats_mcache_inuse_bytes 12000
# HELP go_memstats_mcache_sys_bytes Number of bytes used for mcache structures obtained from system.
# TYPE go_memstats_mcache_sys_bytes gauge
go_memstats_mcache_sys_bytes 15600
# HELP go_memstats_mspan_inuse_bytes Number of bytes in use by mspan structures.
# TYPE go_memstats_mspan_inuse_bytes gauge
go_memstats_mspan_inuse_bytes 240912
# HELP go_memstats_mspan_sys_bytes Number of bytes used for mspan structures obtained from system.
# TYPE go_memstats_mspan_sys_bytes gauge
go_memstats_mspan_sys_bytes 391104
# HELP go_memstats_next_gc_bytes Number of heap bytes when next garbage collection will take place.
# TYPE go_memstats_next_gc_bytes gauge
go_memstats_next_gc_bytes 1.7545208e+07
# HELP go_memstats_other_sys_bytes Number of bytes used for other system allocations.
# TYPE go_memstats_other_sys_bytes gauge
go_memstats_other_sys_bytes 1.745255e+06
# HELP go_memstats_stack_inuse_bytes Number of bytes in use by the stack allocator.
# TYPE go_memstats_stack_inuse_bytes gauge
go_memstats_stack_inuse_bytes 1.572864e+06
# HELP go_memstats_stack_sys_bytes Number of bytes obtained from system for stack allocator.
# TYPE go_memstats_stack_sys_bytes gauge
go_memstats_stack_sys_bytes 1.572864e+06
# HELP go_memstats_sys_bytes Number of bytes obtained from system.
# TYPE go_memstats_sys_bytes gauge
go_memstats_sys_bytes 3.3457416e+07
# HELP go_threads Number of OS threads created.
# TYPE go_threads gauge
go_threads 16
# HELP rest_client_requests_total Number of HTTP requests, partitioned by status code, method, and host.
# TYPE rest_client_requests_total counter
rest_client_requests_total{code="200",host="127.0.0.1:49892",method="GET"} 23
rest_client_requests_total{code="200",host="127.0.0.1:49892",method="PATCH"} 21
rest_client_requests_total{code="201",host="127.0.0.1:49892",method="POST"} 10
rest_client_requests_total{code="404",host="127.0.0.1:49892",method="PATCH"} 31
rest_client_requests_total{code="409",host="127.0.0.1:49892",method="PUT"} 2
# HELP workqueue_adds_total Total number of adds handled by workqueue
# TYPE workqueue_adds_total counter
workqueue_adds_total{name="dataplane"} 98
workqueue_adds_total{name="deployment"} 0
workqueue_adds_total{name="secret"} 4
workqueue_adds_total{name="service"} 29
# HELP workqueue_depth Current depth of workqueue
# TYPE workqueue_depth gauge
workqueue_depth{name="dataplane"} 0
workqueue_depth{name="deployment"} 0
workqueue_depth{name="secret"} 0
workqueue_depth{name="service"} 0
# HELP workqueue_longest_running_processor_seconds How many seconds has the longest running processor for workqueue been running.
# TYPE workqueue_longest_running_processor_seconds gauge
workqueue_longest_running_processor_seconds{name="dataplane"} 0
workqueue_longest_running_processor_seconds{name="deployment"} 0
workqueue_longest_running_processor_seconds{name="secret"} 0
workqueue_longest_running_processor_seconds{name="service"} 0
# HELP workqueue_queue_duration_seconds How long in seconds an item stays in workqueue before being requested
# TYPE workqueue_queue_duration_seconds histogram
workqueue_queue_duration_seconds_bucket{name="dataplane",le="1e-08"} 0
workqueue_queue_duration_seconds_bucket{name="dataplane",le="1e-07"} 0
workqueue_queue_duration_seconds_bucket{name="dataplane",le="1e-06"} 0
workqueue_queue_duration_seconds_bucket{name="dataplane",le="9.999999999999999e-06"} 44
workqueue_queue_duration_seconds_bucket{name="dataplane",le="9.999999999999999e-05"} 52
workqueue_queue_duration_seconds_bucket{name="dataplane",le="0.001"} 55
workqueue_queue_duration_seconds_bucket{name="dataplane",le="0.01"} 94
workqueue_queue_duration_seconds_bucket{name="dataplane",le="0.1"} 96
workqueue_queue_duration_seconds_bucket{name="dataplane",le="1"} 97
workqueue_queue_duration_seconds_bucket{name="dataplane",le="10"} 97
workqueue_queue_duration_seconds_bucket{name="dataplane",le="+Inf"} 98
workqueue_queue_duration_seconds_sum{name="dataplane"} 469.20134874799993
workqueue_queue_duration_seconds_count{name="dataplane"} 98
workqueue_queue_duration_seconds_bucket{name="deployment",le="1e-08"} 0
workqueue_queue_duration_seconds_bucket{name="deployment",le="1e-07"} 0
workqueue_queue_duration_seconds_bucket{name="deployment",le="1e-06"} 0
workqueue_queue_duration_seconds_bucket{name="deployment",le="9.999999999999999e-06"} 0
workqueue_queue_duration_seconds_bucket{name="deployment",le="9.999999999999999e-05"} 0
workqueue_queue_duration_seconds_bucket{name="deployment",le="0.001"} 0
workqueue_queue_duration_seconds_bucket{name="deployment",le="0.01"} 0
workqueue_queue_duration_seconds_bucket{name="deployment",le="0.1"} 0
workqueue_queue_duration_seconds_bucket{name="deployment",le="1"} 0
workqueue_queue_duration_seconds_bucket{name="deployment",le="10"} 0
workqueue_queue_duration_seconds_bucket{name="deployment",le="+Inf"} 0
workqueue_queue_duration_seconds_sum{name="deployment"} 0
workqueue_queue_duration_seconds_count{name="deployment"} 0
workqueue_queue_duration_seconds_bucket{name="secret",le="1e-08"} 0
workqueue_queue_duration_seconds_bucket{name="secret",le="1e-07"} 0
workqueue_queue_duration_seconds_bucket{name="secret",le="1e-06"} 0
workqueue_queue_duration_seconds_bucket{name="secret",le="9.999999999999999e-06"} 2
workqueue_queue_duration_seconds_bucket{name="secret",le="9.999999999999999e-05"} 3
workqueue_queue_duration_seconds_bucket{name="secret",le="0.001"} 4
workqueue_queue_duration_seconds_bucket{name="secret",le="0.01"} 4
workqueue_queue_duration_seconds_bucket{name="secret",le="0.1"} 4
workqueue_queue_duration_seconds_bucket{name="secret",le="1"} 4
workqueue_queue_duration_seconds_bucket{name="secret",le="10"} 4
workqueue_queue_duration_seconds_bucket{name="secret",le="+Inf"} 4
workqueue_queue_duration_seconds_sum{name="secret"} 0.000460082
workqueue_queue_duration_seconds_count{name="secret"} 4
workqueue_queue_duration_seconds_bucket{name="service",le="1e-08"} 0
workqueue_queue_duration_seconds_bucket{name="service",le="1e-07"} 0
workqueue_queue_duration_seconds_bucket{name="service",le="1e-06"} 0
workqueue_queue_duration_seconds_bucket{name="service",le="9.999999999999999e-06"} 7
workqueue_queue_duration_seconds_bucket{name="service",le="9.999999999999999e-05"} 13
workqueue_queue_duration_seconds_bucket{name="service",le="0.001"} 15
workqueue_queue_duration_seconds_bucket{name="service",le="0.01"} 20
workqueue_queue_duration_seconds_bucket{name="service",le="0.1"} 29
workqueue_queue_duration_seconds_bucket{name="service",le="1"} 29
workqueue_queue_duration_seconds_bucket{name="service",le="10"} 29
workqueue_queue_duration_seconds_bucket{name="service",le="+Inf"} 29
workqueue_queue_duration_seconds_sum{name="service"} 0.185648377
workqueue_queue_duration_seconds_count{name="service"} 29
# HELP workqueue_retries_total Total number of retries handled by workqueue
# TYPE workqueue_retries_total counter
workqueue_retries_total{name="dataplane"} 33
workqueue_retries_total{name="deployment"} 0
workqueue_retries_total{name="secret"} 0
workqueue_retries_total{name="service"} 0
# HELP workqueue_unfinished_work_seconds How many seconds of work has been done that is in progress and hasn't been observed by work_duration. Large values indicate stuck threads. One can deduce the number of stuck threads by observing the rate at which this increases.
# TYPE workqueue_unfinished_work_seconds gauge
workqueue_unfinished_work_seconds{name="dataplane"} 0
workqueue_unfinished_work_seconds{name="deployment"} 0
workqueue_unfinished_work_seconds{name="secret"} 0
workqueue_unfinished_work_seconds{name="service"} 0
# HELP workqueue_work_duration_seconds How long in seconds processing an item from workqueue takes.
# TYPE workqueue_work_duration_seconds histogram
workqueue_work_duration_seconds_bucket{name="dataplane",le="1e-08"} 0
workqueue_work_duration_seconds_bucket{name="dataplane",le="1e-07"} 0
workqueue_work_duration_seconds_bucket{name="dataplane",le="1e-06"} 0
workqueue_work_duration_seconds_bucket{name="dataplane",le="9.999999999999999e-06"} 0
workqueue_work_duration_seconds_bucket{name="dataplane",le="9.999999999999999e-05"} 45
workqueue_work_duration_seconds_bucket{name="dataplane",le="0.001"} 49
workqueue_work_duration_seconds_bucket{name="dataplane",le="0.01"} 87
workqueue_work_duration_seconds_bucket{name="dataplane",le="0.1"} 96
workqueue_work_duration_seconds_bucket{name="dataplane",le="1"} 97
workqueue_work_duration_seconds_bucket{name="dataplane",le="10"} 97
workqueue_work_duration_seconds_bucket{name="dataplane",le="+Inf"} 98
workqueue_work_duration_seconds_sum{name="dataplane"} 469.319411498
workqueue_work_duration_seconds_count{name="dataplane"} 98
workqueue_work_duration_seconds_bucket{name="deployment",le="1e-08"} 0
workqueue_work_duration_seconds_bucket{name="deployment",le="1e-07"} 0
workqueue_work_duration_seconds_bucket{name="deployment",le="1e-06"} 0
workqueue_work_duration_seconds_bucket{name="deployment",le="9.999999999999999e-06"} 0
workqueue_work_duration_seconds_bucket{name="deployment",le="9.999999999999999e-05"} 0
workqueue_work_duration_seconds_bucket{name="deployment",le="0.001"} 0
workqueue_work_duration_seconds_bucket{name="deployment",le="0.01"} 0
workqueue_work_duration_seconds_bucket{name="deployment",le="0.1"} 0
workqueue_work_duration_seconds_bucket{name="deployment",le="1"} 0
workqueue_work_duration_seconds_bucket{name="deployment",le="10"} 0
workqueue_work_duration_seconds_bucket{name="deployment",le="+Inf"} 0
workqueue_work_duration_seconds_sum{name="deployment"} 0
workqueue_work_duration_seconds_count{name="deployment"} 0
workqueue_work_duration_seconds_bucket{name="secret",le="1e-08"} 0
workqueue_work_duration_seconds_bucket{name="secret",le="1e-07"} 0
workqueue_work_duration_seconds_bucket{name="secret",le="1e-06"} 0
workqueue_work_duration_seconds_bucket{name="secret",le="9.999999999999999e-06"} 0
workqueue_work_duration_seconds_bucket{name="secret",le="9.999999999999999e-05"} 2
workqueue_work_duration_seconds_bucket{name="secret",le="0.001"} 2
workqueue_work_duration_seconds_bucket{name="secret",le="0.01"} 4
workqueue_work_duration_seconds_bucket{name="secret",le="0.1"} 4
workqueue_work_duration_seconds_bucket{name="secret",le="1"} 4
workqueue_work_duration_seconds_bucket{name="secret",le="10"} 4
workqueue_work_duration_seconds_bucket{name="secret",le="+Inf"} 4
workqueue_work_duration_seconds_sum{name="secret"} 0.014861916
workqueue_work_duration_seconds_count{name="secret"} 4
workqueue_work_duration_seconds_bucket{name="service",le="1e-08"} 0
workqueue_work_duration_seconds_bucket{name="service",le="1e-07"} 0
workqueue_work_duration_seconds_bucket{name="service",le="1e-06"} 0
workqueue_work_duration_seconds_bucket{name="service",le="9.999999999999999e-06"} 0
workqueue_work_duration_seconds_bucket{name="service",le="9.999999999999999e-05"} 19
workqueue_work_duration_seconds_bucket{name="service",le="0.001"} 20
workqueue_work_duration_seconds_bucket{name="service",le="0.01"} 24
workqueue_work_duration_seconds_bucket{name="service",le="0.1"} 29
workqueue_work_duration_seconds_bucket{name="service",le="1"} 29
workqueue_work_duration_seconds_bucket{name="service",le="10"} 29
workqueue_work_duration_seconds_bucket{name="service",le="+Inf"} 29
workqueue_work_duration_seconds_sum{name="service"} 0.12272996100000001
workqueue_work_duration_seconds_count{name="service"} 29
```

### Example metrics about {{site.konnect_short_name}} entity operation {% new_in 1.5 %}

Here is an example of dumped metrics about {{site.konnect_short_name}} operations:

```
# HELP gateway_operator_konnect_entity_operation_count Count of successful/failed entity operations in Konnect. `server_url` describes the URL of the Konnect server. `operation_type` describes the operation type (`create`, `update`, or `delete`).`entity_type` describes the type of the operated entity. `success` describes whether the operation is successful (`true`) or not (`false`). `status_code` is always "0" when  `success="true"` and is populated in case of `success="false"` and describes the status code returned from Konnect API. `status_code`="0" and success="false" means we cannot collect the status code or error happens in the process other than Konnect API call.
# TYPE gateway_operator_konnect_entity_operation_count counter
gateway_operator_konnect_entity_operation_count{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true"} 1
gateway_operator_konnect_entity_operation_count{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true"} 1
gateway_operator_konnect_entity_operation_count{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true"} 2
gateway_operator_konnect_entity_operation_count{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true"} 1
gateway_operator_konnect_entity_operation_count{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true"} 1
# HELP gateway_operator_konnect_entity_operation_duration_milliseconds How long did the Konnect entity operation take in milliseconds. `server_url` describes the URL of the Konnect server. `operation_type` describes the operation type (`create`, `update`, or `delete`).`entity_type` describes the type of the operated entity. `success` describes whether the operation is successful (`true`) or not (`false`). `status_code` is always "0" when  `success="true"` and is populated in case of `success="false"` and describes the status code returned from Konnect API. `status_code`="0" and success="false" means we cannot collect the status code or error happens in the process other than Konnect API call.
# TYPE gateway_operator_konnect_entity_operation_duration_milliseconds histogram
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="1"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="2.0142493107417994"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="4.057200285823813"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="8.172212879262048"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="16.460874159288835"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="33.15630442955503"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="66.78506334397649"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="134.52176780845207"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="270.9603780879429"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="545.7817548019764"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="1099.3405234253305"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="2214.345891580001"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="4460.244685858952"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="8984.044784231166"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="18096.106014311084"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="36450.06906643664"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="73419.52649356097"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="147885.23063464448"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="297877.72387472464"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="600000.0000000001"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="+Inf"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_sum{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true"} 0.433949268
gateway_operator_konnect_entity_op{{site.konnect_short_name}}eration_duration_milliseconds_count{entity_type="KongService",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="1"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="2.0142493107417994"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="4.057200285823813"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="8.172212879262048"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="16.460874159288835"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="33.15630442955503"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="66.78506334397649"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="134.52176780845207"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="270.9603780879429"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="545.7817548019764"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="1099.3405234253305"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="2214.345891580001"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="4460.244685858952"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="8984.044784231166"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="18096.106014311084"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="36450.06906643664"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="73419.52649356097"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="147885.23063464448"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="297877.72387472464"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="600000.0000000001"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="+Inf"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_sum{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true"} 0.244031381
gateway_operator_konnect_entity_operation_duration_milliseconds_count{entity_type="KongService",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="1"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="2.0142493107417994"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="4.057200285823813"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="8.172212879262048"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="16.460874159288835"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="33.15630442955503"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="66.78506334397649"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="134.52176780845207"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="270.9603780879429"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="545.7817548019764"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="1099.3405234253305"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="2214.345891580001"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="4460.244685858952"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="8984.044784231166"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="18096.106014311084"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="36450.06906643664"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="73419.52649356097"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="147885.23063464448"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="297877.72387472464"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="600000.0000000001"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true",le="+Inf"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_sum{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true"} 1.5224173479999998
gateway_operator_konnect_entity_operation_duration_milliseconds_count{entity_type="KonnectGatewayControlPlane",operation_type="create",server_url="https://us.api.konghq.tech",status_code="",success="true"} 2
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="1"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="2.0142493107417994"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="4.057200285823813"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="8.172212879262048"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="16.460874159288835"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="33.15630442955503"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="66.78506334397649"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="134.52176780845207"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="270.9603780879429"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="545.7817548019764"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="1099.3405234253305"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="2214.345891580001"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="4460.244685858952"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="8984.044784231166"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="18096.106014311084"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="36450.06906643664"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="73419.52649356097"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="147885.23063464448"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="297877.72387472464"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="600000.0000000001"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true",le="+Inf"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_sum{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true"} 0.868175824
gateway_operator_konnect_entity_operation_duration_milliseconds_count{entity_type="KonnectGatewayControlPlane",operation_type="delete",server_url="https://us.api.konghq.tech",status_code="",success="true"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="1"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="2.0142493107417994"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="4.057200285823813"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="8.172212879262048"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="16.460874159288835"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="33.15630442955503"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="66.78506334397649"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="134.52176780845207"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="270.9603780879429"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="545.7817548019764"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="1099.3405234253305"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="2214.345891580001"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="4460.244685858952"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="8984.044784231166"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="18096.106014311084"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="36450.06906643664"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="73419.52649356097"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="147885.23063464448"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="297877.72387472464"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="600000.0000000001"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_bucket{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true",le="+Inf"} 1
gateway_operator_konnect_entity_operation_duration_milliseconds_sum{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true"} 0.592125953
gateway_operator_konnect_entity_operation_duration_milliseconds_count{entity_type="KonnectGatewayControlPlane",operation_type="update",server_url="https://us.api.konghq.tech",status_code="",success="true"} 1
```