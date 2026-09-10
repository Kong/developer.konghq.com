---
title: Mesh HTTP Route
name: MeshHttpRoutes
products:
- mesh
description: Match HTTP requests on path, method, headers or query parameters, then modify, redirect or split them across destinations.
content_type: plugin
icon: meshhttproute.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: MeshTCPRoute policy
  url: "/mesh/policies/meshtcproute/"
- text: MeshRetry policy
  url: "/mesh/policies/meshretry/"
- text: MeshTimeout policy
  url: "/mesh/policies/meshtimeout/"
---

`MeshHTTPRoute` matches HTTP requests leaving a proxy and decides what happens to them: which
destination they reach, how the traffic is split across several destinations, and what is
rewritten on the way. Matching and precedence follow the
[Gateway API `HTTPRoute` specification](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.HTTPRouteRule).

A route is also a target other policies can attach to. `MeshRetry`, `MeshTimeout` and
`MeshAccessLog` accept `to[].targetRef.kind: MeshHTTPRoute`, which applies them to the requests
one route matches rather than to everything sent to a destination.

## Route two paths to different destinations

This policy applies to proxies labelled `app: frontend` and splits requests to `backend` by
path prefix:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshHTTPRoute
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
        - matches:
            - path:
                type: PathPrefix
                value: /orders
          default:
            backendRefs:
              - kind: MeshService
                labels:
                  kuma.io/display-name: orders
                port: 8080
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshService
                labels:
                  kuma.io/display-name: backend
                port: 8080
```
{% endpolicy_yaml %}

## Where this policy applies

`spec.targetRef` selects the client proxies whose outbound requests are routed, and accepts
`Mesh` or `Dataplane` with `labels`. Leaving it out is the same as `kind: Mesh`.

`spec.to[].targetRef` names the destination whose traffic the rules apply to, and accepts
`MeshService`, `MeshExternalService` and `MeshMultiZoneService`. `Mesh` is not accepted here,
so a route always names a destination. Add `sectionName` to confine the rules to one named
port of a `MeshService`; without it they apply to every HTTP port that service exposes.

`spec.to[].hostnames` is present in the schema but not implemented. Setting it is rejected with
`must not be defined`.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## Rule structure

`MeshHTTPRoute` nests `default` one level deeper than other outbound policies. A `to` entry
holds `rules`, and each rule pairs a set of `matches` with the `default` configuration for the
requests they match:

```yaml
spec:
  to:
    - targetRef: {...}
      rules:
        - matches: [...]   # which requests this rule covers
          default:
            filters: [...]      # what to change about them
            backendRefs: [...]  # where to send them
```

Every rule needs at least one entry in `matches`.

## Matching a request

A match may constrain any combination of the four fields below, and all of the constraints in
one match entry must hold. Several entries in `matches` are alternatives: the rule applies if
any one of them matches.

{% table %}
columns:
  - title: Field
    key: field
  - title: What it matches
    key: matches
rows:
  - field: "`path`"
    matches: "`type` is `Exact`, `PathPrefix` or `RegularExpression`, with the pattern in `value`. `Exact` and `PathPrefix` values must be absolute, and a `PathPrefix` other than `/` must not end in a slash."
  - field: "`method`"
    matches: "One of `CONNECT`, `DELETE`, `GET`, `HEAD`, `OPTIONS`, `PATCH`, `POST`, `PUT`, `TRACE`."
  - field: "`headers`"
    matches: "A list of header matches. `type` is `Exact` (the default), `Prefix`, `RegularExpression`, `Present` or `Absent`. `Present` and `Absent` take no `value`."
  - field: "`queryParams`"
    matches: "A list of `name` and `value` pairs, with `type` `Exact` or `RegularExpression`. Multiple entries must all match, and a name may appear only once."
{% endtable %}

A `PathPrefix` matches on whole path segments. The prefix `/api` matches `/api` and `/api/v1`,
and does not match `/apiary`.

## Which rule wins

Rules are ordered by specificity rather than by the order they are written in, following the
Gateway API precedence rules. The first of these that distinguishes two rules decides:

1. A rule with a `path` match beats one without.
2. `Exact` beats `PathPrefix`, which beats `RegularExpression`.
3. Within the same type, the longer `value` wins.
4. A rule with a `method` match beats one without.
5. More `headers` matches wins.
6. More `queryParams` matches wins.

## An unmatched request gets a 404

Once any `MeshHTTPRoute` applies to a destination, a request that matches none of its rules is
answered with `404`. It is not passed through to the destination.

This affects paths no rule mentions, and it covers every HTTP port of the destination when the
`to[].targetRef` names a `MeshService` without a `sectionName`. Ports whose protocol is not HTTP
based are unaffected, as is a destination with no `MeshHTTPRoute` at all. On a gRPC destination
the `404` reaches the client as `UNIMPLEMENTED`.

A route written only so another policy can attach to it is the case to check. A route matching
`/api`, added so a `MeshTimeout` can target it, answers `404` on every other path of that
destination. To keep unmatched traffic flowing, add a catch-all rule:

```yaml
rules:
  - matches:
      - path:
          type: PathPrefix
          value: /
    default:
      backendRefs:
        - kind: MeshService
          labels:
            kuma.io/display-name: backend
          port: 8080
