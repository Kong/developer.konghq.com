---
title: "Performance fine-tuning"
description: "Reference guide to performance tuning in {{site.mesh_product_name}}, including configuration trimming, PostgreSQL tuning, XDS snapshot generation, profiling, and Envoy concurrency."
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - performance

related_resources:
  - text: Transparent proxying
    url: '/mesh/transparent-proxying/'
  - text: Zone egress
    url: /mesh/zone-egress/
  - text: Mesh observability
    url: '/mesh/observability/'
  - text: MeshMultiZoneService
    url: /mesh/meshmultizoneservice/

min_version:
  mesh: '2.6'
---

## Reachable services

By default, when transparent proxying is enabled, every data plane proxy receives configuration for every other data plane proxy in the mesh.
In large meshes, a data plane proxy typically communicates with only a small number of services.
Defining that list of services can dramatically improve {{site.mesh_product_name}} performance.

The benefits are:
* The control plane generates a much smaller XDS configuration (fewer Clusters, Listeners, and so on), reducing CPU and memory usage.
* Smaller configurations reduce network bandwidth.
* Envoy maintains fewer Clusters and Listeners, resulting in fewer statistics and lower memory usage.

For more information, see [Transparent proxying](/mesh/transparent-proxying/).

## Configuration trimming with MeshTrafficPermission

{:.warning}
> This feature only works with [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/). If you're using TrafficPermission, migrate to MeshTrafficPermission before enabling this feature, otherwise all traffic flow may stop.

