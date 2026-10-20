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
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshproxypatch"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
---

The `MeshProxyPatch` policy edits the Envoy configuration {{site.mesh_product_name}} generates
for a proxy. It adds, patches, and removes clusters, listeners, filters, and virtual hosts
directly, to cover Envoy features that no policy exposes.

This policy runs after every other policy, so it sees their output and has the final say over
any field it sets. It's also tied to how {{site.mesh_product_name}} generates configuration. A
patch that matches a listener by name or a filter by position can stop matching after an
upgrade, and nothing reports it.

Use a dedicated policy whenever one exposes the behavior you need. Proxies that no
`MeshProxyPatch` selects get the configuration the other policies produce, unchanged.

{:.warning}
> A patch can remove routing or security filters, overwrite a generated resource, or
> produce configuration Envoy rejects. Start with a small set of proxies, save their
> working configuration, and verify both traffic behavior and configuration acceptance
> before expanding the selector.

## Add a Lua filter to outbound requests

The following example inserts a Lua filter before the router filter on outbound HTTP traffic
from proxies labeled `app: backend`:

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

What each field does:

* `targetRef` selects the proxies to patch: `Mesh`, or `Dataplane` with `labels`.
* `match.name` identifies the Envoy router filter, and `origin: outbound` limits the match to
  outbound HTTP filter chains.
* `AddBefore` inserts the Lua filter right before the router, so every matching outbound HTTP
  request gets the `x-header: test` header.

The policy has no `to` or `rules`, everything sits under `default.appendModifications`.

The example affects requests that `backend` sends, not requests arriving at its application.
It only works on outbound traffic the proxy parses as HTTP, because TCP and opaque TLS have no
HTTP router filter. The header is for demonstration and isn't an authenticated identity.

## Modification structure

`appendModifications` needs at least one entry. Each entry names exactly one Envoy resource
type, and carries the following fields:

- `operation`: what to do, from the operations that resource type accepts.
- `match`: which generated resources to act on. Without it, an operation that takes a match
  applies to every resource of that type.
- `value` or `jsonPatches`: what to apply. `Add` takes `value`, `Patch` takes exactly one of
  the two, and `Remove` takes neither.

To narrow the Envoy object being edited, use `match.listenerName` or `match.name`. Read the
current generated name instead of building it from a service name. Where supported, listener
tags refer to metadata on the generated listener, not to every label on the selected Dataplane.

`value` is a native Envoy resource in YAML, parsed against the Envoy proto. A wrong type or
enum value is rejected.

{:.warning}
> An unrecognized field name is accepted and dropped. A misspelled key passes validation, is
> stored in the policy as written, and then does nothing to the generated configuration.
> Check a new modification against the proxy's `/config_dump`, not against the stored policy.

## Resource types and their operations

Each resource type accepts the following operations and `match` fields. Any other operation is
rejected.

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

Some operations have extra requirements:

* `Add` on a cluster or listener takes no `match`. It replaces any existing resource with the
  same name.
* `Add` on a virtual host takes a `match` with `routeConfigurationName`, but not `match.name`.
  An outbound route configuration is named after the KRI of the destination port, in the form
  `kri_msvc_<mesh>_<zone>_<namespace>_<service>_<port>`, where `<port>` is the port's name, or
  its number when it has no name.
* `AddBefore` and `AddAfter` need `match.name` to say which filter to sit next to. If that
  filter isn't present, nothing is added.
* `Patch` on a filter needs `match.name`.

## Match on configuration origin

Every generated resource carries an `origin` that names the component that produced it. Use it
to target one kind of configuration without naming individual resources. `origin` accepts the
following values:

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
    what: "The passthrough listeners and clusters that transparent proxying adds."
  - origin: "`direct-access`"
    what: "Resources for direct access to other proxies."
  - origin: "`admin`"
    what: "The Envoy admin listener."
  - origin: "`prometheus`"
    what: "The listener and cluster Prometheus scrapes."
  - origin: "`ingress`, `egress`"
    what: "Cross-zone listeners and clusters."
  - origin: "`meshaccesslog`, `mesh-trace`, `open-telemetry`, `meshpassthrough`"
    what: "Resources added by `MeshAccessLog`, `MeshTrace`, `MeshMetric`, and `MeshPassthrough`."
  - origin: "`proxy-template-modifications`"
    what: "Clusters added by a `MeshProxyPatch`."
  - origin: "`mesh-proxy-patch`"
    what: "Listeners added by a `MeshProxyPatch`."
{% endtable %}

