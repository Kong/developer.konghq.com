---
title: Mesh Access Log
name: MeshAccessLogs
products:
- mesh
description: Set up access logs on every data plane proxy in a mesh.
content_type: plugin
icon: meshaccesslog.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshaccesslog"
---

`MeshAccessLog` makes data plane proxies write a record for every request or connection they
handle, and ships those records somewhere you can read them: the proxy's own output, a TCP
server, or an OpenTelemetry collector.

Use it to trace a failing request across services, audit which client called which service,
or feed traffic data into an existing log pipeline.

With the default format, one HTTP request produces one line like this:

```text
[2026-09-10T12:04:51.190Z] default "GET /api/orders HTTP/1.1" 200 - 0 1274 12 11 "10.42.0.9" "curl/8.4.0" "-" "b7c1e0f4-9a1d-4c86-9a02-1f0e6d3c55aa" "orders.kong-mesh-demo.svc:8080" "unknown" "orders_kong-mesh-demo_svc_8080" "10.42.0.9" "10.42.1.4:8080"
```

## Log all incoming traffic

This policy logs every request arriving at every proxy in the `default` mesh, writing each
record to the sidecar's standard output:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshAccessLog
mesh: default
name: all-incoming-traffic
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endpolicy_yaml %}

What each field does:

* `targetRef` selects **which proxies** log. `kind: Mesh` means all of them.
* `rules` describes **what to do with inbound traffic** at those proxies. One entry with no
  filter means "log everything", and `backends` says where the records go.

### Check that it works

Send a request through the mesh, then read the sidecar's output:

```sh
kubectl logs deploy/orders -n kong-mesh-demo -c kuma-sidecar --tail 5
```

Each request through the `orders` proxy adds a line in the format shown above. If you see no
lines, confirm the policy landed in the same mesh as the workload, and that the workload is
actually receiving traffic.

## Choose where the logs go

Every `backends` entry is one destination. A single rule can list several, and each record is
written to all of them.

### File

Writes records to a path inside the sidecar container. Use `/dev/stdout` to pick them up with
`kubectl logs`, which is the quickest option while you're getting started:

```yaml
backends:
  - type: File
    file:
      path: /dev/stdout
```

### TCP

Streams records to a log server over a plain TCP connection:

```yaml
backends:
  - type: Tcp
    tcp:
      address: 127.0.0.1:5000
```

### OpenTelemetry

Sends records to an OpenTelemetry collector. Point `backendRef` at a [MeshOpenTelemetryBackend](/mesh/meshopentelemetrybackend/)
resource, which holds the collector endpoint so that several policies can share it:

```yaml
backends:
  - type: OpenTelemetry
    openTelemetry:
      backendRef:
        kind: MeshOpenTelemetryBackend
        labels:
          kuma.io/display-name: otel-collector
```

