---
title: "Migrate policies to {{site.mesh_product_name}} 3.x"
description: "Prepare and migrate policies from {{site.mesh_product_name}} 2.x to 3.x, including shared API changes, policy-specific rewrites, and validation checks."
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - migration
  - upgrade
  - policy
related_resources:
  - text: Check readiness for {{site.mesh_product_name}} 3.x
    url: /mesh/check-upgrade-readiness/
  - text: Migrate zone proxies to {{site.mesh_product_name}} 3.x
    url: /mesh/migrate-zone-proxies-to-3/
  - text: How policies select traffic
    url: /mesh/policy-targeting/
  - text: Upgrade {{site.mesh_product_name}}
    url: /mesh/upgrade/
  - text: Version-specific upgrade notes
    url: /mesh/version-specific-upgrade-notes/
---

This guide helps teams migrate policy configuration from {{site.mesh_product_name}} 2.x to 3.x.
It separates changes shared by several policies from policy-specific rewrites, and identifies
the changes that can alter traffic without producing a validation error.

Use it alongside the [{{site.mesh_product_name}} upgrade guide](/mesh/upgrade/) and the
[version-specific upgrade notes](/mesh/version-specific-upgrade-notes/), which cover control
plane, data plane, and deployment changes outside the policy APIs.

{:.warning}
> Complete these policy changes before upgrading any control plane. A policy already stored in
> the control plane is not validated again. A resource carrying a removed field can keep working in its current
> zone, then fail to sync into a zone after that zone is upgraded.

The guide calls out four kinds of changes:

- **Rejected on apply.** The control plane returns a validation error, so the policy cannot be
  written until it is fixed. These announce themselves.
- **Accepted and ignored on Kubernetes.** `kubectl apply` prunes a removed field and prints a
  warning. The resource applies, but the setting does nothing. On Universal, which is where the
  global control plane runs in 3.x, the API and `kumactl apply` reject the resource with
  `<field>: unknown field` instead. A resource already stored with the field keeps loading, and
  the field is ignored. `Mesh` and `Dataplane` have no generated schema, so removed fields on
  them are ignored on every platform.
- **Accepted with different behavior.** The same configuration remains valid, but routing,
  precedence, defaults, or generated proxy configuration changes.
- **Resource removed or inert.** The old object may remain stored, but the control plane no
  longer uses it to generate proxy configuration.

The last three are the highest-risk changes because a successful apply does not prove that the
old behavior was preserved.

## Migration workflow

Follow this order so later policy rewrites build on identities and resources that already exist:

1. **Run the readiness checker, then export the current state.**
   [Create a {{site.mesh_product_name}} 3.x readiness report](/mesh/check-upgrade-readiness/) and save every `Mesh`,
   policy, legacy policy, and observability backend from the global and zone control planes.
   Include resources that are normally generated or managed through GitOps, not only resources
   applied by hand. Use the report to identify which sections of this guide apply.