```

Put the catch-all on the route itself when the policies targeting that route should also cover
the unmatched traffic, and on a second `MeshHTTPRoute` when they should not.

## Filters

`default.filters` is a list of modifications applied to matched requests. Each entry sets
`type` and the matching configuration object.

{% table %}
columns:
  - title: "`type`"
    key: type
  - title: Effect
    key: effect
rows:
  - type: "`RequestHeaderModifier`"
    effect: "Sets, adds or removes request headers through `set`, `add` and `remove`. At least one of the three is required, and a header name may appear only once across all three."
  - type: "`ResponseHeaderModifier`"
    effect: "The same three operations, applied to the response."
  - type: "`RequestRedirect`"
    effect: "Answers with a redirect instead of forwarding. Takes `scheme` (`http` or `https`), `hostname`, `port`, `path`, and `statusCode`, one of `301`, `302`, `303`, `307`, `308`, defaulting to `302`."
  - type: "`URLRewrite`"
    effect: "Rewrites `hostname` and `path` before forwarding."
  - type: "`RequestMirror`"
    effect: "Copies requests to a second destination named by `backendRef`, and discards its responses. `percentage` controls how many are copied, and defaults to all of them."
{% endtable %}

A `path` under `RequestRedirect` or `URLRewrite` is either `type: ReplaceFullPath` with
`replaceFullPath`, or `type: ReplacePrefixMatch` with `replacePrefixMatch`.
`ReplacePrefixMatch` is accepted only when every entry in the rule's `matches` uses a
`PathPrefix` path, since there is otherwise no prefix to replace.

`urlRewrite.hostToBackendHostname` is present in the schema but not implemented, and setting
it is rejected.

Filters may also be attached to an individual entry in `backendRefs`, where only
`RequestHeaderModifier` is accepted.

## Splitting traffic across destinations

`default.backendRefs` is a list of destinations, each with a `weight`. A request is assigned to
one of them in proportion to its weight against the total, with `weight` defaulting to 1.
`kind` accepts `MeshService`, `MeshExternalService` and `MeshMultiZoneService`, selected by
`labels`, and `port` names the destination port. `MeshMultiZoneService` requires `port`.

Omitting `backendRefs` sends matched requests to the destination in the `to` entry, so a rule
that only sets filters does not need to repeat it.

How an unusable `backendRefs` list behaves:

{% table %}
columns:
  - title: Situation
    key: situation
  - title: Response
    key: response
rows:
  - situation: "None of the entries resolve to an existing resource, or all of them name a port the destination does not have."
    response: "`500` for every request the rule matches. Traffic is not passed through to the destination."
  - situation: "Some entries resolve and some do not."
    response: "The unresolved share of the weight answers `500`. The rest is split across the entries that resolved."
  - situation: "Every entry has weight `0`."
    response: "`503`, treated as no available backend."
{% endtable %}

A reference that has not resolved yet behaves the same as one that never will, so a route
pointing at a `MeshService` that KDS has not synced into the zone fails its requests until the
reference resolves. A rule carrying a `RequestRedirect` filter still redirects, since it
answers without an upstream.

## Merging routes that target the same proxy

Where several `MeshHTTPRoute` policies apply to the same proxy and the same destination, their
rules are merged. `rules` is treated as a map keyed on `matches`, so two rules with identical
`matches` have their `default` blocks merged, and rules with different `matches` are kept
side by side. The order the policies merge in is decided by their top-level `targetRef`, as
described in [How policies select traffic](/mesh/policy-targeting/).

## Interaction with MeshTCPRoute

Where a proxy is matched by both a `MeshHTTPRoute` and a
[`MeshTCPRoute`](/mesh/policies/meshtcproute/) for the same destination, the
`MeshHTTPRoute` takes effect and the `MeshTCPRoute` is ignored.

## Upgrading from {{site.mesh_product_name}} 2.x

The changes fall into two groups. The selector rewrites are rejected when the route is
applied, so they announce themselves. The routing changes do not: a route that still
validates can now answer a request that its destination used to answer.

Do the migration before upgrading. A route already stored in the control plane is not
re-validated, so one carrying a removed selector keeps being served in the zone it was
applied to, and then fails to sync into any zone that is upgraded after it.

### Add a catch-all rule to every route

A request matching none of a route's rules used to reach the destination as if the route did
not exist. It now gets a `404`, described in full under
[An unmatched request gets a 404](#an-unmatched-request-gets-a-404).

The routes to change are those whose `rules` contain no `PathPrefix: /` match. A route written
to anchor another policy is the common case: it matches one path because that was the traffic a
`MeshTimeout` or `MeshRetry` needed to cover, and every other path of that destination now
returns `404`.

Add a rule matching all paths, pointing at the destination the unmatched traffic used to reach:

```yaml
rules:
  - matches:
      - path:
          type: PathPrefix
          value: /orders
    default:
      backendRefs:
        - kind: MeshService
          labels:
            kuma.io/display-name: orders
          port: 8080
  # added for the upgrade
  - matches:
      - path:
          type: PathPrefix
          value: /
    default:
      backendRefs:
        - kind: MeshService
          labels:
            kuma.io/display-name: backend
          port: 8080
