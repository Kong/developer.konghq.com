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

Two differences from other policies are worth knowing. `to[].targetRef` does not accept
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
panic mode and sends traffic to all endpoints regardless of health, on the grounds that a
degraded endpoint beats no endpoint. `healthyPanicThreshold` sets where that happens, as a
percentage, and defaults to 50%. Set it to `0` to disable panic mode entirely.

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

{:.warning}
> **`spec.from` is removed, and is dropped silently.** A policy that still uses `from`
> alongside `to` or `rules` is accepted, and the `from` configuration has no effect on
> inbound traffic. A policy where `from` was the only field set is rejected, because the
> resulting spec has neither `to` nor `rules`.
>
> Rewrite `from` as `rules`. A `from` entry targeting `kind: Mesh`, meaning all clients,
> becomes a single catch-all rule.

{:.warning}
> **`healthyPanicThreshold` moved off `MeshHealthCheck`, and un-migrated settings are
> dropped silently.** The field was removed from `MeshHealthCheck.to[].default`; it now lives
> at `MeshCircuitBreaker.to[].default.outlierDetection.healthyPanicThreshold`.
>
> On Kubernetes the old field is pruned by CRD validation, and on Universal it is discarded
> during deserialization. Either way nothing reports it, and the affected cluster reverts to
> Envoy's 50% default. Migrate these before upgrading.

{:.warning}
> `targetRef.kind` no longer accepts `MeshSubset`, `MeshServiceSubset` or `MeshGateway`, in
> either `targetRef` or `to[].targetRef`. Use `Mesh`, or `Dataplane` with `labels`.
