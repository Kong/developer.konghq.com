---
title: Observe mesh traffic in practice
content_type: how_to
permalink: /mesh/observe-mesh-traffic-in-practice/
description: A guide to mesh observability, collecting metrics, traces, and logs from Kong Air's services without changing application code.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I gain visibility into my service mesh?
  a: |
    {{site.mesh_product_name}} enables "zero-code instrumentation" for full stack observability:
    1. Collect Metrics via Prometheus and visualize with Grafana.
    2. Capture Traces for service-to-service calls using OpenTelemetry.
    3. Gather Logs for all mesh traffic with structured logging backends.
prereqs:
  inline:
    - title: Kong Air demo deployment
      content: |
        A running {{site.mesh_product_name}} deployment with the Kong Air demo apps in `kong-air-mesh`. See [Get started with your first policy](/mesh/get-started-with-your-first-policy/).
cleanup:
  inline:
    - title: Remove the telemetry policies
      include_content: md/mesh/v3/cleanup/observability
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
next_steps:
  - text: "Manage workload identity and mTLS"
    url: "/mesh/manage-workload-identity-and-mtls/"
related_resources:
  - text: Deploy an OpenTelemetry collector
    url: /mesh/deploy-an-opentelemetry-collector/
  - text: MeshOpenTelemetryBackend
    url: /mesh/meshopentelemetrybackend/
  - text: Mesh observability
    url: /mesh/observability/
---
## The observability gap

<!-- vale off -->
{% table %}
columns:
  - title: Challenge
    key: challenge
  - title: Without mesh-level telemetry
    key: without_mesh
  - title: {{site.mesh_product_name}} solution
    key: solution
rows:
  - challenge: Consistency
    without_mesh: Different languages and frameworks use different libraries and formats.
    solution: "Uniform Data Collection: Every service produces data in the same format via the sidecar."
  - challenge: Effort
    without_mesh: Manual instrumentation and SDK maintenance.
    solution: "Zero-Code Instrumentation: Capture metrics and traces automatically at the proxy level."
  - challenge: Context
    without_mesh: Manual header propagation (`x-request-id`) is error-prone.
    solution: "Automated Propagation: The mesh handles span generation and context preservation."
  - challenge: Visibility
    without_mesh: Siloed monitoring tools across clouds.
    solution: "Unified Global View: Every proxy in every zone emits the same series, tagged with `mesh`, `zone`, `kuma_workload`, and `kuma_proxy_role`, so one Prometheus and Grafana stack covers the whole deployment."
{% endtable %}
<!-- vale on -->

## Architecture

{{site.mesh_product_name}} follows a decentralized, push-and-pull hybrid architecture:

- Data Plane Collection: Every Envoy sidecar generates telemetry for the traffic it handles.
- Policy-Driven Configuration: `MeshMetric`, `MeshTrace`, and `MeshAccessLog` define where and how telemetry is sent.
- Control Plane Orchestration: The Control Plane configures sidecars but does not sit in the telemetry data path.

## Install the observability stack

Install and wire up the Prometheus, Grafana, and tracing backends by following the canonical [mesh observability](/mesh/observability/) reference. To collect traces and OTel-based logs, deploy a collector as described in [Deploy an OpenTelemetry collector](/mesh/deploy-an-opentelemetry-collector/). Once the stack is running, wire {{site.mesh_product_name}} into it with the following `MeshMetric`, `MeshTrace`, and `MeshAccessLog` policies.

## Metrics with `MeshMetric`

Enable sidecar metrics exposure so Prometheus can scrape them:

1. Apply the `MeshMetric` policy:

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

1. Verify the metrics endpoint after pod restart (using `check-in-api` as the example workload):

   ```bash
   POD=$(kubectl get pod -n kong-air-production -l app=check-in-api -o jsonpath='{.items[0].metadata.name}')
   POD_IP=$(kubectl get pod "$POD" -n kong-air-production -o jsonpath='{.status.podIP}')
   kubectl exec -n kong-air-production "$POD" -c check-in-api -- \
     wget -qO- http://$POD_IP:5670/metrics | head -10
   ```