```

On the route itself, the catch-all also inherits the policies attached to that route. Where
that is wrong — a 1s `MeshTimeout` that suits `/orders` but not a file download on another
path — put the catch-all in a second `MeshHTTPRoute` instead.

### Check that every backendRef resolves

A rule that declares `backendRefs` and resolves none of them used to fall back to the
destination named in its `to` entry. It now answers `500`. A `backendRef` naming a port the
destination does not have counts as unresolved as well, where it previously fell through to
another port of the same destination.

Both were misconfigurations that traffic survived, which is why they are worth an explicit
pass: after the upgrade they become visible traffic loss. The references to check are the ones
that were never exercised — a `MeshService` in another zone that KDS may not have synced, a
destination in another namespace, and any `backendRef` with an explicit `port` or
`sectionName`.

### Replace MeshServiceSubset references

`backendRefs[]` and the `RequestMirror` filter's `backendRef` no longer accept
`kind: MeshServiceSubset`, and `tags` is gone from the `backendRef` schema. A stored route
carrying one keeps being served, but the control plane no longer resolves that kind, so the
reference counts as unresolved and the rule loses its destination under the rule above.

```yaml
# 2.x
backendRefs:
  - kind: MeshServiceSubset
    tags:
      kuma.io/service: payments
      version: v1

# 3.x
backendRefs:
  - kind: MeshService
    labels:
      kuma.io/display-name: payments
    port: 8080
```

Selecting a subset of a destination's endpoints by tag has no replacement. Where a route split
traffic between tagged subsets of one service, that service has to become separate
`MeshService` resources for the route to address.

### Select real resources by labels

`Dataplane`, `MeshService`, `MeshExternalService`, `MeshMultiZoneService` and `MeshHTTPRoute`
are selected by `labels` only, in `spec.targetRef`, `spec.to[].targetRef` and `backendRefs[]`
alike. `name` and `namespace` select nothing, and a reference carrying them instead of `labels`
is rejected with `labels (): must be set when kind is MeshService`. `sectionName` is unchanged
and still names a `MeshService` port.

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

### Rewrite the top-level targetRef

`spec.targetRef.kind` accepts `Mesh` and `Dataplane`. `MeshSubset`, `MeshService`,
`MeshServiceSubset` and `MeshGateway` are rejected with
`in body should be one of [Mesh Dataplane]`.

A `MeshSubset` or `MeshServiceSubset` selector becomes `kind: Dataplane` with the equivalent
labels. A `MeshGateway` selector becomes `kind: Dataplane` too: the built-in gateway is
removed, and a delegated gateway is an ordinary `Dataplane` as far as the control plane is
concerned.

```yaml
# 2.x
targetRef:
  kind: MeshSubset
  tags:
    kuma.io/service: frontend

# 3.x
targetRef:
  kind: Dataplane
  labels:
    app: frontend
```

`spec.to[].targetRef` narrows in the same release, to `MeshService`,
`MeshExternalService` and `MeshMultiZoneService`. A `MeshHTTPRoute` under a gateway used to
set `to[].targetRef.kind: Mesh`; that is now rejected, so the route names the destination
directly.

### Delete leftover TrafficRoute resources

`TrafficRoute` is removed, along with the legacy `Retry`, `Timeout` and `TrafficLog` policies
that matched on the routes it defined. Where a `MeshHTTPRoute` and a `TrafficRoute` both
applied to a proxy, the `MeshHTTPRoute` already won, so a mesh that had finished migrating to
the new policies loses nothing by deleting them.
