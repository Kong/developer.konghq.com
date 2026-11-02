---
title: Mesh Access Log
name: MeshAccessLogs
products:
- mesh
description: Set up access logs on every data plane proxy in a mesh.
content_type: plugin
icon: meshaccesslog.png
related_resources:
- text: Policy targeting
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshaccesslog"
---

The `MeshAccessLog` policy records traffic handled by selected proxies and sends the records
to a file, a TCP log server, or an OpenTelemetry collector. You can record traffic arriving at
a proxy, traffic it sends, or both, using separate policies.

Use this policy to trace a failing request across services, audit which client called which
service, or feed traffic data into an existing log pipeline.

Proxies that no `MeshAccessLog` selects produce no access logs. HTTP-aware listeners record
requests and TCP listeners record connections, so application requests inside a TCP connection
aren't separate log events.

With the default HTTP format, a record looks like this:

```text
[2026-09-10T12:04:51.190Z] default "GET /api/orders HTTP/2" 200 - 0 1274 12 11 "10.42.0.9" "curl/8.4.0" "-" "b7c1e0f4-9a1d-4c86-9a02-1f0e6d3c55aa" "orders.kong-mesh-demo.svc.cluster.local" "unknown" "kri_dp_default_zone-1_kong-mesh-demo_orders-6f4c9b7d55-xk2vq_http" "10.42.0.9" "10.42.1.4:8080"
```

## Log all incoming traffic

The following example logs requests arriving at the selected proxies, and writes each record
to the sidecar's standard output:

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

