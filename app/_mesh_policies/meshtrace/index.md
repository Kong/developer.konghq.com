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
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshtrace"
- text: MeshAccessLog policy
  url: "/mesh/policies/meshaccesslog/"
- text: MeshMetric policy
  url: "/mesh/policies/meshmetric/"
---

`MeshTrace` makes a proxy emit spans for sampled HTTP requests and send them to a tracing
backend. A span records one part of a request's journey, including timing and outcome.
When services propagate trace context, the backend can join spans from successive hops
into an end-to-end trace.

A proxy cannot tell which outbound request belongs to which inbound one, so the application has
to carry trace context across its calls. Otherwise, you can receive spans for every service
but see separate traces instead of one connected journey. Use application instrumentation
with a propagation format compatible with the selected tracing provider. Proxy tracing
does not create spans for database queries or other work inside the application.

With no `MeshTrace` applying to a proxy, the proxy does not emit tracing spans.

## Send traces to Zipkin

This policy applies to every proxy in the mesh and exports to a Zipkin-compatible collector.
The collector must already be running, reachable from the proxies, and accepting Zipkin v2
spans on the URL shown. Replace that URL with your collector's ingestion endpoint, not its
web interface:

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

`targetRef.kind: Mesh` selects every proxy in the mesh. `backends` chooses the tracing provider,
and `zipkin.url` is where each proxy sends its spans. Because the example omits `sampling`, every
eligible request is sampled by default.

Start with a limited test workload before applying 100% sampling across a busy mesh.
Tracing adds export traffic and backend storage, and spans can contain URLs and other
request metadata. Select a production sampling rate after checking the resulting volume.

## Where this policy applies

`spec.targetRef` selects the proxies that emit spans, and accepts `Mesh` or `Dataplane` with
`labels`. Everything else sits under `default`: there is no `to` or `rules`, because a span
describes one hop and is emitted by the proxy handling it.

Tracing applies where the proxy parses HTTP, including HTTP/2 and gRPC. It cannot create
request spans from plain TCP or application-encrypted traffic that it forwards without
decrypting. Check the declared inbound and service-port protocols if traffic is visible in
metrics but not in traces.

The selected proxy can emit inbound and outbound spans. On inbound and zone-proxy listeners,
`targetRef.sectionName` selects the listener's `name` from the Dataplane resource; an unnamed
inbound uses its port as a string. This is not a destination selector for outbound tracing.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## Keep one trace across application calls

For a request from `frontend` through `backend` to another service, backend must extract
the incoming context and inject it into the outgoing request. Use the tracing library's
propagator so that span relationships and sampling decisions remain consistent.

| Provider | Context to propagate |
| --- | --- |
| Zipkin | B3 context: the `b3` header or the `x-b3-traceid`, `x-b3-spanid`, `x-b3-parentspanid`, `x-b3-sampled`, and `x-b3-flags` headers used by your instrumentation. |
| OpenTelemetry | W3C context in `traceparent` and, when present, `tracestate`. |
| Datadog | Datadog trace context, including `x-datadog-trace-id`, `x-datadog-parent-id`, and `x-datadog-sampling-priority`. |

