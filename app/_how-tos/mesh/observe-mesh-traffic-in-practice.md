---
title: Observe mesh traffic in practice
content_type: how_to
permalink: /mesh/observe-mesh-traffic-in-practice/
description: Collect metrics, traces, and access logs from Kong Air's services with {{site.mesh_product_name}} policies, without changing application code.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
series:
  id: mesh-kong-air-scenario
  position: 6
tldr:
  q: How do I gain visibility into my service mesh?
  a: |
    Apply three policies to the mesh's sidecars, without changing application code:
    1. `MeshMetric` exposes proxy metrics for Prometheus to scrape and Grafana to display.
    2. `MeshTrace` sends traces of service-to-service calls to an OpenTelemetry backend.
    3. `MeshAccessLog` writes a structured record for each request.
cleanup:
  inline:
    - title: Remove the telemetry policies
      include_content: md/mesh/v3/cleanup/observability
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
faqs:
  - q: How do I auto-provision the dashboards instead of importing them manually?
    a: |
      If you run `kube-prometheus-stack`, its Grafana sidecar watches for ConfigMaps labeled `grafana_dashboard: "1"`.
      The Grafana sidecar provisions every key in these ConfigMaps as its own dashboard.
      From the directory that holds the six downloaded `.json` files, create one ConfigMap for all of them, then label it:

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

      The Grafana sidecar picks up the change within seconds.
      The six files total around 450 KB, which fits inside the 1 MiB limit on a single ConfigMap.
next_steps:
  - text: "How-to: Manage workload identity and mTLS"
    url: "/mesh/manage-workload-identity-and-mtls/"
related_resources:
  - text: Deploy an OpenTelemetry collector
    url: /mesh/deploy-an-opentelemetry-collector/
  - text: MeshMetric policy
    url: /mesh/policies/meshmetric/
  - text: MeshTrace policy
    url: /mesh/policies/meshtrace/
  - text: MeshAccessLog policy
    url: /mesh/policies/meshaccesslog/
---
## The observability gap

Without a service mesh, each Kong Air service needs its own instrumentation library, and each library can use its own telemetry format.
{{site.mesh_product_name}} collects telemetry at the sidecar instead, so every service produces metrics, traces, and logs in the same format without code changes.
Every proxy in every zone tags its metrics with `mesh`, `zone`, `kuma_workload`, and `kuma_proxy_role`, so one Prometheus and Grafana stack covers the whole deployment.

## Architecture

In the Kong Air telemetry architecture, each Envoy sidecar generates telemetry for the traffic it handles.
`MeshMetric`, `MeshTrace`, and `MeshAccessLog` define what each sidecar collects and where it sends the data.
The control plane configures the sidecars but doesn't sit in the telemetry data path.

## Install the observability stack

The Kong Air observability stack is Tempo, Loki, and Prometheus, with an OpenTelemetry collector in front of them.
To install the stack, follow [Deploy an OpenTelemetry collector](/mesh/deploy-an-opentelemetry-collector/).
When the stack runs, connect {{site.mesh_product_name}} to it with the `MeshMetric`, `MeshTrace`, and `MeshAccessLog` policies in the following sections.

## Metrics with `MeshMetric`

`MeshMetric` makes each Kong Air sidecar expose its metrics, so Prometheus can scrape them:

1. Create a `MeshMetric` that exposes metrics from every sidecar on port `5670`:

   ```bash
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshMetric
   metadata:
     name: kong-air-metrics
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
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

1. After the `check-in-api` pod restarts, check its metrics endpoint:

   ```bash
   POD=$(kubectl get pod -n kong-air-production -l app=check-in-api -o jsonpath='{.items[0].metadata.name}')
   POD_IP=$(kubectl get pod "$POD" -n kong-air-production -o jsonpath='{.status.podIP}')
   kubectl exec -n kong-air-production "$POD" -c check-in-api -- \
     wget -qO- http://$POD_IP:5670/metrics | head -10
   ```

{:.info}
> `MeshMetric`, `MeshTrace`, and `MeshAccessLog` can live in an application namespace.
> This guide creates them in the system namespace (`{{site.mesh_namespace}}`), so they cover every proxy in the zone.
> `MeshOpenTelemetryBackend` can only live in the system namespace.
> For more information, see [Resource scoping](/mesh/resource-scoping/).
>
> `MeshMetric` opens port `5670` on each sidecar for Prometheus to scrape.
> The sidecar binds the new port at startup, so you must restart the pod for the change to take effect.
>
> Prometheus also needs a scrape config that targets the port.
> For the scrape config, see [Prometheus scrape jobs](#prometheus-scrape-jobs).

{:.info}
> Envoy binds the metrics listener on the pod IP.
> A request to `http://localhost:5670/metrics` returns `connection refused`, and a request to `http://$POD_IP:5670/metrics` works.

### Observing mesh-scoped zone egress

