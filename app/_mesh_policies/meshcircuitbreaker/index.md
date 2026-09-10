---
title: Mesh Circuit Breaker
name: MeshCircuitBreakers
products:
- mesh
description: Cap the connections a proxy will open to a destination, and eject failing endpoints from the load balancing pool.
content_type: plugin
icon: meshcircuitbreaker.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: MeshRetry policy
  url: "/mesh/policies/meshretry/"
- text: MeshHealthCheck policy
  url: "/mesh/policies/meshhealthcheck/"
- text: MeshTimeout policy
  url: "/mesh/policies/meshtimeout/"
---

`MeshCircuitBreaker` does two separate jobs, and a policy can configure either or both.

`connectionLimits` caps how much traffic a proxy will send to a destination. Past the cap,
new requests fail immediately rather than queueing, which stops one slow destination from
consuming the caller's resources.

`outlierDetection` watches how endpoints behave and removes the ones failing more than their
peers from the load balancing pool. It is passive health checking: it draws its conclusions
from real traffic rather than from probes, which is what distinguishes it from
[MeshHealthCheck](/mesh/policies/meshhealthcheck/).

## Cap connections to a destination

This policy applies to proxies labelled `app: web`, and governs the connections they open to
`backend`:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshCircuitBreaker
mesh: default
name: web-to-backend
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: web
  to:
    - targetRef:
        kind: MeshService
        labels:
          kuma.io/display-name: backend
      default:
        connectionLimits:
          maxConnections: 2
          maxPendingRequests: 8
          maxRequests: 2
          maxRetries: 2
```
{% endpolicy_yaml %}

What each field does:

* `targetRef` selects **which proxies** the limits apply at. These are the callers.
* `to[].targetRef` selects **which destination** is being protected.
* `connectionLimits` caps the traffic between the two.

{% table %}
columns:
  - title: Limit
    key: limit
  - title: Caps
    key: caps
rows:
  - limit: "`maxConnections`"
    caps: "Connections opened to the destination."
  - limit: "`maxPendingRequests`"
    caps: "Requests waiting for a connection. For non-HTTP traffic this acts as a connection limit."
  - limit: "`maxRequests`"
    caps: "Parallel requests in flight. Has no effect on non-HTTP traffic."
  - limit: "`maxRetries`"
    caps: "Parallel retries. Set this alongside [MeshRetry](/mesh/policies/meshretry/), so retries cannot amplify a failure."
  - limit: "`maxConnectionPools`"
    caps: "Connection pools held per cluster at once. Relevant only where a cluster creates many pools."
{% endtable %}

## Where this policy applies

`spec.targetRef` selects which proxies the configuration is installed on: `Mesh`, or
`Dataplane` with `labels`. `spec.to[].targetRef` selects the destination being protected, and
accepts `Mesh`, `MeshService`, `MeshExternalService` or `MeshMultiZoneService`. `spec.rules[]`
configures the proxy's own inbound side.

A policy needs at least one of `to` or `rules`, and both may be set together. Each `default`
needs at least one of `connectionLimits` or `outlierDetection`.

This policy differs from others in two ways. `to[].targetRef` does not accept
`MeshHTTPRoute`, which [MeshRetry](/mesh/policies/meshretry/) does, because circuit breaking
applies to a whole destination rather than to one route. And `rules` cannot match on the
client at all: L7 matching for inbound circuit breaking is not implemented, so a single
catch-all entry is the only available shape.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## Eject failing endpoints

`outlierDetection` runs a sweep every `interval`, ejects any endpoint a detector flags, and
returns it after `baseEjectionTime`. Repeat offenders stay out longer: the real ejection time
is `baseEjectionTime` multiplied by the number of times that endpoint has been ejected.

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshCircuitBreaker
mesh: default
name: backend-outlier-detection
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: web
  to:
    - targetRef:
        kind: MeshService
        labels:
          kuma.io/display-name: backend
      default:
        outlierDetection:
          interval: 5s
          baseEjectionTime: 30s
          maxEjectionPercent: 20
          detectors:
            totalFailures:
              consecutive: 10
```
{% endpolicy_yaml %}

`maxEjectionPercent` caps how much of the pool can be ejected at once, and defaults to 10%.
**At least one endpoint can always be ejected, whatever the percentage says**, so a
two-endpoint destination can lose one of them even at a low setting.

`detectors` is required whenever `outlierDetection` is set, and needs at least one detector.
Setting `disabled: true` turns the whole block off without deleting it.

### Detectors

{% table %}
columns:
  - title: Detector
    key: detector
  - title: Ejects an endpoint when
    key: when
rows:
  - detector: "`totalFailures`"
    when: "`consecutive` server-side errors in a row. For HTTP that means 5xx; for TCP, connection failures."
  - detector: "`gatewayFailures`"
    when: "`consecutive` gateway errors in a row, meaning 502, 503 or 504, plus local failures such as a timeout or reset."
  - detector: "`localOriginFailures`"
    when: "`consecutive` locally originated failures in a row: timeout, TCP reset, ICMP errors. Requires `splitExternalAndLocalErrors: true`."
  - detector: "`successRate`"
    when: "The endpoint's success rate falls more than `standardDeviationFactor` below the mean for the cluster."
  - detector: "`failurePercentage`"
    when: "The endpoint's failure rate exceeds a flat `threshold`, rather than being compared to its peers."
{% endtable %}