{:.info}
> `MeshMetric`, `MeshTrace`, and `MeshAccessLog` can live in an application namespace, but this guide applies them mesh-wide from the system namespace (`{{site.mesh_namespace}}`), and `MeshOpenTelemetryBackend` can only be created there. A zone control plane connected to a global control plane requires every resource created in that namespace to carry `kuma.io/origin: zone`, and rejects it otherwise. See [Resource scoping](/mesh/resource-scoping/).
>
> `MeshMetric` opens port `5670` on each sidecar for Prometheus to scrape. This requires a pod restart to take effect, as the sidecar must bind the new port on startup.
>
> Exposing the port is only half the job. Prometheus still needs a scrape config that targets it, which [Prometheus scrape jobs](#prometheus-scrape-jobs) covers.

{:.info}
> Envoy binds the metrics listener on the pod IP, not `127.0.0.1`. `http://localhost:5670/metrics` returns `connection refused`, while `http://$POD_IP:5670/metrics` works.

### Observing mesh-scoped zone egress

Observability policies can target mesh-scoped zone proxies directly. For example, Kong Air can gather Prometheus metrics for every zone egress proxy with:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: zone-egress-metrics
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
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

## Tracing with `MeshTrace`

Configure distributed tracing to an OTLP receiver.

A `MeshTrace` OpenTelemetry backend references a `MeshOpenTelemetryBackend` resource, so define the collector once first:

1. Define the collector:

   ```bash
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshOpenTelemetryBackend
   metadata:
     name: otel-collector
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
       kuma.io/origin: zone
   spec:
     endpoint:
       address: otel-collector.mesh-observability
       port: 4317   # defaults to 4317 when omitted
     protocol: grpc' | kubectl apply -f -
   ```

1. Apply the `MeshTrace` policy:

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
             backendRef:
               kind: MeshOpenTelemetryBackend
               labels:
                 kuma.io/display-name: otel-collector
       tags:
         - name: division
           literal: passenger-service
         - name: airport-code
           header:
             name: x-airport-code
             default: "SFO"' | kubectl apply -f -
   ```

1. Confirm the policy resolved its `backendRef`. A `backendRef` that matches no `MeshOpenTelemetryBackend` still leaves the policy accepted, and it exports nothing without reporting an error, so check the status condition:

   ```sh
   kubectl get meshtrace flight-tracking -n {{site.mesh_namespace}} -o jsonpath='{.status.conditions}'
   ```

   Expected output:

   ```json
   [{"message":"All MeshOpenTelemetryBackend references are resolved","reason":"AllBackendRefsResolved","status":"True","type":"BackendRefsResolved"}]
   ```
   {:.no-copy-code}

1. Verify traces appear in your backend (Tempo, Jaeger, or another OTLP-capable collector you installed):

   ```bash
   kubectl port-forward -n mesh-observability svc/tempo-query-frontend 3200:3200
   # Or for Jaeger: kubectl port-forward -n mesh-observability svc/jaeger-query 16686:80
   ```

{:.info}
> End-to-end trace export still depends on having a working collector in-cluster, so treat that part of the scenario as an integration check.

{:.warning}
> A `MeshTrace` OpenTelemetry backend takes a `backendRef` only. There is no inline `endpoint` field, so the collector address always comes from a `MeshOpenTelemetryBackend`. That resource's `protocol` accepts `grpc` or `http`; `grpc` on port 4317 is the usual choice for a tracing receiver.

### Sharing one OTel backend across policies (`MeshOpenTelemetryBackend`)

`MeshOpenTelemetryBackend` holds the collector address, port, and protocol in one place, and `MeshMetric`, `MeshTrace`, and `MeshAccessLog` all reach it through a `backendRef`. Define it once and every OTel-bound policy points at the same resource, so moving the collector is a one-resource change. See [MeshOpenTelemetryBackend](/mesh/meshopentelemetrybackend/) for the resource fields and configuration examples.

## Logging with `MeshAccessLog`

Capture structured request logs from every sidecar:

1. Apply the `MeshAccessLog` policy:

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

1. Send a request so there is something to log, then read the log. `MeshAccessLog` takes effect without restarting the workload:

   ```bash
   kubectl exec -n kong-air-production deploy/passenger-portal -- \
     wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   kubectl exec -n kong-air-production deploy/passenger-portal -c kuma-sidecar -- tail -n 1 /tmp/access.log
   ```

   Example output:

   ```json
   {"destination":"check-in-api","duration_ms":15,"source":"passenger-portal","start_time":"2026-09-23T16:36:03.178Z","status":403}
   ```
   {:.no-copy-code}

   The `403` is expected, and it is what makes this step worth running. The `MeshTrafficPermission` from [Get started with your first policy](/mesh/get-started-with-your-first-policy/) admits only `flight-control` into `check-in-api`, so `wget` reports `server returned error: HTTP/1.1 403 Forbidden` and the sidecar records the refusal. Access logs capture denied requests as well as permitted ones, which is what makes them useful for audit.

   The `source` and `destination` values are the workloads' `kuma.io/workload` labels. Read the log on the calling workload's sidecar, since the file backend writes on the proxy that originates the request. The sidecar creates `/tmp/access.log` at startup, so a workload that has sent no outbound traffic has an empty file rather than a missing one.

{:.info}
> For production, use a TCP backend pointing to your Loki or Fluentd instance instead of a file, or share a `MeshOpenTelemetryBackend` to ship logs over OTLP gRPC.

## Grafana dashboards

The observability package includes six Grafana dashboards, including Zone Ingress and Zone Egress dashboards for [mesh-scoped zone proxies](/mesh/configure-mesh-scoped-zone-proxies/).

<!-- vale off -->
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
    title: Zone Ingress
    focus: Cross-zone inbound traffic, mTLS handshakes, upstream cluster health, xDS delivery
  - file: "`kuma-zone-egress.json`"
    title: Zone Egress
    focus: Outbound traffic to remote zones and external services, MeshExternalService connection metrics
{% endtable %}
<!-- vale on -->

### Getting the dashboards

You can also download individual dashboards directly from the [Kuma GitHub repository](https://github.com/kumahq/kuma/tree/master/dashboards/grafana).

### Option A, manual import (any Grafana)

1. Open Grafana → **Dashboards** → **New** → **Import**.
2. Click **Upload JSON file** and select one of the six `.json` files.
3. Choose your Prometheus data source, then click **Import**.
4. Repeat for each dashboard.

### Option B, ConfigMap auto-provisioning (kube-prometheus-stack)

`kube-prometheus-stack` includes a Grafana sidecar that watches for ConfigMaps labeled `grafana_dashboard: "1"`. From the directory holding the six downloaded `.json` files, create one ConfigMap for all of them, then label it:

```bash
kubectl create configmap kuma-dashboards -n mesh-observability \
  --from-file=kuma-control-plane.json \
  --from-file=kuma-mesh.json \
  --from-file=kuma-service-health.json \
  --from-file=kuma-service-debug.json \
  --from-file=kuma-zone-ingress.json \
  --from-file=kuma-zone-egress.json

kubectl label configmap kuma-dashboards grafana_dashboard=1 -n mesh-observability
```

The sidecar provisions every key in the ConfigMap as its own dashboard, and picks up the change within seconds. The six files total around 450 KB, comfortably inside the 1 MiB limit on a single ConfigMap.

## Prometheus scrape jobs

Two scrape jobs cover the whole mesh:

- `kuma-dataplanes`: proxy metrics on port `5670`, discovered with the Kubernetes pod role. Mesh-scoped zone proxies are ordinary `Dataplane` resources with an injected sidecar, so this one job covers zone ingress and zone egress alongside workload sidecars. Feeds the Mesh Drilldown, Workload Health, Workload Debug, Zone Ingress, and Zone Egress dashboards.
- `kuma-control-plane`: the control plane's own `/metrics` endpoint on port `5680`. Feeds the Control Plane dashboard.

Add the proxy job under `prometheus.prometheusSpec.additionalScrapeConfigs`:

```yaml
- job_name: kuma-dataplanes
  metrics_path: /metrics
  kubernetes_sd_configs:
    - role: pod
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_container_name]
      regex: kuma-sidecar
      action: keep
    - source_labels: [__meta_kubernetes_pod_phase]
      regex: Running
      action: keep
    - source_labels: [__address__]
      regex: '(.+?)(:[0-9]+)?'
      target_label: __address__
      replacement: '${1}:5670'
    - source_labels: [__meta_kubernetes_pod_name]
      target_label: pod
    - source_labels: [__meta_kubernetes_namespace]
      target_label: namespace
