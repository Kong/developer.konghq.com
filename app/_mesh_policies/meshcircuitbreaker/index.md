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
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshcircuitbreaker"
- text: MeshRetry policy
  url: "/mesh/policies/meshretry/"
- text: MeshHealthCheck policy
  url: "/mesh/policies/meshhealthcheck/"
---

The `MeshCircuitBreaker` policy does two separate jobs:

* With `connectionLimits`, it caps connections, active requests, pending requests, and
  concurrent retries at a proxy. Requests can wait for a connection up to the pending limit,
  and anything beyond that is rejected.
* With `outlierDetection`, it removes endpoints that fail more often than their peers from the
  load balancing pool. Unlike [MeshHealthCheck](/mesh/policies/meshhealthcheck/), it judges
  endpoints from real traffic, not probes.

Both mechanisms work locally at each proxy, so callers don't share limits or health
observations.

## Cap connections to a destination

The following example limits the connections that proxies labeled `app: web` open to
`backend`. The limits are small to make testing easy, so size production limits for your
expected concurrency:

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

* `targetRef` selects the proxies the limits apply to: `Mesh`, or `Dataplane` with `labels`.
* `to[].targetRef` selects the destination to protect: `Mesh`, `MeshService`,
  `MeshExternalService`, or `MeshMultiZoneService`. `MeshHTTPRoute` isn't accepted, because
  circuit breaking applies to a whole destination, not to one route.
* `connectionLimits` sets the limits.

A policy needs `to`, `rules`, or both. Each `default` needs `connectionLimits`,
`outlierDetection`, or both.

`connectionLimits` accepts the following limits:

{% table %}
columns:
  - title: Limit
    key: limit
  - title: Caps
    key: caps
rows:
  - limit: "`maxConnections`"
    caps: "Connections to the destination."
  - limit: "`maxPendingRequests`"
    caps: "Requests waiting for a connection. For non-HTTP traffic, it acts as a connection limit."
  - limit: "`maxRequests`"
    caps: "Parallel requests. It has no effect on non-HTTP traffic."
  - limit: "`maxRetries`"
    caps: "Parallel retries across all requests to the destination. [MeshRetry](/mesh/policies/meshretry/) `numRetries` caps attempts for one request, so set both to keep retries from amplifying a failure."
  - limit: "`maxConnectionPools`"
    caps: "Connection pools per cluster. Only relevant when a cluster creates many pools."
{% endtable %}

A new mesh has no `MeshCircuitBreaker`, so Envoy's own limits apply: `maxConnections`,
`maxPendingRequests`, and `maxRequests` of 1024, `maxRetries` of 3, and no outlier detection.

## Eject failing endpoints

`outlierDetection` temporarily removes failing endpoints from a proxy's healthy pool.
Consecutive-failure detectors react to failures as they happen, and statistical detectors
evaluate each interval. `baseEjectionTime` sets how long an endpoint stays out, and repeated
ejections extend it. An endpoint that returns to the pool gets another attempt, which doesn't
mean it has recovered.

