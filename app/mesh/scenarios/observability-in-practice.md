---
title: Observability
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: A guide to mesh observability, collecting metrics, traces, and logs from Kong Air's services without changing application code.
products:
  - mesh
tldr:
  q: How do I gain visibility into my service mesh?
  a: |
    {{site.mesh_product_name}} enables "zero-code instrumentation" for full stack observability:
    1. **Collect Metrics** via Prometheus and visualize with Grafana.
    2. **Capture Traces** for service-to-service calls using OpenTelemetry.
    3. **Gather Logs** for all mesh traffic with structured logging backends.
next_steps:
  - text: "Workload Identity & Trust"
    url: "/mesh/scenarios/workload-identity/"
---
## The Observability Gap

{% table %}
columns:
  - title: Challenge
    key: challenge
  - title: Legacy approach
    key: legacy
  - title: {{site.mesh_product_name}} solution
    key: solution
rows:
  - challenge: Consistency
    legacy: Different languages and frameworks use different libraries and formats.
    solution: "**Uniform Data Collection**: Every service produces data in the same format via the sidecar."
  - challenge: Effort
    legacy: Manual instrumentation and SDK maintenance.
    solution: "**Zero-Code Instrumentation**: Capture metrics and traces automatically at the proxy level."
  - challenge: Context
    legacy: Manual header propagation (`x-request-id`) is error-prone.
    solution: "**Automated Propagation**: The mesh handles span generation and context preservation."
  - challenge: Visibility
    legacy: Siloed monitoring tools across clouds.
    solution: "**Unified Global View**: Multi-zone MADS aggregates service targets into a single source of truth for discovery."
{% endtable %}

## Architecture

{{site.mesh_product_name}} follows a **decentralized, push-and-pull hybrid** architecture:

- **Data Plane Collection**: Every Envoy sidecar generates telemetry for the traffic it handles.
- **Policy-Driven Configuration**: `MeshMetric`, `MeshTrace`, and `MeshAccessLog` define where and how telemetry is sent.
- **Control Plane Orchestration**: The Control Plane configures sidecars but does **not** sit in the telemetry data path.

## Install the Observability Stack

