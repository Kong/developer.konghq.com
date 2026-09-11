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
- text: MeshHTTPRoute policy
  url: "/mesh/policies/meshhttproute/"
---

`MeshLoadBalancingStrategy` decides which of a destination's endpoints a client's request goes
to. It covers three separate choices: the algorithm that picks between endpoints, the request
property a consistent-hashing algorithm hashes on, and how strongly a client prefers endpoints
close to it.

## Pin requests to an endpoint by header

This policy applies to proxies labelled `app: frontend` and sends every request carrying the
same `x-user` header to the same `backend` endpoint:

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

## Where this policy applies

`spec.targetRef` selects the client proxies whose outbound requests are balanced, and accepts
`Mesh` or `Dataplane` with `labels`. This is a client-side policy: the endpoint choice is made
by the caller's proxy, so it is configured there.

`spec.to[].targetRef` names the destination, and accepts `Mesh`, `MeshService`,
`MeshExternalService`, `MeshMultiZoneService` and `MeshHTTPRoute`.

Two of those kinds are constrained:

- With `kind: MeshHTTPRoute`, only `hashPolicies` is accepted. `loadBalancer` and
  `localityAwareness` are rejected with
  `field is not allowed when targetRef.kind is MeshHTTPRoute, only hashPolicies is supported`.
  Hashing is a per-request decision, so it can be set per route; the algorithm and the locality
  preference belong to the destination's cluster, which a route does not own.
- `localityAwareness.crossZone` is accepted only with `kind: MeshMultiZoneService`. On any
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
    how: "Picks a few endpoints at random and sends the request to whichever of them has the fewest requests in flight."
    settings: "`choiceCount`, how many to compare, at least 2 and 2 by default. `activeRequestBias` scales how much an endpoint's in-flight requests reduce its weight, 0 or greater."
  - type: "`RingHash`"
    how: "Hashes a request property and walks a ring of endpoint hashes to the nearest one, so the same property reaches the same endpoint."
    settings: "`hashFunction`, `XXHash` or `MurmurHash2`. `minRingSize` and `maxRingSize`, between 1 and 8000000, defaulting to 1024 and 8000000."
  - type: "`Random`"
    how: "An endpoint at random. With no health checking in place this spreads load better than round robin, because it does not favour whichever endpoint follows a failed one."
    settings: "None."
  - type: "`Maglev`"
    how: "Consistent hashing, as `RingHash`, with a fixed-size table instead of a ring. A change in the endpoint set moves fewer requests than it does on a ring."
    settings: "`tableSize`, a prime number up to 5000011, 65537 by default."
{% endtable %}

`RingHash` and `Maglev` need `hashPolicies` to hash on. Without one they have no key, and
requests are not pinned to anything.

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

## Locality awareness

Locality awareness is on unless it is turned off, so a client prefers endpoints in its own zone
and only reaches other zones when the local ones run out. `localityAwareness.disabled: true`
removes the preference and treats every endpoint equally, wherever it is.

`localZone` and `crossZone` take effect regardless of `disabled`, since each describes
something more specific than the preference itself.

### Priorities inside a zone

`localZone.affinityTags` orders endpoints within the zone by the tags they carry. Requests go
to the group matching the first tag while it has healthy endpoints, then the next.

```yaml
localityAwareness:
  localZone:
    affinityTags:
      - key: kubernetes.io/hostname
      - key: topology.kubernetes.io/zone
```

`weight` sets the share each group receives. Left unset, the weights are generated so the first
tag takes 90% of requests, the second 9%, the third 1%, and so on. Weights are all-or-nothing:
setting some and not others is rejected with `all or none affinity tags should have weight`.

The tags come from the destination's inbound — a label on the Pod on Kubernetes, an inbound tag
on the `Dataplane` on Universal. A tag no endpoint carries is skipped.

### Falling back to other zones

`crossZone.failover` is a list of rules in priority order, naming which zones a client may
reach once its local endpoints are not enough. It applies only to a
`MeshMultiZoneService` destination.

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
      percentage: 70
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

A zone that no rule selects receives no traffic, so the list ends in an implicit `None`.

`failoverThreshold.percentage` is the proportion of live endpoints below which the next
priority starts receiving traffic, in the range 0 to 100 and 50 by default. At `70` with ten
endpoints deployed, the next priority is used once fewer than seven are live. Quote a
fractional value, as `"70.5"`.

Deciding which endpoints are live is the job of
[MeshHealthCheck](/mesh/policies/meshhealthcheck/) or
[MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/). Without one of them there is nothing
to count, and failover does not start.
