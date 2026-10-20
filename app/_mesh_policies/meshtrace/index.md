---
title: Mesh Trace
name: MeshTraces
products:
- mesh
description: Export distributed traces for the requests a proxy handles, to Zipkin, Datadog or an OpenTelemetry collector.
content_type: plugin
icon: meshtrace.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshtrace"
- text: MeshAccessLog policy
  url: "/mesh/policies/meshaccesslog/"
- text: MeshMetric policy
  url: "/mesh/policies/meshmetric/"
---

The `MeshTrace` policy makes a proxy emit spans for sampled HTTP requests and send them to a
tracing backend. A span records one hop of a request, including its timing and outcome. When
services propagate trace context, the backend joins the spans from each hop into one end-to-end
trace.

A proxy can't link an outbound request to the inbound request that caused it, so the
application must carry trace context across its calls. Otherwise, you get spans for every
service but separate traces. Use application instrumentation with a propagation format that
your tracing provider supports. Proxy tracing doesn't create spans for database queries or
other work inside the application.

Proxies that no `MeshTrace` selects don't emit spans.

## Send traces to Zipkin

The following example sends spans to a Zipkin-compatible collector

The collector is already running, reachable from the proxies, and accepting Zipkin v2
spans. Replace the example URL with your collector's ingestion endpoint:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrace
mesh: default
name: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: Zipkin
        zipkin:
          url: http://jaeger-collector.observability:9411/api/v2/spans
```
{% endpolicy_yaml %}

What each field does:

* `targetRef` selects which proxies emit spans. `kind: Mesh` means every proxy in the policy's
  own namespace. If the policy is created in `{{site.mesh_namespace}}`, the policy applies to
  the whole zone. To trace every zone, create the policy on the global control plane. For more
  information, see [Where a policy applies](/mesh/policy-targeting/#where-a-policy-applies).
* `default` holds the rest of the configuration. There's no `to` or `rules`, because each span
  describes one hop and comes from the proxy that handled it.
* `backends` sets the tracing provider, and `zipkin.url` is where each proxy sends its spans.

The example omits `sampling`, so every eligible request is sampled. Spans add export traffic
and storage, and can contain URLs and other request metadata. Test on a limited workload before
you sample 100% of a busy mesh, then set a production rate based on the resulting volume.

A selected proxy can emit inbound and outbound spans. `targetRef` doesn't accept
`sectionName`, so a policy applies to every HTTP listener of the selected proxies.

Tracing works only where the proxy parses HTTP, including HTTP/2 and gRPC. It can't create
spans for plain TCP, or for application-encrypted traffic that it forwards without decrypting.
If traffic appears in metrics but not in traces, check the declared inbound and service-port
protocols.

## Keep one trace across application calls

For a request from `frontend` through `backend` to another service, `backend` must extract the
incoming context and inject it into its outgoing request. Use your tracing library's
propagator, so span relationships and sampling decisions stay consistent. Each provider uses
the following context:

{% table %}
columns:
  - title: Provider
    key: provider
  - title: Context to propagate
    key: context
rows:
  - provider: "Zipkin"
    context: "B3: the `b3` header, or the `x-b3-traceid`, `x-b3-spanid`, `x-b3-parentspanid`, `x-b3-sampled`, and `x-b3-flags` headers."
  - provider: "OpenTelemetry"
    context: "W3C: `traceparent`, and `tracestate` when present."
  - provider: "Datadog"
    context: "Datadog headers, including `x-datadog-trace-id`, `x-datadog-parent-id`, and `x-datadog-sampling-priority`."
{% endtable %}

Also preserve `x-request-id` to correlate requests. Forwarding B3 headers isn't enough for every backend. For more information, see
[Envoy trace propagation](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing#trace-context-propagation)
and [W3C tracing headers](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#traceparent).

## Backends

`default.backends` is required and takes at most one entry, because Envoy accepts one tracing
provider per listener. To send spans to several systems, export to one collector and have it
forward them. An empty list is accepted. For more information, see
[Turn tracing off for part of the mesh](#turn-tracing-off-for-part-of-the-mesh).

Each backend `type` accepts the following configuration:

{% table %}
columns:
  - title: "`type`"
    key: type
  - title: Configuration
    key: conf
rows:
  - type: "`Zipkin`"
    conf: |
      * `url`: a valid collector URL
      * `apiVersion`: `httpJson` (default) or `httpProto`
      * `traceId128bit`: emits 128-bit trace IDs, off by default
      * `sharedSpanContext`: client and server spans share one context, on by default
  - type: "`Datadog`"
    conf: |
      * `url`: the agent URL, with the `http` scheme, a port, and no path, query, fragment, user, or opaque part. For example, `https://agent:8126` and `http://agent:8126/traces` both fail validation
      * `splitService`: splits the reported service name by direction and destination, off by default
  - type: "`OpenTelemetry`"
    conf: "`backendRef`: a `MeshOpenTelemetryBackend`, selected by labels."
{% endtable %}

