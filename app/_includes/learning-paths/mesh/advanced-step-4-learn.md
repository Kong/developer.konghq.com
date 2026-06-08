You've spent the last few paths configuring resilience: `MeshRetry` against AeroPay, `MeshTimeout` ceilings, `MeshCircuitBreaker` to detect outages. The obvious next question is _do any of those actually work the way you think?_ Traditional testing covers the happy path well, but rarely simulates a backend returning 503s for 10% of requests or a downstream that's intermittently slow. That's what `MeshFaultInjection` is for.

### What you can inject, and why each one matters

`MeshFaultInjection` supports three failure modes. Each one tests a different class of resilience policy.

| Fault type | What it does | What it tests |
| --- | --- | --- |
| **Abort** | Return a chosen HTTP status (e.g., 503) for a percentage of requests | `MeshRetry` (does it actually retry on 5xx?), `MeshCircuitBreaker` (does the circuit open at threshold?), application error handling |
| **Delay** | Insert a fixed delay before serving a percentage of requests | `MeshTimeout` (does the budget kick in?), UI degradation behaviour, queue depth assumptions |
| **Response rate limit** | Throttle the bytes-per-second of the response body | Slow-network handling, streaming-protocol correctness, client-side timeouts on body reads |

Each fault is independent and can be mixed: a single `MeshFaultInjection` can both abort 5% _and_ delay another 10%, simulating both fast and slow failures on the same dependency.

### `Dataplane`-targeted, not `MeshService`-targeted

A small but important detail: the modern `MeshFaultInjection` targets workloads with `kind: Dataplane` and `labels`, not `kind: MeshService`. The older `MeshService`-based targeting is deprecated.

```yaml
spec:
  targetRef:
    kind: Dataplane          # Not MeshService
    labels:
      app: flight-control
      color: blu
  from:
    - targetRef:
        kind: Mesh
      default:
        http:
          - abort:
              httpStatus: 503
              percentage: 10
```

Why? Because fault injection is fundamentally about _proxies_, not services. The `Dataplane` selector targets the specific sidecars that should inject the fault, with whatever granularity you want — by app, by color, by environment, by region.

### Field name gotchas

Two field names that the source documentation gets right but are easy to mis-remember when typing from memory:

- **`http[].delay.value`** — _not_ `fixedDelay`. The delay duration field is named `value`.
- **`percentage`** — accepts either an integer (`10`) or a decimal string (`"10.0"`), but **must** be present on every fault entry. Leaving it off silently means "no faults".

A correctly-formed delay fault:

```yaml
default:
  http:
    - delay:
        value: 5s
        percentage: 50
```

### Blast-radius scoping is the safety story

The most important property of a good fault-injection pattern isn't "what to inject", it's "how to keep it contained." Three techniques, in increasing order of safety, that the Kong Air platform team uses:

#### 1. Header-matching — runs only when explicitly opted in

The safest pattern. The fault matches a header (or set of headers) that real user requests never carry. Developers and synthetic monitors can deliberately set the header to trigger the fault path; production traffic is untouched.

```yaml
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: flight-control
  from:
    - targetRef:
        kind: Mesh
      default:
        http:
          - abort:
              httpStatus: 503
              percentage: 100             # 100% when the header matches
            match:
              headers:
                - name: x-chaos
                  value: "true"
```

This is the only fault injection that's reasonable to deploy to production untouched. Faults only fire when `x-chaos: true` is set — a value real users never send. Tests, synthetic monitors, and developers running scripted resilience drills can trigger them deliberately.

#### 2. Environment / zone scoping — runs only in non-prod

Apply the fault in `env: staging` or `zone: dev` first. Once you trust the behaviour, promote upward.

```yaml
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: flight-control
      env: staging                       # Only the staging fleet
```

#### 3. Low percentages — limits the user impact

Even without a header guard, start with `percentage: 1` and ramp up only after the dashboard says nothing is on fire. Combined with `MeshCircuitBreaker`, even unguarded faults are recoverable.

The three techniques compose. The Kong Air team's standard "chaos in production" deployment is **header-matched _and_ percentage-scoped _and_ targeted to a single colored ring** — three independent containment layers on the same policy.

### What you actually expect to see

When you inject a fault against a service that has resilience policies on it, the dashboard tells you whether they're working:

| You apply | You should see in metrics |
| --- | --- |
| 10% 503s + `MeshRetry: 3 attempts on 5xx` | _Service_ error rate ≈ 1% (10% of 10% gets through after retries); _retry_ counter spikes |
| 5s delay + `MeshTimeout: 3s` | Request-budget exceeded for 100% of delayed calls; `envoy_cluster_upstream_rq_timeout` counter increments |
| Sustained 50% 5xx + `MeshCircuitBreaker: 5 consecutive failures` | Circuit opens after ~10 requests; subsequent calls fail fast with no upstream hit |

If you _don't_ see those expected curves, that's your bug — either in the policy or in the application's handling of the failures. Which is exactly what fault injection is for.

### Things `MeshFaultInjection` doesn't do

For completeness, the failure modes it can _not_ simulate:

- **TCP-level network partition.** Use a different tool (a chaos pod, a Cilium NetworkPolicy, etc.) for that.
- **Memory pressure or CPU starvation** on the destination. These need actual host-level fault injection.
- **DNS failures.** The fault happens after DNS resolution.

If you need any of those, pair `MeshFaultInjection` with a heavier chaos toolkit (Chaos Mesh, Litmus). The mesh's role here is the protocol-layer faults that resilience policies can plausibly recover from.

### Further reading

- [`MeshFaultInjection` reference](/mesh/policies/meshfaultinjection/)
- [Chaos engineering principles for service meshes](/mesh/chaos/)
- [`MeshRetry`, `MeshTimeout`, `MeshCircuitBreaker`](/mesh/policies/)
