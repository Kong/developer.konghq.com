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
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshmetric"
- text: MeshTrace policy
  url: "/mesh/policies/meshtrace/"
- text: MeshAccessLog policy
  url: "/mesh/policies/meshaccesslog/"
---

The `MeshMetric` policy controls what a proxy publishes about itself and its application, and
where:

* With `sidecar`, it selects which of the sidecar's Envoy metrics are published.
* With `applications`, it sets which application endpoints the sidecar scrapes and republishes.
* With `backends`, it exposes the result for Prometheus to scrape, or pushes it to an
  OpenTelemetry collector.

Use this policy to give a monitoring system one combined view of each workload, reduce the
Envoy metrics you store, or send the same metrics to more than one backend during a migration.

Proxies that no `MeshMetric` selects publish no metrics, and a matching policy publishes
nothing until it has at least one entry in `backends`.

This policy doesn't install Prometheus, deploy an OpenTelemetry collector, or instrument your
application. To collect application metrics, the application must already expose them in
Prometheus format. Control plane metrics are configured separately.

## Publish sidecar and application metrics for Prometheus

The following example makes proxies labeled `app: backend` scrape their application's metrics,
and expose them with the proxy's own metrics on port `5670`. Before applying it, confirm that
the application serves Prometheus metrics at `/metrics/prometheus` on port `8888`, and that
port `5670` is free on the selected proxies. For proxy metrics only, omit `applications`:

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

* `targetRef` selects the proxies that publish metrics: `Mesh`, or `Dataplane` with `labels`.
  There's no `to` or `rules`, because a proxy's metrics describe the proxy, not specific
  traffic.
* `applications` sets the application endpoint each proxy scrapes and combines with its own
  metrics.
* `backends` sets where the metrics go. This example exposes a Prometheus endpoint at
  `:5670/metrics` on each selected proxy.

Without `sidecar.profiles`, the proxy publishes the `Basic` profile, and leaves out metrics it
hasn't recorded yet.

The policy exposes the endpoint, but Prometheus doesn't discover it automatically. Add
discovery or a scrape target for port `5670` and path `/metrics` on each selected data plane.
Don't also scrape the application directly into the same pipeline, unless you want duplicate
series under different target labels.

## Overlapping policies

When a mesh-wide policy and a more specific `Dataplane` policy both match a proxy, the
`Dataplane` policy wins for the fields it sets, and inherits the rest. Lists such as
`applications` and `backends` are replaced, not appended. For example, an OpenTelemetry-only
`backends` list in the narrower policy removes the mesh-wide Prometheus endpoint for those
proxies, so include both backends if you need both.

To stop the selected proxies from publishing metrics while keeping the mesh-wide policy for
every other proxy, set `backends: []` in the narrower policy.

`sidecar.profiles.appendProfiles` is the exception: profiles accumulate across policies, so
adding `None` can't remove an inherited `Basic` or `All` profile.

## Sidecar metrics

`default.sidecar.profiles` builds the set of Envoy metrics to publish from one or more base
profiles. Without `profiles`, the proxy uses `Basic`. The following profiles are available:

{% table %}
columns:
  - title: Profile
    key: name
  - title: Contains
    key: what
rows:
  - name: "`Basic`"
    what: "The metrics most deployments watch."
  - name: "`All`"
    what: "Every metric Envoy exposes."
  - name: "`None`"
    what: "No metrics, as a base for `include`."
{% endtable %}

Adjust the set with the following fields:

* `appendProfiles`: combines profiles.
* `exclude`: removes metrics from the result.
* `include`: adds metrics back. It takes precedence over `exclude`.

`Basic` also drops samples for internal proxy components, and `include` doesn't bring them
back. To keep those samples, start from `All` or `None`.

Selectors match Prometheus metric family names, such as `envoy_cluster_upstream_rq_total`.
They don't match raw Envoy stat names, such as `cluster.backend.upstream_rq_total`, or label
values. They only apply to sidecar metrics, not to the application's metrics.

Each `include` and `exclude` entry has a `type` and a `match`. `type` accepts the following
values:

{% table %}
columns:
  - title: "`type`"
    key: type
  - title: Matches
    key: what
rows:
  - type: "`Exact`"
    what: "The metric name in `match`."
  - type: "`Prefix`"
    what: "Names starting with `match`."
  - type: "`Contains`"
    what: "Names containing `match`."
  - type: "`Regex`"
    what: "Names matching the `match` expression. An expression that doesn't compile is rejected."
{% endtable %}

The following example starts with `Basic`, removes cluster metric families, then adds back
families whose names contain `upstream_rq`. Place it under `default`:

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

`sidecar.includeUnused` publishes metrics that were never recorded, such as counters at zero or
histograms with no observations. It defaults to `false`.

