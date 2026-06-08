In Step 2 you used a `MeshTrafficPermission` with a `targetRef`, a `from` block, and a `default` action. That same three-piece shape is the entire {{site.mesh_product_name}} policy model. Every policy — traffic permission, timeout, retry, rate limit, route — has the same structure.

This step is the conceptual foundation under everything that follows.

### Why `targetRef` instead of label-matching

Traditional meshes spread one piece of behaviour across multiple resources: a `VirtualService` to route, a `DestinationRule` to tune connection settings, a `ServiceEntry` to register an external endpoint, a `Gateway` to expose ingress. Each uses its own selector language.

{{site.mesh_product_name}} picks one selector — `targetRef` — and uses it for everything:

- **Consistency** — once you understand `targetRef`, you can read any policy in the mesh.
- **Gateway API alignment** — `targetRef` is the same pattern the Kubernetes Gateway API uses, so your mesh policies look like your ingress policies.
- **No label gymnastics** — you don't write `matchLabels` blocks in every policy; you point at a resource that already represents the workload.

### The three blocks of every policy

```yaml
spec:
  targetRef:                    # 1. Which sidecars receive this configuration
    kind: ...
    name: ...

  to:                           # 2a. Outbound rules (or `from` for inbound)
    - targetRef: { ... }
      default: { ... }

  default: { ... }              # 2b. Direct configuration (no to/from needed)
```

1. **Top-level `targetRef`** — selects the sidecars that get this configuration loaded.
2. **`to` / `from` rules** — what traffic the policy affects, and the config to apply to it.
3. **`default` block** — the actual values: an action, a timeout, a retry budget, a route weight, a metrics backend, etc.

Not every policy uses every block. Some use `to`, some use `from`, some skip both and configure the proxy directly.

### The hierarchy of target kinds

{{site.mesh_product_name}} resolves `targetRef.kind` through three levels:

| Level | `kind` | Typical Kong Air use case |
| --- | --- | --- |
| **Mesh-wide** | `Mesh` | Baseline mTLS, baseline logging, broad permissions. |
| **Grouped** | `MeshSubset` | "Every sidecar tagged `region: us-east-1`" — cross-cutting policies. |
| **Specific** | `MeshService` | A 10% canary on `booking-engine`, a custom timeout on `flight-control`. |

You'll see explicit examples of each level in this step's Practice section.

### `to`, `from`, and `default`: who points at whom

| Direction | What it does | Example policies | Kong Air example |
| --- | --- | --- | --- |
| **Outbound (`to`)** | Affects traffic *leaving* the target sidecar | `MeshHTTPRoute`, `MeshRetry`, `MeshCircuitBreaker`, `MeshTimeout` | Route 10% of `passenger-portal` traffic to `booking-v2`. |
| **Inbound (`from`)** | Affects traffic *entering* the target sidecar | `MeshTrafficPermission` | Only `flight-control` may call `check-in-api`. |
| **Dual** | Can be applied to either direction | `MeshTimeout`, `MeshRateLimit`, `MeshAccessLog` | 5s outbound timeout on every request leaving `flight-control`. |
| **Direct (`default` only)** | Configures the proxy itself | `MeshMetric`, `MeshTrace`, `MeshProxyPatch` | Enable Prometheus metrics on every sidecar. |

### Most specific wins

When more than one policy of the same kind matches a workload, the most specific target wins:

```
MeshService (most specific)  →  beats  →  MeshSubset  →  beats  →  Mesh (broadest)
```

A `MeshTimeout` targeting `MeshService: check-in-api` overrides a `MeshTimeout` targeting `MeshSubset: region: us-east-1`, which itself overrides a `MeshTimeout` targeting `Mesh`.

The exception you already met: for `MeshTrafficPermission`, **Allow beats Deny** at the same specificity level. Specificity rules still apply between levels — a `MeshService`-level deny beats a `Mesh`-level allow.

### A practical layering pattern

The most maintainable {{site.mesh_product_name}} configurations follow a "broad-then-narrow" rhythm:

1. Set sensible defaults at `Mesh` level (basic timeouts, baseline mTLS, broad allow rules for trusted prefixes).
2. Override per region or environment with `MeshSubset` (longer timeouts in a cross-AZ region, tighter rate limits in staging).
3. Tune individual services with `MeshService` only where you need surgical control (a 5s timeout on `flight-control` because it has known slow downstreams).

This keeps the policy surface small and the precedence rules predictable.

### Further reading

- [`targetRef` reference](/mesh/policies/targetref/)
- [Policy precedence and merging](/mesh/policies/merging/)
- [List of all policy kinds](/mesh/policies/)
