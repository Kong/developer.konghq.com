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

Each selected client proxy maintains its own health view. Marking an endpoint unhealthy does
not delete its Pod or change Kubernetes readiness, and another proxy may reach a different
health decision. Without an applicable check configuration, this policy adds no probes.

## Probe a destination over HTTP

This policy applies to proxies labeled `app: web`, and probes the endpoints of `backend`:

The backend must expose `/health` on the selected service port and return 200 when it can
serve traffic. Choose a lightweight endpoint: every selected client proxy probes each endpoint.

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
`backend` endpoints they probe. `interval: 10s` schedules checks and `timeout: 2s` limits
the wait for each response. Three consecutive network failures or timeouts mark an endpoint
unhealthy; an HTTP response outside the expected status set can mark it unhealthy immediately.
One successful probe meets this example's recovery threshold.

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

Thresholds do not provide an exact detection deadline. Probe duration, jitter, and the
no-traffic interval affect timing. HTTP status failures can bypass the failure threshold.
See [Envoy's health-check behavior](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/health_check.proto.html).

Estimate probe load before reducing the interval. With 100 client proxies checking 10 endpoints
every 10 seconds, the destination receives about 100 probes per second before jitter and
special intervals are considered.

### Spread the probes out

Every proxy probing on the same schedule produces a burst of traffic at each interval.
`initialJitter` delays the first probe by a random amount between zero and the value given,
which staggers proxies that start together. `intervalJitter` adds a random delay bounded by
the supplied duration. `intervalJitterPercent` calculates additional jitter from the check
interval, not from `intervalJitter`. Setting both combines their contributions.

### Behavior in panic mode

`failTrafficOnPanic` changes what happens when a cluster enters Envoy's panic mode, where too
few endpoints remain healthy. Left unset, panic mode sends traffic to all endpoints including
the unhealthy ones. Set to `true`, the cluster fails every request instead, which keeps load
off a destination that is already failing.

The panic threshold itself is set on
[MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/), not here.

## Probes per protocol

Configure the check for the destination's declared protocol:

| Destination protocol | Check selected |
| --- | --- |
| HTTP or HTTP/2 | Enabled `http` configuration. |
| gRPC | Enabled `grpc` configuration. |
| TCP | Enabled `tcp` configuration. |

For an HTTP or gRPC destination, TCP fallback requires both an explicitly disabled
protocol-specific check and an enabled `tcp` block. A `tcp` block alone does not make
every HTTP or gRPC destination use a TCP check.

A narrower policy inherits settings it omits. For example, overriding only `interval` keeps
the broader policy's HTTP path and thresholds. To stop an inherited HTTP check, set
`http.disabled: true`; check whether an inherited TCP block then enables fallback.

### HTTP

HTTP destinations use HTTP/1 probes; HTTP/2 destinations use HTTP/2 probes. Check the service's
declared protocol when probes fail even though a manual request succeeds.

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

`send` is the literal string to write, and `receive` lists literal strings expected in the
response. The current implementation sends those strings as bytes; it does not decode base64,
despite the wording in the generated field descriptions. Each receive string must appear in
order, though the strings need not be adjacent.

Leaving `receive` empty or unset makes the probe connect-only, and it succeeds as soon as a
TCP connection is established.

A connect-only check proves that the endpoint accepts connections, not that the application
can complete an operation.

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

The destination must implement the gRPC health-check service. A working application RPC does
not by itself provide that service.

## Observe probe failures

Set `default.eventLogPath: /dev/stdout` to write health-check events to the proxy's output.
Set `default.alwaysLogHealthCheckFailures: true` while diagnosing repeated failures.
On Kubernetes, read the selected client Pod's `kuma-sidecar` logs. These events describe
probes performed by that client, not by the destination proxy.

## Validate endpoint health

1. Make one destination endpoint fail the configured health check while leaving another
   endpoint healthy.
1. Observe the unhealthy event and confirm that new traffic stops reaching the failing endpoint,
   provided the pool has not entered panic mode.
1. Restore the endpoint, wait for `healthyThreshold` successful probes, and confirm that it
   receives traffic again.
1. Confirm that a probe timeout is shorter than the interval and that the probe volume is safe
   for the number of client proxies.
1. If `failTrafficOnPanic` is enabled, make enough endpoints unhealthy to enter panic mode and
   confirm that requests fail instead of returning to unhealthy endpoints.

| Unexpected result | Check |
| --- | --- |
| No probes are sent | Check the destination protocol, enabled check block, and policy selectors. |
| Probes are slower than `interval` | Check `noTrafficInterval` for a destination not yet used by this proxy. |
| An unhealthy endpoint still receives traffic | Check panic mode and whether another client proxy has a different health view. |
| Every HTTP check fails | Verify the path, expected status, protocol, and permission for the probing caller. |
