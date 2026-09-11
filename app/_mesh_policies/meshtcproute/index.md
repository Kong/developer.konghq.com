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
- text: MeshTimeout policy
  url: "/mesh/policies/meshtimeout/"
---

`MeshTCPRoute` changes where a client's connections to a destination go. It can point them at a
different destination entirely, or spread them across several by weight.

TCP carries nothing the proxy can match a connection on, so a route has no equivalent of the
path and header matching in [MeshHTTPRoute](/mesh/policies/meshhttproute/). One `to` entry
holds one rule, and that rule applies to every connection the client opens to that destination.

## Split connections between two destinations

This policy applies to proxies labelled `app: frontend` and sends a tenth of their connections
to `backend` to a second destination:

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

## Where this policy applies

`spec.targetRef` selects the client proxies whose outbound connections are routed, and accepts
`Mesh` or `Dataplane` with `labels`. Leaving it out is the same as `kind: Mesh`.

`spec.to[]` names the destinations, and needs at least one entry. `to[].targetRef` accepts
`MeshService`, `MeshExternalService` and `MeshMultiZoneService`. `Mesh` is not accepted, so a
route always names a destination. Add `sectionName` to confine the route to one named port of a
`MeshService`.

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

A destination that does not resolve is dropped from the list rather than answered with an
error, because a TCP proxy has no status code to answer with. Where none of the entries
resolve, the client gets no outbound listener for that destination at all, and its connections
fail at connect time.

## Precedence against MeshHTTPRoute

Where a destination's protocol is HTTP based, `MeshHTTPRoute` owns its routing and a
`MeshTCPRoute` naming the same destination has no effect. This holds whenever any
`MeshHTTPRoute` targets that destination, whatever either route configures.

`MeshTCPRoute` governs routing for a destination whose protocol is `tcp`, and for an
HTTP-based destination that no `MeshHTTPRoute` targets. The protocol comes from
`networking.inbound[].protocol` on the destination's `Dataplane`, which on Kubernetes is
derived from the `Service` port.
