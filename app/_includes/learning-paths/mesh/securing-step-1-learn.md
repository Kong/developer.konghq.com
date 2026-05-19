Once Kong Air has a few services in the mesh and mTLS turned on, the obvious next question is: _what's actually happening in there?_ {{site.mesh_product_name}} emits the three classical observability signals — metrics, traces, and logs — without any change to application code, because every sidecar sees every request.

### Where the data comes from

| Signal | Source | Backed by |
| --- | --- | --- |
| **Metrics** | Each sidecar exposes a `/metrics` endpoint that Prometheus scrapes. | `MeshMetric` policy + Prometheus's MADS discovery |
| **Traces** | Each sidecar generates spans and propagates trace headers across hops. | `MeshTrace` policy + an OTLP-compatible backend (Jaeger, Tempo, Datadog, …) |
| **Logs** | Each sidecar writes structured access logs for every request it handles. | `MeshAccessLog` policy + a file/TCP/OTel backend |

Three things are worth pinning down before you turn them on.

### 1. The Control Plane is not in the data path

{{site.mesh_product_name}}'s observability is **push-and-pull hybrid**, but importantly **decentralised**:

- Sidecars _produce_ the data and either expose it for scraping (metrics) or push it directly to a backend (traces, logs).
- The Control Plane configures the sidecars via policy, but **never sees** the metric, trace, or log payloads.

This matters operationally: telemetry volume scales with traffic, not with CP capacity, and a CP outage doesn't break observability for traffic already flowing.

### 2. MADS — automatic Prometheus discovery

Manually maintaining a `scrape_configs` list across hundreds of sidecars is a non-starter. The Zone Control Plane solves this by exposing a **Monitoring Assignment Discovery Service (MADS)** endpoint — an HTTP service-discovery API native to Prometheus.

When you configure Prometheus against MADS, it asks the Zone CP "who's in the mesh right now?" and gets a live list of every sidecar with its scrape address. New pods appear automatically; deleted pods disappear. In a multi-zone mesh, a single Prometheus can point at every Zone CP's MADS endpoint and produce a unified, global metrics view.

### 3. Tracing is opt-in per Mesh, not per service

A `MeshTrace` at `kind: Mesh` makes _every_ sidecar in the mesh start emitting spans for the requests it handles, with automatic context propagation. You don't need to add SDKs to your applications — the sidecar inserts/propagates the trace headers (`traceparent`, `x-b3-*`, etc.) for you.

What you _do_ control:

- **Sampling rate** via `sampling.overall` — start low in production (1–5%), crank up in lower environments.
- **Custom tags** to enrich spans with business context (`airport-code`, `tenant-id`, etc.) — either literal values or pulled from request headers.

### Why `MeshMetric` needs a pod restart but `MeshAccessLog` doesn't

A subtle gotcha worth knowing before you apply:

| Policy | Restart required? | Why |
| --- | --- | --- |
| `MeshMetric` | **Yes** | The sidecar opens a new listener on port `5670` for Prometheus. Listeners are bound at startup. |
| `MeshTrace` | No | Tracing reconfigures the existing HTTP/gRPC filter chain — applied via xDS at runtime. |
| `MeshAccessLog` | No | Same — the access log is part of the filter chain. |

In a rolling-update environment, this is essentially zero-cost. In a long-lived sidecar (e.g., on a VM), you'll need to plan a restart window for the first `MeshMetric` rollout.

### What you get on the dashboard

With all three signals on, the bundled Grafana dashboards (`kumactl install observability`) give you, with zero configuration:

- **Per-service latency, error rate, throughput** (the RED metrics)
- A live **Service Map** showing the topology your traffic actually follows — including cross-zone hops via ZoneIngress
- Drill-down from a slow request → its trace → individual access-log entries with `%KUMA_SOURCE_SERVICE%` / `%KUMA_DESTINATION_SERVICE%` decoration

### Further reading

- [`MeshMetric` reference](/mesh/policies/meshmetric/)
- [`MeshTrace` reference](/mesh/policies/meshtrace/)
- [`MeshAccessLog` reference](/mesh/policies/meshaccesslog/)
- [Multi-zone observability and MADS](/mesh/multi-zone-observability/)
