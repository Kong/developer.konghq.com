---
title: MeshOpenTelemetryBackend
description: Shared OpenTelemetry collector configuration that MeshMetric, MeshTrace, and MeshAccessLog can reference instead of duplicating endpoint settings.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: MeshMetric
    url: /mesh/policies/meshmetric/
  - text: MeshTrace
    url: /mesh/policies/meshtrace/
  - text: MeshAccessLog
    url: /mesh/policies/meshaccesslog/
  - text: Multi-zone deployment
    url: /mesh/mesh-multizone-service-deployment/
  - text: Deploy an OpenTelemetry collector
    url: /mesh/deploy-an-opentelemetry-collector/

min_version:
  mesh: '2.14'

tech_preview: true

tags:
  - observability
  - metrics
  - tracing
  - logging
---

`MeshOpenTelemetryBackend` defines an OpenTelemetry collector endpoint that observability policies reference through a `backendRef`. Without it, every [`MeshMetric`](/mesh/policies/meshmetric/), [`MeshTrace`](/mesh/policies/meshtrace/), and [`MeshAccessLog`](/mesh/policies/meshaccesslog/) policies carry their own copy of the collector address. With it, the address lives in one place and the policies point at it by name.

{:.warning}
> Inline `endpoint` fields on those three policies still work in 2.14 but are deprecated and will be removed in 3.0. New deployments should use `backendRef`.

On Kubernetes, the `MeshOpenTelemetryBackend` resource must be created in the system namespace (`kong-mesh-system`). On Universal, it lives in the global control plane store.

## Migrate from inline endpoint

1. Create one `MeshOpenTelemetryBackend` with OpenTelemetry collector endpoint. For example:
   ```yaml
   apiVersion: kuma.io/v1alpha1
   kind: MeshOpenTelemetryBackend
   metadata:
     name: main-collector
     namespace: kong-mesh-system
     labels:
       kuma.io/mesh: default
   spec:
     endpoint:
       address: otel-collector.observability
       port: 4317
     protocol: grpc
   ```
1. On each policy, replace the inline `endpoint` with the following configuration:
   ```yaml
   backendRef: 
    kind: MeshOpenTelemetryBackend, 
    name: main-collector
   ```

1. Keep signal-specific fields (`refreshInterval`, `attributes`, `body`, `sampling`) on the policy.

If the collector endpoint changes, you'll only need to edit the `MeshOpenTelemetryBackend` and the change will automatically apply to the policies that use it.

## Reference a backend from a policy

Every observability policy that supports OpenTelemetry has a `backendRef` field on its OTel backend block. The reference works the same way as `BackendRef` on `MeshHTTPRoute`: use `name` to reference a resource in the same cluster, use `labels` to reference a resource synced from another cluster.

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: '`backendRef.kind`'
    description: 'Must be `MeshOpenTelemetryBackend`.'
  - field: '`backendRef.name`'
    description: |
      `metadata.name` of the backend. Use this when the `MeshOpenTelemetryBackend` and the policy are in the same zone. 
      
      If `name` doesn't resolve, the policy carries a `BackendRefsResolved: False` status condition with the reason `UnresolvedBackendRefs`.'
  - field: '`backendRef.labels`'
    description: |
      Label selector. Required for cross-zone references because [KDS](/mesh/mesh-multizone-service-deployment/) appends a hash suffix to `metadata.name` on synced resources. 
      
      When the `labels` match more than one backend, the oldest by creation time is used. In this case, the control plane doesn't emit a warning, so check creation timestamps if a policy resolves to an unexpected backend.
{% endtable %}

For cross-zone references, match on `kuma.io/display-name` so the resource resolves regardless of the hashed name added during sync:

```yaml
backendRef:
  kind: MeshOpenTelemetryBackend
  labels:
    kuma.io/display-name: main-collector
```

### Per-zone collectors in multi-zone deployments

When zones run separate collectors, create one backend per zone on the global control plane and scope each policy to the matching zone. Because both the backend and the policy live on the global control plane, the control plane resolves `backendRef.name` before KDS sync, so the hashed name that appears on zones never matters.

