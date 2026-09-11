---
title: Mesh Metric
name: MeshMetrics
products:
- mesh
description: Choose which sidecar and application metrics a proxy publishes, and where they go.
content_type: plugin
icon: meshmetric.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshmetric"
- text: MeshTrace policy
  url: "/mesh/policies/meshtrace/"
- text: MeshAccessLog policy
  url: "/mesh/policies/meshaccesslog/"
---

`MeshMetric` decides what a proxy publishes about itself and the application beside it, and
which backends receive it. It covers three separate things: which of the sidecar's own Envoy
metrics are published, which application endpoints the sidecar scrapes and republishes, and
whether the result is exposed for Prometheus to pull or pushed to an OpenTelemetry collector.

## Publish sidecar and application metrics for Prometheus

This policy applies to proxies labelled `app: backend`, scrapes the application's own metrics
endpoint, and exposes everything on the sidecar's Prometheus port:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshMetric
mesh: default
name: backend-metrics
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  default:
    applications:
      - path: /metrics/prometheus
        port: 8888
    backends:
      - type: Prometheus
        prometheus:
          port: 5670
          path: /metrics
```
{% endpolicy_yaml %}

## Where this policy applies

`spec.targetRef` selects the proxies whose metrics are configured, and accepts `Mesh` or
`Dataplane` with `labels`. Everything sits under `default`: there is no `to` or `rules`, since
a proxy's metrics describe the proxy rather than any particular traffic.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## Choose which sidecar metrics are published

`default.sidecar.profiles` builds the set of Envoy metrics to publish, starting from one or
more named profiles and then adding to or subtracting from them.

{% table %}
columns:
  - title: Profile
    key: name
  - title: Contains
    key: what
rows:
  - name: "`Basic`"
    what: "A working set of the metrics most deployments watch."
  - name: "`All`"
    what: "Everything Envoy exposes."
  - name: "`None`"
    what: "Nothing, as a base to add to with `include`."
{% endtable %}

`appendProfiles` combines profiles, `exclude` removes metrics from the result, and `include`
adds them back. **`include` takes precedence over `exclude`**, so a metric matched by both is
published.

Each entry in `include` and `exclude` is a `type` and a `match`:

{% table %}
columns:
  - title: "`type`"
    key: type
  - title: Matches
    key: what
rows:
  - type: "`Exact`"
    what: "The metric name exactly."
  - type: "`Prefix`"
    what: "Metric names starting with `match`."
  - type: "`Contains`"
    what: "Metric names containing `match`."
  - type: "`Regex`"
    what: "Metric names matching the expression. An expression that does not compile is rejected with `invalid regex`."
{% endtable %}

```yaml
sidecar:
  profiles:
    appendProfiles:
      - name: Basic
    include:
      - type: Contains
        match: upstream_rq
    exclude:
      - type: Prefix
        match: envoy_cluster_
```

`sidecar.includeUnused` publishes metrics that have never been touched — counters still at
zero, histograms with no observations. It defaults to false, which keeps the output to metrics
the proxy has actually recorded.

## Scrape the application

`default.applications` lists endpoints on the workload beside the sidecar that the proxy
scrapes and republishes alongside its own metrics. A workload exposing Prometheus metrics
therefore needs no separate scrape target.

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: "`port`"
    value: "The port the application listens on, 1 to 65535. Required."
  - field: "`path`"
    value: "The path to scrape, `/metrics` by default."
  - field: "`address`"
    value: "The address to scrape, where the application is not on localhost."
  - field: "`name`"
    value: "A name for the application, used to label the metrics."
{% endtable %}

`applications` is ignored on a zone-proxy-only `Dataplane`, which has no co-located workload to
scrape.

## Backends

`default.backends` accepts more than one entry, so the same metrics can be exposed for
Prometheus and pushed to a collector at once.

### Prometheus

The sidecar exposes an endpoint for Prometheus to scrape, on `port` 5670 and `path` `/metrics`
by default. `clientId` identifies the backend when MADS is used for proxy discovery.

`prometheus.tls.mode` sets whether that endpoint uses TLS:

{% table %}
columns:
  - title: "`mode`"
    key: mode
  - title: Effect
    key: what
rows:
  - mode: "`Disabled`"
    what: "Plaintext. The default."
  - mode: "`ProvidedTLS`"
    what: "TLS using a certificate and key you supply to the sidecar through `KUMA_DATAPLANE_RUNTIME_METRICS_CERT_PATH` and `KUMA_DATAPLANE_RUNTIME_METRICS_KEY_PATH`."
{% endtable %}

{:.warning}
> The schema also accepts `ActiveMTLSBackend`, which no longer does anything. TLS is applied
> only when the mode is `ProvidedTLS` and the certificate paths are set, so a policy carrying
> `ActiveMTLSBackend` is accepted and serves its metrics endpoint in plaintext. It took its
> certificates from the mesh CA backend, which v3 removed.

### OpenTelemetry

`openTelemetry.backendRef` names a `MeshOpenTelemetryBackend` by labels, and
`refreshInterval` sets how often metrics are pushed to it.

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshMetric
mesh: default
name: backend-otel-metrics
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            labels:
              kuma.io/display-name: otel-collector
          refreshInterval: 30s
```
{% endpolicy_yaml %}

Metrics for an OpenTelemetry backend leave through `kuma-dp`: Envoy exports to a Unix socket
and `kuma-dp` forwards to the collector. Where several `MeshOpenTelemetryBackend` resources
match the labels, the oldest wins.
