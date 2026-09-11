---
title: "Migrate policies to {{site.mesh_product_name}} 3"
description: "What changed in each policy between 2.x and 3, which changes are rejected on apply and which are accepted and silently do nothing, and the rewrite each one needs."
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
  - text: How policies select traffic
    url: /mesh/policy-targeting/
  - text: Upgrade {{site.mesh_product_name}}
    url: /mesh/upgrade/
  - text: Version-specific upgrade notes
    url: /mesh/version-specific-upgrade-notes/
---

This page covers the policy changes in {{site.mesh_product_name}} 3. For the control plane and
data plane changes around them, see the
[version-specific upgrade notes](/mesh/version-specific-upgrade-notes/).

Do the work before upgrading. A policy already stored in the control plane is not re-validated,
so one carrying a removed field keeps being served in the zone it was applied to, and then fails
to sync into any zone that is upgraded after it.

Two kinds of change are described below, and the difference decides how much attention each
needs:

- **Rejected on apply.** The control plane returns a validation error, so the policy cannot be
  written until it is fixed. These announce themselves.
- **Accepted and ignored.** The field is no longer in the schema, so it is pruned by CRD
  validation on Kubernetes and discarded during deserialization on Universal. The policy applies
  successfully and the setting does nothing. Nothing reports it, which is why these are listed
  first in each section.

## Changes that affect every policy

### Legacy targetRef kinds are removed

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
> `kind: Dataplane` selects proxies by `labels` only, and a reference carrying `name` or
> `namespace` instead is **accepted**. Those fields are not in the schema, so they are dropped,
> and what remains is a bare `kind: Dataplane` — every proxy in the mesh. A policy written for
> one destination silently becomes a policy that applies to all of them. Read the policy back
> after rewriting one: a stored `targetRef` with a `kind` and no `labels` covers the whole mesh.

`spec.to[].targetRef` narrows too, and the accepted kinds differ per policy. See
[How policies select traffic](/mesh/policy-targeting/) for the full set, and the policy's own
page for its `to`.

### Real resources are selected by labels

`Dataplane`, `MeshService`, `MeshExternalService`, `MeshMultiZoneService` and `MeshHTTPRoute`
are selected by `labels` only, in `spec.targetRef`, `spec.to[].targetRef` and `backendRefs[]`
alike. `name` and `namespace` select nothing.

Unlike the `Dataplane` case above, the four real-resource kinds require `labels`, so a reference
missing them is rejected with `labels (): must be set when kind is MeshService`.

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

### Two schema defaults are no longer stored

A linter fix removed two declared defaults from the API. Neither changes behaviour, and neither
needs action:

- Header matches on `MeshHTTPRoute` and `MeshRetry` no longer declare a default of `Exact` for
  `type`. An omitted `type` is still matched as `Exact`.
- Backend refs on `MeshHTTPRoute` and `MeshTCPRoute` no longer declare a default of `1` for
  `weight`. An omitted `weight` still counts as `1` when the route is resolved.

The only visible difference is that a resource omitting either field no longer comes back from
the API with the value filled in, which matters to anything comparing a stored resource against
what it applied.

### The `from` array is replaced by `rules`

Inbound configuration moves from `spec.from`, which matched clients by a `targetRef`, to
`spec.rules`, which match them by the identity they present. What happens to a policy that
still sets `from` depends on the policy:

{% table %}
columns:
  - title: Policy
    key: policy
  - title: A stored `from`
    key: stored
  - title: When `from` was the only field
    key: only
rows:
  - policy: "`MeshTrafficPermission`"
    stored: "Rejected."
    only: "Rejected with `spec (): policy must define rules`."
  - policy: "`MeshAccessLog`, `MeshCircuitBreaker`, `MeshTimeout`, `MeshFaultInjection`, `MeshRateLimit`"
    stored: "Accepted and dropped. The policy applies and its inbound configuration is gone."
    only: "Rejected with `spec (): at least one of 'to' or 'rules' has to be defined`."
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
is wrong — a 1s `MeshTimeout` that suits `/orders` but not a file download on another path — put
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

### Legacy policies no longer generate configuration

`TrafficPermission`, `TrafficRoute`, `TrafficLog`, `Timeout`, `Retry`, `FaultInjection` and
`VirtualOutbound` are no longer consumed when generating Envoy configuration. The resources are
still accepted and stored in this release, so nothing breaks on apply, but they have no effect.

For access control this fails closed: an inbound that relied on a `TrafficPermission` grant with
no equivalent `MeshTrafficPermission` now defaults to deny. Every mTLS inbound still gets an
RBAC filter.

The control plane also no longer creates the default allow-all `TrafficPermission` and
route-all `TrafficRoute` when a `Mesh` is created.

## Changes that affect both route policies

