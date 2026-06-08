You'll install the bundled observability stack, then turn on all three signals at the mesh level and verify each one end to end.

### Step 1: Install the bundled stack

`kumactl install observability` renders manifests for Prometheus, Grafana, Jaeger, Loki, and Promtail, pre-wired against the MADS discovery endpoint and bundled Grafana dashboards.

```bash
kumactl install observability --namespace mesh-observability | kubectl apply -f -
```

Confirm the four core pods are up:

```bash
kubectl get pods -n mesh-observability
# expect: prometheus-*, grafana-*, jaeger-*, loki-*, promtail-*
```

### Step 2: Enable metrics with `MeshMetric`

This opens port `5670` on every sidecar for Prometheus to scrape. **A pod restart is required** for sidecars to bind the new listener.

{% navtabs "mesh-metric" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: kong-air-metrics
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    sidecar:
      profiles:
        appendProfiles:
          - name: Basic
    backends:
      - type: Prometheus
        prometheus:
          port: 5670
          path: /metrics
          tls:
            mode: Disabled' | kubectl apply -f -

kubectl rollout restart deploy -n kong-air-production
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshMetric
name: kong-air-metrics
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    sidecar:
      profiles:
        appendProfiles:
          - name: Basic
    backends:
      - type: Prometheus
        prometheus:
          port: 5670
          path: /metrics
          tls:
            mode: Disabled' | kumactl apply -f -
```

Restart the data plane processes on each VM after applying.
{% endnavtab %}
{% endnavtabs %}

Once the pods restart, verify metrics are being exposed:

```bash
POD=$(kubectl get pod -n kong-air-production -l app=flight-control -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kong-air-production "$POD" -c kuma-sidecar -- wget -qO- http://localhost:5670/metrics | head -10
```

You should see Envoy/{{site.mesh_product_name}} metric lines (`envoy_cluster_upstream_rq_total{...}` etc.).

### Step 3: Enable tracing with `MeshTrace`

Point traces at the bundled Jaeger collector's OTLP gRPC endpoint. No pod restart needed — xDS reconfigures the filter chain.

{% navtabs "mesh-trace" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: flight-tracking
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    sampling:
      overall: 100
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: jaeger-collector.mesh-observability:4317
    tags:
      - name: division
        literal: passenger-service
      - name: airport-code
        header:
          name: x-airport-code
          default: SFO' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTrace
name: flight-tracking
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    sampling:
      overall: 100
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: jaeger-collector.mesh-observability:4317
    tags:
      - name: division
        literal: passenger-service
      - name: airport-code
        header:
          name: x-airport-code
          default: SFO' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Generate a few requests, then open Jaeger:

```bash
kubectl port-forward -n mesh-observability svc/jaeger-query 16686:80
# Open http://localhost:16686
```

Search for the `flight-control` service. You should see traces with spans for each hop, decorated with the `division=passenger-service` and `airport-code=SFO` tags you configured.

{% tip %}
Drop `sampling.overall` to `5` (5%) before promoting to production — 100% sampling is a useful default for a hands-on exercise but can be expensive at real traffic volumes.
{% endtip %}

### Step 4: Enable structured logging with `MeshAccessLog`

Write JSON access logs to a file on each sidecar — also no restart needed.

{% navtabs "mesh-access-log" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: flight-audit-logs
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        backends:
          - type: File
            file:
              path: /tmp/access.log
              format:
                type: Json
                json:
                  - key: start_time
                    value: "%START_TIME%"
                  - key: source
                    value: "%KUMA_SOURCE_SERVICE%"
                  - key: destination
                    value: "%KUMA_DESTINATION_SERVICE%"
                  - key: status
                    value: "%RESPONSE_CODE%"
                  - key: duration_ms
                    value: "%DURATION%"' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshAccessLog
name: flight-audit-logs
mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        backends:
          - type: File
            file:
              path: /tmp/access.log
              format:
                type: Json
                json:
                  - key: start_time
                    value: "%START_TIME%"
                  - key: source
                    value: "%KUMA_SOURCE_SERVICE%"
                  - key: destination
                    value: "%KUMA_DESTINATION_SERVICE%"
                  - key: status
                    value: "%RESPONSE_CODE%"
                  - key: duration_ms
                    value: "%DURATION%"' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Tail the log from a sidecar to confirm:

```bash
kubectl exec -n kong-air-production "$POD" -c kuma-sidecar -- tail -f /tmp/access.log
```

Each request through that sidecar produces a JSON line:

```json
{"destination":"check-in-api_kong-air-production_svc_8080","duration_ms":9,"source":"flight-control_kong-air-production_svc_8080","start_time":"2026-05-19T02:11:46.164Z","status":200}
```

{% tip %}
For production, swap the `File` backend for a `Tcp` or `OpenTelemetry` backend pointing at your central log pipeline (Loki, Fluentd, Splunk). Promtail (deployed with `kumactl install observability`) can also tail the files in pods automatically.
{% endtip %}

### Step 5: Open Grafana and confirm the service map

```bash
kubectl port-forward -n mesh-observability svc/grafana 3000:80
# Open http://localhost:3000 (admin / admin)
```

The bundled dashboards include a **{{site.mesh_product_name}} Service Map** that renders the live topology from the metrics you just enabled. You should see your Kong Air services connected by edges labelled with request rates and p99 latencies.

### What you did

- Installed the bundled observability stack against the mesh.
- Turned on Prometheus metrics, OTLP traces, and JSON access logs at the mesh level.
- Verified each signal end to end — `/metrics` scraping, Jaeger traces, sidecar access log lines.
- Confirmed the Grafana service map renders the topology automatically.

In Step 2 you'll go beyond the mesh-wide CA from Fundamentals and assign per-workload SPIFFE identities with `MeshIdentity` + `MeshTrust`.
