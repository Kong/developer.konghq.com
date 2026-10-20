---
title: Mesh HTTP Route
name: MeshHTTPRoutes
products:
- mesh
description: Match HTTP requests on path, method, headers or query parameters, then modify, redirect or split them across destinations.
content_type: plugin
icon: meshhttproute.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshhttproute"
- text: MeshTCPRoute policy
  url: "/mesh/policies/meshtcproute/"
- text: MeshRetry policy
  url: "/mesh/policies/meshretry/"
---

The `MeshHTTPRoute` policy matches HTTP requests leaving a proxy and decides what happens to
them:

* Which destination they reach
* How traffic is split across several destinations
* What's rewritten on the way

Matching and precedence follow the
[Gateway API `HTTPRoute` specification](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.HTTPRouteRule).

Other policies can also target a route: `MeshRetry`, `MeshTimeout`, `MeshAccessLog`, and
`MeshLoadBalancingStrategy` accept `to[].targetRef.kind: MeshHTTPRoute`, which applies them
only to the requests that route matches.

Without a route, requests use normal destination routing. Once a route applies, requests
that match none of its rules return a `404`, so include a catch-all rule when other paths must
keep working.

## Route two paths to different destinations

The following example makes proxies labeled `app: frontend` split requests to `backend` by
path prefix. The application still calls `backend`, and its proxy chooses between the
`orders` and `backend` `MeshServices`. Both must exist with these labels, expose an HTTP
service port 8080, and allow the caller to reach them:

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

The first rule sends `/orders` and every path under it to `orders`. The second is a
catch-all that sends every other path to `backend`.

What each field does:

* `targetRef` selects the client proxies that do the routing: `Mesh`, or `Dataplane` with
  `labels`. The default is `kind: Mesh`.
* `to[].targetRef` selects the destination the application called: `MeshService`,
  `MeshExternalService`, or `MeshMultiZoneService`. `Mesh` isn't accepted, so a route always
  names a destination. To limit the rules to one port, set `sectionName` to a value from
  `MeshService.spec.ports[].name`. Otherwise, they apply to every HTTP port of the service.
* `matches` selects requests within the traffic.
* `backendRefs` sets where the selected requests go. Its `port` takes the numeric port from
  `MeshService.spec.ports[].port`.

Matching a path doesn't rewrite it. A request for `/orders/123` still arrives as
`/orders/123` unless you add a URL rewrite.

{:.warning}
> `kuma.io/display-name` identifies a `MeshService` only within one namespace, and the same
> name usually exists in every other zone. A `backendRefs` entry that selects on the display
> name alone resolves only when the route is in the same namespace as the service. From
> anywhere else, including `{{site.mesh_namespace}}`, it matches nothing, and the proxy
> answers matching requests with an empty `500` instead of reporting an error on the
> resource. Add `k8s.kuma.io/namespace` to the selector when the route and the service are in
> different namespaces.

The service's `appProtocol` must be HTTP, HTTP/2, or gRPC. The proxy can't apply HTTP matches
to traffic configured as opaque TCP.

## Rule structure

`MeshHTTPRoute` nests `default` one level deeper than other outbound policies. A `to` entry
holds `rules`, and each rule pairs `matches` with the `default` configuration for the requests
they match:

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

All the constraints in one match entry must hold. Separate entries in `matches` are
alternatives, so the rule applies if any one of them matches. For example, `method: GET` and a
`/orders` path prefix in the same entry select GET requests under `/orders`. In separate
entries, they select all GET requests and all requests under `/orders`.

A match accepts any combination of the following fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: What it matches
    key: matches
rows:
  - field: "`path`"
    matches: "`type` (`Exact`, `PathPrefix`, or `RegularExpression`) with the pattern in `value`. `Exact` and `PathPrefix` values must be absolute, and a `PathPrefix` other than `/` can't end in a slash."
  - field: "`method`"
    matches: "One of `CONNECT`, `DELETE`, `GET`, `HEAD`, `OPTIONS`, `PATCH`, `POST`, `PUT`, or `TRACE`."
  - field: "`headers`"
    matches: "A list of header matches. `type` can be `Exact` (default), `Prefix`, `RegularExpression`, `Present`, or `Absent`. `Present` and `Absent` take no `value`."
  - field: "`queryParams`"
    matches: "A list of `name` and `value` pairs, with `type` `Exact` or `RegularExpression`. All entries must match, and each name can appear only once."
{% endtable %}

