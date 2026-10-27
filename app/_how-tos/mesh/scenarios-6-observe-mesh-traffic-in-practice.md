---
title: Observe mesh traffic in practice
content_type: how_to
permalink: /mesh/observe-mesh-traffic-in-practice/
description: Scrape Kong Air's proxy metrics with Prometheus, display them in Grafana dashboards, and write an access log on each sidecar with {{site.mesh_product_name}} policies.
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
  q: How do I see my mesh traffic in Prometheus, Grafana, and access logs?
  a: |
    Extend the telemetry policies from the previous guide, without changing application code:
    1. Add a Prometheus backend to `MeshMetric`, and add Prometheus scrape jobs for the proxies and the control plane.
    2. Add a file backend to `MeshAccessLog`, so each sidecar writes a structured record for each request.
    3. Install Grafana and import the {{site.mesh_product_name}} dashboards.
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
  - q: Do I need a separate `MeshMetric` for the zone ingress and zone egress?
    a: |
      No. The `all-metrics` policy targets `kind: Mesh` from the system namespace, so it selects every proxy in the zone, including the zone ingress and zone egress.
      After you add the Prometheus backend, the zone proxies expose their metrics on port `5670` too, and the Zone Ingress and Zone Egress dashboards display them.

      Don't create a second `MeshMetric` that targets the zone proxies with its own `backends` list.
      A `Dataplane` `targetRef` outranks `Mesh`, so its `backends` list replaces the one from `all-metrics`, and the collector stops receiving metrics from those proxies.
      For the labels that select zone proxies, see [Proxy and traffic selection](/mesh/mesh-scoped-zone-proxies/#proxy-and-traffic-selection).
next_steps:
  - text: "How-to: Connect a second zone"
    url: "/mesh/connect-a-second-zone/"
related_resources:
  - text: Deploy an OpenTelemetry collector
    url: /mesh/deploy-an-opentelemetry-collector/
  - text: MeshMetric policy
    url: /mesh/policies/meshmetric/
  - text: MeshAccessLog policy
    url: /mesh/policies/meshaccesslog/
---

## Update `MeshMetric`

The collector from [Deploy an OpenTelemetry collector](/mesh/deploy-an-opentelemetry-collector/) already exports the proxy metrics to Prometheus, but without `pod` and `namespace` labels.
The {{site.mesh_product_name}} Grafana dashboards filter on these labels, and only a Prometheus scrape of each proxy adds them.
Add a Prometheus backend to `MeshMetric`, which makes each Kong Air sidecar expose its metrics for Prometheus to scrape.

1. Update the `all-metrics` policy so every sidecar also exposes its metrics on port `5670`.
   The `OpenTelemetry` backend stays, so the collector keeps receiving metrics:

   ```bash
   echo 'apiVersion: kuma.io/v1alpha1
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
       sidecar:
         profiles:
           appendProfiles:
             - name: Basic
       backends:
         - type: OpenTelemetry
           openTelemetry:
             backendRef:
               kind: MeshOpenTelemetryBackend
               labels:
                 kuma.io/display-name: otel-collector
             refreshInterval: 30s
         - type: Prometheus
           prometheus:
             port: 5670
             path: /metrics
             tls:
               mode: Disabled' | kubectl apply -f -
   ```

1. Restart the Kong Air workloads:

   ```bash
   kubectl rollout restart deployment -n kong-air-production
   kubectl rollout status deployment -n kong-air-production --timeout=120s
   ```

1. Check the metrics endpoint of a `check-in-api` Pod:

   ```bash
   POD=$(kubectl get pod -n kong-air-production -l app=check-in-api -o jsonpath='{.items[0].metadata.name}')
   POD_IP=$(kubectl get pod "$POD" -n kong-air-production -o jsonpath='{.status.podIP}')
   kubectl exec -n kong-air-production "$POD" -c check-in-api -- \
     wget -qO- http://$POD_IP:5670/metrics | head -10
   ```

## Update `MeshAccessLog`

`MeshAccessLog` makes each Kong Air sidecar write a structured record for each request it sends.

1. Update the `all-access-logs` policy so each sidecar also writes JSON records to `/tmp/access.log`.
   The `OpenTelemetry` backend stays, so the collector keeps receiving logs:

   ```bash
   echo 'apiVersion: kuma.io/v1alpha1
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

{:.info}
> In production, use a TCP backend that points to your Loki or Fluentd instance.
> You can also reference a `MeshOpenTelemetryBackend` to send logs over OTLP gRPC.

## Configure Prometheus scrape jobs

Two Prometheus scrape jobs cover the whole mesh:

- `kuma-dataplanes` scrapes proxy metrics on port `5670`, and finds the Pods with the Kubernetes pod role. The Helm chart runs mesh-scoped zone proxies with an injected sidecar, so this job covers zone ingress and zone egress as well as workload sidecars. It feeds the Mesh Drilldown, Workload Health, Workload Debug, Zone Ingress, and Zone Egress dashboards.
- `kuma-control-plane` scrapes the control plane's own `/metrics` endpoint on port `5680`. It feeds the Control Plane dashboard.

1. Create a values file with the two {{site.mesh_product_name}} jobs.
   `extraScrapeConfigs` is one string, so this value replaces the `otel-collector` job:

   ```sh
   cat > values-prometheus.yaml <<'EOF'
   extraScrapeConfigs: |
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
     - job_name: kuma-control-plane
       metrics_path: /metrics
       static_configs:
         - targets: ['kong-mesh-control-plane.{{site.mesh_namespace}}:5680']
   EOF
   ```

1. Upgrade the Prometheus release with the new values:

   ```sh
   helm upgrade prometheus prometheus-community/prometheus \
     --namespace mesh-observability --reuse-values \
     -f values-prometheus.yaml
   ```

## Configure Grafana dashboards

Six Grafana dashboards display the Kong Air telemetry, including Zone Ingress and Zone Egress dashboards for [mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/).

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

### Install Grafana

1. Create a values file that adds Prometheus as the default Grafana data source:

   ```sh
   cat > values-grafana.yaml <<'EOF'
   datasources:
     datasources.yaml:
       apiVersion: 1
       datasources:
         - name: Prometheus
           type: prometheus
           url: http://prometheus-server.mesh-observability.svc.cluster.local
           access: proxy
           isDefault: true
   EOF
   ```

1. Install Grafana in the `mesh-observability` namespace:

   ```sh
   helm install grafana grafana/grafana \
     --namespace mesh-observability \
     -f values-grafana.yaml --wait
   ```

1. Print the password of the Grafana `admin` user:

   ```sh
   kubectl get secret grafana -n mesh-observability \
     -o jsonpath='{.data.admin-password}' | base64 --decode; echo
   ```

1. Forward the Grafana port to your machine:

   ```sh
   kubectl port-forward -n mesh-observability svc/grafana 3000:80 > /dev/null 2>&1 &
   export GRAFANA_PORT_FORWARD_PID=$!
   ```

   The port-forward runs in the background, so you can keep using the same terminal.

### Import the dashboards

1. Download the six dashboards from the [Kuma GitHub repository](https://github.com/kumahq/kuma/tree/master/dashboards/grafana):

   ```sh
   for d in kuma-control-plane kuma-mesh kuma-service-health kuma-service-debug kuma-zone-ingress kuma-zone-egress; do
     curl -fsSLO "https://raw.githubusercontent.com/kumahq/kuma/master/dashboards/grafana/$d.json"
   done
   ```

1. Open `http://localhost:3000` in your browser, and log in as `admin` with the password from the previous step.
1. In the sidebar, click **Dashboards**.
1. Click **Create dashboard**.
1. Click **Import dashboard**.
1. Select one of the six `.json` files.
1. Choose the `Prometheus` data source.
1. Click **Import**.
1. Repeat for each dashboard.

## Validate

Check that Prometheus scrapes the proxies and the control plane:

```sh
kubectl exec -n mesh-observability deploy/prometheus-server -c prometheus-server -- \
  promtool query instant http://localhost:9090 'count by (job) (up{job=~"kuma-.*"} == 1)'
```

The output shows how many targets of each job are up:

```text
{job="kuma-control-plane"} => 1 @[1793008905.132]
{job="kuma-dataplanes"} => 6 @[1793008905.132]
```
{:.no-copy-code}

`kuma-dataplanes` reports one target for each Pod with a sidecar: the four Kong Air workloads, the zone ingress, and the zone egress.

To see why a target is down, run `kubectl port-forward -n mesh-observability svc/prometheus-server 9090:80`, then open `http://localhost:9090/targets`.
The page shows the last scrape error of each target.
