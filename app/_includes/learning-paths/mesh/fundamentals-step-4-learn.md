Kong Air is rolling out **booking-engine v2** — a rewrite of the legacy booking service. The team wants 90% of traffic on the stable `v1` and 10% on `v2` for a pilot group, with a clean kill-switch if anything goes wrong. This is a textbook case for **traffic splitting** with explicit `MeshService` resources and a weighted `MeshHTTPRoute`.

### Explicit subsetting: one resource per version

Modern {{site.mesh_product_name}} (2.6+) treats each deployable version of a service as a first-class `MeshService` resource. Instead of one logical `booking-engine` filtered by labels at routing time, you declare two distinct resources:

- `booking-engine-v1` — selects pods tagged `app: booking-engine, version: v1`.
- `booking-engine-v2` — selects pods tagged `app: booking-engine, version: v2`.

Each version becomes a named, addressable, observable thing in its own right.

### Why this is better than legacy label-matching

Earlier mesh patterns route to `booking-engine` and then use a `subset: v1 | v2` filter at the destination. That works, but it has three failure modes that bite at scale:

1. **Routing is non-deterministic** — endpoints are resolved by tag every request. If a pod's labels drift, traffic shifts without you touching the route.
2. **Metrics are coarse** — Prometheus sees `booking-engine` as one service. To break down by version, every dashboard needs PromQL tag filters.
3. **Tools fight you** — Argo CD, Flagger, and the Gateway API all assume a stable, named target. Implicit subsetting forces custom glue everywhere.

Explicit `MeshService` resources fix all three: routing resolves to a known set of IPs, metrics are pre-segmented by version, and progressive-delivery tools work out of the box.

### What the rollout looks like

{% mermaid %}
graph TD
    User([Passenger request]) --> Portal["passenger-portal sidecar"]
    Portal --> Route{"MeshHTTPRoute<br/>booking-traffic-split"}
    Route -->|"90% weight"| Stable["booking-engine-v1<br/>(MeshService)"]
    Route -->|"10% weight"| Canary["booking-engine-v2<br/>(MeshService)"]
{% endmermaid %}

A single `MeshHTTPRoute`:

- Targets the **source** sidecar (`passenger-portal`) — that's where the routing decision is made.
- Points its `to` block at the **logical** destination (`booking-engine`).
- Distributes via `backendRefs` with `weight` between the two version resources.

### Resource stability

Notice what this model doesn't depend on:

- Pod counts. The split is `90/10` regardless of whether v1 has 50 pods and v2 has 1, or v1 has 3 and v2 has 30. Weights are applied at the routing layer, not derived from endpoint counts.
- Label drift. Each `MeshService` has its own selector; changing labels on one version doesn't accidentally redirect traffic for the other.
- The destination's awareness. `booking-engine-v1` and `booking-engine-v2` don't know they're being split — there's no version-aware code in either of them.

### When to reach for it

Use explicit `MeshService` + weighted `MeshHTTPRoute` whenever you need:

- **Canary releases** — gradual percentage rollouts (this step).
- **Blue/green deploys** — flip a 100/0 to 0/100 in one route change.
- **A/B testing** — route by header or path with the same primitives.
- **Migration cutovers** — move traffic from a legacy service to a rewrite over hours or days.

### Further reading

- [`MeshService` resource reference](/mesh/policies/meshservice/)
- [`MeshHTTPRoute` reference](/mesh/policies/meshhttproute/)
- [Progressive delivery patterns with {{site.mesh_product_name}}](/mesh/canary/)