A `PathPrefix` matches whole path segments. The prefix `/api` matches `/api` and `/api/v1`,
but not `/apiary`.

## Rule precedence

Rules are ordered by specificity, not by the order they're written in, following the Gateway
API precedence rules. The following criteria define precedence, in this order:

1. A match without `path` is treated as `PathPrefix /`. It ties with an explicit `PathPrefix /`
   catch-all, so the later criteria decide, and it ranks below `Exact` and longer prefixes but
   above every `RegularExpression` match.
2. `Exact` beats `PathPrefix`, which beats `RegularExpression`.
3. Between prefixes, or between regular expressions, the longer `value` wins.
4. A rule with a `method` match beats one without.
5. A rule with more `headers` matches wins.
6. A rule with more `queryParams` matches wins.

Ordering regular expressions by length is {{site.mesh_product_name}} behavior, and a longer
expression isn't necessarily more restrictive. Avoid overlapping expressions whose priority
depends on regex semantics.

## Unmatched requests

Once any `MeshHTTPRoute` applies to a destination, a request that matches none of its rules
gets a `404` and isn't passed to the destination. This covers:

* Paths that no rule mentions.
* Every HTTP port of the destination, when `to[].targetRef` names a `MeshService` without a
  `sectionName`.

Non-HTTP ports and destinations with no `MeshHTTPRoute` aren't affected. On a gRPC
destination, the client sees the `404` as `UNIMPLEMENTED`.

Watch for routes written only so another policy can target them. For example, a route
matching `/api`, added so a `MeshTimeout` can target it, returns `404` on every other path of
that destination. The following example adds a catch-all rule that keeps unmatched traffic
flowing:

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

Put the catch-all on the same route if the policies targeting that route should also cover
unmatched traffic. Otherwise, put it on a second `MeshHTTPRoute`.

## Filters

`default.filters` lists changes applied to matched requests. Each entry sets `type` and the
matching configuration object. `filters` accepts the following types:

{% table %}
columns:
  - title: "`type`"
    key: type
  - title: Effect
    key: effect
rows:
  - type: "`RequestHeaderModifier`"
    effect: "Sets, adds, or removes request headers with `set`, `add`, and `remove`. At least one is required, and a header name can appear only once across all three."
  - type: "`ResponseHeaderModifier`"
    effect: "Sets, adds, or removes response headers with `set`, `add`, and `remove`. At least one is required, and a header name can appear only once across all three."
  - type: "`RequestRedirect`"
    effect: "Tells the client to make another request, instead of forwarding. Takes `scheme` (`http` or `https`), `hostname`, `port`, `path`, and `statusCode` (`301`, `302`, `303`, `307`, or `308`, default `302`)."
  - type: "`URLRewrite`"
    effect: "Rewrites `hostname` and `path` before forwarding, without involving the client."
  - type: "`RequestMirror`"
    effect: "Copies requests to a second destination in `backendRef` and discards its responses. `percentage` sets how many are copied, and defaults to all."
{% endtable %}

A `backendRefs` entry can also have its own filters, but only `RequestHeaderModifier`.

A mirror receives real requests, so it can perform writes or other side effects even though
its response is ignored. Use a mirror destination that's prepared for copies of production
traffic.

`RequestRedirect` and `URLRewrite` can also change the path. Set `path.type` to one of the
following values, and put the new path in the field with the same name:

{% table %}
columns:
  - title: "`path.type`"
    key: type
  - title: Effect
    key: effect
rows:
  - type: "`ReplaceFullPath`"
    effect: "Replaces the whole path with the `replaceFullPath` value."
  - type: "`ReplacePrefixMatch`"
    effect: "Replaces only the part of the path that the `PathPrefix` match matched, and keeps the rest. The rule is rejected if any of its `matches` entries isn't a `PathPrefix` path match."
{% endtable %}