`successRate` and `failurePercentage` both need enough traffic to be meaningful, so both take
`requestVolume` — the minimum requests an endpoint must have seen in an interval to be
assessed — and `minimumHosts`, the minimum number of endpoints meeting that volume before the
detector runs at all.

### Distinguish local failures from upstream errors

`splitExternalAndLocalErrors` changes what the detectors count. Left `false`, they treat a
connection reset and a 503 alike. Set `true`, they are counted separately:
`totalFailures` and `successRate` see only errors the destination returned, and
`localOriginFailures` becomes active for the connection-level ones.

Split mode is what to use when a destination is healthy but the path to it is not, since
otherwise both look identical to the detectors.

### Panic threshold

If outlier detection ejects so much of a pool that too few endpoints remain, Envoy enters
panic mode and resumes sending traffic to all endpoints, ejected ones included, rather than
failing the requests. `healthyPanicThreshold` is the percentage of healthy endpoints below
which that happens, and defaults to 50%. Set it to `0` to disable panic mode entirely.

## Circuit breaking for incoming traffic

`rules` configures the proxy's own inbound side, rather than what it sends to a destination:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshCircuitBreaker
mesh: default
name: backend-inbound
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - default:
        connectionLimits:
          maxConnections: 100
          maxPendingRequests: 50
```
{% endpolicy_yaml %}

`rules` currently applies to all inbound traffic at the selected proxies. There is no L7
matching, so a single catch-all entry is the only shape available.

## Upgrading from {{site.mesh_product_name}} 2.x

Two fields move and both move quietly: `from` is dropped rather than rejected, and
`healthyPanicThreshold` arrives here from `MeshHealthCheck` only if it is migrated by hand.
Neither produces an error, so do both before upgrading.

### Rewrite `from` as `rules`

`spec.from` is removed. Circuit breaking for inbound traffic is configured through
`spec.rules`.

`from` is dropped rather than rejected. A policy that also sets `to` or `rules` is accepted and
loses its inbound configuration silently; one where `from` was the only field is rejected with
`spec (): at least one of 'to' or 'rules' has to be defined`.

```yaml
# 2.x
spec:
  from:
    - targetRef:
        kind: Mesh
      default:
        connectionLimits:
          maxConnections: 1024

# 3.x
spec:
  rules:
    - default:
        connectionLimits:
          maxConnections: 1024
```

A `from` entry targeting `kind: Mesh`, meaning every client, becomes a single catch-all rule.

### Bring healthyPanicThreshold over from MeshHealthCheck

The field was removed from `MeshHealthCheck.to[].default` and now lives at
`MeshCircuitBreaker.to[].default.outlierDetection.healthyPanicThreshold`. Both policies
describe the health of the same endpoints, so the setting belongs with the one that ejects
them.

{:.warning}
> An un-migrated `healthyPanicThreshold` is dropped, not rejected. The field is no longer in
> the schema, so CRD validation prunes it on Kubernetes and deserialization discards it on
> Universal. A `MeshHealthCheck` carrying one still applies successfully, and the affected
> cluster falls back to Envoy's default panic threshold of 50%.

```yaml
# 2.x, on MeshHealthCheck
to:
  - targetRef:
      kind: Mesh
    default:
      interval: 10s
      timeout: 2s
      healthyPanicThreshold: 30
      http:
        path: /health

# 3.x, on MeshCircuitBreaker
to:
  - targetRef:
      kind: Mesh
    default:
      outlierDetection:
        healthyPanicThreshold: 30
```

### Rewrite the selectors

`spec.targetRef.kind` accepts `Mesh` and `Dataplane`. `MeshSubset`, `MeshServiceSubset` and
`MeshGateway` are rejected with `in body should be one of [Mesh Dataplane]`. A subset selector
becomes `kind: Dataplane` with the equivalent labels, and a `MeshGateway` selector becomes
`kind: Dataplane` too, since a delegated gateway is an ordinary `Dataplane`.

In `spec.to[]`, real resources are selected by `labels` only, and a `MeshService` named by
`name` is rejected with `labels (): must be set when kind is MeshService`. `MeshCircuitBreaker`
does not accept `kind: MeshHTTPRoute` there — circuit breaking applies to a whole destination,
not to individual routes.

{:.warning}
> `kind: Dataplane` selects proxies by `labels` only, and a reference carrying `name` or
> `namespace` instead is **accepted**. Those fields are not in the schema, so they are dropped,
> and what remains is a bare `kind: Dataplane` — every proxy in the mesh. Nothing reports it, so
> read the policy back after rewriting one: a stored `targetRef` with a `kind` and no `labels`
> covers the whole mesh.

### Review MeshProxyPatch circuit breaker patches

A `MeshProxyPatch` patching `circuitBreakers` used to append a second threshold for a priority
the cluster already had, and Envoy honours only the first, so the patch was dead
configuration while `/config_dump` showed the requested values. The patch now merges into the
existing threshold instead.

Where a cluster is covered by both, `MeshProxyPatch` runs last and now wins the fields it
sets, and the policy keeps the rest. Remove patches written before this change that you no
longer rely on, along with any workaround added because the patch appeared to do nothing.
