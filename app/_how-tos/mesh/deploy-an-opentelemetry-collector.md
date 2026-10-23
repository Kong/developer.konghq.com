---
title: Deploy an OpenTelemetry collector
description: Run a per-node OpenTelemetry collector DaemonSet that receives metrics, traces, and access logs from {{site.mesh_product_name}} proxies and forwards them to your backends.

content_type: how_to
permalink: /mesh/deploy-an-opentelemetry-collector/

breadcrumbs:
  - /mesh/
  - /mesh/scenarios/

products:
  - mesh

works_on:
  - on-prem
  - konnect

min_version:
  mesh: '3.0'

series:
  id: mesh-kong-air-scenario
  position: 5

tags:
  - observability
  - metrics
  - tracing
  - logging
  - kubernetes

related_resources:
  - text: Observe mesh traffic in practice
    url: /mesh/observe-mesh-traffic-in-practice/
  - text: MeshMetric policy
    url: /mesh/policies/meshmetric/
  - text: MeshTrace policy
    url: /mesh/policies/meshtrace/
  - text: MeshAccessLog policy
    url: /mesh/policies/meshaccesslog/

next_steps:
  - text: "How-to: Observe mesh traffic in practice"
    url: "/mesh/observe-mesh-traffic-in-practice/"

tldr:
  q: How do I deploy an OpenTelemetry collector for {{site.mesh_product_name}}?
  a: |
    Run an OpenTelemetry collector as a per-node Kubernetes `DaemonSet` that receives metrics, traces, and access logs over OTLP and forwards them to your backends.

    Then create a `MeshOpenTelemetryBackend` that names the collector, and reference it from `MeshMetric`, `MeshTrace`, and `MeshAccessLog` with a `backendRef`.
    In {{site.mesh_product_name}} 3.0, a `backendRef` is the only way to set an OpenTelemetry backend on these policies.