A missing metric isn't necessarily a collection failure. It might be outside the selected
profile, or unused since the proxy started. Generate traffic before checking, or enable
`includeUnused` if a dashboard needs those series. `All` with `includeUnused: true` can greatly
increase output and storage, so test it on a few proxies first.

## Scrape the application

`default.applications` lists endpoints on the workload that the proxy scrapes and republishes
with its own metrics, so the workload doesn't need its own scrape target. Each entry accepts the
following fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: "`port`"
    value: "The application's port, 1 to 65535. Required."
  - field: "`path`"
    value: "The path to scrape. Defaults to `/metrics`."
  - field: "`address`"
    value: "The address to scrape, if the application isn't on localhost."
  - field: "`name`"
    value: "A name used to label the application's metrics."
{% endtable %}

`applications` is ignored on a zone-proxy-only `Dataplane`, which has no application to scrape.

Scraping is an HTTP request to the application, not instrumentation. Check the address, port,
and path from the sidecar's network, not from your terminal. The endpoint must return valid
Prometheus metrics, not a health check response or a login page.

## Backends

`default.backends` accepts several entries, so you can expose metrics for Prometheus and push
them to a collector at the same time. An empty or missing `backends` publishes nothing.

### Prometheus

The sidecar exposes an endpoint for Prometheus to scrape, on `port` 5670 and `path` `/metrics`
by default. `clientId` identifies the backend when proxies are discovered through the
Monitoring Assignment Discovery Service (MADS).

Prometheus sets its own scrape interval, and the OpenTelemetry `refreshInterval` doesn't affect
it. Restrict network access to the metrics port, because metrics can reveal service names,
topology, and application labels.

`prometheus.tls.mode` sets whether the endpoint uses TLS:

{% table %}
columns:
  - title: "`mode`"
    key: mode
  - title: Effect
    key: what
rows:
  - mode: "`Disabled`"
    what: "Plaintext. This is the default."
  - mode: "`ProvidedTLS`"
    what: "TLS, with a certificate and key that you supply to the sidecar through `KUMA_DATAPLANE_RUNTIME_METRICS_CERT_PATH` and `KUMA_DATAPLANE_RUNTIME_METRICS_KEY_PATH`."
{% endtable %}

`ProvidedTLS` also falls back to plaintext if either certificate path is missing from the proxy
metadata. Mount the certificate and key where the data plane process can read them, set both
environment variables, and check the HTTPS endpoint before relying on encryption. Prometheus
isn't configured automatically, so configure it to trust the issuing CA and the certificate's
server name.

### OpenTelemetry

`openTelemetry.backendRef` selects a
[MeshOpenTelemetryBackend](/mesh/meshopentelemetrybackend/) by labels, and `refreshInterval`
sets how often metrics are pushed to it. The interval defaults to one minute.

Create the backend resource first, with a reachable collector endpoint and a metrics receiver
enabled. Collector transport and credentials belong in the backend resource, not in this
policy.

The following example pushes metrics every 30 seconds to the backend resource labeled
`kuma.io/display-name: otel-collector`. The label selects the `MeshOpenTelemetryBackend`
resource, not a Kubernetes Service named `otel-collector`:

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

`kuma-dp` collects Envoy and application metrics and exports them to the collector. If several
`MeshOpenTelemetryBackend` resources match the labels, the oldest wins, so use labels that
identify one resource. If no backend matches, the export is skipped. There's no default
collector.

## Validating collection and export

1. Generate traffic, and pick one proxy metric and one application metric that should change.
1. If Prometheus is configured, request `http://DATAPLANE_ADDRESS:5670/metrics` from a host
   that can reach the data plane, and confirm that both metrics are there.
1. Check the target in Prometheus. A manual request proves that the endpoint works, not that
   Prometheus discovers, reaches, and stores it.
1. For OpenTelemetry, wait at least one export interval, then confirm that the metrics reached
   both the collector and the final storage backend.
1. When TLS is required, test HTTPS with certificate verification, and confirm that plaintext
   access is unavailable. Policy acceptance alone doesn't prove encryption.

{% table %}
columns:
  - title: Unexpected result
    key: unexpected
  - title: Check
    key: check
rows:
  - unexpected: "Proxy metrics are present, but application metrics are missing"
    check: "Request the application endpoint from the sidecar's network, and look in `kuma-dp` logs for failed scrapes, non-200 responses, or parsing errors."
  - unexpected: "Some proxy series are missing"
    check: "Profiles, name selectors, and `includeUnused`, before changing the collector configuration."
  - unexpected: "OpenTelemetry receives nothing"
    check: "Backend label resolution, endpoint and protocol, credentials, network access, and exporter errors in `kuma-dp`."
{% endtable %}
