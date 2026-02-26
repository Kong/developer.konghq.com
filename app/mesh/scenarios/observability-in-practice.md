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
    Kong Mesh enables "zero-code instrumention" for full stack observability:
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

{{site.mesh_product_name}} ships a bundled observability stack including Prometheus, Grafana, Jaeger, and Loki:

```bash
kumactl install observability --namespace mesh-observability | kubectl apply -f -
```

This deploys:
- **Prometheus**: metrics collection and MADS-based service discovery
- **Grafana**: dashboards (including the Service Map)
- **Jaeger**: distributed tracing (accepts OTLP on port 4317)
- **Loki + Promtail**: log aggregation

## 1. Metrics with `MeshMetric`

Enable sidecar metrics exposure so Prometheus can scrape them:

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
{% endnavtab %}
{% endnavtabs %}

{% tip %}
`MeshMetric` opens port `5670` on each sidecar for Prometheus to scrape. This requires a **pod restart** to take effect, as the sidecar must bind the new port on startup.

Prometheus uses the **Monitoring Assignment Discovery Service (MADS)** a native HTTP Service Discovery endpoint provided by the Zone Control Plane to automatically discover all sidecars, requiring no manual scrape config.
{% endtip %}

Verify the metrics endpoint after pod restart:
```bash
kubectl exec <pod> -c kuma-sidecar -- wget -qO- http://localhost:5670/metrics | head -10
```

## 2. Tracing with `MeshTrace`

Configure distributed tracing to Jaeger using the OTLP receiver:

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
mesh: default
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

Verify traces appear in Jaeger:
```bash
kubectl port-forward -n mesh-observability svc/jaeger-query 16686:80
# Open http://localhost:16686; search for service "flight-control-blu_kong-air-production_svc_8080"
```

{% tip %}
Jaeger is bundled with `kumactl install observability` and exposes an OTLP gRPC endpoint on port `4317` via `jaeger-collector.mesh-observability:4317`. No separate OpenTelemetry Collector is required.
{% endtip %}

## 3. Logging with `MeshAccessLog`

Capture structured request logs from every sidecar:

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
kubectl exec <pod> -c kuma-sidecar -- cat /tmp/access.log
```

Example output:
```json
{"destination":"check-in-api-blu_kong-air-production_svc_8080","duration_ms":9,"source":"flight-control-blu_kong-air-production_svc_8080","start_time":"2026-02-19T02:11:46.164Z","status":200}
```

{% tip %}
For production, use a TCP backend pointing to your Loki or Fluentd instance instead of a file. Promtail (deployed with `kumactl install observability`) can tail files from pods automatically.
{% endtip %}

## Multi-Zone Discovery (MADS)

In a multi-zone mesh, a single Prometheus instance can discover and scrape sidecars across all zones. Each Zone Control Plane exposes a **Monitoring Assignment Discovery Service (MADS)** endpoint. This endpoint acts as the authoritative **catalog of services**, allowing Prometheus to discover all sidecars globally without manual target configuration per zone.

Once metrics flow into Prometheus, the bundled **Grafana dashboards** provide:
- Per-service latency, error rate, and throughput
- A real-time **Service Map** showing cross-zone topology
