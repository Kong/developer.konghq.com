"Color routing" is a deployment pattern where you tag a group of related workloads with the same color label (`blu`, `green`, `red` — the names don't matter) and pin a request to that color for every hop of its journey through the mesh. A request that enters the chain on `blu` stays on `blu` end to end, no matter how many services it traverses.

Three concrete scenarios where color routing earns its keep:

- **Ring-based deploys.** `blu` = stable, `green` = pre-release. Promote services to `green` independently; testers and synthetic monitors hit `green` while real users stay on `blu`.
- **Tenant isolation in a shared mesh.** Each tenant gets a color; their requests can only see other workloads of their color. (This isn't a substitute for `MeshTrafficPermission` — it's a routing-time isolation layer on top.)
- **Shadow environments.** Run a parallel `green` copy of every service for performance testing, hammer it with synthetic load, observe in isolation.

### Why color routing isn't just N parallel meshes

You could build the same thing with hard multi-tenancy from Step 2 of this path — give each color its own mesh, federate via gateways. That works, but:

- Every color pays the cost of a full mesh (Zone CPs, ZoneIngresses, CA, etc.).
- Workloads are physically partitioned, so you can't dynamically rebalance `blu` and `green` pod counts as load shifts.
- Telemetry is fragmented — separate Prometheus, separate Grafana, separate Jaeger per color.

Color routing keeps everything in **one** mesh and uses policies to enforce the segmentation. Lower overhead, shared observability, dynamic capacity.

### The two-resource model

Color routing is built on the same multi-zone primitives you've already met:

1. **One `MeshMultiZoneService` per color, per service.** For Kong Air's `check-in-api` you'd have `check-in-api-blu` and `check-in-api-green`, each selecting `MeshService` resources whose `Dataplane`s are labelled with the matching color.
2. **One agnostic MMZS that aggregates all colors.** Call it `check-in-api-all`. It selects every `MeshService` for `check-in-api` regardless of color.

Workloads call the **agnostic** hostname (`check-in-api-all.mzsvc...`), and a `MeshHTTPRoute` rewrites the destination to the **color-specific** MMZS based on the caller's color. The application code never knows what color it's running.

### Color-pinning routes

The policy that does the routing is just `MeshHTTPRoute` — but the trick is in the `targetRef` and `backendRefs`:

```yaml
spec:
  targetRef:
    kind: MeshService
    name: client-blu               # Apply only to BLU clients
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-all     # When they call the AGNOSTIC name...
      rules:
        - default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: check-in-api-blu   # ...route to the BLU pool.
                weight: 100
```

You write one pair of routes per color (`blu`, `green`, etc.). A `blu` caller targeting `check-in-api-all` ends up on `check-in-api-blu`. A `green` caller ends up on `check-in-api-green`. Neither path leaks across colors.

### Color affinity for free across chains

The same pattern composes across chains. If `check-in-api-blu` then calls `flight-control-all`, _its_ traffic is also pinned: a `MeshHTTPRoute` targeting `check-in-api-blu` and pointing `flight-control-all` → `flight-control-blu` keeps the request `blu` end to end.

A trace through the chain looks like:

```
client-blu ─► check-in-api-blu ─► flight-control-blu ─► ...
                  ▲                       ▲
                  └─ policy routes "all" to BLU ─┘
```

No service ever needs to forward the color in a header, look at a request context, or care that this is happening. The mesh enforces affinity.

### Why agnostic hostnames matter

You _could_ write a route that targets `client-blu` and `backendRefs` directly to `check-in-api-blu`. That works too, but it tightly couples the caller to its color: if you ever want to add a `green` ring, you have to add new routes for every caller-callee pair.

The agnostic hostname inverts the coupling: callers don't know their color, callees don't know their color, only the routes know — and a route is a small, central thing you can add or remove without touching application code or other policies.

### Cross-zone failover within a color

`MeshMultiZoneService` selects across every zone, so `check-in-api-blu` resolves to `blu`-coloured pods in _every_ region. With locality-aware routing (Step 1 of this path), a `blu` request prefers `blu` endpoints in the same zone. If the local `blu` pool collapses, it fails over to `blu` endpoints in another zone — **not** to `green` in the same zone.

That's the property that makes color routing safe in production: degradation stays inside the color ring.

### Zone-local color overrides

Just like per-zone canary in Step 3, zone-originated policies override Global. A platform engineer can re-pin `blu` traffic to `green` in just one zone — useful for breaking a synthetic-only ring out of one zone for performance work — without affecting the global setup. The policy lifetime tracks where you applied it.

### When not to reach for color routing

Color routing is overkill for simple weighted canaries. If your need is "10% of users see v2", you want the Step 3 pattern (one `MeshHTTPRoute` with weighted `backendRefs`). Color routing shines when:

- The "color" is meaningful across many services, not just one.
- You need _routing_-level isolation, not just weighted distribution.
- You want callers to be color-unaware.

If just one of those is true, you can probably get there with simpler primitives.

### Further reading

- [Color-based deployment patterns](/mesh/color-routing/)
- [`MeshMultiZoneService` reference](/mesh/policies/meshmultizoneservice/)
- [`MeshHTTPRoute` reference](/mesh/policies/meshhttproute/)