Also preserve `x-request-id` for request correlation. It is not a replacement for the
provider's trace context. Do not assume forwarding B3 headers is sufficient for every
backend. See [Envoy trace propagation](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing#trace-context-propagation)
and [W3C tracing headers](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#traceparent).

## Backends

`default.backends` takes **at most one** entry. Envoy accepts a single tracing provider per
listener, so two would have no meaning; more than one is rejected with
`must have zero or one backend defined`.

To send the same spans to multiple storage systems, export to one collector and configure
that collector to forward to the required systems. Do not add a second `MeshTrace` backend.

The field itself is required. Omitting it is rejected with `backends (): must be defined`,
while an empty list is accepted and covered under
[Turn tracing off for part of the mesh](#turn-tracing-off-for-part-of-the-mesh).

{% table %}
columns:
  - title: "`type`"
    key: type
  - title: Configuration
    key: conf
rows:
  - type: "`Zipkin`"
    conf: "`url` of the collector, which must be a valid URL. `apiVersion` is `httpJson`, the default, or `httpProto`. `traceId128bit` emits 128-bit trace IDs, off by default. `sharedSpanContext` makes a client and server span share one context, on by default."
  - type: "`Datadog`"
    conf: "`url` of the agent. `splitService` splits the reported service name by direction and destination, off by default."
  - type: "`OpenTelemetry`"
    conf: "`backendRef`, naming a `MeshOpenTelemetryBackend` by labels."
{% endtable %}

A Datadog `url` is checked more narrowly than the others: the scheme must be `http`, a port is
required, and a path, query, fragment, user or opaque part is rejected. `https://agent:8126`
fails with `scheme must be http`, and `http://agent:8126/traces` with `path must not be
defined`.

An OpenTelemetry backend is named indirectly, through a [MeshOpenTelemetryBackend](/mesh/meshopentelemetrybackend/) resource:

Create that resource with the collector endpoint, transport, and credentials first. Its
labels must match `backendRef.labels`; a Kubernetes Service called `otel-collector` is not
enough by itself. Enable a traces receiver and export pipeline in the collector.

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

Spans for an OpenTelemetry backend leave through `kuma-dp`: Envoy exports to a Unix socket and
`kuma-dp` forwards to the collector. Where several `MeshOpenTelemetryBackend` resources match
the labels, the oldest wins.

Use labels that identify one intended backend. If the reference does not resolve, the
proxy does not receive a usable OpenTelemetry tracing provider; it does not fall back to
Zipkin or another collector. Inspect reference resolution before debugging network export.

## Sampling

`default.sampling` decides how many requests produce a trace. All three fields take a
percentage, as an integer or a decimal in quotes, between 0 and 100, and default to 100.

{% table %}
columns:
  - title: Field
    key: field
  - title: What it limits
    key: what
rows:
  - field: "`client`"
    what: "Requests arriving with an `x-client-trace-id` header, which the client uses to ask for a trace."
  - field: "`random`"
    what: "Requests picked at random, where the client neither asked for a trace nor forced one."
  - field: "`overall`"
    what: "The ceiling on everything above. A `client` of 100 with an `overall` of 1 still traces only 1% of the requests that asked for it."
{% endtable %}

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

A value outside the range is rejected with `must be between 0 and 100`.

Here, `random: "0.1"` means 0.1%, not 10%. It reduces ordinary randomly selected traffic,
while requests that explicitly ask for tracing can still pass the `client: 100` setting.
Set an appropriate `overall` ceiling if those requests must also be limited. Sampling is
a selection decision, not an exact quota over every small batch of requests; propagated
context and provider sampling decisions also affect the traces you observe.

## Custom tags

`default.tags` adds tags to every span, from a request header or a fixed string. Each entry
takes a `name` and exactly one of `header` or `literal`; both together is rejected with
`tag must have only one type defined: header, literal`.

Place this fragment under `default`, alongside the required `backends` list:

```yaml
tags:
  - name: team
    literal: core
  - name: env
    header:
      name: x-env
      default: unknown
```

A `header` tag without a `default` is left off the span when the header is absent.

Use low-cardinality values such as team or environment. Do not copy authorization headers,
session cookies, or other secrets into tags: exported tags are stored outside the request
path and can be searchable by other users of the tracing backend.

The proxy also supplies `kuma.mesh`, `kuma.zone`, and, when available, `kuma.workload` tags.
Defining a custom tag with one of those names replaces the automatically supplied value;
avoid those names unless that override is intentional.

## When policies overlap

A more specific policy overrides conflicting fields from a broader policy. Object fields
can inherit omitted values, but `backends` and `tags` lists replace the broader lists.
Every policy must still provide `backends`, even when changing only sampling or tags.

For example, a workload-specific policy with the same backend and `sampling.random: 1`
can reduce random sampling while inheriting the broader `sampling.overall`. Supplying one
custom tag in that policy replaces the entire broader custom-tag list; repeat every tag
you need to retain.

## Turn tracing off for part of the mesh

An empty `backends` list is accepted, and produces no tracing configuration at all. That is how
a subset of proxies is exempted from a mesh-wide policy, since a more specific policy overrides
the broader one:

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

`sampling` and `tags` alongside an empty `backends` are inert, since the proxy writes no tracing
configuration for those listeners to carry them.

This stops spans produced by those proxies only. It does not disable instrumentation in
the application or spans emitted by other proxies along the request path. Removing this
exception restores the broader policy; it does not leave tracing disabled.

## Validate trace export

1. Verify ordinary connectivity, HTTP protocol handling, and collector readiness first.
   Temporarily use 100% sampling on the test workloads to separate export failures from
   sampling decisions.
1. Send a request through at least two meshed services and record its trace ID from the
   propagated context or instrumentation. A request ID can help correlate logs, but is
   not necessarily the trace ID displayed by the backend.
1. Find the trace in the configured backend and confirm that it contains a span for each proxy
   hop.
1. If the trace stops at one service, confirm that the application forwards the configured
   trace headers to its outbound request.
1. For sampling below 100%, send enough requests to observe the rate rather than relying on one
   request.
1. For OpenTelemetry, confirm that the referenced `MeshOpenTelemetryBackend` is resolved and
   inspect `kuma-dp` exporter errors and the collector's received spans. A reachable collector
   alone does not prove that its export pipeline stored the trace.
1. Restore the intended sampling rate after the test.

If no spans arrive, check policy selection, the effective backend, HTTP handling, sampling,
and export connectivity in that order. If spans arrive as disconnected traces, check context
propagation at the service where the trace splits. If only internal application operations
are missing, add application instrumentation rather than changing the proxy policy.
