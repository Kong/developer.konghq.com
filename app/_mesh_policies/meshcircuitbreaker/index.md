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
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshcircuitbreaker"
- text: MeshRetry policy
  url: "/mesh/policies/meshretry/"
- text: MeshHealthCheck policy
  url: "/mesh/policies/meshhealthcheck/"
---

`MeshCircuitBreaker` does two separate jobs, and a policy can configure either or both.

`connectionLimits` bounds connections, active requests, pending requests, and concurrent
retries at a proxy. Work that cannot fit within the applicable limit is rejected. Pending
requests may wait for a connection up to their configured limit; this is not a requests-per-second
rate limit.

`outlierDetection` watches how endpoints behave and removes the ones failing more than their
peers from the load balancing pool. It is passive health checking: it draws its conclusions
from real traffic rather than from probes, which is what distinguishes it from
[MeshHealthCheck](/mesh/policies/meshhealthcheck/).

Both mechanisms operate locally at each proxy and its destination cluster. A limit of 100
does not create a shared allowance of 100 across all callers. Scaling the client deployment
adds proxies with their own limits and health observations.

## Cap connections to a destination

This policy applies to proxies labeled `app: web`, and governs the connections they open to
`backend`:

These deliberately small limits make the behavior easy to test. Size production limits for
expected concurrency and the resources available to each caller.

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

`maxRetries` limits retries running at the same time across requests to this destination.
`MeshRetry.numRetries` instead limits attempts for one request. Setting either one does not
replace the other.

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

The initial mesh-wide circuit-breaker policy sets `maxConnections`, `maxPendingRequests`,
and `maxRequests` to 1024, and `maxRetries` to 3. It does not enable outlier detection.
Installations that skip creating this initial policy still have Envoy's underlying limits.

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

## How overlapping policies combine

A narrower policy overrides fields it sets while retaining fields from broader policies.
For example, setting only `maxConnections: 100` for web-to-backend traffic retains the
broader request and retry limits. To disable inherited outlier detection, set
`outlierDetection.disabled: true`; omitting the block from the narrower policy does not remove
the broader configuration.

## Eject failing endpoints

`outlierDetection` temporarily removes failing endpoints from a proxy's healthy pool.
Consecutive-failure detectors react to observed failures; statistical detectors use analysis
intervals. `baseEjectionTime` starts the exclusion period, and repeated ejections can extend
it. Returning to the pool permits another attempt; it does not prove the endpoint has recovered.

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
Do not assume that one endpoint can always be ejected regardless of this limit.
Envoy provides a separate `always_eject_one_host` option for that behavior, which this
policy does not enable. Test the limit with your actual endpoint count, especially for
small pools. See [Envoy's outlier detection reference](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/outlier_detection.proto).

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

Inbound limits apply to the destination proxy's connections to its local application. They do
not impose a global limit across every replica of that application. Use `targetRef.sectionName`
to select a specific named inbound when the proxy serves multiple ports.

## Validate the circuit breaker

1. Drive more concurrent work than the configured `connectionLimits` allow and confirm that the
   excess fails at the client proxy without reaching the destination.
1. If retries are enabled, confirm that concurrent retries stop at `maxRetries`.
1. Make one endpoint produce the failures configured under `detectors` and keep enough traffic
   flowing for the detector to evaluate it.
1. Confirm that traffic stops reaching the ejected endpoint and returns after the effective
   `baseEjectionTime`.
1. Test the `healthyPanicThreshold` behavior with enough unhealthy endpoints to cross the
   configured percentage.

Inspect the selected proxy's Envoy `/stats` endpoint for the affected cluster's
`circuit_breakers` gauges and overflow counters. For ejections, inspect its
`outlier_detection` counters and `/clusters` health state. Compare values before and after
the controlled test, rather than interpreting a historical nonzero counter as a current failure.

| Unexpected result | Check |
| --- | --- |
| The service receives more concurrency than the configured limit | Count caller proxies and destination clusters; limits are not shared mesh-wide. |
| Requests queue instead of failing immediately | Check pending-request capacity and whether an established connection can accept more work. |
| No endpoint is ejected | Check detector thresholds, minimum traffic volume, and whether the chosen detector counts that failure. |
| An ejected endpoint receives traffic again | Check panic mode, the ejection period, and other proxies' independent health views. |