faqs:
  - q: What do I check if no telemetry reaches the OpenTelemetry collector?
    a: |
      When no telemetry reaches the OpenTelemetry collector, check the following:

      - Does each policy's `backendRef` resolve? The policy's `BackendRefsResolved` condition reports `AllBackendRefsResolved` when it does. A `backendRef` that matches nothing exports nothing.
      - Does the collector listen where `kuma-dp` sends? With an empty `MeshOpenTelemetryBackend` spec, `kuma-dp` sends to port 4317 on the node IP, so the collector container needs `hostPort: 4317`.
      - Does the collector run outside the mesh? A collector with a sidecar rejects the plaintext export.

      For more checks, see [Verify backend references](/mesh/meshopentelemetrybackend/#verify-backend-references).
  - q: How do I run the collector as a Deployment instead?
    a: |
      A collector Deployment suits small and medium clusters, or any cluster where collector throughput isn't a bottleneck.
      A Deployment has no node-local address, so the `MeshOpenTelemetryBackend` must name the collector `Service`.

      Replace the DaemonSet in [Deploy the collector](#deploy-the-collector) with a Deployment behind the same `ClusterIP` service, and drop the `hostPort` entries:

      ```sh
      kubectl apply -f - <<'EOF'
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: otel-collector
        namespace: mesh-observability
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
      EOF
      ```

      Then set the `Service` address in the `MeshOpenTelemetryBackend` spec:

      ```yaml
      spec:
        endpoint:
          address: otel-collector.mesh-observability
          port: 4317
        protocol: grpc
      ```

      The same `endpoint.address` field works for a collector outside the cluster.
      For `protocol`, `endpoint.path`, and their rules, see [Configure the collector connection](/mesh/meshopentelemetrybackend/#configure-the-collector-connection).
  - q: Can one collector serve several meshes?
    a: |
      Yes, one OpenTelemetry collector can serve several meshes.
      Each mesh needs its own `MeshOpenTelemetryBackend` that points at the same collector, because a backend belongs to one mesh.
      Give each backend a distinct name.
      The control plane rejects a backend that reuses an existing name with a different `kuma.io/mesh` label.
      For more information, see [MeshOpenTelemetryBackend](/mesh/meshopentelemetrybackend/).
  - q: Can Envoy export telemetry to the collector directly, as it did before 3.0?
    a: |
      No. In {{site.mesh_product_name}} 3.0, `kuma-dp` exports every signal to the collector.
      3.0 removes the `runtime.kubernetes.injector.otelPipeEnabled` and `KUMA_DATAPLANE_RUNTIME_OTEL_PIPE_ENABLED` settings, and the control plane and `kuma-dp` ignore them.
      For the export path, see [Collector placement](/mesh/meshopentelemetrybackend/#collector-placement).
  - q: Why is my `MeshAccessLog` rejected after I change its attributes?
    a: |
      The control plane rejects a `MeshAccessLog` attribute key that isn't a static, lowercase name.
      Placeholders such as `%KUMA_MESH%` work in attribute values but not in keys, and keys can't start with `otel.`.
      For the full key rules, see the [MeshAccessLog OpenTelemetry backend](/mesh/policies/meshaccesslog/#opentelemetry).

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: Tempo
      content: |
        Install [Grafana Tempo](https://grafana.com/docs/tempo/latest/setup/helm-chart/) as the trace backend. The collector configuration in this guide pushes traces to `tempo.mesh-observability:4317`.

        1. Add the Grafana Helm repository:

           ```sh
           helm repo add grafana https://grafana.github.io/helm-charts
           helm repo update
           ```

        1. Create the Tempo values file:

           ```sh
           cat > values-tempo.yaml <<'EOF'
           tempo:
             receivers:
               otlp:
                 protocols:
                   grpc:
                     endpoint: 0.0.0.0:4317
                   http:
                     endpoint: 0.0.0.0:4318
           EOF
           ```

        1. Install Tempo:

           ```sh
           helm install tempo grafana/tempo \
             --namespace mesh-observability --create-namespace \
             -f values-tempo.yaml
           ```

        1. Wait for Tempo to be ready:

           ```sh
           kubectl wait -n mesh-observability --for=condition=ready pod \
             -l app.kubernetes.io/name=tempo --timeout=120s
           ```
      icon_url: /assets/icons/third-party/grafana.svg
    - title: Loki
      content: |
        Install [Grafana Loki](https://grafana.com/docs/loki/latest/setup/install/helm/) as the log backend. The collector configuration in this guide pushes logs to `http://loki.mesh-observability:3100/otlp`.

        1. Add the Grafana Helm repository, if you haven't already:

           ```sh
           helm repo add grafana https://grafana.github.io/helm-charts
           helm repo update
           ```

        1. Create the Loki values file:

           ```sh
           cat > values-loki.yaml <<'EOF'
           deploymentMode: SingleBinary
           loki:
             auth_enabled: false
             commonConfig:
               replication_factor: 1
             storage:
               type: filesystem
             schemaConfig:
               configs:
                 - from: '2024-01-01'
                   store: tsdb
                   object_store: filesystem
                   schema: v13
                   index:
                     prefix: loki_index_
                     period: 24h
           singleBinary:
             replicas: 1
           read:
             replicas: 0
           write:
             replicas: 0
           backend:
             replicas: 0
           chunksCache:
             enabled: false
           resultsCache:
             enabled: false
           EOF
           ```

        1. Install Loki:

           ```sh
           helm install loki grafana/loki \
             --namespace mesh-observability --create-namespace \
             -f values-loki.yaml
           ```
      icon_url: /assets/icons/third-party/grafana.svg
    - title: Prometheus
      content: |
        Install [Prometheus](https://prometheus.io/docs/prometheus/latest/installation/) with a scrape job for the collector's `/metrics` endpoint at `otel-collector.mesh-observability:8889`.

        1. Add the Prometheus community Helm repository:

           ```sh
           helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
           helm repo update
           ```

        1. Create the Prometheus values file:

           ```sh
           cat > values-prometheus.yaml <<'EOF'
           extraScrapeConfigs: |
             - job_name: otel-collector
               static_configs:
                 - targets: ['otel-collector.mesh-observability:8889']
           EOF
           ```

        1. Install Prometheus:

           ```sh
           helm install prometheus prometheus-community/prometheus \
             --namespace mesh-observability --create-namespace \
             -f values-prometheus.yaml
           ```

        For the scrape jobs for proxy and control plane metrics, see [Prometheus scrape jobs](/mesh/observe-mesh-traffic-in-practice/#prometheus-scrape-jobs).
      icon_url: /assets/icons/prometheus.svg

cleanup:
  inline:
    - title: Remove the collector
      include_content: md/mesh/v3/cleanup/otel-collector
---

Kong Air sends three telemetry signals from its sidecars to one OpenTelemetry collector: metrics from [MeshMetric](/mesh/policies/meshmetric/), traces from [MeshTrace](/mesh/policies/meshtrace/), and access logs from [MeshAccessLog](/mesh/policies/meshaccesslog/).
The collector runs as a per-node Kubernetes `DaemonSet` and forwards each signal to its backend.

## How telemetry reaches the collector

Kong Air telemetry leaves each pod through `kuma-dp`.
Envoy writes each signal to a Unix socket in the pod, and `kuma-dp` exports it to the collector over OTLP.
The transparent proxy doesn't intercept this export, so `reachableBackends` and `MeshPassthrough` don't affect it, and the collector can run outside the mesh.
For where a collector can run, see [Collector placement](/mesh/meshopentelemetrybackend/#collector-placement).

{% mermaid %}
flowchart LR
    E[Envoy] -->|Unix socket| D[kuma-dp]
    D -->|OTLP| C[OpenTelemetry collector]
    C --> T[Tempo]
    C --> L[Loki]
    C --> P[Prometheus]
{% endmermaid %}

## Deploy the collector

1. Create a namespace for the collector:

   ```sh
   kubectl create namespace mesh-observability --dry-run=client -o yaml | kubectl apply -f -
   ```

1. Disable sidecar injection in the `mesh-observability` namespace, so the collector runs outside the mesh:

   ```sh
   kubectl label namespace mesh-observability kuma.io/sidecar-injection=disabled --overwrite
   ```

   The collector must run without a sidecar.
   `kuma-dp` exports telemetry as plaintext, and a collector with a sidecar rejects these connections under the default `Strict` mTLS mode.

1. Create a `ConfigMap` with the collector configuration:

   ```sh
   kubectl apply -f - <<'EOF'
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: otel-collector-config
     namespace: mesh-observability
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
         otlp/tempo:
           endpoint: tempo.mesh-observability:4317
           tls:
             insecure: true
         prometheus:
           endpoint: 0.0.0.0:8889
         otlphttp/loki:
           endpoint: http://loki.mesh-observability:3100/otlp

       service:
         pipelines:
           traces:
             receivers: [otlp]
             processors: [memory_limiter, batch]
             exporters: [otlp/tempo, debug]
           metrics:
             receivers: [otlp]
             processors: [memory_limiter, batch]
             exporters: [prometheus, debug]
           logs:
             receivers: [otlp]
             processors: [memory_limiter, batch]
             exporters: [otlphttp/loki, debug]
   EOF
   ```

   The collector configuration defines three pipelines: traces, metrics, and logs.
   Each pipeline runs a memory limiter, a batch processor, and a debug exporter that shows telemetry flowing during testing.
   The configuration works as follows:

   - `memory_limiter` runs first, as the OpenTelemetry project recommends. The limiter sheds load before later processors allocate memory.
   - `batch` reduces export overhead. `send_batch_size: 4096` is a starting point. Raise it if your backend reports too many requests, and lower it if your backend reports batches that are too large.
   - The `debug` exporter runs in every pipeline at `verbosity: basic`, so it logs one line per batch. Remove it from the pipelines after you verify the setup, or set `verbosity: detailed` to see individual records.
   - `otlp/tempo`, `otlphttp/loki`, and `prometheus` are example exporters. The trace and log exporters send OTLP to a backend. The `prometheus` exporter exposes a `/metrics` endpoint on port 8889 for Prometheus to scrape. Change the addresses to match your backends.
   - `tls.insecure: true` on the Tempo exporter turns off TLS, so the exporter sends plaintext gRPC to the in-cluster Tempo. In production, point the exporter at a TLS endpoint with a trusted CA, and remove the `insecure` flag.

1. Create the collector `DaemonSet` and its `Service`:

   ```sh
   kubectl apply -f - <<'EOF'
   apiVersion: apps/v1
   kind: DaemonSet
   metadata:
     name: otel-collector
     namespace: mesh-observability
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
                 hostPort: 4317
               - name: otlp-http
                 containerPort: 4318
                 hostPort: 4318
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
     namespace: mesh-observability
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
         targetPort: prometheus
   EOF
   ```

   `hostPort: 4317` publishes the collector on each node's IP.
   The node-local default in [Name the collector with MeshOpenTelemetryBackend](#name-the-collector-with-meshopentelemetrybackend) depends on it.
   Prometheus scrapes the `Service` on port 8889.
   The `Service` also gives the collector a cluster-wide address, if you later name the collector explicitly.

   {:.warning}
   > A `hostPort` binds the port on every node that runs a collector Pod, so no other workload on those nodes can use port 4317 or 4318.
   > The hop to the collector stays on the node and does not fail over.
   > While a node's collector Pod restarts, the proxies on that node lose their telemetry.

1. Wait for the collector `DaemonSet` to finish rolling out:

   ```sh
   kubectl rollout status daemonset/otel-collector -n mesh-observability --timeout=180s
   ```

   Use `rollout status` instead of `kubectl wait` on the Pods.
   The DaemonSet controller creates the Pods a moment after `kubectl apply` returns.
   If you run `kubectl wait` before the Pods exist, it fails with `no matching resources found`.

## Name the collector with MeshOpenTelemetryBackend

`MeshMetric`, `MeshTrace`, and `MeshAccessLog` don't carry a collector address.
Each policy reaches the collector through a `backendRef` to a [`MeshOpenTelemetryBackend`](/mesh/meshopentelemetrybackend/).
The address lives in that one resource, so you change one resource when you move the collector.

Create a `MeshOpenTelemetryBackend` named `otel-collector` with an empty spec:

```sh
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshOpenTelemetryBackend
metadata:
  name: otel-collector
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec: {}
EOF
```

With an empty spec, each sidecar sends to port 4317 on its own node's IP, where the `DaemonSet`'s `hostPort` publishes the collector.
For the fields and their defaults, see [Configure the collector connection](/mesh/meshopentelemetrybackend/#configure-the-collector-connection).

To run the collector as a Deployment instead, see the FAQ about running the collector as a Deployment.

## Point the policies at the backend

Create a `MeshMetric`, a `MeshTrace`, and a `MeshAccessLog` that all reference the `otel-collector` backend.
Each policy has a top-level `targetRef` of kind `Mesh` and lives in the system namespace, so it covers every proxy in the zone:

```sh
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: all-metrics
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            labels:
              kuma.io/display-name: otel-collector
          refreshInterval: 30s
---
apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: all-traces
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  default:
    sampling:
      overall: 100
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            labels:
              kuma.io/display-name: otel-collector
---
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: all-access-logs
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        backends:
          - type: OpenTelemetry
            openTelemetry:
              backendRef:
                kind: MeshOpenTelemetryBackend
                labels:
                  kuma.io/display-name: otel-collector
              attributes:
                - key: mesh
                  value: "%KUMA_MESH%"
                - key: source
                  value: "%KUMA_SOURCE_SERVICE%"
                - key: destination
                  value: "%KUMA_DESTINATION_SERVICE%"
EOF
```

{:.info}
> The `MeshTrace` policy samples 100% of traces, so you see traces during testing.
> In production, lower the rate to single digits.

### Confirm every backendRef resolved

When a `backendRef` matches no `MeshOpenTelemetryBackend`, the control plane still accepts the policy, but the policy exports nothing.
The `BackendRefsResolved` status condition shows whether a policy's references resolved.
Check the condition on each policy:

```sh
for p in meshmetric/all-metrics meshtrace/all-traces meshaccesslog/all-access-logs; do
  kubectl get "$p" -n {{site.mesh_namespace}} -o jsonpath='{.metadata.name}{"\t"}{.status.conditions[?(@.type=="BackendRefsResolved")].reason}{"\n"}'
done
```

The output shows `AllBackendRefsResolved` for each policy:

```text
all-metrics	AllBackendRefsResolved
all-traces	AllBackendRefsResolved
all-access-logs	AllBackendRefsResolved
```
{:.no-copy-code}

## Validate

1. List the collector Pods with their nodes, and check that each node runs one collector Pod:

   ```sh
   kubectl get pod -n mesh-observability -o wide -l app=otel-collector
   ```

1. Send a request from `flight-control` to `check-in-api`, which the Kong Air `MeshTrafficPermission` allows:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- \
     wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The response is the name of the `check-in-api` Pod that served the request:

   ```text
   check-in-api-6b4584fff-d58rx
   ```
   {:.no-copy-code}

1. Check that all three signals reach the collector:

   ```sh
   kubectl logs -n mesh-observability -l app=otel-collector --tail=40 | grep -E 'Traces|Metrics|Logs'
   ```

   With the `debug` exporter at `verbosity: basic`, the collector logs one line per batch for each signal.
   `Metrics` lines flow continuously from Envoy stats.
   `Traces` and `Logs` lines appear alongside them after the request.
   If `Metrics` appears but another signal is missing, the matching `MeshTrace` or `MeshAccessLog` policy doesn't select the proxy.
   Check the policy's `targetRef` and its `BackendRefsResolved` condition.

To scrape proxy and control plane metrics and read the telemetry in Grafana, continue with [Observe mesh traffic in practice](/mesh/observe-mesh-traffic-in-practice/).
