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

Install the observability tools with their own community Helm charts and then wire {{site.mesh_product_name}} into them with `MeshMetric`, `MeshTrace`, and `MeshAccessLog`.

A minimal install for Kong Air:

```bash
# Prometheus + Grafana (kube-prometheus-stack bundles both)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace mesh-observability --create-namespace

# Tempo, Jaeger, or any OTLP-capable backend for traces
helm upgrade --install tempo grafana/tempo --namespace mesh-observability

# Loki (or your existing log backend) for access logs
helm upgrade --install loki grafana/loki --namespace mesh-observability
```

{% warning %}
Prometheus metric format change in 2.14. Control-plane metrics moved from **Summary** to **Histogram**. Any dashboard or alert that uses `quantile="0.5"` / `"0.9"` / `"0.99"` series on {{site.mesh_product_name}} CP metrics will break, switch to `histogram_quantile()` against `_bucket` series. Data-plane sidecar metrics are unaffected by this change.
{% endwarning %}

{% tip %}
Stat name format change (KRI). A feature flag in 2.14 (`KUMA_DATAPLANE_RUNTIME_METRICS_KRI_STATS` on the DP, `KUMA_MESH_SERVICE_KRI_STATS_ENABLED` on the CP) renames Envoy cluster, listener, and stat names to the **KRI** format, `kri_wl_<mesh>_<zone>_<namespace>_<name>_<section>`. If you enable it, expect dashboard panels that hard-code old stat names (e.g. `cluster.outbound:check-in-api_kong-air-production_svc_8080.upstream_rq_total`) to need updating.
{% endtip %}

## 1. Metrics with `MeshMetric`

Enable sidecar metrics exposure so Prometheus can scrape them:

