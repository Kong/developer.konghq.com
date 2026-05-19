In Step 4 of Fundamentals you split traffic between `booking-engine-v1` and `booking-engine-v2` _globally_ — every sidecar in the mesh sent 90% to v1 and 10% to v2 regardless of where it was running. That's the right model when you trust v2 enough to expose every passenger to it, but for an early canary Kong Air's release engineers want something more conservative: **roll v2 out in `us-east-1` first; keep `eu-west-1` and `us-west-2` on 100% v1 until East has burned in for a few days**.

This step is about expressing that asymmetric rollout cleanly, and adding a safety net that catches the canary even if it collapses entirely.

### The shape of an asymmetric, per-zone canary

In a single-zone canary, one `MeshHTTPRoute` decides the weights. In a per-zone canary, you write one route _per zone_ — each scoped to the workload making the call in that zone — pointing at the same `MeshMultiZoneService` resources.

```
us-east-1: passenger-portal-east  --route(90/10)-->  check-in-api (v1 / v2)
us-west-2: passenger-portal-west  --route(100/0)-->  check-in-api (v1 only)
eu-west-1: passenger-portal-eu    --route(100/0)-->  check-in-api (v1 only)
```

Each route targets a different `MeshService` (the zone-specific `passenger-portal`), so each only applies to sidecars in that zone. Because they all `to:` the same global `MeshMultiZoneService`, no other config changes are needed.

### Why `MeshMultiZoneService`, not `MeshService`, for the destinations

If you pointed the routes at plain `MeshService` resources, you'd be talking only to local endpoints — `passenger-portal-east` would route to the v1 instances in `us-east-1`, never to `us-west-2`. That's what you want most of the time, but it leaves no failover when East's `check-in-api` collapses.

Pointing at an MMZS means each route sees endpoints in every zone, with locality preference applied. Day-to-day, `passenger-portal-east` still hits East endpoints. When East's `check-in-api` is unhealthy, locality awareness automatically promotes West endpoints into the pool.

### Locality awareness + `MeshLoadBalancingStrategy` = the safety net

You set up the default locality-aware behaviour in Step 1 of this path. For the canary, you add one more piece: cross-zone failover for the _canary_ specifically.

If `booking-engine-v2` in East goes off the rails (segfaults, OOM-kills, terminal latency), you want East traffic that was destined for v2 to fall through to v1 in West — _not_ to v2 in West, where the same bug presumably lives. That's exactly what `failover: type: Any` gives you: when local endpoints in the canary pool fail, the next preference is _any_ healthy endpoint, which means West stable.

```yaml
spec:
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: check-in-api-canary
      default:
        localityAwareness:
          crossZone:
            failover:
              - to:
                  type: Any  # When East v2 fails, traffic flows to West v1
```

This is the property that makes canaries safe to deploy to a single zone: failure of the canary takes a user to the stable version in a different region, not to nothing.

### Zone-originated policies override Global

A subtle but powerful feature: when a Zone CP _also_ has a policy of the same name and specificity as a Global one, **the zone-originated policy wins** in that zone.

That means you can express the canary entirely from East's Zone CP without touching Global policy at all:

1. Global policy says `check-in-api: 100% v1` everywhere.
2. East's Zone CP applies a local override: `check-in-api: 90/10 in East`.
3. Sidecars in East see both; the zone-local one wins. West and EU are untouched.

This is the workflow most release engineers prefer — no need to coordinate with the platform team for every rollout, and no risk of accidentally affecting another region.

### What you can't do this way

Per-zone canary with MMZS isn't a replacement for every release pattern. Two things specifically:

- **Path-based experimentation** — if you want "all `/baggage` traffic goes to v2, all other paths go to v1", that's normal `MeshHTTPRoute` with `matches`, not per-zone routing.
- **Header-based shadow traffic** — for "send 1% of production traffic to v2 silently and discard the response", reach for `MeshFaultInjection` mirroring patterns (Advanced Patterns path).

Per-zone canary is specifically the answer to "expose v2 to a fraction of users in a specific region before going global."

### Further reading

- [`MeshMultiZoneService` reference](/mesh/policies/meshmultizoneservice/)
- [`MeshHTTPRoute` reference](/mesh/policies/meshhttproute/)
- [`MeshLoadBalancingStrategy` reference](/mesh/policies/meshloadbalancingstrategy/)
- [Zone-local policy precedence](/mesh/policies/precedence/)
