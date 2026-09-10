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

Two pieces do the work:

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

This is why `deny` cannot be overridden by a later `allow`: a service owner cannot grant
access that a mesh-wide `deny` has withdrawn.

## Match on identity or SNI

A matcher selects clients by one of two fields.

{% table %}
columns:
  - title: Field
    key: field
  - title: Matches on
    key: matches
rows:
  - field: "`spiffeID`"
    matches: "The SPIFFE ID of the calling workload, issued by `MeshIdentity`."
  - field: "`sni`"
    matches: "The SNI value on the TLS connection. Used on zone egress, where the destination is identified by SNI."
{% endtable %}

Both take a `type` of `Exact` or `Prefix`, and a `value`.

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
`targetRef.sectionName` — `10001` for zone ingress, `10002` for zone egress.

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

## Upgrading from {{site.mesh_product_name}} 2.x

{:.warning}
> The `from` array is removed. Rewrite `from` entries as `rules`, which match on the client's
> SPIFFE ID instead of on a `targetRef`.
>
> The `action` field is removed. `action: Allow` becomes an entry in `allow`, `action: Deny`
> becomes an entry in `deny`, and `action: AllowWithShadowDeny` becomes an entry in
> `allowWithShadowDeny`.
>
> `targetRef.kind` no longer accepts `MeshSubset` or `MeshServiceSubset`. Use `Mesh`, or
> `Dataplane` with `labels`.
>
> Access control now depends on workload identity, so a mesh needs a
> [MeshIdentity](/mesh/policies/meshidentity/). `Mesh.mtls` no longer produces mTLS.

A 2.x policy allowing one service to reach another:

```yaml
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
```

becomes:

```yaml
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

The client is now named by the identity it presents, not by the tags it carries.