An OpenTelemetry backend references a
[MeshOpenTelemetryBackend](/mesh/meshopentelemetrybackend/) resource by labels. Create that
resource first, with the collector endpoint, transport, and credentials, and with labels that
match `backendRef.labels`. The
collector needs a traces receiver and export pipeline.

The following example sends spans to the `otel-collector` backend:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrace
mesh: default
name: otel-tracing
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            labels:
              kuma.io/display-name: otel-collector
```
{% endpolicy_yaml %}

Envoy exports OpenTelemetry spans to a Unix socket, and `kuma-dp` forwards them to the
collector. If several `MeshOpenTelemetryBackend` resources match the labels, the oldest wins,
so use labels that identify one backend. If the reference doesn't resolve, the proxy gets no
usable tracing provider and doesn't fall back to another collector. Check reference resolution
before you debug network export.

## Sampling

`default.sampling` sets how many requests produce a trace. It accepts the following fields.
Each takes a percentage from 0 to 100, as an integer or a quoted decimal, and defaults to 100.
A value outside the range is rejected.

{% table %}
columns:
  - title: Field
    key: field
  - title: What it limits
    key: what
rows:
  - field: "`client`"
    what: "Requests with an `x-client-trace-id` header, which the client sends to ask for a trace."
  - field: "`random`"
    what: "Randomly picked requests that didn't ask for or force a trace."
  - field: "`overall`"
    what: "The ceiling on `client` and `random` combined. For example, `client: 100` with `overall: 1` traces only 1% of the requests that asked for it."
{% endtable %}

The following example traces every request that asks for a trace, and 0.1% of other requests:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrace
mesh: default
name: sampled-tracing
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: Zipkin
        zipkin:
          url: http://jaeger-collector.observability:9411/api/v2/spans
    sampling:
      client: 100
      random: "0.1"
      overall: 100
```
{% endpolicy_yaml %}

Requests that ask for tracing still pass `client: 100`, so
set `overall` if you need to limit them too. Sampling isn't an exact quota for every small
batch of requests, and propagated context and provider sampling also affect which traces you
see.

## Custom tags

`default.tags` adds tags to every span, from a request header or a fixed string. Each entry
takes a `name` and either `header` or `literal`.

The following example adds a fixed `team` tag and an `env` tag from the `x-env` header. Place
it under `default`, next to the required `backends` list:

```yaml
tags:
  - name: team
    literal: core
  - name: env
    header:
      name: x-env
      default: unknown
```

A `header` tag without a `default` is left off the span when the header is missing.

Use low-cardinality values, such as team or environment. Don't copy authorization headers,
session cookies, or other secrets into tags. Exported tags are stored outside the request path,
and other users of the tracing backend might be able to search them.

The proxy also adds `kuma.mesh`, `kuma.zone`, and, when available, `kuma.workload` tags. A
custom tag with one of those names replaces the built-in value, so avoid those names unless you
mean to override it.

## Turn tracing off for part of the mesh

An empty `backends` list produces no tracing configuration. Because a more specific policy
overrides a broader one, you can use it to exempt some proxies from a mesh-wide policy. The
following example turns off tracing for proxies labeled `app: batch`:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrace
mesh: default
name: no-tracing-for-batch
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: batch
  default:
    backends: []
```
{% endpolicy_yaml %}

`sampling` and `tags` have no effect with an empty `backends` list.

This stops spans from those proxies only. It doesn't turn off application instrumentation, or
spans from other proxies on the request path. Removing the policy restores the broader one.

## Overlapping policies

A more specific policy overrides conflicting fields from a broader one. Object fields can
inherit omitted values, but `backends` and `tags` lists replace the broader lists. Every policy
must still set `backends`, even if it only changes sampling or tags.

For example, a workload policy with the same backend and `sampling.random: 1` lowers random
sampling and inherits the broader `sampling.overall`. Adding one custom tag to that policy
replaces the whole broader tag list, so repeat every tag you want to keep.

## Validating trace export

1. Check connectivity, HTTP protocol handling, and collector readiness. Temporarily set 100%
   sampling on the test workloads, so sampling doesn't hide export failures.
1. Send a request through at least two meshed services, and record its trace ID from the
   propagated context or instrumentation. A request ID isn't necessarily the trace ID that the
   backend shows.
1. Find the trace in the backend, and confirm that it has a span for each proxy hop.
1. If the trace stops at one service, confirm that the application forwards the trace headers
   to its outbound request.
1. For sampling below 100%, send enough requests to confirm the rate.
1. For OpenTelemetry, confirm that the `MeshOpenTelemetryBackend` reference resolves, and check
   `kuma-dp` exporter errors and the spans the collector received. A reachable collector
   doesn't prove that its pipeline stored the trace.
1. Restore the intended sampling rate.

{% table %}
columns:
  - title: Unexpected result
    key: unexpected
  - title: Check
    key: check
rows:
  - unexpected: "No spans arrive"
    check: "Policy selection, the effective backend, HTTP handling, sampling, and export connectivity, in that order."
  - unexpected: "Spans arrive as separate traces"
    check: "Context propagation at the service where the trace splits."
  - unexpected: "Spans for internal application operations are missing"
    check: "Add application instrumentation. The proxy policy can't create those spans."
{% endtable %}
