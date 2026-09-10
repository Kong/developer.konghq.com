---
title: Mesh Timeout
name: MeshTimeouts
products:
- mesh
description: Set how long a proxy waits when connecting to a destination, and when serving a request.
content_type: plugin
icon: meshtimeout.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: MeshRetry policy
  url: "/mesh/policies/meshretry/"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
- text: MeshHTTPRoute policy
  url: "/mesh/policies/meshhttproute/"
---

`MeshTimeout` sets how long a proxy waits before giving up: on establishing a connection, on
an idle connection, and on a response arriving.

A mesh already has timeouts. {{site.mesh_product_name}} creates a default `MeshTimeout` for
every mesh, so a policy of your own changes those values rather than introducing timeouts
where there were none.

## Timeouts for requests a proxy sends

This policy applies to proxies labelled `app: web`, and governs the requests they make to
`backend`:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTimeout
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
        connectionTimeout: 5s
        idleTimeout: 1h
        http:
          requestTimeout: 15s
          streamIdleTimeout: 30m
```
{% endpolicy_yaml %}

## Where this policy applies

`spec.targetRef` selects which proxies the timeouts are configured on: `Mesh`, or `Dataplane`
with `labels`. `spec.to[].targetRef` sets timeouts for traffic those proxies send, and
accepts `Mesh`, `MeshService`, `MeshExternalService`, `MeshMultiZoneService` or
`MeshHTTPRoute`. `spec.rules[]` sets timeouts for traffic they receive.

**`to` and `rules` are mutually exclusive.** A policy defining both is rejected with
`fields 'to' must be empty when 'rules' is defined`, so inbound and outbound timeouts need
separate policies.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## What each timeout governs

{% table %}
columns:
  - title: Field
    key: field
  - title: Governs
    key: governs
rows:
  - field: "`connectionTimeout`"
    governs: "How long the proxy waits for a TCP connection to be established."
  - field: "`idleTimeout`"
    governs: "How long a connection may exist with no activity. On HTTP, how long before a connection with no active streams is closed."
  - field: "`http.requestTimeout`"
    governs: "How long the proxy waits for a complete response, measured from the point the whole request has been processed."
  - field: "`http.streamIdleTimeout`"
    governs: "How long an HTTP/2 stream may exist with no activity."
  - field: "`http.maxStreamDuration`"
    governs: "The maximum lifetime of a stream, whatever its activity. Used to recycle long-lived streams."
  - field: "`http.maxConnectionDuration`"
    governs: "How long after establishment a connection is drained and closed. With active streams, the drain runs and the connection is force-closed 5 seconds later."
  - field: "`http.requestHeadersTimeout`"
    governs: "How long the proxy waits for request headers, timed from the first byte of the headers to the last."
{% endtable %}

{:.info}
> The stream timeouts apply to HTTP/1.1 services as well. Connections between data plane
> proxies are upgraded to HTTP/2, so streams exist regardless of what the application speaks.

## The defaults a mesh starts with

{{site.mesh_product_name}} creates two `MeshTimeout` policies for each mesh, one for inbound
and one for outbound, both targeting `kind: Mesh`.

{% table %}
columns:
  - title: Timeout
    key: timeout
  - title: Outbound default
    key: out
  - title: Inbound default
    key: in
rows:
  - timeout: "`connectionTimeout`"
    out: "5s"
    in: "10s"
  - timeout: "`idleTimeout`"
    out: "1h"
    in: "2h"
  - timeout: "`http.requestTimeout`"
    out: "15s"
    in: "0, disabled"
  - timeout: "`http.streamIdleTimeout`"
    out: "30m"
    in: "1h"
  - timeout: "`http.maxStreamDuration`"
    out: "unset"
    in: "0, disabled"
{% endtable %}

The inbound values are twice the outbound ones, so a receiving proxy does not time out a
request before the caller does. `http.requestTimeout` is disabled inbound for the same
reason: the caller's 15 seconds governs how long a request may take.

A mesh created with `skipCreatingInitialPolicies` covering `MeshTimeout` has neither default,
and the proxies fall back to Envoy's own values.

## Timeouts for requests a proxy receives

`rules` configures the inbound side, and each rule may match on the calling identity:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTimeout
mesh: default
name: backend-inbound
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - default:
        connectionTimeout: 10s
        idleTimeout: 2h
        http:
          requestTimeout: 30s
```
{% endpolicy_yaml %}

