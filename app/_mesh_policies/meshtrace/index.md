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

`MeshTrace` makes a proxy emit a span for each request it handles and send it to a tracing
backend. Spans from the proxies along a request's path share a trace ID, which is what lets a
backend reconstruct the whole path from the individual hops.

A proxy cannot tell which outbound request belongs to which inbound one, so the application has
to carry the trace headers across: a trace breaks at any service that receives them and does not
pass them on. Either instrument the application with a tracing library, or forward
`x-request-id`, `x-b3-traceid`, `x-b3-parentspanid`, `x-b3-spanid`, `x-b3-sampled` and
`x-b3-flags` by hand.

## Send traces to Zipkin

This policy applies to every proxy in the mesh and exports to a Zipkin-compatible collector:

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

## Where this policy applies

`spec.targetRef` selects the proxies that emit spans, and accepts `Mesh` or `Dataplane` with
`labels`. Everything else sits under `default`: there is no `to` or `rules`, because a span
describes one hop and is emitted by the proxy handling it.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## Backends

`default.backends` takes **at most one** entry. Envoy accepts a single tracing provider per
listener, so two would have no meaning; more than one is rejected with
`must have zero or one backend defined`.

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

An OpenTelemetry backend is named indirectly, through a `MeshOpenTelemetryBackend` resource:

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

## Custom tags

`default.tags` adds tags to every span, from a request header or a fixed string. Each entry
takes a `name` and exactly one of `header` or `literal`; both together is rejected with
`tag must have only one type defined: header, literal`.

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