If the policy is created on a zone control plane and references a backend synced from the global control plane, use `backendRef.labels` instead, because the synced backend's `metadata.name` carries a hash suffix that doesn't match a plain `name`.

When all zones can share the same collector service name, one backend on the global control plane is enough, and DNS resolves to the local collector in each zone.

## Environment-variable resolution

`kuma-dp` reads `OTEL_EXPORTER_OTLP_*` environment variables locally at startup and merges them with the backend config. Secret-bearing values (headers, client keys, certificates) stay local to `kuma-dp`. During startup, `kuma-dp` reports only which environment variable keys are present to the control plane, never the values.

Here are the variable used:
* Shared: 
  * `OTEL_EXPORTER_OTLP_ENDPOINT`
  * `OTEL_EXPORTER_OTLP_PROTOCOL`
  * `OTEL_EXPORTER_OTLP_HEADERS`
  * `OTEL_EXPORTER_OTLP_INSECURE`
  * `OTEL_EXPORTER_OTLP_TIMEOUT`
  * `OTEL_EXPORTER_OTLP_COMPRESSION`
  * `OTEL_EXPORTER_OTLP_CERTIFICATE`
  * `OTEL_EXPORTER_OTLP_CLIENT_KEY`
  * `OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE`
* Per-signal (override shared per signal): 
  * `OTEL_EXPORTER_OTLP_TRACES_*`
  * `OTEL_EXPORTER_OTLP_LOGS_*`
  * `OTEL_EXPORTER_OTLP_METRICS_*`

For each field, `kuma-dp` resolves the first available source. By default, environment variables take precedence:

1. Signal-specific environment variable (when `allowSignalOverrides: true`)
1. Shared environment variable
1. Explicit field on the backend
1. Built-in default

