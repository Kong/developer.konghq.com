---
title: Mesh Health Check
name: MeshHealthChecks
products:
- mesh
description: Probe a destination's endpoints and remove the ones that fail from the load balancing pool.
content_type: plugin
icon: meshhealthcheck.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshhealthcheck"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
- text: MeshRetry policy
  url: "/mesh/policies/meshretry/"
---

`MeshHealthCheck` makes a client proxy send probes to a destination's endpoints, and stop
sending traffic to the ones that fail. The probes run on a schedule and are independent of
real requests, which makes this active health checking.

[MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/) reaches the same outcome from the
other direction. Its `outlierDetection` draws conclusions from the traffic already flowing,
which is passive health checking. A destination that receives little traffic is a case for
active checks, since there may not be enough requests to judge it by.

## Probe a destination over HTTP

This policy applies to proxies labeled `app: web`, and probes the endpoints of `backend`:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshHealthCheck
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
        interval: 10s
        timeout: 2s
        unhealthyThreshold: 3
        healthyThreshold: 1
        http:
          path: /health
          expectedStatuses:
            - 200
```
{% endpolicy_yaml %}

`targetRef` selects the `web` proxies that send probes, while `to[].targetRef` selects the
`backend` endpoints they probe. An endpoint is removed after three consecutive probes fail or
time out, and one successful probe returns it to the healthy pool.

## Where this policy applies

`spec.targetRef` selects which proxies send the probes, and these are the callers: `Mesh`, or
`Dataplane` with `labels`. `spec.to[].targetRef` selects the destination to probe, and
accepts `Mesh`, `MeshService`, `MeshExternalService` or `MeshMultiZoneService`.

There is no `rules` array. A health check is something a caller performs, so it is configured
outbound only. `to[].targetRef` does not accept `MeshHTTPRoute`: a probe addresses an
endpoint, not a route.

Each `default` needs at least one of `http`, `tcp` or `grpc`.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## Scheduling and thresholds

{% table %}
columns:
  - title: Field
    key: field
  - title: Governs
    key: governs
  - title: Default
    key: default
rows:
  - field: "`interval`"
    governs: "Time between consecutive probes."
    default: "`1m`"
  - field: "`timeout`"
    governs: "How long to wait for a probe response."
    default: "`15s`"
  - field: "`unhealthyThreshold`"
    governs: "Consecutive failed probes before an endpoint is treated as unhealthy."
    default: "5"
  - field: "`healthyThreshold`"
    governs: "Consecutive successful probes before an endpoint is treated as healthy again."
    default: "1"
  - field: "`noTrafficInterval`"
    governs: "Probe interval for a destination that has never received traffic. Takes precedence over `interval`."
    default: "`60s`"
  - field: "`reuseConnection`"
    governs: "Whether to reuse the connection between probes."
    default: "`true`"
{% endtable %}

The default `interval` of one minute with an `unhealthyThreshold` of 5 means an endpoint that
fails every probe is removed roughly five minutes after it starts failing. Shorten both to
detect a failure sooner, at the cost of more probe traffic.

### Spread the probes out

Every proxy probing on the same schedule produces a burst of traffic at each interval.
`initialJitter` delays the first probe by a random amount between zero and the value given,
which staggers proxies that start together. `intervalJitter` adds a fixed amount to each
wait, and `intervalJitterPercent` adds a proportion of `intervalJitter`. Setting both applies
both.

### Behavior in panic mode

`failTrafficOnPanic` changes what happens when a cluster enters Envoy's panic mode, where too
few endpoints remain healthy. Left unset, panic mode sends traffic to all endpoints including
the unhealthy ones. Set to `true`, the cluster fails every request instead, which keeps load
off a destination that is already failing.

The panic threshold itself is set on
[MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/), not here.

## Probes per protocol

The protocol is chosen by taking the most specific one configured. Setting `disabled: true`
on a protocol falls back to the more general one, so a policy can define an HTTP check for
most destinations and disable it for one that only speaks TCP.

### HTTP

HTTP probes are sent over HTTP/2.

{% table %}
columns:
  - title: Field
    key: field
  - title: Governs
    key: governs
  - title: Default
    key: default
rows:
  - field: "`path`"
    governs: "Path the probe requests."
    default: "`/`"
  - field: "`expectedStatuses`"
    governs: "Response statuses treated as healthy. Only `100` to `599` are accepted."
    default: "`200` only"
  - field: "`requestHeadersToAdd`"
    governs: "Headers to `set` or `add` on each probe. `set` replaces an existing header, `add` appends to it."
    default: "none"
{% endtable %}

### TCP

`send` is base64-encoded content to write, and `receive` is a list of base64-encoded blocks
expected in the response. Matching is fuzzy but ordered: each block must appear, in the order
given, though not necessarily contiguously.

Leaving `receive` empty or unset makes the probe connect-only, and it succeeds as soon as a
TCP connection is established.

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshHealthCheck
mesh: default
name: web-to-redis-tcp
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: web
  to:
    - targetRef:
        kind: MeshService
        labels:
          kuma.io/display-name: redis
      default:
        interval: 10s
        timeout: 2s
        tcp: {}
```
{% endpolicy_yaml %}

### gRPC

`serviceName` is passed to the destination's gRPC health service. `authority` sets the
`:authority` header on the probe, and defaults to the name of the cluster the check belongs
to.

## Validate endpoint health

1. Make one destination endpoint fail the configured health check while leaving another
   endpoint healthy.
1. Wait for `unhealthyThreshold` consecutive probes and confirm that new traffic stops reaching
   the failing endpoint.
1. Restore the endpoint, wait for `healthyThreshold` successful probes, and confirm that it
   receives traffic again.
1. Confirm that a probe timeout is shorter than the interval and that the probe volume is safe
   for the number of client proxies.
1. If `failTrafficOnPanic` is enabled, make enough endpoints unhealthy to enter panic mode and
   confirm that requests fail instead of returning to unhealthy endpoints.