For example, the following filter forwards `/api/users` as `/v2/users`:

```yaml
rules:
  - matches:
      - path:
          type: PathPrefix
          value: /api
    default:
      filters:
        - type: URLRewrite
          urlRewrite:
            path:
              type: ReplacePrefixMatch
              replacePrefixMatch: /v2
```

## Splitting traffic across destinations

`default.backendRefs` lists destinations, each with a `weight` that defaults to 1. A request
goes to one of them in proportion to its weight. Each entry takes the following fields:

* `kind`: `MeshService`, `MeshExternalService`, or `MeshMultiZoneService`, selected by
  `labels`.
* `port`: the destination port. Required for `MeshMultiZoneService`, and for a `MeshService`
  with more than one port. Without it, the entry doesn't resolve.

Without `backendRefs`, matched requests go to the destination in the `to` entry, so a rule
that only sets filters doesn't need to repeat it.

An unusable `backendRefs` list behaves as follows:

{% table %}
columns:
  - title: Situation
    key: situation
  - title: Response
    key: response
rows:
  - situation: "No entry resolves to an existing resource, or every entry names a port the destination doesn't have."
    response: "`500` for every request the rule matches. Traffic isn't passed to the destination."
  - situation: "Some entries resolve and some don't."
    response: "`500` for the unresolved share of the weight. The rest is split across the entries that resolved."
  - situation: "Every entry has weight `0`."
    response: "`503`, treated as no available backend."
{% endtable %}

A reference that hasn't resolved yet behaves like one that never will. For example, a route
pointing at a `MeshService` that KDS hasn't synced into the zone fails its requests until the
reference resolves. A rule with a `RequestRedirect` filter still redirects, because it doesn't
need an upstream.

## Overlapping policies

When several `MeshHTTPRoute` policies apply to the same proxy and destination, their rules are
merged, keyed on `matches`:

* Rules with identical `matches` have their `default` blocks merged, and the narrower policy
  can change that match's backend configuration.
* Rules with different `matches` are kept side by side.

The merge order depends on each policy's top-level `targetRef`. For more information, see
[Policy precedence](/mesh/policy-targeting/#policy-precedence). For example, a mesh-wide `/orders`
rule and a client-specific `/payments` rule both apply to that client, and request
specificity then picks among them.

When a proxy matches both a `MeshHTTPRoute` and a
[`MeshTCPRoute`](/mesh/policies/meshtcproute/) for the same destination, the `MeshHTTPRoute`
takes effect and the `MeshTCPRoute` is ignored.

## Validating HTTP routing

1. Send one request that matches each rule, and confirm that it reaches the expected backend.
   Confirm the receiving application through its logs or a response that identifies it.
1. If the route has no catch-all, send a request that matches no rule, and confirm that it
   returns `404`.
1. If the route splits traffic by weight, send enough requests to confirm the distribution.
1. If a request returns `500` or `503`, check `backendRefs`: the destination might not
   resolve, the named port might not exist, or all weights might be zero.

For the example in [Route two paths to different destinations](#route-two-paths-to-different-destinations),
confirm that `/orders` and `/orders/123` reach `orders` with their paths unchanged, and that
`/health` reaches `backend`.

{% table %}
columns:
  - title: Unexpected result
    key: unexpected
  - title: Check
    key: check
rows:
  - unexpected: "An unlisted path returns 404"
    check: "Add a catch-all if that path should keep normal routing."
  - unexpected: "The backend receives an unexpected path"
    check: "Matching doesn't change the path. Only `URLRewrite` does."
  - unexpected: "A fraction of requests returns 500"
    check: "Whether a weighted backend reference fails to resolve in the client's zone."
  - unexpected: "A backend resolves but requests fail"
    check: "Healthy endpoints, protocol compatibility, and destination permissions."
  - unexpected: "A narrower policy doesn't remove an old route"
    check: "Rules with different matches coexist. Review the effective matches from all applicable policies."
{% endtable %}