A later modification can match on `proxy-template-modifications` or `mesh-proxy-patch` to act
on what an earlier one added.

## Patch with a value or with JSON patches

`Patch` takes either a partial Envoy resource in `value`, or a list of
[JSON Patch](https://jsonpatch.com/) operations in `jsonPatches`, but not both. Each
`jsonPatches` entry takes:

* `op`: `add`, `remove`, `replace`, `move`, or `copy`
* `path`: the field to change
* `value`: for `add` and `replace`
* `from`: for `move` and `copy`

For a filter modification, paths start inside the filter's decoded `typedConfig`. For a
cluster, listener, or virtual host, paths start at the resource's root. Use JSON Patch to
replace a list instead of appending to it, and check array indexes against the generated
resource. Before using `replace`, confirm that the field exists on every matched filter,
because replacing a missing path fails.

The following example sets the stream idle timeout on inbound HTTP connection managers to show
the JSON Patch syntax. The path is `/streamIdleTimeout`, not `/typedConfig/streamIdleTimeout`.
For a real stream idle timeout, use [MeshTimeout](/mesh/policies/meshtimeout/) instead:

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

## Value merging on Patch

A `value` is merged into the matched resource instead of replacing it. The merge handles the
following kinds of field differently:

- Repeated fields: appended, not replaced. Patching a list of filters adds to it.
- Durations: replaced. Patching `connectTimeout` sets it.
- Circuit breaker thresholds and `perHostThresholds`: merged by routing priority. Every
  generated cluster already has a `DEFAULT`-priority threshold, and Envoy honors only the first
  threshold for a priority, so the patch merges into the existing one. A `value` that lists one
  priority twice keeps the first entry.

As a result, a `MeshProxyPatch` and a [MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/)
on the same cluster combine instead of conflicting. The patch wins the fields it names, and
the policy keeps the rest.

## Overlapping policies

Modifications run in list order, and each one sees the result of the previous ones. Policies
that apply to the same proxy append their `appendModifications` lists, so a narrower policy
doesn't replace a broader one. The merged order follows policy precedence, not edit time.

This means:

* One modification can add a cluster and a later one can patch it.
* If one modification removes the filter a later `AddBefore` names, the insertion has no match.
* Two additions can produce duplicate filters instead of one overriding the other.

Keep dependent modifications together, and inspect the merged result when several policies
select the same proxy.

## Validating the generated configuration

1. Confirm that the control plane accepts the policy.
1. Confirm that configuration generation succeeds and Envoy accepts the update. If the active
   configuration doesn't change, check the control plane for patch errors and the proxy for
   configuration-rejection messages.
1. Read the proxy's `/config_dump` and confirm that it contains the change. For the first
   example, look for `envoy.filters.http.lua` right before `envoy.filters.http.router` on an
   outbound filter chain.
1. Send test traffic and confirm the effect. For the first example, the destination receives
   `x-header: test`.
1. Repeat the `/config_dump` check after each {{site.mesh_product_name}} upgrade. A stored,
   valid patch can stop matching any generated resource.

Retrieve `/config_dump` from the proxy's local admin interface. Don't expose the admin listener
publicly. Compare only the intended resources with your saved baseline.

{% table %}
columns:
  - title: Unexpected result
    key: unexpected
  - title: Check
    key: check
rows:
  - unexpected: "No change and no error"
    check: "The exact resource name, the origin, and whether another modification removed the match."
  - unexpected: "A list contains duplicates"
    check: "Overlapping policies and the append behavior of `value` merges."
{% endtable %}

To roll back, remove or narrow the patch policy and check the regenerated configuration. This
restores what the remaining policies produce, which isn't necessarily the configuration you
saved before other policy changes. You don't need an inverse patch unless another patch must
stay in place.
