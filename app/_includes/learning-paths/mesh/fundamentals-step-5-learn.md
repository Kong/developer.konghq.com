In Step 4 you used `MeshService` to split traffic between two versions. In Step 3 you used `MeshSubset` to apply a regional timeout. Both `kind: ...` values can appear in the same `targetRef` slot — but they solve very different problems. This step explains the distinction so you reach for the right one without second-guessing.

### Two ways to group endpoints

| | `MeshSubset` | `MeshService` |
| --- | --- | --- |
| **Logic** | Implicit, tag-based | Explicit, resource-based |
| **Defined where?** | In a policy's `targetRef.tags` | As a standalone resource with its own selector |
| **Lives for…** | The lifetime of the policy that mentions it | Independently — outlives any single policy |
| **Used as a proxy target?** | Yes — picks _which sidecars_ receive a policy | Yes |
| **Used as a destination (`backendRef`)?** | **No** | Yes — primary destination for routes |
| **Best for** | Cross-cutting policies that span many services | Canary, blue/green, A/B, named destinations |

### `MeshSubset` is for cross-cutting policies

Use `MeshSubset` when the workloads you want to target share an environmental trait — region, zone, environment label, mesh tag — rather than a service identity. The classic case is "every sidecar in `us-east-1` gets a longer timeout because of cross-AZ latency" (which is exactly what you applied in Step 3).

A `MeshSubset` is _ephemeral_: it exists only as a `targetRef.tags` block inside one policy. There's no `MeshSubset` resource to `kubectl get`. Two policies that both target `region: us-east-1` aren't sharing a definition — they're both independently matching on tags.

### `MeshService` is the modern standard for routing

Use `MeshService` when you need a stable, named, addressable thing — anything that's going to appear in a `backendRef`, anything you want as a distinct line on a metrics dashboard, anything a progressive-delivery tool needs to point at.

Critically, `backendRef: { kind: MeshSubset, ... }` is **not supported**. The moment you need to route traffic _to_ a group of endpoints, you need a `MeshService` — not a subset.

### When to use which: a decision shortcut

Answer these in order:

1. **Will this resource appear in a `backendRef`?** → `MeshService`. (Subsets can't be destinations.)
2. **Do I need distinct metrics per group?** → `MeshService`. (Each is its own Prometheus target.)
3. **Is the grouping a permanent, named concept that other policies will reference?** → `MeshService`.
4. **Am I just applying a one-off policy to a tag-matched set of sidecars?** → `MeshSubset`.

In a typical mesh, most policies that go through this flowchart end up at `MeshService`. `MeshSubset` is reserved for genuinely cross-cutting concerns — the kind you'd otherwise express as "for every sidecar where X is true."

### Legacy `MeshServiceSubset`

You may still see `kind: MeshServiceSubset` in older docs or unmigrated clusters. It was a virtual kind used before explicit `MeshService` resources existed: a way to say "the subset of `booking-engine` where `version=v1`" without creating a separate resource for it. It's still honoured for backwards compatibility but is considered **legacy**. Anywhere you'd reach for `MeshServiceSubset` in a new project, use two explicit `MeshService` resources instead — exactly the pattern from Step 4.

### Further reading

- [`MeshSubset` reference](/mesh/policies/meshsubset/)
- [`MeshService` reference](/mesh/policies/meshservice/)
- [Migrating from `MeshServiceSubset` to explicit `MeshService`](/mesh/migration/explicit-subsetting/)