### MeshServiceSubset is no longer a backendRef kind

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
`Mesh` is rejected with `value 'Mesh' is not supported`, so the 2.x gateway form — a
`MeshGateway` top-level `targetRef` with `to[].targetRef.kind: Mesh` — has no equivalent on
either route policy. Name the destination directly.

## MeshTrafficPermission

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [the `from` to `rules` move](#the-from-array-is-replaced-by-rules) and [the legacy policies going inert](#legacy-policies-no-longer-generate-configuration).

This migration can take traffic away. `from` matched clients by the tags they carried, and
`rules` match them by the identity they present, so a mesh whose proxies have no workload
identity has nothing for a rule to match, and everything it used to allow is denied.

### Give the mesh a MeshIdentity

Do this first. `rules` match on the SPIFFE ID a client presents, which a proxy only has once
the mesh issues one. `Mesh.mtls` is removed from the API and no longer produces mTLS, so
identity comes from a [MeshIdentity](/mesh/policies/meshidentity/).

Until every proxy a policy covers has an identity, a rewritten policy matches nothing, and
traffic that matches no rule is denied.

### Rewrite from as rules, and action as a list

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
    replacement: "The control plane no longer derives a proxy's reachable services from its `MeshTrafficPermission` policies. To trim the outbound clusters a proxy receives, set reachable backends on the `Dataplane` — the `kuma.io/reachable-backends` annotation on Kubernetes. Access control itself is unaffected: traffic that no policy permits is still denied at the proxy, it is only no longer pruned from the configuration."
  - setting: "`defaults.createMeshRoutingResources` / `KUMA_DEFAULTS_CREATE_MESH_ROUTING_RESOURCES`"
    replacement: "Nothing. A new `Mesh` gets no default `TrafficPermission` or `TrafficRoute`."
{% endtable %}

## MeshAccessLog

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [labels-only selection](#real-resources-are-selected-by-labels), [the `from` to `rules` move](#the-from-array-is-replaced-by-rules), [the `404` for an unmatched route request](#a-request-matching-no-meshhttproute-rule-gets-a-404), [the Universal inbound protocol change](#universal-inbounds-must-declare-their-protocol) and [the legacy policies going inert](#legacy-policies-no-longer-generate-configuration).

### Point OpenTelemetry backends at a MeshOpenTelemetryBackend

`openTelemetry.endpoint` is removed, and `openTelemetry.backendRef` is the only way to name a
collector. A policy still setting `endpoint` is rejected with
`openTelemetry.backendRef (): must be defined`.

Create a `MeshOpenTelemetryBackend` carrying the endpoint, then reference it by labels:

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

### Move Mesh.spec.logging into a policy

`Mesh.spec.logging`, with its `LoggingBackend` definitions, is removed. A `Mesh` still setting
it applies successfully and the field is ignored, so mesh-wide access logging stops without an
error. Express the same backends as a `MeshAccessLog` targeting `kind: Mesh`.

## MeshCircuitBreaker

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [labels-only selection](#real-resources-are-selected-by-labels) and [the `from` to `rules` move](#the-from-array-is-replaced-by-rules).

### Bring healthyPanicThreshold over from MeshHealthCheck

The field was removed from `MeshHealthCheck.to[].default` and now lives at
`MeshCircuitBreaker.to[].default.outlierDetection.healthyPanicThreshold`. Both policies
describe the health of the same endpoints, so the setting belongs with the one that ejects them.

{:.warning}
> An un-migrated `healthyPanicThreshold` is dropped, not rejected. The `MeshHealthCheck`
> carrying one still applies successfully, and the affected cluster falls back to Envoy's
> default panic threshold of 50%.

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
the cluster already had, and Envoy honours only the first, so the patch was dead configuration
while `/config_dump` showed the requested values. The patch now merges into the existing
threshold instead.

Where a cluster is covered by both, `MeshProxyPatch` runs last and now wins the fields it sets,
and the policy keeps the rest. Remove patches written before this change that you no longer rely
on, along with any workaround added because the patch appeared to do nothing.

### to[] does not accept MeshHTTPRoute

Circuit breaking applies to a whole destination rather than to individual routes, so
`MeshCircuitBreaker` is one of the policies that does not accept `kind: MeshHTTPRoute` in
`to[].targetRef`.

## MeshHTTPRoute

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [labels-only selection](#real-resources-are-selected-by-labels), [the two dropped schema defaults](#two-schema-defaults-are-no-longer-stored), [the `404` for an unmatched route request](#a-request-matching-no-meshhttproute-rule-gets-a-404), [MeshServiceSubset backend refs](#meshservicesubset-is-no-longer-a-backendref-kind) and [naming a destination rather than the mesh](#a-route-names-a-destination-not-the-mesh).

The `404` for an unmatched request is the change to plan for, and it is covered under
[A request matching no MeshHTTPRoute rule gets a 404](#a-request-matching-no-meshhttproute-rule-gets-a-404).

### Check that every backendRef resolves

A rule that declares `backendRefs` and resolves none of them used to fall back to the
destination named in its `to` entry. It now answers `500`. A `backendRef` naming a port the
destination does not have counts as unresolved as well, where it previously fell through to
another port of the same destination.

Both were misconfigurations that traffic survived, which is why they are worth an explicit
pass: after the upgrade they become visible traffic loss. The references to check are the ones
that were never exercised — a `MeshService` in another zone that KDS may not have synced, a
destination in another namespace, and any `backendRef` with an explicit `port` or `sectionName`.

A rule whose `backendRefs` all have weight `0` answers `503`, and a rule carrying a
`RequestRedirect` filter still redirects, since it answers without an upstream.

### Fields that are accepted and unimplemented

`to[].hostnames` and `urlRewrite.hostToBackendHostname` are present in the schema but not
implemented, and setting either is rejected with `must not be defined`.

## MeshTCPRoute

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [labels-only selection](#real-resources-are-selected-by-labels), [the two dropped schema defaults](#two-schema-defaults-are-no-longer-stored), [MeshServiceSubset backend refs](#meshservicesubset-is-no-longer-a-backendref-kind), [naming a destination rather than the mesh](#a-route-names-a-destination-not-the-mesh) and [the legacy policies going inert](#legacy-policies-no-longer-generate-configuration).

### backendRefs is now required

A rule must declare `backendRefs`. An empty or missing list is rejected with
`backendRefs (): must be defined`. This differs from `MeshHTTPRoute`, where omitting the list
sends matched requests to the destination in the `to` entry.

`to` needs at least one entry, and a `to` entry accepts at most one rule.

### An unresolved backendRef costs the rule its destination

A TCP proxy has no status code to answer with, so an unresolved reference is dropped from the
split rather than answered with an error, and the rule loses that share of its connections.
Where every entry in a rule is unresolvable, the client gets no outbound listener for that
destination at all, and its connections fail at connect time.

## MeshLoadBalancingStrategy

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [labels-only selection](#real-resources-are-selected-by-labels) and [the `404` for an unmatched route request](#a-request-matching-no-meshhttproute-rule-gets-a-404).

### Move hash policies out of the load balancer

`loadBalancer.ringHash.hashPolicies` and `loadBalancer.maglev.hashPolicies` are removed.
`to[].default.hashPolicies` is the only place for them.

{:.warning}
> The nested field is dropped, not rejected. A policy still setting it is accepted, and reading
> it back shows an empty `ringHash: {}`. The algorithm stays as configured but has nothing left
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

### Move Mesh.spec.routing.localityAwareLoadBalancing into a policy

That field is removed from the `Mesh` schema. A `Mesh` still setting it applies successfully and
the field is ignored. Locality awareness is on by default in this policy, so a `Mesh` that had
it enabled needs nothing; one that relied on its absence to spread traffic across zones needs
`localityAwareness.disabled: true` on the destinations concerned.

### Drop the Zone Egress caveats

The 2.x guidance about `MeshLoadBalancingStrategy` behind a Zone Egress no longer applies.
`ZoneEgress` and `ZoneIngress` are removed, so there is no shared L4 proxy holding long-lived
connections between zones, and no restriction on the top-level `targetRef` because of one.

## MeshRetry

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [labels-only selection](#real-resources-are-selected-by-labels), [the two dropped schema defaults](#two-schema-defaults-are-no-longer-stored), [the `404` for an unmatched route request](#a-request-matching-no-meshhttproute-rule-gets-a-404) and [the legacy policies going inert](#legacy-policies-no-longer-generate-configuration).

### Lower-case every header name

Header names carry a lower-case-only pattern. A 2.x policy naming `Retry-After` in
`rateLimitedBackOff.resetHeaders` is rejected with
`name (): in body should match '^[a-z0-9!#$%&'*+\-.^_\x60|~]+$'`. Write `retry-after`. HTTP
header names are case insensitive on the wire, so the matching is unaffected.

## MeshRateLimit

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [the `from` to `rules` move](#the-from-array-is-replaced-by-rules) and [the Universal inbound protocol change](#universal-inbounds-must-declare-their-protocol).

### Split a policy that limited both inbound and gateway traffic

`to` and `rules` are now mutually exclusive, and which one a policy may use is decided by its
top-level `targetRef`:

- `kind: Dataplane` accepts `rules` only. Defining `to` is rejected with
  `spec.to (): must not be defined`.
- `kind: Mesh` accepts `to` only, whose `targetRef` takes `kind: Mesh` and nothing else.
  Defining `rules` is rejected with `spec.rules (): must not be defined`.

Setting both is rejected with `field 'to' must be empty when 'rules' is defined`.

A 2.x policy that carried both therefore becomes two policies. A mesh-wide inbound limit is
written as `kind: Dataplane` with no `labels`, which selects every proxy in the mesh;
`kind: Mesh` with `rules` is rejected.

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

## MeshPassthrough

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed).

### Replace a Mesh that disabled passthrough

`Mesh.spec.networking.outbound.passthrough` is removed. A `Mesh` still setting it applies
successfully and the field is ignored.

{:.warning}
> After the upgrade the control plane behaves as if `passthrough` was `true`, its previous
> default. A `Mesh` that set it to `false` therefore stops blocking traffic out of the mesh, and
> nothing reports the change.

Replace it before upgrading with a policy that says the same thing:

```yaml
type: MeshPassthrough
mesh: default
name: no-passthrough
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: None
```

### Add a port to every non-wildcard Domain match

A `Domain` match used to build an `ORIGINAL_DST` cluster: the sidecar matched the SNI or the
`Host` header and then sent the request to the address the client dialed. A workload covered by
the policy could dial any address, present an allowed domain, and reach that address through the
policy — the opposite of what an allowlist is for.

The sidecar now resolves the domain itself and connects to the resolved address, so the
destination no longer depends on the address the client dialed. Resolving needs a port, so a
`Domain` that is not a wildcard requires one. A policy without it is rejected with
`port must be defined for a domain, the sidecar resolves the domain to pin the destination`.

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

In a policy stored before the upgrade, such a match stops applying. Where it was the only match,
nothing is left to allow and the sidecar rejects all passthrough traffic for the proxies that
policy covers until the port is added.

Duplicate the entry to allow one domain on several ports, and check that the sidecar can resolve
those names: a domain it cannot resolve has no endpoint, so its traffic fails rather than
following the original destination.

A wildcard `Domain` keeps the old behaviour, because there is no single address to resolve. Its
traffic goes to the address the client dialed and the match only restricts the SNI or `Host`, so
a workload covered by a wildcard entry can still dial any address and present a matching name to
reach it. Prefer exact domains, IPs or CIDR ranges where the set of destinations is known.

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
already had, and Envoy honours only the first, so the patch was dead configuration while
`/config_dump` showed the requested values. Thresholds are now keyed by priority and the patch
merges into the existing one.

Where a cluster is also covered by a `MeshCircuitBreaker`, the patch now wins the fields it sets
and the policy keeps the rest. Remove patches written before this change that you no longer rely
on, along with any workaround added because the patch appeared to do nothing. This is the same
change described under
[Review MeshProxyPatch circuit breaker patches](#review-meshproxypatch-circuit-breaker-patches).

## MeshTimeout

MeshTimeout has no changes of its own. What it is subject to: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [labels-only selection](#real-resources-are-selected-by-labels), [the `from` to `rules` move](#the-from-array-is-replaced-by-rules), [the `404` for an unmatched route request](#a-request-matching-no-meshhttproute-rule-gets-a-404), [the Universal inbound protocol change](#universal-inbounds-must-declare-their-protocol) and [the legacy policies going inert](#legacy-policies-no-longer-generate-configuration).

## MeshHealthCheck

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed) and [labels-only selection](#real-resources-are-selected-by-labels).

### Move healthyPanicThreshold to MeshCircuitBreaker

`to[].default.healthyPanicThreshold` is removed. See
[Bring healthyPanicThreshold over from MeshHealthCheck](#bring-healthypanicthreshold-over-from-meshhealthcheck)
for where it goes and what happens if it is left behind.

## MeshFaultInjection

Shared changes that apply here: [the `targetRef` rewrite](#legacy-targetref-kinds-are-removed), [the `from` to `rules` move](#the-from-array-is-replaced-by-rules), [the Universal inbound protocol change](#universal-inbounds-must-declare-their-protocol) and [the legacy policies going inert](#legacy-policies-no-longer-generate-configuration).

### to is accepted only with a Mesh targetRef

`spec.to` is accepted only when `spec.targetRef.kind` is `Mesh`, and then `to[].targetRef`
accepts `kind: Mesh` and nothing else. With `kind: Dataplane`, defining `to` at all is rejected
with `spec.to (): must not be defined`.

A fault is produced by the proxy answering the request, so it is configured on that proxy's
inbound side. A gateway has no inbound side to configure, which is the case the `to` form
covers.

A `MeshGateway`-targeted 2.x policy that used `to` therefore has nowhere to go as a
`Dataplane`: keep `kind: Mesh` and narrow the destination in `to[].targetRef`, or drop `to` and
configure the faults inbound.
