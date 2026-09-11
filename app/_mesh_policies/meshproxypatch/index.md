---
title: Mesh Proxy Patch
name: MeshProxyPatches
products:
- mesh
description: Change the Envoy configuration a proxy receives, where no policy covers what you need.
content_type: plugin
icon: meshproxypatch.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshproxypatch"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
---

`MeshProxyPatch` edits the Envoy configuration {{site.mesh_product_name}} generates for a proxy.
It adds, patches and removes clusters, listeners, filters and virtual hosts directly, which
covers the Envoy features no policy exposes.

It runs last, after every other policy, so a modification sees the configuration everything else
produced and has the final say over any field it sets. That also means it is coupled to the
configuration {{site.mesh_product_name}} happens to generate: a patch matching a listener by
name or a filter by position can stop matching after an upgrade changes how that configuration
is built, and nothing reports it beyond the patch no longer taking effect.

## Add a Lua filter to outbound requests

This policy applies to proxies labeled `app: backend` and inserts a Lua filter before the
router filter on their outbound HTTP traffic:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshProxyPatch
mesh: default
name: backend-lua-filter
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  default:
    appendModifications:
      - httpFilter:
          operation: AddBefore
          match:
            name: envoy.filters.http.router
            origin: outbound
          value: |
            name: envoy.filters.http.lua
            typedConfig:
              '@type': type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua
              inlineCode: |
                function envoy_on_request(request_handle)
                  request_handle:headers():add("x-header", "test")
                end
