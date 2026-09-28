---
title: Mesh Load Balancing Strategy
name: MeshLoadBalancingStrategies
products:
- mesh
description: Choose the load balancing algorithm for a destination, pin requests to a host, and set how far traffic may travel to reach it.
content_type: plugin
icon: policy.svg
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshloadbalancingstrategy"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
- text: MeshHealthCheck policy
  url: "/mesh/policies/meshhealthcheck/"
---

`MeshLoadBalancingStrategy` decides which of a destination's endpoints a client's request goes
to. It covers three separate choices: the algorithm that picks between endpoints, the request
property a consistent-hashing algorithm hashes on, and how strongly a client prefers endpoints
close to it.

The caller's proxy makes this choice independently; there is no central scheduler sharing
load measurements between clients. Routing chooses the destination service first, then
load balancing chooses an endpoint within that destination. This policy does not set the
traffic split between services in a [MeshHTTPRoute](/mesh/policies/meshhttproute/).

Without a configured `loadBalancer`, the generated cluster keeps its existing algorithm.
Set the algorithm explicitly when your application depends on a particular selection
strategy. Omitting `hashPolicies` does not establish session affinity.

## Pin requests to an endpoint by header

This policy applies to proxies labeled `app: frontend` and uses the `x-user` header to
choose a `backend` endpoint. The destination must exist as a `MeshService`, and the caller's
proxy must handle the traffic as HTTP so that it can read the header:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshLoadBalancingStrategy
mesh: default
name: backend-hash-on-user
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        labels:
          kuma.io/display-name: backend
      default:
        loadBalancer:
          type: RingHash
        hashPolicies:
          - type: Header
            header:
              name: x-user
