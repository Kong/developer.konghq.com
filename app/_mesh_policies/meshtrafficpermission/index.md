---
title: Mesh Traffic Permission
name: MeshTrafficPermissions
products:
- mesh
description: Control which clients can reach a service, based on workload identity.
content_type: plugin
type: policy
icon: meshtrafficpermission.png
tags:
- access-control
- authorization
- security
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Issue identity with the MeshIdentity bundled provider
  url: "/mesh/issue-identity-with-meshidentity/"
- text: Issue identity with MeshIdentity Spire provider
  url: "/mesh/issue-identity-with-meshidentity-spire/"
- text: MeshIdentity policy
  url: "/mesh/policies/meshidentity/"
- text: MeshTrust policy
  url: "/mesh/policies/meshtrust/"
- text: MeshTLS policy
  url: "/mesh/policies/meshtls/"
---

`MeshTrafficPermission` decides which clients can reach a service, and matches them on the
SPIFFE ID of the calling workload rather than on its address or tags.

Use it to deny a namespace outright, allow a group of clients by default, or shadow-deny
traffic to see what a rule would block before it blocks anything.

{:.warning}
> A workload has no identity until [MeshIdentity](/mesh/policies/meshidentity/) issues one.
> Apply a `MeshIdentity` before any `MeshTrafficPermission`, or every request is denied.

**Traffic with no matching rule is denied.** A mesh with `MeshIdentity` in place and no
`MeshTrafficPermission` refuses all service-to-service traffic, so the first policy you write
has to allow something.

## Allow a namespace, deny one client inside it

This policy applies to proxies labelled `app: my-app`. It accepts any identity in the
`my-mesh.us-east-2.mesh.local` trust domain, except the `legacy-ns` namespace and one named
client:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrafficPermission
name: my-app-permissions
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: my-app
  rules:
    - default:
        deny:
          - spiffeID:
              type: Prefix
              value: "spiffe://my-mesh.us-east-2.mesh.local/ns/legacy-ns"
          - spiffeID:
              type: Exact
              value: "spiffe://my-mesh.us-east-2.mesh.local/ns/test/sa/client"
        allow:
          - spiffeID:
              type: Prefix
              value: "spiffe://my-mesh.us-east-2.mesh.local"
```
{% endpolicy_yaml %}

What each field does:

* `targetRef` selects **which proxies enforce the policy**. `kind: Dataplane` with `labels`
  narrows it to one workload; `kind: Mesh` applies it everywhere.
* `rules` describes **which clients those proxies accept**. Each entry carries `allow`,
  `deny`, or `allowWithShadowDeny` lists of matchers.

`deny` wins over `allow`, so the order of entries in the lists does not matter.

## How a request is evaluated

For each request, the proxy walks the matchers in a fixed order:

1. A request matching any `deny` matcher is **denied**.
1. Otherwise, a request matching any `allow` or `allowWithShadowDeny` matcher is **allowed**.
1. A request matching nothing is **denied**.

Every `deny` across every policy that applies to the proxy is evaluated before any `allow`,
so a `deny` cannot be overridden by a later or narrower `allow`. A service owner cannot grant
access that a mesh-wide `deny` has withdrawn.

{:.warning}
> **Do not write a mesh-wide deny-all and then allow services back in.** That pattern comes
> from {{site.mesh_product_name}} 2.x, where the last matching rule won, and it does not
> work here: a blanket `deny` matches every client and no later `allow` can re-open it.
>
> A mesh is already closed. With no `MeshTrafficPermission` in place, nothing is allowed, so
> write only the `allow` rules for the traffic you want.

## Match on identity or SNI

A matcher selects clients by one of two fields.

{% table %}
columns:
  - title: Field
    key: field
  - title: Matches on
    key: matches
  - title: "`type`"
    key: type
rows:
  - field: "`spiffeID`"
    matches: "The SPIFFE ID of the calling workload, issued by `MeshIdentity`."
    type: "`Exact` or `Prefix`"
  - field: "`sni`"
    matches: "The SNI carried on the TLS connection. Used on zone egress, where the destination is identified by SNI rather than by client identity."
    type: "`Exact` only"
{% endtable %}

`spiffeID` is the matcher for service-to-service access, since it names the client.
`sni` accepts only `Exact`, and its value has to be a DNS subdomain.

`Prefix` is how you address a group. A SPIFFE ID is structured as
`spiffe://<trust-domain>/ns/<namespace>/sa/<service-account>`, so a prefix ending at the
namespace selects every workload in it:

```yaml
- spiffeID:
    type: Prefix
    value: spiffe://default.default.mesh.local/ns/observability
```

The trust domain comes from the `MeshIdentity` that issued the identity. Read it from
[MeshTrust](/mesh/policies/meshtrust/) rather than assuming it.

## Test a rule before enforcing it

`allowWithShadowDeny` allows the traffic and logs it as though it had been denied. The
request succeeds, and the log records what a `deny` would have done:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrafficPermission
name: shadow-deny-legacy
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - default:
        allowWithShadowDeny:
          - spiffeID:
              type: Prefix
              value: spiffe://default.default.mesh.local/ns/legacy