```
{% endpolicy_yaml %}

`targetRef` limits the patch to `backend` proxies. `match.name` identifies the existing Envoy
router filter, and `origin: outbound` limits the match to outbound HTTP filter chains.
`AddBefore` inserts the Lua filter immediately before that router, so every matching outbound
HTTP request receives the `x-header: test` header before it is forwarded.

## Where this policy applies

`spec.targetRef` selects the proxies whose configuration is patched, and accepts `Mesh` or
`Dataplane` with `labels`. There is no `to` or `rules`: the policy describes edits to one
proxy's configuration, so everything sits under `default.appendModifications`.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## What a modification looks like

`appendModifications` must contain at least one entry, and each entry names exactly one Envoy
resource type. Defining two in one entry is rejected with
`exactly one modification can be defined at a time`.

Within that, an entry carries:

- `operation` — what to do, from the set that resource type accepts.
- `match` — which generated resources to act on. Omitted, an operation that takes a match
  applies to every resource of that type.
- `value` or `jsonPatches` — what to apply. `Add` takes `value`; `Patch` takes exactly one of
  the two; `Remove` takes neither.

`value` is a native Envoy resource in YAML, parsed against the real Envoy proto. A value whose
type or enum is wrong is rejected on apply, naming the reason — `bad Duration: time: invalid
duration "not-a-duration"`, or `unknown value "NOT_A_REAL_TYPE" for enum
envoy.config.cluster.v3.Cluster.DiscoveryType`.

{:.warning}
> An unrecognized field name is **accepted and dropped**. The parser allows unknown fields, so a
> misspelled key passes validation, is stored in the policy exactly as written, and then does
> nothing to the generated configuration. Reading the policy back shows the field still there.
> Check a new modification against the proxy's `/config_dump` rather than against the stored
> policy.

## Resource types and their operations

{% table %}
columns:
  - title: Modification
    key: mod
  - title: Operations
    key: ops
  - title: Matches on
    key: match
rows:
  - mod: "`cluster`"
    ops: "`Add`, `Patch`, `Remove`"
    match: "`name`, `origin`"
  - mod: "`listener`"
    ops: "`Add`, `Patch`, `Remove`"
    match: "`name`, `origin`, `tags`"
  - mod: "`virtualHost`"
    ops: "`Add`, `Patch`, `Remove`"
    match: "`name`, `origin`, `routeConfigurationName`"
  - mod: "`networkFilter`"
    ops: "`AddFirst`, `AddLast`, `AddBefore`, `AddAfter`, `Patch`, `Remove`"
    match: "`name`, `origin`, `listenerName`, `listenerTags`"
  - mod: "`httpFilter`"
    ops: "`AddFirst`, `AddLast`, `AddBefore`, `AddAfter`, `Patch`, `Remove`"
    match: "`name`, `origin`, `listenerName`, `listenerTags`"
{% endtable %}

An operation outside a resource type's set is rejected, and the error names the ones it accepts.

`Add` on a cluster or listener takes no `match`, since there is nothing yet to match. It
replaces any existing resource of the same name rather than failing.

`AddBefore` and `AddAfter` need `match.name` to say which filter to sit next to, and are
rejected with `must be defined. You need to pick a filter before which this one will be added`
when it is missing. A filter naming one that is not present is not added at all. `Patch` on a
filter needs `match.name` as well.

`Add` on a virtual host takes a `match` for `routeConfigurationName`, since a virtual host
belongs to a route configuration, but `match.name` must not be defined.

## Match on where configuration came from

Every generated resource carries an `origin`, naming the component that produced it, which is
how a modification reaches one kind of configuration without naming individual resources.

{% table %}
columns:
  - title: "`origin`"
    key: origin
  - title: Resources
    key: what
rows:
  - origin: "`inbound`"
    what: "Listeners and clusters for traffic arriving at the proxy."
  - origin: "`outbound`"
    what: "Listeners and clusters for traffic the proxy sends."
  - origin: "`transparent`"
    what: "The passthrough listeners and clusters transparent proxying adds."
  - origin: "`direct-access`"
    what: "Resources for direct access to other proxies."
  - origin: "`admin`"
    what: "The Envoy admin listener."
  - origin: "`prometheus`"
    what: "The listener and cluster Prometheus scrapes."
  - origin: "`ingress`, `egress`"
    what: "Cross-zone listeners and clusters."
  - origin: "`meshaccesslog`, `mesh-trace`, `open-telemetry`, `meshpassthrough`"
    what: "Resources added by `MeshAccessLog`, `MeshTrace`, `MeshMetric` and `MeshPassthrough`."
{% endtable %}

Resources this policy adds itself carry an origin too, and it differs by type: an added cluster
is marked `proxy-template-modifications`, and an added listener `mesh-proxy-patch`. A later
modification matching on either origin acts on what an earlier one added.

## Patch with a value or with JSON patches

`Patch` takes either a partial Envoy resource in `value`, or a list of
[JSON Patch](https://jsonpatch.com/) operations in `jsonPatches`. Giving both is rejected.

`jsonPatches` entries take `op` — `add`, `remove`, `replace`, `move` or `copy` — a `path`, a
`value` for `add` and `replace`, and a `from` for `move` and `copy`:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshProxyPatch
mesh: default
name: backend-stream-idle-timeout
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  default:
    appendModifications:
      - networkFilter:
          operation: Patch
          match:
            name: envoy.filters.network.http_connection_manager
            origin: inbound
          jsonPatches:
            - op: replace
              path: /streamIdleTimeout
              value: 15s
```
{% endpolicy_yaml %}

## How a value merges on Patch

A `value` is merged into the matched resource rather than replacing it, and the merge treats
three kinds of field differently:

- A repeated field is **appended** to what the resource already has, not replaced. Patching a
  list of filters adds to it.
- A duration is **replaced**, so patching `connectTimeout` sets it rather than combining it.
- Circuit breaker thresholds are keyed by routing priority instead of appended. Every generated
  cluster already carries a `DEFAULT`-priority threshold, and Envoy honors only the first
  threshold for a priority, so appending a second would leave the patch as dead configuration.
  A patch merges into the threshold of the same priority, and a `value` listing one priority
  twice keeps the first entry. `per_host_thresholds` behaves the same way.

That last behavior means a `MeshProxyPatch` and a
[MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/) on one cluster combine rather than
conflict: the patch wins the fields it names, and the policy keeps the rest.

## Validate the generated configuration

Read the selected proxy's Envoy `/config_dump` and confirm that the intended resource was
changed. For the first example, find `envoy.filters.http.lua` immediately before
`envoy.filters.http.router` on an outbound filter chain. Then send a request through that proxy
and confirm that the destination receives `x-header: test`.

Repeat the configuration check after upgrading {{site.mesh_product_name}}. A
`MeshProxyPatch` can remain valid and stored while matching no generated resource, so successful
resource validation alone does not prove that the patch still applies.