```
{% endpolicy_yaml %}

`targetRef` selects the `frontend` proxies making the requests, and `to[].targetRef` selects the
`backend` destination. `RingHash` chooses an endpoint by hashing `x-user`, so requests carrying
the same header value stay on the same healthy endpoint while the endpoint set is stable.

This is affinity, not durable session storage. Scaling, endpoint health, locality, or
configuration changes can move requests to another endpoint. Different clients can also
have different eligible endpoint sets. Keep session state recoverable when that happens.
If `x-user` is absent, this example produces no hash key and does not pin the request.

## Where this policy applies

`spec.targetRef` selects the client proxies whose outbound requests are balanced, and accepts
`Mesh` or `Dataplane` with `labels`. This is a client-side policy: the endpoint choice is made
by the caller's proxy, so it is configured there.

`spec.to[].targetRef` names the destination, and accepts `Mesh`, `MeshService`,
`MeshExternalService`, `MeshMultiZoneService` and `MeshHTTPRoute`.

For a service with multiple ports, set `to[].targetRef.sectionName` to the relevant port's
`name` in that service's `spec.ports[]`. This selects the destination port, not an inbound
on the caller. For a `MeshHTTPRoute`, a section selects a named route rule.

The algorithm can select endpoints for TCP connections, but `hashPolicies` on this policy
are installed on HTTP routes. `type: Connection` is an HTTP hash input based on source IP;
it does not enable source-IP hashing for arbitrary TCP traffic. An established TCP
connection stays with its selected endpoint rather than being rebalanced for each message.

Two of those kinds are constrained:

- With `kind: MeshHTTPRoute`, only `hashPolicies` is accepted. `loadBalancer` and
  `localityAwareness` are rejected with
  `field is not allowed when targetRef.kind is MeshHTTPRoute, only hashPolicies is supported`.
  Hashing is a per-request decision, so it can be set per route; the algorithm and the locality
  preference belong to the destination's cluster, which a route does not own.
- `localityAwareness.crossZone` is accepted only with `kind: MeshMultiZoneService` — see
  [MeshMultiZoneService](/mesh/meshmultizoneservice/). On any
  other kind it is rejected with
  `crossZone is only supported when targetRef.kind is MeshMultiZoneService`.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## Load balancing algorithms

`loadBalancer.type` chooses the algorithm, and the object named after it carries that
algorithm's settings.

{% table %}
columns:
  - title: "`type`"
    key: type
  - title: How it picks an endpoint
    key: how
  - title: Settings
    key: settings
rows:
  - type: "`RoundRobin`"
    how: "Each endpoint in turn."
    settings: "None."
  - type: "`LeastRequest`"
    how: "With equal endpoint weights, compares randomly selected endpoints and chooses the least busy. With unequal weights, adjusts weighted selection using active request counts."
    settings: "`choiceCount`, how many to compare, at least 2 and 2 by default. `activeRequestBias` scales how much an endpoint's in-flight requests reduce its weight, 0 or greater."
  - type: "`RingHash`"
    how: "Hashes a request property and walks a ring of endpoint hashes to the nearest one, so the same property reaches the same endpoint."
    settings: "`hashFunction`, `XXHash` or `MurmurHash2`. `minRingSize` and `maxRingSize`, between 1 and 8000000, defaulting to 1024 and 8000000."
  - type: "`Random`"
    how: "An endpoint at random. With no health checking in place this spreads load better than round robin, because it does not favour whichever endpoint follows a failed one."
    settings: "None."
  - type: "`Maglev`"
    how: "Consistent hashing using a fixed-size lookup table. It generally builds and looks up faster than a large ring, but can move more keys when endpoints change."
    settings: "`tableSize`, a prime number up to 5000011, 65537 by default."
{% endtable %}

`RingHash` and `Maglev` need `hashPolicies` to hash on. Without one they have no key, and
requests are not pinned to anything.

Use `LeastRequest` when HTTP requests have different processing times; use a hashing
algorithm when affinity matters. A heavily used hash key can concentrate load on one
endpoint, so hashing does not guarantee even request counts. For algorithm tradeoffs, see
[Envoy load balancers](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/load_balancers).

## Hash policies

`hashPolicies` is a list of request properties to hash, evaluated in order.

{% table %}
columns:
  - title: "`type`"
    key: type
  - title: What it hashes
    key: what
rows:
  - type: "`Header`"
    what: "`header.name`, a request header."
  - type: "`Cookie`"
    what: "`cookie.name`. With `ttl` set, a client that arrives without the cookie is given one, which pins it for subsequent requests. `cookie.path` must be an absolute path."
  - type: "`Connection`"
    what: "The client's source IP, with `connection.sourceIP: true`."
  - type: "`QueryParameter`"
    what: "`queryParameter.name`, a URL query parameter. Names are case sensitive."
  - type: "`FilterState`"
    what: "`filterState.key`, an `Envoy::Hashable` object another filter put in the per-request state."
{% endtable %}

A property that is absent from a request produces no hash, and the next policy in the list is
tried. `terminal: true` stops the list once a hash exists, which saves evaluating the rest.

Without `terminal: true`, properties that produce hashes contribute to a combined hash;
the list is not automatically a sequence of fallback choices. For example, put a terminal
header policy first and a cookie policy second to use the cookie only when the header is
absent. Both the chosen algorithm and a usable hash input are needed for affinity.

Source-IP hashing uses the address seen by the proxy, not a user identity or an arbitrary
forwarded-for header. Callers sharing an address can therefore share a hash key. Cookie
hashing requires the client to retain and return the cookie.

## When policies overlap

More specific destination configuration overrides conflicting fields from a broader
configuration; omitted fields can remain inherited. Lists such as `hashPolicies`,
`affinityTags`, and `failover` are replaced rather than appended.

For example, a mesh-wide rule can choose `RingHash`, while a rule for `backend` supplies
the `x-user` hash policy. Backend traffic uses both settings. A still more specific HTTP
route can replace the hash list with a cookie hash, but cannot change the cluster's
algorithm. Conversely, changing the algorithm to `RoundRobin` makes an inherited hash
policy ineffective for affinity. See [policy targeting](/mesh/policy-targeting/) for the
full precedence rules.

## Locality awareness

Locality awareness is on unless it is turned off, so a client prefers endpoints in its own zone
and uses lower-priority remote endpoints as the local priority loses healthy capacity.
This is based on endpoint availability, not a measurement of spare CPU or request latency.
`localityAwareness.disabled: true` removes this automatic local-zone preference.

`localZone` and `crossZone` take effect regardless of `disabled`, since each describes
explicit grouping. To distribute across zones without locality grouping, also remove any
inherited `localZone` and `crossZone` configuration rather than setting `disabled` alone.

### Priorities inside a zone

`localZone.affinityTags` groups local endpoints by values they share with the caller. For
each key, the control plane reads the selected caller Dataplane's label value and compares
it with endpoint metadata. An endpoint joins the first matching group. These groups share
traffic by weight at the same priority; they are not tried one after another on failure.

Place this fragment under a destination's `to[].default`. It prefers endpoints on the same
host as the caller, then endpoints in the same infrastructure zone:

```yaml
localityAwareness:
  localZone:
    affinityTags:
      - key: kubernetes.io/hostname
      - key: topology.kubernetes.io/zone