You can add [`attributes`](https://opentelemetry.io/docs/specs/otel/logs/data-model/#field-attributes),
which carry extra fields alongside the record, and a
[`body`](https://opentelemetry.io/docs/specs/otel/logs/data-model/#field-body), which can be a
string or structured data:

```yaml
backends:
  - type: OpenTelemetry
    openTelemetry:
      backendRef:
        kind: MeshOpenTelemetryBackend
        labels:
          kuma.io/display-name: otel-collector
      body:
        kvlistValue:
          values:
            - key: "mesh"
              value:
                stringValue: "%KUMA_MESH%"
      attributes:
        - key: "start_time"
          value: "%START_TIME%"
```

Attribute values and the body accept the same placeholders as a log format. Attribute keys must
be static names. When more than one `MeshOpenTelemetryBackend` matches the labels, the oldest
resource wins.

## Choose what each record contains

Add a `format` to a backend to override the default record shape. Formats are built from
_command operators_ such as `%START_TIME%`, which the proxy replaces with a value per request.

### Plain text

`Plain` produces one line per record from a template string:

```yaml
backends:
  - type: File
    file:
      path: /dev/stdout
      format:
        type: Plain
        plain: '[%START_TIME%] %KUMA_SOURCE_SERVICE% => %KUMA_DESTINATION_SERVICE% %DURATION%ms'
```

### JSON

`Json` produces one JSON object per record from a list of key-value pairs. Prefer it when
something downstream parses the logs, because it can query on the keys:

```yaml
backends:
  - type: File
    file:
      path: /dev/stdout
      format:
        type: Json
        json:
          - key: "start_time"
            value: "%START_TIME%"
          - key: "bytes_received"
            value: "%BYTES_RECEIVED%"
```

That produces:

```json
{
  "start_time": "2026-09-10T12:04:51.190Z",
  "bytes_received": "154"
}
```

### Command operators

Every [command operator defined by Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#command-operators)
works here. {{site.mesh_product_name}} adds these, all valid for both HTTP and TCP traffic:

<!-- vale off -->
{% table %}
columns:
  - title: Command Operator
    key: command_operator
  - title: Description
    key: description
rows:
  - command_operator: "`%KUMA_MESH%`"
    description: Name of the mesh in which traffic is flowing.
  - command_operator: "`%KUMA_ZONE%`"
    description: Name of the zone the logging proxy runs in.
  - command_operator: "`%KUMA_WORKLOAD%`"
    description: "Kuma Resource Identifier (KRI) of the workload the logging proxy belongs to."
  - command_operator: "`%KUMA_SOURCE_SERVICE%`"
    description: "Name of the `service` that is the `source` of traffic."
  - command_operator: "`%KUMA_DESTINATION_SERVICE%`"
    description: "Name of the `service` that is the `destination` of traffic."
  - command_operator: "`%KUMA_SOURCE_ADDRESS%`"
    description: "Address of the `Dataplane` that is the `source` of traffic, including the port."
  - command_operator: "`%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%`"
    description: "Address of the `Dataplane` that is the `source` of traffic."
  - command_operator: "`%KUMA_TRAFFIC_DIRECTION%`"
    description: "Direction of the traffic, `INBOUND`, `OUTBOUND`, or `UNSPECIFIED`."
{% endtable %}
<!-- vale on -->

{:.info}
> On inbound records, the client isn't identified at the point the record is written, so
> `%KUMA_SOURCE_SERVICE%` renders as `unknown` — that's the `"unknown"` field in the sample
> line above. To tell clients apart, split them into separate rules with a
> [`spiffeID` match](#match-on-client-identity-or-sni).

An operator that only applies to HTTP traffic, such as `%REQ(X?Y):Z%`, becomes `-` in a plain
record and `null` in a JSON record when the traffic is TCP. Set `format.omitEmptyValues: true`
to render an empty string instead, or to drop the key from JSON entirely.

{% details %}
summary: "Default format strings"
content: |
  TCP traffic:

  ```text
  [%START_TIME%] %RESPONSE_FLAGS% %KUMA_MESH% %KUMA_SOURCE_ADDRESS_WITHOUT_PORT%(%KUMA_SOURCE_SERVICE%)->%UPSTREAM_HOST%(%KUMA_DESTINATION_SERVICE%) took %DURATION%ms, sent %BYTES_SENT% bytes, received: %BYTES_RECEIVED% bytes
  ```

  HTTP traffic:

  ```text
  [%START_TIME%] %KUMA_MESH% "%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%" %RESPONSE_CODE% %RESPONSE_FLAGS% %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% "%REQ(X-FORWARDED-FOR)%" "%REQ(USER-AGENT)%" "%REQ(X-B3-TRACEID?X-DATADOG-TRACEID)%" "%REQ(X-REQUEST-ID)%" "%REQ(:AUTHORITY)%" "%KUMA_SOURCE_SERVICE%" "%KUMA_DESTINATION_SERVICE%" "%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%" "%UPSTREAM_HOST%"
  ```
{% enddetails %}

## Log a narrower slice of traffic

The starter policy logs everything, which gets expensive and noisy in production. Narrow it in
two ways: pick which proxies log, with `targetRef`, and pick which of their traffic logs, with
`rules` or `to`.

`targetRef` accepts `kind: Mesh` for every proxy in the mesh, or `kind: Dataplane` with `labels`
to select a subset.

Traffic direction is where `rules` and `to` differ:

<!-- vale off -->
{% table %}
columns:
  - title: Field
    key: field
  - title: Direction
    key: direction
  - title: Selects on
    key: selects
rows:
  - field: "`rules`"
    direction: Inbound — traffic arriving at the selected proxies
    selects: Client identity or SNI, using `matches`
  - field: "`to`"
    direction: Outbound — traffic the selected proxies send
    selects: The destination, using `to[].targetRef`
{% endtable %}
<!-- vale on -->

{:.warning}
> `rules` and `to` are mutually exclusive within one policy. Setting both is rejected with
> `fields 'to' and 'from' must be empty when 'rules' is defined`. To log both directions,
> create two policies.

### Match on client identity or SNI

Add `matches` to a rule to log only some inbound traffic. A match selects on the client's
SPIFFE ID (with `Exact` or `Prefix`) or on the SNI of the TLS connection (with `Exact`).

By default, {{site.mesh_product_name}} issues SPIFFE IDs shaped like
`spiffe://{mesh}.{zone}.mesh.local/ns/{namespace}/sa/{service-account}` on Kubernetes, and
`spiffe://{mesh}.{zone}.mesh.local/workload/{workload}` on Universal. Both the trust domain and
the path are templates on the `MeshIdentity` resource, so check what your mesh actually issues
before writing a match.

This policy logs only the requests that reach `orders` from workloads in the `kong-mesh-demo`
namespace of zone `zone-1`:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshAccessLog
mesh: default
name: incoming-from-kong-mesh-demo
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: orders
  rules:
    - matches:
        - spiffeID:
            type: Prefix
            value: spiffe://default.zone-1.mesh.local/ns/kong-mesh-demo/
      default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endpolicy_yaml %}

{:.info}
> Rules fire independently. A connection matching several rules is logged to every matching
> rule's backends, so one request can produce more than one record.

### Log outbound traffic

Use `to` to log what the selected proxies send, with each entry naming a destination. This
policy logs everything the `orders` proxies send to `payments`:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshAccessLog
mesh: default
name: orders-to-payments
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: orders
  to:
    - targetRef:
        kind: MeshService
        labels:
          kuma.io/display-name: payments
      default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endpolicy_yaml %}

`to[].targetRef` accepts `Mesh` to cover every destination, or `MeshService`,
`MeshExternalService`, `MeshMultiZoneService`, and `MeshHTTPRoute` to name one. See the
[configuration reference](/mesh/policies/meshaccesslog/reference/) for the full field list.

## Where this policy applies

`spec.targetRef` selects which proxies log: `Mesh`, or `Dataplane` with `labels`.
`spec.to[].targetRef` selects a destination to log requests to, and accepts `Mesh`,
`MeshService`, `MeshExternalService`, `MeshMultiZoneService` or `MeshHTTPRoute`.
`spec.rules[].matches` selects which clients to log requests from.

For the selectors a policy can carry and why inbound matches an identity rather than a name,
see [How policies select traffic](/mesh/policy-targeting/).
