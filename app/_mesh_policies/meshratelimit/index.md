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
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshratelimit"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
- text: MeshFaultInjection policy
  url: "/mesh/policies/meshfaultinjection/"
---

`MeshRateLimit` limits incoming HTTP requests or new TCP connections at the destination
proxy. When the applicable limit has no capacity left, the proxy rejects the request or
connection before it reaches the application.

The limit is enforced by each proxy against its own traffic, using Envoy's
[token bucket](https://www.envoyproxy.io/docs/envoy/latest/api-v3/type/v3/token_bucket.proto).
It does not maintain a shared quota across a service's replicas. Adding replicas adds
capacity; uneven traffic can exhaust one proxy's allowance while another has capacity left.
Size the limit for an individual instance, not for the deployment's total traffic.

Without a matching configured limit, this policy does not restrict the rate. Rate is also
different from concurrency: use [MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/)
to limit work that is active at the same time. A slow application can accumulate concurrent
requests even when its incoming request rate stays below the limit.

## Limit requests to a destination

This policy applies to proxies labeled `app: backend`. For each selected inbound route, it
allows a burst of five requests and replenishes that allowance at five requests per ten seconds:

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

`targetRef` selects the `backend` proxies that count and reject requests. The rule has no
caller match, so all callers using the same inbound route share its bucket on each proxy.
The bucket starts full and holds at most five tokens. Each accepted request consumes one;
a request arriving when the bucket is empty receives `429 Too Many Requests` by default.

This is a burst allowance with replenishment, not a promise that every ten-second window
contains at most five successful requests. Requests arriving over time can consume newly
available tokens. Unused capacity does not accumulate beyond five tokens.

HTTP buckets belong to individual generated routes on each proxy. Different inbounds and
client-specific routes do not share one service-wide bucket. In particular, a new client
connection does not reset an HTTP route's allowance.

## Where this policy applies

A rate limit belongs to the proxy doing the accepting, so this is an inbound policy, configured
on the proxy being protected rather than on its clients.

Which field carries the configuration depends on what `spec.targetRef` selects, and the two
combinations do not overlap:

{% table %}
columns:
  - title: "`spec.targetRef.kind`"
    key: kind
  - title: Configuration goes in
    key: field
  - title: What it limits
    key: limits
rows:
  - kind: "`Dataplane`, with `labels`"
    field: "`rules`. Defining `to` is rejected with `spec.to (): must not be defined`."
    limits: "Traffic arriving at the selected proxies. Omit `labels` to select every proxy in the mesh."
  - kind: "`Mesh`"
    field: "`to`, whose `targetRef` accepts `kind: Mesh` and nothing else. Defining `rules` is rejected with `spec.rules (): must not be defined`."
    limits: "The API accepts this form, but the v3 proxy implementation applies limits from rules, not to. Migrate to the Dataplane/rules form."
{% endtable %}

Setting both `to` and `rules` is rejected with
`field 'to' must be empty when 'rules' is defined`, and setting neither with
`at least one of 'to' or 'rules' has to be defined`.

A mesh-wide inbound limit is therefore written as `kind: Dataplane` with no `labels`, not as
`kind: Mesh`.

To limit one inbound, set `targetRef.sectionName` to its `name` in the destination
Dataplane's `spec.networking.inbound[]`. If it has no name, use its port as a string, such
as `"8080"`. On a zone proxy, use the listener's `name` from
`spec.networking.listeners[]`. Without `sectionName`, eligible listeners on the selected
proxies are covered; they do not share a single bucket.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## HTTP limits

`local.http.requestRate` sets the cap: `num` requests per `interval`. `num` must be greater
than 0 and `interval` greater than 50ms.

`local.http.onRateLimit` decides what a rejected request receives. Without it the proxy answers
`429 Too Many Requests`.

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

Use an HTTP error status such as `429` or `503`. Although the policy validator accepts a
positive `status`, Envoy uses `429` when the configured status is below `400`.
`headers.set` replaces a header already on the response and `headers.add` appends to it,
each taking up to 16 entries. Header names are lower case only. See the
[Envoy response-status behavior](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/local_ratelimit/v3/local_rate_limit.proto#extensions-filters-http-local-ratelimit-v3-localratelimit).

Returning `503` can trigger a caller's retry policy, increasing attempts while the
destination is already rejecting work. Keep the default `429` unless the client requires
another status, and test the client's retry and backoff behavior.

`onRateLimit` only customizes a rejection. It does not create a limit without an effective
`requestRate`, either in the same rule or inherited from a broader configuration.

## TCP limits

`local.tcp.connectionRate` caps new connections rather than requests, with the same `num` and
`interval` fields. It applies to any inbound, including one carrying HTTP traffic, where it
limits how often clients may connect rather than what they may send over an established
connection.

When the connection bucket is empty, the proxy closes the new connection; it cannot return
an HTTP rate-limit response at this stage. Existing connections remain open. A long-lived
connection can carry many requests, so a connection-rate limit is not a request-rate limit
or a cap on the total number of open connections.

An inbound served as plain TCP has no HTTP filters, so `local.http` has no effect there. See
[Universal inbounds must declare their protocol](/mesh/migrate-policies-to-3/#universal-inbounds-must-declare-their-protocol)
for the case where an inbound is served as TCP unintentionally.

## Give one workload identity a separate request limit

`rules[].matches` narrows a rule to requests from particular clients, matched on `spiffeID`
(`Exact` or `Prefix`) or `sni` (`Exact` only). A rule with no `matches` applies to every client.

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

Each `matches` entry needs at least one of `spiffeID` or `sni`, and a `spiffeID` must set
`type`.

On each destination proxy, requests matching the batch identity use the 10-per-second
bucket. Other callers use the shared 1000-per-second bucket. Batch requests do not also
consume the fallback bucket: this is a separate allowance, not a 10-request share of a
1000-request total.

All replicas presenting the same batch identity share that matching route's bucket on a
given destination proxy. A `Prefix` match similarly gives the matched group one allowance
per route and proxy; it does not create a new bucket for every identity in that group.

Copy the complete SPIFFE URI from the batch workload's certificate into
`rules[].matches[].spiffeID.value`. Do not assume either the example's trust domain or its
Kubernetes path: a custom [MeshIdentity](/mesh/policies/meshidentity/) template can change
both. The destination must authenticate the caller through mesh mTLS; plaintext traffic
has no SPIFFE identity to match. Rate limiting does not grant access, so the caller must
also be allowed by [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/).

A rule that matches on `spiffeID` cannot carry `local.tcp`, and doing so is rejected with
`can't be specified when matches contain spiffeID because this field cannot be conditioned on
source identity`. The client's identity comes out of the TLS handshake, which a connection-level
limit is counting rather than inspecting. Limit connections with a rule that has no `spiffeID`
match, and limit an individual client's requests with `local.http`.

## How overlapping HTTP limits combine

The catch-all configuration supplies the base settings. A matching identity rule can
override those settings: `Exact` identity matches take precedence over `Prefix` matches.
Within either match type, a match that also specifies SNI is more specific. Among prefixes
with the same SNI condition, a longer matching prefix takes precedence over a shorter one.
Settings omitted by the more specific
configuration can be inherited; limits are not added together or reduced to the smallest value.

For example, a catch-all rule can set `requestRate` and a custom response header. An exact
batch-identity rule that changes only `requestRate` uses its own rate and keeps the response
header. If the broader configuration sets `disabled: true`, set `disabled: false` explicitly
when enabling a narrower limit; setting a new rate alone does not clear the inherited flag.

If separate policies configure the same traffic, policy precedence resolves conflicting
fields. Avoid relying on resource creation order; see
[How policies select traffic](/mesh/policy-targeting/) for policy roles and tie-breakers.

## Turn a limit off for part of the traffic

`disabled: true` on `local.http` or `local.tcp` removes the limit that a broader policy set,
which is how one client or one inbound is exempted without narrowing the original policy.

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
            value: spiffe://default.default.mesh.local/ns/observability/
      default:
        local:
          http:
            disabled: true
```
{% endpolicy_yaml %}

Replace the prefix with the shared beginning of the monitoring workloads' actual SPIFFE
IDs. Keep the trailing `/` so that `observability` does not also match namespace names such
as `observability-test`. With the default Kubernetes path, this exempts every service
account in the `observability` namespace, not just one monitoring workload.

The exception disables HTTP rate limiting only. It does not bypass a separate TCP limit,
traffic permissions, or an even more specific HTTP rule that enables a limit again.

## Validate the rate limit

1. Confirm normal connectivity before applying the policy. Keep the test on one destination
   replica and inbound so load balancing does not spread requests across independent buckets.
1. Send requests below the configured rate and confirm that they reach the application.
1. Send a burst that exhausts the bucket and confirm that the proxy returns the configured
   status and headers without sending the rejected requests to the application. Check
   `x-envoy-ratelimited` to help distinguish proxy rejections from application-generated errors.
1. Pause traffic for at least the configured interval, then confirm that requests succeed again.
1. Repeat the test against each destination replica. The limit is local to each proxy, not
   shared across the deployment.
1. For a client-specific HTTP rule, send the same traffic from a non-matching SPIFFE ID and
   confirm that it uses the fallback rule. Without a fallback limit, unmatched callers are
   not rate-limited by this policy.
1. For TCP, open fresh connections to test exhaustion. Reusing a connection cannot test a
   connection-rate limit.

If requests exceed the rate you expected, check how many destination replicas, inbounds,
and matched routes the test uses, and account for the initial burst allowance. If no HTTP
requests are rejected, check the inbound protocol and any inherited `disabled` setting.
Count client retry attempts as requests too; a final successful call can conceal earlier
rate-limit rejections.