```

`weight` sets each group's relative share. Without explicit weights, the generated weights
decrease tenfold down the list: with two tags they are 90 and 9, with unmatched local
endpoints retaining a fallback group weight of 1. These are relative weights, not fixed
percentages when groups are absent or unhealthy. Weights are all-or-nothing:
setting some and not others is rejected with `all or none affinity tags should have weight`.

Check both sides: the caller Dataplane must carry the label, and destination endpoint
metadata must carry the corresponding value. Endpoint metadata can come from resource
labels or inbound tags. A key missing from the caller creates no affinity group. A key
present on the caller but on no endpoint attracts no traffic. Node labels are not useful
here unless they are also available in the workload's Dataplane labels and endpoint metadata.

Adding explicit locality groups rebuilds the endpoint priorities. Include an appropriate
`crossZone.failover` list on a `MeshMultiZoneService` if remote endpoints must remain
eligible; a local-only grouping does not automatically preserve remote fallback.

### Falling back to other zones

`crossZone.failover` is a list of rules in priority order, naming which zones a client may
reach once its local endpoints are not enough. It applies only to a
`MeshMultiZoneService` destination.

This fragment belongs under `to[].default` for a `MeshMultiZoneService`. Replace the zone
names with the mesh zones where that service has endpoints:

```yaml
localityAwareness:
  crossZone:
    failover:
      - from:
          zones: ["us-1", "us-2"]
        to:
          type: Only
          zones: ["us-1", "us-2"]
      - to:
          type: Only
          zones: ["eu-1"]
    failoverThreshold:
      percentage: 50
```

`from.zones` limits a rule to clients in those zones, and applies to every zone when omitted.
`to.type` says which zones the rule sends traffic to:

{% table %}
columns:
  - title: "`to.type`"
    key: type
  - title: Zones it selects
    key: zones
rows:
  - type: "`Only`"
    zones: "Those named in `to.zones`, which must not be empty."
  - type: "`AnyExcept`"
    zones: "Every available zone except those named in `to.zones`, which must not be empty."
  - type: "`Any`"
    zones: "Every available zone. `to.zones` must be empty."
  - type: "`None`"
    zones: "No zone. `to.zones` must be empty."
{% endtable %}

A remote zone that no applicable rule selects receives no traffic. Local endpoints retain
the highest priority independently of this list. A remote zone named by several applicable
rules takes the first matching priority. `None` contributes no remote endpoints; it does
not cancel zones selected by another rule.

`failoverThreshold.percentage` controls when a priority's healthy capacity is insufficient
and traffic starts moving to the next priority. The default is `50`: with ten endpoints
still present in the priority, fewer than five healthy endpoints starts spillover.
This is not an all-at-once switch; traffic can be shared between priorities during degradation.

{:.warning}
> The current v3 implementation rounds the threshold when converting it to Envoy's
> `overprovisioning_factor`. For example, `70` generates a factor of `100`, not a precise
> 70% threshold. Do not rely on an exact custom percentage without checking the generated
> `overprovisioning_factor` and testing failover. `0` uses the default factor rather than
> disabling failover.

Deciding which endpoints are live is the job of
[MeshHealthCheck](/mesh/policies/meshhealthcheck/) or
[MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/) outlier detection. Service discovery
can also remove endpoints. Removal is different from marking an existing endpoint unhealthy:
it changes the endpoint set against which capacity is calculated. Test the failure mode
you expect in production rather than assuming scale-down and failed health checks behave identically.

## Validate endpoint selection

1. Use a destination with multiple endpoints and a response or access log identifying the
   serving instance. Confirm that the caller proxy has the intended algorithm and hash
   policy in its generated cluster and HTTP route configuration.
1. Send repeated requests from the same caller with the same hash input and confirm that
   they reach the same endpoint while eligibility and configuration remain stable.
1. Change the header, cookie, query parameter, or source IP used by the hash policy and confirm
   that the request can select a different endpoint.
1. Repeat without the hash input to verify the fallback behavior. Test many different keys;
   two different keys can legitimately select the same endpoint.
1. Remove one endpoint and measure how many keys move. Consistent hashing reduces disruption,
   but does not guarantee that only keys previously assigned to the removed endpoint move.
1. For locality awareness, identify the zone serving the response, make the local endpoint set
   unhealthy, and confirm that traffic follows the configured failover priority.
1. Confirm that a remote zone omitted from every applicable `crossZone.failover` rule receives
   no traffic. Check each caller zone separately because `from.zones` changes the rules that apply.

If affinity fails, first check that the traffic is parsed as HTTP, the hash input is
present, and the effective cluster uses `RingHash` or `Maglev`. If locality fails, compare
the caller's labels with endpoint metadata and inspect endpoint priorities and health.
Use fresh TCP connections when testing TCP distribution; an existing connection does not move.