In 2.14, `kumactl install observability` is **deprecated** and will be removed in 3.0 — running it now prints a deprecation warning. The recommended path is to install the observability tools with their own community Helm charts and then wire {{site.mesh_product_name}} into them with `MeshMetric`, `MeshTrace`, and `MeshAccessLog`. Use the dashboards shipped under [`dashboards/grafana/`](https://github.com/kumahq/kuma/tree/master/dashboards/grafana) in the Kuma repo as your starting point.

{% tip %}
**If you're on 2.13:** `kumactl install observability` still exists and is the familiar on-ramp. It is reasonable to keep using it on 2.13 if that's what your teams already know. **If you're planning for 2.14 or Kong Mesh 3**, prefer the community Helm charts and the repo-shipped Grafana dashboards shown below so you don't build new operational habits around a deprecated installer.
{% endtip %}

A minimal install for Kong Air:

```bash
# Prometheus (with the community kube-prometheus-stack chart)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace mesh-observability --create-namespace

# Grafana ships with kube-prometheus-stack; import the Kuma dashboards from
#   https://github.com/kumahq/kuma/tree/master/dashboards/grafana
# (kuma-control-plane.json, kuma-mesh-drilldown.json, kuma-workload-health.json,
#  kuma-workload-debug.json)

# Tempo, Jaeger, or any OTLP-capable backend for traces
helm upgrade --install tempo grafana/tempo --namespace mesh-observability

# Loki (or your existing log backend) for access logs
helm upgrade --install loki grafana/loki --namespace mesh-observability
```

{% warning %}
**Prometheus metric format change in 2.14.** Control-plane metrics moved from **Summary** to **Histogram**. Any dashboard or alert that uses `quantile="0.5"` / `0.9"` / `0.99"` series on Kuma CP metrics will break — switch to `histogram_quantile()` against `_bucket` series. Data-plane sidecar metrics are unaffected by this change.
{% endwarning %}

{% tip %}
**Stat name format change (KRI).** A feature flag in 2.14 (`KUMA_DATAPLANE_RUNTIME_METRICS_KRI_STATS` on the DP, `KUMA_MESH_SERVICE_KRI_STATS_ENABLED` on the CP) renames Envoy cluster, listener, and stat names to the **KRI** format — `kri_wl_<mesh>_<zone>_<namespace>_<name>_<section>`. If you enable it, expect dashboard panels that hard-code old stat names (e.g. `cluster.outbound:check-in-api_kong-air-production_svc_8080.upstream_rq_total`) to need updating.
{% endtip %}

## 1. Metrics with `MeshMetric`

Enable sidecar metrics exposure so Prometheus can scrape them:

{% navtabs "mesh-metric" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: kong-air-metrics
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
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
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshMetric
name: kong-air-metrics
mesh: kong-air-mesh
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
{% endnavtab %}
{% endnavtabs %}

{% tip %}
On a **Zone CP**, mesh-scoped observability policies created in the system namespace need `kuma.io/origin: zone`, just like `MeshExternalService`.

`MeshMetric` opens port `5670` on each sidecar for Prometheus to scrape. This requires a **pod restart** to take effect, as the sidecar must bind the new port on startup.

Prometheus uses the **Monitoring Assignment Discovery Service (MADS)** a native HTTP Service Discovery endpoint provided by the Zone Control Plane to automatically discover all sidecars, requiring no manual scrape config.
{% endtip %}

Verify the metrics endpoint after pod restart:
```bash
POD_IP=$(kubectl get pod <pod> -n kong-air-production -o jsonpath='{.status.podIP}')
kubectl exec -n kong-air-production <pod> -c <app-container> -- \
  curl -sS http://$POD_IP:5670/metrics | head -10
```

{% tip %}
On the validated 2.13 Kubernetes path, Envoy bound the metrics listener on the **pod IP**, not `127.0.0.1`. `http://localhost:5670/metrics` returned `connection refused`, while `http://$POD_IP:5670/metrics` worked.
{% endtip %}

## 2. Tracing with `MeshTrace`

Configure distributed tracing to Jaeger using the OTLP receiver:

{% navtabs "mesh-trace" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: flight-tracking
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  targetRef:
    kind: Mesh
  default:
    sampling:
      overall: 100  # 100% of requests traced for audit compliance
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
          default: "SFO"' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTrace
name: flight-tracking
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  default:
    sampling:
      overall: 100  # 100% of requests traced for audit compliance
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
          default: "SFO"' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Verify traces appear in your backend (Tempo, Jaeger, or whatever OTLP-capable collector you installed):
```bash
kubectl port-forward -n mesh-observability svc/tempo-query-frontend 3200:3200
# Or for Jaeger: kubectl port-forward -n mesh-observability svc/jaeger-query 16686:80
```

{% tip %}
On the validated 2.13 cluster, the `MeshTrace` resource applied successfully with an inline OTLP gRPC endpoint. End-to-end trace export still depends on having a working collector in-cluster, so treat that part of the scenario as an integration check.
{% endtip %}

{% warning %}
**OTLP transport: gRPC only in 2.14.** Earlier releases briefly supported HTTP/HTTPS OTel transports; those were dropped on master. Configure your tracing backend's gRPC OTLP receiver (port 4317 by convention) and use `type: OpenTelemetry` as shown above.
{% endwarning %}

### Sharing one OTel backend across policies (`MeshOpenTelemetryBackend`)

{% tip %}
**2.13 best practice:** keep the collector endpoint inline in `MeshTrace`, `MeshMetric`, and `MeshAccessLog`.

**2.14+ / Kong Mesh 3 path:** move that shared endpoint into `MeshOpenTelemetryBackend` and reference it with `backendRef`.

The validated 2.13 cluster did **not** expose a `MeshOpenTelemetryBackend` CRD yet, so don't use the resource below until you're on that newer path.
{% endtip %}

If you also configure access logs over OTel, repeating the same `openTelemetry.endpoint` in every policy is brittle. 2.14 adds a new resource — **`MeshOpenTelemetryBackend`** — that you can reference from `MeshMetric`, `MeshTrace`, and `MeshAccessLog` via `BackendResourceRef`. This is the recommended pattern going forward:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOpenTelemetryBackend
metadata:
  name: kong-air-otel
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  endpoint: otel-collector.mesh-observability:4317
  protocol: grpc
```

`MeshTrace` then refers to it by name instead of embedding the endpoint inline:

```yaml
backends:
  - type: OpenTelemetry
    openTelemetry:
      backendRef:
        kind: MeshOpenTelemetryBackend
        name: kong-air-otel
```

## 3. Logging with `MeshAccessLog`

Capture structured request logs from every sidecar:

{% navtabs "mesh-access-log" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: flight-audit-logs
  namespace: {{site.mesh_system_namespace}}
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
          - type: File
            file:
              path: /tmp/access.log
              format:
                type: Json
                json:
                  - key: "start_time"
                    value: "%START_TIME%"
                  - key: "source"
                    value: "%KUMA_SOURCE_SERVICE%"
                  - key: "destination"
                    value: "%KUMA_DESTINATION_SERVICE%"
                  - key: "status"
                    value: "%RESPONSE_CODE%"
                  - key: "duration_ms"
                    value: "%DURATION%"' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshAccessLog
name: flight-audit-logs
mesh: kong-air-mesh
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
                  - key: "start_time"
                    value: "%START_TIME%"
                  - key: "source"
                    value: "%KUMA_SOURCE_SERVICE%"
                  - key: "destination"
                    value: "%KUMA_DESTINATION_SERVICE%"
                  - key: "status"
                    value: "%RESPONSE_CODE%"
                  - key: "duration_ms"
                    value: "%DURATION%"' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Verify logs are writing immediately (no restart required):
```bash
kubectl exec -n kong-air-production <source-pod> -c kuma-sidecar -- tail -n 5 /tmp/access.log
```

Example output:
```json
{"destination":"check-in-api","duration_ms":4,"source":"client_kong-air-production_svc","start_time":"2026-05-21T11:20:02.701Z","status":0}
```

{% tip %}
On the validated 2.13 Kubernetes path, the file-backed access log showed up on the **source sidecar** after traffic was generated.

For production, use a TCP backend pointing to your Loki or Fluentd instance instead of a file, or share the `MeshOpenTelemetryBackend` defined above to ship logs over OTLP gRPC. In 2.14, the `KUMA_SOURCE_SERVICE` / `KUMA_DESTINATION_SERVICE` format codes will return KRI-format identifiers if you enable the KRI stat-name feature flag — adjust downstream log parsing accordingly.
{% endtip %}

## Multi-Zone Discovery (MADS)

In a multi-zone mesh, a single Prometheus instance can discover and scrape sidecars across all zones. Each Zone Control Plane exposes a **Monitoring Assignment Discovery Service (MADS)** endpoint. This endpoint acts as the authoritative **catalog of services**, allowing Prometheus to discover all sidecars globally without manual target configuration per zone.

Once metrics flow into Prometheus, import the [Kuma Grafana dashboards](https://github.com/kumahq/kuma/tree/master/dashboards/grafana) (shipped in the repo, designed for 2.14 metric shapes):
- `kuma-control-plane.json` — control-plane health and reconciler activity
- `kuma-mesh-drilldown.json` — fleet-wide RED metrics with mesh/zone/workload filters
- `kuma-workload-health.json` — per-workload SLOs
- `kuma-workload-debug.json` — Envoy-level retries, circuit-breaker state, and connection pool stats