You can customize this behavior:
* Set [`env.precedence`](#schema--env-precedence) to `ExplicitFirst` to use the explicit backend field first.

* Set [`env.mode`](/#schema--env-mode) to `Disabled` to skip environment variables entirely.

* Set [`env.mode`](/#schema--env-mode) to `Required` to block the signal when input blocks are missing or invalid, even if the explicit configuration or defaults could otherwise fill the gap. Use `Required` when missing input should fail loudly. The signal blocks, `RequiredEnvMissing` appears in `DataplaneInsight`, and you can alert on the absence of exported data.

Environment variable values change only when `kuma-dp` restarts and re-bootstraps. Status updates pick them up at the same time.

### Ambiguity rule

OpenTelemetry environment variables are process-global. If one data plane resolves more than one backend for the same signal and both backends allow environment input, the control plane can't tell which backend the values belong to. The control plane marks the signal `ambiguous` and drops environment input for it. Explicit configuration still applies. Plan one backend per signal per data plane, or set `mode: Disabled` on backends that should never receive environment input.

## Examples

The following examples show how to configure `MeshOpenTelemetryBackend` for different use cases.

### Single collector for all three signals

This is the most common configuration: one backend resource carries the collector address and three policies point at it by name.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOpenTelemetryBackend
metadata:
  name: main-collector
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  endpoint:
    address: otel-collector.observability
    port: 4317
  protocol: grpc
---
apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: all-metrics
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            name: main-collector
          refreshInterval: 30s
---
apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: all-traces
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            name: main-collector
    sampling:
      overall: 80
---
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: all-access-logs
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            name: main-collector
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshOpenTelemetryBackend
name: main-collector
mesh: default
spec:
  endpoint:
    address: otel-collector.observability
    port: 4317
  protocol: grpc
---
type: MeshMetric
name: all-metrics
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            name: main-collector
          refreshInterval: 30s
---
type: MeshTrace
name: all-traces
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            name: main-collector
    sampling:
      overall: 80
---
type: MeshAccessLog
name: all-access-logs
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            name: main-collector
```

{% endnavtab %}
{% endnavtabs %}

### Node-local collector

If the collector runs as a DaemonSet with `hostPort`, an empty backend is enough. `kuma-dp` uses the default `grpc` protocol and resolves `HOST_IP:4317` on Kubernetes (Downward API) and `127.0.0.1:4317` on Universal and VMs.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOpenTelemetryBackend
metadata:
  name: node-collector
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshOpenTelemetryBackend
name: node-collector
mesh: default
```

{% endnavtab %}
{% endnavtabs %}

If the DaemonSet exposes OTLP/HTTP on a different port, override only the fields that change:

```yaml
spec:
  endpoint:
    port: 4318
    path: /otlp
  protocol: http
```

### Reuse OpenTelemetry environment variables from the sidecar

Many setups already inject standard `OTEL_EXPORTER_OTLP_*` environment variables into the sidecar (OpenTelemetry Operator on Kubernetes, systemd unit on Universal, container runtime, wrapper script). An empty backend reuses the default `env` configuration:

```yaml
env:
  mode: Optional
  precedence: EnvFirst
  allowSignalOverrides: true
```

With per-signal variables, traces can target a different collector while logs and metrics share the default. For example, if the sidecar has the following environment variables:

* OTEL_EXPORTER_OTLP_ENDPOINT=https://otel-gateway.observability:4318
* OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
* OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=https://tempo.observability:4318

{{site.mesh_product_name}} will use the specific `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` value for traces, and the default `OTEL_EXPORTER_OTLP_ENDPOINT` value for logs and metrics.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOpenTelemetryBackend
metadata:
  name: from-env
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshOpenTelemetryBackend
name: from-env
mesh: default
```

{% endnavtab %}
{% endnavtabs %}

When environment input must be ignored, set `mode: Disabled`. When the backend is meaningless without environment input (per-tenant headers, mTLS client keys), set `mode: Required`. In this case, the signal stays `missing` until the keys are present.

### Per-zone collector

When each zone runs its own collector, create one backend per zone on the global control plane and scope each policy to the matching zone with `MeshSubset` and the `kuma.io/zone` tag.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOpenTelemetryBackend
metadata:
  name: collector-us-east
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  endpoint:
    address: collector.us-east.internal
    port: 4317
---
apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: metrics-us-east
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/zone: us-east
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            name: collector-us-east
          refreshInterval: 30s
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshOpenTelemetryBackend
name: collector-us-east
mesh: default
spec:
  endpoint:
    address: collector.us-east.internal
    port: 4317
---
type: MeshMetric
name: metrics-us-east
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/zone: us-east
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            name: collector-us-east
          refreshInterval: 30s
```

{% endnavtab %}
{% endnavtabs %}

## Troubleshooting

The control plane writes runtime status per backend and signal to each [`DataplaneInsight`](/mesh/dataplane/) under `status.openTelemetry`. Run the following commands to read it:

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```sh
kubectl get dataplaneinsight $DATAPLANE_NAME -o yaml
```

{% endnavtab %}
{% navtab "Universal" %}

```sh
kumactl inspect dataplane $DATAPLANE_NAME
```

{% endnavtab %}
{% endnavtabs %}

The following fields are available for each signal:

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: '`enabled`'
    description: 'Whether a policy targets this signal on this backend. `false` means no policy asked for it, distinct from `state: missing` (asked for but unresolved).'
  - field: '`state`'
    description: |
      The state of the signal. The value can be:
      * `ready`
      * `blocked`
      * `missing`
      * `ambiguous`
  - field: '`envAllowed`'
    description: 'Whether `env.mode` permits environment input for this backend.'
  - field: '`envInputPresent`'
    description: 'Whether `kuma-dp` reported any matching environment variable keys at bootstrap.'
  - field: '`overrideKinds`'
    description: |
      OTLP fields where a per-signal variable overrides the shared layer. For example:
      * `endpoint`
      * `protocol`
      * `headers`
      * `timeout`
  - field: '`missingFields`'
    description: |
      Fields the merge could not produce. For example:
      * `endpoint`
      * `protocol`
      * `headers`
      * `client_key`
  - field: '`blockedReasons`'
    description: |
      The reason the signal was blocked. The value can be one or more of the following:
      * `EnvDisabledByPolicy`
      * `RequiredEnvMissing`
      * `SignalOverridesDisallowed`
      * `MultipleBackendsForSignal`
{% endtable %}

A signal is `ready` when the merge produces an `endpoint`. Other fields fall back to OpenTelemetry SDK defaults.

There are two types of blocks:
* Soft blocks (`EnvDisabledByPolicy` and `SignalOverridesDisallowed`) mean that the control plane ignored the environment input but the export still works. 
* Hard blocks (`RequiredEnvMissing` and `MultipleBackendsForSignal`) prevent export entirely and move the state out of `ready`.

### Signal missing: no endpoint resolved

A `state: missing` entry means a policy asked for the signal but the merge couldn't produce an `endpoint`. For example:

```yaml
openTelemetry:
  backends:
  - name: from-env
    metrics:
      enabled: true
      state: missing
      envAllowed: true
      envInputPresent: false
      missingFields:
      - endpoint
```
{:.no-copy-code}

The backend has no explicit address and no environment input was found. Either set `endpoint.address` on the backend or check the sidecar environment for `OTEL_EXPORTER_OTLP_ENDPOINT` or `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT`.

### Signal blocked: required input missing

A backend configured with `mode: Required` reports `state: blocked` and `RequiredEnvMissing` when `kuma-dp` doesn't report the expected environment keys. For example:

```yaml
openTelemetry:
  backends:
  - name: tenant-cloud
    traces:
      enabled: true
      state: blocked
      envAllowed: true
      envInputPresent: false
      blockedReasons:
      - RequiredEnvMissing
```
{:.no-copy-code}

The backend has `mode: Required` but `kuma-dp` didn't report the expected environment keys. Inject them on the sidecar and restart the data plane so the keys reach the control plane through bootstrap.

### Signal ambiguous: more than one backend competing for input

When two backends resolve to the same data plane for the same signal and both allow environment input, every competing backend reports `state: ambiguous` with `MultipleBackendsForSignal`. For example:

```yaml
openTelemetry:
  backends:
  - name: backend-a
    traces:
      enabled: true
      state: ambiguous
      envAllowed: true
      envInputPresent: true
      blockedReasons:
      - MultipleBackendsForSignal
  - name: backend-b
    traces:
      enabled: true
      state: ambiguous
      envAllowed: true
      envInputPresent: true
      blockedReasons:
      - MultipleBackendsForSignal
```
{:.no-copy-code}

Set `mode: Disabled` on every backend that should not receive environment input, or scope policies so only one backend reaches each data plane.

### Backend reference doesn't resolve

`MeshOpenTelemetryBackend` carries a `ReferencedByPolicies` condition with reason `Referenced` while at least one policy points at it. Otherwise the reason is `NotReferenced`. When a policy points at a backend that doesn't exist, the control plane logs through the `otel-backend-resolution` logger and skips the OTel export for that signal:

```text
MeshOpenTelemetryBackend not found, skipping backend  name=main-collector  labels=null
```
{:.no-copy-code}

In multi-zone, the most common cause is a zone-authored policy referencing a backend synced from the global control plane by `name` instead of `labels`. Switch to `labels` with the `kuma.io/display-name` label. A backend only applied on the global control plane can also take a few seconds to reach zone control planes through KDS, so expect short-lived `NotReferenced` and `not found` log lines while sync catches up.

### Mixed-version data planes during upgrade

`backendRef` requires the data plane to advertise the `feature-otel-via-kuma-dp` feature. All 2.14 data planes do by default. During an upgrade where some proxies are still on 2.13, the control plane silently skips the OTel pipe route for those proxies and emits no log entry. The signal doesn't export through the backend. Read `status.openTelemetry` on the affected proxies and confirm that the control plane writes no signal status entries for backends referenced with `backendRef` until the proxy advertises the feature.

Inline `endpoint` configurations stay on the direct Envoy export path and keep working through the upgrade.

## Schema

{% json_schema MeshOpenTelemetryBackends %}