* `targetRef` selects which proxies log. `kind: Mesh` means every proxy in the policy's own
  namespace. If the policy is created in `{{site.mesh_namespace}}`, it applies to the whole
  zone. To log every zone, create the policy on the global control plane. For more
  information, see [Policy scope](/mesh/policy-targeting/#policy-scope).
* `rules` describes what to do with inbound traffic at those proxies. One entry with no
  filter logs everything.
* `backends` sets where the records go.

## Log destinations

Each `backends` entry is one destination. A rule can list several, and each record is written
to all of them. Put the following fragments under `rules[].default` for inbound logging, or
`to[].default` for outbound logging.

### File

The following fragment writes records to `/dev/stdout` inside the sidecar container, where
`kubectl logs` picks them up:

```yaml
backends:
  - type: File
    file:
      path: /dev/stdout
```

### TCP

The following fragment streams records over a plain TCP connection to a log server beside
the logging proxy. If the server runs elsewhere, use its reachable address and port:

```yaml
backends:
  - type: Tcp
    tcp:
      address: 127.0.0.1:5000
```

### OpenTelemetry

To send records to an OpenTelemetry collector, point `backendRef` at a
[MeshOpenTelemetryBackend](/mesh/meshopentelemetrybackend/) resource, which holds the collector
endpoint. Create that resource first, because an unresolved reference doesn't fall back to
stdout. The following fragment selects it by the label `kuma.io/display-name: otel-collector`:

```yaml
backends:
  - type: OpenTelemetry
    openTelemetry:
      backendRef:
        kind: MeshOpenTelemetryBackend
        labels:
          kuma.io/display-name: otel-collector
```

The following fragment also sets
[`attributes`](https://opentelemetry.io/docs/specs/otel/logs/data-model/#field-attributes),
which carry extra fields with the record, and a
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

Attribute values and the body accept the same placeholders as a log format, but attribute
keys must be static names: lowercase letters and digits, separated by single `.` or `_`
characters, starting with a letter (for example, `http.request_id`). Keys can't contain
placeholders or start with the reserved `otel.` prefix, so the control plane rejects keys
such as `request-id`, `Service.Version`, or `%KUMA_ZONE%`. If several `MeshOpenTelemetryBackend` resources match the labels,
the oldest one wins.

## Record format

To override the default record format, set `file.format` or `tcp.format`. OpenTelemetry uses
`body` and `attributes` instead. Formats use command operators such as `%START_TIME%`, which the
proxy replaces with a value for each request.

### Plain text

The following fragment uses `Plain` to write one line per record from a template string:

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

`Json` writes one JSON object per record, which is easier to query when something downstream
parses the logs. The following fragment builds the object from a list of key-value pairs:

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

That fragment produces:

```json
{
  "start_time": "2026-09-10T12:04:51.190Z",
  "bytes_received": "154"
}
```

### Command operators

You can use any of the [command operators supported by Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#command-operators).
{{site.mesh_product_name}} adds the following operators:

<!-- vale off -->
{% table %}
columns:
  - title: Command operator
    key: command
  - title: Description
    key: description
rows:
  - command: "`%KUMA_MESH%`"
    description: Name of the mesh the traffic flows in.
  - command: "`%KUMA_ZONE%`"
    description: Name of the zone the logging proxy runs in.
  - command: "`%KUMA_WORKLOAD%`"
    description: "Kuma Resource Identifier (KRI) of the workload the logging proxy belongs to."
  - command: "`%KUMA_SOURCE_SERVICE%`"
    description: "Name of the `service` that is the `source` of traffic."
  - command: "`%KUMA_DESTINATION_SERVICE%`"
    description: "Name of the `service` that is the `destination` of traffic."
  - command: "`%KUMA_SOURCE_ADDRESS%`"
    description: "Address of the logging proxy's `Dataplane`, with port `0`."
  - command: "`%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%`"
    description: "Address of the logging proxy's `Dataplane`."
  - command: "`%KUMA_TRAFFIC_DIRECTION%`"
    description: "Direction of the traffic: `INBOUND`, `OUTBOUND`, or `UNSPECIFIED`."
{% endtable %}
<!-- vale on -->

On inbound records, `%KUMA_SOURCE_SERVICE%` is `unknown`, even when an mTLS caller has an
identity, and `%KUMA_SOURCE_ADDRESS%` and `%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%` hold the
receiving proxy's own address. To record the caller, add `%DOWNSTREAM_REMOTE_ADDRESS%` or the
peer certificate's SPIFFE URI, `%DOWNSTREAM_PEER_URI_SAN%`, to the format. To restrict which callers are logged, use a
[`spiffeID` match](#match-on-client-identity-or-sni).

On TCP traffic, HTTP-only operators such as `%REQ(X?Y):Z%` become `-` in a plain record and
`null` in a JSON record. To render an empty string instead, or to drop the key from JSON, set
`format.omitEmptyValues: true`.

{{site.mesh_product_name}} uses the following format strings by default:

* TCP traffic:

  ```text
  [%START_TIME%] %RESPONSE_FLAGS% %KUMA_MESH% %KUMA_SOURCE_ADDRESS_WITHOUT_PORT%(%KUMA_SOURCE_SERVICE%)->%UPSTREAM_HOST%(%KUMA_DESTINATION_SERVICE%) took %DURATION%ms, sent %BYTES_SENT% bytes, received: %BYTES_RECEIVED% bytes
  ```

* HTTP traffic:

  ```text
  [%START_TIME%] %KUMA_MESH% "%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%" %RESPONSE_CODE% %RESPONSE_FLAGS% %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% "%REQ(X-FORWARDED-FOR)%" "%REQ(USER-AGENT)%" "%REQ(X-B3-TRACEID?X-DATADOG-TRACEID)%" "%REQ(X-REQUEST-ID)%" "%REQ(:AUTHORITY)%" "%KUMA_SOURCE_SERVICE%" "%KUMA_DESTINATION_SERVICE%" "%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%" "%UPSTREAM_HOST%"
  ```

## Log a narrower slice of traffic

Logging everything gets expensive and noisy in production. To narrow it, use the following
fields:

* `targetRef`: selects which proxies log, with `kind: Mesh` or `kind: Dataplane` and `labels`.
* `rules` or `to`: selects which of their traffic is logged, by direction.

`rules` and `to` accept the following directions:

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
    direction: "Inbound: traffic arriving at the selected proxies"
    selects: Client identity or SNI, using `matches`
  - field: "`to`"
    direction: "Outbound: traffic the selected proxies send"
    selects: The destination, using `to[].targetRef`
{% endtable %}
<!-- vale on -->

{:.warning}
> `rules` and `to` are mutually exclusive within one policy. To log both directions, create
> two policies. A request may then appear in the caller's outbound log and the destination's
> inbound log; these are separate observations of the same traffic.

### Match on client identity or SNI

To log only some inbound traffic, add `matches` to `rules`. A match selects on one of the
following:

* The client's SPIFFE ID, with `Exact` or `Prefix`. A plaintext caller has no certificate
  identity, so it can't match.
* The SNI of the TLS connection, with `Exact`. SNI is the name requested in the TLS handshake,
  not the caller.

By default, {{site.mesh_product_name}} issues SPIFFE IDs in the following formats:

* `spiffe://{mesh}.{zone}.mesh.local/ns/{namespace}/sa/{service-account}` on Kubernetes
* `spiffe://{mesh}.{zone}.mesh.local/workload/{workload}` on Universal

Read the domain from the caller's certificate, or from its issuer's generated
`MeshTrust.spec.trustDomain`, and use it after `spiffe://` in
`rules[].matches[].spiffeID.value`. For a custom path template, check
`MeshIdentity.spec.spiffeID.path`. For example, a domain of `payments.eu.mesh.local` and the
default Kubernetes path produce the namespace prefix
`spiffe://payments.eu.mesh.local/ns/kong-mesh-demo/sa`.

The value must be a valid SPIFFE ID, so it can't end in `/`. `Prefix` is a plain string
comparison, so a prefix ending at `/ns/kong-mesh-demo` also matches `kong-mesh-demo-test`.
To match only that namespace, end the prefix at `/ns/kong-mesh-demo/sa`.

The following example logs only the requests that reach `orders` from workloads in the
`kong-mesh-demo` namespace of zone `zone-1`:

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
            value: spiffe://default.zone-1.mesh.local/ns/kong-mesh-demo/sa
      default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endpolicy_yaml %}

Rules apply independently, so a connection that matches several rules is logged to each
rule's backends. For example, if a catch-all rule writes to stdout and a namespace rule
writes to a collector, requests from that namespace are logged to both.

### Log outbound traffic

To log what the selected proxies send, use `to`, with each entry naming a destination. The
following example logs everything the `orders` proxies send to `payments`:

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

`to[].targetRef` accepts `Mesh` for every destination, or `MeshService`,
`MeshExternalService`, `MeshMultiZoneService`, or `MeshHTTPRoute` to name one. For more
information, see the [configuration reference](/mesh/policies/meshaccesslog/reference/).

## Troubleshoot missing or duplicate records

{% table %}
columns:
  - title: Symptom
    key: symptom
  - title: Check
    key: check
rows:
  - symptom: "No stdout record"
    check: "Confirm the policy selects the proxy you're reading and the traffic direction you tested. Use `/dev/stdout` for the File path."
  - symptom: "TCP traffic has no record yet"
    check: "Close the test connection. The default connection log is written when it ends."
  - symptom: "Logs appear locally but not at the collector"
    check: "Confirm that the backend reference resolves, and that the collector accepts logs at its endpoint."
  - symptom: "An identity-filtered rule produces nothing"
    check: "Compare the peer's issued SPIFFE URI with the matcher and confirm the connection uses mTLS."
  - symptom: "One request produces several records"
    check: "Overlapping inbound rules, multiple backends, and whether both client and destination proxies log the request."
  - symptom: "HTTP fields are empty"
    check: "Confirm the listener treats the service as HTTP. TCP logging can't extract HTTP headers or status codes."
{% endtable %}

When you add headers or query strings to a format, include only the fields you need for
diagnosis. Tokens and personal data in logs inherit the log system's access and retention
settings.
