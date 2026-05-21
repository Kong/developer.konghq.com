---
title: Deploy an OpenTelemetry collector for metrics, traces, and logs
description: Run a per-node OpenTelemetry collector DaemonSet that receives metrics, traces, and access logs from {{site.mesh_product_name}} sidecars and forwards them to your backends.

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
  - text: OpenTelemetry collector deployment patterns
    url: https://opentelemetry.io/docs/collector/deploy/
  - text: OpenTelemetry collector processors
    url: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor

tldr:
  q: How do I deploy an OpenTelemetry collector for {{site.mesh_product_name}}?
  a: Run an OpenTelemetry collector as a per-node Kubernetes `DaemonSet` that receives metrics, traces, and access logs from sidecars over OTLP and forwards them to your backends.

faqs:
  - q: What should I check if no telemetry reaches the collector?
    a: |
      Walk back through these checks:

      - Did you apply the policy to the right `Mesh`?
      - Does the collector Pod's address match the policy `endpoint`?
      - Can a debug Pod in a mesh namespace reach `otel-collector.observability:4317` on TCP?
  - q: How do I run the collector as a Deployment instead?
    a: |
      Use a Deployment for small and medium clusters, or any cluster where collector throughput isn't a bottleneck. See [OpenTelemetry collector topologies](/mesh/observability/#topologies) for the trade-offs.

      Replace the DaemonSet workload and service in [Deploy the collector](#deploy-the-collector) with a Deployment behind a `ClusterIP` service:

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

      Sidecars resolve `otel-collector.observability:4317` to the Service IP, and Kubernetes forwards traffic to one of the collector replicas. With a Deployment, you can skip the node-local checks (Pod node assignments and endpoint slice) in [Verify the collector](#verify-the-collector).

prereqs:
  inline:
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Helm
      include_content: prereqs/helm
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart
    - title: Tempo
      content: |
        Install [Grafana Tempo](https://grafana.com/docs/tempo/latest/setup/helm-chart/) as the trace backend. The collector config in this guide pushes traces to `tempo.observability:4317`:

        ```sh
        helm repo add grafana https://grafana.github.io/helm-charts
        helm repo update

        echo "
        tempo:
          receivers:
            otlp:
              protocols:
                grpc:
                  endpoint: 0.0.0.0:4317
                http:
                  endpoint: 0.0.0.0:4318
        " > values-tempo.yaml

        helm install tempo grafana/tempo \
          --namespace observability --create-namespace \
          -f values-tempo.yaml

        kubectl wait -n observability --for=condition=ready pod \
          -l app.kubernetes.io/name=tempo --timeout=120s
        ```
      icon_url: /assets/icons/third-party/grafana.svg
    - title: Loki
      content: |
        Install [Grafana Loki](https://grafana.com/docs/loki/latest/setup/install/helm/) as the log backend. The collector config in this guide pushes logs to `http://loki.observability:3100/otlp`:

        ```sh
        helm repo add grafana https://grafana.github.io/helm-charts
        helm repo update

        echo "
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
        " > values-loki.yaml

        helm install loki grafana/loki \
          --namespace observability --create-namespace \
          -f values-loki.yaml
        ```
      icon_url: /assets/icons/third-party/grafana.svg
    - title: Prometheus
      content: |
        Install [Prometheus](https://prometheus.io/docs/prometheus/latest/installation/) with a scrape job for the collector's `/metrics` endpoint at `otel-collector.observability:8889`:

        ```sh
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo update

        echo "
        extraScrapeConfigs: |
          - job_name: otel-collector
            static_configs:
              - targets: ['otel-collector.observability:8889']
        " > values-prometheus.yaml

        helm install prometheus prometheus-community/prometheus \
          --namespace observability --create-namespace \
          -f values-prometheus.yaml
        ```
      icon_url: /assets/icons/prometheus.svg

---

This guide deploys an OpenTelemetry collector as a per-node Kubernetes `DaemonSet` that receives all three telemetry signals from {{site.mesh_product_name}}: metrics from [MeshMetric](/mesh/policies/meshmetric/), traces from [MeshTrace](/mesh/policies/meshtrace/), and access logs from [MeshAccessLog](/mesh/policies/meshaccesslog/). Sidecars push to it over OTLP gRPC on port 4317. It also covers what to change when mesh passthrough is off.

For background on the push model and topology trade-offs, see [OpenTelemetry collector](/mesh/observability/#opentelemetry-collector) in the observability reference docs.

## Deploy the collector

1. Create a dedicated namespace for the collector:

   ```sh
   kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
   ```

   The collector Pod must run without a sidecar, otherwise the sidecar would push telemetry back through the collector it runs alongside, creating a circular dependency.

1. Exclude the namespace from sidecar injection:

   ```sh
   kubectl label namespace observability kuma.io/sidecar-injection=disabled
   ```

1. Apply the collector configuration:

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
         otlp/tempo:
           endpoint: tempo.observability:4317
           tls:
             insecure: true
         prometheus:
           endpoint: 0.0.0.0:8889
         otlphttp/loki:
           endpoint: http://loki.observability:3100/otlp

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
             exporters: [otlphttp/loki, debug]" | kubectl apply -f -
   ```
   The configuration defines three pipelines: traces, metrics, and logs. It also runs a memory limiter, a tuned batch processor, and a debug exporter on every pipeline so you can see telemetry flowing during testing.

   Notes on this configuration:

   - `memory_limiter` runs first. The OpenTelemetry project recommends this order so the collector can shed load before later processors allocate memory. If batching ran first, a burst could OOM the pod before the limiter ever saw it.
   - `batch` reduces export overhead. `send_batch_size: 4096` is a reasonable starting point. Tune up if your backend complains about request rate, down if it complains about batch size.
   - The `debug` exporter runs in every pipeline at `verbosity: basic` so each batch shows up as one log line. Drop it from the pipelines once you've verified the setup, or raise it to `verbosity: detailed` when you need to see individual records.
   - `otlp/tempo`, `otlphttp/loki`, and `prometheus` are examples. The trace and log exporters send OTLP to a backend; the `prometheus` exporter exposes a `/metrics` endpoint on port 8889 for Prometheus to scrape. Swap the addresses to match your own backends if needed.
   - `tls.insecure: true` on the Tempo exporter disables certificate verification for the in-cluster example. In production, point the exporter at a TLS endpoint with a trusted CA and remove the `insecure` flag.

1. Apply the DaemonSet and node-local service:

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

   Sidecars resolve `otel-collector.observability:4317` to whichever collector Pod runs on their node.

   {:.warning}
   > `internalTrafficPolicy: Local` keeps the hop node-local but does not fail over to another node. If the collector Pod on a node restarts, that node's telemetry drops until the Pod is ready.

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
> The `MeshTrace` policy samples 100% of traces so you see something during testing. Drop the rate to single digits in production.

## Reach the collector when passthrough is off

By default, sidecars reach the collector through [passthrough mode](/mesh/policies/meshpassthrough/). If you've disabled passthrough on the `Mesh`, declare the collector with a [MeshExternalService](/mesh/meshexternalservice/) so sidecars can still reach it:

{:.info}
> `MeshExternalService` requires [ZoneEgress](/mesh/zone-egress/) and [mutual TLS](/mesh/policies/mutual-tls/) on the mesh. If you already disabled passthrough, you likely already have mTLS enabled.

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

1. Check that the collector is receiving metrics:

   ```sh
   kubectl logs -n observability -l app=otel-collector --tail=20
   ```

   With the `debug` exporter at `verbosity: basic`, each batch shows up as one line per signal. Metrics flow continuously from Envoy stats, so you should see `Metrics` lines within a minute or so.

1. List the collector Pods with their node assignments:

   ```sh
   kubectl get pod -n observability -o wide -l app=otel-collector
   ```

1. Inspect the endpoint slice to confirm traffic is going node-local:

   ```sh
   kubectl get endpointslice -n observability -l kubernetes.io/service-name=otel-collector -o yaml
   ```

   The endpoint slice lists one collector Pod per node, and each node's kube-proxy only routes to its own entry.

## Generate traffic

1. Port-forward the demo app service on port `5050`:

   ```sh
   kubectl port-forward svc/demo-app -n kong-mesh-demo 5050:5050
   ```

1. Go to <http://127.0.0.1:5050> to open the demo app UI.

1. Enable **Auto-increment** to generate traffic.

## Validate

In a new terminal, re-check the collector logs and confirm all three signals appear:

```sh
kubectl logs -n observability -l app=otel-collector --tail=20
```

You should now see `Traces` and `Logs` lines alongside `Metrics`. If `Metrics` appears but one of the others is missing, the corresponding `MeshTrace` or `MeshAccessLog` policy isn't matching. In that case, verify the `targetRef`.
