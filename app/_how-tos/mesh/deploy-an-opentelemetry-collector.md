---
title: Deploy an OpenTelemetry collector for metrics, traces, and logs
description: Run one OpenTelemetry collector that receives metrics, traces, and access logs from {{site.mesh_product_name}}, with guidance on Deployment vs DaemonSet topologies and passthrough handling.

content_type: how_to
permalink: /mesh/deploy-an-opentelemetry-collector/

breadcrumbs:
  - /mesh/

products:
  - mesh

works_on:
  - on-prem

tags:
  - observability
  - metrics
  - tracing
  - logging
  - kubernetes

related_resources:
  - text: MeshMetric policy
    url: /mesh/policies/meshmetric/
  - text: MeshTrace policy
    url: /mesh/policies/meshtrace/
  - text: MeshAccessLog policy
    url: /mesh/policies/meshaccesslog/
  - text: Observability
    url: /mesh/observability/

next_steps:
  - text: MeshMetric policy
    url: /mesh/policies/meshmetric/
  - text: MeshTrace policy
    url: /mesh/policies/meshtrace/
  - text: MeshAccessLog policy
    url: /mesh/policies/meshaccesslog/
  - text: OpenTelemetry collector processors
    url: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor

tldr:
  q: How do I deploy an OpenTelemetry collector for {{site.mesh_product_name}}?
  a: Run a single OpenTelemetry collector that receives metrics, traces, and access logs from sidecars over OTLP, and pick between a Deployment or per-node DaemonSet topology.

prereqs:
  inline:
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart
    - title: Observability backends
      content: |
        Bring your own backends for the three signals the collector forwards. The examples in this guide assume:

        - A trace backend that accepts OTLP gRPC (for example, Tempo or Jaeger)
        - A log backend that accepts OTLP HTTP (for example, Loki)
        - Prometheus scraping the collector's `/metrics` endpoint

        Adjust the exporter section of the collector config to match the addresses of your backends.

---

This guide deploys a single OpenTelemetry collector that receives all three telemetry signals from {{site.mesh_product_name}}: metrics from [MeshMetric](/mesh/policies/meshmetric/), traces from [MeshTrace](/mesh/policies/meshtrace/), and access logs from [MeshAccessLog](/mesh/policies/meshaccesslog/). It covers two production topologies, how the collector fits with sidecar injection, and what changes when mesh passthrough is off.

## How {{site.mesh_product_name}} talks to the collector

Sidecars push telemetry to the collector over OTLP gRPC on port 4317. The collector receives, batches, and exports it to whatever backends you configure.

This is a push model. Each sidecar opens an outbound connection to one collector pod and writes its own telemetry. Compare that to a pull model, where a collector scrapes Prometheus endpoints from every workload it can reach.

