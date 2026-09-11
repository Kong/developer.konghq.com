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

## Upgrading from {{site.mesh_product_name}} 2.x

`MeshTCPRoute` keeps its shape. What changes is how its references name things, and one of the
three changes is silent.

### Select real resources by labels

`MeshService`, `MeshExternalService` and `MeshMultiZoneService` are selected by `labels` only,
in `to[].targetRef` and `backendRefs[]` alike. A reference carrying `name` and `namespace`
instead is rejected with `labels (): must be set when kind is MeshService`. `sectionName` is
unchanged and still names a port.

```yaml
# 2.x
to:
  - targetRef:
      kind: MeshService
      name: backend
      namespace: kong-mesh-demo
      sectionName: http

# 3.x
to:
  - targetRef:
      kind: MeshService
      labels:
        kuma.io/display-name: backend
        k8s.kuma.io/namespace: kong-mesh-demo
      sectionName: http
```

### Replace MeshServiceSubset backendRefs

`backendRefs[].kind` no longer accepts `MeshServiceSubset`, and `tags` is gone from the schema.
A stored route carrying one keeps being served, but the control plane no longer resolves that
kind, so the reference is dropped and the rule loses that share of its connections. Where every
entry is a subset reference, the client loses its listener for the destination.

```yaml
# 2.x
backendRefs:
  - kind: MeshServiceSubset
    tags:
      kuma.io/service: backend
      version: v1

# 3.x
backendRefs:
  - kind: MeshService
    labels:
      kuma.io/display-name: backend-v1
    port: 8080
```

Splitting connections between tagged subsets of one service has no replacement. That service
has to become separate `MeshService` resources for the route to address.

### Rewrite the top-level targetRef

`spec.targetRef.kind` accepts `Mesh` and `Dataplane`. `MeshSubset`, `MeshServiceSubset` and
`MeshGateway` are rejected with `in body should be one of [Mesh Dataplane]`. A subset selector
becomes `kind: Dataplane` with the equivalent labels, and a `MeshGateway` selector becomes
`kind: Dataplane` too, since a delegated gateway is an ordinary `Dataplane`.

{:.warning}
> `kind: Dataplane` selects proxies by `labels` only, and a reference carrying `name` or
> `namespace` instead is **accepted**. Those fields are not in the schema, so they are dropped,
> and what remains is a bare `kind: Dataplane` — every proxy in the mesh. Nothing reports it, so
> read the policy back after rewriting one: a stored `targetRef` with a `kind` and no `labels`
> covers the whole mesh.

A 2.x gateway route also set `to[].targetRef.kind: Mesh`, which is now rejected. Name the
destination in `to[].targetRef` instead.

### Delete leftover TrafficRoute and VirtualOutbound resources

`TrafficRoute` is removed, along with the legacy policies that matched on the routes it
defined. `VirtualOutbound` no longer affects generated Envoy configuration either. Where both a
`MeshTCPRoute` and a `TrafficRoute` applied to a proxy, the `MeshTCPRoute` already won.
