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

Use it to give a monitoring system one combined view of each workload, reduce the Envoy metrics
you store, or send the same metrics to more than one backend during a migration.

A proxy with no matching `MeshMetric` does not expose a Prometheus endpoint or push metrics to
an OpenTelemetry collector. A matching policy also needs at least one entry in `backends` before
it publishes anything.

This policy does not install Prometheus, deploy an OpenTelemetry collector, or add metrics
instrumentation to your application. The application must already expose metrics in
Prometheus format if you want the sidecar to collect them. Control-plane metrics are
configured separately; this page describes data-plane and workload metrics.

## Publish sidecar and application metrics for Prometheus

This policy applies to proxies labeled `app: backend`, scrapes the application's own metrics
endpoint, and exposes the combined application and proxy metrics on port 5670:

Before applying it, confirm that the application serves Prometheus metrics at
`/metrics/prometheus` on port `8888`, and that `5670` is available on the selected proxies.
If you only need proxy metrics, omit `applications`.

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

What each field does:

* `targetRef` selects **which proxies publish metrics**.
* `applications` tells each selected proxy which endpoint on its co-located application to
  scrape. The proxy combines those metrics with its own.
* `backends` says **where the combined metrics go**. This example creates a Prometheus endpoint
  on each selected proxy at `:5670/metrics`.

Because this example does not set `sidecar.profiles`, the proxy publishes the `Basic` profile.
It leaves out unused metrics until the proxy records them.

Configure Prometheus discovery or a scrape target for each selected data-plane address,
port `5670`, and path `/metrics`. Creating this policy exposes an endpoint; it does not
make an existing Prometheus server discover that endpoint automatically. Avoid also
scraping the application directly into the same monitoring pipeline unless you intend
to retain duplicate observations under different target labels.

### Check that it works

Send some traffic through the workload, then request the metrics endpoint from a host that can
reach the data plane address:

```sh
curl http://DATAPLANE_ADDRESS:5670/metrics
```

The response uses the Prometheus text format. It contains the used metrics from the `Basic`
sidecar profile and the metrics returned by the application at port 8888. If the application
metrics are absent, confirm that `/metrics/prometheus` is reachable from the sidecar.
Then check the target in Prometheus itself: a successful manual request proves the endpoint
works, but not that Prometheus can discover, reach, and store its metrics.

## Where this policy applies

`spec.targetRef` selects the proxies whose metrics are configured, and accepts `Mesh` or
`Dataplane` with `labels`. Everything sits under `default`: there is no `to` or `rules`, since
a proxy's metrics describe the proxy rather than any particular traffic.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## How multiple policies combine

When both a mesh-wide policy and a more specific `Dataplane` policy match a proxy, the
`Dataplane` policy takes precedence for fields it sets. Object fields that it omits continue to
come from the mesh-wide policy, but lists such as `applications` and `backends` replace the
broader list instead of being appended to it.

Set `backends: []` in the more specific policy to stop the selected proxies from publishing
metrics while leaving the mesh-wide policy in place for every other proxy.

For example, replacing a mesh-wide Prometheus `backends` list with an OpenTelemetry-only
list removes Prometheus exposure for the selected proxies. Include both backends in the
narrower list if both must remain enabled. `sidecar.profiles.appendProfiles` is an exception
to list replacement: those profile entries accumulate across applicable policies. Adding
`None` cannot subtract an inherited `Basic` or `All` profile.

## Choose which sidecar metrics are published

`default.sidecar.profiles` builds the set of Envoy metrics to publish, starting from one or
more named profiles and then adding to or subtracting from them. If you omit `profiles`, the
proxy starts with `Basic`.

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
selected by the name filter. `Basic` also removes samples for internal proxy components;
an `include` name match does not undo that sample-level filtering. Use an explicit `All`
or `None` base when building a selection that needs those internal samples.

Selectors match Prometheus metric-family names, such as `envoy_cluster_upstream_rq_total`,
not raw Envoy stat names such as `cluster.backend.upstream_rq_total`, and not label values.
These filters apply to sidecar metrics, not to the application's own metric families.

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

Place this fragment under `default`. It starts with `Basic`, removes cluster metric
families, then adds back families whose names contain `upstream_rq`:

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

A missing metric is therefore not necessarily a collection failure or a zero value. It
can be outside the selected profile or unused since the proxy started. Generate the relevant
traffic before checking, or enable `includeUnused` when a dashboard needs untouched series.
Using `All` together with `includeUnused: true` can substantially increase output and storage;
test the volume on a small set of proxies first.

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

Application scraping is an HTTP metrics request, not application instrumentation. Verify
the address, port, and path from the sidecar's network environment; `localhost` in an
operator's terminal is not necessarily the application's address. The endpoint must return
valid Prometheus metrics, not a health-check response or an HTML login page.

## Backends

`default.backends` accepts more than one entry, so the same metrics can be exposed for
Prometheus and pushed to a collector at once. Omitting `backends`, or setting it to an empty
list, publishes nothing.

### Prometheus

The sidecar exposes an endpoint for Prometheus to scrape, on `port` 5670 and `path` `/metrics`
by default. `clientId` identifies the backend when MADS is used for proxy discovery.

Prometheus controls how often it scrapes this endpoint. The OpenTelemetry
`refreshInterval` does not change the Prometheus scrape interval. Restrict network access
to the metrics port: metrics can reveal service names, topology, and application labels.

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

`ProvidedTLS` also falls back to plaintext when either certificate path is missing from
the proxy metadata. Mount the certificate and key where the data-plane process can read
them, set both environment variables, and verify the actual HTTPS endpoint before relying
on encryption. Configure Prometheus to trust the issuing CA and the certificate's server
name; setting this mode does not automatically configure the scraper.

### OpenTelemetry

`openTelemetry.backendRef` names a
[MeshOpenTelemetryBackend](/mesh/meshopentelemetrybackend/) by labels, and `refreshInterval`
sets how often metrics are pushed to it. The interval defaults to one minute.

Create that backend resource first, with a reachable collector endpoint and a metrics
receiver enabled. Copy its identifying labels into `backendRef.labels`; the example
selects the resource labeled `kuma.io/display-name: otel-collector`, not a Kubernetes
Service merely named `otel-collector`. Collector transport and credentials belong in
the backend resource, not in this policy.

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

`kuma-dp` collects Envoy and application metrics and exports them through its OpenTelemetry
pipeline to the collector. Where several `MeshOpenTelemetryBackend` resources match the
labels, the oldest wins; use labels that identify one intended resource. If no backend
resolves, that export destination is skipped rather than replaced with a default collector.

## Validate collection and export

1. Generate traffic and choose one proxy metric and one application metric whose values
   should change. Confirm both at the combined Prometheus endpoint, if configured.
1. For OpenTelemetry, wait at least the configured export interval, then inspect the
   collector's received metrics and the final storage backend. Collector receipt and
   successful downstream storage are separate checks.
1. If proxy metrics are present but application metrics are absent, request the application
   endpoint from the sidecar's network environment and inspect `kuma-dp` logs for failed
   scrapes, non-200 responses, or parsing errors.
1. If only some proxy series are absent, check profiles, name selectors, and `includeUnused`
   before changing the collector configuration.
1. If OpenTelemetry receives nothing, check backend label resolution, endpoint and protocol,
   credentials, network reachability, and exporter errors in `kuma-dp`.
1. When TLS is required, test HTTPS with certificate verification and confirm plaintext
   access is not available. Policy acceptance alone does not prove the endpoint is encrypted.