```

Only the Control Plane dashboard filters on the `job` label, because `kuma-cp` metrics carry no proxy labels. Every sample a proxy emits already carries `mesh`, `zone`, `kuma_workload`, and `kuma_proxy_role` (`sidecar`, `gateway`, `zone-ingress`, or `zone-egress`), so the other five dashboards select proxies by those labels and need no relabeling beyond `pod` and `namespace`.

For the rest of the stack configuration, see the canonical [mesh observability](/mesh/observability/) reference.

## Validate

1. Generate a request from `flight-control` to `check-in-api` (already permitted by the `MeshTrafficPermission` from [Get started with your first policy](/mesh/get-started-with-your-first-policy/)):

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

1. Confirm `MeshAccessLog` captured the request on `flight-control`'s sidecar:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -c kuma-sidecar -- tail -n 1 /tmp/access.log
   ```

   Expected output, with `destination`, `status`, and `duration_ms` confirming the request was logged:

   ```json
   {"destination":"check-in-api","duration_ms":3,"source":"flight-control","start_time":"2026-09-23T16:30:37.200Z","status":200}
   ```
   {:.no-copy-code}

Together, these confirm telemetry is flowing end-to-end: the sidecar captured, formatted, and wrote a structured record for the request, the same request-response data your Prometheus metrics and tracing backend rely on.