The distinction matters when you pick a topology. A [CNCF post](https://www.cncf.io/blog/2025/12/16/how-to-build-a-cost-effective-observability-platform-with-opentelemetry/) warns about 20-40x metric explosion when DaemonSet collectors all scrape the same Prometheus targets. That problem is specific to the pull model. {{site.mesh_product_name}} pushes, so each metric reaches one collector instance regardless of how many collector pods exist.

## Pick a topology

Two patterns work for the OTLP receiver. Pick one before you write the manifests.

### Deployment + ClusterIP service

Run two or three collector replicas behind a `ClusterIP` service. Sidecars resolve `otel-collector.observability:4317` to whichever replica kube-proxy picks.

This is the default recommendation. It's simple, the failure domain is the whole replica set, and a rolling update of the collector doesn't drop telemetry from any specific node. Use this for small and medium clusters, or any cluster where collector throughput isn't a bottleneck.

### Per-node DaemonSet

Run one collector pod per node and route traffic node-locally. With `internalTrafficPolicy: Local` on the service, kube-proxy on each node only forwards to the collector pod on that same node. Sidecars still resolve the same DNS name (`otel-collector.observability:4317`), but the hop never leaves the node.

Pick this for large clusters or workloads where the extra network hop matters. It improves locality, distributes load across nodes, and isolates collector failure to a single node's telemetry.

{:.warning}
> The tradeoff is silent loss. If the collector pod on a node crashes or is being rescheduled, sidecars on that node have no fallback. Their telemetry drops on the floor until the pod is back. There is no cross-node failover with `Local` traffic policy.

## Deploy the collector

1. Create a dedicated namespace for the collector. The collector pod must not run a sidecar that pushes its own telemetry through itself, which would create a circular dependency.

   ```sh
   kubectl create namespace observability
   ```

1. Exclude the namespace from sidecar injection:

   ```sh
   kubectl label namespace observability kuma.io/sidecar-injection=disabled
   ```

1. Apply the collector configuration. It defines three pipelines, a memory limiter as the first processor, a tuned batch processor, and a debug exporter on every pipeline so you can see what's flowing through during testing.

   ```sh
   echo "apiVersion: v1
   kind: ConfigMap
   metadata:
     name: otel-collector-config
     namespace: observability
   data:
     config.yaml: |
       receivers:
         otlp:
           protocols:
             grpc:
               endpoint: 0.0.0.0:4317
             http:
               endpoint: 0.0.0.0:4318

       processors:
         memory_limiter:
           check_interval: 5s
           limit_mib: 500
           spike_limit_mib: 400
         batch:
           send_batch_size: 4096
           send_batch_max_size: 8192
           timeout: 10s

       exporters:
         debug:
           verbosity: basic
         otlp_grpc/tempo:
           endpoint: tempo.observability:4317
           tls:
             insecure: true
         prometheus:
           endpoint: 0.0.0.0:8889
         otlp_http/loki:
           endpoint: http://loki.observability:3100/otlp

       service:
         pipelines:
           traces:
             receivers: [otlp]
             processors: [memory_limiter, batch]
             exporters: [otlp_grpc/tempo, debug]
           metrics:
             receivers: [otlp]
             processors: [memory_limiter, batch]
             exporters: [prometheus, debug]
           logs:
             receivers: [otlp]
             processors: [memory_limiter, batch]
             exporters: [otlp_http/loki, debug]" | kubectl apply -f -
   ```

   A few things worth flagging:

   - `memory_limiter` runs first. The OpenTelemetry project recommends this so the collector can shed load before later processors allocate. If batching ran first, a burst could OOM the pod before the limiter ever saw it.
   - `batch` reduces export overhead. `send_batch_size: 4096` is a reasonable starting point. Tune up if your backend complains about request rate, down if it complains about batch size.
   - The `debug` exporter is enabled in every pipeline at `verbosity: basic` so each batch shows up as one log line. Drop it from the pipelines once you've verified the setup, or bump to `verbosity: detailed` when you need to see individual records.
   - `otlp_grpc/tempo`, `otlp_http/loki`, and `prometheus` are examples. The trace and log exporters send OTLP to a backend; the `prometheus` exporter exposes a `/metrics` endpoint on port 8889 for Prometheus to scrape. Swap the addresses to match your own backends.

1. Apply the workload and service. Both topologies share the same collector configuration. Only the workload kind and the service traffic policy change.

   {% navtabs "topology" %}
   {% navtab "Deployment" %}

   ```sh
   echo "apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: otel-collector
     namespace: observability
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: otel-collector
     template:
       metadata:
         labels:
           app: otel-collector
       spec:
         containers:
           - name: otel-collector
             image: otel/opentelemetry-collector-contrib:0.141.0
             args: ['--config=/conf/config.yaml']
             ports:
               - name: otlp-grpc
                 containerPort: 4317
               - name: otlp-http
                 containerPort: 4318
               - name: prometheus
                 containerPort: 8889
             resources:
               requests:
                 cpu: 100m
                 memory: 256Mi
               limits:
                 cpu: 500m
                 memory: 512Mi
             volumeMounts:
               - name: config
                 mountPath: /conf
         volumes:
           - name: config
             configMap:
               name: otel-collector-config
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: otel-collector
     namespace: observability
   spec:
     selector:
       app: otel-collector
     ports:
       - name: otlp-grpc
         port: 4317
         targetPort: otlp-grpc
         appProtocol: grpc
       - name: otlp-http
         port: 4318
         targetPort: otlp-http
       - name: prometheus
         port: 8889
         targetPort: prometheus" | kubectl apply -f -
   ```

   {% endnavtab %}
   {% navtab "DaemonSet" %}

   ```sh
   echo "apiVersion: apps/v1
   kind: DaemonSet
   metadata:
     name: otel-collector
     namespace: observability
   spec:
     selector:
       matchLabels:
         app: otel-collector
     template:
       metadata:
         labels:
           app: otel-collector
       spec:
         containers:
           - name: otel-collector
             image: otel/opentelemetry-collector-contrib:0.141.0
             args: ['--config=/conf/config.yaml']
             ports:
               - name: otlp-grpc
                 containerPort: 4317
               - name: otlp-http
                 containerPort: 4318
               - name: prometheus
                 containerPort: 8889
             resources:
               requests:
                 cpu: 100m
                 memory: 256Mi
               limits:
                 cpu: 500m
                 memory: 512Mi
             volumeMounts:
               - name: config
                 mountPath: /conf
         volumes:
           - name: config
             configMap:
               name: otel-collector-config
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: otel-collector
     namespace: observability
   spec:
     selector:
       app: otel-collector
     internalTrafficPolicy: Local
     ports:
       - name: otlp-grpc
         port: 4317
         targetPort: otlp-grpc
         appProtocol: grpc
       - name: otlp-http
         port: 4318
         targetPort: otlp-http
       - name: prometheus
         port: 8889
         targetPort: prometheus" | kubectl apply -f -
   ```

   {% endnavtab %}
   {% endnavtabs %}

   The DNS name `otel-collector.observability:4317` works the same way in both options. With `internalTrafficPolicy: Local`, kube-proxy resolves it to the node-local pod transparently.

1. Wait for the collector to be ready:

   ```sh
   kubectl wait -n observability --for=condition=ready pod -l app=otel-collector --timeout=120s
   ```

## Point {{site.mesh_product_name}} policies at the collector

All three policies use the same endpoint. Apply them at the `Mesh` level to cover every sidecar in the mesh:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: all-metrics
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: otel-collector.observability:4317
---
apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: all-traces
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: otel-collector.observability:4317
    sampling:
      overall: 100
---
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: all-access-logs
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        backends:
          - type: OpenTelemetry
            openTelemetry:
              endpoint: otel-collector.observability:4317" | kubectl apply -f -
```

{:.info}
> Trace sampling is set to 100% so you see something during testing. Drop it to single digits in production.

## Reach the collector when passthrough is off

By default, sidecars can reach addresses outside the mesh through [passthrough mode](/mesh/policies/meshpassthrough/). The collector lives outside the mesh, so passthrough is what gets sidecar telemetry to it.

If you disable passthrough at the `Mesh` level, sidecars can't reach the collector anymore and telemetry stops. To restore that path, declare the collector with a [MeshExternalService](/mesh/meshexternalservice/).

{:.info}
> `MeshExternalService` requires [ZoneEgress](/mesh/zone-egress/) and [mutual TLS](/mesh/mutual-tls/) on the mesh. If you already disabled passthrough, you likely have mTLS on already.

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: otel-collector
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 4317
    protocol: grpc
  endpoints:
    - address: otel-collector.observability
      port: 4317" | kubectl apply -f -
```

The hostname generator publishes the service under `otel-collector.extsvc.mesh.local`. Update the three policies to point at that hostname on port 4317 instead of `otel-collector.observability:4317`.

## Verify the collector

1. Check that the collector is receiving data:

   ```sh
   kubectl logs -n observability -l app=otel-collector --tail=20
   ```

   With the `debug` exporter at `verbosity: basic`, each batch shows up as one line per signal. If you see nothing, walk back: is the policy applied to the right `Mesh`, does the collector pod's address match the policy `endpoint`, can a debug pod in a mesh namespace reach `otel-collector.observability:4317` on TCP?

1. For the DaemonSet topology, list the collector pods with their node assignments:

   ```sh
   kubectl get pod -n observability -o wide -l app=otel-collector
   ```

1. Inspect the endpoint slice to confirm traffic is going node-local:

   ```sh
   kubectl get endpointslice -n observability -l kubernetes.io/service-name=otel-collector -o yaml
   ```

   The endpoint slice will list one collector pod per node. With `Local` traffic policy, each node's kube-proxy only routes to its own entry.