The problem described in [Reachable services](#reachable-services) can also be mitigated by defining [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) policies and [configuring](/mesh/control-plane-configuration/) a zone control plane with `KUMA_EXPERIMENTAL_AUTO_REACHABLE_SERVICES=true`.

Enabling this flag causes {{site.mesh_product_name}} to compute a dependency graph between services and generate XDS configuration that allows communication only between services permitted to reach each other (those whose [effective](/mesh/policies-introduction/) action is not `deny`).

In the example below, service `b` can only be called by service `a`. There is no reason to compute or distribute configuration for service `b` to any other service, since they are not permitted to communicate with it.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: kuma-system
  name: mtp-b
spec:
  targetRef:
    kind: MeshService
    name: b
  from:
    - targetRef:
        kind: MeshService
        name: a
      default:
        action: Allow
```

{:.info}
> You can combine `autoReachableServices` with reachable services, but reachable services takes precedence.

Requests from services that don't have access to a given service fail with a connection closed error:

```sh
root@second-test-server:/# curl -v first-test-server:80
*   Trying [IP]:80...
* Connected to first-test-server ([IP]) port 80 (#0)
> GET / HTTP/1.1
> Host: first-test-server
> User-Agent: curl/7.81.0
> Accept: */*
>
* Empty reply from server
* Closing connection 0
curl: (52) Empty reply from server
```

The sections below highlight the most important aspects of this feature. For more information, see the [MADR](https://github.com/kumahq/kuma/blob/master/docs/madr/decisions/031-automatic-rechable-services.md#automatic-reachable-services).

### Supported targetRef kinds

The following kinds affect graph generation and performance:
* All levels of `MeshService`
* Top-level `MeshSubset` and `MeshServiceSubset` with `k8s.kuma.io/namespace`, `k8s.kuma.io/service-name`, `k8s.kuma.io/service-port` tags
* `from` level `MeshSubset` and `MeshServiceSubset` with all tags

A MeshTrafficPermission using any other kind won't affect performance. For example:

{% policy_yaml %}
```yaml
type: MeshTrafficPermission
mesh: default
name: mtp-mesh-to-mesh
spec:
  targetRef:
    kind: MeshSubset
    tags:
      customTag: true
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow
```
{% endpolicy_yaml %}

### Migration

The recommended migration path is to start with a coarse-grained `MeshTrafficPermission` targeting a `MeshSubset` with `k8s.kuma.io/namespace`, then narrow down to individual services as needed.

## PostgreSQL

If you're using `Postgres` as a configuration store for {{site.mesh_product_name}} on Universal, the following settings affect control plane performance:

* `KUMA_STORE_POSTGRES_CONNECTION_TIMEOUT`: Connection timeout to the PostgreSQL database (default: `5s`).
* `KUMA_STORE_POSTGRES_MAX_OPEN_CONNECTIONS`: Maximum number of open connections to the PostgreSQL database (default: `unlimited`).

### KUMA_STORE_POSTGRES_CONNECTION_TIMEOUT

The default value works well when `kuma-cp` and the PostgreSQL database are deployed in the same data center or cloud region.

If you're using a more distributed topology, such as hosting `kuma-cp` on-premises with PostgreSQL as a cloud service, the default timeout may not be sufficient.

### KUMA_STORE_POSTGRES_MAX_OPEN_CONNECTIONS

As more data planes join your meshes, {{site.mesh_product_name}} may need more PostgreSQL connections to fetch configurations and update statuses.


If your PostgreSQL database only permits a small number of concurrent connections, adjust {{site.mesh_product_name}}'s configuration accordingly.

## Profiling

{{site.mesh_product_name}}'s control plane exposes [`pprof`](https://golang.org/pkg/net/http/pprof/) endpoints for profiling and debugging `kuma-cp` performance.

To enable debugging endpoints, set `KUMA_DIAGNOSTICS_DEBUG_ENDPOINTS=true` before starting `kuma-cp`, then retrieve profiling data using one of the following methods:

{% navtabs "profiling" %}
{% navtab "pprof" %}

```sh
go tool pprof http://$CONTROL_PLANE_IP:5680/debug/pprof/profile?seconds=30
```

{% endnavtab %}
{% navtab "curl" %}

```sh
curl http://$CONTROL_PLANE_IP:5680/debug/pprof/profile?seconds=30 --output prof.out
```

{% endnavtab %}
{% endnavtabs %}

You can then analyze the profiling data using a tool like [Speedscope](https://www.speedscope.app/).

{:.warning}
> After debugging, disable the debugging endpoints. Anyone with access can execute heap dumps, potentially exposing sensitive data.

### Kubernetes client

The Kubernetes client uses client-level throttling to avoid overwhelming the kube-apiserver. In deployments with more than 2,000 services in a single Kubernetes cluster, the volume of resource updates can hit this limit. It's generally safe to raise this limit, since kube-apiserver has its own throttling mechanism. To adjust client throttling:

```yaml
runtime:
  kubernetes:
    clientConfig:
      qps: ... # maximum requests per second the Kubernetes client is allowed to make
      burstQps: ... # maximum burst requests per second the Kubernetes client is allowed to make
```

### Kubernetes controller manager

{{site.mesh_product_name}} modifies Kubernetes resources through reconciliation. Each resource type has its own work queue, and the control plane adds reconciliation tasks to that queue. In deployments with more than 2,000 services in a single Kubernetes cluster, the Pod reconciliation queue can grow and slow down Pod updates. To increase the number of concurrent Pod reconciliation tasks:

```yaml
runtime:
  kubernetes:
    controllersConcurrency:
      podController: ... # maximum concurrent Pod reconciliations
```

## Envoy

Envoy is the data plane proxy used by {{site.mesh_product_name}}. The following settings let you tune its performance characteristics.

### Envoy concurrency tuning

Envoy's [worker thread](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/intro/threading_model) count can be tuned. The mechanism differs by deployment type.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

By default, Envoy sets concurrency based on the container's CPU resource limit. For example, a limit of `7000m` results in 7 worker threads. On Kubernetes, concurrency is capped between 2 and 10 by default. To exceed that limit, use the `kuma.io/sidecar-proxy-concurrency` annotation:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
spec:
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
      annotations:
        kuma.io/sidecar-proxy-concurrency: 55
[...]
```

{% endnavtab %}
{% navtab "Universal" %}

On Linux, Envoy starts with the `--cpuset-threads` flag by default, using the `cpuset` size to determine worker thread count. When not available, it falls back to the number of hardware threads. Use the `--concurrency` flag when starting `kuma-dp` to override this:

```sh
kuma-dp run \
  [..]
  --concurrency=5
```

{% endnavtab %}
{% endnavtabs %}

### Incremental xDS {% new_in 2.11 %}

{:.warning}
> This feature is experimental.

{{site.mesh_product_name}} supports [Incremental xDS](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol#incremental-xds), a new model for exchanging configuration between the control plane and Envoy.

Instead of sending the entire configuration on each update, the control plane sends only the changes. This reduces CPU and memory usage on sidecars during updates, but may slightly increase load on the control plane, which must maintain state and compute diffs.

This feature is especially beneficial for sidecars that don't use `reachableBackends` or `reachableServices`.

Enable it for the entire deployment with `KUMA_EXPERIMENTAL_DELTA_XDS=true`, or for an individual sidecar (including Ingress and Egress):

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

Add the following annotation to the Pod template:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: kuma-demo
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        kuma.io/xds-transport-protocol-variant: DELTA_GRPC
```

{% endnavtab %}
{% navtab "Universal" %}

Set the following environment variable when starting the sidecar:

```bash
KUMA_DATAPLANE_RUNTIME_ENVOY_XDS_TRANSPORT_PROTOCOL_VARIANT=DELTA_GRPC
```

{% endnavtab %}
{% endnavtabs %}

## Snapshot generation

{:.warning}
> This section covers internal {{site.mesh_product_name}} control plane implementation details and is intended for advanced users.

The main task of the control plane is to provide configuration to data planes. When a data plane connects to the control plane, the control plane starts a new Goroutine that runs a reconciliation process at a configurable interval (one second by default). You can customize this interval with the `KUMA_XDS_SERVER_DATAPLANE_CONFIGURATION_REFRESH_INTERVAL` parameter. During reconciliation, all data planes and policies are fetched and matched. The resulting Envoy configuration, including policies and available service endpoints, is generated and sent only if it has changed.

This process can be CPU-intensive with a large number of data planes. Increasing the interval reduces control plane load at the cost of higher config propagation latency. For example, setting it to five seconds means that when you apply a policy or a service instance changes state, the control plane will generate and distribute the new configuration within five seconds.

For high-traffic systems, stale endpoint data for that long may not be acceptable. In that case, use passive or active [health checks](/mesh/policies/health-check/).

To reduce storage load, a cache shares fetch results across concurrent reconciliation Goroutines for multiple data planes. The default expiration time for cache entries is five seconds, but you can customize it using the `KUMA_STORE_CACHE_EXPIRATION_TIME` parameter.

This value should not exceed `KUMA_XDS_SERVER_DATAPLANE_CONFIGURATION_REFRESH_INTERVAL`, otherwise the control plane will build Envoy config from stale data.