1. **Stage workload identity first.** Follow
   [Migrate mesh mTLS to MeshIdentity](/mesh/migrate-mtls-to-meshidentity/): publish SPIFFE IDs
   with a non-issuing `MeshIdentity`, rewrite `MeshTrafficPermission` and `MeshTLS`, deploy
   mesh-scoped egress if you use `MeshExternalService`, then roll out the issuing identity and
   confirm its [MeshTrust](#meshtrust).
1. **Rewrite the shared policy shape.** Replace legacy top-level target kinds, switch real
   resource references to labels, and move inbound configuration from `from` to `rules`. Apply
   the changes under [Changes that affect every policy](#changes-that-affect-every-policy) to
   every policy type before working through policy-specific fields.
1. **Fix routing before policies that attach to routes.** Migrate `MeshHTTPRoute` and
   `MeshTCPRoute` backend references, then decide how unmatched HTTP requests should behave.
   Retry, timeout, access-log, and load-balancing policies can all depend on those routes.
1. **Apply the policy-specific rewrites.** Use the [policy migration index](#policy-migration-index)
   to open only the sections relevant to resources in your deployment.
1. **Read every changed resource back.** Confirm that Kubernetes CRD pruning did not remove a
   field that carried the intended behavior. Pay particular
   attention to a `Dataplane` `targetRef` that comes back without `labels`.
1. **Validate a representative traffic path.** Check identity, authorization, routing,
   resilience, and telemetry on the first upgraded non-production zone before upgrading the
   remaining zones. Use
   [Validate the migrated policies](#validate-the-migrated-policies) as the final gate.

## Policy migration index

The detailed policy sections are a reference rather than a second sequence of steps. Start with
the policies present in your exported configuration.

{% table %}
columns:
  - title: Policy or resource
    key: policy
  - title: Main migration work
    key: main
  - title: Risk if missed
    key: risk
rows:
  - policy: "[MeshIdentity](#meshidentity)"
    main: "Replace `Mesh.mtls`; coordinate identities, trust, and permissions."
    risk: "Proxies can lose mTLS and serve plaintext."
  - policy: "[MeshTrust](#meshtrust)"
    main: "Preserve external and transitional trust; remove generated trusts deliberately."
    risk: "Peers can stop verifying workload certificates."
  - policy: "[MeshTrafficPermission](#meshtrafficpermission)"
    main: "Stage identity first, rewrite `from` as `rules`, and remove deny-all rules."
    risk: "Traffic is denied, or intended grants match no identity."
  - policy: "[MeshTLS](#meshtls)"
    main: "Preserve permissive mode explicitly and rewrite `from` as `rules`."
    risk: "Plaintext is unexpectedly allowed or rejected."
  - policy: "[MeshPassthrough](#meshpassthrough)"
    main: "Allow external destinations explicitly, add a port to exact domain matches, and resolve filter-chain collisions."
    risk: "External traffic stops working."
  - policy: "[MeshHTTPRoute](#meshhttproute)"
    main: "Rewrite selectors and backend refs; add intentional catch-all behavior."
    risk: "Requests return `404`, `500`, or `503`."
  - policy: "[MeshTCPRoute](#meshtcproute)"
    main: "Add required backend refs and resolve every destination."
    risk: "Connections lose traffic shares or fail to connect."
  - policy: "[MeshLoadBalancingStrategy](#meshloadbalancingstrategy)"
    main: "Move hash policies and cross-zone failover configuration."
    risk: "Session affinity or locality behavior changes silently."
  - policy: "[MeshCircuitBreaker](#meshcircuitbreaker)"
    main: "Move `healthyPanicThreshold` and review proxy patches."
    risk: "Endpoint ejection uses an unintended threshold."
  - policy: "[MeshHealthCheck](#meshhealthcheck)"
    main: "Move `healthyPanicThreshold` to `MeshCircuitBreaker`."
    risk: "The removed field is silently pruned on Kubernetes."
  - policy: "[MeshRetry](#meshretry)"
    main: "Apply shared selector changes, lowercase header names, and replace `retriableResponseHeaders`."
    risk: "The policy is rejected on apply, or response headers don't trigger retries."
  - policy: "[MeshTimeout](#meshtimeout)"
    main: "Apply the shared selector, inbound-rule, route, and protocol changes."
    risk: "Timeouts disappear from some traffic paths."
  - policy: "[MeshFaultInjection](#meshfaultinjection)"
    main: "Move every fault from `to` into inbound `rules`."
    risk: "Faults are rejected, or a policy using `to` injects nothing."
  - policy: "[MeshRateLimit](#meshratelimit)"
    main: "Move every limit from `to` into `rules`, separate TCP and identity matches, and check intervals."
    risk: "Limits are rejected, or a policy using `to` limits nothing."
  - policy: "[MeshAccessLog](#meshaccesslog)"
    main: "Move mesh logging into a policy and use a shared OpenTelemetry backend."
    risk: "Access logs stop without an error."
  - policy: "[MeshMetric](#meshmetric)"
    main: "Move OpenTelemetry endpoints, prepare scrapers for `ActiveMTLSBackend`, and migrate Kubernetes discovery from MADS."
    risk: "Metrics stop or remote scrapes are refused."
  - policy: "[MeshTrace](#meshtrace)"
    main: "Move OpenTelemetry endpoints into `MeshOpenTelemetryBackend`."
    risk: "Trace export is skipped."
  - policy: "[MeshOPA](#meshopa)"
    main: "Rewrite secure data sources and targeting; remove legacy `OPAPolicy`."
    risk: "Authorization evaluates a wider scope or stops applying."
  - policy: "[MeshProxyPatch](#meshproxypatch)"
    main: "Replace gateway-origin matches and review circuit-breaker patches."
    risk: "Patches stop matching or begin overriding policy fields."
  - policy: "[MeshGlobalRateLimit](#meshglobalratelimit)"
    main: "Remove the policy, service, configuration, and optional leftover CRD."
    risk: "Fleet-wide limits disappear because there is no 3.x replacement."
{% endtable %}

## Changes that affect every policy

### Legacy `targetRef` kinds are removed

`spec.targetRef.kind` accepts `Mesh` and `Dataplane`. `MeshSubset`, `MeshService`,
`MeshServiceSubset` and `MeshGateway` are rejected with
`in body should be one of [Mesh Dataplane]`.

A subset selector becomes `kind: Dataplane` with the equivalent labels:

```yaml
# 2.x
targetRef:
  kind: MeshServiceSubset
  tags:
    kuma.io/service: payments
    version: v1

# 3.x
targetRef:
  kind: Dataplane
  labels:
    app: payments
    version: v1
```

A `MeshGateway` selector also becomes `kind: Dataplane`. The built-in gateway is removed, and a
delegated gateway is an ordinary `Dataplane` as far as the control plane is concerned.

{:.warning}
> `kind: Dataplane` selects proxies by `labels` only. On Kubernetes, a reference carrying `name`
> or `namespace` instead is accepted. Those fields are not in the schema, so they are pruned,
> and what remains is a bare `kind: Dataplane`, which selects every proxy in the mesh. On Universal the policy
> is rejected with `spec.targetRef.name: unknown field`. A policy written for
> one destination silently becomes a policy that applies to all of them. Read the policy back
> after rewriting one: a stored `targetRef` with a `kind` and no `labels` covers the whole mesh.

### References select resources by labels

A reference to a specific resource, such as a `Dataplane` or a `MeshService`, selects it by
`labels`. `name` and `namespace` are no longer fields of a reference. Each field accepts a
different set of kinds:

{% table %}
columns:
  - title: Field
    key: field
  - title: Accepted kinds
    key: kinds
rows:
  - field: "`spec.targetRef`"
    kinds: "`Mesh`, `Dataplane`"
  - field: "`spec.to[].targetRef`"
    kinds: "`Mesh`, `MeshService`, `MeshExternalService`, `MeshMultiZoneService`, `MeshHTTPRoute`. Each policy accepts a subset; see its own page."
  - field: "`backendRefs[]`"
    kinds: "`MeshService`, `MeshExternalService`, `MeshMultiZoneService`"
{% endtable %}

In `spec.to[].targetRef`, every kind except `Mesh` requires `labels`, and a reference without
them is rejected with `labels: must be set when kind is MeshService`. A `backendRef` without
`labels` is accepted but resolves to nothing, so check it as described in
[Check that every `backendRef` resolves](#check-that-every-backendref-resolves).

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

`sectionName` is unchanged and still names a `MeshService` port or a `Dataplane` inbound.

See [How policies select traffic](/mesh/policy-targeting/) for how each kind is matched.

### The `from` array is replaced by `rules`

Inbound configuration moves from `spec.from`, which matched clients by a `targetRef`, to
`spec.rules`, which match them by the identity they present. On Universal, the API and
`kumactl apply` reject any policy that still sets `from` with `spec.from: unknown field`. On
Kubernetes, `kubectl apply` prunes `from`, and what happens next depends on the policy:

{% table %}
columns:
  - title: Policy
    key: policy
  - title: "`from` alongside `to` or `rules`"
    key: stored
  - title: When `from` was the only field
    key: only
rows:
  - policy: "`MeshTrafficPermission`"
    stored: "Accepted. The policy applies with its `rules` only."
    only: "Rejected with `spec (): policy must define rules`."
  - policy: "`MeshAccessLog`, `MeshCircuitBreaker`, `MeshTimeout`, `MeshRateLimit`"
    stored: "Accepted and dropped. The policy applies and its inbound configuration is gone."
    only: "Rejected with `spec (): at least one of 'to' or 'rules' has to be defined`."
  - policy: "`MeshFaultInjection`, [`MeshTLS`](#meshtls)"
    stored: "Accepted and dropped. The policy applies and its inbound configuration is gone."
    only: "Accepted with an empty spec. The policy applies and configures nothing."
{% endtable %}

A `from` entry targeting `kind: Mesh`, meaning every client, becomes a single rule with no
`matches`:

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

A `from` entry that named a narrower set of clients becomes a rule with `matches`, which take a
`spiffeID` (`Exact` or `Prefix`) or an `sni` (`Exact` only):

```yaml
rules:
  - matches:
      - spiffeID:
          type: Prefix
          value: spiffe://default.default.mesh.local/ns/kong-mesh-demo/sa/frontend
    default: {...}
```

`MeshCircuitBreaker` and `MeshTLS` rules have no `matches`, so a rule applies to every client of
the selected inbound, and a per-client `from` on those policies has no 3.x equivalent.

A client is now named by the identity it presents rather than by the tags it sets, so a client
that could previously be matched by declaring a tag no longer can. `MeshRetry`,
`MeshHealthCheck` and `MeshLoadBalancingStrategy` are unaffected: they configure the client
side and never had a `from`.

### A request matching no MeshHTTPRoute rule gets a 404

A request matching none of a `MeshHTTPRoute`'s rules used to reach the destination as if the
route did not exist. It now gets a `404`.

This reaches further than `MeshHTTPRoute` itself, because `MeshRetry`, `MeshTimeout`,
`MeshAccessLog` and `MeshLoadBalancingStrategy` can attach to a route through
`to[].targetRef.kind: MeshHTTPRoute`. A route that exists only to anchor one of those policies
now answers `404` on every path it does not match. On a gRPC destination that `404` reaches the
client as `UNIMPLEMENTED`.

Add a catch-all rule to any route that should keep passing unmatched traffic through:

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

The `404` covers every HTTP port of the destination when the `to[].targetRef` names a
`MeshService` without a `sectionName`. Ports whose protocol is not HTTP based are unaffected, as
is a destination with no `MeshHTTPRoute` at all.

On the route itself, the catch-all also inherits the policies attached to that route. Where that
is wrong (a 1s `MeshTimeout` that suits `/orders` but not a file download on another path), put
the catch-all in a second `MeshHTTPRoute` instead.

### Universal inbounds must declare their protocol

An inbound's protocol is now read only from `networking.inbound[].protocol`. The
`kuma.io/protocol` tag stays a regular tag that policies can match on, but it is no longer used
as a fallback when the field is unset. Kubernetes is unaffected, since the field is derived from
the `Service` port.

{:.warning}
> An inbound with no `protocol` is treated as an unknown protocol and served as plain TCP, which
> loses the L7 filters that depend on the protocol: the `http` timeouts in `MeshTimeout`,
> `MeshFaultInjection` entirely, the HTTP limits in `MeshRateLimit`, HTTP access log fields, and
> HTTP-aware routing. `MeshTimeout`'s `connectionTimeout` and `idleTimeout` sit outside `http`
> and still apply. Nothing rejects the `Dataplane`, so the change is silent.

Set `networking.inbound[].protocol` explicitly on every Universal `Dataplane` that declared its
protocol only through the tag.

### Legacy policy types are removed

The legacy policy types `TrafficPermission`, `TrafficRoute`, `TrafficLog`, `TrafficTrace`,
`HealthCheck`, `CircuitBreaker`, `Retry`, `Timeout`, `RateLimit`, `FaultInjection`,
`VirtualOutbound` and `ProxyTemplate` are removed. The control plane no longer serves, syncs or
accepts them, their CRDs are no longer installed, and stored resources are not migrated.
Migrate each one to its `Mesh*` replacement and delete the old resources before upgrading.

For access control this fails closed: an inbound that relied on a `TrafficPermission` grant with
no equivalent `MeshTrafficPermission` now defaults to deny. Every mTLS inbound still gets an
RBAC filter.

The control plane also no longer creates the default allow-all `TrafficPermission` and
route-all `TrafficRoute` when a `Mesh` is created.

## Changes that affect MeshHTTPRoute and MeshTCPRoute

### MeshServiceSubset is no longer a `backendRef` kind

`backendRefs[]` accepts `MeshService`, `MeshExternalService` and `MeshMultiZoneService`, and
`tags` is gone from the `backendRef` schema entirely. On `MeshHTTPRoute` this covers the
`RequestMirror` filter's `backendRef` too.

A stored route carrying a subset reference keeps being served, but the control plane no longer
resolves that kind, so the reference counts as unresolved. What that costs differs by policy:
a `MeshHTTPRoute` rule answers `500`, and a `MeshTCPRoute` rule loses that share of its
connections.

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

### A route names a destination, not the mesh

`to[].targetRef` accepts `MeshService`, `MeshExternalService` and `MeshMultiZoneService`.
`Mesh` is rejected with `value 'Mesh' is not supported`, so the 2.x gateway form (a
`MeshGateway` top-level `targetRef` with `to[].targetRef.kind: Mesh`) has no equivalent on
either route policy. Name the destination directly.

## MeshTrafficPermission

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [the `from` to `rules` move](#the-from-array-is-replaced-by-rules) and [the legacy policy removal](#legacy-policy-types-are-removed).

This migration can take traffic away. `from` matched clients by the tags they carried, and
`rules` match them by the identity they present, so a mesh whose proxies have no workload
identity has nothing for a rule to match, and everything it used to allow is denied.

### Give the mesh a MeshIdentity

`rules` match on the SPIFFE ID a client presents, which a proxy only has once the mesh issues
one. `Mesh.mtls` is removed from the API and no longer produces mTLS, so identity comes from a
[MeshIdentity](/mesh/policies/meshidentity/).

Until every proxy a policy covers has an identity, a rewritten policy matches nothing, and
traffic that matches no rule is denied.

Follow [Migrate mesh mTLS to MeshIdentity](/mesh/migrate-mtls-to-meshidentity/) for the order:
publish the future SPIFFE IDs with a non-issuing `MeshIdentity`, rewrite this policy and
`MeshTLS` for those IDs, deploy mesh-scoped egress if you use `MeshExternalService`, then canary
and expand the issuing identity and verify every proxy before upgrading.

### Rewrite `from` as `rules`, and `action` as a list

`spec.from` is removed, along with `action` and the client `targetRef` it matched on.

```yaml
# 2.x
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: payments
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: orders
      default:
        action: Allow

# 3.x
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: payments
  rules:
    - default:
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://default.default.mesh.local/ns/kong-mesh-demo/sa/orders
```

`action: Allow` becomes an entry in `allow`, `action: Deny` an entry in `deny`, and
`action: AllowWithShadowDeny` an entry in `allowWithShadowDeny`.

Every entry in `allow`, `deny` and `allowWithShadowDeny` must set `spiffeID`, `sni`, or both. An
empty match object, which 2.14 accepted, is rejected with
`must specify at least one of 'spiffeID' or 'sni'`. Fix stored policies on 2.14 before upgrading.

### Delete the mesh-wide deny

In 2.x the last matching rule won, so the documented pattern was a deny-all followed by
narrower allows that re-opened specific paths. Precedence is now fixed: every `deny` is
evaluated before every `allow`, so a deny-all can never be re-opened and the policy denies
everything.

Delete the deny-all and keep the allow rules. Traffic matching no rule is denied anyway, which
is what the deny-all was there to express.

### Drop the removed control plane settings

Three settings are gone and are ignored if left in place:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: What replaced it
    key: replacement
rows:
  - setting: "`KUMA_MESH_TRAFFIC_PERMISSION_DISABLE_CLIQUES_ALGORITHM`"
    replacement: "Nothing. Rule generation always uses the cliques-based grouping algorithm."
  - setting: "`experimental.autoReachableServices` / `KUMA_EXPERIMENTAL_AUTO_REACHABLE_SERVICES`"
    replacement: "Nothing derives reachable services any more. A data plane proxy without `reachableBackends` (the `kuma.io/reachable-backends` annotation on Kubernetes) gets no outbounds at all, unless `KUMA_DEFAULTS_RESTRICT_OUTBOUND` is set to `false`. Define reachable backends on every proxy before upgrading."
  - setting: "`defaults.createMeshRoutingResources` / `KUMA_DEFAULTS_CREATE_MESH_ROUTING_RESOURCES`"
    replacement: "Nothing. A new `Mesh` gets no default `TrafficPermission` or `TrafficRoute`."
{% endtable %}

## MeshAccessLog

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [labels-only selection](#references-select-resources-by-labels), [the `from` to `rules` move](#the-from-array-is-replaced-by-rules), [the `404` for an unmatched route request](#a-request-matching-no-meshhttproute-rule-gets-a-404), [the Universal inbound protocol change](#universal-inbounds-must-declare-their-protocol) and [the legacy policy removal](#legacy-policy-types-are-removed).

### Point OpenTelemetry backends at a MeshOpenTelemetryBackend

`openTelemetry.endpoint` is removed, and `openTelemetry.backendRef` is the only way to name a
collector. A policy still setting `endpoint` is rejected with
`openTelemetry.backendRef: must be defined`.

Create a [MeshOpenTelemetryBackend](/mesh/meshopentelemetrybackend/) carrying the endpoint, then reference it by labels:

```yaml
# 2.x
backends:
  - type: OpenTelemetry
    openTelemetry:
      endpoint: otel-collector.observability:4317

# 3.x
backends:
  - type: OpenTelemetry
    openTelemetry:
      backendRef:
        kind: MeshOpenTelemetryBackend
        labels:
          kuma.io/display-name: otel-collector
```

### OpenTelemetry backends now always export through kuma-dp

A `backendRef` pointing at a `MeshOpenTelemetryBackend` sends data through `kuma-dp`: Envoy
exports to a Unix socket and `kuma-dp` forwards it to the collector. Two settings used to make
Envoy export to the collector directly and are now removed:
`runtime.kubernetes.injector.otelPipeEnabled` (`KUMA_RUNTIME_KUBERNETES_INJECTOR_OTEL_PIPE_ENABLED`)
on the control plane, and `KUMA_DATAPLANE_RUNTIME_OTEL_PIPE_ENABLED` on the sidecar.

Nothing to do unless either was set to `false`. Both are ignored now, so remove them from the
control plane configuration and the sidecar environment. The same applies to `MeshTrace` and
`MeshMetric`.

### Move `Mesh.spec.logging` into a policy

`Mesh.spec.logging`, with its `LoggingBackend` definitions, is removed. A `Mesh` still setting
it applies successfully and the field is ignored, so mesh-wide access logging stops without an
error. Express the same backends as a `MeshAccessLog` targeting `kind: Mesh`.

## MeshCircuitBreaker

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [labels-only selection](#references-select-resources-by-labels) and [the `from` to `rules` move](#the-from-array-is-replaced-by-rules).

### Bring `healthyPanicThreshold` over from MeshHealthCheck

The field was removed from `MeshHealthCheck.to[].default` and now lives at
`MeshCircuitBreaker.to[].default.outlierDetection.healthyPanicThreshold`. Both policies
describe the health of the same endpoints, so the setting belongs with the one that ejects them.

{:.warning}
> On Kubernetes, an un-migrated `healthyPanicThreshold` is pruned, not rejected. The
> `MeshHealthCheck` carrying one still applies successfully, and the affected cluster falls back
> to Envoy's default panic threshold of 50%. On Universal the policy is rejected with an
> `unknown field` error for `healthyPanicThreshold`.

```yaml
# 2.x, on MeshHealthCheck
to:
  - targetRef:
      kind: Mesh
    default:
      interval: 10s
      timeout: 2s
      healthyPanicThreshold: 30
      http:
        path: /health

# 3.x, on MeshCircuitBreaker
to:
  - targetRef:
      kind: Mesh
    default:
      outlierDetection:
        healthyPanicThreshold: 30
```

Keep the rest of the `MeshHealthCheck` as it is. Only the threshold moves.

### Review MeshProxyPatch circuit breaker patches

A `MeshProxyPatch` patching `circuitBreakers` used to append a second threshold for a priority
the cluster already had, and Envoy honors only the first, so the patch was dead configuration
while `/config_dump` showed the requested values. The patch now merges into the existing
threshold instead.

Where a cluster is covered by both, `MeshProxyPatch` runs last and now wins the fields it sets,
and the policy keeps the rest. Remove patches written before this change that you no longer rely
on, along with any workaround added because the patch appeared to do nothing.

### `to[]` does not accept MeshHTTPRoute

Circuit breaking applies to a whole destination rather than to individual routes, so
`MeshCircuitBreaker` is one of the policies that does not accept `kind: MeshHTTPRoute` in
`to[].targetRef`.

## MeshHTTPRoute

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [labels-only selection](#references-select-resources-by-labels), [the `404` for an unmatched route request](#a-request-matching-no-meshhttproute-rule-gets-a-404), [MeshServiceSubset backend refs](#meshservicesubset-is-no-longer-a-backendref-kind) and [naming a destination rather than the mesh](#a-route-names-a-destination-not-the-mesh).

The `404` for an unmatched request is the change to plan for, and it is covered under
[A request matching no MeshHTTPRoute rule gets a 404](#a-request-matching-no-meshhttproute-rule-gets-a-404).

### Check that every `backendRef` resolves

A rule that declares `backendRefs` and resolves none of them used to fall back to the
destination named in its `to` entry. It now answers `500`. A `backendRef` naming a port the
destination does not have counts as unresolved as well, where it previously fell through to
another port of the same destination.

Both were misconfigurations that traffic survived, which is why they are worth an explicit
pass: after the upgrade they become visible traffic loss. The references to check are the ones
that were never exercised: a `MeshService` in another zone that KDS may not have synced, a
destination in another namespace, and any `backendRef` with an explicit `port` or `sectionName`.

A rule whose `backendRefs` all have weight `0` answers `503`, and a rule carrying a
`RequestRedirect` filter still redirects, since it answers without an upstream.

### Remove fields that are present in the schema but unimplemented

`to[].hostnames` and `urlRewrite.hostToBackendHostname` remain present in the schema but are not
implemented. Remove either field before migrating: setting `hostnames` is rejected with
`must not be defined`, and `hostToBackendHostname: true` with `must not be set`.

## MeshTCPRoute

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [labels-only selection](#references-select-resources-by-labels), [MeshServiceSubset backend refs](#meshservicesubset-is-no-longer-a-backendref-kind), [naming a destination rather than the mesh](#a-route-names-a-destination-not-the-mesh) and [the legacy policy removal](#legacy-policy-types-are-removed).

### `backendRefs` is now required

A rule must declare `backendRefs`. An empty or missing list is rejected with
`backendRefs: must be defined`. This differs from `MeshHTTPRoute`, where omitting the list
sends matched requests to the destination in the `to` entry.

`to` needs at least one entry, and a `to` entry accepts at most one rule.

### An unresolved `backendRef` costs the rule its destination

A TCP proxy has no status code to answer with, so an unresolved reference is dropped from the
split rather than answered with an error, and the rule loses that share of its connections.
Where every entry in a rule is unresolvable, the client gets no outbound listener for that
destination at all, and its connections fail at connect time.

## MeshIdentity

`MeshIdentity` and [MeshTrust](#meshtrust) are how a mesh issues and verifies workload
identities in 3.x. They are not policies and have no `targetRef`, so the [changes that affect every
policy](#changes-that-affect-every-policy) do not apply to them. What does apply is that they are now required.

{:.warning}
> `Mesh.mtls` is removed from the API, and the transport socket builders no longer read it. A
> proxy gets an mTLS transport socket only when a `MeshIdentity` matches it, with the
> certificate from the identity and the trust bundle from a `MeshTrust`. A mesh whose only
> identity source was `mtls` therefore serves and accepts **plaintext** after upgrading, and
> `MeshTLS` and `MeshTrafficPermission` no longer apply to its proxies at all.

Create a `MeshIdentity` for every mesh that had mTLS through `Mesh.mtls`, before upgrading. See
[Migrate mesh mTLS to MeshIdentity](/mesh/migrate-mtls-to-meshidentity/) for the rollout order,
[MeshIdentity](/mesh/policies/meshidentity/) for the provider options, and
[MeshTrafficPermission](#meshtrafficpermission) for the access control that depends on it.

### Stage changes to the trust domain and workload path

`spiffeID.trustDomain` and `spiffeID.path` are immutable: an update that changes either is
rejected with `is immutable, cannot be changed from ...`. Treat a new trust domain or path as an
identity migration, not an ordinary text edit.

The control plane renders the trust domain once and records it in `status.trustDomain`, so a
template that includes the zone name does not change when the zone is renamed. Read the
workload certificate's SPIFFE URI to verify its actual identity.

For a staged transition, create a second `MeshIdentity` under a different name, publish
the required trust, and allow both old and new caller identities in destination
permissions. Move a small group using a more specific selector, verify calls in both
directions, then expand. Remove the old issuer and trust only after no workload needs them.
Two trusted issuers alone do not guarantee access: authorization must also allow the new IDs.

Recreating under the same name is accepted and does converge, but it is not a migration: the
`MeshTrust` and the CA are keyed by the identity's name, so there is a window with one trust
domain in flight where certificates issued under the old one no longer verify.

## MeshTrust

A `MeshIdentity` with a `Bundled` provider creates the `MeshTrust` for its CA, so a mesh issuing
its own identities needs no `MeshTrust` written by hand. Write one to trust a CA the mesh does
not own, or to keep a second trust domain verifiable during a migration.

{:.warning}
> Deleting a `MeshIdentity` does not delete the `MeshTrust` it generated. The generated resource
> is owned by the zone that created it, so it outlives the identity and has to be removed from
> that zone.

`MeshService.spec.identities` also accepts SPIFFE IDs only now, where it previously took
dataplane tags.

## MeshLoadBalancingStrategy

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [labels-only selection](#references-select-resources-by-labels) and [the `404` for an unmatched route request](#a-request-matching-no-meshhttproute-rule-gets-a-404).

### Move hash policies out of the load balancer

`loadBalancer.ringHash.hashPolicies` and `loadBalancer.maglev.hashPolicies` are removed.
`to[].default.hashPolicies` is the only place for them.

{:.warning}
> On Kubernetes the nested field is pruned, not rejected. A policy still setting it is accepted,
> and reading it back shows an empty `ringHash: {}`. On Universal the policy is rejected with an
> `unknown field` error for `hashPolicies`. The algorithm stays as configured but has nothing left
> to hash, so requests that were pinned to an endpoint stop being pinned and spread across the
> destination instead.

```yaml
# 2.x
default:
  loadBalancer:
    type: RingHash
    ringHash:
      hashPolicies:
        - type: Header
          header:
            name: x-user

# 3.x
default:
  loadBalancer:
    type: RingHash
  hashPolicies:
    - type: Header
      header:
        name: x-user
```

### Move cross-zone failover onto a MeshMultiZoneService

`localityAwareness.crossZone` is now accepted only on a `to` entry targeting a
`MeshMultiZoneService`. On `Mesh`, `MeshService` or `MeshExternalService` it is rejected with
`crossZone is only supported when targetRef.kind is MeshMultiZoneService`.

A `MeshMultiZoneService` is the resource that represents one service across zones, which is what
a cross-zone failover order is about. Split a policy that configured both: keep `localZone` and
`loadBalancer` on the entry targeting the `MeshService`, and move `crossZone` to an entry
targeting the `MeshMultiZoneService`.

### Move `Mesh.spec.routing.localityAwareLoadBalancing` into a policy

That field is removed from the `Mesh` schema. A `Mesh` still setting it applies successfully and
the field is ignored. Locality awareness is on by default in this policy, so a `Mesh` that had
it enabled needs nothing; one that relied on its absence to spread traffic across zones needs
`localityAwareness.disabled: true` on the destinations concerned.

### Drop the zone egress caveats

The 2.x guidance about `MeshLoadBalancingStrategy` behind a zone egress no longer applies.
`ZoneEgress` and `ZoneIngress` are removed, so there is no shared L4 proxy holding long-lived
connections between zones, and no restriction on the top-level `targetRef` because of one.

## MeshRetry

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [labels-only selection](#references-select-resources-by-labels), [the `404` for an unmatched route request](#a-request-matching-no-meshhttproute-rule-gets-a-404) and [the legacy policy removal](#legacy-policy-types-are-removed).

### Lower-case every header name

Header names carry a lower-case-only pattern. A 2.x policy naming `Retry-After` in
`rateLimitedBackOff.resetHeaders` is rejected with
`resetHeaders[0].name in body should match '^[a-z0-9!#$%&'*+\-.^_\x60|~]+$'`. Write `retry-after`. HTTP
header names are case insensitive on the wire, so the matching is unaffected.

### Add a MeshRetry to new meshes that need retries

A new `Mesh` no longer comes with the default `mesh-retry-all-<mesh>` policy, so it does not
retry requests until you apply a `MeshRetry`. Existing meshes keep the default policies they
already have.

### Don't rely on `retriableResponseHeaders`

`retriableResponseHeaders` is accepted and passed to Envoy, but Envoy only uses these matchers
with its `retriable-headers` retry condition, which `retryOn` can't set. A policy that relied on
a response header to trigger retries doesn't retry on it. Use a `retryOn` condition instead,
such as a status code, and check the generated configuration. For more information, see
[Envoy's retry policy reference](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/route/v3/route_components.proto#config-route-v3-retrypolicy).

## MeshRateLimit

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [the `from` to `rules` move](#the-from-array-is-replaced-by-rules) and [the Universal inbound protocol change](#universal-inbounds-must-declare-their-protocol).

### Move every limit into `rules`

`to` and `rules` are now mutually exclusive, and which one a policy may use is decided by its
top-level `targetRef`:

- `kind: Dataplane` accepts `rules` only. Defining `to` is rejected with
  `spec.to: must not be defined`.
- `kind: Mesh` accepts `to` only, whose `targetRef` takes `kind: Mesh` and nothing else.
  Defining `rules` is rejected with `spec.rules: must not be defined`.

Setting both is rejected with `field 'to' must be empty when 'rules' is defined`.

The proxy applies limits only from `rules`. A `kind: Mesh` policy with `to` is accepted, but
limits nothing. Rewrite its limits as `rules` on a `kind: Dataplane` policy. For a mesh-wide
inbound limit, use `kind: Dataplane` with no `labels`, which selects every proxy in the mesh.

### Move TCP limits off rules that match a client

A rule whose `matches` contain a `spiffeID` cannot carry `local.tcp`. It is rejected with
`can't be specified when matches contain spiffeID because this field cannot be conditioned on
source identity`.

A client's identity comes out of the TLS handshake, which a connection-level limit counts rather
than inspects. Split such a rule: limit connections in a rule with no `spiffeID` match, and
limit that client's requests with `local.http`.

### Check every interval is above 50ms

`requestRate.interval` and `connectionRate.interval` must be greater than 50ms, and `num`
greater than 0. A shorter interval is rejected with `must be greater than: 50ms`.

## MeshMetric

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed).

### Point OpenTelemetry backends at a MeshOpenTelemetryBackend

`openTelemetry.endpoint` is removed, and `backendRef` is the only way to name a collector. A
policy still setting `endpoint` is rejected with `openTelemetry.backendRef: must be defined`.

```yaml
# 2.x
backends:
  - type: OpenTelemetry
    openTelemetry:
      endpoint: otel-collector:4317

# 3.x
backends:
  - type: OpenTelemetry
    openTelemetry:
      backendRef:
        kind: MeshOpenTelemetryBackend
        labels:
          kuma.io/display-name: otel-collector
```

The export path change under
[OpenTelemetry backends now always export through kuma-dp](#opentelemetry-backends-now-always-export-through-kuma-dp)
applies here too.

### Prepare scrapers for `ActiveMTLSBackend`

`prometheus.tls.mode: ActiveMTLSBackend` now secures the metrics endpoint with the workload
identity of the data plane proxy. A remote scraper must present a client certificate with a
SPIFFE ID that chains to a trust bundle the mesh trusts, such as a `MeshTrust` bundle. Scrapes
from the proxy's own address or from loopback stay plaintext over `http`. A proxy without a
workload identity accepts only these local scrapes.

{:.warning}
> In 2.x this mode produced a plaintext endpoint. After the upgrade, a remote scraper without a
> trusted client certificate is refused, so its metrics stop.

Before upgrading, give each remote scraper such a certificate, or change the mode. `Disabled`
keeps a plaintext endpoint, and `ProvidedTLS` serves TLS with a certificate and key you supply
to the sidecar:

```yaml
backends:
  - type: Prometheus
    prometheus:
      port: 5670
      tls:
        mode: ProvidedTLS
```

With `ProvidedTLS`, the paths go to the sidecar as `KUMA_DATAPLANE_RUNTIME_METRICS_CERT_PATH`
and `KUMA_DATAPLANE_RUNTIME_METRICS_KEY_PATH`.

### Move off MADS on Kubernetes

The Monitoring Assignment Discovery Service server no longer starts on Kubernetes control
planes, whatever `KUMA_MONITORING_ASSIGNMENT_SERVER_ENABLED` or `controlPlane.madsServer.enabled`
are set to, and the Helm chart stops rendering the `mads-server` port 5676 there. It stays
supported in universal mode, including universal-on-Kubernetes.

Kubernetes deployments that discovered proxies through MADS need Prometheus Kubernetes service
discovery against the endpoints this policy exposes instead.

## MeshOPA

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed).

### Rewrite the agent config and rego as secure data sources

`agentConfig` and every `appendPolicies[].rego` move from the old flat `DataSource` type, which
has been removed from the API, to `SecureDataSource`. The old type had no discriminator and
carried `inline`, `inlineString` or `secret` directly; the new one requires a `type` and nests
the value under a field of the same name.

{% table %}
columns:
  - title: Old field
    key: old
  - title: New field
    key: new
rows:
  - old: "`inlineString: <text>`"
    new: "`type: InsecureInline` with `insecureInline.value: <text>`"
  - old: "`inline: <base64>`"
    new: "`type: InsecureInline` with `insecureInline.value: <plain text>`"
  - old: "`secret: <name>`"
    new: "`type: Secret` with `secretRef: {kind: Secret, name: <name>}`"
{% endtable %}

{:.warning}
> `inline` was base64-encoded and `insecureInline.value` is plain text. Decode the old value
> when rewriting it, or the agent is handed base64 where it expects rego.

```yaml
# 2.x
rego:
  inlineString: |
    package envoy.authz
    default allow = false

# 3.x
rego:
  type: InsecureInline
  insecureInline:
    value: |
      package envoy.authz
      default allow = false
```

A policy in the old shape is rejected after upgrading, because the missing `type` discriminator
is a validation violation: `rego.type (): in body is required`.

An inline rego policy is compiled when the resource is applied, so the rewrite is checked at
write time. A module supplied through a `Secret` is resolved and compiled by the control
plane when generating agent configuration instead. Check source-loading and combined-module
compilation errors after applying; resource acceptance alone does not prove the policy is active.

### Replace a MeshService or named `targetRef`

`spec.targetRef.kind` accepts `Mesh` and `Dataplane` only. `MeshService` is rejected with
`in body should be one of [Mesh Dataplane]`, in the CRD enum as well as in the control plane, so
a policy keeping it fails to sync from a global control plane into an upgraded Zone.

{:.warning}
> `spec.targetRef.name`, `namespace` and `mesh` are removed. On Kubernetes they are **pruned
> rather than rejected** by the API server on the next write, and a policy already stored with
> them ignores them on either platform. A `MeshOPA` that used `name` to scope itself to one service therefore widens to every
> proxy matching `kind`, and its rego starts evaluating requests it never saw before. Nothing
> reports it. On Universal, a write that still sets them is rejected with
> `spec.targetRef.name: unknown field`.

```yaml
# 2.x
spec:
  targetRef:
    kind: MeshService
    name: backend

# 3.x
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
```

Check the effective scope of every `MeshOPA` after rewriting it, and before rolling proxies.

### Migrate off the legacy OPA policy resource

The legacy `OPAPolicy` resource (`config.kong-mesh.io/v1alpha1`) and its CRD are removed, and a
leftover object is rejected by the control plane after upgrading. Move to `MeshOPA` and delete
the old resources before upgrading.

The OPA integration has also used the same dynamic configuration mechanism as DNS and
`MeshMetric` since 2.13, which only ever worked with `MeshOPA`.

`kuma-dp` no longer loads an OPA agent configuration from a file. The `--opa-config-path` flag
and the `KMESH_OPA_CONFIG_PATH` and `KMESH_OPA_EXPERIMENTAL_USE_DYNAMIC_CONFIG` environment
variables are removed, and `kuma-dp` fails to start if the flag is still set. Move the file's
contents into `spec.default.agentConfig` on a `MeshOPA` before upgrading.

## MeshPassthrough

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed).

### Allow external destinations explicitly

`Mesh.spec.networking.outbound.passthrough` is removed. A `Mesh` still setting it applies
successfully and the field is ignored.

{:.warning}
> A data plane proxy using a transparent proxy that no `MeshPassthrough` selects now drops
> traffic to destinations outside the mesh, as if `passthroughMode: None` applied to it. A mesh
> that relied on the old default of `passthrough: true` loses passthrough, and nothing reports
> the change. A mesh that set it to `false` keeps blocking.

Before upgrading, allow the external destinations your workloads use with a
`MeshExternalService` or a `MeshPassthrough` (`passthroughMode: Matched` with `appendMatch`, or
`passthroughMode: All`). Setting `KUMA_DEFAULTS_RESTRICT_OUTBOUND` to `false` on the control
plane restores the previous allow-all behavior.

```yaml
type: MeshPassthrough
mesh: default
name: allow-external
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: Matched
    appendMatch:
      - type: Domain
        value: api.example.com
        port: 443
        protocol: tls
```

### Add a port to every exact domain match

A `Domain` match that is not a wildcard now requires `port`. The sidecar resolves the domain
itself and connects to the resolved address, so the destination no longer depends on the
address the client dialed. A match without a port is rejected with
`port must be defined for a domain, the sidecar resolves the domain to pin the destination`.

{:.warning}
> A policy stored before the upgrade with an exact `Domain` match and no port is not rejected,
> but that match stops applying. When it was the only match in the policy, the sidecar rejects all
> passthrough traffic until you add the port.

```yaml
# 2.x
appendMatch:
  - type: Domain
    value: api.example.com
    protocol: tls

# 3.x
appendMatch:
  - type: Domain
    value: api.example.com
    port: 443
    protocol: tls
```

Duplicate the entry to allow one domain on several ports, and make sure the sidecar can resolve
the domain: a domain it cannot resolve has no endpoint, so its traffic fails.

A wildcard `Domain`, such as `*.example.com`, has no address to resolve. Its traffic still goes
to the address the client dialed, and the match only restricts the TLS SNI or HTTP `Host`, so a
client can dial a different address while presenting an allowed name. Use IP or CIDR
restrictions, registered external destinations, and network controls when the address must be
constrained. HTTP-family wildcard domains require a port; TLS wildcard domains can omit it,
which allows all destination ports. Test allowed and unlisted ports as well as allowed and
unlisted names. See
[MeshPassthrough](/mesh/policies/meshpassthrough/) for matching and security boundaries.

### Resolve matches that describe the same filter chain

Two matches resolving to the same filter chain of the generated passthrough listener are now
rejected on apply. Such a policy used to be accepted, and Envoy then rejected the whole
listener, breaking passthrough traffic for every proxy the policy matched.

Matches collide when they configure the same port, or both configure no port, with two of
`grpc`, `http` and `http2`; with the same address written differently, including a CIDR with
host bits set or another textual form of an IPv6 address; or with `tcp` and `mysql` on one
address.

An already-applied policy with a conflict is not re-validated. The control plane keeps the first
match of the pair in `appendMatch` order, drops the later one, and names it in a debug log of
the `MeshPassthrough` component, so proxies previously stuck with a rejected listener recover on
their own. The next edit of that policy is rejected until the conflict is resolved.

## MeshGlobalRateLimit

The policy is removed, along with all of its control plane support and the rate-limit service
the Helm chart deployed. There is no replacement that limits requests across a fleet:
[MeshRateLimit](/mesh/policies/meshratelimit/) is a local limit, enforced by each proxy against
its own traffic.

Before upgrading, delete every `MeshGlobalRateLimit` resource and remove the rate-limit service
configuration:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Where
    key: where
rows:
  - setting: "`ratelimit.*` and `global.ratelimit.*`"
    where: "Helm values."
  - setting: "`KMESH_GLOBAL_RATE_LIMIT_*`"
    where: "Control plane environment."
  - setting: "`kmesh.globalRateLimit`"
    where: "Control plane configuration."
{% endtable %}

After upgrading, the control plane no longer registers, reconciles or serves the policy, so a
leftover resource becomes inert rather than rejected: it produces no Envoy or rate-limit
configuration, and nothing reports it.

Helm does not delete CRDs, so `meshglobalratelimits.kuma.io` stays on an existing cluster until
it is removed by hand:

```sh
kubectl delete crd meshglobalratelimits.kuma.io
```

## MeshProxyPatch

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed).

### Stop matching on the gateway origin

The built-in gateway is removed, so no resource carries `origin: gateway` any more. A
modification matching on it matches nothing, and nothing reports that: the policy applies, and
the patch silently stops taking effect.

A delegated gateway is an ordinary `Dataplane`, and its listeners and clusters carry `inbound`
and `outbound` like any other proxy's. Select the gateway with the top-level `targetRef` and
match on those origins instead.

The `ingress` and `egress` origins are unaffected. Standalone `ZoneIngress` and `ZoneEgress`
proxies are gone, but cross-zone listeners and clusters are still generated with those origins
on ordinary proxies.

### Check patches that set circuit breaker thresholds

A patch on `circuitBreakers` used to append a second threshold for a priority the cluster
already had, and Envoy honors only the first, so the patch was dead configuration while
`/config_dump` showed the requested values. Thresholds are now keyed by priority and the patch
merges into the existing one.

Where a cluster is also covered by a `MeshCircuitBreaker`, the patch now wins the fields it sets
and the policy keeps the rest. Remove patches written before this change that you no longer rely
on, along with any workaround added because the patch appeared to do nothing. This is the same
change described under
[Review MeshProxyPatch circuit breaker patches](#review-meshproxypatch-circuit-breaker-patches).

## MeshTLS

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed).

The following two changes are silent, and both can leave an inbound stricter or looser than intended.

### Author a policy for every mesh that relied on a permissive CA backend

`MeshTLS` is now the only thing that decides whether an inbound accepts plaintext. The mode is
resolved from the policy alone, and the `mode` of the enabled `Mesh` CA backend is no longer
consulted.

{:.warning}
> A mesh that set `mtls.backends[].mode: PERMISSIVE` and has no `MeshTLS` policy gets `Strict`
> inbounds after the upgrade, and plaintext traffic to them is rejected. `Mesh.mtls` is removed
> from the API, so there is nothing left to express the old intent.

Add a policy before upgrading for every mesh that relied on it:

```yaml
type: MeshTLS
mesh: default
name: permissive
spec:
  rules:
    - default:
        mode: Permissive
```

Meshes on `mtls.backends[].mode: STRICT`, meshes with mTLS disabled, and meshes that already
have a `MeshTLS` policy are unaffected. A mesh using `MeshIdentity` already resolved to `Strict`
without a policy.

### Rewrite `from` as `rules`

`spec.from` is removed, and `spec.rules` is the only place for inbound TLS configuration.

{:.warning}
> `MeshTLS` has no check that the remaining spec configures anything, so on Kubernetes a policy
> whose only field was `from` is **accepted**, not rejected, unlike most other policies that lost
> `from`. It applies with an empty spec, and reading it back shows nothing but the `targetRef`.
> Since an inbound with no policy is `Strict`, a `from` that was there to allow plaintext
> silently stops allowing it. On Universal the policy is rejected with `spec.from: unknown field`.

```yaml
# 2.x
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        mode: Permissive

# 3.x
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        mode: Permissive
```

Find the affected resources before upgrading:

```sh
kubectl get meshtls -A -o yaml | grep -B5 'from:'
```

## MeshTrace

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed).

### Point OpenTelemetry backends at a MeshOpenTelemetryBackend

`openTelemetry.endpoint` is removed, and `backendRef` is the only way to name a collector. A
policy still setting `endpoint` is rejected with `openTelemetry.backendRef: must be defined`.

```yaml
# 2.x
backends:
  - type: OpenTelemetry
    openTelemetry:
      endpoint: otel-collector:4317

# 3.x
backends:
  - type: OpenTelemetry
    openTelemetry:
      backendRef:
        kind: MeshOpenTelemetryBackend
        labels:
          kuma.io/display-name: otel-collector
```

Create the `MeshOpenTelemetryBackend` carrying the endpoint first, otherwise the reference does
not resolve and the backend is skipped. This is the same move `MeshAccessLog` makes, described
under
[Point OpenTelemetry backends at a MeshOpenTelemetryBackend](#point-opentelemetry-backends-at-a-meshopentelemetrybackend),
and the export path change under
[OpenTelemetry backends now always export through kuma-dp](#opentelemetry-backends-now-always-export-through-kuma-dp)
applies here too.

### Move `Mesh.spec.tracing` into a policy

`Mesh.spec.tracing` is removed. A `Mesh` still setting it applies successfully and the field is
ignored, so mesh-wide tracing stops without an error. Express the same backends as a
`MeshTrace` before upgrading.

## MeshTimeout

`MeshTimeout` has no policy-specific field changes. It is still affected by
[the `targetRef` rewrite](#legacy-targetref-kinds-are-removed),
[labels-only selection](#references-select-resources-by-labels),
[the `from` to `rules` move](#the-from-array-is-replaced-by-rules),
[the `404` for an unmatched route request](#a-request-matching-no-meshhttproute-rule-gets-a-404),
[the Universal inbound protocol change](#universal-inbounds-must-declare-their-protocol), and
[the legacy policy removal](#legacy-policy-types-are-removed).

## MeshHealthCheck

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed) and [labels-only selection](#references-select-resources-by-labels).

### Move `healthyPanicThreshold` to MeshCircuitBreaker

`to[].default.healthyPanicThreshold` is removed. See
[Bring healthyPanicThreshold over from MeshHealthCheck](#bring-healthypanicthreshold-over-from-meshhealthcheck)
for where it goes and what happens if it is left behind.

## MeshFaultInjection

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [the `from` to `rules` move](#the-from-array-is-replaced-by-rules), [the Universal inbound protocol change](#universal-inbounds-must-declare-their-protocol) and [the legacy policy removal](#legacy-policy-types-are-removed).

### Move every fault into `rules`

`spec.to` is accepted only when `spec.targetRef.kind` is `Mesh`, and then `to[].targetRef`
accepts `kind: Mesh` and nothing else. With `kind: Dataplane`, defining `to` at all is rejected
with `spec.to: must not be defined`.

The proxy applies faults only from `rules`, so a policy accepted with `to` injects no faults.
A fault is produced by the proxy answering the request, so configure it on that proxy's inbound
side:

1. Select the receiving proxies with `kind: Dataplane` and `labels`.
1. Move each `to[].default` into `rules[].default`.
1. To keep a fault limited to some callers, add `rules[].matches` with their `spiffeID`.

On Kubernetes, a `MeshFaultInjection` whose only field was `from` is accepted with an empty spec
and injects nothing. See [The `from` array is replaced by `rules`](#the-from-array-is-replaced-by-rules).

## Validate the migrated policies

A policy being accepted by the API only proves that its schema is valid. Complete the migration
by checking the behavior each policy is intended to produce.

1. Read the migrated resources back from the API. Confirm that no fields were silently removed
   and that every `Dataplane` reference includes the labels needed to select the intended proxy.
2. Confirm that every mesh has the required `MeshIdentity`, `MeshTrust`, and `MeshTLS`
   configuration. Test one connection that should be allowed and one that should be denied.
3. Exercise every route path that matters: a matching HTTP request, an unmatched HTTP request,
   every `backendRef`, and at least one cross-zone destination where applicable. Test TCP routes
   at connection time.
4. Trigger the behavior of resilience and traffic policies instead of checking only that the
   resources exist. Verify retries, timeouts, rate limits, circuit breakers, health checks, and
   fault injection against their expected outcomes.
5. Confirm that access logs, metrics, and traces reach their configured backends. For
   OpenTelemetry, check that each `MeshOpenTelemetryBackend` reports the expected policy
   references and that the relevant data planes report an OpenTelemetry status.
6. Review control plane and data plane status for unresolved references, rejected configuration,
   synchronization failures, and policies that no longer generate configuration.
7. While every control plane is still running the latest supported 2.14 patch, rerun the
   [{{site.mesh_product_name}} 3.x readiness checker](/mesh/check-upgrade-readiness/) against
   the complete estate. Do not upgrade the first zone until the report has no blockers or
   coverage gaps and its manual checks are complete. A clean report complements the behavioral
   checks in [Validate the migrated policies](#validate-the-migrated-policies); it does not
   replace them.
8. Upgrade the global control plane first, then a non-production zone. Repeat these checks
   there, and then proceed with the remaining zones.

The migration is complete when the stored resources match the intended 3.x configuration, the
proxies receive valid configuration, and both the expected success and failure paths behave as
designed.
