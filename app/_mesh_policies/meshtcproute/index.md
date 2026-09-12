---
title: Mesh TCP Route
name: MeshTCPRoutes
products:
- mesh
description: Send a client's TCP connections to a different destination, or split them across several.
content_type: plugin
icon: meshtcproute.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshtcproute"
- text: MeshHTTPRoute policy
  url: "/mesh/policies/meshhttproute/"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
---

`MeshTCPRoute` changes where a client's connections to a destination go. It can point them at a
different destination entirely, or spread them across several by weight.

`MeshTCPRoute` does not inspect application requests for paths or headers. Use
[MeshHTTPRoute](/mesh/policies/meshhttproute/) when routing depends on those HTTP fields.
One `to` entry holds one rule, which applies to connections the selected client proxies
open to that destination.

Without an applicable route, connections use the destination's normal backend. A route changes
the destination used by the proxy; it does not change the address the client application calls.

## Split connections between two destinations

This policy applies to proxies labeled `app: frontend` and sends a tenth of their connections
to `backend` to a second destination:

Both `backend` and `backend-next` must already exist as MeshServices, with the labels below
and service port 8080. The new backend must accept the same application protocol. For mTLS
traffic, its permissions must allow the original caller's identity.

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTCPRoute
mesh: default
name: frontend-to-backend
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
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                labels:
                  kuma.io/display-name: backend
                port: 8080
                weight: 90
              - kind: MeshService
                labels:
                  kuma.io/display-name: backend-next
                port: 8080
                weight: 10
```
{% endpolicy_yaml %}

Read the policy from the client to the backends:

- `targetRef` selects the `frontend` proxies that make the connections.
- `to[].targetRef` selects connections whose original destination is `backend`.
- `backendRefs` replaces that destination with a 90/10 weighted split between `backend` and
  `backend-next`.
- The weights apply to TCP connections, not to individual requests sent over a reused
  connection.

## Where this policy applies

`spec.targetRef` selects the client proxies whose outbound connections are routed, and accepts
`Mesh` or `Dataplane` with `labels`. Leaving it out is the same as `kind: Mesh`.

`spec.to[]` names the destinations, and needs at least one entry. `to[].targetRef` accepts
`MeshService`, `MeshExternalService` and `MeshMultiZoneService`. `Mesh` is not accepted, so a
route always names a destination. Add `sectionName` to confine the route to one named port of a
`MeshService`.

Read the named port from `MeshService.spec.ports[].name` and put it in
`to[].targetRef.sectionName`. The `backendRefs[].port` value is a numeric service port
from `spec.ports[].port`, not a container port or the name used by `sectionName`.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## Rule structure

`MeshTCPRoute` nests `default` one level deeper than other outbound policies, inside `rules`,
which mirrors the shape of `MeshHTTPRoute`:

```yaml
spec:
  to:
    - targetRef: {...}
      rules:
        - default:
            backendRefs: [...]
```

A `to` entry accepts exactly one rule, since there is nothing to distinguish a second one by,
and that rule must declare `backendRefs`. An empty or missing list is rejected with
`backendRefs (): must be defined`.

## Where connections go

`backendRefs` is a list of destinations, each with a `weight`. A connection is assigned to one
of them in proportion to its weight against the total, with `weight` defaulting to 1. `kind`
accepts `MeshService`, `MeshExternalService` and `MeshMultiZoneService`, selected by `labels`,
and `port` names the destination port. `MeshMultiZoneService` requires `port`.

A backend reference that does not resolve is omitted from the routing list. For example,
if `backend-next` does not exist in the client proxy's zone, the resolved `backend` entry
receives the connections instead of retaining only its original 90 percent share.

If no backend references resolve, this route generates no outbound listener for the destination.
It cannot provide the intended route. Do not treat that condition as an intentional access-control
mechanism; use traffic permissions to control access.

Reference resolution is separate from endpoint health. A MeshService can resolve successfully
while all of its workload endpoints are unavailable. Its routing weight does not automatically
move to a different MeshService; connections assigned to it can fail. Use
[MeshHealthCheck](/mesh/policies/meshhealthcheck/) and
[MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/) to manage endpoint health within a
backend, and change the route weights when traffic must move between services.

## How overlapping routes combine

Applicable policies contribute to one effective rule for each destination. A more specific
policy's `backendRefs` list replaces the broader list; the weights are not added together.
For example, a mesh-wide route splitting `backend` and `backend-next` 90/10 can be
overridden for `app: test-client` by a route sending all connections to `backend-next`.
Other clients keep the 90/10 split.

Changing weights affects new connections. Existing connections remain attached to their
selected backend, so long-lived sessions can delay the observed effect of a rollout.

## Precedence against MeshHTTPRoute

Where a destination's protocol is HTTP based, `MeshHTTPRoute` owns its routing and a
`MeshTCPRoute` naming the same destination has no effect. This holds whenever any
`MeshHTTPRoute` targets that destination, whatever either route configures.

`MeshTCPRoute` governs routing for a destination whose protocol is `tcp`, and for an
HTTP-based destination that no `MeshHTTPRoute` targets. The protocol comes from
`networking.inbound[].protocol` on the destination's `Dataplane`, which on Kubernetes is
derived from the `Service` port.

## Validate TCP routing

1. Open new connections from a proxy selected by `targetRef` to the destination selected by
   `to[].targetRef`.
1. Confirm that each connection reaches one of the resolved `backendRefs`.
1. Use enough independent connections to observe the configured weight distribution. Sending
   many requests over one persistent connection does not test the split.
1. Test reference resolution separately from endpoint health. A missing MeshService and an
   existing MeshService with unavailable endpoints are different failure cases.

| Unexpected result | Check |
| --- | --- |
| All requests reach one backend | Open independent connections; requests sharing one TCP session share its backend. Check that both references resolve. |
| A share of connections fails | Check endpoint health and permissions on the backend assigned that share. |
| A TCP route has no effect on HTTP traffic | Check for a matching MeshHTTPRoute, which takes precedence for HTTP destinations. |
| Only some clients use the new split | Compare their top-level policy selectors and effective backend lists. |