### Timeouts that cannot vary by client

A rule matching on `spiffeID` may set only `http.requestTimeout` and
`http.streamIdleTimeout`. The other five fields are rejected with
`can't be specified when matches contain spiffeID because this field cannot be conditioned on
source identity`.

The reason is where each timeout is applied. `requestTimeout` and `streamIdleTimeout` act on
a request or stream, which belongs to one client. `connectionTimeout`, `idleTimeout`,
`requestHeadersTimeout`, `maxStreamDuration` and `maxConnectionDuration` act on a connection
or a listener, which is shared, so there is no single client to condition them on.

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTimeout
mesh: default
name: backend-from-frontend
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - matches:
        - spiffeID:
            type: Prefix
            value: spiffe://default.default.mesh.local/ns/kong-mesh-demo
      default:
        http:
          requestTimeout: 45s
```
{% endpolicy_yaml %}

## Disable a timeout

Set it to `0`. This is how the default inbound `http.requestTimeout` is disabled, and it is
the correct way to remove a timeout rather than a very large value:

```yaml
http:
  requestTimeout: 0s
```

## Upgrading from {{site.mesh_product_name}} 2.x

Every change here is silent. `from` is dropped rather than rejected, and on Universal an
inbound that declares its protocol only through a tag loses its HTTP timeouts altogether.
Both are worth handling before the upgrade, because neither produces an error afterwards.

### Rewrite `from` as `rules`

`spec.from` is removed. Timeouts for inbound traffic are configured through `spec.rules`.

`from` is dropped rather than rejected. A policy that also sets `to` or `rules` is accepted and
loses its inbound timeouts silently; one where `from` was the only field is rejected with
`spec (): at least one of 'to' or 'rules' has to be defined`.

```yaml
# 2.x
spec:
  from:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 1h

# 3.x
spec:
  rules:
    - default:
        idleTimeout: 1h
```

A `from` entry targeting `kind: Mesh`, meaning every client, becomes a single catch-all rule.
To keep different timeouts per client, match on their SPIFFE ID in `rules[].matches`.

### Set the protocol on Universal inbounds

An inbound's protocol is now read only from `networking.inbound[].protocol`. The
`kuma.io/protocol` tag stays a regular tag that policies can match on, but it is no longer used
as a fallback when the field is unset. Kubernetes is unaffected, since the field is derived
from the `Service` port.

{:.warning}
> An inbound with no `protocol` is treated as an unknown protocol and served as plain TCP. It
> loses the L7 filters that depend on the protocol, including the `http` timeouts in this
> policy — `requestTimeout`, `streamIdleTimeout`, `maxStreamDuration`,
> `maxConnectionDuration` and `requestHeadersTimeout`. `connectionTimeout` and `idleTimeout`
> sit outside `http` and still apply.
> Nothing rejects the `Dataplane`, so the change is silent.

Set `networking.inbound[].protocol` explicitly on every Universal `Dataplane` that declared its
protocol only through the tag.

### Rewrite the selectors

`spec.targetRef.kind` accepts `Mesh` and `Dataplane`. `MeshSubset`, `MeshServiceSubset` and
`MeshGateway` are rejected with `in body should be one of [Mesh Dataplane]`. A subset selector
becomes `kind: Dataplane` with the equivalent labels, and a `MeshGateway` selector becomes
`kind: Dataplane` too, since a delegated gateway is an ordinary `Dataplane`.

In `spec.to[]`, real resources are selected by `labels` only, and a `MeshService` named by
`name` is rejected with `labels (): must be set when kind is MeshService`.

{:.warning}
> `kind: Dataplane` selects proxies by `labels` only, and a reference carrying `name` or
> `namespace` instead is **accepted**. Those fields are not in the schema, so they are dropped,
> and what remains is a bare `kind: Dataplane` — every proxy in the mesh. Nothing reports it, so
> read the policy back after rewriting one: a stored `targetRef` with a `kind` and no `labels`
> covers the whole mesh.

### Check routes this policy targets

`to[].targetRef.kind: MeshHTTPRoute` still applies timeouts to the requests one route matches.
What changed is the route: a request matching none of a `MeshHTTPRoute`'s rules now gets a
`404` instead of reaching the destination, so a route that exists only to anchor a
`MeshTimeout` will answer `404` on every path it does not match. See
[the MeshHTTPRoute upgrade guide](/mesh/policies/meshhttproute/#add-a-catch-all-rule-to-every-route).
