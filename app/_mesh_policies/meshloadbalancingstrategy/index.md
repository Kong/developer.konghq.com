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
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshloadbalancingstrategy"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
- text: MeshHealthCheck policy
  url: "/mesh/policies/meshhealthcheck/"
---

The `MeshLoadBalancingStrategy` policy decides which of a destination's endpoints a client's
request goes to. It controls three things:

* With `loadBalancer`, it sets the algorithm that picks an endpoint.
* With `hashPolicies`, it sets the request property that a consistent-hashing algorithm hashes
  on.
* With `localityAwareness`, it sets how strongly a client prefers endpoints close to it.

Each caller's proxy makes this choice on its own, with no central scheduler sharing load data.
Routing picks the destination service first, then load balancing picks an endpoint in it. To
split traffic between services, use [MeshHTTPRoute](/mesh/policies/meshhttproute/) instead.

Without a `loadBalancer`, the cluster keeps its existing algorithm, so set one explicitly if
your application depends on it. Without `hashPolicies`, there's no session affinity.

## Pin requests to an endpoint by header

The following example makes `frontend` proxies pick a `backend` endpoint by hashing the
`x-user` header. The destination must exist as a `MeshService`, and the caller's proxy must
handle the traffic as HTTP to read the header:

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

What each field does:

* `targetRef` selects the `frontend` proxies that make the requests, because the caller's proxy
  picks the endpoint. It accepts `Mesh`, or `Dataplane` with `labels`.
* `to[].targetRef` selects the `backend` destination. It accepts `Mesh`, `MeshService`,
  `MeshExternalService`, `MeshMultiZoneService`, and `MeshHTTPRoute`. For a service with
  several ports, set `sectionName` to the port's `name` in the service's `spec.ports[]`. This
  selects the destination port, not an inbound on the caller. `sectionName` isn't accepted with
  `MeshHTTPRoute`.
* `RingHash` with the `x-user` hash policy keeps requests with the same header value on the
  same healthy endpoint while the endpoint set is stable. This is affinity, not durable session storage. Scaling, endpoint health, locality, or configuration changes can move requests to another endpoint, and different clients can see different endpoints, so keep session state recoverable. Requests without `x-user` aren't pinned.

## Load balancing algorithms

`loadBalancer.type` sets the algorithm, and the object named after it holds that algorithm's
settings:

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
    how: "Compares randomly chosen endpoints and picks the least busy. With unequal endpoint weights, it adjusts weighted selection by active request counts."
    settings: |
      * `choiceCount`: how many endpoints to compare, at least 2, and 2 by default.
      * `activeRequestBias`: how much in-flight requests reduce an endpoint's weight, 0 or greater.
  - type: "`RingHash`"
    how: "Hashes a request property and picks the nearest endpoint on a hash ring, so the same property reaches the same endpoint."
    settings: |
      * `hashFunction`: `XXHash` or `MurmurHash2`.
      * `minRingSize`: 1 to 8000000, and 1024 by default.
      * `maxRingSize`: 1 to 8000000, and 8000000 by default.
  - type: "`Random`"
    how: "A random endpoint. Without health checks, this spreads load better than round robin, because it doesn't favor the endpoint after a failed one."
    settings: "None."
  - type: "`Maglev`"
    how: "Consistent hashing with a fixed-size lookup table. It's generally faster than a large ring, but can move more keys when endpoints change."
    settings: "`tableSize`: a prime number up to 5000011, and 65537 by default."
{% endtable %}

`RingHash` and `Maglev` need `hashPolicies`. Without them, requests aren't pinned.

Use `LeastRequest` when HTTP requests take different amounts of time, and a hashing algorithm
when affinity matters. A popular hash key can concentrate load on one endpoint, so hashing
doesn't guarantee even load. For more information, see
[Envoy load balancers](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/load_balancers).

## Hash policies

`hashPolicies` lists the request properties to hash, in order. It accepts the following types:

{% table %}
columns:
  - title: "`type`"
    key: type
  - title: What it hashes
    key: what
rows:
  - type: "`Header`"
    what: "A request header, set in `header.name`."
  - type: "`Cookie`"
    what: "A cookie, set in `cookie.name`. With `ttl` set, a client without the cookie gets one, which pins its next requests. `cookie.path` must be an absolute path."
  - type: "`Connection`"
    what: "The client's source IP, with `connection.sourceIP: true`."
  - type: "`QueryParameter`"
    what: "A URL query parameter, set in `queryParameter.name`. Names are case sensitive."
  - type: "`FilterState`"
    what: "An `Envoy::Hashable` object that another filter stored in the request state, set in `filterState.key`."
{% endtable %}

A property missing from the request produces no hash, and the next entry is tried. Entries that
produce a hash are combined, unless one sets `terminal: true`, which stops the list once a hash
exists. For example, to use a cookie only when a header is missing, put a terminal header entry
first and the cookie entry second.

Source-IP hashing uses the address the proxy sees, not a user identity or a forwarded-for
header, so callers sharing an address share a hash key. Cookie hashing requires the client to
return the cookie.

The algorithm also applies to TCP connections, but `hashPolicies` only apply to HTTP routes.
`type: Connection` hashes the source IP of HTTP requests, not of arbitrary TCP traffic. An
established TCP connection stays on its endpoint.

With `to[].targetRef.kind: MeshHTTPRoute`, only `hashPolicies` is accepted. `loadBalancer` and
`localityAwareness` are rejected, because they belong to the destination's cluster, which a
route doesn't own.

## Locality awareness

Locality awareness is on by default. A client prefers endpoints in its own zone, and moves to
lower-priority remote endpoints as local ones lose healthy capacity. This is based on endpoint
availability, not CPU or latency. To turn off the local-zone preference, set
`localityAwareness.disabled: true`.