{% navtabs "mesh-metric" %}
{% navtab "Kubernetes (Zone CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: kong-air-metrics
  namespace: {{site.mesh_namespace}}
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
{% navtab "Universal (Zone CP)" %}
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

Verify the metrics endpoint after pod restart (using `check-in-api` as the example workload):
```bash
POD=$(kubectl get pod -n kong-air-production -l app=check-in-api -o jsonpath='{.items[0].metadata.name}')
POD_IP=$(kubectl get pod "$POD" -n kong-air-production -o jsonpath='{.status.podIP}')
kubectl exec -n kong-air-production "$POD" -c check-in-api -- \
  wget -qO- http://$POD_IP:5670/metrics | head -10
```

{% tip %}
Envoy binds the metrics listener on the **pod IP**, not `127.0.0.1`. `http://localhost:5670/metrics` returns `connection refused`, while `http://$POD_IP:5670/metrics` works.
{% endtip %}

### Observing mesh-scoped zone egress

One of the important 2.14 improvements is that observability policies can target mesh-scoped zone proxies directly. For example, Kong Air can gather Prometheus metrics for every zone egress proxy with:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: zone-egress-metrics
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneegress: enabled
  default:
    backends:
      - type: Prometheus
        prometheus:
          port: 5670
          path: /metrics
          tls:
            mode: Disabled
```

This is the cleanest way to get telemetry on the cross-zone and external-service hop itself, not just on the calling and receiving sidecars.

## 2. Tracing with `MeshTrace`

Configure distributed tracing to an OTLP gRPC receiver:

{% navtabs "mesh-trace" %}
{% navtab "Kubernetes (Zone CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: flight-tracking
  namespace: {{site.mesh_namespace}}
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
          endpoint: otel-collector.mesh-observability:4317
    tags:
      - name: division
        literal: passenger-service
      - name: airport-code
        header:
          name: x-airport-code
          default: "SFO"' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Zone CP)" %}
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
          endpoint: otel-collector.mesh-observability:4317
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

Verify traces appear in your backend (Tempo, Jaeger, or another OTLP-capable collector you installed):
```bash
kubectl port-forward -n mesh-observability svc/tempo-query-frontend 3200:3200
# Or for Jaeger: kubectl port-forward -n mesh-observability svc/jaeger-query 16686:80
```

{% tip %}
End-to-end trace export still depends on having a working collector in-cluster, so treat that part of the scenario as an integration check.
{% endtip %}

{% warning %}
OTLP transport: gRPC only in 2.14. Earlier releases briefly supported HTTP/HTTPS OTel transports; those were dropped on master. Configure your tracing backend's gRPC OTLP receiver (port 4317 by convention) and use `type: OpenTelemetry` as shown above.
{% endwarning %}

### Sharing one OTel backend across policies (`MeshOpenTelemetryBackend`)

If you also configure access logs or metrics over OTel, repeating the same collector endpoint in every policy is brittle. 2.14 adds a new resource, **`MeshOpenTelemetryBackend`**, that you can reference from `MeshMetric`, `MeshTrace`, and `MeshAccessLog` via `backendRef`. This is the recommended pattern going forward:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOpenTelemetryBackend
metadata:
  name: kong-air-otel
  namespace: {{site.mesh_namespace}}
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
{% navtab "Kubernetes (Zone CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: flight-audit-logs
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
{% navtab "Universal (Zone CP)" %}
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
SRC=$(kubectl get pod -n kong-air-production -l app=passenger-portal -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kong-air-production "$SRC" -c kuma-sidecar -- tail -n 5 /tmp/access.log
```

Example output:
```json
{"destination":"check-in-api","duration_ms":4,"source":"passenger-portal_kong-air-production_svc","start_time":"2026-05-21T11:20:02.701Z","status":200}
```

{% tip %}
On Kubernetes, the file-backed access log showed up on the **source sidecar** after traffic was generated.

For production, use a TCP backend pointing to your Loki or Fluentd instance instead of a file, or share the `MeshOpenTelemetryBackend` defined above to ship logs over OTLP gRPC. In 2.14, the `KUMA_SOURCE_SERVICE` / `KUMA_DESTINATION_SERVICE` format codes will return KRI-format identifiers if you enable the KRI stat-name feature flag, adjust downstream log parsing accordingly.
{% endtip %}

## 4. Grafana Dashboards

{{site.mesh_product_name}} 2.14 ships six Grafana dashboards. Two are new in this release, **Zone Ingress** and **Zone Egress**, providing first-class observability for [mesh-scoped zone proxies](/mesh/scenarios/mesh-scoped-zone-proxies/).

{% table %}
columns:
  - title: File
    key: file
  - title: Title
    key: title
  - title: What it shows
    key: focus
rows:
  - file: "`kuma-control-plane.json`"
    title: Control Plane
    focus: xDS generation latency, KDS sync, store ops, gRPC server health
  - file: "`kuma-mesh.json`"
    title: Mesh Drilldown
    focus: Fleet-wide RED metrics with mesh/zone/workload filters
  - file: "`kuma-service-health.json`"
    title: Workload Health
    focus: Per-workload request rate, error rate, latency percentiles (inbound and outbound)
  - file: "`kuma-service-debug.json`"
    title: Workload Debug
    focus: Envoy-level retries, circuit-breaker state, connection pool saturation, DNS
  - file: "`kuma-zone-ingress.json`"
    title: Zone Ingress *(new)*
    focus: Cross-zone inbound traffic, mTLS handshakes, upstream cluster health, xDS delivery
  - file: "`kuma-zone-egress.json`"
    title: Zone Egress *(new)*
    focus: Outbound traffic to remote zones and external services, MeshExternalService connection metrics
{% endtable %}

### Getting the dashboards

You can also download individual dashboards directly from the [Kuma GitHub repository](https://github.com/kumahq/kuma/tree/master/dashboards/grafana).

### Option A, Manual import (any Grafana)

1. Open Grafana → **Dashboards** → **New** → **Import**.
2. Click **Upload JSON file** and select one of the six `.json` files.
3. Choose your Prometheus datasource, then click **Import**.
4. Repeat for each dashboard.

### Option B, ConfigMap auto-provisioning (kube-prometheus-stack)

`kube-prometheus-stack` includes a Grafana sidecar that watches for ConfigMaps labeled `grafana_dashboard: "1"`. Create one ConfigMap per dashboard, then label it:

```bash
for f in kuma-*.json; do
  name="kuma-dashboard-${f%.json}"
  kubectl create configmap "$name" --from-file="$f" -n mesh-observability
  kubectl label configmap "$name" grafana_dashboard=1 -n mesh-observability
done
```

The sidecar detects the ConfigMaps within seconds and provisions the dashboards automatically into Grafana.

## Prometheus Scrape Jobs

The dashboards filter metrics by `job` label. Three scrape jobs are required. Add them under `prometheus.prometheusSpec.additionalScrapeConfigs` in your kube-prometheus-stack Helm values.

### `kuma-dataplanes`, sidecar metrics via MADS

This job uses {{site.mesh_product_name}}'s native Prometheus service discovery (**MADS**) to discover sidecar scrape targets automatically. MADS runs on the Zone Control Plane at port `5676` and acts as the authoritative catalog of all Dataplane proxies in the zone, no manual target configuration needed.

This feeds the **Workload Health**, **Workload Debug**, and **Mesh Drilldown** dashboards.

```yaml
- job_name: kuma-dataplanes
  scrape_interval: 5s
  metrics_path: /metrics
  kuma_sd_configs:
    - server: http://kong-mesh-control-plane.{{site.mesh_namespace}}:5676
  relabel_configs:
    - source_labels: [__meta_kuma_mesh]
      target_label: mesh
    - source_labels: [__meta_kuma_dataplane]
      target_label: dataplane
    - action: labelmap
      regex: __meta_kuma_label_(.+)
    - source_labels: [k8s_kuma_io_name]
      target_label: pod
    - source_labels: [k8s_kuma_io_namespace]
      target_label: namespace
```

### `kuma-control-plane`, CP metrics

Scrapes the Control Plane's own `/metrics` endpoint. Feeds the **Control Plane** dashboard.

```yaml
- job_name: kuma-control-plane
  metrics_path: /metrics
  static_configs:
    - targets:
        - kong-mesh-control-plane.{{site.mesh_namespace}}:5680
```

### `kuma-zone-proxies`, zone ingress and egress metrics (new in 2.14)

Scrapes zone proxy pods using Kubernetes pod SD. Zone proxies expose Envoy stats at port `9902` (the readiness proxy, which also serves `/stats/prometheus`). This job feeds the new **Zone Ingress** and **Zone Egress** dashboards.

```yaml
- job_name: kuma-zone-proxies
  metrics_path: /stats/prometheus
  kubernetes_sd_configs:
    - role: pod
      namespaces:
        names: [{{site.mesh_namespace}}]
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_label_k8s_kuma_io_zone_proxy_type]
      regex: ingress|egress
      action: keep
    - source_labels: [__meta_kubernetes_pod_label_k8s_kuma_io_zone_proxy_type]
      target_label: proxy
    - source_labels: [__meta_kubernetes_pod_label_kuma_io_mesh]
      target_label: mesh
    - source_labels: [__meta_kubernetes_namespace]
      target_label: namespace
    - source_labels: [__address__]
      regex: '(.+?)(:[0-9]+)?$'
      target_label: __address__
      replacement: '${1}:9902'
    - source_labels: [__meta_kubernetes_pod_name]
      target_label: pod
    - target_label: zone
      replacement: zone1  # replace with the zone name for this Prometheus instance
```