Kong Air can also collect metrics from its zone egress proxies, which carry traffic to `MeshExternalService` destinations.
For the labels that select zone proxies, and which policies support them, see [Proxy and traffic selection](/mesh/mesh-scoped-zone-proxies/#proxy-and-traffic-selection).
The following `MeshMetric` exposes Prometheus metrics from every zone egress proxy:

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

## Tracing with `MeshTrace`

`MeshTrace` makes each Kong Air sidecar send trace spans to an OTLP receiver.
A `MeshTrace` OpenTelemetry backend references a `MeshOpenTelemetryBackend`, so you create the backend first:

1. Create a `MeshOpenTelemetryBackend` named `otel-collector` that points at the collector `Service`:

   ```bash
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshOpenTelemetryBackend
   metadata:
     name: otel-collector
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
   spec:
     endpoint:
       address: otel-collector.mesh-observability
       port: 4317   # defaults to 4317 when omitted
     protocol: grpc' | kubectl apply -f -
   ```

1. Create a `MeshTrace` that traces every request and adds two Kong Air tags to each span:

   ```bash
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshTrace
   metadata:
     name: flight-tracking
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
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

1. Port-forward to your trace backend, such as Tempo or Jaeger, and check that traces arrive:

   ```bash
   kubectl port-forward -n mesh-observability svc/tempo-query-frontend 3200:3200
   # Or for Jaeger: kubectl port-forward -n mesh-observability svc/jaeger-query 16686:80
   ```

## Logging with `MeshAccessLog`

`MeshAccessLog` makes each Kong Air sidecar write a structured record for each request it sends:

1. Create a `MeshAccessLog` that writes JSON records to `/tmp/access.log` on each sidecar:

   ```bash
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshAccessLog
   metadata:
     name: flight-audit-logs
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

1. Send a request from `passenger-portal` to `check-in-api`, then read the last line of the log.
   `MeshAccessLog` takes effect without a workload restart:

   ```bash
   kubectl exec -n kong-air-production deploy/passenger-portal -- \
     wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   kubectl exec -n kong-air-production deploy/passenger-portal -c kuma-sidecar -- tail -n 1 /tmp/access.log
   ```

   The log line records the denied request:

   ```json
   {"destination":"check-in-api","duration_ms":15,"source":"passenger-portal","start_time":"2026-09-23T16:36:03.178Z","status":403}
   ```
   {:.no-copy-code}

   The `403` status is expected.
   The `MeshTrafficPermission` from [Create a security policy](/mesh/create-a-security-policy/) allows only `flight-control` to call `check-in-api`.
   So `wget` reports `server returned error: HTTP/1.1 403 Forbidden`, and the sidecar records the denied request.
   Access logs record denied requests as well as allowed ones, which makes them useful for audits.

   The `source` and `destination` values are the workloads' `kuma.io/workload` labels.
   The file backend writes on the proxy that sends the request, so read the log on the calling workload's sidecar.
   The sidecar creates `/tmp/access.log` at startup.
   A workload that hasn't sent outbound traffic has an empty file.

{:.info}
> In production, use a TCP backend that points to your Loki or Fluentd instance.
> You can also reference a `MeshOpenTelemetryBackend` to send logs over OTLP gRPC.

## Grafana dashboards

Six Grafana dashboards display the Kong Air telemetry, including Zone Ingress and Zone Egress dashboards for [mesh-scoped zone proxies](/mesh/configure-mesh-scoped-zone-proxies/).

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
    focus: Traffic to external services, MeshExternalService connection metrics
{% endtable %}
<!-- vale on -->

### Import the dashboards

Download the six dashboards from the [Kuma GitHub repository](https://github.com/kumahq/kuma/tree/master/dashboards/grafana), then import each one:

1. Open Grafana → **Dashboards** → **New** → **Import**.
2. Click **Upload JSON file** and select one of the six `.json` files.
3. Choose your Prometheus data source, then click **Import**.
4. Repeat for each dashboard.

## Prometheus scrape jobs

Two Prometheus scrape jobs cover the whole mesh:

- `kuma-dataplanes` scrapes proxy metrics on port `5670`, and finds the pods with the Kubernetes pod role. The Helm chart runs mesh-scoped zone proxies with an injected sidecar, so this job covers zone ingress and zone egress as well as workload sidecars. It feeds the Mesh Drilldown, Workload Health, Workload Debug, Zone Ingress, and Zone Egress dashboards.
- `kuma-control-plane` scrapes the control plane's own `/metrics` endpoint on port `5680`. It feeds the Control Plane dashboard.

Add the `kuma-dataplanes` job under `prometheus.prometheusSpec.additionalScrapeConfigs`:

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

Only the Control Plane dashboard filters on the `job` label, because `kuma-cp` metrics carry no proxy labels.
Every proxy sample carries `mesh`, `zone`, `kuma_workload`, and `kuma_proxy_role` (`sidecar`, `gateway`, `zone-ingress`, or `zone-egress`).
The other five dashboards select proxies by these labels, so they need no relabeling beyond `pod` and `namespace`.

## Validate

1. Send a request from `flight-control` to `check-in-api`, which the `MeshTrafficPermission` from [Create a security policy](/mesh/create-a-security-policy/) allows:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

1. Check that `MeshAccessLog` recorded the request on the `flight-control` sidecar:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -c kuma-sidecar -- tail -n 1 /tmp/access.log
   ```

   The log line shows the request to `check-in-api` with a `200` status:

   ```json
   {"destination":"check-in-api","duration_ms":3,"source":"flight-control","start_time":"2026-09-23T16:30:37.200Z","status":200}
   ```
   {:.no-copy-code}

The `flight-control` sidecar wrote a structured record for the allowed request.
Your Prometheus metrics and tracing backend use the same request data.