`localZone` and `crossZone` still apply when `disabled` is set. To spread traffic across zones
without locality grouping, also remove any inherited `localZone` and `crossZone`
configuration.

### Priorities inside a zone

`localZone.affinityTags` groups local endpoints by label values they share with the caller. For
each key, the control plane compares the caller `Dataplane`'s label value with endpoint
metadata. An endpoint joins the first group it matches. Groups share traffic by weight at the
same priority, instead of being tried in order on failure.

The following example prefers endpoints on the caller's host, then endpoints in the same
infrastructure zone. Place it under a destination's `to[].default`:

```yaml
localityAwareness:
  localZone:
    affinityTags:
      - key: kubernetes.io/hostname
      - key: topology.kubernetes.io/zone
```

`weight` sets each group's relative share. Without weights, they decrease tenfold down the
list: with two tags they're 90 and 9, and unmatched local endpoints get 1. These are relative
weights, not fixed percentages. Set weights on all groups or none, because partial weights are
rejected.

The caller `Dataplane` must carry the label, and destination endpoint metadata must carry a
matching value. Endpoint metadata comes from resource labels or inbound tags. A key missing
from the caller creates no group, and a key that no endpoint has gets no traffic. Node labels
only work if they're also in the workload's `Dataplane` labels and endpoint metadata.

Explicit locality groups rebuild endpoint priorities and don't keep remote fallback. If remote
endpoints must stay eligible, add a `crossZone.failover` list on a `MeshMultiZoneService`.

### Falling back to other zones

`crossZone.failover` lists, in priority order, the zones a client can reach when its local
endpoints aren't enough. It's only accepted when `to[].targetRef.kind` is
[MeshMultiZoneService](/mesh/meshmultizoneservice/).

The following example lets clients in `us-1` and `us-2` fail over to those zones first, then
lets every client fail over to `eu-1`. Place it under `to[].default` for a
`MeshMultiZoneService`, and replace the zone names with zones where the service has endpoints:

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

`from.zones` limits a rule to clients in those zones. Without it, the rule applies to every
zone. `to.type` selects the zones a rule sends traffic to:

{% table %}
columns:
  - title: "`to.type`"
    key: type
  - title: Zones it selects
    key: zones
rows:
  - type: "`Only`"
    zones: "The zones in `to.zones`, which can't be empty."
  - type: "`AnyExcept`"
    zones: "Every available zone except those in `to.zones`, which can't be empty."
  - type: "`Any`"
    zones: "Every available zone. `to.zones` must be empty."
  - type: "`None`"
    zones: "No zone. `to.zones` must be empty."
{% endtable %}

A remote zone that no rule selects gets no traffic. Local endpoints always have the highest
priority. A zone named by several rules gets the first matching priority. `None` adds no
remote endpoints, but doesn't cancel zones that another rule selects.

`failoverThreshold.percentage` sets when a priority has too little healthy capacity and traffic
starts moving to the next one. It defaults to `50`: with ten endpoints in a priority, spillover
starts when fewer than five are healthy. Traffic can be shared between priorities during
degradation, instead of switching all at once.

{:.warning}
> The effective threshold can only be 100 divided by a whole number: 100%, 50%, 33.3%, 25%,
> 20%, and so on. Any other value is rounded up to the next one of these, so spillover starts
> earlier than the value you set. For example, `30` behaves like 33.3%, and any value above
> `50`, such as `70`, behaves like 100%: spillover starts as soon as one endpoint in the
> priority is unhealthy. `0` is rejected.

Endpoint health comes from [MeshHealthCheck](/mesh/policies/meshhealthcheck/) or
[MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/) outlier detection. Service discovery
can also remove endpoints, which changes the endpoint set that capacity is calculated against,
unlike marking an endpoint unhealthy. Test the failure you expect in production, because
scale-down and failed health checks can behave differently.

## Overlapping policies

A more specific policy overrides the fields it sets, and inherits the fields it omits. Lists
such as `hashPolicies`, `affinityTags`, and `failover` are replaced, not appended.

For example, a mesh-wide rule can choose `RingHash` while a `backend` rule adds the `x-user`
hash policy, and backend traffic uses both. A more specific HTTP route can replace the hash list
with a cookie hash, but can't change the algorithm. Switching the algorithm to `RoundRobin`
makes an inherited hash policy useless for affinity. For more information, see
[Policy precedence](/mesh/policy-targeting/#policy-precedence).

## Validating endpoint selection

1. Use a destination with several endpoints, and a response or access log that identifies the
   serving instance. Confirm that the caller proxy's cluster and HTTP route configuration have
   the intended algorithm and hash policy.
1. Send repeated requests with the same hash input, and confirm that they reach the same
   endpoint.
1. Change the hash input (header, cookie, query parameter, or source IP), and confirm that
   requests can reach a different endpoint.
1. Send requests without the hash input to check the fallback behavior. Test many keys, because
   two keys can select the same endpoint.
1. Remove one endpoint and measure how many keys move. Consistent hashing reduces disruption,
   but keys that weren't on the removed endpoint can move too.
1. For locality awareness, identify the zone serving the response, make the local endpoints
   unhealthy, and confirm that traffic follows the failover priority.
1. Confirm that a remote zone missing from every applicable `crossZone.failover` rule gets no
   traffic. Check each caller zone separately, because `from.zones` changes which rules apply.

If affinity fails, check the following:

* The traffic is handled as HTTP.
* The hash input is present.
* The effective cluster uses `RingHash` or `Maglev`.

If locality fails, compare the caller's labels with endpoint metadata, and inspect endpoint
priorities and health. When testing TCP distribution, use new connections, because an existing
connection doesn't move.