The following example ejects `backend` endpoints after 10 consecutive failures:

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
In a small pool, this limit can prevent any endpoint from being ejected, because this policy
doesn't enable Envoy's `always_eject_one_host` option. Test the limit with your actual
endpoint count. For more information, see
[Envoy's outlier detection reference](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/outlier_detection.proto).

`outlierDetection` requires at least one detector. To turn the block off without deleting it,
set `disabled: true`. The block still needs a detector while disabled, but the detector is
ignored.

### Detectors

{% table %}
columns:
  - title: Detector
    key: detector
  - title: Ejects an endpoint when
    key: when
rows:
  - detector: "`totalFailures`"
    when: "It returns `consecutive` server errors in a row: 5xx for HTTP, connection failures for TCP."
  - detector: "`gatewayFailures`"
    when: "It returns `consecutive` gateway errors in a row (502, 503, or 504), including local failures such as timeouts or resets."
  - detector: "`localOriginFailures`"
    when: "It has `consecutive` local failures in a row, such as timeouts, TCP resets, or ICMP errors. Requires `splitExternalAndLocalErrors: true`."
  - detector: "`successRate`"
    when: "Its success rate is more than `standardDeviationFactor` below the cluster mean."
  - detector: "`failurePercentage`"
    when: "Its failure rate is above a fixed `threshold`, regardless of its peers."
{% endtable %}

`successRate` and `failurePercentage` need enough traffic to be meaningful.
`requestVolume` sets the minimum requests an endpoint must see in an interval to be evaluated,
and `minimumHosts` sets how many endpoints must reach that volume before the detector runs.

### Distinguish local failures from upstream errors

`splitExternalAndLocalErrors` controls what the detectors count:

* `false` (default): connection resets and 503 responses count the same.
* `true`: `totalFailures` and `successRate` count only errors returned by the destination, and
  `localOriginFailures` counts connection-level failures.

Use `true` when the destination is healthy but the network path to it isn't. Otherwise, the
detectors can't tell the two apart.

### Panic threshold

If too few healthy endpoints remain, Envoy enters panic mode and sends traffic to all
endpoints, including ejected ones, instead of failing requests. `healthyPanicThreshold` sets
the percentage of healthy endpoints below which this happens, and defaults to 50%. Set it to
`0` to disable panic mode. `healthyPanicThreshold` is only applied while outlier detection is
enabled. When it's disabled, the 50% default applies.

## Cap incoming connections

`rules` limits the proxy's own inbound traffic instead of what it sends to a destination:

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

`rules` applies to all inbound traffic at the selected proxies. It has no L7 matching, so use
a single catch-all entry.

Inbound limits apply to the connections between the destination proxy and its local
application, not across every replica. To limit one named inbound on a proxy with several
ports, set `targetRef.sectionName`.

## Overlapping policies

A narrower policy overrides only the fields it sets. For example, setting only
`maxConnections: 100` for web-to-backend traffic keeps the broader request and retry limits.
To turn off inherited outlier detection, set `outlierDetection.disabled: true`. The block still
needs a `detectors` entry, for example `detectors: {totalFailures: {consecutive: 5}}`, which is
ignored while disabled. Leaving the block out of the narrower policy doesn't remove it.

## Validating the circuit breaker

1. Send more concurrent requests than `connectionLimits` allows, and confirm that the excess
   fails at the client proxy without reaching the destination.
1. If retries are enabled, confirm that concurrent retries stop at `maxRetries`.
1. Make one endpoint return the failures your `detectors` count, and keep enough traffic
   flowing for the detector to evaluate it.
1. Confirm that traffic stops reaching the ejected endpoint and returns when the ejection
   period ends.
1. Make enough endpoints unhealthy to cross `healthyPanicThreshold`, and confirm that traffic
   reaches all endpoints again.

To check the results, inspect the selected proxy's Envoy admin endpoints:

* `/stats`: the cluster's `circuit_breakers` gauges, overflow counters, and
  `outlier_detection` counters.
* `/clusters`: endpoint health.

Compare values before and after the test, because a nonzero counter can come from older
traffic.

{% table %}
columns:
  - title: Unexpected result
    key: unexpected
  - title: Check
    key: check
rows:
  - unexpected: "The service receives more concurrency than the limit"
    check: "Limits apply per caller proxy and destination cluster, not mesh-wide."
  - unexpected: "Requests queue instead of failing immediately"
    check: "`maxPendingRequests`, and whether an open connection can accept more requests."
  - unexpected: "No endpoint is ejected"
    check: "Detector thresholds, `requestVolume`, and whether the detector counts that type of failure."
  - unexpected: "An ejected endpoint receives traffic again"
    check: "Panic mode, the ejection period, and whether other proxies still see the endpoint as healthy."
{% endtable %}
