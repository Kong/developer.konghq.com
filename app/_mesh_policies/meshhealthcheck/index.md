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
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshhealthcheck"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
- text: MeshRetry policy
  url: "/mesh/policies/meshretry/"
---

The `MeshHealthCheck` policy makes a client proxy probe a destination's endpoints on a
schedule, and stop sending traffic to the ones that fail. Unlike
[MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/) outlier detection, which judges
endpoints from real traffic, probes run even when there's little traffic to judge by.

Each selected client proxy keeps its own health view, so another proxy can reach a different
decision. Marking an endpoint unhealthy doesn't delete its Pod or change Kubernetes readiness.
Proxies that no `MeshHealthCheck` selects send no probes.

## Probe a destination over HTTP

The following example makes proxies labeled `app: web` probe `/health` on the endpoints of
`backend`. The backend must return 200 on that path when it can serve traffic. Every
selected client proxy probes each endpoint, so use a lightweight endpoint:

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

What each field does:

* `targetRef` selects the proxies that send probes: `Mesh`, or `Dataplane` with `labels`.
* `to[].targetRef` selects the destination they probe: `Mesh`, `MeshService`,
  `MeshExternalService`, or `MeshMultiZoneService`. `MeshHTTPRoute` isn't accepted, because a
  probe addresses an endpoint, not a route.
* `interval` and `timeout` set how often to probe and how long to wait for each response.
* `unhealthyThreshold: 3` marks an endpoint unhealthy after three network failures or timeouts
  in a row. A response outside `expectedStatuses` can mark it unhealthy immediately.
* `healthyThreshold: 1` marks it healthy again after one successful probe.

The policy has no `rules`, because a caller performs the health check. Each `default` needs
at least one of `http`, `tcp`, or `grpc`.

## Scheduling and thresholds

`default` accepts the following scheduling fields:

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
    governs: "Time between probes."
    default: "`1m`"
  - field: "`timeout`"
    governs: "Time to wait for a probe response."
    default: "`15s`"
  - field: "`unhealthyThreshold`"
    governs: "Failed probes in a row before an endpoint is unhealthy."
    default: "5"
  - field: "`healthyThreshold`"
    governs: "Successful probes in a row before an endpoint is healthy again."
    default: "1"
  - field: "`noTrafficInterval`"
    governs: "Probe interval for a destination that has never received traffic. Takes precedence over `interval`."
    default: "`60s`"
  - field: "`reuseConnection`"
    governs: "Whether probes reuse the connection."
    default: "`true`"
{% endtable %}

Thresholds don't give an exact detection deadline, because probe duration, jitter, and the
no-traffic interval affect timing, and HTTP status failures can bypass the threshold. For more
information, see
[Envoy's health-check behavior](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/health_check.proto.html).

Estimate probe load before shortening the interval. For example, 100 client proxies checking
10 endpoints every 10 seconds send about 100 probes per second to the destination.

### Spreading out the probes

Proxies probing on the same schedule send traffic in bursts. To spread it out, use the
following fields:

* `initialJitter`: delays the first probe by a random amount up to this value, which staggers
  proxies that start together.
* `intervalJitter`: adds a random delay up to this duration to each interval.
* `intervalJitterPercent`: adds jitter calculated as a percentage of `interval`. Setting it
  with `intervalJitter` combines both.

### Behavior in panic mode

When too few endpoints are healthy, Envoy enters panic mode. `failTrafficOnPanic` controls what
happens then:

* Unset: traffic goes to all endpoints, including unhealthy ones.
* `true`: every request fails, which keeps load off a destination that's already failing.

The panic threshold itself is set on [MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/).

## Probes per protocol

The proxy runs the check that matches the destination's declared protocol. An HTTP or gRPC destination falls back to a TCP check only when its protocol-specific check is explicitly disabled and a `tcp` block is enabled.

### HTTP

HTTP destinations get HTTP/1 probes, and HTTP/2 destinations get HTTP/2 probes. If probes fail
but a manual request succeeds, check the service's declared protocol.

`http` accepts the following fields:

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
    governs: "Response statuses treated as healthy, from `100` to `599`."
    default: "`200` only"
  - field: "`requestHeadersToAdd`"
    governs: "Headers to `set` (replace) or `add` (append) on each probe."
    default: "none"
{% endtable %}

### TCP

`tcp` accepts the following fields:

* `send`: a literal string to write.
* `receive`: literal strings expected in the response, in order but not necessarily adjacent.

Both are sent and compared as plain bytes.

Without `receive`, the probe only checks that a TCP connection opens. That proves the endpoint
accepts connections, not that the application works.

### gRPC

`grpc` accepts the following fields:

* `serviceName`: passed to the destination's gRPC health service.
* `authority`: the `:authority` header on the probe. Defaults to the name of the check's
  cluster.

The destination must implement the gRPC health-check service.

## Observe probe failures

To log health-check events, set the following fields under `default`:

* `eventLogPath: /dev/stdout`: writes events to the proxy's output.
* `alwaysLogHealthCheckFailures: true`: logs every failure while you diagnose repeated
  failures.

On Kubernetes, read the client Pod's `kuma-sidecar` logs. The events describe probes sent by
that client, not by the destination proxy.

## Overlapping policies

A narrower policy inherits the settings it omits. For example, overriding only `interval` keeps
the broader policy's HTTP path and thresholds. To stop an inherited HTTP check, set
`http.disabled: true`, then check whether an inherited `tcp` block enables TCP fallback.

## Validating endpoint health

1. Make one destination endpoint fail the health check while another stays healthy.
1. Confirm the unhealthy event, and that new traffic stops reaching the failing endpoint unless
   the pool is in panic mode.
1. Restore the endpoint, wait for `healthyThreshold` successful probes, and confirm that it
   receives traffic again.
1. Confirm that `timeout` is shorter than `interval`, and that the probe volume is safe for the
   number of client proxies.
1. If `failTrafficOnPanic` is enabled, make enough endpoints unhealthy to enter panic mode, and
   confirm that requests fail instead of reaching unhealthy endpoints.

{% table %}
columns:
  - title: Unexpected result
    key: unexpected
  - title: Check
    key: check
rows:
  - unexpected: "No probes are sent"
    check: "The destination protocol, the enabled check block, and the policy selectors."
  - unexpected: "Probes are slower than `interval`"
    check: "`noTrafficInterval`, for a destination this proxy hasn't used yet."
  - unexpected: "An unhealthy endpoint still receives traffic"
    check: "Panic mode, and whether another client proxy has a different health view."
  - unexpected: "Every HTTP check fails"
    check: "The path, expected status, protocol, and permission for the probing caller."
{% endtable %}