```
{% endpolicy_yaml %}

Roll a restrictive policy out this way, read the logs to find what it would break, then
change `allowWithShadowDeny` to `deny`.

## Narrow a policy to one port

`targetRef.sectionName` applies the rules to a single named inbound of the selected proxy,
leaving its other ports alone. This is how a mesh-wide allow rule gets overridden on one
admin port:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrafficPermission
name: deny-observability-ns
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
    sectionName: backend-admin-api
  rules:
    - default:
        deny:
          - spiffeID:
              type: Prefix
              value: spiffe://default.default.mesh.local/ns/observability
```
{% endpolicy_yaml %}

## Zone proxies

`MeshTrafficPermission` applies to a mesh-scoped zone proxy like any other `Dataplane`.
Select the proxy role and zone with `targetRef.labels`, and the listener with
`targetRef.sectionName`.

`sectionName` matches the listener's `name` in
`Dataplane.networking.listeners[]`. A listener with no `name` set takes its port number as
its name, so on a Helm install with default ports that means `10001` for zone ingress and
`10002` for zone egress. Read the listener names from the `Dataplane` rather than assuming
the defaults:

```sh
kubectl get dataplane <zone-proxy> -n kong-mesh-system -o jsonpath='{.spec.networking.listeners}'
```

On zone egress, the destination is matched by SNI:

{% policy_yaml namespace=kong-mesh-system %}
```yaml
type: MeshTrafficPermission
name: deny-external-service-kube
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneegress: enabled
      kuma.io/zone: zone-1
    sectionName: "10002"
  rules:
    - default:
        deny:
          - sni:
              type: Exact
              value: sni.extsvc.default.zone-1.kong-mesh-system.external-service-kube.80
```
{% endpolicy_yaml %}

For a walkthrough, see [Apply policies to mesh-scoped zone proxies](/mesh/zone-proxy-policies/).

## Where this policy applies

`spec.targetRef` selects which proxies enforce the policy: `Mesh`, or `Dataplane` with
`labels`. `spec.rules[]` selects which clients those proxies accept.

There is no `to` array. Access control is an inbound question only, so there is nothing to
select on the outbound side.

For the selectors a policy can carry and why inbound matches an identity rather than a name,
see [How policies select traffic](/mesh/policy-targeting/).

## Upgrading from {{site.mesh_product_name}} 2.x

This migration can take traffic away. `from` matched clients by the tags they carried; `rules`
matches them by the identity they present, so a mesh whose proxies have no workload identity
has nothing for a rule to match, and everything it used to allow is denied.

Work through the steps in order and finish them before upgrading. A stored policy is not
re-validated, so one still carrying `from` keeps being served in the zone it was applied to and
then fails to sync into any zone that is upgraded after it.

### Give the mesh a MeshIdentity

`rules` match on the SPIFFE ID a client presents, which a proxy only has once the mesh issues
one. `Mesh.mtls` is removed from the API and no longer produces mTLS, so identity comes from a
[MeshIdentity](/mesh/policies/meshidentity/).

Do this first. Until every proxy a policy covers has an identity, a rewritten policy matches
nothing, and traffic that matches no rule is denied.

### Rewrite `from` as `rules`

`spec.from` is removed, along with `action` and the client `targetRef` it matched on. A policy
with only `from`, or with neither field, is rejected with `spec (): policy must define rules`.

A `from` entry becomes a `rules` entry whose `allow`, `deny` or `allowWithShadowDeny` list
names the client's SPIFFE ID:

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
`action: AllowWithShadowDeny` an entry in `allowWithShadowDeny`. A `from` entry targeting
`kind: Mesh`, meaning every client, becomes a rule with a mesh-wide `spiffeID` prefix.

The client is now named by the identity it presents rather than by the tags it sets, so a
client that could previously reach a destination by declaring the right tag no longer can.

### Delete the mesh-wide deny

In 2.x the last matching rule won, so the documented pattern was a deny-all followed by
narrower allows that re-opened specific paths. Precedence is now fixed: every `deny` is
evaluated before every `allow`, so a deny-all can never be re-opened and the policy denies
everything.

Delete the deny-all and keep the allow rules. Traffic matching no rule is denied anyway, which
is what the deny-all was there to express.

### Rewrite the top-level targetRef

`spec.targetRef.kind` accepts `Mesh` and `Dataplane`. `MeshSubset`, `MeshService` and
`MeshServiceSubset` are rejected with `in body should be one of [Mesh Dataplane]`, so those
announce themselves. A `MeshSubset` or `MeshServiceSubset` selector becomes `kind: Dataplane`
with the equivalent labels:

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

{:.warning}
> `kind: Dataplane` selects proxies by `labels` only, and a reference carrying `name` or
> `namespace` instead is **accepted**. Those fields are not in the schema, so they are dropped,
> and what remains is a bare `kind: Dataplane` — every proxy in the mesh. A policy written to
> allow one client into one destination becomes a policy that applies to all of them. Nothing
> reports it.

Check the result of any such rewrite by reading the policy back: a stored `targetRef` with a
`kind` and no `labels` covers the whole mesh.

### Move off the legacy TrafficPermission

`TrafficPermission` resources are still accepted and stored, but they no longer affect
generated Envoy configuration. An inbound, external service or gateway route that relied on a
`TrafficPermission` grant with no equivalent `MeshTrafficPermission` now defaults to deny. Every
mTLS inbound still gets an RBAC filter, so this fails closed rather than open. Traffic that no
policy permits is denied at the proxy.

The control plane also no longer creates the default allow-all `TrafficPermission` with a new
`Mesh`.

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
