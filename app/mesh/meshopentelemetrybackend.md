---
title: MeshOpenTelemetryBackend
description: A shared OpenTelemetry collector endpoint that MeshMetric, MeshTrace and MeshAccessLog reference instead of each carrying its own copy.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - observability
  - metrics
  - tracing
related_resources:
  - text: MeshMetric policy
    url: /mesh/policies/meshmetric/
  - text: MeshTrace policy
    url: /mesh/policies/meshtrace/
  - text: MeshAccessLog policy
    url: /mesh/policies/meshaccesslog/
  - text: Migrate policies to {{site.mesh_product_name}} 3
    url: /mesh/migrate-policies-to-3/
---

`MeshOpenTelemetryBackend` holds an OpenTelemetry collector endpoint that observability policies
point at through a `backendRef`. Without it, every
[MeshMetric](/mesh/policies/meshmetric/), [MeshTrace](/mesh/policies/meshtrace/) and
[MeshAccessLog](/mesh/policies/meshaccesslog/) carries its own copy of the collector address.
With it the address lives in one place.

It is not a policy. There is no `targetRef`: the resource describes a collector, and the
policies referencing it decide which proxies send to it. On Kubernetes it is accepted only in
the system namespace.

## Define a collector and reference it

{% policy_yaml %}
```yaml
type: MeshOpenTelemetryBackend
mesh: default
name: otel-collector
labels:
  kuma.io/display-name: otel-collector
spec:
  endpoint:
    address: otel-collector.observability
    port: 4317
```
{% endpolicy_yaml %}

A policy then references it by labels:

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

A `backendRef` carries `kind` and `labels`, and nothing else. `labels` is required, and an
empty set is rejected. Where several backends match the labels, **the oldest by creation time
wins**, so labels that match more than one backend make the choice depend on creation order.

## Fields

Every field is optional. An empty spec is valid, and describes the node-local default: the
control plane defaults the port to 4317 and leaves the address unset, and `kuma-dp` resolves it
at runtime from `HOST_IP`, falling back to `127.0.0.1`.

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: "`endpoint.address`"
    value: "The collector's hostname or IP. Anything that is neither is rejected with `address has to be a valid IP or hostname`. Unset, `kuma-dp` resolves it at runtime."
  - field: "`endpoint.port`"
    value: "The collector's port, 1 to 65535. Defaults to 4317."
  - field: "`endpoint.path`"
    value: "A base path prefix for HTTP endpoints, to which the control plane appends `/v1/traces`, `/v1/metrics` or `/v1/logs`. Accepted only with `protocol: http`."
  - field: "`protocol`"
    value: "`grpc`, the default, or `http`."
  - field: "`env`"
    value: "How OpenTelemetry environment variables on the sidecar combine with the fields above. See [Environment variables](#environment-variables)."
{% endtable %}

`endpoint.path` has three constraints, each rejected on apply: it must not be set when the
protocol is `grpc` (`must not be set when protocol is grpc`), it must begin with a slash
(`must start with /`), and it must carry no query or fragment
(`must not contain query or fragment`).

## Environment variables

`kuma-dp` reads `OTEL_EXPORTER_OTLP_*` variables at startup and merges them with this
resource's fields. Values that carry secrets — headers, client keys, certificates — stay local
to `kuma-dp`: at bootstrap it reports only which variable *keys* are present to the control
plane, never their values.

The shared variables are `OTEL_EXPORTER_OTLP_ENDPOINT`, `_PROTOCOL`, `_HEADERS`, `_INSECURE`,
`_TIMEOUT`, `_COMPRESSION`, `_CERTIFICATE`, `_CLIENT_KEY` and `_CLIENT_CERTIFICATE`. Each also
has a per-signal form — `OTEL_EXPORTER_OTLP_TRACES_*`, `_METRICS_*` and `_LOGS_*` — which
overrides the shared value for that signal.

For each field, the first available source wins. By default that order is:

