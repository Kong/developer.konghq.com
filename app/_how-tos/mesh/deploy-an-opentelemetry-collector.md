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
  - text: Observe mesh traffic in practice
    url: /mesh/observe-mesh-traffic-in-practice/

tldr:
  q: How do I deploy an OpenTelemetry collector for {{site.mesh_product_name}}?
  a: |
    Run an OpenTelemetry collector as a per-node Kubernetes `DaemonSet` that receives metrics, traces, and access logs over OTLP and forwards them to your backends.

    Then create a `MeshOpenTelemetryBackend` to name that collector, and point `MeshMetric`, `MeshTrace`, and `MeshAccessLog` at it with a `backendRef`. In {{site.mesh_product_name}} 3.0 a `backendRef` is the only way to configure an OpenTelemetry backend on those policies.

faqs:
  - q: What should I check if no telemetry reaches the collector?
    a: |
      Walk back through these checks:

      - Does the policy's `backendRef` resolve? `kubectl get meshtrace all-traces -n {{site.mesh_namespace}} -o jsonpath='{.status.conditions}'` reports `AllBackendRefsResolved` when it does. A `backendRef` that matches nothing leaves the policy accepted and silently exports nothing.
      - Did you apply the policy to the right `Mesh`? On a zone control plane connected to a global control plane, every resource in `{{site.mesh_namespace}}` also needs the `kuma.io/origin: zone` label.
      - Is the collector listening where `kuma-dp` is dialing? With an empty `MeshOpenTelemetryBackend` spec, `kuma-dp` dials the node IP on port 4317, which needs `hostPort: 4317` on the collector container.
      - Is the collector Pod running without a sidecar? A collector that receives telemetry through its own sidecar is a circular dependency.
  - q: How do I run the collector as a Deployment instead?
    a: |
      Use a Deployment for small and medium clusters, or any cluster where collector throughput isn't a bottleneck. A Deployment has no node-local address, so the `MeshOpenTelemetryBackend` has to name the Service explicitly rather than rely on the node-local default.

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

      Then name the Service in the `MeshOpenTelemetryBackend` spec:

      ```yaml
      spec:
        endpoint:
          address: otel-collector.mesh-observability
          port: 4317
        protocol: grpc
      ```

      The same `endpoint.address` works for a collector outside the cluster. `protocol` accepts `grpc` or `http` and defaults to `grpc`. `endpoint.path` is a base path prefix for HTTP endpoints only, and the control plane appends the signal suffixes (`/v1/traces`, `/v1/metrics`, `/v1/logs`) itself. Setting a non-empty `path` with `protocol: grpc` fails validation.
  - q: Can one collector serve several meshes?
    a: |
      Yes. The collector is an ordinary workload outside the mesh, so nothing about it is mesh-scoped. `MeshOpenTelemetryBackend` is, though: it carries a `kuma.io/mesh` label and lives in `{{site.mesh_namespace}}`, so each mesh needs its own resource pointing at the same collector.

      Give each one a distinct name. A `MeshOpenTelemetryBackend` is bound to the mesh it was first created in, and re-applying the same name with a different `kuma.io/mesh` label is rejected:

      ```text
      The MeshOpenTelemetryBackend "otel-collector" is invalid: metadata.ownerReferences[0].name: must be the same as the mesh of the resource "kong-air-mesh", got "default". A resource cannot be moved between meshes, delete it and apply it again in the new mesh
      ```

      Delete the old resource and apply it again under the new mesh, as the message says.
  - q: Can Envoy export telemetry to the collector directly, as it did before 3.0?
    a: |
      No. `runtime.kubernetes.injector.otelPipeEnabled` and `KUMA_DATAPLANE_RUNTIME_OTEL_PIPE_ENABLED` used to make Envoy export directly. Both settings are removed in 3.0, and the control plane and `kuma-dp` ignore them.
  - q: Why is my `MeshAccessLog` rejected after I change its attributes?
    a: |
      `MeshAccessLog` validates `openTelemetry.attributes[].key` against a strict grammar. A key must start with a lowercase letter, use only lowercase letters, digits, `_`, or `.`, avoid consecutive delimiters, end with a letter or digit, and must not use the reserved `otel.` prefix. Placeholders such as `%KUMA_MESH%` are allowed in values but not in keys.

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

        [Observe mesh traffic in practice](/mesh/observe-mesh-traffic-in-practice/#prometheus-scrape-jobs) covers the scrape jobs for proxy and control plane metrics.
      icon_url: /assets/icons/prometheus.svg

cleanup:
  inline:
    - title: Remove the collector
      include_content: md/mesh/v3/cleanup/otel-collector
---

This guide deploys an OpenTelemetry collector as a per-node Kubernetes `DaemonSet` that receives all three telemetry signals from {{site.mesh_product_name}}: metrics from [MeshMetric](/mesh/policies/meshmetric/), traces from [MeshTrace](/mesh/policies/meshtrace/), and access logs from [MeshAccessLog](/mesh/policies/meshaccesslog/).

## How telemetry reaches the collector

In {{site.mesh_product_name}} 3.0, the proxy does not export to the collector itself. Envoy writes each signal to a Unix socket in the pod, and `kuma-dp` reads from that socket and forwards to the collector over OTLP.

That export bypasses the transparent proxy. `kuma-dp` runs as its own user, and the transparent proxy rules return traffic owned by that user rather than redirecting it. Telemetry never enters an Envoy outbound listener, so passthrough mode, `MeshPassthrough`, `MeshExternalService`, and `reachableBackends` have no bearing on whether the collector is reachable. A collector outside the mesh needs no mesh configuration at all.

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

1. Keep the namespace out of the mesh:

   ```sh
   kubectl label namespace mesh-observability kuma.io/sidecar-injection=disabled --overwrite
   ```

   The collector must run without a sidecar. A collector with a sidecar pushes its own telemetry into itself, which is a circular dependency.

1. Apply the collector configuration:

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

   The configuration defines three pipelines: traces, metrics, and logs. Each runs a memory limiter, a tuned batch processor, and a debug exporter so you can see telemetry flowing during testing.

   Notes on this configuration:

   - `memory_limiter` runs first. The OpenTelemetry project recommends this order so the collector can shed load before later processors allocate memory. If batching ran first, a burst could exhaust the Pod's memory before the limiter ever saw it.
   - `batch` reduces export overhead. `send_batch_size: 4096` is a reasonable starting point. Tune up if your backend complains about request rate, down if it complains about batch size.
   - The `debug` exporter runs in every pipeline at `verbosity: basic`, so each batch shows up as one log line. Drop it from the pipelines once you have verified the setup, or raise it to `verbosity: detailed` when you need to see individual records.
   - `otlp/tempo`, `otlphttp/loki`, and `prometheus` are examples. The trace and log exporters send OTLP to a backend, and the `prometheus` exporter exposes a `/metrics` endpoint on port 8889 for Prometheus to scrape. Swap the addresses to match your own backends.
   - `tls.insecure: true` on the Tempo exporter disables certificate verification for the in-cluster example. In production, point the exporter at a TLS endpoint with a trusted CA and remove the `insecure` flag.

1. Apply the DaemonSet and its service:

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

   `hostPort: 4317` publishes the collector on each node's own IP, which is what makes the node-local default in [Name the collector with MeshOpenTelemetryBackend](#name-the-collector-with-meshopentelemetrybackend) work. The Service is what Prometheus scrapes on port 8889, and it also gives you a cluster-wide address if you decide to name the collector explicitly instead.

   {:.warning}
   > A `hostPort` binds the port on every node that runs a collector Pod, so nothing else on those nodes can use 4317 or 4318. The hop is node-local and does not fail over: while a node's collector Pod is restarting, that node's telemetry is dropped rather than sent elsewhere.

1. Wait for the collector to be ready:

   ```sh
   kubectl rollout status daemonset/otel-collector -n mesh-observability --timeout=180s
   ```

   Use `rollout status` rather than `kubectl wait` on the Pods. The DaemonSet controller creates the Pods a moment after the apply returns, and `kubectl wait` run immediately fails with `no matching resources found` before they exist.

## Name the collector with MeshOpenTelemetryBackend

`MeshMetric`, `MeshTrace`, and `MeshAccessLog` do not carry a collector address of their own. Each one reaches the collector through a `backendRef` to a `MeshOpenTelemetryBackend`, so the address lives in one resource and moving the collector is a one-resource change.

Create the backend with an empty spec:

```sh
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshOpenTelemetryBackend
metadata:
  name: otel-collector
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec: {}
EOF
```

An empty spec is the node-local default. The control plane defaults the port to 4317 and leaves the address unset, and `kuma-dp` resolves it at runtime from the `HOST_IP` environment variable the injector sets from the Pod's node IP, falling back to `127.0.0.1`. Combined with the `hostPort` on the DaemonSet, every proxy reaches the collector on its own node without a cluster-wide hop.

To run the collector somewhere other than on each node, see the FAQ on running it as a Deployment.

## Point the policies at the backend

All three policies reference the same backend. Apply them at the `Mesh` level to cover every proxy in the mesh:

```sh
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: all-metrics
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
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
    kuma.io/origin: zone
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
    kuma.io/origin: zone
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
> The `MeshTrace` policy samples 100% of traces so you see something during testing. Drop the rate to single digits in production.

### Confirm every backendRef resolved

A `backendRef` that matches no `MeshOpenTelemetryBackend` leaves the policy accepted and exports nothing, without reporting an error on the policy itself. Check the status condition on each one:

```sh
for p in meshmetric/all-metrics meshtrace/all-traces meshaccesslog/all-access-logs; do
  kubectl get "$p" -n {{site.mesh_namespace}} -o jsonpath='{.metadata.name}{"\t"}{.status.conditions[?(@.type=="BackendRefsResolved")].reason}{"\n"}'
done
```

Expected output:

```text
all-metrics	AllBackendRefsResolved
all-traces	AllBackendRefsResolved
all-access-logs	AllBackendRefsResolved
```
{:.no-copy-code}

## Validate

1. List the collector Pods with their node assignments, and confirm there is one per node:

   ```sh
   kubectl get pod -n mesh-observability -o wide -l app=otel-collector
   ```

1. Send a request that the Kong Air `MeshTrafficPermission` allows:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- \
     wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The response is the name of the `check-in-api` Pod that served the request:

   ```text
   check-in-api-6b4584fff-d58rx
   ```
   {:.no-copy-code}

1. Confirm all three signals reach the collector:

   ```sh
   kubectl logs -n mesh-observability -l app=otel-collector --tail=40 | grep -E 'Traces|Metrics|Logs'
   ```

   With the `debug` exporter at `verbosity: basic`, each batch shows up as one line per signal. `Traces` and `Logs` lines appear alongside `Metrics`, which flow continuously from Envoy stats. If `Metrics` appears but one of the others is missing, the corresponding `MeshTrace` or `MeshAccessLog` policy is not matching, so check its `targetRef` and its `BackendRefsResolved` condition.

With telemetry arriving, [Observe mesh traffic in practice](/mesh/observe-mesh-traffic-in-practice/) covers the Prometheus scrape jobs, the Grafana dashboards, and the policy configuration for reading it back.
