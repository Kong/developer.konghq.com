---
title: Mesh Rate Limit
name: MeshRateLimits
products:
- mesh
description: Cap how many requests or connections a proxy accepts in a given interval, and choose what a rejected request receives.
content_type: plugin
icon: meshratelimit.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshratelimit"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
- text: MeshFaultInjection policy
  url: "/mesh/policies/meshfaultinjection/"
---

The `MeshRateLimit` policy limits incoming traffic at the destination proxy:

* With `local.http`, it limits HTTP requests.
* With `local.tcp`, it limits new TCP connections.

When a limit has no capacity left, the proxy rejects the request or connection before it
reaches the application.

Each proxy enforces the limit on its own traffic, using Envoy's
[token bucket](https://www.envoyproxy.io/docs/envoy/latest/api-v3/type/v3/token_bucket.proto).
Replicas don't share a quota, so adding replicas adds capacity, and uneven traffic can use up
one proxy's allowance while another still has some. Size the limit for one instance, not for
the whole deployment.

Proxies that no `MeshRateLimit` selects aren't rate limited. Rate also isn't concurrency: a
slow application can pile up concurrent requests while staying under the rate limit. To limit
concurrent work, use [MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/).

## Limit requests to a destination

The following example allows each inbound route on proxies labeled `app: backend` a burst of
five requests, refilled at five requests per ten seconds:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshRateLimit
mesh: default
name: backend-rate-limit
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - default:
        local:
          http:
            requestRate:
              num: 5
              interval: 10s
```
{% endpolicy_yaml %}

What each field does:

* `targetRef` selects the `backend` proxies that count and reject requests.
* `rules` has no caller match, so all callers on the same inbound route share one bucket on
  each proxy.
* `requestRate` sets the bucket size and refill rate. The bucket starts full with five tokens,
  each accepted request uses one, and a request that arrives when it's empty gets
  `429 Too Many Requests` by default.

This is a burst allowance with refill, not a cap of five successful requests per ten-second
window. Requests spread over time can use newly refilled tokens, and unused capacity never
grows beyond five tokens.

Each generated route on each proxy has its own HTTP bucket. Different inbounds and
client-specific routes don't share a service-wide bucket, and a new client connection doesn't
reset a route's allowance.

## Target selection

A rate limit is an inbound policy: configure it on the proxy being protected, not on its
clients. Set `spec.targetRef.kind` to `Dataplane` and put the limits in `rules`. Use `labels` to
select the protected proxies, or omit `labels` to select every proxy in the policy's scope.
`kind: Mesh`, or an omitted `targetRef`, isn't accepted with `rules`: the policy is rejected with
`spec.rules: must not be defined`.

To limit a whole zone, use `kind: Dataplane` with no `labels`, and create the policy in
`{{site.mesh_namespace}}`. In an application namespace, the policy only applies to the proxies
in that namespace. To cover every zone, create the policy on the global control plane. For
more information, see [Where a policy applies](/mesh/policy-targeting/#where-a-policy-applies).

To limit one inbound, set `targetRef.sectionName` to one of the following:

* The inbound's `name` in the destination Dataplane's `spec.networking.inbound[]`.
* The inbound's port as a string, such as `"8080"`, if it doesn't have a name.
* On a zone proxy, the listener's `name` in `spec.networking.listeners[]`.

Without `sectionName`, the policy covers all eligible listeners on the selected proxies, each
with its own bucket.

## HTTP limits

`local.http.requestRate` sets the limit: `num` requests per `interval`. `num` must be greater
than 0, and `interval` greater than 50ms.

`local.http.onRateLimit` sets the response a rejected request gets. It only customizes the
rejection, so it needs a `requestRate` in the same rule or inherited from a broader one. Without
`onRateLimit`, the proxy returns `429 Too Many Requests`.

The following example returns `503` with an `x-kuma-rate-limited: true` header when the limit
is reached:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshRateLimit
mesh: default
name: backend-rate-limit-response
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - default:
        local:
          http:
            requestRate:
              num: 5
              interval: 10s
            onRateLimit:
              status: 503
              headers:
                set:
                  - name: x-kuma-rate-limited
                    value: "true"
```
{% endpolicy_yaml %}

`onRateLimit` accepts the following fields:

* `status`: an HTTP error status such as `429` or `503`. The validator accepts any positive
  value, but a value below `400` produces a deprecation warning on apply, and Envoy uses `429`
  for it. For more information, see
  [Envoy's local rate limit reference](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/local_ratelimit/v3/local_rate_limit.proto#extensions-filters-http-local-ratelimit-v3-localratelimit).
* `headers.set`: replaces a header already on the response. Up to 16 entries.
* `headers.add`: appends to a header. Up to 16 entries.

Header names must be lowercase.

A `503` can trigger the caller's retry policy and add more attempts while the destination is
already rejecting work. Keep the default `429` unless the client needs another status, and
test the client's retry and backoff behavior.

## TCP limits

`local.tcp.connectionRate` limits new connections instead of requests, with the same `num` and
`interval` fields. It applies to any inbound, including HTTP ones, where it limits how often
clients connect, not what they send on an open connection.

When the bucket is empty, the proxy closes the new connection without an HTTP response.
Existing connections stay open. Because a long-lived connection can carry many requests, a
connection-rate limit isn't a request-rate limit or a cap on open connections.

An inbound served as plain TCP has no HTTP filters, so `local.http` has no effect there. For
more information, see
[Universal inbounds must declare their protocol](/mesh/migrate-policies-to-3/#universal-inbounds-must-declare-their-protocol).

## Give one workload identity a separate request limit

`rules[].matches` narrows a rule to requests from particular clients. Each `matches` entry
needs `spiffeID`, `sni`, or both:

* `spiffeID`: `Exact` or `Prefix`. `type` is required.
* `sni`: `Exact` only.

A rule with no `matches` applies to every client.

The following example gives the `batch` service account its own limit of 10 requests per second,
and every other caller a shared limit of 1000 requests per second:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshRateLimit
mesh: default
name: backend-limit-batch-client
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - matches:
        - spiffeID:
            type: Exact
            value: spiffe://default.default.mesh.local/ns/kong-mesh-demo/sa/batch
      default:
        local:
          http:
            requestRate:
              num: 10
              interval: 1s
    - default:
        local:
          http:
            requestRate:
              num: 1000
              interval: 1s
```
{% endpolicy_yaml %}

Batch requests don't use the fallback bucket, so this is a separate allowance, not a share
of the 1000-request total. On each destination proxy, all replicas presenting the batch identity
share one bucket per route. A `Prefix` match also gives the whole matched group one bucket per
route and proxy, not one bucket per identity.

Copy the full SPIFFE URI from the batch workload's certificate into
`rules[].matches[].spiffeID.value`. A custom [MeshIdentity](/mesh/policies/meshidentity/)
template can change both the trust domain and the path in the example. The caller must use
mesh mTLS, because plaintext traffic has no SPIFFE identity to match. Rate limiting doesn't
grant access, so [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) must also allow
the caller.

A rule that matches on `spiffeID` can't use `local.tcp`, because the client identity comes from
the TLS handshake, which a connection-level limit counts instead of inspecting. Limit connections in a rule
without a `spiffeID` match, and limit one client's requests with `local.http`.

## Overlapping HTTP limits

The catch-all rule supplies the base settings, and a matching identity rule can override them.
The most specific match wins:

* `Exact` identity matches win over `Prefix` matches.
* Within either type, a match that also specifies SNI is more specific.
* Among prefixes with the same SNI condition, the longer prefix wins.

The more specific rule inherits any setting it leaves out. Limits aren't added together or
reduced to the smallest value. For example, if a catch-all rule sets `requestRate` and a custom
response header, an exact batch-identity rule that only changes `requestRate` keeps that header.

If the broader configuration sets `disabled: true`, set `disabled: false` explicitly on the
narrower limit. A new rate alone doesn't clear the inherited flag.

When separate policies configure the same traffic, policy precedence resolves conflicting
fields, not creation order. For more information, see
[Policy precedence](/mesh/policy-targeting/#policy-precedence).

## Turn a limit off for part of the traffic

To exempt one client or one inbound without narrowing the original policy, set
`disabled: true` on `local.http` or `local.tcp`. The following example turns off the HTTP limit
for every service account in the `observability` namespace:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshRateLimit
mesh: default
name: backend-exempt-monitoring
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - matches:
        - spiffeID:
            type: Prefix
            value: spiffe://default.default.mesh.local/ns/observability/sa
      default:
        local:
          http:
            disabled: true
```
{% endpolicy_yaml %}

Replace the prefix with the start of your monitoring workloads' actual SPIFFE IDs. Keep the
`/sa` suffix so the prefix doesn't also match namespaces such as `observability-test`. The value
must be a valid SPIFFE ID, so it can't end in `/`.

The exception only turns off HTTP rate limiting. It doesn't bypass a TCP limit, traffic
permissions, or a more specific HTTP rule that turns a limit back on.

## Validating the rate limit

1. Confirm normal connectivity before applying the policy. Test against one destination
   replica and inbound, so load balancing doesn't spread requests across separate buckets.
1. Send requests under the limit and confirm that they reach the application.
1. Send a burst that empties the bucket, and confirm that the proxy returns the configured
   status and headers without forwarding the rejected requests. The `x-envoy-ratelimited`
   header helps tell proxy rejections apart from application errors.
1. Pause for at least the configured interval, and confirm that requests succeed again.
1. Repeat against each destination replica, because each proxy has its own limit.
1. For a client-specific HTTP rule, send the same traffic from a non-matching SPIFFE ID and
   confirm that it uses the fallback rule. Without a fallback rule, unmatched callers aren't
   rate limited by this policy.
1. For TCP, open new connections to test the limit. Reusing a connection doesn't test a
   connection-rate limit.

{% table %}
columns:
  - title: Unexpected result
    key: unexpected
  - title: Check
    key: check
rows:
  - unexpected: "More requests succeed than expected"
    check: "Count the destination replicas, inbounds, and matched routes in the test, and account for the initial burst."
  - unexpected: "No HTTP requests are rejected"
    check: "The inbound protocol and any inherited `disabled` setting."
  - unexpected: "The client reports success but the limit was hit"
    check: "Count client retries as requests. A final successful call can hide previous rate-limit rejections."
{% endtable %}