1. The per-signal environment variable, when `allowSignalOverrides` is true
2. The shared environment variable
3. The field on this resource
4. The built-in default

`spec.env` changes that:

{% table %}
columns:
  - title: Field
    key: field
  - title: Values
    key: values
rows:
  - field: "`mode`"
    values: "`Optional`, the default, uses environment variables when present and tolerates their absence. `Disabled` skips them entirely, leaving only this resource's fields and the built-in defaults. `Required` blocks the signal when the variables do not supply the missing fields, even where an explicit value or default could have filled them."
  - field: "`precedence`"
    values: "`EnvFirst`, the default, lets environment variables win and this resource's fields fill the gaps. `ExplicitFirst` reverses that. Built-in defaults are the last fallback either way."
  - field: "`allowSignalOverrides`"
    values: "`true`, the default, lets per-signal variables diverge from the shared ones. `false` ignores the per-signal variables and applies the shared values to every signal."
{% endtable %}

`Required` is for making missing input fail loudly: the signal blocks, `RequiredEnvMissing`
appears in the status, and the absence of exported data becomes something to alert on.

Environment variable values are read only when `kuma-dp` restarts and re-bootstraps, and the
status picks them up at the same time.

### One backend per signal per proxy

OpenTelemetry environment variables are process-global, so when a proxy resolves more than one
backend for the same signal and both allow environment input, there is no way to tell which
backend the values belong to. The control plane marks that signal `ambiguous` and drops the
environment input for it; this resource's explicit fields still apply.

Plan one backend per signal per proxy, or set `mode: Disabled` on the backends that should never
take environment input.

## Per-zone collectors

Where zones run their own collectors, create one backend per zone and scope each policy to the
matching zone with labels.

Where every zone can use the same collector service name, one backend is enough and DNS resolves
to the local collector in each zone.

## Checking that a signal is exporting

The control plane writes per-backend, per-signal status to each proxy's `DataplaneInsight` under
`status.openTelemetry`:

```sh
kubectl get dataplaneinsight $DATAPLANE_NAME -o yaml
```

{% table %}
columns:
  - title: Field
    key: field
  - title: Meaning
    key: meaning
rows:
  - field: "`enabled`"
    meaning: "Whether any policy targets this signal on this backend. `false` means nothing asked for it, which is different from `state: missing`."
  - field: "`state`"
    meaning: "`ready`, `blocked`, `missing` or `ambiguous`."
  - field: "`envAllowed`"
    meaning: "Whether `env.mode` permits environment input for this backend."
  - field: "`envInputPresent`"
    meaning: "Whether `kuma-dp` reported any matching variable keys at bootstrap."
  - field: "`overrideKinds`"
    meaning: "The OTLP fields where a per-signal variable overrode the shared one."
  - field: "`missingFields`"
    meaning: "Fields the merge could not produce."
  - field: "`blockedReasons`"
    meaning: "`EnvDisabledByPolicy`, `RequiredEnvMissing`, `SignalOverridesDisallowed` or `MultipleBackendsForSignal`."
{% endtable %}

A signal reaches `ready` once the merge produces an `endpoint`; the remaining fields fall back to
OpenTelemetry SDK defaults.

The blocked reasons divide in two. `EnvDisabledByPolicy` and `SignalOverridesDisallowed` are
soft: the control plane ignored some environment input and export still works.
`RequiredEnvMissing` and `MultipleBackendsForSignal` are hard — they stop export and move the
state out of `ready`.

A `state: missing` means a policy asked for the signal and the merge produced no endpoint. A
`backendRef` whose labels match no backend is the common cause, followed by an empty spec on a
proxy where `HOST_IP` resolves to no collector.

## Status on the backend itself

`status.conditions` carries `ReferencedByPolicies`, with a reason of `Referenced` or
`NotReferenced`. A backend nothing references is not an error, but on a mesh where exporting is
expected it usually means a `backendRef`'s labels do not match this resource's labels.
