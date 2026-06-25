---
title: Mesh Trace
name: MeshTraces
products:
    - mesh
description: 'Publish traces to a third party tracing solution.'
content_type: plugin
type: policy
icon: meshtrace.png

related_resources:
  - text: Deploy an OpenTelemetry collector
    url: /mesh/deploy-an-opentelemetry-collector/
  - text: MeshOpenTelemetryBackend
    url: /mesh/meshopentelemetrybackend/
---

{:.warning}
> This policy uses new policy matching algorithm.
> Do **not** combine with the deprecated TrafficTrace policy.

This policy enables publishing traces to a third party tracing solution.

Tracing is supported over HTTP, HTTP2, and gRPC protocols.
You must explicitly specify the protocol for each service and data plane proxy you want to enable tracing for.

{{site.mesh_product_name}} currently supports the following trace exposition formats:

- `Zipkin` traces in this format can be sent to [many different tracing backends](https://github.com/openzipkin/openzipkin.github.io/issues/65)
- `Datadog`

{:.warning}
> Services still need to be instrumented to preserve the trace chain across requests made across different services.
>
> You can instrument with a language library of your choice ([for Zipkin](https://zipkin.io/pages/tracers_instrumentation) and [for Datadog](https://docs.datadoghq.com/tracing/setup_overview/setup/java/?tab=containers)).
> For HTTP you can also manually forward the following headers:
>
> - `x-request-id`
> - `x-b3-traceid`
> - `x-b3-parentspanid`
> - `x-b3-spanid`
> - `x-b3-sampled`
> - `x-b3-flags`

## TargetRef support matrix

{% navtabs "support-matrix" %}
{% navtab "Sidecar" %}
<!-- vale off -->
{% table %}
columns:
  - title: "`targetRef`"
    key: targetref
  - title: Allowed kinds
    key: allowed_kinds
rows:
  - targetref: "`targetRef.kind`"
    allowed_kinds: "`Mesh`, `Dataplane`, `MeshSubset(deprecated)`"
{% endtable %}
<!-- vale on -->
{% endnavtab %}

{% navtab "Built-in Gateway" %}
<!-- vale off -->
{% table %}
columns:
  - title: "`targetRef`"
    key: targetref
  - title: Allowed kinds
    key: allowed_kinds
rows:
  - targetref: "`targetRef.kind`"
    allowed_kinds: "`Mesh`, `MeshGateway`"
{% endtable %}
<!-- vale on -->
{% endnavtab %}

{% navtab "Delegated Gateway" %}
<!-- vale off -->
{% table %}
columns:
  - title: "`targetRef`"
    key: targetref
  - title: Allowed kinds
    key: allowed_kinds
rows:
  - targetref: "`targetRef.kind`"
    allowed_kinds: "`Mesh`, `MeshSubset`"
{% endtable %}
<!-- vale on -->
{% endnavtab %}

{% endnavtabs %}



## Configuration

### Sampling

{:.info}
> Most of the time setting only `overall` is sufficient. `random` and `client` are for advanced use cases.

You can configure sampling settings equivalent to Envoy's:

- [overall](https://www.envoyproxy.io/docs/envoy/v1.22.5/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto.html?highlight=overall_sampling#extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-tracing)
- [random](https://www.envoyproxy.io/docs/envoy/v1.22.5/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto.html?highlight=random_sampling#extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-tracing)
- [client](https://www.envoyproxy.io/docs/envoy/v1.22.5/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto.html?highlight=client_sampling#extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-tracing)

The value is always a percentage and is between 0 and 100.

Example:

```yaml
sampling:
  overall: 80
  random: 60
  client: 40
```

### Tags

You can add tags to trace metadata by directly supplying the value (`literal`) or by taking it from a header (`header`).

Example:

```yaml
tags:
  - name: team
    literal: core
  - name: env
    header:
      name: x-env
      default: prod
  - name: version
    header:
      name: x-version
```

If a value is missing for `header`, `default` is used.
If `default` isn't provided, then the tag won't be added.

### Backends

#### Datadog

You can configure a Datadog backend with a `url` and `splitService`.

Example:
```yaml
datadog:
  url: http://my-agent:8080 # Required. The url to reach a running datadog agent
  splitService: true # Default to false. If true, it will split inbound and outbound requests in different services in Datadog
```

The `splitService` property determines if Datadog service names should be split based on traffic direction and destination.
For example, with `splitService: true` and a `backend` service that communicates with a couple of databases,
you would get service names like `backend_INBOUND`, `backend_OUTBOUND_db1`, and `backend_OUTBOUND_db2` in Datadog.

#### Zipkin

In most cases the only field you'll want to set is `url`.

Example:
```yaml
zipkin:
  url: http://jaeger-collector:9411/api/v2/spans # Required. The url to a zipkin collector to send traces to 
  traceId128bit: false # Default to false which will expose a 64bits traceId. If true, the id of the trace is 128bits
  apiVersion: httpJson # Default to httpJson. It can be httpJson, httpProto and is the version of the zipkin API
  sharedSpanContext: false # Default to true. If true, the inbound and outbound traffic will share the same span. 
```

#### OpenTelemetry

The only field you can set is `endpoint`.

Example:
```yaml
openTelemetry:
  endpoint: otel-collector:4317 # Required. Address of OpenTelemetry collector
```
