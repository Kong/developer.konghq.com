---
title: Mesh TCP Route
name: MeshTCPRoutes
products:
- mesh
description: Send a client's TCP connections to a different destination, or split them across several.
content_type: plugin
icon: meshtcproute.png
related_resources:
- text: Policy targeting
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshtcproute"
- text: MeshHTTPRoute policy
  url: "/mesh/policies/meshhttproute/"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
---

The `MeshTCPRoute` policy changes where a client's TCP connections to a destination go. It can
send them to a different destination, or split them across several by weight.

`MeshTCPRoute` doesn't inspect paths or headers. To route on those, use
[MeshHTTPRoute](/mesh/policies/meshhttproute/).

Without a route, connections go to the destination's normal backend. A route changes where the
proxy sends a connection, not the address the client application calls.

## Split connections between two destinations

The following example sends 10% of the connections that proxies labeled `app: frontend` open
to `backend` to `backend-next`.

`backend` and `backend-next` already exist as `MeshService` resources with service port 8080 and the
labels used in the example. `backend-next` accepts the same application protocol, and for
mTLS traffic, its permissions allow the original caller's identity:

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

What each field does:

* `targetRef` selects the `frontend` proxies that open the connections. Leaving it out is the
  same as `kind: Mesh`.
* `to[].targetRef` selects connections whose original destination is `backend`.
* `backendRefs` replaces that destination with a 90/10 split between `backend` and
  `backend-next`.

The weights apply to connections, not to individual requests sent over a reused connection.

## Rule structure

`MeshTCPRoute` nests `default` one level deeper than other outbound policies, inside `rules`,
like `MeshHTTPRoute`:

```yaml
spec:
  to:
    - targetRef: {...}
      rules:
        - default:
            backendRefs: [...]
```

Each `to` entry accepts at most one rule, and that rule needs a non-empty `backendRefs` list.

`spec.to[]` needs at least one entry. `to[].targetRef` accepts `MeshService`,
`MeshExternalService`, and `MeshMultiZoneService`, but not `Mesh`, so a route always names a
destination. To limit a route to one named port of a `MeshService`, set
`to[].targetRef.sectionName` to a `MeshService.spec.ports[].name` value. `backendRefs[].port`
is different: it takes the numeric service port from `spec.ports[].port`, not a container port
or a port name.

## Connection destinations

Each connection goes to one `backendRefs` entry, in proportion to its weight. Each entry accepts
the following fields:

* `kind`: `MeshService`, `MeshExternalService`, or `MeshMultiZoneService`.
* `labels`: selects the destination.
* `port`: the destination port. Required for `MeshMultiZoneService`, and for a `MeshService`
  with more than one port. Without it, the entry doesn't resolve.
* `weight`: the entry's share of connections, relative to the total. Defaults to 1.

A reference that doesn't resolve is dropped from the list. For example, if `backend-next`
doesn't exist in the client proxy's zone, `backend` gets 100% of the connections.

If no references resolve, the route generates no outbound listener for the destination. Don't
rely on this to block access. Use traffic permissions instead.

A resolved reference isn't necessarily healthy. A `MeshService` can resolve while all its
endpoints are down, and connections assigned to it then fail instead of moving to another
backend. Use [MeshHealthCheck](/mesh/policies/meshhealthcheck/) and
[MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/) to manage endpoint health within a
backend, and change the route weights to move traffic between services.

## Overlapping routes

For each destination, the applicable policies combine into one effective rule. A more specific
policy's `backendRefs` list replaces the broader list, and weights aren't added together. For
example, a mesh-wide route splitting `backend` and `backend-next` 90/10 can be overridden for
`app: test-client` by a route that sends all connections to `backend-next`. Other clients keep
the 90/10 split.

Weight changes affect only new connections. Existing connections stay on their backend, so
long-lived sessions can delay a rollout.

## Precedence against MeshHTTPRoute

If any `MeshHTTPRoute` targets an HTTP-based destination, it owns that destination's routing,
and a `MeshTCPRoute` for the same destination has no effect.

`MeshTCPRoute` routes destinations with the `tcp` protocol, and HTTP-based destinations that no
`MeshHTTPRoute` targets. The protocol comes from `networking.inbound[].protocol` on the
destination's `Dataplane`. On Kubernetes, it's derived from the `Service` port.

## Validating TCP routing

1. Open new connections from a proxy that `targetRef` selects to the destination that
   `to[].targetRef` selects.
1. Confirm that each connection reaches one of the resolved `backendRefs`.
1. Open enough separate connections to confirm the weight distribution. Many requests over one
   connection don't test the split.
1. Test a missing `MeshService` and a `MeshService` with unavailable endpoints separately, because
   they fail differently.

{% table %}
columns:
  - title: Unexpected result
    key: unexpected
  - title: Check
    key: check
rows:
  - unexpected: "All requests reach one backend"
    check: "Open separate connections, because requests on one TCP connection share its backend. Confirm that both references resolve."
  - unexpected: "A share of connections fails"
    check: "Endpoint health and permissions on the backend that gets that share."
  - unexpected: "A TCP route has no effect on HTTP traffic"
    check: "A `MeshHTTPRoute` that targets the destination. It takes precedence."
  - unexpected: "Only some clients use the new split"
    check: "Compare their `targetRef` selectors and effective backend lists."
{% endtable %}
